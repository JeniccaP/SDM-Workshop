# Facilitator-only script: create cached data for the workshop.
#
# Participants do not need to run this script. It downloads public data and
# creates the small files used by the live workshop.

source("scripts/99_helpers.R")

check_required_packages(c(
  "dplyr",
  "readr",
  "rgbif",
  "sf",
  "terra",
  "rnaturalearth",
  "rnaturalearthdata"
))

library(dplyr)
library(readr)
library(rgbif)
library(sf)
library(terra)
library(rnaturalearth)
library(rnaturalearthdata)

safe_dir_create("data/occurrences")
safe_dir_create("data/environment")
safe_dir_create("data/boundaries")

message_step("Create Brazil boundary")

brazil <- ne_countries(country = "Brazil", scale = "medium", returnclass = "sf")
brazil <- st_make_valid(brazil)
st_write(brazil, "data/boundaries/brazil_boundary.gpkg", delete_dsn = TRUE, quiet = TRUE)

message_step("Download and cache GBIF occurrence records")

target_species <- "Aedes aegypti"
target_country <- "BR"

gbif_count <- occ_count(
  scientificName = target_species,
  country = target_country,
  hasCoordinate = TRUE
)

gbif_download <- occ_search(
  scientificName = target_species,
  country = target_country,
  hasCoordinate = TRUE,
  limit = min(gbif_count, 10000)
)

occurrences_raw <- gbif_download$data
write_csv(occurrences_raw, "data/occurrences/aedes_aegypti_brazil_gbif_raw.csv")

occurrences_clean <- clean_occurrence_table(occurrences_raw)
occurrences_backup <- sample_occurrences(occurrences_clean, max_points = 1200, seed = 42)

write_csv(occurrences_backup, "data/occurrences/aedes_aegypti_brazil_clean_backup.csv")
write_csv(occurrences_backup, "data/occurrences/aedes_aegypti_brazil_clean_workshop.csv")

message("Cached ", nrow(occurrences_backup), " cleaned occurrence records.")

message_step("Download WorldClim bioclimatic predictors")

worldclim_url <- "https://geodata.ucdavis.edu/climate/worldclim/2_1/base/wc2.1_10m_bio.zip"
zip_file <- file.path(tempdir(), "wc2.1_10m_bio.zip")
unzip_dir <- file.path(tempdir(), "wc2.1_10m_bio")

if (!file.exists(zip_file)) {
  download.file(worldclim_url, zip_file, mode = "wb", quiet = FALSE)
}

if (!dir.exists(unzip_dir)) {
  dir.create(unzip_dir, recursive = TRUE)
  unzip(zip_file, exdir = unzip_dir)
}

predictor_files <- file.path(
  unzip_dir,
  c(
    "wc2.1_10m_bio_1.tif",
    "wc2.1_10m_bio_4.tif",
    "wc2.1_10m_bio_12.tif",
    "wc2.1_10m_bio_15.tif"
  )
)

predictors <- rast(predictor_files)
names(predictors) <- c(
  "bio01_annual_mean_temperature",
  "bio04_temperature_seasonality",
  "bio12_annual_precipitation",
  "bio15_precipitation_seasonality"
)

# WorldClim temperature variables are stored as scaled integers.
predictors[["bio01_annual_mean_temperature"]] <- predictors[["bio01_annual_mean_temperature"]] / 10
predictors[["bio04_temperature_seasonality"]] <- predictors[["bio04_temperature_seasonality"]] / 100

brazil_vect <- vect(st_transform(brazil, crs(predictors)))
predictors_brazil <- crop(predictors, brazil_vect)
predictors_brazil <- mask(predictors_brazil, brazil_vect)

writeRaster(
  predictors_brazil,
  "data/environment/brazil_bioclim_predictors.tif",
  overwrite = TRUE
)

message("Cached environmental predictors.")

message_step("Done")

message("Cached files created in data/occurrences, data/environment, and data/boundaries.")

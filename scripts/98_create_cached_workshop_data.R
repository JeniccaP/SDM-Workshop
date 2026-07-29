# Facilitator-only script: create cached data for the workshop.
#
# Participants do not need to run this script. It downloads public data and
# creates the small files used by the live workshop.

required_packages <- c(
  "dplyr",
  "readr",
  "rgbif",
  "sf",
  "terra",
  "rnaturalearth",
  "rnaturalearthdata"
)

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "These packages are missing: ",
    paste(missing_packages, collapse = ", "),
    "\nPlease run scripts/00_install_packages.R first.",
    call. = FALSE
  )
}

library(dplyr)
library(readr)
library(rgbif)
library(sf)
library(terra)
library(rnaturalearth)
library(rnaturalearthdata)

dir.create("data/occurrences", recursive = TRUE, showWarnings = FALSE)
dir.create("data/environment", recursive = TRUE, showWarnings = FALSE)
dir.create("data/boundaries", recursive = TRUE, showWarnings = FALSE)

cat("\nCreate Brazil boundary\n")

brazil <- ne_countries(country = "Brazil", scale = "medium", returnclass = "sf")
brazil <- st_make_valid(brazil)
st_write(brazil, "data/boundaries/brazil_boundary.gpkg", delete_dsn = TRUE, quiet = TRUE)

cat("\nDownload and cache GBIF occurrence records\n")

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

occurrences_clean <- occurrences_raw %>%
  filter(!is.na(decimalLongitude), !is.na(decimalLatitude)) %>%
  filter(decimalLongitude >= -75, decimalLongitude <= -30) %>%
  filter(decimalLatitude >= -35, decimalLatitude <= 6) %>%
  filter(!(decimalLongitude == 0 & decimalLatitude == 0)) %>%
  distinct(decimalLongitude, decimalLatitude, .keep_all = TRUE)

set.seed(42)
if (nrow(occurrences_clean) > 1200) {
  occurrences_backup <- slice_sample(occurrences_clean, n = 1200)
} else {
  occurrences_backup <- occurrences_clean
}

write_csv(occurrences_backup, "data/occurrences/aedes_aegypti_brazil_clean_backup.csv")
write_csv(occurrences_backup, "data/occurrences/aedes_aegypti_brazil_clean_workshop.csv")

message("Cached ", nrow(occurrences_backup), " cleaned occurrence records.")

cat("\nDownload WorldClim bioclimatic predictors\n")

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

# WorldClim v2.1 bioclimatic variables are provided in interpretable units.
# bio01 is annual mean temperature in degrees Celsius, so we keep it unchanged.
#
# bio04 is temperature seasonality. It is the standard deviation of monthly
# temperature values multiplied by 100 in the bioclim convention. Dividing by
# 100 gives a more intuitive "standard deviation in degrees Celsius" scale for
# teaching and plotting.
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

cat("\nDone\n")

message("Cached files created in data/occurrences, data/environment, and data/boundaries.")

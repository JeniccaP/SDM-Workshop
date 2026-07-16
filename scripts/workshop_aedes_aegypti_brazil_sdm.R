# Dengue vector SDM workshop
# A beginner-friendly species distribution model for Aedes aegypti in Brazil
#
# How to use this script:
# 1. Open SDM_dengue_Brazil_workshop.Rproj.
# 2. Open this script in RStudio.
# 3. Run it section by section, using Ctrl+Enter / Cmd+Enter.
#
# Important:
# This is a teaching model. It estimates environmental suitability for
# Aedes aegypti. It does not estimate dengue transmission or dengue risk.


# =============================================================================
# SECTION 0: Setup
# =============================================================================

# This line loads a small file of workshop helper functions that we wrote for
# this lesson. These helper functions are not from an R package.
#
# You can open scripts/99_helpers.R to inspect them. The main helpers used here
# are:
# - check_required_packages(): checks whether packages are installed
# - safe_dir_create(): creates folders if they do not already exist
# - message_step(): prints readable section messages in the Console
# - clean_occurrence_table(): does simple coordinate cleaning
# - sample_occurrences(): keeps a random teaching-sized sample of records
# - thin_to_one_point_per_cell(): keeps one record per environmental raster cell
source("scripts/99_helpers.R")

# Packages are collections of functions. For example, the function rast() comes
# from the terra package. In this workshop script, we usually write that as:
#
# terra::rast()
#
# This package::function() style helps you see where a function comes from.
#
# Quick examples you will see below:
# - rgbif::occ_search() downloads occurrence records from GBIF
# - readr::read_csv() reads a CSV file
# - ggplot2::ggplot() starts a plot
# - rnaturalearth::ne_countries() gets a country boundary
# - terra::rast() reads raster layers
# - sf::st_read() reads vector spatial data
# - biomod2::BIOMOD_Modeling() fits the SDM
required_packages <- c(
  "biomod2",
  "dplyr",
  "ggplot2",
  "readr",
  "rgbif",
  "sf",
  "terra",
  "viridis",
  "rnaturalearth",
  "rnaturalearthdata",
  "randomForest"
)

check_required_packages(required_packages)

# Most of the script uses package::function() so you can see where functions
# come from. biomod2 is a special case: some biomod2 modeling steps expect the
# package to be attached with library(). We still write the visible biomod2 calls
# as biomod2::BIOMOD_Modeling(), biomod2::BIOMOD_Projection(), and so on.
suppressPackageStartupMessages(suppressWarnings(library(biomod2)))

safe_dir_create("outputs/figures")
safe_dir_create("outputs/maps")
safe_dir_create("outputs/models")
safe_dir_create("outputs/tables")


# =============================================================================
# SECTION 1: Choose the species and study area
# =============================================================================

target_species <- "Aedes aegypti"
target_country <- "BR"

# For the live workshop, FALSE is safer and quicker because it uses the cleaned
# backup file. To demonstrate a live GBIF download, change this to TRUE.
download_from_gbif <- FALSE

message_step("Workshop target")
message("Species: ", target_species)
message("Country: ", target_country)


# =============================================================================
# SECTION 2: Get occurrence records from GBIF or use the cached backup
# =============================================================================

raw_file <- "data/occurrences/aedes_aegypti_brazil_gbif_raw.csv"
backup_file <- "data/occurrences/aedes_aegypti_brazil_clean_backup.csv"

if (download_from_gbif) {
  message_step("Checking GBIF record count")

  gbif_count <- rgbif::occ_count(
    scientificName = target_species,
    country = target_country,
    hasCoordinate = TRUE
  )

  message("GBIF currently reports ", gbif_count, " coordinate-bearing records.")

  message_step("Downloading GBIF occurrence records")

  gbif_download <- rgbif::occ_search(
    scientificName = target_species,
    country = target_country,
    hasCoordinate = TRUE,
    limit = min(gbif_count, 10000)
  )

  occurrences_raw <- gbif_download$data
  readr::write_csv(occurrences_raw, raw_file)
  message("Saved raw GBIF records to: ", raw_file)
} else if (file.exists(raw_file)) {
  message_step("Using cached raw GBIF records")
  occurrences_raw <- suppressWarnings(readr::read_csv(raw_file, show_col_types = FALSE, guess_max = 10000))
} else {
  message_step("Using cleaned backup occurrence records")
  occurrences_raw <- suppressWarnings(readr::read_csv(backup_file, show_col_types = FALSE, guess_max = 10000))
}

message("Rows loaded: ", nrow(occurrences_raw))


# =============================================================================
# SECTION 3: Clean and map occurrence records
# =============================================================================

message_step("Cleaning occurrence coordinates")

# clean_occurrence_table() is one of our workshop helper functions from
# scripts/99_helpers.R. It keeps records with plausible Brazil coordinates,
# removes missing coordinates, removes zero-zero coordinates, and drops exact
# duplicate coordinate pairs.
occurrences_clean <- clean_occurrence_table(occurrences_raw)

message("Rows before cleaning: ", nrow(occurrences_raw))
message("Rows after cleaning:  ", nrow(occurrences_clean))

# Keep a workshop-sized sample so the model is fast on beginner laptops.
max_points <- 1000

# sample_occurrences() is also a workshop helper. It uses dplyr::slice_sample()
# inside the helper file, but we keep the main script uncluttered here.
occurrences_workshop <- sample_occurrences(occurrences_clean, max_points = max_points, seed = 42)

clean_file <- "data/occurrences/aedes_aegypti_brazil_clean_workshop.csv"
readr::write_csv(occurrences_workshop, clean_file)

message("Records used in the live workflow: ", nrow(occurrences_workshop))
message("Saved cleaned workshop records to: ", clean_file)

message_step("Mapping cleaned occurrence records")

# rnaturalearth::ne_countries() downloads/loads a country boundary.
# returnclass = "sf" means we want an sf spatial object, which ggplot2 can map.
brazil <- rnaturalearth::ne_countries(country = "Brazil", scale = "medium", returnclass = "sf")

p_occ <- ggplot2::ggplot() +
  ggplot2::geom_sf(data = brazil, fill = "grey95", color = "grey45", linewidth = 0.3) +
  ggplot2::geom_point(
    data = occurrences_workshop,
    ggplot2::aes(x = decimalLongitude, y = decimalLatitude),
    color = "#D1495B",
    alpha = 0.55,
    size = 1.4
  ) +
  ggplot2::coord_sf(xlim = c(-75, -30), ylim = c(-35, 6), expand = FALSE) +
  ggplot2::labs(
    title = "Cleaned Aedes aegypti occurrence records",
    subtitle = "Brazil, GBIF records with coordinates",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::theme_minimal(base_size = 12)

print(p_occ)
ggplot2::ggsave("outputs/figures/cleaned_occurrence_records.png", p_occ, width = 7, height = 7, dpi = 180, bg = "white")


# =============================================================================
# SECTION 4: Load environmental predictors
# =============================================================================

message_step("Loading environmental predictors")

predictor_file <- "data/environment/brazil_bioclim_predictors.tif"
boundary_file <- "data/boundaries/brazil_boundary.gpkg"

# terra::rast() reads raster data. A raster is a grid of cells, like a map image,
# where each cell contains data values such as temperature or rainfall.
predictors <- terra::rast(predictor_file)

# sf::st_read() reads vector spatial data, such as the Brazil boundary polygon.
brazil_boundary <- sf::st_read(boundary_file, quiet = TRUE)

message("Predictor layers:")
print(names(predictors))

annual_temp <- predictors[["bio01_annual_mean_temperature"]]
annual_temp_df <- as.data.frame(annual_temp, xy = TRUE, na.rm = TRUE)

p_temp <- ggplot2::ggplot(annual_temp_df) +
  ggplot2::geom_raster(ggplot2::aes(x = x, y = y, fill = bio01_annual_mean_temperature)) +
  ggplot2::geom_sf(data = brazil_boundary, fill = NA, color = "grey25", linewidth = 0.25, inherit.aes = FALSE) +
  ggplot2::scale_fill_viridis_c(name = "deg C") +
  ggplot2::coord_sf(expand = FALSE) +
  ggplot2::labs(
    title = "Annual mean temperature predictor",
    subtitle = "Prepared for the workshop modeling exercise",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::theme_minimal(base_size = 12)

print(p_temp)
ggplot2::ggsave("outputs/figures/environment_annual_temperature.png", p_temp, width = 7, height = 7, dpi = 180, bg = "white")


# =============================================================================
# SECTION 5: Format data and run a first biomod2 model
# =============================================================================

message_step("Preparing occurrence records for biomod2")

# Thin to one occurrence per environmental grid cell. This avoids giving extra
# weight to repeated points inside the same predictor pixel.
#
# thin_to_one_point_per_cell() is a workshop helper. Inside that helper, the key
# terra function is terra::cellFromXY(), which asks: "which raster cell contains
# this longitude/latitude point?"
occurrences_model <- thin_to_one_point_per_cell(occurrences_workshop, predictors)
occurrences_model <- sample_occurrences(occurrences_model, max_points = 800, seed = 42)

message("Records used for modeling: ", nrow(occurrences_model))

species_xy <- as.matrix(occurrences_model[, c("decimalLongitude", "decimalLatitude")])
species_presence <- rep(1, nrow(occurrences_model))

message_step("Formatting data for biomod2")

# biomod2::BIOMOD_FormatingData() organizes the species records, coordinates,
# environmental predictors, and pseudo-absence settings into the format biomod2
# expects.
formatted_data <- biomod2::BIOMOD_FormatingData(
  resp.name = "Aedes_aegypti",
  resp.var = species_presence,
  resp.xy = species_xy,
  expl.var = predictors,
  PA.nb.rep = 1,
  PA.nb.absences = 1000,
  PA.strategy = "random",
  filter.raster = TRUE,
  seed.val = 42
)

message_step("Fitting a simple model")

# GLM is used live because it is fast, interpretable, and has few dependencies.
# Random Forest and ensemble models are good next steps after this workshop.
models_to_run <- c("GLM")

model_out <- suppressWarnings(
  # biomod2::BIOMOD_Modeling() fits the SDM. Here we use a GLM because it is
  # fast and easier to explain in a short beginner workshop.
  biomod2::BIOMOD_Modeling(
    bm.format = formatted_data,
    modeling.id = "first_sdm",
    models = models_to_run,
    CV.strategy = "random",
    CV.nb.rep = 1,
    CV.perc = 0.8,
    metric.eval = c("TSS", "AUCroc"),
    var.import = 1,
    nb.cpu = 1,
    seed.val = 42,
    do.progress = TRUE
  )
)

saveRDS(model_out, "outputs/models/aedes_aegypti_biomod2_model.rds")

evaluations <- biomod2::get_evaluations(model_out)
readr::write_csv(as.data.frame(evaluations), "outputs/tables/model_evaluation.csv")

variables <- biomod2::get_variables_importance(model_out)
readr::write_csv(as.data.frame(variables), "outputs/tables/variable_importance.csv")

message("Saved model object to: outputs/models/aedes_aegypti_biomod2_model.rds")
message("Saved evaluation table to: outputs/tables/model_evaluation.csv")
message("Saved variable importance table to: outputs/tables/variable_importance.csv")


# =============================================================================
# SECTION 6: Project and map suitability across Brazil
# =============================================================================

message_step("Projecting suitability across Brazil")

# biomod2::BIOMOD_Projection() applies the fitted model to every raster cell in
# Brazil, creating a map of predicted environmental suitability.
projection_out <- biomod2::BIOMOD_Projection(
  bm.mod = model_out,
  proj.name = "Brazil_current",
  new.env = predictors,
  models.chosen = "all",
  build.clamping.mask = FALSE,
  nb.cpu = 1,
  seed.val = 42
)

projection_raster_all <- biomod2::get_predictions(projection_out)

# biomod2 may return several projection layers for run/full-data models.
# For this first workshop map, average them into one suitability layer.
if (terra::nlyr(projection_raster_all) > 1) {
  suitability <- terra::app(projection_raster_all, mean, na.rm = TRUE)
} else {
  suitability <- projection_raster_all
}

names(suitability) <- "aedes_aegypti_suitability"

terra::writeRaster(
  suitability,
  "outputs/maps/aedes_aegypti_brazil_suitability.tif",
  overwrite = TRUE
)

saveRDS(projection_out, "outputs/models/aedes_aegypti_biomod2_projection.rds")

message("Saved suitability raster to: outputs/maps/aedes_aegypti_brazil_suitability.tif")

message_step("Mapping predicted suitability")

suitability_df <- as.data.frame(suitability, xy = TRUE, na.rm = TRUE)
names(suitability_df)[3] <- "suitability"

p_suitability <- ggplot2::ggplot() +
  ggplot2::geom_raster(
    data = suitability_df,
    ggplot2::aes(x = x, y = y, fill = suitability)
  ) +
  ggplot2::geom_sf(data = brazil_boundary, fill = NA, color = "grey20", linewidth = 0.25) +
  ggplot2::geom_point(
    data = occurrences_workshop,
    ggplot2::aes(x = decimalLongitude, y = decimalLatitude),
    color = "black",
    fill = "white",
    shape = 21,
    size = 0.9,
    alpha = 0.45,
    stroke = 0.15
  ) +
  ggplot2::scale_fill_viridis_c(
    name = "Suitability",
    option = "magma",
    limits = c(0, 1000)
  ) +
  ggplot2::coord_sf(expand = FALSE) +
  ggplot2::labs(
    title = "Predicted environmental suitability for Aedes aegypti",
    subtitle = "Teaching model for Brazil using GBIF occurrences and bioclimatic predictors",
    x = "Longitude",
    y = "Latitude",
    caption = "Suitability is not dengue risk. Interpretation requires vector biology, surveillance context, and uncertainty checks."
  ) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(
    plot.caption = ggplot2::element_text(color = "grey35", size = 8),
    legend.position = "right"
  )

print(p_suitability)
ggplot2::ggsave(
  "outputs/maps/aedes_aegypti_brazil_suitability.png",
  p_suitability,
  width = 8,
  height = 7,
  dpi = 220,
  bg = "white"
)


# =============================================================================
# SECTION 7: Interpret the model output
# =============================================================================

message_step("Model evaluation")

evaluations <- readr::read_csv("outputs/tables/model_evaluation.csv", show_col_types = FALSE)
print(evaluations)

message_step("Interpretation prompts")

cat("
Discuss with a neighbor:

1. Where does the model predict higher suitability?
2. Are these areas biologically plausible for Aedes aegypti?
3. What could be caused by sampling bias rather than true suitability?
4. Why is this map not the same as a dengue risk map?
5. What additional data would public health teams need before acting?

")

message("Workshop script complete.")

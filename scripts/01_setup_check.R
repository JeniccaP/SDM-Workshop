# Check that the workshop folder and packages are ready.

source("scripts/99_helpers.R")

required_packages <- c(
  "biomod2",
  "gbm",
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

message_step("Checking required packages")
check_required_packages(required_packages)

message_step("Checking workshop folders")
required_dirs <- c(
  "scripts",
  "data/occurrences",
  "data/environment",
  "data/boundaries",
  "outputs/figures",
  "outputs/maps",
  "outputs/models",
  "outputs/tables"
)

for (folder in required_dirs) {
  safe_dir_create(folder)
}

message_step("Checking cached data")
cached_occurrences <- "data/occurrences/aedes_aegypti_brazil_clean_backup.csv"
cached_predictors <- "data/environment/brazil_bioclim_predictors.tif"
cached_boundary <- "data/boundaries/brazil_boundary.gpkg"

if (file.exists(cached_occurrences)) {
  message("Found cached occurrences: ", cached_occurrences)
} else {
  message("Cached occurrences not found yet. They will be created or downloaded.")
}

if (file.exists(cached_predictors)) {
  message("Found cached environmental predictors: ", cached_predictors)
} else {
  message("Cached environmental predictors not found yet. The workshop includes a script to create them.")
}

if (file.exists(cached_boundary)) {
  message("Found Brazil boundary: ", cached_boundary)
} else {
  message("Brazil boundary not found yet. The workshop includes a script to create it.")
}

message_step("Setup check complete")
message("If there were no errors, you are ready for the workshop.")

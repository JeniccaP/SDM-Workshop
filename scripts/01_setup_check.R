# Check that the workshop folder and packages are ready.

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

cat("\nChecking required packages...\n")

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

cat("\nChecking workshop folders...\n")
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
  if (!dir.exists(folder)) {
    dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  }
}

cat("\nChecking cached data...\n")
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

cat("\nSetup check complete.\n")
message("If there were no errors, you are ready for the workshop.")

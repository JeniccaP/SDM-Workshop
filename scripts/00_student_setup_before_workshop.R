# 00_student_setup_before_workshop.R
# Run this script once before the SDM workshop.
# It installs the R packages used in the workshop and checks that the data
# files are already inside the workshop folder.
#
# How to use:
# 1. Download and unzip the workshop folder from GitHub.
# 2. Open SDM_dengue_Brazil_workshop.Rproj in RStudio.
# 3. Open this file and click Source, or run:
#    source("scripts/00_student_setup_before_workshop.R")

cat("\n")
cat("SDM workshop setup: Aedes aegypti in Brazil\n")
cat("------------------------------------------------------------\n")
cat("Working folder:\n")
cat(getwd(), "\n\n")

options(repos = c(CRAN = "https://cloud.r-project.org"))

required_packages <- data.frame(
  package = c(
    "biomod2", "terra", "sf", "dplyr", "readr", "ggplot2", "rgbif",
    "gbm", "randomForest", "viridis", "rnaturalearth",
    "rnaturalearthdata", "tibble"
  ),
  used_for = c(
    "main SDM workflow: formatting data, fitting models, projections, ensembles",
    "reading, writing, cropping, and plotting raster environmental layers",
    "reading and working with vector spatial data such as Brazil boundaries",
    "simple data cleaning, filtering, and table manipulation",
    "reading and writing csv files",
    "making plots used during the workshop",
    "downloading occurrence records from GBIF",
    "fitting boosted regression tree / GBM models through biomod2",
    "fitting random forest models through biomod2",
    "colour scales for maps and plots",
    "downloading country boundaries used in the backup-data builder",
    "boundary data used by rnaturalearth",
    "creating small tidy tables used in the annotated workshop script"
  ),
  stringsAsFactors = FALSE
)

optional_packages <- data.frame(
  package = c("geodata", "CoordinateCleaner"),
  used_for = c(
    "optional: re-download climate rasters if the cached data need to be rebuilt",
    "optional: extra occurrence-record quality checks for more advanced workflows"
  ),
  stringsAsFactors = FALSE
)

cat("Required packages for the workshop:\n")
print(required_packages, row.names = FALSE)

cat("\nOptional packages:\n")
print(optional_packages, row.names = FALSE)

install_if_missing <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    message("Installing package: ", package)
    install.packages(package, dependencies = TRUE)
  } else {
    message("Already installed: ", package)
  }
}

cat("\nInstalling required packages from CRAN...\n")
invisible(lapply(required_packages$package, install_if_missing))

install_optional_packages <- FALSE

if (install_optional_packages) {
  cat("\nInstalling optional packages...\n")
  invisible(lapply(optional_packages$package, install_if_missing))
} else {
  cat("\nOptional packages were not installed automatically.\n")
  cat("To install them, change install_optional_packages <- FALSE to TRUE and run this script again.\n")
}

package_ok <- vapply(required_packages$package, requireNamespace, logical(1), quietly = TRUE)

if (!all(package_ok)) {
  missing_after_install <- required_packages$package[!package_ok]
  stop(
    "These required packages are still missing: ",
    paste(missing_after_install, collapse = ", "),
    "\nTry running this script again. If sf or terra fails, update R/RStudio first; ",
    "on Windows install Rtools if R asks for it; on Mac install Xcode Command Line Tools if R asks for compilers."
  )
}

cat("\nAll required packages are installed.\n\n")

folders_needed <- c(
  "data/occurrences",
  "data/environment",
  "data/boundaries",
  "outputs/figures",
  "outputs/maps",
  "outputs/tables"
)

for (folder in folders_needed) {
  if (!dir.exists(folder)) {
    dir.create(folder, recursive = TRUE)
    message("Created missing folder: ", folder)
  }
}

data_needed <- data.frame(
  file = c(
    "data/occurrences/aedes_aegypti_brazil_clean_backup.csv",
    "data/occurrences/aedes_aegypti_brazil_clean_workshop.csv",
    "data/occurrences/aedes_aegypti_brazil_gbif_raw.csv",
    "data/environment/brazil_bioclim_predictors.tif",
    "data/boundaries/brazil_boundary.gpkg"
  ),
  what_it_is = c(
    "cleaned Aedes aegypti occurrence records used as the fast workshop backup",
    "working copy of the cleaned occurrence records used during the practical",
    "raw GBIF occurrence download kept as a reference and backup",
    "Brazil environmental predictor raster stack used for modelling",
    "Brazil national boundary used for maps and cropping"
  ),
  stringsAsFactors = FALSE
)

data_needed$found <- file.exists(data_needed$file)

cat("Data files expected in the workshop folder:\n")
print(data_needed, row.names = FALSE)

if (all(data_needed$found)) {
  cat("\nAll required workshop data files are present.\n")
} else {
  cat("\nSome required data files are missing.\n")
  cat("Please re-download the full workshop folder from GitHub, including the data folder.\n")
  cat("These files are provided so that we do not depend on large downloads during the live session.\n")
  cat("Missing files:\n")
  print(data_needed$file[!data_needed$found])
}

cat("\nDuring the workshop we will open and run:\n")
cat("scripts/workshop_aedes_aegypti_brazil_sdm.R\n\n")

cat("Optional only: if you want to rebuild the cached data from online sources later,\n")
cat("run scripts/98_create_cached_workshop_data.R. This can take longer and needs internet.\n\n")

cat("Setup script finished.\n")

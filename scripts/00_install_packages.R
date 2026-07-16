# Install packages for the dengue vector SDM workshop.
#
# Run this script before the workshop. It is okay if optional packages fail;
# the main lesson does not depend on them.

cran_packages <- c(
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

optional_packages <- c(
  "CoordinateCleaner",
  "geodata"
)

install_if_missing <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    install.packages(package)
  }
}

message("Installing required packages...")
invisible(lapply(cran_packages, install_if_missing))

message("Trying optional packages...")
invisible(lapply(optional_packages, function(package) {
  try(install_if_missing(package), silent = TRUE)
}))

message("Done. Now run scripts/01_setup_check.R")

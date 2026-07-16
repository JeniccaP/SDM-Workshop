# Helper functions for the dengue vector SDM workshop.
# These functions are intentionally plain and explicit for beginner readers.

# safe_dir_create() is a small wrapper around base R's dir.exists() and
# dir.create(). We use it so scripts can create output folders only when needed.
safe_dir_create <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
}

# message_step() uses base R's cat() to print a clear section header in the
# Console. This is only for readability during the workshop.
message_step <- function(text) {
  cat("\n", strrep("=", 72), "\n", sep = "")
  cat(text, "\n")
  cat(strrep("=", 72), "\n", sep = "")
}

# check_required_packages() checks whether each package can be found by R.
# requireNamespace() is useful because it checks for a package without attaching
# it with library().
check_required_packages <- function(packages) {
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]

  if (length(missing) > 0) {
    stop(
      "These packages are missing: ",
      paste(missing, collapse = ", "),
      "\nPlease run scripts/00_install_packages.R first.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}

# clean_occurrence_table() does simple coordinate cleaning for this Brazil
# example. It uses dplyr::filter() to keep rows and dplyr::distinct() to remove
# exact duplicate coordinate pairs.
clean_occurrence_table <- function(occurrences) {
  needed <- c("species", "decimalLongitude", "decimalLatitude")
  missing_cols <- setdiff(needed, names(occurrences))

  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
  }

  occurrences |>
    dplyr::filter(!is.na(decimalLongitude), !is.na(decimalLatitude)) |>
    dplyr::filter(decimalLongitude >= -75, decimalLongitude <= -30) |>
    dplyr::filter(decimalLatitude >= -35, decimalLatitude <= 6) |>
    dplyr::filter(!(decimalLongitude == 0 & decimalLatitude == 0)) |>
    dplyr::distinct(decimalLongitude, decimalLatitude, .keep_all = TRUE)
}

# thin_to_one_point_per_cell() keeps only one occurrence record in each
# environmental raster cell. This reduces repeated records from the same raster
# pixel. terra::cellFromXY() finds the raster cell for each longitude/latitude.
thin_to_one_point_per_cell <- function(occurrences, predictor_stack) {
  cells <- terra::cellFromXY(
    predictor_stack[[1]],
    as.matrix(occurrences[, c("decimalLongitude", "decimalLatitude")])
  )

  occurrences$predictor_cell <- cells
  occurrences |>
    dplyr::filter(!is.na(predictor_cell)) |>
    dplyr::distinct(predictor_cell, .keep_all = TRUE) |>
    dplyr::select(-predictor_cell)
}

# sample_occurrences() keeps at most max_points records. set.seed() makes the
# random sample reproducible, so everyone in the workshop gets the same result.
sample_occurrences <- function(occurrences, max_points = 1000, seed = 42) {
  if (nrow(occurrences) <= max_points) {
    return(occurrences)
  }

  set.seed(seed)
  dplyr::slice_sample(occurrences, n = max_points)
}

# save_png() is a tiny shortcut for ggplot2::ggsave(). The main workshop script
# now calls ggplot2::ggsave() directly, but this helper remains for extensions.
save_png <- function(filename, width = 8, height = 6, dpi = 180) {
  ggplot2::ggsave(filename, width = width, height = height, dpi = dpi, bg = "white")
}

# Troubleshooting Package Installation

## First Things To Try

Restart RStudio, then run:

```r
source("scripts/00_install_packages.R")
source("scripts/01_setup_check.R")
```

Make sure you opened the project file:

```text
SDM_dengue_Brazil_workshop.Rproj
```

## If `terra` Or `sf` Fails

These packages connect R to geospatial libraries. They usually install cleanly from CRAN binaries, but they can be fussy on older systems.

Try:

```r
install.packages("terra", type = "binary")
install.packages("sf", type = "binary")
```

If R says binary packages are not available, install the latest R version from CRAN and try again.

## If `biomod2` Fails

Try installing the core modeling helpers first:

```r
install.packages(c("randomForest", "gbm", "maxnet"))
install.packages("biomod2")
```

The live workshop uses GLM by default, which has the lightest dependency burden.

## If GBIF Download Fails

That is okay. Use the cleaned backup data:

```r
use_cached_backup <- TRUE
```

in:

```text
scripts/workshop_aedes_aegypti_brazil_sdm.R
```

## If R Cannot Find Files

Check the top-right of RStudio. The project name should be:

```text
SDM_dengue_Brazil_workshop
```

Then run:

```r
getwd()
list.files()
```

You should see folders called `scripts`, `data`, and `outputs`.

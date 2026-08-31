# Dengue Vector SDM Workshop: Setup Guide

Welcome! In this workshop we will use R to build a first species distribution model for the dengue vector *Aedes aegypti* in Brazil.

The workshop is beginner-friendly, but it does rely on several R packages. Please try to complete this setup before the session. If something fails, do not worry: we will have cached data available during the workshop.

## 1. Install R

Download and install the latest version of R from:

<https://cran.r-project.org/>

Choose the version for your operating system:

- Windows: "Download R for Windows"
- macOS: "Download R for macOS"

## 2. Install RStudio Desktop

Download and install RStudio Desktop from:

<https://posit.co/download/rstudio-desktop/>

R is the programming language. RStudio is the interface we will use to write and run R code.

## 3. Download The Workshop Folder

You should have a folder called:

```text
SDM_dengue_Brazil_workshop
```

Put it somewhere easy to find, such as your Desktop or Documents folder.

## 4. Open The RStudio Project

Inside the workshop folder, double-click:

```text
SDM_dengue_Brazil_workshop.Rproj
```

This opens RStudio in the correct folder. This means you should not need to use `setwd()`.

## 5. Run The Pre-workshop Setup Script

In RStudio, open:

```text
scripts/00_student_setup_before_workshop.R
```

Run the whole script.

This one script will:

- show which R packages are needed and what each one is used for
- install any missing required packages from CRAN
- check that the workshop data files are present in the `data/` folder
- create the `outputs/` folders used during the practical

If the script says that data files are missing, please re-download the full workshop folder from GitHub. The cached data are included so we do not depend on large live downloads during the session.

Optional packages are listed in the script but are not installed automatically. To install them too, change:

```r
install_optional_packages <- FALSE
```

to:

```r
install_optional_packages <- TRUE
```

and run the script again.

## 6. Common Installation Problems

### Windows

If package installation asks whether to compile from source, choose "No" unless you already have RTools installed.

### macOS

Some spatial packages may ask for command line tools. If prompted, install them and try again.

### Slow Internet

The workshop includes cached occurrence data and environmental layers. If the live GBIF download fails, you can still complete the model.

## 7. During The Workshop

The participant-facing lesson is:

```text
lesson.html
```

The short intro slide deck is:

```text
slides/intro_sdm_dengue_brazil.pptx
```

During the live workshop, we will mostly use one script and run it section by section:

```text
scripts/workshop_aedes_aegypti_brazil_sdm.R
```

The other scripts are setup checks, cached-data builders, or optional exports.

Outputs will be saved into:

```text
outputs/
```

The model is a teaching model. It estimates environmental suitability for *Aedes aegypti*, not dengue transmission or human disease risk.

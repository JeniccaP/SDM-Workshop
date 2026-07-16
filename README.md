# Mapping Dengue Vector Suitability In Brazil

This repository contains a beginner-friendly 90-minute workshop on using species distribution models in R for infectious disease applications.

The practical example models environmental suitability for *Aedes aegypti*, a dengue vector, across Brazil using GBIF occurrence records, WorldClim bioclimatic predictors, and `biomod2`.

## Start Here

Participants should open:

```text
SDM_dengue_Brazil_workshop.Rproj
```

Then follow:

```text
README_setup.md
lesson.html
scripts/workshop_aedes_aegypti_brazil_sdm.R
```

## Main Materials

- `README_setup.md` - pre-workshop setup instructions
- `lesson.html` - participant-facing lesson
- `lesson.md` and `lesson.Rmd` - editable lesson sources
- `scripts/workshop_aedes_aegypti_brazil_sdm.R` - main live workshop script
- `slides/intro_sdm_dengue_brazil.pptx` - short intro deck
- `materials_pdf/` - PDF versions of the lesson, setup guide, slides, and handouts
- `data/` - cached occurrence records, environmental predictors, and Brazil boundary

## Live Workshop Script

The main script is intentionally written as one annotated file with section headers:

```text
scripts/workshop_aedes_aegypti_brazil_sdm.R
```

It uses the `package::function()` style so participants can see where functions come from, for example:

```r
rgbif::occ_search()
terra::rast()
sf::st_read()
ggplot2::ggplot()
biomod2::BIOMOD_Modeling()
```

## Data

The repository includes cached teaching data so the workshop can run even if live downloads are slow:

- GBIF *Aedes aegypti* occurrence records for Brazil
- WorldClim v2.1 bioclimatic predictors cropped to Brazil
- Brazil boundary from Natural Earth

See:

```text
data_sources.md
```

## Important Interpretation Note

This workshop estimates environmental suitability for *Aedes aegypti*. It does not estimate dengue incidence, dengue transmission, mosquito abundance, or outbreak risk.

The suitability map is a teaching output and a starting point for discussion, not an operational public health risk product.

## Regenerating Materials

To regenerate the HTML lesson:

```r
source("lesson_render.R")
```

To regenerate PDFs:

```bash
python scripts/97_export_shareable_materials.py
```

To rebuild cached public data as a facilitator:

```r
source("scripts/98_create_cached_workshop_data.R")
```

# Data Sources And Provenance

This workshop uses public data for teaching species distribution modeling.

## Occurrence Data

Species:

```text
Aedes aegypti
```

Country:

```text
Brazil, GBIF country code BR
```

Source:

```text
GBIF occurrence records downloaded through the rgbif R package
```

The facilitator cache was created with:

```text
scripts/98_create_cached_workshop_data.R
```

Cached files:

```text
data/occurrences/aedes_aegypti_brazil_gbif_raw.csv
data/occurrences/aedes_aegypti_brazil_clean_backup.csv
```

The cached clean backup contains a teaching-sized sample of cleaned coordinate records.

## Environmental Predictors

Source:

```text
WorldClim v2.1 bioclimatic variables, 10 minute resolution
```

URL used by the cache builder:

```text
https://geodata.ucdavis.edu/climate/worldclim/2_1/base/wc2.1_10m_bio.zip
```

Variables used:

```text
bio01 annual mean temperature
bio04 temperature seasonality
bio12 annual precipitation
bio15 precipitation seasonality
```

Cached file:

```text
data/environment/brazil_bioclim_predictors.tif
```

## Boundary Data

Source:

```text
Natural Earth country boundary, accessed through rnaturalearth
```

Cached file:

```text
data/boundaries/brazil_boundary.gpkg
```

## Important Interpretation Note

The model estimates environmental suitability for *Aedes aegypti*. It does not estimate dengue incidence, dengue transmission, mosquito abundance, or future outbreak risk.

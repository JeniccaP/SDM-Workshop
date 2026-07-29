# Dengue vector SDM workshop
# A beginner-friendly species distribution model for Aedes aegypti in Brazil
#
# Open SDM_dengue_Brazil_workshop.Rproj first.
# Then run this script section by section in RStudio.
#
# This is a teaching model. It estimates environmental suitability for
# Aedes aegypti. It does not estimate dengue transmission or dengue risk.


################################################################################
################################################################################
############################### 0. LOAD PACKAGES ################################
################################################################################
################################################################################

# If some packages are not installed, run:
# source("scripts/00_install_packages.R")

LIB <- c(
  "rgbif",              # download occurrence records from GBIF
  "biomod2",            # species distribution models
  "terra",              # raster data
  "sf",                 # vector spatial data
  "dplyr",              # data cleaning
  "readr",              # read/write CSV files
  "ggplot2",            # plotting
  "rnaturalearth",      # Brazil boundary map
  "rnaturalearthdata",  # map data used by rnaturalearth
  "gbm",                # GBM model used by biomod2
  "randomForest"        # Random Forest model used by biomod2
)

for (pkg in LIB) {
  suppressPackageStartupMessages(suppressWarnings(library(pkg, character.only = TRUE)))
}

# Create output folders if they do not already exist.
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/maps", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/models", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)


################################################################################
################################################################################
###################### 1. CHOOSE SPECIES AND STUDY AREA ########################
################################################################################
################################################################################

target_species <- "Aedes aegypti"
target_country <- "BR"   # BR is the GBIF country code for Brazil

cat("\nSpecies:", target_species, "\n")
cat("Country:", target_country, "\n")


################################################################################
################################################################################
######################### 2. GET OCCURRENCE RECORDS ############################
################################################################################
################################################################################

raw_file <- "data/occurrences/aedes_aegypti_brazil_gbif_raw.csv"
backup_file <- "data/occurrences/aedes_aegypti_brazil_clean_backup.csv"

# -------------------------------------------------------------------------
# 2A. Demonstration: how to check and download records from GBIF
# -------------------------------------------------------------------------
#
# I will show this in the workshop so you know how to adapt the workflow later.
# If the internet is slow, you do not need to run the download lines. We already
# provide cached GBIF data in the workshop folder.
#
# occ_count() comes from rgbif.
# It tells us how many GBIF records match our search.
#
# gbif_count <- occ_count(
#   scientificName = target_species,
#   country = target_country,
#   hasCoordinate = TRUE
# )
#
# cat("\nGBIF records with coordinates:", gbif_count, "\n")
#
# occ_search() comes from rgbif.
# It downloads occurrence records.
#
# This can take a little time. During the workshop, we may run this once as a
# demonstration, or we may skip straight to the cached file below.
#
# gbif_download <- occ_search(
#   scientificName = target_species,
#   country = target_country,
#   hasCoordinate = TRUE,
#   limit = min(gbif_count, 10000)
# )
#
# occurrences_raw <- gbif_download$data
#
# write_csv(occurrences_raw, raw_file)


# -------------------------------------------------------------------------
# 2B. Workshop path: load the cached GBIF records
# -------------------------------------------------------------------------
#
# This is the line we will normally use for the hands-on model.
# It keeps the workshop moving even if GBIF or the internet is slow.

occurrences_raw <- suppressWarnings(
  read_csv(raw_file, show_col_types = FALSE, guess_max = 10000)
)

# Backup option:
# If the raw cached file is missing, use the already cleaned backup instead.

# occurrences_raw <- suppressWarnings(
#   read_csv(backup_file, show_col_types = FALSE, guess_max = 10000)
# )

cat("\nNumber of occurrence records loaded:", nrow(occurrences_raw), "\n")


################################################################################
################################################################################
######################## 3. CLEAN OCCURRENCE RECORDS ###########################
################################################################################
################################################################################

# We keep only records with longitude and latitude.
occurrences_clean <- occurrences_raw %>%
  filter(!is.na(decimalLongitude), !is.na(decimalLatitude))

# We keep points inside a broad Brazil bounding box.
# This is a simple teaching filter, not a perfect country-border check.
occurrences_clean <- occurrences_clean %>%
  filter(decimalLongitude >= -75, decimalLongitude <= -30) %>%
  filter(decimalLatitude >= -35, decimalLatitude <= 6)

# Remove the common bad coordinate 0, 0.
occurrences_clean <- occurrences_clean %>%
  filter(!(decimalLongitude == 0 & decimalLatitude == 0))

# Remove exact duplicate coordinate pairs.
occurrences_clean <- occurrences_clean %>%
  distinct(decimalLongitude, decimalLatitude, .keep_all = TRUE)

cat("\nRecords before cleaning:", nrow(occurrences_raw), "\n")
cat("Records after cleaning:", nrow(occurrences_clean), "\n")

# Keep a smaller random sample for the live workshop.
# This keeps the model fast on ordinary laptops.
set.seed(42)
max_points <- 1000

if (nrow(occurrences_clean) > max_points) {
  occurrences_workshop <- slice_sample(occurrences_clean, n = max_points)
} else {
  occurrences_workshop <- occurrences_clean
}

write_csv(
  occurrences_workshop,
  "data/occurrences/aedes_aegypti_brazil_clean_workshop.csv"
)


################################################################################
################################################################################
########################### 4. MAP OCCURRENCE RECORDS ##########################
################################################################################
################################################################################

# ne_countries() comes from rnaturalearth.
brazil <- ne_countries(country = "Brazil", scale = "medium", returnclass = "sf")

# st_geometry() comes from sf.
# It keeps only the map shape, so base R plots the boundary without trying to
# plot every attribute column in the Brazil data table.
plot(st_geometry(brazil))

p_occ <- ggplot() +
  geom_sf(data = brazil, fill = "grey95", color = "grey45", linewidth = 0.3) +
  geom_point(
    data = occurrences_workshop,
    aes(x = decimalLongitude, y = decimalLatitude),
    color = "#D1495B",
    alpha = 0.55,
    size = 1.4
  ) +
  coord_sf(xlim = c(-75, -30), ylim = c(-35, 6), expand = FALSE) +
  labs(
    title = "Cleaned Aedes aegypti occurrence records",
    subtitle = "Brazil, GBIF records with coordinates",
    x = "Longitude",
    y = "Latitude"
  ) +
  theme_minimal(base_size = 12)

print(p_occ)

ggsave(
  "outputs/figures/cleaned_occurrence_records.png",
  p_occ,
  width = 7,
  height = 7,
  dpi = 180,
  bg = "white"
)


################################################################################
################################################################################
######################### 5. LOAD ENVIRONMENTAL RASTERS ########################
################################################################################
################################################################################

# rast() comes from terra.
# It reads raster data: gridded data such as temperature or rainfall.
predictors <- rast("data/environment/brazil_bioclim_predictors.tif")

# st_read() comes from sf.
# It reads vector spatial data, such as a country boundary.
brazil_boundary <- st_read("data/boundaries/brazil_boundary.gpkg", quiet = TRUE)

# These are the four environmental predictors used in the workshop.
# They come from WorldClim "bioclimatic" variables.
#
# Why these four?
# We want a small beginner-friendly predictor set that still captures two ideas:
# 1. average climate conditions, and
# 2. seasonal variation in climate conditions.
#
# For Aedes aegypti, temperature and rainfall are biologically relevant because
# they can affect mosquito survival, development, breeding sites, and seasonal
# persistence. These variables are still simplifications; they do not include
# urban habitat, water storage, vector control, human movement, or dengue virus.
predictor_info <- tibble::tribble(
  ~layer_name, ~plain_name, ~unit, ~what_it_means, ~why_it_might_matter,
  "bio01_annual_mean_temperature",
  "Annual mean temperature",
  "degrees Celsius",
  "Average temperature across the year.",
  "Mosquito survival and development are temperature sensitive.",
  "bio04_temperature_seasonality",
  "Temperature seasonality",
  "standard deviation of monthly temperature, degrees Celsius",
  "How much temperature varies across the year.",
  "Strong seasonality can affect whether mosquito populations persist year-round.",
  "bio12_annual_precipitation",
  "Annual precipitation",
  "millimetres",
  "Total rainfall across the year.",
  "Rainfall can influence outdoor water availability and potential breeding sites.",
  "bio15_precipitation_seasonality",
  "Precipitation seasonality",
  "coefficient of variation",
  "How uneven rainfall is across the year.",
  "Highly seasonal rainfall can change when breeding habitats are available."
)

print(predictor_info)

# Check the raster layer names.
names(predictors)

# See a numeric summary of each environmental layer.
# This is a useful check for unit mistakes. For example, annual mean temperature
# in Brazil should look like degrees Celsius, not values near 1 or 2.
summary(predictors)

plot(predictors)

# Plot one environmental layer.
annual_temp <- predictors[["bio01_annual_mean_temperature"]]
annual_temp_df <- as.data.frame(annual_temp, xy = TRUE, na.rm = TRUE)

p_temp <- ggplot(annual_temp_df) +
  geom_raster(aes(x = x, y = y, fill = bio01_annual_mean_temperature)) +
  geom_sf(data = brazil_boundary, fill = NA, color = "grey25", linewidth = 0.25) +
  scale_fill_viridis_c(name = "Annual mean\ntemperature\n(deg C)") +
  coord_sf(expand = FALSE) +
  labs(
    title = "Annual mean temperature predictor",
    subtitle = "WorldClim bio01, cropped to Brazil",
    x = "Longitude",
    y = "Latitude"
  ) +
  theme_minimal(base_size = 12)

print(p_temp)

ggsave(
  "outputs/figures/environment_annual_temperature.png",
  p_temp,
  width = 7,
  height = 7,
  dpi = 180,
  bg = "white"
)


################################################################################
################################################################################
####################### 5B. CHECK PREDICTOR CORRELATION ########################
################################################################################
################################################################################

# Environmental predictors are often correlated.
#
# Example:
# Places with high annual mean temperature may also have different rainfall,
# elevation, or seasonality. If two predictors carry almost the same information,
# it can be difficult to interpret which one is really driving the model.
#
# In a short workshop we will not remove variables automatically, but we should
# learn how to check correlation before modelling.

# spatSample() comes from terra.
# It samples raster cells from the study area.
#
# We sample cells because rasters can contain thousands or millions of pixels.
# A sample is enough to inspect the broad correlation pattern quickly.
set.seed(42)
predictor_sample <- spatSample(
  predictors,
  size = 5000,
  method = "regular",
  na.rm = TRUE,
  as.df = TRUE
)

# cor() comes from base R.
# It calculates pairwise correlation between variables.
#
# Pearson correlation ranges from -1 to +1:
# +1 means two variables increase together.
#  0 means no linear relationship.
# -1 means one variable decreases as the other increases.
predictor_correlation <- cor(predictor_sample, method = "pearson")

print(round(predictor_correlation, 2))

# Convert the correlation matrix to a long table for ggplot2.
# as.table() is from base R. It turns the matrix into row/column/value format.
correlation_df <- as.data.frame(as.table(predictor_correlation))
names(correlation_df) <- c("variable_1", "variable_2", "correlation")

# Save the correlation table so participants can inspect it later.
write_csv(
  correlation_df,
  "outputs/tables/environmental_predictor_correlation.csv"
)

p_correlation <- ggplot(correlation_df) +
  geom_tile(aes(x = variable_1, y = variable_2, fill = correlation), color = "white") +
  geom_text(aes(x = variable_1, y = variable_2, label = round(correlation, 2)), size = 3) +
  scale_fill_gradient2(
    low = "#2C7BB6",
    mid = "white",
    high = "#B2182B",
    midpoint = 0,
    limits = c(-1, 1),
    name = "Pearson\ncorrelation"
  ) +
  labs(
    title = "Correlation between environmental predictors",
    subtitle = "High absolute correlations suggest predictors may carry similar information",
    x = NULL,
    y = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 35, hjust = 1),
    panel.grid = element_blank()
  )

print(p_correlation)

ggsave(
  "outputs/figures/environmental_predictor_correlation.png",
  p_correlation,
  width = 8,
  height = 6,
  dpi = 180,
  bg = "white"
)


################################################################################
################################################################################
########################## 6. PREPARE DATA FOR BIOMOD2 #########################
################################################################################
################################################################################

# Biomod2 needs:
# 1. A response variable: 1 means presence.
# 2. Coordinates for the presence records.
# 3. Environmental raster layers.

# First, keep only one occurrence record per raster cell.
# This avoids giving too much weight to repeated records in the same pixel.
cell_id <- cellFromXY(
  predictors[[1]],
  as.matrix(occurrences_workshop[, c("decimalLongitude", "decimalLatitude")])
)

occurrences_workshop$cell_id <- cell_id

occurrences_model <- occurrences_workshop %>%
  filter(!is.na(cell_id)) %>%
  distinct(cell_id, .keep_all = TRUE)

# Keep the modeling dataset small enough for the workshop.
set.seed(42)
max_model_points <- 800

if (nrow(occurrences_model) > max_model_points) {
  occurrences_model <- slice_sample(occurrences_model, n = max_model_points)
}

species_xy <- as.matrix(occurrences_model[, c("decimalLongitude", "decimalLatitude")])
species_presence <- rep(1, nrow(occurrences_model))

cat("\nNumber of records used for modeling:", nrow(occurrences_model), "\n")

# BIOMOD_FormatingData() comes from biomod2.
# Because we only have presence records, biomod2 creates pseudo-absences.
formatted_data <- BIOMOD_FormatingData(
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

## << quickly run the other PA strategies that BIOMOD offer >> 
## << Provide papers ... >> BIG Question in SDMs 

################################################################################
################################################################################
############################ 7. RUN INDIVIDUAL MODELS ##########################
################################################################################
################################################################################

# We will run three example algorithms:
# GLM = Generalized Linear Model
# GBM = Generalized Boosting Model / boosted regression trees
# RF  = Random Forest

models_to_run <- c("GLM", "GBM", "RF")

# For the workshop we use biomod2's "bigboss" default model settings.
# This keeps the live code shorter.
#
# If you want to customize model settings later, look at the optional section
# near the end of this script.



model_out <- BIOMOD_Modeling(
  bm.format = formatted_data,
  modeling.id = "first_sdm",
  models = models_to_run,
  CV.strategy = "random",
  CV.nb.rep = 1,
  CV.perc = 0.8,
  OPT.strategy = "bigboss",
  metric.eval = c("TSS", "AUCroc"),
  var.import = 1,
  nb.cpu = 1,
  seed.val = 42,
  do.progress = TRUE
)

saveRDS(model_out, "outputs/models/aedes_aegypti_biomod2_model.rds")

# get_evaluations() and get_variables_importance() come from biomod2.
model_evaluation <- get_evaluations(model_out)
variable_importance <- get_variables_importance(model_out)

write_csv(as.data.frame(model_evaluation), "outputs/tables/model_evaluation.csv")
write_csv(as.data.frame(variable_importance), "outputs/tables/variable_importance.csv")

model_evaluation


################################################################################
################################################################################
############################### 8. BUILD ENSEMBLES #############################
################################################################################
################################################################################

# Ensemble models combine predictions from the individual models.
#
# EMmean  = mean prediction
# EMwmean = weighted mean prediction
#
# For this beginner workshop, we keep all models in the ensemble.

ensemble_out <- BIOMOD_EnsembleModeling(
  bm.mod = model_out,
  models.chosen = "all",
  em.by = "all",
  em.algo = c("EMmean", "EMwmean"),
  metric.select = "all",
  metric.eval = c("TSS", "AUCroc"),
  var.import = 1,
  nb.cpu = 1,
  seed.val = 42,
  do.progress = TRUE
)

saveRDS(ensemble_out, "outputs/models/aedes_aegypti_biomod2_ensemble.rds")

ensemble_evaluation <- get_evaluations(ensemble_out)
write_csv(as.data.frame(ensemble_evaluation), "outputs/tables/ensemble_evaluation.csv")

ensemble_evaluation


################################################################################
################################################################################
########################## 9. PROJECT MODELS ACROSS BRAZIL #####################
################################################################################
################################################################################

# BIOMOD_Projection() projects the individual models across all raster cells.
projection_out <- BIOMOD_Projection(
  bm.mod = model_out,
  proj.name = "Brazil_current",
  new.env = predictors,
  models.chosen = "all",
  build.clamping.mask = FALSE,
  nb.cpu = 1,
  seed.val = 42
)

prediction_layers <- get_predictions(projection_out)

# Biomod2 returns several prediction layers. For this first workshop map,
# we average them into one simple suitability raster.
if (nlyr(prediction_layers) > 1) {
  suitability <- app(prediction_layers, mean, na.rm = TRUE)
} else {
  suitability <- prediction_layers
}

names(suitability) <- "aedes_aegypti_suitability"

writeRaster(
  suitability,
  "outputs/maps/aedes_aegypti_brazil_suitability.tif",
  overwrite = TRUE
)

# BIOMOD_EnsembleForecasting() projects the ensemble model.
ensemble_projection_out <- BIOMOD_EnsembleForecasting(
  bm.em = ensemble_out,
  bm.proj = projection_out,
  models.chosen = "all",
  nb.cpu = 1
)

ensemble_prediction_layers <- get_predictions(ensemble_projection_out)

if (nlyr(ensemble_prediction_layers) > 1) {
  ensemble_suitability <- app(ensemble_prediction_layers, mean, na.rm = TRUE)
} else {
  ensemble_suitability <- ensemble_prediction_layers
}

names(ensemble_suitability) <- "aedes_aegypti_ensemble_suitability"

writeRaster(
  ensemble_suitability,
  "outputs/maps/aedes_aegypti_brazil_ensemble_suitability.tif",
  overwrite = TRUE
)


################################################################################
################################################################################
############################### 10. MAP PREDICTIONS ############################
################################################################################
################################################################################

suitability_df <- as.data.frame(suitability/1000, xy = TRUE, na.rm = TRUE)
names(suitability_df)[3] <- "suitability"

p_suitability <- ggplot() +
  geom_raster(data = suitability_df, aes(x = x, y = y, fill = suitability)) +
  geom_sf(data = brazil_boundary, fill = NA, color = "grey20", linewidth = 0.25) +
  geom_point(
    data = occurrences_workshop,
    aes(x = decimalLongitude, y = decimalLatitude),
    color = "black",
    fill = "white",
    shape = 21,
    size = 0.9,
    alpha = 0.45,
    stroke = 0.15
  ) +
  scale_fill_viridis_c(name = "Suitability", option = "magma", limits = c(0, 1)) +
  coord_sf(expand = FALSE) +
  labs(
    title = "Predicted environmental suitability for Aedes aegypti",
    subtitle = "Average prediction from GLM, GBM, and Random Forest outputs",
    x = "Longitude",
    y = "Latitude",
    caption = "Suitability is not dengue risk."
  ) +
  theme_minimal(base_size = 12)

print(p_suitability)

ggsave(
  "outputs/maps/aedes_aegypti_brazil_suitability.png",
  p_suitability,
  width = 8,
  height = 7,
  dpi = 220,
  bg = "white"
)

ensemble_suitability_df <- as.data.frame(ensemble_suitability/1000, xy = TRUE, na.rm = TRUE)
names(ensemble_suitability_df)[3] <- "ensemble_suitability"

p_ensemble <- ggplot() +
  geom_raster(data = ensemble_suitability_df, aes(x = x, y = y, fill = ensemble_suitability)) +
  geom_sf(data = brazil_boundary, fill = NA, color = "grey20", linewidth = 0.25) +
  geom_point(
    data = occurrences_workshop,
    aes(x = decimalLongitude, y = decimalLatitude),
    color = "black",
    fill = "white",
    shape = 21,
    size = 0.9,
    alpha = 0.45,
    stroke = 0.15
  ) +
  scale_fill_viridis_c(name = "Ensemble suitability", option = "magma", limits = c(0, 1)) +
  coord_sf(expand = FALSE) +
  labs(
    title = "Ensemble prediction of environmental suitability for Aedes aegypti",
    subtitle = "Teaching ensemble combining GLM, GBM, and Random Forest models",
    x = "Longitude",
    y = "Latitude",
    caption = "Suitability is not dengue risk."
  ) +
  theme_minimal(base_size = 12)

print(p_ensemble)

ggsave(
  "outputs/maps/aedes_aegypti_brazil_ensemble_suitability.png",
  p_ensemble,
  width = 8,
  height = 7,
  dpi = 220,
  bg = "white"
)


################################################################################
################################################################################
############################### 11. INTERPRETATION #############################
################################################################################
################################################################################

model_evaluation
ensemble_evaluation

# Discussion questions:
# 1. Where does the model predict higher suitability?
# 2. Are these areas biologically plausible for Aedes aegypti?
# 3. What could be caused by sampling bias rather than true suitability? ## Reword 
# 4. Why is this map not the same as a dengue risk map?
# 5. What additional data would public health teams need before acting?


################################################################################
################################################################################
########################### 12. OPTIONAL: MODEL SETTINGS #######################
################################################################################
################################################################################

# This section is optional. You do not need it for the live workshop.
#
# Biomod2 can use default settings, or you can define your own settings for
# individual models. The function for this is bm_ModelingOptions().
#
# Example only:
#
# custom_model_values <- list(
#   GLM.binary.stats.glm = list(
#     "_allData_allRun" = list(control = list(maxit = 100))
#   ),
#   GBM.binary.gbm.gbm = list(
#     "_allData_allRun" = list(
#       n.trees = 1000,
#       interaction.depth = 3,
#       shrinkage = 0.005,
#       n.minobsinnode = 5,
#       bag.fraction = 0.5,
#       cv.folds = 3
#     )
#   ),
#   RF.binary.randomForest.randomForest = list(
#     "_allData_allRun" = list(
#       ntree = 300,
#       mtry = 2,
#       nodesize = 5
#     )
#   )
# )
#
# custom_options <- bm_ModelingOptions(
#   data.type = "binary",
#   models = models_to_run,
#   strategy = "user.defined",
#   user.val = custom_model_values,
#   user.base = "bigboss",
#   bm.format = formatted_data
# )
#
# To use these options in BIOMOD_Modeling(), you would add:
#
# OPT.strategy = "user.defined",
# OPT.user = custom_options

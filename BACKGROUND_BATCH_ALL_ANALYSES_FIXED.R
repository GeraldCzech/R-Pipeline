#!/usr/bin/env Rscript
# BACKGROUND BATCH FIXED: Gamma family for continuous frequency data

library(tidyverse)
library(lavaan)
library(brms)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  BACKGROUND BATCH FIXED: Complete Model Suite                 ║\n")
cat("║  Fix: Gamma family for continuous OF02_Freq                   ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

start_time <- Sys.time()
base_dir <- "/home/gerald/R-pipeline"
batch_out_dir <- file.path(base_dir, "v2_pipeline/BATCH_OUTPUTS")
dir.create(batch_out_dir, showWarnings=FALSE, recursive=TRUE)

cat(sprintf("[%s] START: Background Batch (FIXED)\n", format(Sys.time(), "%H:%M:%S")))

# Load Data
data <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>%
  as.data.frame() %>%
  filter(!is.na(RC_Awareness))

cat(sprintf("[%s] Data loaded: N=%d\n\n", format(Sys.time(), "%H:%M:%S"), nrow(data)))

# STEP 1: Lavaan
cat("STEP 1: Lavaan models\n")
lavaan_results <- tibble()
for (file in c("chatzi_bo_org_proof_BASELINE_VALIDATED_CLUSTERING.rds",
               "chatzi_bo_4stage_4outcomes_MLR_FIML.rds",
               "sem_fc_EXACT_LITERATURE_5factor_lavaan.rds",
               "sem_bo_EXACT_LITERATURE_with2ndorder_lavaan.rds")) {
  model_file <- file.path(base_dir, "v2_pipeline/C_STRUCTURAL_MODELS/outputs", file)
  if (file.exists(model_file)) {
    fit <- readRDS(model_file)
    fit_stats <- fitMeasures(fit, c("cfi", "rmsea"))
    lavaan_results <- bind_rows(lavaan_results, tibble(
      Model = gsub(".rds", "", file),
      CFI = fit_stats["cfi"],
      RMSEA = fit_stats["rmsea"]
    ))
    cat(sprintf("  ✓ %s: CFI=%.4f\n", gsub(".rds", "", file), fit_stats["cfi"]))
  }
}
write_csv(lavaan_results, file.path(batch_out_dir, "BATCH_01_LAVAAN_SUMMARY.csv"))
cat("✓ Step 1 complete\n\n")

# STEP 2: GLM
cat("STEP 2: GLM models\n")
data_glm <- data %>%
  mutate(
    BO_RC_score = rowMeans(select(., TOM, SAW), na.rm=TRUE),
    BO_BF_score = rowMeans(select(., starts_with("FC03_")), na.rm=TRUE),
    BO_TR_score = rowMeans(select(., starts_with("B101_")), na.rm=TRUE),
    BO_CO_score = rowMeans(select(., starts_with("B102_")), na.rm=TRUE)
  )

glm_1 <- glm(OF02_Freq ~ RC_Awareness + org, family=quasipoisson(link="log"), 
             data=data_glm, na.action=na.exclude)
glm_2 <- glm(OF02_Freq ~ BO_RC_score + BO_BF_score + BO_TR_score + BO_CO_score + org, 
             family=quasipoisson(link="log"), data=data_glm, na.action=na.exclude)

cat("  ✓ GLM models fitted\n")

write_csv(tibble(Model = c("Simple", "Full"), AIC = c(AIC(glm_1), AIC(glm_2))),
          file.path(batch_out_dir, "BATCH_02_GLM_COMPARISON.csv"))

glm_paths <- tibble(
  Predictor = names(coef(glm_2))[-1],
  Coefficient = coef(glm_2)[-1],
  P_value = summary(glm_2)$coefficients[-1, 4]
)
write_csv(glm_paths, file.path(batch_out_dir, "BATCH_02_GLM_PATHS.csv"))
cat("✓ Step 2 complete\n\n")

# STEP 3: Bayesian GLM (FIXED: Gamma family)
cat("STEP 3: Bayesian GLM (Gamma family for continuous)\n")
cat("  This will take 10-15 minutes...\n")

data_brms <- data_glm %>% 
  filter(!is.na(OF02_Freq), !is.na(org), OF02_Freq > 0)

brms_1 <- brms::brm(
  OF02_Freq ~ RC_Awareness + (1 | org),
  family = Gamma(link = "log"),
  data = data_brms,
  chains = 2,
  iter = 2000,
  warmup = 1000,
  refresh = 0,
  verbose = FALSE,
  cores = 2
)
cat("  ✓ Model 1 fitted\n")

brms_2 <- brms::brm(
  OF02_Freq ~ BO_RC_score + BO_BF_score + BO_TR_score + BO_CO_score + (1 | org),
  family = Gamma(link = "log"),
  data = data_brms,
  chains = 2,
  iter = 2000,
  warmup = 1000,
  refresh = 0,
  verbose = FALSE,
  cores = 2
)
cat("  ✓ Model 2 fitted\n")

brms_summary_1 <- posterior_summary(brms_1) %>% as.data.frame() %>% rownames_to_column("Parameter")
write_csv(brms_summary_1, file.path(batch_out_dir, "BATCH_03_BAYESIAN_GLM_M1.csv"))
write_csv(posterior_summary(brms_2) %>% as.data.frame() %>% rownames_to_column("Parameter"),
          file.path(batch_out_dir, "BATCH_03_BAYESIAN_GLM_M2.csv"))
cat("✓ Step 3 complete\n\n")

# STEP 4: Org latents
cat("STEP 4: Organization latents\n")
fit_primary <- readRDS(file.path(base_dir, "v2_pipeline/C_STRUCTURAL_MODELS/outputs", 
                                  "chatzi_bo_org_proof_BASELINE_VALIDATED_CLUSTERING.rds"))

factor_scores_data <- data %>%
  select(CASE, org) %>%
  bind_cols(as.data.frame(lavPredict(fit_primary, type="lv")))

org_latents <- factor_scores_data %>%
  group_by(org) %>%
  summarise(
    BO_RC_mean = mean(BO_RC, na.rm=t),
    BO_TR_mean = mean(BO_TR, na.rm=t),
    BO_CO_mean = mean(BO_CO, na.rm=t),
    INTENTION_mean = mean(INTENTION, na.rm=t),
    .groups = "drop"
  )

org_outcomes <- data %>%
  group_by(org) %>%
  summarise(
    N_donors = n(),
    Avg_Frequency = mean(OF02_Freq, na.rm=t),
    .groups = "drop"
  )

org_comparison <- org_latents %>%
  left_join(org_outcomes, by = "org")

write_csv(org_comparison, file.path(batch_out_dir, "BATCH_04_ORG_LATENTS_OUTCOMES.csv"))
cat("✓ Step 4 complete\n\n")

# STEP 5: Heterogeneity
cat("STEP 5: Heterogeneity analysis\n")
org_het <- org_latents %>%
  summarise(
    BO_RC_range = max(BO_RC_mean, na.rm=t) - min(BO_RC_mean, na.rm=t),
    BO_TR_range = max(BO_TR_mean, na.rm=t) - min(BO_TR_mean, na.rm=t),
    BO_CO_range = max(BO_CO_mean, na.rm=t) - min(BO_CO_mean, na.rm=t)
  )

write_csv(org_het, file.path(batch_out_dir, "BATCH_05_ORG_HETEROGENEITY.csv"))
cat("✓ Step 5 complete\n\n")

elapsed <- difftime(Sys.time(), start_time, units="mins")
cat(sprintf("✓ ALL COMPLETE in %.1f minutes\n", elapsed))


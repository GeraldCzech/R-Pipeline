#!/usr/bin/env Rscript
# BACKGROUND BATCH: ALL Lavaan Models + GLM + Bayesian + Org Analysis
# Runtime: ~2-3 hours (runs in background)

library(tidyverse)
library(lavaan)
library(brms)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  BACKGROUND BATCH: Comprehensive Model Suite                  ║\n")
cat("║  Runtime: ~2-3 hours                                           ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

start_time <- Sys.time()
base_dir <- "/home/gerald/R-pipeline"
batch_log <- file.path(base_dir, "BATCH_LOG.txt")
batch_out_dir <- file.path(base_dir, "v2_pipeline/BATCH_OUTPUTS")
dir.create(batch_out_dir, showWarnings=FALSE, recursive=TRUE)

log_msg <- function(msg) {
  timestamp <- format(Sys.time(), "%H:%M:%S")
  full_msg <- sprintf("[%s] %s", timestamp, msg)
  cat(full_msg, "\n")
  cat(full_msg, "\n", file = batch_log, append = TRUE)
}

log_msg("START: Background Batch Analysis")
log_msg(sprintf("PID: %d", Sys.getpid()))

# ─────────────────────────────────────────────────────────────────────────────
# Load Data
# ─────────────────────────────────────────────────────────────────────────────

data <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>%
  as.data.frame() %>%
  filter(!is.na(RC_Awareness))

log_msg(sprintf("Data loaded: N=%d", nrow(data)))

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: All Lavaan Models Re-estimated
# ─────────────────────────────────────────────────────────────────────────────

log_msg("STEP 1: Re-estimating all Lavaan models...")

model_specs <- list(
  "bo_3out" = list(
    name = "Boenigk 3-Outcome",
    file = "chatzi_bo_org_proof_BASELINE_VALIDATED_CLUSTERING.rds"
  ),
  "bo_4out" = list(
    name = "Boenigk 4-Outcome",
    file = "chatzi_bo_4stage_4outcomes_MLR_FIML.rds"
  ),
  "fc_exact" = list(
    name = "Faircloth EXACT",
    file = "sem_fc_EXACT_LITERATURE_5factor_lavaan.rds"
  ),
  "bo_exact" = list(
    name = "Boenigk EXACT",
    file = "sem_bo_EXACT_LITERATURE_with2ndorder_lavaan.rds"
  )
)

lavaan_results <- tibble()

for (spec_name in names(model_specs)) {
  spec <- model_specs[[spec_name]]
  model_file <- file.path(base_dir, "v2_pipeline/C_STRUCTURAL_MODELS/outputs", spec$file)
  
  if (file.exists(model_file)) {
    log_msg(sprintf("  Loading: %s", spec$name))
    fit <- readRDS(model_file)
    
    # Extract key stats
    fit_stats <- fitMeasures(fit, c("cfi", "tli", "rmsea", "srmr", "aic", "bic"))
    n_pars <- length(coef(fit))
    
    lavaan_results <- bind_rows(lavaan_results, tibble(
      Model = spec$name,
      CFI = fit_stats["cfi"],
      TLI = fit_stats["tli"],
      RMSEA = fit_stats["rmsea"],
      SRMR = fit_stats["srmr"],
      N_params = n_pars,
      Converged = fit@optim$converged
    ))
    
    log_msg(sprintf("    ✓ CFI=%.4f", fit_stats["cfi"]))
  } else {
    log_msg(sprintf("    ✗ File not found: %s", model_file))
  }
}

write_csv(lavaan_results, file.path(batch_out_dir, "BATCH_01_LAVAAN_SUMMARY.csv"))
log_msg("✓ Lavaan summary saved")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: GLM Models for OF02_Freq (Frequentist)
# ─────────────────────────────────────────────────────────────────────────────

log_msg("STEP 2: GLM Models for Donation Frequency (Frequentist)...")

glm_models <- list()

# GLM 1: Simple predictors
glm_1 <- glm(OF02_Freq ~ RC_Awareness + org, family=quasipoisson(link="log"), 
             data=data, na.action=na.exclude)
glm_models$simple <- glm_1

# GLM 2: With brand equity indicators
data_glm <- data %>%
  mutate(
    BO_RC_score = rowMeans(select(., TOM, SAW), na.rm=TRUE),
    BO_BF_score = rowMeans(select(., starts_with("FC03_")), na.rm=TRUE),
    BO_TR_score = rowMeans(select(., starts_with("B101_")), na.rm=TRUE),
    BO_CO_score = rowMeans(select(., starts_with("B102_")), na.rm=TRUE)
  )

glm_2 <- glm(OF02_Freq ~ BO_RC_score + BO_BF_score + BO_TR_score + BO_CO_score + org, 
             family=quasipoisson(link="log"), data=data_glm, na.action=na.exclude)
glm_models$full <- glm_2

log_msg("  ✓ GLM models fitted")

# Comparison
glm_comparison <- tibble(
  Model = c("GLM Simple (RC_Awareness + org)", "GLM Full (Brand Equity + org)"),
  AIC = c(AIC(glm_1), AIC(glm_2)),
  Deviance = c(deviance(glm_1), deviance(glm_2)),
  DF = c(df.residual(glm_1), df.residual(glm_2))
)

write_csv(glm_comparison, file.path(batch_out_dir, "BATCH_02_GLM_COMPARISON.csv"))

# GLM paths
glm_paths <- tibble(
  Model = "GLM (Brand Equity)",
  Predictor = names(coef(glm_2))[-1],
  Coefficient = coef(glm_2)[-1],
  Std_Error = summary(glm_2)$coefficients[-1, 2],
  P_value = summary(glm_2)$coefficients[-1, 4]
)

write_csv(glm_paths, file.path(batch_out_dir, "BATCH_02_GLM_PATHS.csv"))
log_msg("✓ GLM results saved")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3: Bayesian GLM Models
# ─────────────────────────────────────────────────────────────────────────────

log_msg("STEP 3: Bayesian GLM Models (MCMC)...")

data_brms <- data_glm %>% filter(!is.na(OF02_Freq), !is.na(org))

# Bayesian GLM 1: Simple model with organization random effects
brms_1 <- brms::brm(
  OF02_Freq ~ RC_Awareness + (1 | org),
  family = poisson(link = "log"),
  data = data_brms,
  chains = 2,
  iter = 2000,
  warmup = 1000,
  refresh = 0,
  verbose = FALSE,
  cores = 2
)

log_msg("  ✓ Bayesian model 1 fitted (RC_Awareness random org)")

# Bayesian GLM 2: Full brand equity model
brms_2 <- brms::brm(
  OF02_Freq ~ BO_RC_score + BO_BF_score + BO_TR_score + BO_CO_score + (1 | org),
  family = poisson(link = "log"),
  data = data_brms,
  chains = 2,
  iter = 2000,
  warmup = 1000,
  refresh = 0,
  verbose = FALSE,
  cores = 2
)

log_msg("  ✓ Bayesian model 2 fitted (Brand Equity random org)")

# Extract results
brms_summary <- bind_rows(
  tidybayes::tidy_draws(brms_1) %>% pivot_longer(everything()) %>% 
    mutate(Model = "Bayesian GLM 1"),
  tidybayes::tidy_draws(brms_2) %>% pivot_longer(everything()) %>% 
    mutate(Model = "Bayesian GLM 2")
)

write_csv(brms_summary, file.path(batch_out_dir, "BATCH_03_BAYESIAN_GLM_DRAWS.csv"))
log_msg("✓ Bayesian GLM results saved")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4: Organization-Specific Latent Variables
# ─────────────────────────────────────────────────────────────────────────────

log_msg("STEP 4: Computing organization-specific latent factors...")

# Load primary Lavaan model
fit_primary <- readRDS(file.path(base_dir, "v2_pipeline/C_STRUCTURAL_MODELS/outputs", 
                                  "chatzi_bo_org_proof_BASELINE_VALIDATED_CLUSTERING.rds"))

# Extract factor scores
factor_scores <- lavPredict(fit_primary, type="lv") %>% as.data.frame()
factor_scores$CASE <- data$CASE
factor_scores$org <- data$org

# Aggregate to organization level
org_latents <- factor_scores %>%
  group_by(org) %>%
  summarise(
    across(c(BO_RC, BO_BF, BO_TR, BO_CO, INTENTION), 
           list(mean = mean, sd = sd, n = ~sum(!is.na(.))),
           .names = "{.col}_{.fn}"),
    .groups = "drop"
  )

# Add organization outcomes
org_outcomes <- data %>%
  group_by(org) %>%
  summarise(
    N_donors = n(),
    Avg_Annual_Donation = mean(OF02_02_num, na.rm=T),
    Avg_Frequency = mean(OF02_Freq, na.rm=T),
    Pct_Regular = 100 * mean(OF_Spender, na.rm=T),
    .groups = "drop"
  )

org_comparison <- org_latents %>%
  left_join(org_outcomes, by = "org") %>%
  arrange(desc(N_donors))

write_csv(org_comparison, file.path(batch_out_dir, "BATCH_04_ORG_LATENTS_OUTCOMES.csv"))
log_msg("✓ Organization latent factors computed")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 5: Organization Heterogeneity Analysis
# ─────────────────────────────────────────────────────────────────────────────

log_msg("STEP 5: Quantifying organization-level heterogeneity...")

org_het <- org_comparison %>%
  summarise(
    across(contains("_mean"), 
           list(min = min, max = max, range = ~max(.) - min(.)),
           .names = "{.col}_{.fn}"),
    N_orgs = n(),
    .groups = "drop"
  ) %>%
  pivot_longer(everything())

write_csv(org_het, file.path(batch_out_dir, "BATCH_05_ORG_HETEROGENEITY.csv"))
log_msg("✓ Organization heterogeneity quantified")

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY & TIMING
# ─────────────────────────────────────────────────────────────────────────────

end_time <- Sys.time()
elapsed <- difftime(end_time, start_time, units="mins")

log_msg(sprintf("COMPLETE: All analyses finished in %.1f minutes", elapsed))
log_msg(sprintf("Output directory: %s", batch_out_dir))

cat("\n\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  BACKGROUND BATCH COMPLETE                                    ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

cat(sprintf("✓ All analyses complete in %.1f minutes\n", elapsed))
cat("✓ Output files:\n")
cat("  - BATCH_01_LAVAAN_SUMMARY.csv\n")
cat("  - BATCH_02_GLM_COMPARISON.csv & BATCH_02_GLM_PATHS.csv\n")
cat("  - BATCH_03_BAYESIAN_GLM_DRAWS.csv\n")
cat("  - BATCH_04_ORG_LATENTS_OUTCOMES.csv\n")
cat("  - BATCH_05_ORG_HETEROGENEITY.csv\n")
cat("\nLog: ", batch_log, "\n")


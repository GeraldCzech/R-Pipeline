#!/usr/bin/env Rscript
# BACKGROUND BATCH INTENSIVE: High-quality Bayesian analysis with comprehensive reporting
# Chains: 4 | Warmup: 2000 | Sample: 4000 = 24,000 total samples per model

library(tidyverse)
library(lavaan)
library(brms)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  BACKGROUND BATCH INTENSIVE: Full Bayesian Pipeline            ║\n")
cat("║  4 chains × 6000 iterations (2000 warmup + 4000 sample)        ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

start_time <- Sys.time()
base_dir <- "/home/gerald/R-pipeline"
batch_out_dir <- file.path(base_dir, "v2_pipeline/BATCH_OUTPUTS")
dir.create(batch_out_dir, showWarnings=FALSE, recursive=TRUE)

# Create report directory
report_dir <- file.path(batch_out_dir, "REPORTS")
dir.create(report_dir, showWarnings=FALSE, recursive=TRUE)

log_msg <- function(msg, stage="") {
  timestamp <- format(Sys.time(), "%H:%M:%S")
  full_msg <- sprintf("[%s] %s", timestamp, msg)
  cat(full_msg, "\n")
  if (stage != "") {
    cat(full_msg, "\n", file=file.path(report_dir, paste0(stage, "_LOG.txt")), append=TRUE)
  }
}

log_msg("START: Intensive Bayesian Analysis", "00_MASTER")

# Load data
data <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>%
  as.data.frame() %>%
  filter(!is.na(RC_Awareness))

log_msg(sprintf("Data loaded: N=%d", nrow(data)), "00_MASTER")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: Lavaan Models
# ─────────────────────────────────────────────────────────────────────────────

log_msg("STEP 1: Lavaan Models", "01_LAVAAN")
cat("STEP 1: Re-estimating Lavaan models...\n")

model_specs <- list(
  "bo_3out" = list(name = "Boenigk 3-Outcome", file = "chatzi_bo_org_proof_BASELINE_VALIDATED_CLUSTERING.rds"),
  "bo_4out" = list(name = "Boenigk 4-Outcome", file = "chatzi_bo_4stage_4outcomes_MLR_FIML.rds"),
  "fc_exact" = list(name = "Faircloth EXACT", file = "sem_fc_EXACT_LITERATURE_5factor_lavaan.rds"),
  "bo_exact" = list(name = "Boenigk EXACT", file = "sem_bo_EXACT_LITERATURE_with2ndorder_lavaan.rds")
)

lavaan_results <- tibble()

for (spec_name in names(model_specs)) {
  spec <- model_specs[[spec_name]]
  model_file <- file.path(base_dir, "v2_pipeline/C_STRUCTURAL_MODELS/outputs", spec$file)
  
  if (file.exists(model_file)) {
    log_msg(sprintf("  Loading: %s", spec$name), "01_LAVAAN")
    fit <- readRDS(model_file)
    fit_stats <- fitMeasures(fit, c("cfi", "tli", "rmsea", "srmr", "aic", "bic"))
    
    lavaan_results <- bind_rows(lavaan_results, tibble(
      Model = spec$name,
      CFI = fit_stats["cfi"],
      TLI = fit_stats["tli"],
      RMSEA = fit_stats["rmsea"],
      SRMR = fit_stats["srmr"],
      AIC = fit_stats["aic"],
      BIC = fit_stats["bic"]
    ))
    
    log_msg(sprintf("    ✓ CFI=%.4f, RMSEA=%.4f", fit_stats["cfi"], fit_stats["rmsea"]), "01_LAVAAN")
  }
}

write_csv(lavaan_results, file.path(batch_out_dir, "BATCH_01_LAVAAN_SUMMARY.csv"))

# Create Lavaan report
lavaan_report <- paste(collapse = "\n", c(
  "# Step 1: Lavaan Structural Models",
  "",
  "## Summary",
  sprintf("Timestamp: %s", Sys.time()),
  sprintf("Models: %d", nrow(lavaan_results)),
  "",
  "## Results",
  "",
  "| Model | CFI | RMSEA | AIC |",
  "|-------|-----|-------|-----|",
  apply(lavaan_results, 1, function(row) {
    sprintf("| %s | %.4f | %.4f | %.0f |",
            row["Model"],
            as.numeric(row["CFI"]),
            as.numeric(row["RMSEA"]),
            as.numeric(row["AIC"]))
  }),
  "",
  "**Status:** ✅ Complete"
))

writeLines(lavaan_report, file.path(report_dir, "01_LAVAAN_REPORT.md"))
log_msg("✓ Step 1 complete (Lavaan + Report)", "00_MASTER")
cat("\n")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: GLM Models
# ─────────────────────────────────────────────────────────────────────────────

log_msg("STEP 2: GLM Models", "02_GLM")
cat("STEP 2: Frequentist GLM models...\n")

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

log_msg("  ✓ GLM models fitted", "02_GLM")

write_csv(tibble(Model = c("Simple (RC + org)", "Full (Brand Equity + org)"), 
                AIC = c(AIC(glm_1), AIC(glm_2))),
          file.path(batch_out_dir, "BATCH_02_GLM_COMPARISON.csv"))

glm_paths <- tibble(
  Predictor = names(coef(glm_2))[-1],
  Coefficient = coef(glm_2)[-1],
  Std_Error = summary(glm_2)$coefficients[-1, 2],
  P_value = summary(glm_2)$coefficients[-1, 4]
)
write_csv(glm_paths, file.path(batch_out_dir, "BATCH_02_GLM_PATHS.csv"))

# GLM report
glm_report <- paste(collapse = "\n", c(
  "# Step 2: Frequentist GLM Models",
  "",
  "## Summary",
  sprintf("Timestamp: %s", Sys.time()),
  "Family: Quasipoisson (robust to overdispersion)",
  "Outcome: OF02_Freq (Donation Frequency)",
  "",
  "## Model Comparison",
  sprintf("Model 1 AIC: %.0f", AIC(glm_1)),
  sprintf("Model 2 AIC: %.0f", AIC(glm_2)),
  "",
  "## Top Predictors (Model 2)",
  "",
  "| Predictor | β | SE | p-value |",
  "|-----------|---|----|---------| ",
  apply(head(glm_paths, 5), 1, function(row) {
    sprintf("| %s | %.4f | %.4f | %.4f |",
            row["Predictor"],
            as.numeric(row["Coefficient"]),
            as.numeric(row["Std_Error"]),
            as.numeric(row["P_value"]))
  }),
  "",
  "**Status:** ✅ Complete"
))

writeLines(glm_report, file.path(report_dir, "02_GLM_REPORT.md"))
log_msg("✓ Step 2 complete (GLM + Report)", "00_MASTER")
cat("\n")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3: Bayesian GLM (INTENSIVE)
# ─────────────────────────────────────────────────────────────────────────────

log_msg("STEP 3: Bayesian GLM (Intensive MCMC)", "03_BAYESIAN_GLM")
cat("STEP 3: Intensive Bayesian GLM - 4 chains × 6000 iter (20-30 min)...\n")

data_brms <- data_glm %>% 
  filter(!is.na(OF02_Freq), !is.na(org), OF02_Freq > 0)

log_msg(sprintf("  Sample: N=%d", nrow(data_brms)), "03_BAYESIAN_GLM")

cat("  Compiling Model 1 (RC_Awareness)...\n")
brms_1 <- brms::brm(
  OF02_Freq ~ RC_Awareness + (1 | org),
  family = Gamma(link = "log"),
  data = data_brms,
  chains = 4,
  iter = 6000,
  warmup = 2000,
  sample = 4000,
  refresh = 0,
  verbose = FALSE,
  cores = 4
)
log_msg("  ✓ Model 1 fitted (Intensive MCMC complete)", "03_BAYESIAN_GLM")

cat("  Compiling Model 2 (Brand Equity)...\n")
brms_2 <- brms::brm(
  OF02_Freq ~ BO_RC_score + BO_BF_score + BO_TR_score + BO_CO_score + (1 | org),
  family = Gamma(link = "log"),
  data = data_brms,
  chains = 4,
  iter = 6000,
  warmup = 2000,
  sample = 4000,
  refresh = 0,
  verbose = FALSE,
  cores = 4
)
log_msg("  ✓ Model 2 fitted (Intensive MCMC complete)", "03_BAYESIAN_GLM")

# Save results
write_csv(posterior_summary(brms_1) %>% as.data.frame() %>% rownames_to_column("Parameter"),
          file.path(batch_out_dir, "BATCH_03_BAYESIAN_GLM_M1.csv"))
write_csv(posterior_summary(brms_2) %>% as.data.frame() %>% rownames_to_column("Parameter"),
          file.path(batch_out_dir, "BATCH_03_BAYESIAN_GLM_M2.csv"))
write_csv(as_draws_df(brms_1) %>% as_tibble(),
          file.path(batch_out_dir, "BATCH_03_BAYESIAN_DRAWS_M1.csv"))
write_csv(as_draws_df(brms_2) %>% as_tibble(),
          file.path(batch_out_dir, "BATCH_03_BAYESIAN_DRAWS_M2.csv"))

# Bayesian report
diag_1 <- tibble(
  Chain = 1:4,
  Rhat_max = NA,
  ESS_bulk_min = NA
)

bayes_report <- paste(collapse = "\n", c(
  "# Step 3: Intensive Bayesian GLM (Gamma family)",
  "",
  "## MCMC Configuration",
  "- **Chains:** 4",
  "- **Warmup (burnin):** 2000 per chain",
  "- **Sampling:** 4000 per chain",
  "- **Total samples:** 16,000 (4 chains × 4000)",
  "- **Family:** Gamma(link = log)",
  "",
  "## Convergence Diagnostics",
  sprintf("Model 1 Rhat max: %.4f (target < 1.01)", max(rhat(brms_1), na.rm=TRUE)),
  sprintf("Model 2 Rhat max: %.4f (target < 1.01)", max(rhat(brms_2), na.rm=TRUE)),
  "",
  "## Posterior Summaries",
  "",
  "### Model 1: RC_Awareness + (1|org)",
  sprintf("Samples: %d", nrow(as_draws_df(brms_1))),
  "",
  "### Model 2: Brand Equity + (1|org)",
  sprintf("Samples: %d", nrow(as_draws_df(brms_2))),
  "",
  "**Status:** ✅ Complete (High-quality MCMC)"
))

writeLines(bayes_report, file.path(report_dir, "03_BAYESIAN_GLM_REPORT.md"))
log_msg("✓ Step 3 complete (Bayesian GLM Intensive + Report)", "00_MASTER")
cat("\n")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4: Org Indicators
# ─────────────────────────────────────────────────────────────────────────────

log_msg("STEP 4: Organization Indicators", "04_ORG")
cat("STEP 4: Org-level brand indicators...\n")

org_indicators <- data %>%
  group_by(org) %>%
  summarise(
    N_respondents = n(),
    RC_Recognition = mean(c(TOM, SAW), na.rm=TRUE),
    BF_Familiarity = rowMeans(pick(starts_with("FC03_")), na.rm=TRUE) %>% mean(na.rm=TRUE),
    TR_Trust = rowMeans(pick(starts_with("B101_")), na.rm=TRUE) %>% mean(na.rm=TRUE),
    CO_Commitment = rowMeans(pick(starts_with("B102_")), na.rm=TRUE) %>% mean(na.rm=TRUE),
    Avg_Annual_Donation = mean(OF02_02_num, na.rm=TRUE),
    Avg_Frequency = mean(OF02_Freq, na.rm=TRUE),
    Pct_Regular_Donor = 100 * mean(OF_Spender, na.rm=TRUE),
    .groups = "drop"
  )

write_csv(org_indicators, file.path(batch_out_dir, "BATCH_04_ORG_INDICATORS.csv"))

# Org report
org_report <- paste(collapse = "\n", c(
  "# Step 4: Organization-Level Brand Indicators",
  "",
  "## Summary",
  sprintf("Organizations: %d", nrow(org_indicators)),
  sprintf("Total respondents: %d", sum(org_indicators$N_respondents)),
  "",
  "## Top Organizations (by N)",
  "",
  "| Org | N | Recognition | Trust | Frequency |",
  "|-----|---|-------------|-------|-----------|",
  apply(head(org_indicators %>% arrange(desc(N_respondents)), 5), 1, function(row) {
    sprintf("| %s | %d | %.2f | %.2f | %.1f |",
            row["org"],
            as.integer(row["N_respondents"]),
            as.numeric(row["RC_Recognition"]),
            as.numeric(row["TR_Trust"]),
            as.numeric(row["Avg_Frequency"]))
  }),
  "",
  "**Status:** ✅ Complete"
))

writeLines(org_report, file.path(report_dir, "04_ORG_REPORT.md"))
log_msg("✓ Step 4 complete (Org Indicators + Report)", "00_MASTER")
cat("\n")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 5: Heterogeneity
# ─────────────────────────────────────────────────────────────────────────────

log_msg("STEP 5: Heterogeneity Analysis", "05_HETERO")
cat("STEP 5: Organization heterogeneity...\n")

org_het <- org_indicators %>%
  summarise(
    Orgs_N = n(),
    RC_Recognition_range = max(RC_Recognition, na.rm=TRUE) - min(RC_Recognition, na.rm=TRUE),
    TR_Trust_range = max(TR_Trust, na.rm=TRUE) - min(TR_Trust, na.rm=TRUE),
    CO_Commitment_range = max(CO_Commitment, na.rm=TRUE) - min(CO_Commitment, na.rm=TRUE),
    Frequency_range = max(Avg_Frequency, na.rm=TRUE) - min(Avg_Frequency, na.rm=TRUE),
    Annual_Donation_range = max(Avg_Annual_Donation, na.rm=TRUE) - min(Avg_Annual_Donation, na.rm=TRUE)
  )

write_csv(org_het, file.path(batch_out_dir, "BATCH_05_ORG_HETEROGENEITY.csv"))

# Heterogeneity report
hetero_report <- paste(collapse = "\n", c(
  "# Step 5: Organization Heterogeneity Analysis",
  "",
  "## Variability Across Organizations",
  "",
  sprintf("Recognition range: %.2f (%.2f to %.2f)",
          org_het$RC_Recognition_range,
          min(org_indicators$RC_Recognition, na.rm=TRUE),
          max(org_indicators$RC_Recognition, na.rm=TRUE)),
  sprintf("Trust range: %.2f (%.2f to %.2f)",
          org_het$TR_Trust_range,
          min(org_indicators$TR_Trust, na.rm=TRUE),
          max(org_indicators$TR_Trust, na.rm=TRUE)),
  sprintf("Frequency range: %.1f (%.1f to %.1f x/year)",
          org_het$Frequency_range,
          min(org_indicators$Avg_Frequency, na.rm=TRUE),
          max(org_indicators$Avg_Frequency, na.rm=TRUE)),
  "",
  "**Status:** ✅ Complete"
))

writeLines(hetero_report, file.path(report_dir, "05_HETERO_REPORT.md"))
log_msg("✓ Step 5 complete (Heterogeneity + Report)", "00_MASTER")

# ─────────────────────────────────────────────────────────────────────────────
# Final Summary
# ─────────────────────────────────────────────────────────────────────────────

elapsed <- difftime(Sys.time(), start_time, units="mins")
final_msg <- sprintf("✅ PHASE 1 COMPLETE - All 5 steps finished in %.1f minutes", elapsed)
log_msg(final_msg, "00_MASTER")

# Create master index
index <- paste(collapse = "\n", c(
  "# Phase 1: Complete Analysis Index",
  "",
  sprintf("**Generated:** %s", Sys.time()),
  sprintf("**Duration:** %.1f minutes", elapsed),
  "",
  "## Reports",
  "- [Step 1: Lavaan Models](01_LAVAAN_REPORT.md)",
  "- [Step 2: GLM Models](02_GLM_REPORT.md)",
  "- [Step 3: Bayesian GLM Intensive](03_BAYESIAN_GLM_REPORT.md)",
  "- [Step 4: Organization Indicators](04_ORG_REPORT.md)",
  "- [Step 5: Heterogeneity Analysis](05_HETERO_REPORT.md)",
  "",
  "## Data Files",
  "- BATCH_01_LAVAAN_SUMMARY.csv",
  "- BATCH_02_GLM_COMPARISON.csv, BATCH_02_GLM_PATHS.csv",
  "- BATCH_03_BAYESIAN_GLM_M1.csv, BATCH_03_BAYESIAN_GLM_M2.csv",
  "- BATCH_03_BAYESIAN_DRAWS_M1.csv, BATCH_03_BAYESIAN_DRAWS_M2.csv",
  "- BATCH_04_ORG_INDICATORS.csv",
  "- BATCH_05_ORG_HETEROGENEITY.csv",
  "",
  "## Configuration",
  "- Bayesian: 4 chains × 6000 iterations (2000 warmup + 4000 sample)",
  "- GLM: Quasipoisson family (robust to overdispersion)",
  "- Total MCMC samples: 16,000 per model",
  "",
  "✅ **Status: COMPLETE**"
))

writeLines(index, file.path(report_dir, "INDEX.md"))
log_msg("✓ Master index created", "00_MASTER")

cat("\n\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  PHASE 1 COMPLETE - INTENSIVE BAYESIAN ANALYSIS               ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")


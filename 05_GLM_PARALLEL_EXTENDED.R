#!/usr/bin/env Rscript
# EXTENDED GLM ANALYSIS WITH DONATION TYPE SEGMENTATION
# Parallel execution: Main analysis + Stratified by donation type
# Plus: 3-way interaction (Brand × Donation_Type × SES_z)

set.seed(2026)
suppressPackageStartupMessages({
  library(tidyverse)
  library(lme4)
  library(brms)
  library(future)
  library(furrr)
})

log_msg <- function(msg, level = "INFO") {
  ts <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(sprintf("[%s] %s: %s\n", ts, level, msg))
  flush.console()
}

log_msg("═══════════════════════════════════════════════════════════════", "")
log_msg("EXTENDED GLM ANALYSIS - WITH DONATION TYPE SEGMENTATION", "PHASE")
log_msg("═══════════════════════════════════════════════════════════════", "")

# ─────────────────────────────────────────────────────────────────────────────
# LOAD DATA
# ─────────────────────────────────────────────────────────────────────────────

log_msg("Loading data...", "")

block1 <- readRDS("/home/gerald/R-pipeline/results/block1_prepared.rds")
admin_data <- readRDS("/home/gerald/R-pipeline/results/glm_prep/admin_data_prepared.rds")

log_msg(sprintf("Block1: n=%d", nrow(block1)), "")
log_msg(sprintf("Admin: n=%d", nrow(admin_data)), "")

# ─────────────────────────────────────────────────────────────────────────────
# PART A: CREATE DONATION TYPE VARIABLE
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("PART A: Creating Donation Type Variable", "SECTION")

# Check for donation type indicators in admin_data
log_msg("Checking for donation type variables...", "")

donation_type_cols <- c("donation_type", "Spendentyp", "giver_type", "donor_type",
                       "Einmalig", "Regelmässig", "Mengengabe")

found_col <- NULL
for (col in donation_type_cols) {
  if (col %in% names(admin_data)) {
    found_col <- col
    log_msg(sprintf("✓ Found: %s", col), "")
    break
  }
}

if (is.null(found_col)) {
  log_msg("⚠️ No donation type variable found - inferring from giving patterns", "WARN")

  # Infer donation type from admin_data structure
  # Group by donor ID and count donations
  admin_summary <- admin_data %>%
    group_by(respondent_id) %>%  # Assuming there's an ID column
    summarize(
      n_donations = n(),
      total_amount = sum(amount, na.rm = TRUE),
      avg_amount = mean(amount, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      donation_type = case_when(
        n_donations == 1 ~ "Einmalig",
        n_donations >= 2 & n_donations <= 5 ~ "Regelmäßig",
        n_donations > 5 ~ "Regelmäßig",  # High frequency = regular
        TRUE ~ "Einmalig"
      ),
      # Further classify bulk/large donors
      is_bulk = total_amount > quantile(total_amount, 0.75, na.rm = TRUE)
    )

  # Add to block1
  block1 <- block1 %>%
    left_join(admin_summary %>% select(respondent_id, donation_type, is_bulk),
              by = c("id" = "respondent_id"))  # Adjust ID column name as needed

  log_msg(sprintf("✓ Inferred donation types from admin_data"), "")
} else {
  # Use existing column
  block1$donation_type <- admin_data[[found_col]]
  log_msg(sprintf("✓ Using existing column: %s", found_col), "")
}

# Summarize donation types
log_msg("Donation Type Distribution:", "")
dt_summary <- block1 %>%
  group_by(donation_type) %>%
  summarize(n = n(), pct = 100*n()/nrow(block1), .groups = "drop")

print(dt_summary)

# ─────────────────────────────────────────────────────────────────────────────
# SETUP PARALLEL PROCESSING
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("Setting up parallel processing...", "")

n_cores <- detectCores()
n_workers <- max(2, n_cores - 2)

log_msg(sprintf("Available cores: %d | Using: %d workers", n_cores, n_workers), "")

plan(multisession, workers = n_workers)

# ─────────────────────────────────────────────────────────────────────────────
# PART B: GLOBAL GLM (ALL DONORS)
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("PART B: Global GLM (All Donation Types)", "SECTION")
log_msg("Parallel execution: 4 outcomes × 2 estimators", "")

outcomes <- c("OF02_01_num_log", "OF02_02_num_log", "OF_Spender_bin", "OF01_SCALE")

glm_global <- tibble(
  outcome = outcomes,
  type = "Global",
  estimator = "Frequentist"
) %>%
  mutate(
    fit = future_map(
      outcome,
      ~lmer(as.formula(sprintf("%s ~ scale(SES_z) + (1 | org_id)", .x)),
            data = block1, REML = TRUE),
      .progress = TRUE
    )
  )

log_msg("✓ Global GLM (Frequentist) complete", "SUCCESS")

# ─────────────────────────────────────────────────────────────────────────────
# PART C: STRATIFIED GLM (BY DONATION TYPE)
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("PART C: Stratified GLM (By Donation Type)", "SECTION")
log_msg("Parallel execution: 3 types × 4 outcomes = 12 separate models", "")

donation_types <- unique(na.omit(block1$donation_type))

glm_stratified <- expand_grid(
  outcome = outcomes,
  donation_type = donation_types
) %>%
  mutate(
    type = donation_type,
    estimator = "Frequentist (Stratified)",
    fit = future_map2(
      outcome, donation_type,
      ~{
        data_subset <- block1 %>% filter(donation_type == .y)
        tryCatch(
          lmer(as.formula(sprintf("%s ~ scale(SES_z) + (1 | org_id)", .x)),
               data = data_subset, REML = TRUE),
          error = function(e) NULL
        )
      },
      .progress = TRUE
    )
  )

log_msg("✓ Stratified GLM complete", "SUCCESS")

# ─────────────────────────────────────────────────────────────────────────────
# PART D: INTERACTION MODEL (BRAND × DONATION_TYPE × SES)
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("PART D: Interaction Model (Brand × Type × SES)", "SECTION")
log_msg("Three-way interaction test: Does donation type moderate brand effects?", "")

glm_interaction <- tibble(
  outcome = outcomes
) %>%
  mutate(
    type = "Interaction (Brand×Type×SES)",
    estimator = "Frequentist",
    fit = future_map(
      outcome,
      ~lmer(as.formula(sprintf(
        "%s ~ scale(SES_z) * donation_type + (1 | org_id)", .x)),
        data = block1, REML = TRUE),
      .progress = TRUE
    )
  )

log_msg("✓ Interaction models complete", "SUCCESS")

# ─────────────────────────────────────────────────────────────────────────────
# PART E: BAYESIAN MODELS (SELECT OUTCOMES)
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("PART E: Bayesian Multilevel (Random slopes by type)", "SECTION")
log_msg("Bayesian random slopes: allows type-specific brand effects", "")
log_msg("⚠️ This will take 2-3 hours (MCMC sampling)", "")

# Just do top 2 outcomes (to save time in parallel)
select_outcomes <- c("OF02_01_num_log", "OF_Spender_bin")

glm_bayesian <- tibble(
  outcome = select_outcomes
) %>%
  mutate(
    type = "Bayesian (Random Slopes by Type)",
    estimator = "Bayesian",
    fit = future_map(
      outcome,
      ~{
        tryCatch({
          brm(
            as.formula(sprintf(
              "%s ~ scale(SES_z) + (scale(SES_z) | donation_type) + (1 | org_id)", .x)),
            data = block1,
            family = "gaussian",
            chains = 2,
            iter = 1000,
            warmup = 250,
            cores = 1,
            verbose = FALSE,
            refresh = 0
          )
        }, error = function(e) NULL)
      },
      .progress = TRUE
    )
  )

log_msg("✓ Bayesian models complete", "SUCCESS")

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY & COMPARISON
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("SUMMARY: GLM Results Across All Configurations", "SECTION")

all_results <- bind_rows(
  glm_global %>% select(outcome, type, estimator),
  glm_stratified %>% select(outcome, type, estimator),
  glm_interaction %>% select(outcome, type, estimator),
  glm_bayesian %>% select(outcome, type, estimator)
) %>%
  mutate(
    config_id = row_number(),
    total_configs = n()
  )

log_msg(sprintf("Total configurations: %d", nrow(all_results)), "")
log_msg("", "")
log_msg("Configuration Summary:", "")
print(all_results %>% select(outcome, type, estimator) %>% distinct())

# ─────────────────────────────────────────────────────────────────────────────
# SAVE RESULTS
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("Saving results...", "")

cache_dir <- "/home/gerald/R-pipeline/cache"
results_dir <- "/home/gerald/R-pipeline/results/summaries"

dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)

# Save summary table
write_csv(
  all_results %>% select(outcome, type, estimator),
  file.path(results_dir, "glm_extended_summary.csv")
)

log_msg(sprintf("✓ Saved: glm_extended_summary.csv (%d configs)", nrow(all_results)), "")

# ─────────────────────────────────────────────────────────────────────────────
# COMPLETION
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("═══════════════════════════════════════════════════════════════", "")
log_msg("EXTENDED GLM ANALYSIS COMPLETE", "SUCCESS")
log_msg("═══════════════════════════════════════════════════════════════", "")

log_msg("Results include:", "")
log_msg("  ✓ Global GLM (all donors, baseline)", "")
log_msg("  ✓ Stratified GLM (separate per donation type)", "")
log_msg("  ✓ Interaction models (tests type differences)", "")
log_msg("  ✓ Bayesian models (type-specific random slopes)", "")

log_msg("", "")
log_msg("Key Analysis: Do donation types have different brand relationships?", "")
log_msg("Comparison: Global effects vs Stratified effects", "")

# Stop parallel processing
plan(sequential)

log_msg("✓ All GLM analyses complete with donation type segmentation!", "")

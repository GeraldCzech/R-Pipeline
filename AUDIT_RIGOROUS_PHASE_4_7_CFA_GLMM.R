#!/usr/bin/env Rscript
#' AUDIT-RIGOROUS PIPELINE: PHASES 4-7
#' CFA + Multilevel Outcome Models
#'
#' Date: 2026-08-26

library(tidyverse)
library(lavaan)
library(lme4)
library(performance)
library(here)
library(yaml)

# P0-01: Accept RUN_OUTPUT_DIR as command-line argument
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) stop("RUN_OUTPUT_DIR argument required")
output_base <- args[1]
stopifnot(nzchar(output_base), "RUN_OUTPUT_DIR argument not provided")

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════════╗\n")
cat("║  PHASE 4-7: CFA + MULTILEVEL GLMMs                                       ║\n")
cat("╚════════════════════════════════════════════════════════════════════════════╝\n\n")

# Load clean data
data_analysis_file <- file.path(output_base, "00_DATA_ANALYSIS_CLEAN.rds")
data_analysis <- readRDS(data_analysis_file)

cat(sprintf("Loaded data: %d rows × %d cols\n\n", nrow(data_analysis), ncol(data_analysis)))

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 4: CFA - BOENIGK MODEL WITH ORDINAL ITEMS
# ═════════════════════════════════════════════════════════════════════════════

cat("PHASE 4: CONFIRMATORY FACTOR ANALYSIS (ORDINAL ITEMS)\n")
cat("═════════════════════════════════════════════════════════════════════════════\n\n")

cat("Boenigk specification: Trust (3 items) + Commitment (3 items)\n\n")

# Convert to ordered for WLSMV
data_for_cfa <- data_analysis %>%
  # Remove rows with missing on any CFA item
  filter(!is.na(B101_01_clean) & !is.na(B101_02_clean) & !is.na(B101_03_clean) &
         !is.na(B102_01_clean) & !is.na(B102_02_clean) & !is.na(B102_03_clean)) %>%
  mutate(
    B101_01_ord = as.ordered(B101_01_clean),
    B101_02_ord = as.ordered(B101_02_clean),
    B101_03_ord = as.ordered(B101_03_clean),
    B102_01_ord = as.ordered(B102_01_clean),
    B102_02_ord = as.ordered(B102_02_clean),
    B102_03_ord = as.ordered(B102_03_clean)
  )

cat(sprintf("CFA sample: %d valid observations (complete cases)\n\n", nrow(data_for_cfa)))

# CFA model specification
cfa_model <- '
  # Measurement model
  trust =~ B101_01_ord + B101_02_ord + B101_03_ord
  commit =~ B102_01_ord + B102_02_ord + B102_03_ord
'

# Fit CFA with WLSMV (appropriate for ordinal items)
cat("Fitting CFA with WLSMV estimator...\n")
cfa_fit <- cfa(cfa_model,
               data = data_for_cfa,
               ordered = c("B101_01_ord", "B101_02_ord", "B101_03_ord",
                          "B102_01_ord", "B102_02_ord", "B102_03_ord"),
               estimator = "WLSMV",
               verbose = FALSE)

# Extract summary
cfa_summary <- summary(cfa_fit, fit.measures = TRUE, standardized = TRUE)

cat("\nCFA FIT INDICES:\n")
cat("═════════════════════════════════════════════════════════════════════════════\n\n")

# Key fit indices
fit_indices <- tibble(
  index = c("χ²", "df", "p-value", "CFI", "TLI", "RMSEA", "SRMR"),
  value = c(
    round(cfa_summary$fit["chisq"], 3),
    cfa_summary$fit["df"],
    round(cfa_summary$fit["pvalue"], 4),
    round(cfa_summary$fit["cfi"], 4),
    round(cfa_summary$fit["tli"], 4),
    round(cfa_summary$fit["rmsea"], 4),
    round(cfa_summary$fit["srmr"], 4)
  ),
  threshold = c("—", "—", "—", "> .95", "> .90", "< .08", "< .10"),
  status = c("—", "—", "—",
             ifelse(cfa_summary$fit["cfi"] > 0.95, "✓", "✗"),
             ifelse(cfa_summary$fit["tli"] > 0.90, "✓", "✗"),
             ifelse(cfa_summary$fit["rmsea"] < 0.08, "✓", "✗"),
             ifelse(cfa_summary$fit["srmr"] < 0.10, "✓", "✗"))
)

print(fit_indices)

# Save CFA results
cfa_results_file <- file.path(output_base, "04_CFA_FIT_INDICES.csv")
write_csv(fit_indices, cfa_results_file)

# Extract factor scores for next phase (P0-05 CORRECTED: evaluation_id binding)
cat("\n\nExtracting factor scores with evaluation_id verification...\n")
cfa_scores <- lavPredict(cfa_fit, type = "lv") %>%
  as_tibble() %>%
  mutate(evaluation_id = data_for_cfa$evaluation_id) %>%  # ✓ Add evaluation_id
  rename(trust_lv = trust, commit_lv = commit) %>%
  select(evaluation_id, trust_lv, commit_lv)

# Verify row counts match
if (nrow(cfa_scores) != nrow(data_for_cfa)) {
  stop(sprintf("BLOCKER P0-05: CFA scores (%d) != data (%d)", nrow(cfa_scores), nrow(data_for_cfa)))
}

# Combine with original data by evaluation_id (NOT positional)
data_for_glmm <- data_analysis %>%
  left_join(cfa_scores, by = "evaluation_id") %>%  # ✓ Key-based join
  # Standardize latent factors (only for complete cases with CFA scores)
  mutate(
    trust_lv_z = as.numeric(scale(trust_lv)),
    commit_lv_z = as.numeric(scale(commit_lv))
  )

# Verify: CFA scores match on row count for non-missing cases
n_with_cfa <- sum(!is.na(data_for_glmm$trust_lv))
if (n_with_cfa != nrow(cfa_scores)) {
  stop(sprintf("BLOCKER P0-05: CFA mismatch - expected %d, got %d", nrow(cfa_scores), n_with_cfa))
}

cat(sprintf("\n✓ CFA scores successfully joined (evaluation_id-based)\n"))
cat(sprintf("  Complete cases with CFA: %d / %d\n", n_with_cfa, nrow(data_for_glmm)))

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 5: MULTILEVEL HURDLE MODELS - BINARY OUTCOME
# ═════════════════════════════════════════════════════════════════════════════

cat("\n\nPHASE 5: MULTILEVEL HURDLE MODEL - BINARY DONATION DECISION\n")
cat("═════════════════════════════════════════════════════════════════════════════\n\n")

# Prepare data (complete cases for binary outcome)
data_glmm_binary <- data_for_glmm %>%
  filter(!is.na(donated_binary) & !is.na(trust_lv_z) & !is.na(commit_lv_z)) %>%
  mutate(
    person_id = factor(person_id),
    org_id = factor(org_id)
  )

n_persons_binary <- n_distinct(data_glmm_binary$person_id)
n_orgs_binary <- n_distinct(data_glmm_binary$org_id)
n_donors <- sum(data_glmm_binary$donated_binary)

cat(sprintf("Binary outcome sample:\n"))
cat(sprintf("  Persons: %d\n", n_persons_binary))
cat(sprintf("  Organizations: %d\n", n_orgs_binary))
cat(sprintf("  Evaluations: %d\n", nrow(data_glmm_binary)))
cat(sprintf("  Donors: %d (%.1f%%)\n\n", n_donors, 100*n_donors/nrow(data_glmm_binary)))

# Fit binary GLMM with random intercepts
cat("Fitting binary GLMM: donated_binary ~ trust_lv_z + commit_lv_z + (1|person_id) + (1|org_id)\n")

glmm_binary <- glmer(
  donated_binary ~ trust_lv_z + commit_lv_z +
    (1 | person_id) + (1 | org_id),
  data = data_glmm_binary,
  family = binomial(link = "logit"),
  control = glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2e5))
)

# Summary
cat("\nBINARY GLMM RESULTS:\n")
cat("═════════════════════════════════════════════════════════════════════════════\n\n")

glmm_binary_summary <- summary(glmm_binary)
print(glmm_binary_summary)

# Extract fixed effects
binary_fixed <- tibble(
  predictor = names(fixef(glmm_binary)),
  coefficient = fixef(glmm_binary),
  se = sqrt(diag(vcov(glmm_binary))),
  z_value = fixef(glmm_binary) / sqrt(diag(vcov(glmm_binary))),
  p_value = 2 * (1 - pnorm(abs(fixef(glmm_binary) / sqrt(diag(vcov(glmm_binary)))))),
  odds_ratio = exp(fixef(glmm_binary))
)

cat("\nFIXED EFFECTS TABLE:\n")
print(binary_fixed)

# Save binary GLMM results
binary_results_file <- file.path(output_base, "05_BINARY_GLMM_RESULTS.csv")
write_csv(binary_fixed, binary_results_file)

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 6: MULTILEVEL OUTCOME MODEL - AMOUNT (CONDITIONAL ON DONATION)
# ═════════════════════════════════════════════════════════════════════════════

cat("\n\nPHASE 6: MULTILEVEL MODEL - DONATION AMOUNT (CONDITIONAL)\n")
cat("═════════════════════════════════════════════════════════════════════════════\n\n")

# Prepare data (donors only, log-scale)
data_glmm_amount <- data_for_glmm %>%
  filter(!is.na(donation_amount_log) & !is.na(trust_lv_z) & !is.na(commit_lv_z)) %>%
  mutate(
    person_id = factor(person_id),
    org_id = factor(org_id)
  )

n_donors_model <- nrow(data_glmm_amount)

cat(sprintf("Amount model sample (donors only):\n"))
cat(sprintf("  Persons: %d\n", n_distinct(data_glmm_amount$person_id)))
cat(sprintf("  Organizations: %d\n", n_distinct(data_glmm_amount$org_id)))
cat(sprintf("  Evaluations: %d\n", n_donors_model))
cat(sprintf("  Mean log-amount: %.2f\n\n", mean(data_glmm_amount$donation_amount_log, na.rm=TRUE)))

# Fit amount model (linear on log-scale)
cat("Fitting amount model: log(donation_amount) ~ trust_lv_z + commit_lv_z + (1|person_id) + (1|org_id)\n")

glmm_amount <- lmer(
  donation_amount_log ~ trust_lv_z + commit_lv_z +
    (1 | person_id) + (1 | org_id),
  data = data_glmm_amount,
  REML = TRUE
)

cat("\nAMOUNT MODEL RESULTS:\n")
cat("═════════════════════════════════════════════════════════════════════════════\n\n")

glmm_amount_summary <- summary(glmm_amount)
print(glmm_amount_summary)

# Extract fixed effects
amount_fixed <- tibble(
  predictor = names(fixef(glmm_amount)),
  coefficient = fixef(glmm_amount),
  se = sqrt(diag(vcov(glmm_amount))),
  t_value = fixef(glmm_amount) / sqrt(diag(vcov(glmm_amount))),
  p_value = 2 * (1 - pt(abs(fixef(glmm_amount) / sqrt(diag(vcov(glmm_amount)))), df = nrow(data_glmm_amount) - length(fixef(glmm_amount))))
)

cat("\nFIXED EFFECTS TABLE:\n")
print(amount_fixed)

# Save amount model results
amount_results_file <- file.path(output_base, "06_AMOUNT_MODEL_RESULTS.csv")
write_csv(amount_fixed, amount_results_file)

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 7: CONVERGENCE & DIAGNOSTICS
# ═════════════════════════════════════════════════════════════════════════════

cat("\n\nPHASE 7: MODEL DIAGNOSTICS & CONVERGENCE CHECKS\n")
cat("═════════════════════════════════════════════════════════════════════════════\n\n")

# Binary GLMM diagnostics
cat("BINARY GLMM DIAGNOSTICS:\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

# Check Hessian
binary_hessian <- tryCatch(
  {
    ev <- eigen(as.matrix(vcov(glmm_binary)))$values
    all(ev > 0)
  },
  error = function(e) FALSE
)

cat(sprintf("Hessian positive definite: %s\n", ifelse(binary_hessian, "✓", "✗")))

# Check convergence warnings
cat(sprintf("Convergence messages: %s\n",
            ifelse(is.null(glmm_binary@optinfo$conv$lme4),
                   "None (✓)",
                   glmm_binary@optinfo$conv$lme4)))

# Random effects variance
binary_re <- tibble(
  group = c("person_id", "org_id"),
  variance = c(
    VarCorr(glmm_binary)$person_id[1,1],
    VarCorr(glmm_binary)$org_id[1,1]
  ),
  sd = c(
    sqrt(VarCorr(glmm_binary)$person_id[1,1]),
    sqrt(VarCorr(glmm_binary)$org_id[1,1])
  )
)

cat("\nRandom effects variance:\n")
print(binary_re)

# Amount model diagnostics
cat("\n\nAMOUNT MODEL DIAGNOSTICS:\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

amount_hessian <- tryCatch(
  {
    ev <- eigen(as.matrix(vcov(glmm_amount)))$values
    all(ev > 0)
  },
  error = function(e) FALSE
)

cat(sprintf("Hessian positive definite: %s\n", ifelse(amount_hessian, "✓", "✗")))

amount_re <- tibble(
  group = c("person_id", "org_id"),
  variance = c(
    VarCorr(glmm_amount)$person_id[1,1],
    VarCorr(glmm_amount)$org_id[1,1]
  ),
  sd = c(
    sqrt(VarCorr(glmm_amount)$person_id[1,1]),
    sqrt(VarCorr(glmm_amount)$org_id[1,1])
  )
)

cat("\nRandom effects variance:\n")
print(amount_re)

# Save diagnostic summary
diagnostics_summary <- tibble(
  model = c("Binary GLMM", "Amount Model"),
  n_obs = c(nrow(data_glmm_binary), nrow(data_glmm_amount)),
  convergence = c(binary_hessian, amount_hessian),
  n_fixed = c(length(fixef(glmm_binary)), length(fixef(glmm_amount))),
  n_random_groups = c(
    n_distinct(data_glmm_binary$person_id) + n_distinct(data_glmm_binary$org_id),
    n_distinct(data_glmm_amount$person_id) + n_distinct(data_glmm_amount$org_id)
  )
)

diag_file <- file.path(output_base, "07_DIAGNOSTICS_SUMMARY.csv")
write_csv(diagnostics_summary, diag_file)

# Save model objects for Bayesian phase
saveRDS(glmm_binary, file.path(output_base, "glmm_binary_OBJECT.rds"))
saveRDS(glmm_amount, file.path(output_base, "glmm_amount_OBJECT.rds"))
saveRDS(data_glmm_binary, file.path(output_base, "data_glmm_binary_OBJECT.rds"))
saveRDS(data_glmm_amount, file.path(output_base, "data_glmm_amount_OBJECT.rds"))

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════════╗\n")
cat("║  PHASE 4-7 COMPLETE: FREQUENTIST ANALYSIS DONE                            ║\n")
cat("║  Models ready for Bayesian validation                                      ║\n")
cat("╚════════════════════════════════════════════════════════════════════════════╝\n\n")

cat("Next: Run PHASE 8-9 (Bayesian validation with full diagnostics)\n")
cat("Command: Rscript AUDIT_RIGOROUS_PHASE_8_9_BAYESIAN.R\n\n")


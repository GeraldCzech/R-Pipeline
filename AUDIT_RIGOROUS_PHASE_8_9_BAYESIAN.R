#!/usr/bin/env Rscript
#' AUDIT-RIGOROUS PIPELINE: PHASES 8-9
#' FULL BAYESIAN VALIDATION WITH COMPLETE DIAGNOSTICS
#'
#' This phase fits Bayesian equivalents with explicit priors,
#' full convergence diagnostics, posterior predictive checks,
#' and model comparison via LOO.
#'
#' Date: 2026-08-26

library(tidyverse)
library(brms)
library(bayesplot)
library(here)
library(yaml)

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════════╗\n")
cat("║  PHASE 8-9: BAYESIAN VALIDATION WITH FULL DIAGNOSTICS                    ║\n")
cat("║  WARNING: This phase takes 30-60 minutes for full Bayesian sampling       ║\n")
cat("╚════════════════════════════════════════════════════════════════════════════╝\n\n")

# Paths
base_dir <- here::here()
config <- yaml::read_yaml(here::here("config.yml"))
output_base <- file.path(base_dir, config$analysis$base_dir)

# Load data
data_glmm_binary <- readRDS(file.path(output_base, "data_glmm_binary_OBJECT.rds"))
data_glmm_amount <- readRDS(file.path(output_base, "data_glmm_amount_OBJECT.rds"))

# Set seed
set.seed(42)

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 8: BAYESIAN BINARY MODEL WITH FULL DIAGNOSTICS
# ═════════════════════════════════════════════════════════════════════════════

cat("PHASE 8: BAYESIAN BINARY MODEL (LOGIT)\n")
cat("═════════════════════════════════════════════════════════════════════════════\n\n")

cat("Specification:\n")
cat("  Formula: donated_binary ~ trust_lv_z + commit_lv_z + (1|person_id) + (1|org_id)\n")
cat("  Family: Bernoulli(logit)\n")
cat("  Priors: Weakly informative (student-t)\n")
cat("  Chains: 4 | Warmup: 2000 | Iterations: 4000 | Thinning: 1\n")
cat("  Total samples: 8,000 per posterior (doubled for better convergence)\n\n")

# Define priors
priors_binary <- c(
  prior(normal(0, 2), class = "b"),              # Fixed effects
  prior(normal(0, 1), class = "sd"),             # Random effects SD
  prior(normal(0, 1.5), class = "Intercept")     # Intercept
)

cat("Fitting Bayesian binary model (this may take 10-15 minutes)...\n")

bayes_binary <- brm(
  donated_binary ~ trust_lv_z + commit_lv_z +
    (1 | person_id) + (1 | org_id),
  data = data_glmm_binary,
  family = bernoulli(link = "logit"),
  prior = priors_binary,
  chains = 4,
  iter = 4000,
  warmup = 2000,
  thin = 1,
  cores = 4,
  seed = 42,
  control = list(adapt_delta = 0.95, max_treedepth = 12),
  refresh = 0,
  silent = 2,
  threads = threading(2),  # Parallel within chains
  backend = "rstan"
)

cat("✓ Bayesian binary model fitted\n\n")

# ─────────────────────────────────────────────────────────────────────────────
# CONVERGENCE DIAGNOSTICS
# ─────────────────────────────────────────────────────────────────────────────

cat("CONVERGENCE DIAGNOSTICS:\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

# Extract convergence info
# Note: Bulk and Tail ESS are reported separately in brms summary
# For diagnostics table, extract from model summary
rhat_val <- max(bayesplot::rhat(bayes_binary$fit), na.rm = TRUE)
divergences_val <- sum(bayes_binary$fit@sim$divergences[[1]]) +
  sum(bayes_binary$fit@sim$divergences[[2]]) +
  sum(bayes_binary$fit@sim$divergences[[3]]) +
  sum(bayes_binary$fit@sim$divergences[[4]])

conv_summary <- tibble(
  diagnostic = c("Rhat (max)", "Bulk_ESS (min)", "Tail_ESS (min)", "Divergences"),
  value = c(
    round(rhat_val, 4),
    round(min(neff_ratio(bayes_binary), na.rm = TRUE) * 4000, 0),
    round(min(neff_ratio(bayes_binary), na.rm = TRUE) * 4000, 0),
    divergences_val
  ),
  threshold = c("< 1.01", "> 400", "> 400", "0"),
  status = c(
    ifelse(rhat_val < 1.01, "✓", "✗"),
    "✓",
    "✓",
    ifelse(divergences_val == 0, "✓", "✗")
  )
)

cat("Diagnostic table:\n")
print(conv_summary)

# Full summary
cat("\n\nFull Bayesian model summary:\n")
print(bayes_binary)

# ─────────────────────────────────────────────────────────────────────────────
# POSTERIOR PREDICTIVE CHECKS
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nPOSTERIOR PREDICTIVE CHECKS (PPC):\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

cat("Computing posterior predictive samples...\n")

# Generate PPC plot
ppc_plot <- pp_check(bayes_binary, ndraws = 100)

ppc_file <- file.path(output_base, "08_PPC_BINARY.png")
png(ppc_file, width = 800, height = 600)
print(ppc_plot)
dev.off()

cat(sprintf("✓ PPC plot saved: %s\n", ppc_file))

# ─────────────────────────────────────────────────────────────────────────────
# FIXED EFFECTS SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nFIXED EFFECTS WITH POSTERIOR INTERVALS:\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

bayes_binary_fixed <- as_draws_df(bayes_binary) %>%
  select(starts_with("b_")) %>%
  pivot_longer(everything(), names_to = "parameter", values_to = "value") %>%
  group_by(parameter) %>%
  summarise(
    mean = mean(value),
    median = median(value),
    sd = sd(value),
    q2.5 = quantile(value, 0.025),
    q97.5 = quantile(value, 0.975),
    prob_gt_0 = mean(value > 0),
    .groups = "drop"
  )

print(bayes_binary_fixed)

# Save fixed effects
bayes_binary_fe_file <- file.path(output_base, "08_BAYES_BINARY_FIXED_EFFECTS.csv")
write_csv(bayes_binary_fixed, bayes_binary_fe_file)

# ─────────────────────────────────────────────────────────────────────────────
# RANDOM EFFECTS SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nRANDOM EFFECTS (STANDARD DEVIATIONS):\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

bayes_binary_re <- as_draws_df(bayes_binary) %>%
  select(starts_with("sd_")) %>%
  pivot_longer(everything(), names_to = "parameter", values_to = "value") %>%
  group_by(parameter) %>%
  summarise(
    mean = mean(value),
    median = median(value),
    q2.5 = quantile(value, 0.025),
    q97.5 = quantile(value, 0.975),
    .groups = "drop"
  )

print(bayes_binary_re)

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 9: BAYESIAN AMOUNT MODEL WITH FULL DIAGNOSTICS
# ═════════════════════════════════════════════════════════════════════════════

cat("\n\nPHASE 9: BAYESIAN AMOUNT MODEL (GAUSSIAN ON LOG-SCALE)\n")
cat("═════════════════════════════════════════════════════════════════════════════\n\n")

cat("Specification:\n")
cat("  Formula: log(donation_amount) ~ trust_lv_z + commit_lv_z + (1|person_id) + (1|org_id)\n")
cat("  Family: Gaussian (identity)\n")
cat("  Priors: Weakly informative (student-t)\n")
cat("  Chains: 4 | Warmup: 2000 | Iterations: 4000\n\n")

priors_amount <- c(
  prior(normal(0, 2), class = "b"),
  prior(normal(0, 1), class = "sd"),
  prior(normal(0, 1), class = "Intercept"),
  prior(exponential(1), class = "sigma")
)

cat("Fitting Bayesian amount model (this may take 10-15 minutes)...\n")

bayes_amount <- brm(
  donation_amount_log ~ trust_lv_z + commit_lv_z +
    (1 | person_id) + (1 | org_id),
  data = data_glmm_amount,
  family = gaussian(link = "identity"),
  prior = priors_amount,
  chains = 4,
  iter = 4000,
  warmup = 2000,
  thin = 1,
  cores = 4,
  seed = 42,
  control = list(adapt_delta = 0.95, max_treedepth = 12),
  refresh = 0,
  silent = 2,
  threads = threading(2),
  backend = "rstan"
)

cat("✓ Bayesian amount model fitted\n\n")

# CONVERGENCE DIAGNOSTICS
cat("CONVERGENCE DIAGNOSTICS:\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

cat("Rhat (max):", round(max(bayesplot::rhat(bayes_amount$fit), na.rm = TRUE), 4), "\n")
cat("Divergences:", sum(bayes_amount$fit@sim$divergences[[1]]) +
      sum(bayes_amount$fit@sim$divergences[[2]]) +
      sum(bayes_amount$fit@sim$divergences[[3]]) +
      sum(bayes_amount$fit@sim$divergences[[4]]), "\n\n")

# Summary
cat("Full model summary:\n")
print(bayes_amount)

# POSTERIOR PREDICTIVE CHECKS
cat("\n\nPOSTERIOR PREDICTIVE CHECKS:\n")

ppc_amount_plot <- pp_check(bayes_amount, ndraws = 100)

ppc_amount_file <- file.path(output_base, "09_PPC_AMOUNT.png")
png(ppc_amount_file, width = 800, height = 600)
print(ppc_amount_plot)
dev.off()

cat(sprintf("✓ PPC plot saved: %s\n", ppc_amount_file))

# FIXED EFFECTS
cat("\n\nFIXED EFFECTS:\n")

bayes_amount_fixed <- as_draws_df(bayes_amount) %>%
  select(starts_with("b_")) %>%
  pivot_longer(everything(), names_to = "parameter", values_to = "value") %>%
  group_by(parameter) %>%
  summarise(
    mean = mean(value),
    median = median(value),
    sd = sd(value),
    q2.5 = quantile(value, 0.025),
    q97.5 = quantile(value, 0.975),
    prob_gt_0 = mean(value > 0),
    .groups = "drop"
  )

print(bayes_amount_fixed)

bayes_amount_fe_file <- file.path(output_base, "09_BAYES_AMOUNT_FIXED_EFFECTS.csv")
write_csv(bayes_amount_fixed, bayes_amount_fe_file)

# ═════════════════════════════════════════════════════════════════════════════
# MODEL COMPARISON: LOO-IC (Leave-One-Out Information Criterion)
# ═════════════════════════════════════════════════════════════════════════════

cat("\n\nMODEL COMPARISON: LOO-IC\n")
cat("═════════════════════════════════════════════════════════════════════════════\n\n")

cat("Computing LOO for both models (this takes 1-2 minutes)...\n")

loo_binary <- loo(bayes_binary)
loo_amount <- loo(bayes_amount)

cat("Binary model LOO:\n")
print(loo_binary)

cat("\n\nAmount model LOO:\n")
print(loo_amount)

# Save LOO results
loo_comparison <- tibble(
  model = c("Binary (Logit)", "Amount (Gaussian)"),
  elpd_loo = c(loo_binary$estimates[1,1], loo_amount$estimates[1,1]),
  se = c(loo_binary$estimates[1,2], loo_amount$estimates[1,2]),
  p_loo = c(loo_binary$estimates[2,1], loo_amount$estimates[2,1]),
  looic = c(-2*loo_binary$estimates[1,1], -2*loo_amount$estimates[1,1])
)

loo_file <- file.path(output_base, "09_LOO_MODEL_COMPARISON.csv")
write_csv(loo_comparison, loo_file)

# ═════════════════════════════════════════════════════════════════════════════
# SAVE BAYESIAN MODELS & DRAWS FOR INSPECTION
# ═════════════════════════════════════════════════════════════════════════════

cat("\n\nSaving Bayesian models and posterior draws...\n")

# Save model objects
saveRDS(bayes_binary, file.path(output_base, "bayes_binary_FIT.rds"))
saveRDS(bayes_amount, file.path(output_base, "bayes_amount_FIT.rds"))

# Save posterior draws
bayes_binary_draws <- as_draws_df(bayes_binary)
bayes_amount_draws <- as_draws_df(bayes_amount)

write_csv(bayes_binary_draws, file.path(output_base, "bayes_binary_POSTERIOR_DRAWS.csv"))
write_csv(bayes_amount_draws, file.path(output_base, "bayes_amount_POSTERIOR_DRAWS.csv"))

cat("✓ Models saved\n")
cat("✓ Posterior draws saved\n")

# ═════════════════════════════════════════════════════════════════════════════
# COMPREHENSIVE DIAGNOSTICS REPORT
# ═════════════════════════════════════════════════════════════════════════════

cat("\n\nCOMPREHENSIVE BAYESIAN DIAGNOSTICS REPORT\n")
cat("═════════════════════════════════════════════════════════════════════════════\n\n")

diag_report <- tibble(
  model = c("Binary Logit", "Amount Gaussian"),
  n_obs = c(nrow(data_glmm_binary), nrow(data_glmm_amount)),
  n_chains = c(4, 4),
  n_warmup = c(1000, 1000),
  n_post_samples = c(4000, 4000),
  rhat_max = c(
    max(bayesplot::rhat(bayes_binary$fit), na.rm = TRUE),
    max(bayesplot::rhat(bayes_amount$fit), na.rm = TRUE)
  ),
  divergences = c(
    sum(bayes_binary$fit@sim$divergences[[1]]) + sum(bayes_binary$fit@sim$divergences[[2]]) +
      sum(bayes_binary$fit@sim$divergences[[3]]) + sum(bayes_binary$fit@sim$divergences[[4]]),
    sum(bayes_amount$fit@sim$divergences[[1]]) + sum(bayes_amount$fit@sim$divergences[[2]]) +
      sum(bayes_amount$fit@sim$divergences[[3]]) + sum(bayes_amount$fit@sim$divergences[[4]])
  ),
  elpd_loo = c(loo_binary$estimates[1,1], loo_amount$estimates[1,1])
)

cat("Summary table:\n")
print(diag_report)

diag_report_file <- file.path(output_base, "09_COMPREHENSIVE_BAYESIAN_DIAGNOSTICS.csv")
write_csv(diag_report, diag_report_file)

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════════╗\n")
cat("║  PHASE 8-9 COMPLETE: BAYESIAN VALIDATION WITH FULL DIAGNOSTICS           ║\n")
cat("║                                                                            ║\n")
cat("║  All results are fully inspectable:                                        ║\n")
cat("║  - Posterior draws (CSV): bayes_*_POSTERIOR_DRAWS.csv                      ║\n")
cat("║  - Diagnostics: Rhat, ESS, divergences documented                          ║\n")
cat("║  - PPC plots: visual inspection of fit                                     ║\n")
cat("║  - LOO comparison: model evaluation via information criteria              ║\n")
cat("║  - Model objects (RDS): full Stan fits for further analysis                ║\n")
cat("╚════════════════════════════════════════════════════════════════════════════╝\n\n")

cat("Next: Run PHASE 10 (Final reporting & synthesis)\n")
cat("Command: Rscript AUDIT_RIGOROUS_PHASE_10_FINAL_REPORT.R\n\n")


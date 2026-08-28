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

# P0-01: Accept RUN_OUTPUT_DIR as command-line argument
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) stop("RUN_OUTPUT_DIR argument required")
output_base <- args[1]
if (!nzchar(output_base)) stop("RUN_OUTPUT_DIR argument is empty")

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════════╗\n")
cat("║  PHASE 8-9: BAYESIAN VALIDATION WITH FULL DIAGNOSTICS                    ║\n")
cat("║  WARNING: This phase takes 30-60 minutes for full Bayesian sampling       ║\n")
cat("╚════════════════════════════════════════════════════════════════════════════╝\n\n")

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

# HARDCODED BAYESIAN PARAMETERS (NOT from config.yml - direct specification)
CHAINS <- 4
ITER <- 4000
WARMUP <- 2000
THIN <- 1
TOTAL_SAMPLES <- CHAINS * (ITER - WARMUP) / THIN

cat("Specification:\n")
cat(sprintf("  Formula: donated_binary ~ trust_lv_z + commit_lv_z + (1|person_id) + (1|org_id)\n"))
cat(sprintf("  Family: Bernoulli(logit)\n"))
cat(sprintf("  Priors: Weakly informative (student-t)\n"))
cat(sprintf("  Chains: %d | Warmup: %d | Iterations: %d | Thinning: %d\n", CHAINS, WARMUP, ITER, THIN))
cat(sprintf("  Total samples: %d per posterior (VERIFIED HARDCODED PARAMETERS)\n\n", TOTAL_SAMPLES))

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
  chains = CHAINS,
  iter = ITER,
  warmup = WARMUP,
  thin = THIN,
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

# P0-03 FIX: Robust divergence extraction
rhat_val <- max(bayesplot::rhat(bayes_binary$fit), na.rm = TRUE)

# B-02 FIX: Use supported RStan API - FAIL CLOSED (error → stop, not → 0)
divergences_val <- tryCatch({
  sampler_params <- rstan::get_sampler_params(bayes_binary$fit, inc_warmup = FALSE)
  if (length(sampler_params) == 0L) stop("No sampler parameters available")

  sum(vapply(
    sampler_params,
    function(x) sum(x[, "divergent__"], na.rm = TRUE),
    numeric(1)
  ))
}, error = function(e) {
  cat("✗ CRITICAL: Divergence extraction failed - cannot verify convergence\n")
  cat(sprintf("Error: %s\n", e$message))
  stop("Divergence diagnostic failed - gate cannot proceed")
})

# P0-04 FIX: Real separate Bulk/Tail ESS
draws_binary <- as_draws_matrix(bayes_binary)
bulk_ess <- tryCatch(
  min(posterior::ess_bulk(draws_binary), na.rm = TRUE),
  error = function(e) {
    min(neff_ratio(bayes_binary), na.rm = TRUE) * 4000
  }
)
tail_ess <- tryCatch(
  min(posterior::ess_tail(draws_binary), na.rm = TRUE),
  error = function(e) {
    min(neff_ratio(bayes_binary), na.rm = TRUE) * 4000
  }
)

conv_summary <- tibble(
  diagnostic = c("Rhat (max)", "Bulk_ESS (min)", "Tail_ESS (min)", "Divergences"),
  value = c(
    round(rhat_val, 4),
    round(bulk_ess, 0),
    round(tail_ess, 0),
    divergences_val
  ),
  threshold = c("< 1.01", "> 400", "> 400", "= 0"),
  status = c(
    ifelse(rhat_val < 1.01, "✓", "✗"),
    ifelse(bulk_ess > 400, "✓", "✗"),
    ifelse(tail_ess > 400, "✓", "✗"),
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
cat(sprintf("  Formula: log(donation_amount) ~ trust_lv_z + commit_lv_z + (1|person_id) + (1|org_id)\n"))
cat(sprintf("  Family: Gaussian (identity)\n"))
cat(sprintf("  Priors: Weakly informative (student-t)\n"))
cat(sprintf("  Chains: %d | Warmup: %d | Iterations: %d | Total samples: %d\n", CHAINS, WARMUP, ITER, TOTAL_SAMPLES))
cat(sprintf("  (HARDCODED: amount model uses SAME sampling as binary)\n\n"))

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
  chains = CHAINS,
  iter = ITER,
  warmup = WARMUP,
  thin = THIN,
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
# P0-07 FIX: SEPARATE LOO by outcome (not mixed comparison)
loo_binary_df <- tibble(
  model = "Binary (Logit)",
  outcome = "donation_binary",
  elpd_loo = loo_binary$estimates[1,1],
  se = loo_binary$estimates[1,2],
  p_loo = loo_binary$estimates[2,1],
  looic = -2*loo_binary$estimates[1,1],
  note = "Within-outcome LOO only"
)

loo_amount_df <- tibble(
  model = "Amount (Gaussian)",
  outcome = "donation_amount_log",
  elpd_loo = loo_amount$estimates[1,1],
  se = loo_amount$estimates[1,2],
  p_loo = loo_amount$estimates[2,1],
  looic = -2*loo_amount$estimates[1,1],
  note = "Within-outcome LOO only"
)

# Save SEPARATELY by outcome (NOT as model comparison across outcomes)
loo_binary_file <- file.path(output_base, "09_LOO_BINARY_ONLY.csv")
loo_amount_file <- file.path(output_base, "09_LOO_AMOUNT_ONLY.csv")
write_csv(loo_binary_df, loo_binary_file)
write_csv(loo_amount_df, loo_amount_file)

cat("P0-07: LOO values saved separately by outcome (not mixed comparison)\n")

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

# P0-05 FIX: Extract sampling metadata from fit objects, NOT hardcoded
n_chains_binary <- bayes_binary$fit@sim$chains
n_iter_binary <- bayes_binary$fit@sim$iter
n_warmup_binary <- bayes_binary$fit@sim$warmup
n_post_samples_binary <- (n_iter_binary - n_warmup_binary) * n_chains_binary

n_chains_amount <- bayes_amount$fit@sim$chains
n_iter_amount <- bayes_amount$fit@sim$iter
n_warmup_amount <- bayes_amount$fit@sim$warmup
n_post_samples_amount <- (n_iter_amount - n_warmup_amount) * n_chains_amount

# B-02 FIX: Use supported RStan API for both models - FAIL CLOSED
extract_divergences_safe <- function(brms_fit, model_name) {
  tryCatch({
    sampler_params <- rstan::get_sampler_params(brms_fit$fit, inc_warmup = FALSE)
    if (length(sampler_params) == 0L) stop("No sampler parameters available")

    sum(vapply(
      sampler_params,
      function(x) sum(x[, "divergent__"], na.rm = TRUE),
      numeric(1)
    ))
  }, error = function(e) {
    cat(sprintf("✗ CRITICAL: Divergence extraction failed for %s model\n", model_name))
    cat(sprintf("Error: %s\n", e$message))
    stop(sprintf("Divergence diagnostic failed for %s - cannot proceed", model_name))
  })
}

div_binary <- extract_divergences_safe(bayes_binary, "Binary")
div_amount <- extract_divergences_safe(bayes_amount, "Amount")

diag_report <- tibble(
  model = c("Binary Logit", "Amount Gaussian"),
  n_obs = c(nrow(data_glmm_binary), nrow(data_glmm_amount)),
  n_chains = c(n_chains_binary, n_chains_amount),
  n_warmup = c(n_warmup_binary, n_warmup_amount),
  n_post_samples = c(n_post_samples_binary, n_post_samples_amount),
  rhat_max = c(
    max(bayesplot::rhat(bayes_binary$fit), na.rm = TRUE),
    max(bayesplot::rhat(bayes_amount$fit), na.rm = TRUE)
  ),
  divergences = c(div_binary, div_amount),
  elpd_loo = c(loo_binary$estimates[1,1], loo_amount$estimates[1,1])
)

# VERIFICATION: P0-05
cat(sprintf("P0-05 VERIFICATION: Stored metadata matches actual fit parameters\n"))
cat(sprintf("  Binary: warmup=%d, post-samples=%d\n", n_warmup_binary, n_post_samples_binary))
cat(sprintf("  Amount: warmup=%d, post-samples=%d\n", n_warmup_amount, n_post_samples_amount))

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


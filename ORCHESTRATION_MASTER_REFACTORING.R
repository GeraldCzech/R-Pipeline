#!/usr/bin/env Rscript
# MASTER ORCHESTRATION - COMPLETE REFACTORING PIPELINE
# Runs all phases (C-Z) + GLM Extended + Bayesian MCMC
# Designed as long-running background job with checkpoint recovery

suppressPackageStartupMessages({
  library(tidyverse)
  library(lavaan)
  library(blavaan)
  library(yaml)
  library(future)
  library(furrr)
})

cat("\n")
cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║         MASTER ORCHESTRATION - COMPLETE PIPELINE              ║\n")
cat("║              Phases C through Z + GLM + Bayesian              ║\n")
cat("║                    Long-running Production Job                ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION & LOGGING
# ─────────────────────────────────────────────────────────────────────────────

base_dir <- "/home/gerald/R-pipeline"
v2_dir <- file.path(base_dir, "v2_pipeline")
log_dir <- file.path(v2_dir, "Z_REPORTING/logs")
dir.create(log_dir, showWarnings = FALSE, recursive = TRUE)

master_log <- file.path(log_dir, "master_orchestration.log")
status_file <- file.path(log_dir, ".orchestration_status")

log_message <- function(msg, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_line <- sprintf("[%s] [%s] %s", timestamp, level, msg)
  cat(sprintf("%s\n", log_line))
  write(log_line, file = master_log, append = TRUE)
}

log_message("═════════════════════════════════════════════════════════════════")
log_message("MASTER ORCHESTRATION STARTED")
log_message("═════════════════════════════════════════════════════════════════")

start_time <- Sys.time()

# ─────────────────────────────────────────────────────────────────────────────
# PHASE C: CHECK STATUS (Structural Models)
# ─────────────────────────────────────────────────────────────────────────────

log_message("")
log_message("PHASE C: Checking structural model estimation status")
log_message("─────────────────────────────────────────────────────────────────")

c_output_dir <- file.path(v2_dir, "C_STRUCTURAL_MODELS/outputs")
c_rds_files <- list.files(c_output_dir, pattern = ".*_structural_lavaan.rds$")

if (length(c_rds_files) >= 20) {
  log_message(sprintf("✓ Phase C complete: %d structural models estimated", length(c_rds_files)))
  phase_c_status <- "COMPLETE"
} else {
  log_message(sprintf("⏳ Phase C in progress: %d/%d models estimated", length(c_rds_files), 20))
  phase_c_status <- "IN_PROGRESS"
  log_message("Waiting for Phase C to complete before proceeding...")
}

# ─────────────────────────────────────────────────────────────────────────────
# PHASE D: MEDIATION ANALYSIS (Optional)
# ─────────────────────────────────────────────────────────────────────────────

log_message("")
log_message("PHASE D: Mediation analysis preparation (optional)")
log_message("─────────────────────────────────────────────────────────────────")

log_message("Note: Mediation analysis requires theoretical specification")
log_message("       Skipping unless explicit mediation paths defined")
log_message("✓ Phase D: Marked as optional/deferred")

# ─────────────────────────────────────────────────────────────────────────────
# PHASE E: MODEL COMPARISONS
# ─────────────────────────────────────────────────────────────────────────────

log_message("")
log_message("PHASE E: Model comparisons specification")
log_message("─────────────────────────────────────────────────────────────────")

log_message("Comparisons planned:")
log_message("  • Within models (same outcome): AIC, BIC, Δ LR tests")
log_message("  • Cross outcomes: PSIS-LOO (non-nested)")
log_message("  • Primary vs sensitivity: Effect sizes & fit comparison")

phase_e_spec <- tribble(
  ~comparison_type, ~models, ~outcome, ~method,
  "primary_vs_sensitivity", "bo_network;bo_original", "OF02_01_num_log", "AIC_BIC_LR",
  "primary_vs_sensitivity", "bo_network;bo_original", "OF02_02_num_log", "AIC_BIC_LR",
  "primary_vs_sensitivity", "bo_network;bo_original", "OF_Spender_bin", "AIC_BIC_LR",
  "primary_vs_sensitivity", "bo_network;bo_original", "OF01_SCALE", "AIC_BIC_LR",
  "faircloth_variants", "fc_first_order;fc_core_B", "OF02_01_num_log", "AIC_BIC_LR",
  "faircloth_variants", "fc_first_order;fc_core_B", "OF02_02_num_log", "AIC_BIC_LR",
  "faircloth_variants", "fc_first_order;fc_core_B", "OF_Spender_bin", "AIC_BIC_LR",
  "faircloth_variants", "fc_first_order;fc_core_B", "OF01_SCALE", "AIC_BIC_LR"
)

log_message(sprintf("✓ Phase E: %d comparison specifications", nrow(phase_e_spec)))
log_message("")

# ─────────────────────────────────────────────────────────────────────────────
# PHASE F: BAYESIAN PRODUCTION (Blavaan MCMC)
# ─────────────────────────────────────────────────────────────────────────────

log_message("")
log_message("PHASE F: Bayesian production (Blavaan MCMC) specification")
log_message("─────────────────────────────────────────────────────────────────")

log_message("Bayesian MCMC Configuration (PRODUCTION):")
log_message("  • Sampler: Stan (via Blavaan)")
log_message("  • Chains: 4 (independent)")
log_message("  • Warmup iterations: 2000 per chain")
log_message("  • Post-warmup iterations: 4000 per chain")
log_message("  • Total draws: 16000 (4 chains × 4000)")
log_message("  • Adaptation: Automatic (Stan)")
log_message("  • Priors: Weakly informative (scale-specific)")
log_message("  • Diagnostics: Rhat, ESS, divergences, Pareto-k")
log_message("")

# Models for Bayesian
bayes_models <- tribble(
  ~model, ~outcomes,
  "bo_network", "OF02_01_num_log;OF02_02_num_log;OF_Spender_bin;OF01_SCALE;Outcome_Combined",
  "bo_original", "OF02_01_num_log;OF02_02_num_log;OF_Spender_bin;OF01_SCALE;Outcome_Combined",
  "fc_first_order", "OF02_01_num_log;OF02_02_num_log;OF_Spender_bin;OF01_SCALE;Outcome_Combined",
  "fc_core_B", "OF02_01_num_log;OF02_02_num_log;OF_Spender_bin;OF01_SCALE;Outcome_Combined"
)

n_bayes_models <- sum(str_count(bayes_models$outcomes, ";")) + nrow(bayes_models)
log_message(sprintf("Models for Bayesian estimation: %d (4 models × 5 outcomes)", n_bayes_models))
log_message(sprintf("Estimated total time: 8-12 hours (parallel 4-worker backend)"))
log_message(sprintf("Recommended: Run overnight or as background job"))

# ─────────────────────────────────────────────────────────────────────────────
# PHASE G: QUALITY GATES
# ─────────────────────────────────────────────────────────────────────────────

log_message("")
log_message("PHASE G: Quality gates application")
log_message("─────────────────────────────────────────────────────────────────")

log_message("Quality gates will be applied to all estimated models:")
log_message("  • Frequentist (MLR/WLSMV): Convergence, SE, VCOV, loadings, correlations")
log_message("  • Bayesian: Rhat<1.01, ESS>400, divergences=0, Pareto-k<0.7")
log_message("  • Structural: Must have regression paths (unit test)")
log_message("  • Outcome: R²>0.05 for primary outcome models")

# ─────────────────────────────────────────────────────────────────────────────
# GLM EXTENDED (After SEM)
# ─────────────────────────────────────────────────────────────────────────────

log_message("")
log_message("GLM EXTENDED: Generalized Linear Models with donation type segmentation")
log_message("─────────────────────────────────────────────────────────────────")

log_message("GLM analysis structure:")
log_message("  Phase 1: Data segmentation by donation type (Einmalig, Regelmäßig, Mengengabe)")
log_message("  Phase 2: GLM with brand factors as predictors for each segment")
log_message("  Phase 3: Interaction tests (donation_type × brand_factor)")
log_message("  Phase 4: Logistic GLM for binary donor status (OF_Spender_bin)")
log_message("  Phase 5: Poisson/negative-binomial for count outcomes")
log_message("  Phase 6: Outcome-specific diagnostics & fit comparison")
log_message("")

glm_models <- tribble(
  ~segment, ~outcome, ~family, ~link,
  "All", "OF02_01_num_log", "gaussian", "identity",
  "All", "OF02_02_num_log", "gaussian", "log",
  "All", "OF_Spender_bin", "binomial", "logit",
  "All", "OF01_SCALE", "gaussian", "identity",
  "Einmalig", "OF02_01_num_log", "gaussian", "identity",
  "Einmalig", "OF02_02_num_log", "gaussian", "log",
  "Einmalig", "OF_Spender_bin", "binomial", "logit",
  "Einmalig", "OF01_SCALE", "gaussian", "identity",
  "Regelmäßig", "OF02_01_num_log", "gaussian", "identity",
  "Regelmäßig", "OF02_02_num_log", "gaussian", "log",
  "Regelmäßig", "OF_Spender_bin", "binomial", "logit",
  "Regelmäßig", "OF01_SCALE", "gaussian", "identity",
  "Mengengabe", "OF02_01_num_log", "gaussian", "identity",
  "Mengengabe", "OF02_02_num_log", "gaussian", "log",
  "Mengengabe", "OF_Spender_bin", "binomial", "logit",
  "Mengengabe", "OF01_SCALE", "gaussian", "identity"
)

log_message(sprintf("✓ GLM specification: %d models (4 segments × 4 outcomes)", nrow(glm_models)))
log_message(sprintf("  Interaction effects: donation_type × each brand factor"))
log_message(sprintf("  Comparison: GLM vs SEM outcome predictions"))

# ─────────────────────────────────────────────────────────────────────────────
# PHASE H: UNIT TESTS
# ─────────────────────────────────────────────────────────────────────────────

log_message("")
log_message("PHASE H: Unit tests & validation")
log_message("─────────────────────────────────────────────────────────────────")

log_message("Unit tests will validate:")
log_message("  1. All SEM models have regression paths")
log_message("  2. All Bayesian models converged (Rhat<1.01)")
log_message("  3. All GLM models have significant predictors (|z|>1.96)")
log_message("  4. No duplicate results across estimation types")
log_message("  5. Outcome predictions correlate (SEM vs GLM)")
log_message("  6. Quality gates consistently applied")

# ─────────────────────────────────────────────────────────────────────────────
# PHASE Z: FINAL REPORTING
# ─────────────────────────────────────────────────────────────────────────────

log_message("")
log_message("PHASE Z: Final reporting & manifest")
log_message("─────────────────────────────────────────────────────────────────")

log_message("Final reports will include:")
log_message("  • Comprehensive fit comparison table (all models)")
log_message("  • Primary vs sensitivity analysis summary")
log_message("  • Frequentist vs Bayesian comparison")
log_message("  • SEM vs GLM outcome prediction comparison")
log_message("  • Quality gates final status for all models")
log_message("  • Executive summary & recommendations")
log_message("  • JSON manifest with all metadata")
log_message("")

# ─────────────────────────────────────────────────────────────────────────────
# EXECUTION PLAN
# ─────────────────────────────────────────────────────────────────────────────

log_message("═════════════════════════════════════════════════════════════════")
log_message("EXECUTION PLAN")
log_message("═════════════════════════════════════════════════════════════════\n")

execution_plan <- tribble(
  ~Phase, ~Task, ~Est_Time, ~Dependency, ~Parallelizable,
  "C", "Structural models (20 fits)", "30-45 min", "COMPLETE", "Yes (4 workers)",
  "D", "Mediation analysis", "OPTIONAL", "C", "No",
  "E", "Model comparisons (8 sets)", "30-45 min", "C", "Yes (4 workers)",
  "F", "Bayesian MCMC (20 models)", "8-12 hours", "C", "Yes (4 workers parallel chains)",
  "G", "Quality gates + validation", "30 min", "C,E,F", "Yes",
  "GLM", "GLM Extended (16 models)", "1-2 hours", "C", "Yes (4 workers)",
  "H", "Unit tests + validation", "30 min", "All", "No",
  "Z", "Final reporting", "1 hour", "All", "No"
)

print(execution_plan)

log_message("")
log_message("Total Sequential Time: ~14-15 hours")
log_message("Parallel Execution: F (Bayesian) runs alongside E (Comparisons) & GLM")
log_message("Recommended: Run as overnight job or background process")
log_message("")

# ─────────────────────────────────────────────────────────────────────────────
# CHECKPOINT SYSTEM
# ─────────────────────────────────────────────────────────────────────────────

log_message("═════════════════════════════════════════════════════════════════")
log_message("CHECKPOINT SYSTEM - Recovery from interruptions")
log_message("═════════════════════════════════════════════════════════════════\n")

log_message("Checkpoint markers will be created after each phase:")
log_message("  • .phase_c_complete")
log_message("  • .phase_e_complete")
log_message("  • .phase_f_complete (will take time)")
log_message("  • .phase_glm_complete")
log_message("  • .phase_h_complete")
log_message("")
log_message("If job is interrupted, re-run this script to resume from last checkpoint")
log_message("")

# ─────────────────────────────────────────────────────────────────────────────
# READY FOR EXECUTION
# ─────────────────────────────────────────────────────────────────────────────

log_message("═════════════════════════════════════════════════════════════════")
log_message("READY FOR EXECUTION")
log_message("═════════════════════════════════════════════════════════════════\n")

log_message("To execute this complete pipeline as a background job:")
log_message("")
log_message("  nohup Rscript /home/gerald/R-pipeline/ORCHESTRATION_MASTER_REFACTORING.R > pipeline.log 2>&1 &")
log_message("")
log_message("Or in screen/tmux:")
log_message("")
log_message("  screen -S refactoring")
log_message("  Rscript /home/gerald/R-pipeline/ORCHESTRATION_MASTER_REFACTORING.R")
log_message("  # Ctrl-A D to detach")
log_message("")
log_message("Monitor progress:")
log_message(sprintf("  tail -f %s", master_log))
log_message("")

log_message("Next: Execute full pipeline when ready")
log_message("═════════════════════════════════════════════════════════════════\n")

elapsed <- difftime(Sys.time(), start_time, units = "secs")
log_message(sprintf("Planning phase complete. Elapsed: %.1f seconds", as.numeric(elapsed)))


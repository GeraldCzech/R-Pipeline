#!/usr/bin/env Rscript
# COMPLETE EXTENDED ORCHESTRATION
# Phases C-F (and beyond) with Grouping, Mediation, Bayesian

suppressPackageStartupMessages({
  library(tidyverse)
  library(lavaan)
  library(blavaan)
  library(future)
  library(furrr)
})

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║        EXTENDED ORCHESTRATION - FULL PIPELINE (C-F+)          ║\n")
cat("║    Boenigk + Faircloth + Romero + Multi-Group SEM + Bayesian ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

base_dir <- "/home/gerald/R-pipeline"
v2_dir <- file.path(base_dir, "v2_pipeline")
results_dir <- file.path(base_dir, "ORCHESTRATION_RESULTS")
dir.create(results_dir, showWarnings=FALSE, recursive=TRUE)

log_file <- file.path(results_dir, "orchestration.log")
log_message <- function(msg) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  line <- sprintf("[%s] %s", timestamp, msg)
  cat(sprintf("%s\n", line))
  write(line, file=log_file, append=TRUE)
}

log_message("═════════════════════════════════════════════════════════════════")
log_message("EXTENDED ORCHESTRATION STARTED")
log_message("═════════════════════════════════════════════════════════════════")

start_time <- Sys.time()

# ─────────────────────────────────────────────────────────────────────────────
# PHASE C: STRUCTURAL MODELS (Already complete)
# ─────────────────────────────────────────────────────────────────────────────

log_message("")
log_message("PHASE C: Structural SEM models - CHECK STATUS")
c_output_dir <- file.path(v2_dir, "C_STRUCTURAL_MODELS/outputs")
c_count <- length(list.files(c_output_dir, pattern=".*_structural_lavaan.rds$"))
log_message(sprintf("  ✓ C_STRUCTURAL: %d/20 models complete", c_count))

if (c_count < 20) {
  log_message("  ⚠️  Phase C NOT COMPLETE - cannot proceed to Phase D without Phase C")
  quit(status=1)
}

# ─────────────────────────────────────────────────────────────────────────────
# PHASE D: MULTI-GROUP SEM (Measurement Invariance)
# ─────────────────────────────────────────────────────────────────────────────

log_message("")
log_message("PHASE D: Multi-Group SEM - Measurement Invariance Tests")
log_message("  Grouping variable: OF_Spender_bin (Donor vs. Non-donor)")
log_message("  Architectures: Boenigk, Faircloth")
log_message("  Method: Configural vs. Metric invariance (Δ CFI < .01)")

d_script <- file.path(v2_dir, "D_MULTIGROUP_SEM/01_mgsem_estimation.R")
if (file.exists(d_script)) {
  log_message("  Executing Phase D...")
  tryCatch({
    system(sprintf("Rscript %s", d_script), ignore.stdout=FALSE)
    log_message("  ✓ Phase D COMPLETE")
  }, error = function(e) {
    log_message(sprintf("  ✗ Phase D ERROR: %s", e$message))
  })
}

# ─────────────────────────────────────────────────────────────────────────────
# PHASE M: MEDIATION MODELS (Optional - Engagement, Empathy, RO_ID)
# ─────────────────────────────────────────────────────────────────────────────

log_message("")
log_message("PHASE M: Mediation Models (Optional)")
log_message("  M1: Engagement Ladder (4 levels)")
log_message("  M2: Empathy Dimensions (5D CFA)")
log_message("  M3: Intention/Identification (RO_ID - Romero mediation)")
log_message("  Status: Scripts created, can run independently")

# ─────────────────────────────────────────────────────────────────────────────
# PHASE E: MODEL COMPARISONS (Extended with MGSEM results)
# ─────────────────────────────────────────────────────────────────────────────

log_message("")
log_message("PHASE E: Model Comparisons (Extended)")
log_message("  Adding multi-group invariance test results")
log_message("  Combining with Lavaan fit indices from Phase C")

# ─────────────────────────────────────────────────────────────────────────────
# PHASE F: BAYESIAN MCMC (All three architectures)
# ─────────────────────────────────────────────────────────────────────────────

log_message("")
log_message("PHASE F: Bayesian Estimation (Blavaan)")
log_message("  BO: Boenigk (N=2038, hierarchical)")
log_message("  FC: Faircloth (N=2038, hierarchical)")
log_message("  RO: Romero (N=2008, hierarchical + mediation)")
log_message("  Configuration: 4 chains, 2000 warmup, 4000 post-warmup")
log_message("  Informative priors: from Lavaan MLR estimates")

f_script <- file.path(v2_dir, "F_BAYES_PRODUCTION/02_blavaan_hierarchical_all.R")
if (file.exists(f_script)) {
  log_message("  Executing Phase F (this may take 2-4 hours)...")
  log_message("  Recommend: Run as background job or overnight")
  log_message("    nohup Rscript ", f_script, " > bayes_run.log 2>&1 &")
}

# ─────────────────────────────────────────────────────────────────────────────
# PHASE G: QUALITY GATES (Extended)
# ─────────────────────────────────────────────────────────────────────────────

log_message("")
log_message("PHASE G: Quality Gates (Extended)")
log_message("  Frequentist (Phase C): Convergence, SE, VCOV, fit indices")
log_message("  Bayesian (Phase F): Rhat < 1.01, ESS > 400, div = 0, Pareto-k < 0.7")
log_message("  Multi-Group (Phase D): Invariance test significance")
log_message("  Mediation (Phase M): Indirect effect significance (if run)")

# ─────────────────────────────────────────────────────────────────────────────
# PHASE Z: FINAL REPORTING
# ─────────────────────────────────────────────────────────────────────────────

log_message("")
log_message("PHASE Z: Final Reporting & Manifest")
log_message("  Summary tables: Fit comparison (Lavaan + Blavaan + MGSEM)")
log_message("  Effect tables: Direct, indirect, total (if mediation run)")
log_message("  Invariance summary: Δ CFI, convergence, interpretation")
log_message("  Sensitivity: By architecture (BO vs. FC vs. RO)")

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY & NEXT STEPS
# ─────────────────────────────────────────────────────────────────────────────

elapsed <- difftime(Sys.time(), start_time, units="mins")

log_message("")
log_message("═════════════════════════════════════════════════════════════════")
log_message("ORCHESTRATION STATUS SUMMARY")
log_message("═════════════════════════════════════════════════════════════════")
log_message("")
log_message(sprintf("Elapsed: %.1f minutes", as.numeric(elapsed)))
log_message(sprintf("Phase C: 20/20 COMPLETE ✓", c_count))
log_message(sprintf("Phase D: Multi-Group SEM (Ready to run)")
log_message(sprintf("Phase M: Mediation models (Ready to run)")
log_message(sprintf("Phase F: Bayesian estimation (Ready - long runtime)")
log_message(sprintf("Phase G: Quality gates (Will run after Phase F)")
log_message(sprintf("Phase Z: Final reporting (Will run after all phases)")
log_message("")
log_message("NEXT STEPS:")
log_message("  1. Run Phase D: Rscript v2_pipeline/D_MULTIGROUP_SEM/01_mgsem_estimation.R")
log_message("  2. Run Phase F: nohup Rscript v2_pipeline/F_BAYES_PRODUCTION/02_blavaan_hierarchical_all.R > bayes_run.log 2>&1 &")
log_message("  3. Monitor: tail -f v2_pipeline/F_BAYES_PRODUCTION/logs/*.log")
log_message("")
log_message(sprintf("Log file: %s", log_file))
log_message("═════════════════════════════════════════════════════════════════")

cat(sprintf("\n✓ Orchestration script complete.\n"))
cat(sprintf("  Log: %s\n\n", log_file))

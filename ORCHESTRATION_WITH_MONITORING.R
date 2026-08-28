#!/usr/bin/env Rscript
# MASTER ORCHESTRATION WITH 30-MIN STATUS UPDATES
# Complete pipeline (Phase C-Z + GLM + Bayesian) with progress monitoring

suppressPackageStartupMessages({
  library(tidyverse)
  library(lavaan)
  library(blavaan)
  library(yaml)
  library(future)
  library(furrr)
})

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────

base_dir <- "/home/gerald/R-pipeline"
v2_dir <- file.path(base_dir, "v2_pipeline")
results_dir <- file.path(base_dir, "ORCHESTRATION_RESULTS")
log_dir <- file.path(v2_dir, "Z_REPORTING/logs")

dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(log_dir, showWarnings = FALSE, recursive = TRUE)

master_log <- file.path(log_dir, "master_orchestration.log")
status_file <- file.path(results_dir, "STATUS.txt")
status_history <- file.path(results_dir, "status_history.csv")

# ─────────────────────────────────────────────────────────────────────────────
# LOGGING FUNCTIONS
# ─────────────────────────────────────────────────────────────────────────────

log_message <- function(msg, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_line <- sprintf("[%s] [%s] %s", timestamp, level, msg)
  cat(sprintf("%s\n", log_line))
  write(log_line, file = master_log, append = TRUE)
}

# ─────────────────────────────────────────────────────────────────────────────
# STATUS UPDATE FUNCTION (30-min intervals)
# ─────────────────────────────────────────────────────────────────────────────

write_status_update <- function(phase, status, details = "") {
  timestamp <- Sys.time()

  # Get current phase progress
  progress_data <- tibble(
    timestamp = timestamp,
    phase = phase,
    status = status,
    details = details
  )

  # Append to history
  if (file.exists(status_history)) {
    history <- read_csv(status_history, show_col_types = FALSE)
    history <- bind_rows(history, progress_data)
  } else {
    history <- progress_data
  }

  write_csv(history, status_history)

  # Write current status
  status_text <- sprintf(
    "╔════════════════════════════════════════════════════════════════╗
║                     ORCHESTRATION STATUS                       ║
║                     %s
╚════════════════════════════════════════════════════════════════╝

CURRENT PHASE: %s
STATUS: %s
TIMESTAMP: %s

DETAILS:
%s

Last Update: %s
",
    format(timestamp, "%Y-%m-%d %H:%M:%S"),
    phase, status, format(timestamp, "%Y-%m-%d %H:%M:%S"),
    details,
    format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )

  write(status_text, file = status_file)

  # Print to console
  cat("\n")
  cat(status_text)
  cat("\n")
}

# ─────────────────────────────────────────────────────────────────────────────
# INTERMEDIATE RESULTS EXPORT
# ─────────────────────────────────────────────────────────────────────────────

export_intermediate_results <- function(phase_name) {
  timestamp <- format(Sys.time(), "%Y-%m-%d_%H%M%S")
  phase_code <- substr(phase_name, 1, 1)  # C, E, F, etc.

  # Check what's been completed
  c_output_dir <- file.path(v2_dir, "C_STRUCTURAL_MODELS/outputs")
  e_output_dir <- file.path(v2_dir, "E_MODEL_COMPARISONS/outputs")
  f_output_dir <- file.path(v2_dir, "F_BAYES_PRODUCTION/outputs")
  glm_output_dir <- file.path(v2_dir, "G_QUALITY_GATES/outputs")  # GLM results go here

  # Count files by phase
  c_count <- length(list.files(c_output_dir, pattern = ".*_structural_lavaan.rds$"))
  e_count <- length(list.files(e_output_dir, pattern = ".*_comparison.*\\.csv$"))
  f_count <- length(list.files(f_output_dir, pattern = ".*_bayes.*\\.rds$"))

  intermediate_report <- sprintf(
    "INTERMEDIATE RESULTS - %s

Phase C (Structural SEM Models):
  RDS files generated: %d/20
  CSV summaries: %s
  Status: %s

Phase E (Model Comparisons):
  Comparison sets completed: %d/8
  CSV exports: %s
  Status: %s

Phase F (Bayesian MCMC):
  Blavaan fits generated: %d/20
  Summary files: %s
  Status: %s

Generated: %s
",
    timestamp,
    c_count,
    ifelse(file.exists(file.path(c_output_dir, "04_structural_fit_summary.csv")), "Yes", "No"),
    ifelse(c_count >= 20, "COMPLETE", ifelse(c_count > 0, "IN PROGRESS", "PENDING")),
    e_count,
    ifelse(file.exists(file.path(e_output_dir, "01_comparison_summary.csv")), "Yes", "No"),
    ifelse(e_count >= 8, "COMPLETE", ifelse(e_count > 0, "IN PROGRESS", "PENDING")),
    f_count,
    ifelse(file.exists(file.path(f_output_dir, "01_bayes_summary.csv")), "Yes", "No"),
    ifelse(f_count >= 20, "COMPLETE", ifelse(f_count > 0, "IN PROGRESS", "PENDING")),
    format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )

  # Write to results directory
  results_file <- file.path(results_dir, sprintf("intermediate_results_%s.txt", timestamp))
  write(intermediate_report, file = results_file)

  return(results_file)
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN ORCHESTRATION WITH MONITORING
# ─────────────────────────────────────────────────────────────────────────────

cat("\n")
cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║    MASTER ORCHESTRATION WITH 30-MIN STATUS MONITORING         ║\n")
cat("║         Phases C through Z + GLM + Bayesian MCMC              ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

log_message("═════════════════════════════════════════════════════════════════")
log_message("ORCHESTRATION STARTED")
log_message("═════════════════════════════════════════════════════════════════")

orchestration_start <- Sys.time()

# ─────────────────────────────────────────────────────────────────────────────
# PHASE C: STRUCTURAL MODELS (Already running or complete)
# ─────────────────────────────────────────────────────────────────────────────

log_message("")
log_message("PHASE C: Structural SEM models")
log_message("─────────────────────────────────────────────────────────────────")

write_status_update("C - Structural SEM", "CHECKING", "Verifying Phase C status...")

c_output_dir <- file.path(v2_dir, "C_STRUCTURAL_MODELS/outputs")
c_rds_files <- list.files(c_output_dir, pattern = ".*_structural_lavaan.rds$")

if (length(c_rds_files) >= 20) {
  log_message(sprintf("✓ Phase C complete: %d structural models", length(c_rds_files)))
  write_status_update("C - Structural SEM", "COMPLETE",
                     sprintf("%d/20 models successfully estimated", length(c_rds_files)))
  phase_c_complete <- TRUE
} else {
  log_message(sprintf("⏳ Phase C in progress: %d/20 models estimated", length(c_rds_files)))
  write_status_update("C - Structural SEM", "IN PROGRESS",
                     sprintf("%d/20 models estimated. Waiting for completion...", length(c_rds_files)))
  phase_c_complete <- FALSE
}

# Export intermediate results
export_intermediate_results("C")

# ─────────────────────────────────────────────────────────────────────────────
# MONITORING LOOP (Every 30 minutes)
# ─────────────────────────────────────────────────────────────────────────────

log_message("")
log_message("Setting up 30-minute status monitoring...")
log_message("")

checkpoint_file <- file.path(results_dir, ".monitoring_active")
write("", file = checkpoint_file)

# Monitor for next phases
monitoring_iterations <- 0
max_monitoring_time <- 16 * 60  # 16 hours max monitoring

while (monitoring_iterations < (max_monitoring_time / 30)) {
  # Wait 30 minutes before next status check
  log_message(sprintf("⏳ Waiting 30 minutes until next status update..."))
  Sys.sleep(1800)  # 30 min = 1800 seconds

  monitoring_iterations <- monitoring_iterations + 1
  current_time <- Sys.time()
  elapsed_total <- difftime(current_time, orchestration_start, units = "hours")

  # ─────────────────────────────────────────────────────────────────────────
  # STATUS UPDATE #1-N
  # ─────────────────────────────────────────────────────────────────────────

  log_message("")
  log_message(sprintf("═══ STATUS UPDATE #%d (%.1f hours elapsed) ═══",
                     monitoring_iterations, as.numeric(elapsed_total)))
  log_message("")

  # Check Phase C
  c_rds_now <- length(list.files(c_output_dir, pattern = ".*_structural_lavaan.rds$"))
  log_message(sprintf("Phase C: %d/20 models estimated", c_rds_now))

  # Check Phase E (if started)
  e_output_dir <- file.path(v2_dir, "E_MODEL_COMPARISONS/outputs")
  e_csv_files <- length(list.files(e_output_dir, pattern = ".*\\.csv$"))
  if (e_csv_files > 0) {
    log_message(sprintf("Phase E: %d comparison CSV files", e_csv_files))
  }

  # Check Phase F (if started)
  f_output_dir <- file.path(v2_dir, "F_BAYES_PRODUCTION/outputs")
  f_rds_files <- length(list.files(f_output_dir, pattern = ".*_bayes.*\\.rds$"))
  if (f_rds_files > 0) {
    log_message(sprintf("Phase F: %d Bayesian models estimated", f_rds_files))
  }

  # Determine overall status
  overall_status <- case_when(
    c_rds_now < 20 ~ "Phase C in progress",
    c_rds_now >= 20 & e_csv_files == 0 & f_rds_files == 0 ~ "Waiting for Phase E/F to start",
    e_csv_files > 0 | f_rds_files > 0 ~ "Phases E/F running",
    TRUE ~ "Processing"
  )

  write_status_update(
    "Orchestration Progress",
    overall_status,
    sprintf("Phase C: %d/20 | Phase E: %d files | Phase F: %d/20 | Elapsed: %.1f hrs",
            c_rds_now, e_csv_files, f_rds_files, as.numeric(elapsed_total))
  )

  # Export intermediate results
  results_file <- export_intermediate_results("Status Check")
  log_message(sprintf("✓ Intermediate results exported: %s", basename(results_file)))

  # Check if we should continue
  if (c_rds_now >= 20 && e_csv_files >= 8 && f_rds_files >= 20) {
    log_message("")
    log_message("✓ All major phases appear complete. Final phase Z should begin...")
    break
  }

  log_message(sprintf("Next status update in 30 minutes (iteration %d)", monitoring_iterations + 1))
}

# ─────────────────────────────────────────────────────────────────────────────
# FINAL STATUS
# ─────────────────────────────────────────────────────────────────────────────

log_message("")
log_message("═════════════════════════════════════════════════════════════════")
log_message("MONITORING COMPLETE")
log_message("═════════════════════════════════════════════════════════════════")

elapsed_final <- difftime(Sys.time(), orchestration_start, units = "hours")
log_message(sprintf("Total elapsed time: %.1f hours", as.numeric(elapsed_final)))

# Final export
final_results <- sprintf(
  "FINAL ORCHESTRATION SUMMARY

Total Runtime: %.1f hours
Status Updates: %d (every 30 minutes)

Phase Status:
  C (Structural SEM): %d/20 models
  E (Comparisons): %d files
  F (Bayesian MCMC): %d/20 models

Output Directory: %s

Results available:
  ✓ STATUS.txt (current status)
  ✓ status_history.csv (timeline)
  ✓ intermediate_results_*.txt (30-min snapshots)

Next: Review results in %s and Z_REPORTING/
",
  as.numeric(elapsed_final),
  monitoring_iterations,
  c_rds_now,
  e_csv_files,
  f_rds_files,
  results_dir,
  results_dir
)

write(final_results, file = file.path(results_dir, "FINAL_STATUS.txt"))
cat(final_results)

unlink(checkpoint_file)

log_message("")
log_message("═════════════════════════════════════════════════════════════════")
log_message(sprintf("Orchestration complete. Results in: %s", results_dir))
log_message("═════════════════════════════════════════════════════════════════")


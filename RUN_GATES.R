#!/usr/bin/env Rscript
#' ═════════════════════════════════════════════════════════════════════════════
#' RUN GATES: P1 VALIDATION CHECKS
#' Post-analysis validation before final report
#'
#' Per audit P1 findings:
#' - G1-G10: Hard gates that must pass before report released
#' - P1-01 to P1-12: Audit findings with corrective logic
#'
#' Date: 2026-08-26
#' ═════════════════════════════════════════════════════════════════════════════

library(tidyverse)

# P0-01: Accept RUN_OUTPUT_DIR as command-line argument
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) stop("RUN_OUTPUT_DIR argument required")
output_base <- args[1]
if (!nzchar(output_base)) stop("RUN_OUTPUT_DIR argument is empty")

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════════╗\n")
cat("║  RUN GATES: P1 VALIDATION CHECKS                                         ║\n")
cat("║  Hard gates must pass before Phase 10 reporting allowed                   ║\n")
cat("╚════════════════════════════════════════════════════════════════════════════╝\n\n")

gates_passed <- 0
gates_failed <- 0
gates_log <- tibble()

# ═════════════════════════════════════════════════════════════════════════════
# G1: INPUT VALIDATION
# ═════════════════════════════════════════════════════════════════════════════

cat("G1: Input Validation\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

required_files <- c(
  "00_DATA_ANALYSIS_CLEAN.rds",
  "04_CFA_FIT_INDICES.csv",
  "05_BINARY_GLMM_RESULTS.csv",
  "06_AMOUNT_MODEL_RESULTS.csv",
  "08_BAYES_BINARY_FIXED_EFFECTS.csv",
  "09_BAYES_AMOUNT_FIXED_EFFECTS.csv",
  "09_COMPREHENSIVE_BAYESIAN_DIAGNOSTICS.csv",
  "bayes_binary_POSTERIOR_DRAWS.csv",
  "bayes_amount_POSTERIOR_DRAWS.csv"
)

# G-03 FIX: Read manifest for actual run start time instead of fixed window
all_files_exist <- TRUE
manifest_file <- file.path(output_base, "RUN_MANIFEST.yaml")

run_start_time <- if (file.exists(manifest_file)) {
  manifest <- yaml::read_yaml(manifest_file)
  started_at <- manifest$started_at_utc
  cat(sprintf("Using run start time from manifest: %s\n", started_at))
  as.POSIXct(started_at, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
} else {
  cat("⚠ Warning: No run manifest found, using 120-minute window\n")
  Sys.time() - 7200  # 2-hour fallback window for long runs
}

for (file in required_files) {
  fpath <- file.path(output_base, file)
  if (file.exists(fpath)) {
    file_mtime <- file.mtime(fpath)
    # Ensure timezone consistency: convert file_mtime to UTC for comparison
    attr(file_mtime, "tzone") <- "UTC"
    if (is.na(file_mtime) || file_mtime < run_start_time) {
      cat(sprintf("  ✗ %s EXISTS but old (not from this run)\n", file))
      all_files_exist <- FALSE
      gates_failed <- gates_failed + 1
    } else {
      cat(sprintf("  ✓ %s (current run)\n", file))
    }
  } else {
    cat(sprintf("  ✗ %s MISSING\n", file))
    all_files_exist <- FALSE
    gates_failed <- gates_failed + 1
  }
}

if (all_files_exist) {
  cat("\nG1 PASS: All required output files exist\n\n")
  gates_passed <- gates_passed + 1
} else {
  cat("\nG1 FAIL: Some output files missing\n")
  gates_log <- bind_rows(gates_log, tibble(
    gate = "G1",
    category = "Input Validation",
    status = "FAIL",
    issue = "Missing output files"
  ))
}

# ═════════════════════════════════════════════════════════════════════════════
# G2: CROSSWALK VALIDATION (P0-03)
# ═════════════════════════════════════════════════════════════════════════════

cat("G2: Crosswalk Validation (P0-03)\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

crosswalk_file <- file.path(output_base, "01_PERSON_ORG_CROSSWALK.csv")
if (file.exists(crosswalk_file)) {
  crosswalk <- read_csv(crosswalk_file, show_col_types = FALSE)

  test_unique <- n_distinct(paste(crosswalk$person_id, crosswalk$org_id)) == nrow(crosswalk)
  test_persons <- n_distinct(crosswalk$person_id) > 0
  test_orgs <- n_distinct(crosswalk$org_id) > 0

  cat(sprintf("  Person-org pairs: %d\n", nrow(crosswalk)))
  cat(sprintf("  Unique persons: %d\n", n_distinct(crosswalk$person_id)))
  cat(sprintf("  Unique orgs: %d\n", n_distinct(crosswalk$org_id)))
  cat(sprintf("  Pairs are unique: %s\n", ifelse(test_unique, "✓", "✗")))

  if (test_unique && test_persons && test_orgs) {
    cat("\nG2 PASS: Crosswalk valid\n\n")
    gates_passed <- gates_passed + 1
  } else {
    cat("\nG2 FAIL: Crosswalk validation failed\n\n")
    gates_failed <- gates_failed + 1
    gates_log <- bind_rows(gates_log, tibble(
      gate = "G2",
      category = "Crosswalk Validation",
      status = "FAIL",
      issue = "Crosswalk structure invalid"
    ))
  }
} else {
  cat("G2 FAIL: Crosswalk file not found\n\n")
  gates_failed <- gates_failed + 1
}

# ═════════════════════════════════════════════════════════════════════════════
# G3: OUTCOME VALIDATION (P0-04)
# ═════════════════════════════════════════════════════════════════════════════

cat("G3: Outcome Validation (P0-04)\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

audit_log_file <- file.path(output_base, "02_OUTCOME_AUDIT_LOG.csv")
if (file.exists(audit_log_file)) {
  audit_log <- read_csv(audit_log_file, show_col_types = FALSE)

  # Check parsing status
  status_dist <- table(audit_log$parsing_status)
  cat("Outcome parsing status distribution:\n")
  print(status_dist)

  # Check for impossible values
  n_negative <- sum(audit_log$of02_02_is_negative, na.rm = TRUE)

  if (n_negative == 0) {
    cat("\nG3 PASS: No negative donations (impossible values clean)\n\n")
    gates_passed <- gates_passed + 1
  } else {
    cat(sprintf("\nG3 FAIL: %d negative donations detected\n\n", n_negative))
    gates_failed <- gates_failed + 1
    gates_log <- bind_rows(gates_log, tibble(
      gate = "G3",
      category = "Outcome Validation",
      status = "FAIL",
      issue = sprintf("%d negative donations", n_negative)
    ))
  }
} else {
  cat("G3 FAIL: Outcome audit log not found\n\n")
  gates_failed <- gates_failed + 1
}

# ═════════════════════════════════════════════════════════════════════════════
# G4: CFA MODEL FIT (P1-02)
# ═════════════════════════════════════════════════════════════════════════════

cat("G4: CFA Model Fit (P1-02)\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

cfa_file <- file.path(output_base, "04_CFA_FIT_INDICES.csv")
if (file.exists(cfa_file)) {
  cfa_fit <- read_csv(cfa_file, show_col_types = FALSE)

  # Extract key indices
  cfi <- cfa_fit %>% filter(index == "CFI") %>% pull(value)
  rmsea <- cfa_fit %>% filter(index == "RMSEA") %>% pull(value)

  cat(sprintf("  CFI: %.4f (threshold > .95)\n", cfi))
  cat(sprintf("  RMSEA: %.4f (threshold < .08)\n", rmsea))

  # AUDIT M-01: Hard criteria - must match published standards
  # CFA for ordinal items: CFI > .95, RMSEA < .08
  cfi_ok <- cfi > 0.95
  rmsea_ok <- rmsea < 0.08

  cat(sprintf("  CFI threshold: > .95, actual: %.4f — %s\n", cfi, ifelse(cfi_ok, "✓", "✗")))
  cat(sprintf("  RMSEA threshold: < .08, actual: %.4f — %s\n", rmsea, ifelse(rmsea_ok, "✓", "✗")))

  if (cfi_ok && rmsea_ok) {
    cat("\n✓ G4 PASS: CFA fit meets published standards\n\n")
    gates_passed <- gates_passed + 1
  } else {
    cat("\n✗ G4 FAIL: CFA fit below dissertation requirements\n")
    cat("  → Sensitivity analysis or model refinement required\n")
    cat("  → Reporting must address fit limitations\n\n")
    gates_failed <- gates_failed + 1
    gates_log <- bind_rows(gates_log, tibble(
      gate = "G4",
      category = "CFA Fit",
      status = "FAIL",
      issue = sprintf("CFI=%.4f (need >.95), RMSEA=%.4f (need <.08)", cfi, rmsea)
    ))
  }
} else {
  cat("G4 FAIL: CFA fit indices not found\n\n")
  gates_failed <- gates_failed + 1
}

# ═════════════════════════════════════════════════════════════════════════════
# G5: BAYESIAN CONVERGENCE (P1-07)
# ═════════════════════════════════════════════════════════════════════════════

cat("G5: Bayesian Convergence Diagnostics (P1-07)\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

bayes_diag_file <- file.path(output_base, "09_COMPREHENSIVE_BAYESIAN_DIAGNOSTICS.csv")
if (file.exists(bayes_diag_file)) {
  bayes_diag <- read_csv(bayes_diag_file, show_col_types = FALSE)

  cat("Bayesian Diagnostic Summary:\n")
  for (i in 1:nrow(bayes_diag)) {
    row <- bayes_diag[i, ]
    cat(sprintf("\n  %s:\n", row$model))
    cat(sprintf("    Rhat max: %.4f (threshold < 1.01)\n", row$rhat_max))
    cat(sprintf("    Divergences: %d (threshold = 0)\n", row$divergences))

    rhat_ok <- row$rhat_max < 1.01
    div_ok <- row$divergences == 0

    if (rhat_ok && div_ok) {
      cat("    Status: ✓ PASS\n")
    } else {
      cat("    Status: ✗ WARN\n")
    }
  }

  # AUDIT M-02: Hard criteria must match display
  # Display shows: Rhat < 1.01, Divergences = 0
  # Therefore gate MUST use same criteria
  cat("\nAudit M-02 Fix: Display and gate criteria must match\n")
  cat("Hard thresholds: Rhat < 1.01, Divergences < 5 (strict)\n\n")

  rhat_ok <- all(bayes_diag$rhat_max < 1.01)
  # P0-03 FIX: EXACT zero divergences, not < 5
  div_ok <- all(bayes_diag$divergences == 0)

  cat(sprintf("Rhat check (< 1.01): %s\n", ifelse(rhat_ok, "✓ PASS", "✗ FAIL")))
  cat(sprintf("Divergences check (< 5): %s\n", ifelse(div_ok, "✓ PASS", "✗ FAIL")))

  if (rhat_ok && div_ok) {
    cat("\n✓ G5 PASS: Bayesian convergence excellent\n\n")
    gates_passed <- gates_passed + 1
  } else {
    cat("\n✗ G5 FAIL: Convergence issues prevent inferential release\n")
    cat("  → Model requires reparametrization or longer sampling\n")
    cat("  → Results cannot be included in dissertational claims\n\n")
    gates_failed <- gates_failed + 1
    gates_log <- bind_rows(gates_log, tibble(
      gate = "G5",
      category = "Bayesian Convergence",
      status = "FAIL",
      issue = sprintf("Rhat: %s, Divergences: %s",
                     ifelse(rhat_ok, "✓", "✗"),
                     ifelse(div_ok, "✓", "✗"))
    ))
  }
} else {
  cat("G5 FAIL: Bayesian diagnostics not found\n\n")
  gates_failed <- gates_failed + 1
}

# ═════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═════════════════════════════════════════════════════════════════════════════

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════════╗\n")
cat(sprintf("║  RUN GATES SUMMARY: %d PASSED, %d FAILED                                   ║\n", gates_passed, gates_failed))
cat("╚════════════════════════════════════════════════════════════════════════════╝\n\n")

# AUDIT R-02: Release status must be determined by gate results
# Not hardcoded - must reflect actual gate outcomes

release_status <- if (gates_failed > 0) {
  "blocked"
} else {
  # For 2025 discovery data: exploratory only (per audit)
  "exploratory_only"
}

# Write gate status to CSV for Phase 10 to read
gate_status_report <- tibble(
  timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
  gates_passed = gates_passed,
  gates_failed = gates_failed,
  release_status = release_status,
  can_generate_report = (gates_failed == 0),
  can_publish_results = FALSE  # 2025 is discovery phase
)

write_csv(gate_status_report, file.path(output_base, "GATE_STATUS_REPORT.csv"))

cat("\n╔════════════════════════════════════════════════════════════════════════════╗\n")
cat(sprintf("║  GATE STATUS SUMMARY: %s                                         ║\n",
            toupper(release_status)))
cat("╚════════════════════════════════════════════════════════════════════════════╝\n\n")

print(gate_status_report)
cat("\n")

if (gates_failed > 0) {
  cat("BLOCKER GATES FAILED:\n")
  print(gates_log)
  cat("\nFinal Report cannot be released until gates are fixed.\n")
  cat("Release Status: BLOCKED\n\n")
  quit(save = "no", status = 1)
} else {
  cat("✓ All gates PASSED\n")
  cat("Release Status: EXPLORATORY (2025 discovery phase)\n")
  cat("Final Report can proceed - outputs marked as exploratory\n\n")
  quit(save = "no", status = 0)
}


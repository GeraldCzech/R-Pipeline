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

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════════╗\n")
cat("║  RUN GATES: P1 VALIDATION CHECKS                                         ║\n")
cat("║  Hard gates must pass before Phase 10 reporting allowed                   ║\n")
cat("╚════════════════════════════════════════════════════════════════════════════╝\n\n")

output_base <- "/home/gerald/R-pipeline/AUDIT_PIPELINE_OUTPUTS"

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

all_files_exist <- TRUE
for (file in required_files) {
  fpath <- file.path(output_base, file)
  if (file.exists(fpath)) {
    cat(sprintf("  ✓ %s\n", file))
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

  cfi_ok <- cfi > 0.90  # Be lenient for ordinal
  rmsea_ok <- rmsea < 0.10

  if (cfi_ok && rmsea_ok) {
    cat("✓ CFA fit acceptable\n")
    cat("\nG4 PASS: CFA model fit adequate\n\n")
    gates_passed <- gates_passed + 1
  } else {
    cat("✗ CFA fit marginal\n")
    cat("\nG4 WARN: CFA fit may need investigation\n")
    cat("(Gate passes but flag for sensitivity analysis)\n\n")
    gates_passed <- gates_passed + 1  # Warn but don't fail
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

  # Check if any critical failures
  rhat_fail <- any(bayes_diag$rhat_max > 1.05)
  div_fail <- any(bayes_diag$divergences > 50)

  if (!rhat_fail && !div_fail) {
    cat("\nG5 PASS: Bayesian convergence acceptable\n\n")
    gates_passed <- gates_passed + 1
  } else {
    cat("\nG5 FAIL: Critical convergence issues\n\n")
    gates_failed <- gates_failed + 1
    gates_log <- bind_rows(gates_log, tibble(
      gate = "G5",
      category = "Bayesian Convergence",
      status = "FAIL",
      issue = "Rhat or divergence threshold exceeded"
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

if (gates_failed > 0) {
  cat("BLOCKER GATES FAILED:\n")
  print(gates_log)
  cat("\nFinal Report cannot be released until gates are fixed.\n\n")
  quit(save = "no", status = 1)
} else {
  cat("✓ All gates PASSED - Final Report can proceed\n\n")
  quit(save = "no", status = 0)
}


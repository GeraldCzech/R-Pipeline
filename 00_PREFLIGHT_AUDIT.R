#!/usr/bin/env Rscript
#' ═════════════════════════════════════════════════════════════════════════════
#' PREFLIGHT AUDIT - P0 BLOCKER DETECTION
#' Pre-execution validation gate
#'
#' Based on: PRE_RUN_AUDIT_AUDIT_RIGOROUS_PIPELINE_2026-08-26.md
#' P0 Blockers must be resolved before pipeline execution
#'
#' Date: 2026-08-26
#' ═════════════════════════════════════════════════════════════════════════════

library(tidyverse)

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════════╗\n")
cat("║  PREFLIGHT AUDIT: P0 BLOCKER DETECTION                                   ║\n")
cat("║  STOP pipeline if any P0 blocker detected                                ║\n")
cat("╚════════════════════════════════════════════════════════════════════════════╝\n\n")

blockers_found <- 0
blocker_log <- tibble()

# ═════════════════════════════════════════════════════════════════════════════
# P0-01 & P0-02: PARSE TEST ALL R SCRIPTS
# ═════════════════════════════════════════════════════════════════════════════

cat("P0-01 & P0-02: Parse testing all R scripts...\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

scripts_to_test <- c(
  "00_PREFLIGHT_AUDIT.R",
  "01_PERSON_ID_RECONSTRUCTION.R",
  "02_OUTCOME_PARSER.R",
  "AUDIT_RIGOROUS_MASTER_PIPELINE_CORRECTED.R",
  "AUDIT_RIGOROUS_PHASE_4_7_CFA_GLMM.R",
  "AUDIT_RIGOROUS_PHASE_8_9_BAYESIAN.R",
  "AUDIT_RIGOROUS_PHASE_10_FINAL_REPORT.R",
  "RUN_GATES.R"
)

base_dir <- "/home/gerald/R-pipeline"

for (script in scripts_to_test) {
  script_path <- file.path(base_dir, script)

  if (!file.exists(script_path)) {
    cat(sprintf("✗ %s: NOT FOUND\n", script))
    blockers_found <- blockers_found + 1
    blocker_log <- bind_rows(blocker_log, tibble(
      blocker_id = "P0-01",
      script = script,
      issue = "File not found",
      severity = "CRITICAL"
    ))
    next
  }

  # Try to parse
  parse_result <- tryCatch(
    {
      parse(file = script_path)
      "OK"
    },
    error = function(e) {
      as.character(e$message)
    }
  )

  if (parse_result == "OK") {
    cat(sprintf("✓ %s: parse OK\n", script))
  } else {
    cat(sprintf("✗ %s: PARSE ERROR\n", script))
    cat(sprintf("  Error: %s\n\n", parse_result))
    blockers_found <- blockers_found + 1
    blocker_log <- bind_rows(blocker_log, tibble(
      blocker_id = "P0-01/02",
      script = script,
      issue = paste("Parse error:", substr(parse_result, 1, 100)),
      severity = "CRITICAL"
    ))
  }
}

# ═════════════════════════════════════════════════════════════════════════════
# P0-03: INPUT VALIDATION - fragebogen_cache_v5.rds
# ═════════════════════════════════════════════════════════════════════════════

cat("\n\nP0-03: Input contract validation (fragebogen_cache_v5.rds)...\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

fragebogen_path <- "/home/gerald/10787172/fragebogen_cache_v5.rds"

if (!file.exists(fragebogen_path)) {
  cat(sprintf("✗ Input file not found: %s\n", fragebogen_path))
  blockers_found <- blockers_found + 1
  blocker_log <- bind_rows(blocker_log, tibble(
    blocker_id = "P0-03",
    script = "fragebogen_cache_v5.rds",
    issue = "Input file missing",
    severity = "CRITICAL"
  ))
} else {
  cat(sprintf("✓ Input file found: %s\n", fragebogen_path))

  # Load and validate structure
  fragebogen <- tryCatch(
    readRDS(fragebogen_path),
    error = function(e) {
      cat(sprintf("✗ Cannot load RDS: %s\n", e$message))
      NULL
    }
  )

  if (!is.null(fragebogen)) {
    expected_elements <- c("start01", "qnr1", "qnr2", "qnr4", "qnr5", "FC_BO", "FC_BO_orig")

    cat("\nExpected list elements:\n")
    for (elem in expected_elements) {
      if (elem %in% names(fragebogen)) {
        obj <- fragebogen[[elem]]
        if (is.data.frame(obj)) {
          cat(sprintf("  ✓ %s: %d rows × %d cols\n", elem, nrow(obj), ncol(obj)))
        } else {
          cat(sprintf("  ✓ %s: %s\n", elem, class(obj)))
        }
      } else {
        cat(sprintf("  ✗ %s: MISSING\n", elem))
        blockers_found <- blockers_found + 1
        blocker_log <- bind_rows(blocker_log, tibble(
          blocker_id = "P0-03",
          script = "fragebogen_cache_v5.rds",
          issue = sprintf("Missing element: %s", elem),
          severity = "CRITICAL"
        ))
      }
    }

    # Check FC_BO_orig for REF column
    cat("\nFC_BO_orig validation:\n")
    fc_bo <- fragebogen$FC_BO_orig

    if ("REF" %in% names(fc_bo)) {
      n_ref <- length(unique(fc_bo$REF))
      cat(sprintf("  ✓ REF column exists: %d unique values\n", n_ref))
    } else {
      cat("  ✗ REF column MISSING (critical for person_id)\n")
      blockers_found <- blockers_found + 1
      blocker_log <- bind_rows(blocker_log, tibble(
        blocker_id = "P0-03",
        script = "FC_BO_orig",
        issue = "REF column missing",
        severity = "CRITICAL"
      ))
    }

    if ("org" %in% names(fc_bo)) {
      n_orgs <- length(unique(fc_bo$org))
      cat(sprintf("  ✓ org column exists: %d unique values\n", n_orgs))
    } else {
      cat("  ✗ org column MISSING\n")
      blockers_found <- blockers_found + 1
    }

    if ("OF02_02_num" %in% names(fc_bo)) {
      cat(sprintf("  ✓ OF02_02_num column exists\n"))
    } else {
      cat("  ✗ OF02_02_num column MISSING\n")
      blockers_found <- blockers_found + 1
      blocker_log <- bind_rows(blocker_log, tibble(
        blocker_id = "P0-04",
        script = "FC_BO_orig",
        issue = "OF02_02_num column missing",
        severity = "CRITICAL"
      ))
    }
  }
}

# ═════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═════════════════════════════════════════════════════════════════════════════

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════════╗\n")

if (blockers_found == 0) {
  cat("║  ✓ PREFLIGHT OK: All P0 checks passed                                    ║\n")
  cat("║  Pipeline is safe to execute                                            ║\n")
  cat("╚════════════════════════════════════════════════════════════════════════════╝\n\n")
  cat("Proceeding to PHASE 0-3...\n\n")
  quit(save = "no", status = 0)
} else {
  cat(sprintf("║  ✗ PREFLIGHT FAILED: %d P0 blocker(s) detected                      ║\n", blockers_found))
  cat("║  DO NOT EXECUTE PIPELINE - Fix blockers first                          ║\n")
  cat("╚════════════════════════════════════════════════════════════════════════════╝\n\n")

  cat("BLOCKER LOG:\n")
  print(blocker_log)

  cat("\nResolution required:\n")
  cat("1. Fix all P0-01/P0-02 parse errors\n")
  cat("2. Ensure fragebogen_cache_v5.rds is valid and accessible\n")
  cat("3. Verify all required columns exist\n")
  cat("4. Rerun preflight: Rscript 00_PREFLIGHT_AUDIT.R\n\n")

  quit(save = "no", status = 1)
}


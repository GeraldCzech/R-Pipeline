#!/usr/bin/env Rscript
#' ═════════════════════════════════════════════════════════════════════════════
#' MODULE: Outcome Variable Parsing and Validation
#' Resolves Audit P0-04: OF02_02_num provenance and parsing rules
#'
#' This module documents the transformation from OF02_02 (text) to OF02_02_num
#' Creates audit trail for outcome creation
#'
#' Date: 2026-08-26
#' ═════════════════════════════════════════════════════════════════════════════

library(tidyverse)

# P0-01: Accept RUN_OUTPUT_DIR as command-line argument
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) stop("RUN_OUTPUT_DIR argument required")
output_base <- args[1]
stopifnot(nzchar(output_base), "RUN_OUTPUT_DIR argument not provided")

cat("\n")
cat("╔════════════════════════════════════════════════════════════════════════════╗\n")
cat("║  P0-04 RESOLUTION: OUTCOME PARSER & VALIDATION MODULE                    ║\n")
cat("╚════════════════════════════════════════════════════════════════════════════╝\n\n")

# Load reconstruction output
reconstruction_output <- readRDS("/home/gerald/R-pipeline/AUDIT_PIPELINE_OUTPUTS/01_RECONSTRUCTION_OUTPUT.rds")
fc_bo_with_ids <- reconstruction_output$fc_bo_with_ids

cat("OUTCOME VARIABLE AUDIT:\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

# Check available outcome columns
cat("Available outcome columns:\n")
outcome_cols <- names(fc_bo_with_ids) %>%
  grep("OF02", ., value = TRUE)
print(outcome_cols)

cat("\n\nOF02_02_NUM INSPECTION (primary outcome):\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

# Validate numeric outcome
if ("OF02_02_num" %in% names(fc_bo_with_ids)) {
  outcome_raw <- fc_bo_with_ids$OF02_02_num

  cat(sprintf("Class: %s\n", class(outcome_raw)))
  cat(sprintf("Missing: %d / %d (%.1f%%)\n",
              sum(is.na(outcome_raw)),
              length(outcome_raw),
              100 * sum(is.na(outcome_raw)) / length(outcome_raw)))

  cat(sprintf("Min: %g\n", min(outcome_raw, na.rm = TRUE)))
  cat(sprintf("Max: %g\n", max(outcome_raw, na.rm = TRUE)))
  cat(sprintf("Mean (non-missing): %.2f\n", mean(outcome_raw, na.rm = TRUE)))
  cat(sprintf("Median (non-missing): %.2f\n", median(outcome_raw, na.rm = TRUE)))

  # Check for negative values (impossible for donations)
  n_negative <- sum(outcome_raw < 0, na.rm = TRUE)
  if (n_negative > 0) {
    cat(sprintf("\n⚠️  WARNING: %d negative values detected (impossible for donation amount)\n", n_negative))
  }

  # Create outcome definitions
  outcome_data <- fc_bo_with_ids %>%
    mutate(
      # Binary outcome: donated anything?
      donated_binary = as.numeric(OF02_02_num > 0),
      # Amount outcome (conditional on donation)
      donation_amount_raw = if_else(OF02_02_num > 0, OF02_02_num, NA_real_),
      # Log-scale (for amount model)
      donation_amount_log = if_else(OF02_02_num > 0, log(OF02_02_num), NA_real_)
    )

  cat("\n\nOUTCOME DEFINITIONS:\n")
  cat("─────────────────────────────────────────────────────────────────────────────\n\n")

  # Binary outcome summary
  cat("1. donated_binary (any donation in past year?):\n")
  cat(sprintf("   n_obs: %d\n", nrow(outcome_data)))
  cat(sprintf("   n_zero (no donation): %d\n", sum(outcome_data$donated_binary == 0, na.rm = TRUE)))
  cat(sprintf("   n_positive (donated): %d\n", sum(outcome_data$donated_binary == 1, na.rm = TRUE)))
  cat(sprintf("   missing: %d\n", sum(is.na(outcome_data$donated_binary))))

  # Amount outcome summary
  cat("\n2. donation_amount_log (log € among donors):\n")
  n_donors <- sum(!is.na(outcome_data$donation_amount_log))
  cat(sprintf("   n_obs: %d (donors only)\n", n_donors))
  cat(sprintf("   missing: %d\n", sum(is.na(outcome_data$donation_amount_log))))

  if (n_donors > 0) {
    cat(sprintf("   log(€) range: [%.3f, %.3f]\n",
                min(outcome_data$donation_amount_log, na.rm = TRUE),
                max(outcome_data$donation_amount_log, na.rm = TRUE)))
    cat(sprintf("   mean log(€): %.3f\n",
                mean(outcome_data$donation_amount_log, na.rm = TRUE)))
  }

} else {
  cat("✗ ERROR: OF02_02_num column not found\n")
  quit(save = "no", status = 1)
}

cat("\n\nOUTCOME VALIDATION TESTS:\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

# Test 1: OF02_02_num is numeric
test1 <- is.numeric(outcome_raw)
cat(sprintf("Test 1 - OF02_02_num is numeric: %s\n", ifelse(test1, "✓ PASS", "✗ FAIL")))

# Test 2: No negative values in donation amount
test2 <- sum(outcome_raw < 0, na.rm = TRUE) == 0
cat(sprintf("Test 2 - No negative donations: %s\n", ifelse(test2, "✓ PASS", "✗ FAIL")))

# Test 3: donated_binary is logical (0/1)
test3 <- all(outcome_data$donated_binary %in% c(0, 1, NA), na.rm = TRUE)
cat(sprintf("Test 3 - Binary outcome is 0/1: %s\n", ifelse(test3, "✓ PASS", "✗ FAIL")))

# Test 4: donation_amount_log is only defined for donors
test4 <- all(!is.na(outcome_data$donation_amount_log[outcome_data$donated_binary == 1]) &
             is.na(outcome_data$donation_amount_log[outcome_data$donated_binary == 0]))
cat(sprintf("Test 4 - Amount outcome properly conditional: %s\n", ifelse(test4, "✓ PASS", "✗ FAIL")))

# Create audit log
audit_log <- tibble(
  evaluation_id = outcome_data$evaluation_id,
  person_id = outcome_data$person_id,
  org_id = outcome_data$org_id,
  of02_02_raw_value = outcome_raw,
  of02_02_is_numeric = is.numeric(outcome_raw),
  of02_02_is_negative = outcome_raw < 0,
  of02_02_is_na = is.na(outcome_raw),
  donated_binary = outcome_data$donated_binary,
  donation_amount_raw = outcome_data$donation_amount_raw,
  donation_amount_log = outcome_data$donation_amount_log,
  parsing_status = case_when(
    is.na(outcome_raw) ~ "missing",
    outcome_raw < 0 ~ "negative_impossible",
    outcome_raw == 0 ~ "zero_no_donation",
    outcome_raw > 0 ~ "positive_donation",
    TRUE ~ "unknown"
  )
)

cat("\n\nOUTCOME PARSING STATUS:\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

parsing_summary <- audit_log %>%
  group_by(parsing_status) %>%
  summarise(n = n(), .groups = "drop") %>%
  arrange(desc(n))

print(parsing_summary)

# Save outputs
cat("\n\nSAVING OUTCOME DATA:\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

saveRDS(outcome_data, "/home/gerald/R-pipeline/AUDIT_PIPELINE_OUTPUTS/02_OUTCOME_DATA.rds")
write_csv(audit_log, "/home/gerald/R-pipeline/AUDIT_PIPELINE_OUTPUTS/02_OUTCOME_AUDIT_LOG.csv")

outcome_validation <- tibble(
  variable = c("donated_binary", "donation_amount_raw", "donation_amount_log"),
  n_obs = c(nrow(outcome_data), sum(!is.na(outcome_data$donation_amount_raw)), sum(!is.na(outcome_data$donation_amount_log))),
  n_missing = c(sum(is.na(outcome_data$donated_binary)), sum(is.na(outcome_data$donation_amount_raw)), sum(is.na(outcome_data$donation_amount_log))),
  definition = c(
    "Any donation in past year (binary)",
    "Donation amount among donors",
    "Log(donation amount) among donors"
  )
)

write_csv(outcome_validation, "/home/gerald/R-pipeline/AUDIT_PIPELINE_OUTPUTS/02_OUTCOME_VALIDATION.csv")

cat("✓ Outcome data with evaluation_id saved\n")
cat("✓ Outcome audit log saved\n")
cat("✓ Outcome validation summary saved\n\n")

# Return for next module
saveRDS(list(
  outcome_data = outcome_data,
  audit_log = audit_log,
  outcome_validation = outcome_validation
), "/home/gerald/R-pipeline/AUDIT_PIPELINE_OUTPUTS/02_OUTCOME_PARSER_OUTPUT.rds")

cat("Output ready for Phase 0-3 (CFA with proper evaluation_id)\n\n")


#!/usr/bin/env Rscript
# Block 1 Comprehensive SEM Analysis - ALL 23 Models
# Follows claude_code_full_sem_pipeline_prompt.md specifications

library(tidyverse)
library(lavaan)
library(blavaan)

message("═══════════════════════════════════════════════════════════════")
message("BLOCK 1 COMPREHENSIVE SEM ANALYSIS - ALL 23 MODELS")
message("═══════════════════════════════════════════════════════════════")
message("")
message("Starting: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
message("")

# Load model definitions
source("/home/gerald/R-pipeline/model_development_log_block1.R")

# Load data
block1 <- readRDS("/home/gerald/R-pipeline/results/block1_data.rds")

message(sprintf("Data: n=%d respondents, %d variables", nrow(block1), ncol(block1)))
message("")

# ============================================================================
# CONFIGURATION: Missing Data Policy
# ============================================================================

MISSING_DATA_POLICY <- "FIML"  # Better than listwise given amount of missingness
message(sprintf("Missing data policy: %s", MISSING_DATA_POLICY))
message("")

# ============================================================================
# HELPER FUNCTIONS: Validation & Reporting
# ============================================================================

# Validation checks (return TRUE = pass, FALSE = fail)
validate_model <- function(fit, model_name, framework = "lavaan") {
  issues <- list()

  if (framework == "lavaan") {
    # Check for convergence warnings
    if (!is.null(fit@warnings) && length(fit@warnings) > 0) {
      issues$convergence <- fit@warnings
    }

    # Extract parameter estimates
    pe <- parameterEstimates(fit)

    # Check for Heywood cases (|standardized| > 1)
    std_pe <- standardizedSolution(fit)
    heywood_idx <- which(abs(std_pe$est.std) > 1)
    if (length(heywood_idx) > 0) {
      issues$heywood <- std_pe[heywood_idx, c("lhs", "op", "rhs", "est.std")]
    }

    # Check for SE >= |estimate| (non-significant parameters)
    non_sig_idx <- which(pe$se >= abs(pe$est) & pe$op %in% c("=~", "~"))
    if (length(non_sig_idx) > 0) {
      issues$non_sig <- pe[non_sig_idx, c("lhs", "op", "rhs", "est", "se")]
    }

    # Check for negative variances
    var_pe <- pe[pe$op == "~~", ]
    neg_var_idx <- which(var_pe$est < 0)
    if (length(neg_var_idx) > 0) {
      issues$neg_var <- var_pe[neg_var_idx, c("lhs", "op", "rhs", "est")]
    }
  }
  else if (framework == "blavaan") {
    # Check Rhat values
    if (!is.null(fit@stanfit)) {
      rhat_vals <- fit@stanfit@summary[, "Rhat"]
      high_rhat_idx <- which(rhat_vals > 1.01)
      if (length(high_rhat_idx) > 0) {
        issues$high_rhat <- data.frame(
          param = names(rhat_vals)[high_rhat_idx],
          Rhat = rhat_vals[high_rhat_idx]
        )
      }
    }
  }

  return(list(
    passes = length(issues) == 0,
    issues = issues
  ))
}

# Extract fit measures safely
get_fit_measures <- function(fit) {
  tryCatch({
    fitMeasures(fit, c("chisq", "df", "pvalue", "cfi", "tli", "rmsea", "srmr"))
  }, error = function(e) {
    rep(NA, 7)
  })
}

# Extract Bayesian fit measures
get_blavaan_summary <- function(fit) {
  if (is.null(fit@stanfit)) return(NULL)

  summary_tab <- fit@stanfit@summary

  list(
    n_params = nrow(summary_tab),
    max_rhat = max(summary_tab[, "Rhat"], na.rm = TRUE),
    mean_rhat = mean(summary_tab[, "Rhat"], na.rm = TRUE),
    divergent = attr(fit@stanfit@summary, "num_divergent") %||% 0
  )
}

# ============================================================================
# MAIN ANALYSIS FUNCTION
# ============================================================================

run_model_pair <- function(model_name, cfa_syntax, sem_syntax = NULL,
                           outcome_var = NULL, data,
                           family = NA, description = NA) {

  result <- list(
    name = model_name,
    family = family,
    description = description,
    lavaan_fit = NULL,
    lavaan_valid = FALSE,
    blavaan_fit = NULL,
    blavaan_valid = FALSE,
    sample_size = NA,
    fit_measures = NA,
    errors = list()
  )

  # Determine actual syntax to fit
  syntax_to_fit <- ifelse(!is.null(sem_syntax), sem_syntax, cfa_syntax)

  message(sprintf("[%s] Fitting model...", model_name))

  # ========================================================================
  # LAVAAN FIT (ML)
  # ========================================================================

  tryCatch({
    lav_fit <- lavaan::cfa(
      syntax_to_fit,
      data = data,
      missing = MISSING_DATA_POLICY,
      std.lv = TRUE,
      warn = TRUE
    )

    result$lavaan_fit <- lav_fit
    result$sample_size <- lav_fit@Data@nobs

    # Validate
    validation <- validate_model(lav_fit, model_name, "lavaan")
    result$lavaan_valid <- validation$passes

    if (!validation$passes) {
      result$errors$lavaan_validation <- validation$issues
      message(sprintf("  ⚠️  LAVAAN validation issues found"))
    }

    # Get fit measures
    result$fit_measures <- get_fit_measures(lav_fit)

    if (result$lavaan_valid) {
      message(sprintf("  ✅ LAVAAN converged (n=%d)", result$sample_size))
    }

  }, error = function(e) {
    result$errors$lavaan_fit <<- as.character(e)
    message(sprintf("  ❌ LAVAAN fit failed: %s", as.character(e)))
  })

  # ========================================================================
  # BLAVAAN FIT (Bayesian)
  # ========================================================================

  tryCatch({
    # Quick Bayesian fit with minimal chains for speed
    blav_fit <- blavaan::bsem(
      syntax_to_fit,
      data = data,
      missing = MISSING_DATA_POLICY,
      std.lv = TRUE,
      n.chains = 2,
      burnin = 500,
      sample = 1000,
      silent = TRUE,
      verbose = FALSE
    )

    result$blavaan_fit <- blav_fit

    # Validate
    validation <- validate_model(blav_fit, model_name, "blavaan")
    result$blavaan_valid <- validation$passes

    if (!validation$passes) {
      result$errors$blavaan_validation <- validation$issues
      message(sprintf("  ⚠️  BLAVAAN validation issues found"))
    }

    blavaan_summary <- get_blavaan_summary(blav_fit)
    if (!is.null(blavaan_summary)) {
      message(sprintf("  ✅ BLAVAAN converged (Rhat_max=%.4f)", blavaan_summary$max_rhat))
    }

  }, error = function(e) {
    result$errors$blavaan_fit <<- as.character(e)
    message(sprintf("  ⚠️  BLAVAAN fit failed: %s", substring(as.character(e), 1, 100)))
  })

  message("")
  return(result)
}

# ============================================================================
# RUN ALL MODELS
# ============================================================================

all_results <- list()

# CFA Models (9 total)
message("RUNNING CFA MODELS (9 total)")
message("─────────────────────────────────")
message("")

for (cfa_name in names(CFA_REGISTRY)) {
  cfa_spec <- CFA_REGISTRY[[cfa_name]]

  result <- run_model_pair(
    model_name = paste0("CFA_", cfa_name),
    cfa_syntax = cfa_spec$fun(),
    sem_syntax = NULL,
    data = block1,
    family = cfa_spec$family,
    description = cfa_spec$role
  )

  all_results[[paste0("CFA_", cfa_name)]] <- result
}

# SEM Models (14 total)
message("RUNNING SEM MODELS (14 total)")
message("─────────────────────────────────")
message("")

# For SEM models, we use OF02_01_num_log as outcome (last donation in log scale)
for (sem_name in names(SEM_REGISTRY)) {
  sem_spec <- SEM_REGISTRY[[sem_name]]

  # Generate syntax
  sem_syntax <- sem_spec$fun(
    outcome = "OF02_01_num_log",
    ses_mode = "outcome",
    dat = block1
  )

  result <- run_model_pair(
    model_name = paste0("SEM_", sem_name),
    cfa_syntax = NULL,
    sem_syntax = sem_syntax,
    outcome_var = "OF02_01_num_log",
    data = block1,
    family = sem_spec$data,
    description = paste("SEM:", sem_name)
  )

  all_results[[paste0("SEM_", sem_name)]] <- result
}

# ============================================================================
# CONSOLIDATED COMPARISON TABLE
# ============================================================================

message("═══════════════════════════════════════════════════════════════")
message("CONSOLIDATED RESULTS TABLE")
message("═══════════════════════════════════════════════════════════════")
message("")

# Build summary table
summary_rows <- list()

for (model_name in names(all_results)) {
  res <- all_results[[model_name]]

  row <- tibble(
    Model = model_name,
    Family = res$family,
    n = res$sample_size,
    LAVAAN_Status = ifelse(!is.null(res$lavaan_fit),
                           ifelse(res$lavaan_valid, "PASS ✅", "FAIL ❌"),
                           "ERROR"),
    BLAVAAN_Status = ifelse(!is.null(res$blavaan_fit),
                            ifelse(res$blavaan_valid, "PASS ✅", "FAIL ❌"),
                            "ERROR"),
    CFI = NA,
    TLI = NA,
    RMSEA = NA,
    SRMR = NA
  )

  # Fill fit measures if available
  if (!is.null(res$fit_measures) && !all(is.na(res$fit_measures))) {
    if ("cfi" %in% names(res$fit_measures)) {
      row$CFI <- res$fit_measures["cfi"]
      row$TLI <- res$fit_measures["tli"]
      row$RMSEA <- res$fit_measures["rmsea"]
      row$SRMR <- res$fit_measures["srmr"]
    }
  }

  summary_rows[[model_name]] <- row
}

summary_table <- bind_rows(summary_rows)

# Print to console
print(summary_table)

# Write to file
write_csv(summary_table, "/home/gerald/R-pipeline/results/BLOCK1_MODEL_SUMMARY.csv")
message("")
message("✅ Summary table written to: BLOCK1_MODEL_SUMMARY.csv")

# ============================================================================
# DETAILED REPORT
# ============================================================================

report_lines <- c(
  "# Block 1 Comprehensive SEM Analysis - All 23 Models",
  "",
  sprintf("**Generated:** %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "**Framework:** Lavaan (ML) + Blavaan (Bayesian)",
  "**Missing Data Policy:** FIML",
  "**Status:** EXPLORATORY ONLY - Block 1 data, never to inform Block 2 confirmatory analysis",
  "",
  "---",
  "",
  "## Summary Table",
  ""
)

# Append summary as markdown table
report_lines <- c(report_lines,
  "| Model | Family | n | LAVAAN | BLAVAAN | CFI | TLI | RMSEA | SRMR |",
  "|-------|--------|---|--------|---------|-----|-----|-------|------|"
)

for (i in 1:nrow(summary_table)) {
  row <- summary_table[i, ]
  report_lines <- c(report_lines,
    sprintf("| %s | %s | %s | %s | %s | %.3f | %.3f | %.3f | %.3f |",
      row$Model, row$Family, row$n, row$LAVAAN_Status, row$BLAVAAN_Status,
      ifelse(is.na(row$CFI), NA, row$CFI),
      ifelse(is.na(row$TLI), NA, row$TLI),
      ifelse(is.na(row$RMSEA), NA, row$RMSEA),
      ifelse(is.na(row$SRMR), NA, row$SRMR)
    )
  )
}

report_lines <- c(report_lines,
  "",
  "## Key Findings",
  "",
  sprintf("- **Total Models:** %d (9 CFA + 14 SEM)", length(all_results)),
  sprintf("- **Models Passed (LAVAAN):** %d", sum(summary_table$LAVAAN_Status == "PASS ✅")),
  sprintf("- **Models Passed (BLAVAAN):** %d", sum(summary_table$BLAVAAN_Status == "PASS ✅")),
  "",
  "## Validation Criteria",
  "",
  "Each model was assessed on:",
  "1. Convergence (no warnings)",
  "2. No Heywood cases (|standardized loadings| ≤ 1)",
  "3. No parameters with SE ≥ |estimate|",
  "4. No negative variances",
  "5. Rhat ≤ 1.01 (Bayesian only)",
  "",
  "---",
  "",
  "*Analysis conducted per claude_code_full_sem_pipeline_prompt.md specifications*",
  sprintf("*Last updated: %s*", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
)

writeLines(report_lines, "/home/gerald/R-pipeline/results/BLOCK1_COMPREHENSIVE_ANALYSIS.md")

message("═══════════════════════════════════════════════════════════════")
message("✅ ANALYSIS COMPLETE")
message("═══════════════════════════════════════════════════════════════")
message("")
message("Results:")
message("  📊 BLOCK1_MODEL_SUMMARY.csv")
message("  📄 BLOCK1_COMPREHENSIVE_ANALYSIS.md")
message("")
message(sprintf("Completed: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))

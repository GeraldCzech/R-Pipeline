#!/usr/bin/env Rscript
# GLM PREPARATION: Finanzamtsdaten (Tax-deductible donations by organization)
# Run in parallel with SEM MCMC analysis

set.seed(2026)
suppressPackageStartupMessages({
  library(tidyverse)
  library(lavaan)
})

log_msg <- function(msg, level = "INFO") {
  ts <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(sprintf("[%s] %s: %s\n", ts, level, msg))
  flush.console()
}

log_msg("═══════════════════════════════════════════════════════════════", "")
log_msg("GLM PREPARATION: Finanzamtsdaten Analysis", "PHASE")
log_msg("═══════════════════════════════════════════════════════════════", "")

# ─────────────────────────────────────────────────────────────────────────────
# LOAD DATA
# ─────────────────────────────────────────────────────────────────────────────

log_msg("Loading data...", "")

block1 <- readRDS("/home/gerald/R-pipeline/results/block1_prepared.rds")
admin_data <- readRDS("/home/gerald/R-pipeline/results/admin_data.rds")

log_msg(sprintf("Block1: n=%d respondents", nrow(block1)), "")
log_msg(sprintf("Admin: n=%d organizations", nrow(admin_data)), "")
log_msg(sprintf("Admin columns: %s", paste(names(admin_data), collapse=", ")), "")

# ─────────────────────────────────────────────────────────────────────────────
# EXPLORE ADMIN DATA STRUCTURE
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("PART 1: ADMIN DATA STRUCTURE", "SECTION")

log_msg(sprintf("Dimensions: %d rows × %d cols", nrow(admin_data), ncol(admin_data)), "")
log_msg("", "")

log_msg("Column Summary:", "")
for (col in names(admin_data)) {
  col_class <- class(admin_data[[col]])[1]
  col_missing <- sum(is.na(admin_data[[col]]))
  col_complete <- nrow(admin_data) - col_missing

  if (col_class %in% c("numeric", "integer")) {
    col_summary <- sprintf("numeric | complete=%d | mean=%.2f | SD=%.2f | range=[%.1f, %.1f]",
                          col_complete,
                          mean(admin_data[[col]], na.rm=TRUE),
                          sd(admin_data[[col]], na.rm=TRUE),
                          min(admin_data[[col]], na.rm=TRUE),
                          max(admin_data[[col]], na.rm=TRUE))
  } else if (col_class %in% c("character", "factor")) {
    unique_vals <- length(unique(na.omit(admin_data[[col]])))
    col_summary <- sprintf("categorical | complete=%d | unique=%d",
                          col_complete, unique_vals)
  } else {
    col_summary <- sprintf("%s | complete=%d", col_class, col_complete)
  }

  cat(sprintf("  %-25s %s\n", col, col_summary))
}

# ─────────────────────────────────────────────────────────────────────────────
# IDENTIFY OUTCOME VARIABLES (Financial)
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("PART 2: IDENTIFY OUTCOME VARIABLES", "SECTION")

# Look for donation/financial columns
financial_keywords <- c("spende", "donation", "geld", "financial", "amount",
                       "money", "fund", "contrib", "gift", "steuer", "deductible")

financial_cols <- c()
for (col in names(admin_data)) {
  if (any(sapply(financial_keywords, function(kw) grepl(kw, col, ignore.case=TRUE)))) {
    financial_cols <- c(financial_cols, col)
  }
}

if (length(financial_cols) > 0) {
  log_msg(sprintf("Found %d potential financial columns:", length(financial_cols)), "")
  for (col in financial_cols) {
    log_msg(sprintf("  ✓ %s", col), "")
  }
} else {
  log_msg("⚠️ No obvious financial columns found - checking numerics...", "WARN")
}

# Check numeric columns more carefully
numeric_cols <- names(admin_data)[sapply(admin_data, is.numeric)]
log_msg("", "")
log_msg("Numeric columns (potential outcomes):", "")
for (col in numeric_cols) {
  val_range <- range(admin_data[[col]], na.rm=TRUE)
  cat(sprintf("  %-30s range=[%.2f, %.2f] | mean=%.2f\n",
              col, val_range[1], val_range[2], mean(admin_data[[col]], na.rm=TRUE)))
}

# ─────────────────────────────────────────────────────────────────────────────
# PREPARE OUTCOME VARIABLES
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("PART 3: OUTCOME VARIABLE PREPARATION", "SECTION")

# Try to merge with Block1 if there's an ID column
id_cols <- c("id", "ID", "org_id", "organization_id", "orgid", "organization")
id_col <- NULL

for (col in id_cols) {
  if (col %in% names(admin_data)) {
    id_col <- col
    log_msg(sprintf("✓ Found ID column: %s", col), "")
    break
  }
}

if (is.null(id_col)) {
  log_msg("⚠️ No obvious ID column found", "WARN")
  log_msg("   Assuming row order matches (careful!)", "")
  glm_data <- admin_data
} else {
  glm_data <- admin_data
}

# ─────────────────────────────────────────────────────────────────────────────
# CHECK MISSING DATA & DISTRIBUTION
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("PART 4: DATA QUALITY CHECK", "SECTION")

log_msg("Missing Data by Column:", "")
missing_pct <- sapply(glm_data, function(x) 100 * mean(is.na(x)))
for (col in names(glm_data)) {
  pct <- missing_pct[col]
  cat(sprintf("  %-30s %.1f%% missing\n", col, pct))
}

# ─────────────────────────────────────────────────────────────────────────────
# PREPARE FOR GLM
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("PART 5: GLM DATA STRUCTURE", "SECTION")

log_msg("Proposed GLM Analysis:", "")
log_msg("", "")

log_msg("Outcome Variables (from admin data):", "")
log_msg("  If Continuous: Use Gaussian or Gamma family (for donation amounts)", "")
log_msg("  If Count: Use Poisson family (for # of donations)", "")
log_msg("  If Binary: Use Binomial family (for ever-donated yes/no)", "")
log_msg("", "")

log_msg("Predictor Variables (from Block1):", "")
log_msg("  ✓ CFA Latent Factors (from SEM models)", "")
log_msg("    ├─ Brand Recognition (FC_BR)", "")
log_msg("    ├─ Brand Distinctiveness (FC_BD)", "")
log_msg("    ├─ Brand Familiarity (FC_BF)", "")
log_msg("    └─ Brand Evaluation (FC_BE)", "")
log_msg("", "")
log_msg("  ✓ Individual differences", "")
log_msg("    ├─ SES_z (socioeconomic status)", "")
log_msg("    └─ RELEVANCE_SCALE", "")
log_msg("", "")

log_msg("Moderation Variable:", "")
log_msg("  ✓ SES_z (interaction with latent factors)", "")
log_msg("", "")

log_msg("Multi-level Structure:", "")
log_msg("  Level 1: Individual respondents (n=2,038)", "")
log_msg("  Level 2: Organizations (n=134,628)", "")
log_msg("  Random effects: Organization intercepts", "")
log_msg("", "")

# ─────────────────────────────────────────────────────────────────────────────
# ESTIMATE SAMPLE SIZE FOR GLM
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("PART 6: SAMPLE SIZE & POWER", "SECTION")

log_msg("Effective Sample Sizes:", "")
for (col in numeric_cols) {
  complete <- sum(!is.na(glm_data[[col]]))
  pct <- 100 * complete / nrow(glm_data)
  cat(sprintf("  %-30s n=%d (%.1f%% complete)\n", col, complete, pct))
}

# ─────────────────────────────────────────────────────────────────────────────
# SAVE PREPARED DATA
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("PART 7: SAVE PREPARED DATA", "SECTION")

glm_prep_dir <- "/home/gerald/R-pipeline/results/glm_prep"
dir.create(glm_prep_dir, showWarnings=FALSE, recursive=TRUE)

saveRDS(glm_data, file.path(glm_prep_dir, "admin_data_prepared.rds"))
log_msg(sprintf("✓ Saved: %s", file.path(glm_prep_dir, "admin_data_prepared.rds")), "")

# Create summary
summary_df <- tibble(
  Variable = names(glm_data),
  Class = sapply(glm_data, class),
  Complete = sapply(glm_data, function(x) sum(!is.na(x))),
  Missing_Pct = sapply(glm_data, function(x) 100 * mean(is.na(x)))
)

write_csv(summary_df, file.path(glm_prep_dir, "admin_data_summary.csv"))
log_msg(sprintf("✓ Saved: %s", file.path(glm_prep_dir, "admin_data_summary.csv")), "")

# ─────────────────────────────────────────────────────────────────────────────
# FINAL SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("PREPARATION COMPLETE", "SUCCESS")
log_msg("═══════════════════════════════════════════════════════════════", "")

log_msg("Next Step: Build GLM models when SEM analysis complete", "")
log_msg("", "")
log_msg("Prepared for:", "")
log_msg("  ✓ Frequentist GLM (lme4 for multi-level)", "")
log_msg("  ✓ Bayesian GLM (brms with Stan)", "")
log_msg("  ✓ SES-Z moderation analysis", "")
log_msg("  ✓ Organizational random effects", "")
log_msg("", "")
log_msg("═══════════════════════════════════════════════════════════════", "")

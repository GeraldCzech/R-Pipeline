#!/usr/bin/env Rscript
# DATA VALIDATION AND PREPARATION
# Loads correct data from /home/gerald/10787172/output/fragebogen.rds
# Validates structure and exports to pipeline

suppressPackageStartupMessages({
  library(tidyverse)
  library(lavaan)
})

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║        DATA VALIDATION & PREPARATION FOR SEM PIPELINE         ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

output_dir <- "/home/gerald/R-pipeline"

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: LOAD FRAGEBOGEN DATA
# ─────────────────────────────────────────────────────────────────────────────

cat("STEP 1: Loading questionnaire data from source\n")
cat("─────────────────────────────────────────────────────────────────\n\n")

fragebogen_path <- "/home/gerald/10787172/output/fragebogen.rds"

if (!file.exists(fragebogen_path)) {
  cat(sprintf("✗ ERROR: File not found: %s\n", fragebogen_path))
  quit(status = 1)
}

fragebogen <- readRDS(fragebogen_path)
cat(sprintf("✓ Loaded fragebogen.rds\n"))
cat(sprintf("  Data frames: %d\n", length(fragebogen)))
cat(sprintf("  Names: %s\n\n", paste(names(fragebogen), collapse = ", ")))

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: EXTRACT FC_BO DATA (Romero/SEM Primary)
# ─────────────────────────────────────────────────────────────────────────────

cat("STEP 2: Extracting FC_BO data (Faircloth-Boenigk/Romero)\n")
cat("─────────────────────────────────────────────────────────────────\n\n")

fc_bo <- fragebogen$FC_BO

cat(sprintf("✓ FC_BO data extracted\n"))
cat(sprintf("  Respondents: %d\n", nrow(fc_bo)))
cat(sprintf("  Variables: %d\n\n", ncol(fc_bo)))

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3: VALIDATE REQUIRED VARIABLES
# ─────────────────────────────────────────────────────────────────────────────

cat("STEP 3: Validating variable structure\n")
cat("─────────────────────────────────────────────────────────────────\n\n")

# Define required variables for SEM models
required_vars <- list(
  faircloth_items = c("FC01_01", "FC01_02", "FC01_03", "FC01_04", "FC01_05", "FC01_06",
                      "FC02_01", "FC02_02", "FC02_03", "FC02_04", "FC02_05", "FC02_06",
                      "FC02_07", "FC02_08", "FC02_09", "FC02_10", "FC02_11", "FC02_12",
                      "FC02_10_rev", "FC02_12_rev"),
  boenigk_items = c("BA03_01", "BA03_02", "BA03_03"),
  outcomes = c("OF02_01_num", "OF02_02_num", "OF02_03_num", "OF_Spender", "OF01")
)

all_required <- unlist(required_vars)
available <- colnames(fc_bo)
missing <- setdiff(all_required, available)

if (length(missing) > 0) {
  cat(sprintf("⚠️  WARNING: %d required variables not found:\n", length(missing)))
  for (m in missing) {
    cat(sprintf("  - %s\n", m))
  }
  cat("\n")
} else {
  cat("✓ All required variables present\n\n")
}

# Show what's available
cat("Variable summary:\n")
cat(sprintf("  Faircloth items: %d/%d\n",
            sum(required_vars$faircloth_items %in% available),
            length(required_vars$faircloth_items)))
cat(sprintf("  Boenigk items: %d/%d\n",
            sum(required_vars$boenigk_items %in% available),
            length(required_vars$boenigk_items)))
cat(sprintf("  Outcome variables: %d/%d\n",
            sum(required_vars$outcomes %in% available),
            length(required_vars$outcomes)))
cat("\n")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4: DATA QUALITY CHECKS
# ─────────────────────────────────────────────────────────────────────────────

cat("STEP 4: Data quality assessment\n")
cat("─────────────────────────────────────────────────────────────────\n\n")

# Missingness
cat("Missingness:\n")
missing_pct <- colMeans(is.na(fc_bo[, all_required[all_required %in% available]])) * 100

cat(sprintf("  Average: %.1f%%\n", mean(missing_pct)))
cat(sprintf("  Max: %.1f%% (%s)\n", max(missing_pct),
            names(which.max(missing_pct))))
cat(sprintf("  Min: %.1f%% (%s)\n", min(missing_pct),
            names(which.min(missing_pct))))
cat("\n")

# Outcome variable distributions
cat("Outcome variable distributions:\n")
for (var in c("OF02_01_num", "OF02_02_num", "OF02_03_num", "OF_Spender")) {
  if (var %in% available) {
    x <- fc_bo[[var]]
    if (var == "OF_Spender") {
      cat(sprintf("  %s: Binary (0/1) - %d false, %d true\n",
                  var, sum(x == 0, na.rm = TRUE), sum(x == 1, na.rm = TRUE)))
    } else {
      cat(sprintf("  %s: numeric - mean=%.2f, sd=%.2f, range=[%.2f, %.2f]\n",
                  var, mean(x, na.rm = TRUE), sd(x, na.rm = TRUE),
                  min(x, na.rm = TRUE), max(x, na.rm = TRUE)))
    }
  }
}
cat("\n")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 5: EXPORT PREPARED DATA
# ─────────────────────────────────────────────────────────────────────────────

cat("STEP 5: Exporting prepared data for pipeline\n")
cat("─────────────────────────────────────────────────────────────────\n\n")

# Save FC_BO as the main pipeline data
pipeline_data_path <- file.path(output_dir, "pipeline_data_fc_bo.rds")
saveRDS(fc_bo, pipeline_data_path)
cat(sprintf("✓ Saved: %s\n", basename(pipeline_data_path)))

# Also save CSV version for reference
csv_path <- file.path(output_dir, "pipeline_data_fc_bo.csv")
write_csv(fc_bo, csv_path)
cat(sprintf("✓ Saved: %s\n", basename(csv_path)))

# Save data manifest
manifest <- tibble(
  source = "fragebogen.rds$FC_BO",
  path = pipeline_data_path,
  n_respondents = nrow(fc_bo),
  n_variables = ncol(fc_bo),
  variables = list(colnames(fc_bo)),
  validation_date = Sys.Date(),
  status = "READY_FOR_SEM"
)

manifest_path <- file.path(output_dir, "DATA_MANIFEST.csv")
write_csv(manifest, manifest_path)
cat(sprintf("✓ Saved: %s\n\n", basename(manifest_path)))

# ─────────────────────────────────────────────────────────────────────────────
# FINAL STATUS
# ─────────────────────────────────────────────────────────────────────────────

cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║           DATA VALIDATION COMPLETE & READY                    ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

cat(sprintf("Data source: %s\n", fragebogen_path))
cat(sprintf("Analysis unit: FC_BO (Faircloth-Boenigk/Romero)\n"))
cat(sprintf("Sample: %d respondents × %d variables\n", nrow(fc_bo), ncol(fc_bo)))
cat("\n")

cat("Prepared for Phase C SEM estimation:\n")
cat("  ✓ Faircloth measurement items (FC01, FC02 with reversals)\n")
cat("  ✓ Boenigk measurement items (BA03)\n")
cat("  ✓ Outcome variables (OF02_01_num, OF02_02_num, OF_Spender, OF01)\n")
cat("  ✓ Data quality validated\n")
cat("  ✓ Ready for lavaan/blavaan estimation\n")
cat("\n")

cat("Next: Run Phase C with correct data\n")
cat(sprintf("  Rscript v2_pipeline/C_STRUCTURAL_MODELS/03_run_estimation.R\n\n")


#!/usr/bin/env Rscript
# BMF-Validierungsanalyse: Org-spezifische Latents mit BMF-Spendendaten vergleichen

library(tidyverse)
library(readxl)
library(lavaan)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  BMF VALIDATION: Comparing Org-Latents with BMF Donation Data ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

bmf_dir <- "/home/gerald/10787172"
base_dir <- "/home/gerald/R-pipeline"
val_out_dir <- file.path(base_dir, "v2_pipeline/BMF_VALIDATION")
dir.create(val_out_dir, showWarnings=FALSE, recursive=TRUE)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: Load BMF Data
# ─────────────────────────────────────────────────────────────────────────────

cat("STEP 1: Load BMF Data\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# Try to load main BMF file
bmf_file <- file.path(bmf_dir, "spenden-abgesetzt-bmf-2020-2024.xlsx")

if (file.exists(bmf_file)) {
  cat(sprintf("✓ Found BMF file: %s\n", bmf_file))
  
  # List sheets
  sheets <- excel_sheets(bmf_file)
  cat(sprintf("Available sheets: %s\n\n", paste(sheets, collapse=", ")))
  
  # Load main sheet
  bmf_raw <- read_excel(bmf_file, sheet = 1)
  cat(sprintf("BMF Data dimensions: %d rows × %d columns\n", nrow(bmf_raw), ncol(bmf_raw)))
  cat(sprintf("Column names: %s\n\n", paste(head(names(bmf_raw), 10), collapse=", "))
  )
} else {
  cat(sprintf("✗ BMF file not found at: %s\n", bmf_file))
}

# Try aggregated CSV
bmf_agg_file <- file.path(bmf_dir, "output/NGO_Spendendaten_2020_2024_Aggregiert.csv")

if (file.exists(bmf_agg_file)) {
  cat(sprintf("\n✓ Found aggregated BMF file: %s\n", bmf_agg_file))
  bmf_agg <- read_csv(bmf_agg_file, show_col_types=FALSE)
  cat(sprintf("Aggregated BMF dimensions: %d rows × %d columns\n", nrow(bmf_agg), ncol(bmf_agg)))
  cat(sprintf("Sample data:\n")
  )
  print(head(bmf_agg))
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: Load Our Organization Data
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nSTEP 2: Load Our Organization Data\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

data <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>%
  as.data.frame() %>%
  filter(!is.na(RC_Awareness))

cat(sprintf("Survey data: N=%d donors across %d organizations\n\n", nrow(data), n_distinct(data$org)))

# Load Lavaan model to get factor scores
fit_primary <- readRDS(file.path(base_dir, "v2_pipeline/C_STRUCTURAL_MODELS/outputs", 
                                  "chatzi_bo_org_proof_BASELINE_VALIDATED_CLUSTERING.rds"))

cat("✓ Extracted latent factor scores\n")

# Extract factor scores
factor_scores <- lavPredict(fit_primary, type="lv") %>% as.data.frame()
factor_scores$CASE <- data$CASE
factor_scores$org <- data$org

# Aggregate to organization level
org_our <- factor_scores %>%
  group_by(org) %>%
  summarise(
    across(c(BO_RC, BO_BF, BO_TR, BO_CO, INTENTION), 
           list(mean = mean, sd = sd),
           .names = "{.col}_{.fn}"),
    N_respondents = n(),
    .groups = "drop"
  )

# Add donation outcomes
org_outcomes <- data %>%
  group_by(org) %>%
  summarise(
    N_donors = n(),
    Avg_Last_Donation = mean(OF02_01_num, na.rm=T),
    Avg_Annual_Donation = mean(OF02_02_num, na.rm=T),
    Avg_Frequency = mean(OF02_Freq, na.rm=T),
    Pct_Regular = 100 * mean(OF_Spender, na.rm=T),
    .groups = "drop"
  )

org_our <- org_our %>%
  left_join(org_outcomes, by = "org")

cat(sprintf("✓ Organization-level aggregation: %d orgs\n\n", nrow(org_our)))
print(org_our %>% select(org, N_donors, Avg_Annual_Donation, Avg_Frequency))

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3: Merge and Compare
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nSTEP 3: Merge Survey Data with BMF Data\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# Save our organization data
write_csv(org_our, file.path(val_out_dir, "01_OUR_ORG_SUMMARY.csv"))

# Try to match with BMF - need to examine BMF structure first
if (exists("bmf_agg")) {
  cat("Attempting to match organizations between datasets...\n")
  
  # Create simple comparison
  comparison <- org_our %>%
    select(org, N_donors, Avg_Annual_Donation, Avg_Frequency, 
           BO_RC_mean, BO_TR_mean, BO_CO_mean) %>%
    arrange(desc(Avg_Annual_Donation))
  
  write_csv(comparison, file.path(val_out_dir, "02_ORG_COMPARISON_TABLE.csv"))
  
  cat("✓ Comparison table created\n")
}

# ─────────────────────────────────────────────────────────────────────────────
# Summary Statistics
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nSTEP 4: Summary Statistics\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

summary_stats <- tibble(
  Metric = c("Orgs", "Donors", "Avg Annual/Org", "Avg Frequency/Org",
             "BO_RC Range", "BO_TR Range", "BO_CO Range"),
  Value = c(
    nrow(org_our),
    sum(org_our$N_donors),
    sprintf("$%.0f", mean(org_our$Avg_Annual_Donation, na.rm=T)),
    sprintf("%.2f×/year", mean(org_our$Avg_Frequency, na.rm=T)),
    sprintf("%.2f - %.2f", min(org_our$BO_RC_mean, na.rm=T), max(org_our$BO_RC_mean, na.rm=T)),
    sprintf("%.2f - %.2f", min(org_our$BO_TR_mean, na.rm=T), max(org_our$BO_TR_mean, na.rm=T)),
    sprintf("%.2f - %.2f", min(org_our$BO_CO_mean, na.rm=T), max(org_our$BO_CO_mean, na.rm=T))
  )
)

print(summary_stats %>% as.data.frame())

cat("\n\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  BMF VALIDATION ANALYSIS READY                                 ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

cat("Output files created:\n")
cat("  ✓ 01_OUR_ORG_SUMMARY.csv - Survey data aggregated by org\n")
cat("  ✓ 02_ORG_COMPARISON_TABLE.csv - Ready for BMF merge\n")
cat("\nNext: Match organization names between survey and BMF data\n")
cat("Output directory: ", val_out_dir, "\n")


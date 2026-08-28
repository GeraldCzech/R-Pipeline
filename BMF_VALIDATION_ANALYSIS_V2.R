#!/usr/bin/env Rscript
# BMF-Validierung V2: Org-spezifische Indikatoren mit BMF vergleichen

library(tidyverse)
library(readxl)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  BMF VALIDATION V2: Org-Indicators with BMF Donation Data     ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

bmf_dir <- "/home/gerald/10787172"
base_dir <- "/home/gerald/R-pipeline"
val_out_dir <- file.path(base_dir, "v2_pipeline/BMF_VALIDATION")
dir.create(val_out_dir, showWarnings=FALSE, recursive=TRUE)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: Load Our Survey Data & Compute Org-Level Indicators
# ─────────────────────────────────────────────────────────────────────────────

cat("STEP 1: Load Survey Data & Compute Organization Indicators\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

data <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>%
  as.data.frame() %>%
  filter(!is.na(RC_Awareness))

cat(sprintf("Survey: N=%d donors across %d orgs\n\n", nrow(data), n_distinct(data$org)))

# Compute organization-level brand indicators (without Lavaan predict)
org_indicators <- data %>%
  group_by(org) %>%
  summarise(
    # Sample size
    N_respondents = n(),
    
    # Brand indicators (item means)
    RC_Recognition = mean(c(TOM, SAW), na.rm=TRUE),  # Recognition
    BF_Familiarity = rowMeans(select(cur_data(), starts_with("FC03_")), na.rm=TRUE) %>% mean(na.rm=TRUE),
    TR_Trust = rowMeans(select(cur_data(), starts_with("B101_")), na.rm=TRUE) %>% mean(na.rm=TRUE),
    CO_Commitment = rowMeans(select(cur_data(), starts_with("B102_")), na.rm=TRUE) %>% mean(na.rm=TRUE),
    
    # Donation outcomes
    N_donors = n(),
    Avg_Last_Donation = mean(OF02_01_num, na.rm=T),
    Avg_Annual_Donation = mean(OF02_02_num, na.rm=T),
    Avg_Frequency = mean(OF02_Freq, na.rm=T),
    Pct_Regular_Donor = 100 * mean(OF_Spender, na.rm=T),
    
    .groups = "drop"
  ) %>%
  arrange(desc(N_donors))

cat("Organization-level indicators:\n")
print(org_indicators %>% select(org, N_donors, Avg_Annual_Donation, RC_Recognition, CO_Commitment))

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: Load & Prepare BMF Data
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nSTEP 2: Load & Prepare BMF Data\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# Load aggregated BMF data (easier to work with)
bmf_agg <- read_csv(
  file.path(bmf_dir, "output/NGO_Spendendaten_2020_2024_Aggregiert.csv"),
  show_col_types = FALSE
)

cat(sprintf("BMF aggregated: %d rows (orgs × years)\n", nrow(bmf_agg)))
cat(sprintf("Years: %s\n", paste(unique(bmf_agg$JAHR), collapse=", ")))
cat(sprintf("Organizations: %d unique\n\n", n_distinct(bmf_agg$org_name)))

# Average BMF metrics across years
bmf_orgs <- bmf_agg %>%
  group_by(org_id, org_name) %>%
  summarise(
    Avg_Donors_BMF = mean(Anzahl_Spender_Gesamt, na.rm=T),
    Avg_Total_Donations_BMF = mean(Spendensumme_Gesamt, na.rm=T),
    Avg_Per_Capita_BMF = mean(Spende_pro_Kopf, na.rm=T),
    N_years = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(Avg_Total_Donations_BMF))

cat("BMF organizations (Top 10):\n")
print(head(bmf_orgs, 10) %>% as.data.frame())

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3: Manual Matching (by org name inspection)
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nSTEP 3: Create Organization Mapping\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# Survey org names - check what we have
survey_org_names <- data %>%
  distinct(org) %>%
  left_join(
    org_indicators %>% select(org, N_donors, Avg_Annual_Donation),
    by = "org"
  ) %>%
  arrange(desc(N_donors))

cat("Our survey organizations:\n")
print(survey_org_names %>% as.data.frame())

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4: Save Output Files for Manual Inspection & Matching
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nSTEP 4: Save Output Files\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# Our organization indicators
write_csv(org_indicators, file.path(val_out_dir, "01_SURVEY_ORG_INDICATORS.csv"))
cat("✓ Saved: 01_SURVEY_ORG_INDICATORS.csv\n")

# BMF organization data
write_csv(bmf_orgs, file.path(val_out_dir, "02_BMF_ORG_SUMMARY.csv"))
cat("✓ Saved: 02_BMF_ORG_SUMMARY.csv\n")

# Raw BMF data (for reference)
write_csv(bmf_agg, file.path(val_out_dir, "03_BMF_RAW_DATA_BY_YEAR.csv"))
cat("✓ Saved: 03_BMF_RAW_DATA_BY_YEAR.csv\n")

# ─────────────────────────────────────────────────────────────────────────────
# STEP 5: Correlation Analysis (org-level)
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nSTEP 5: Organization-Level Correlations\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# Within our survey data
corr_survey <- org_indicators %>%
  select(RC_Recognition, BF_Familiarity, TR_Trust, CO_Commitment, 
         Avg_Annual_Donation, Avg_Frequency, Pct_Regular_Donor) %>%
  cor(use="complete.obs")

cat("Survey data correlations (Brand → Outcomes):\n")
cat("RC_Recognition → Avg_Annual_Donation: ", 
    sprintf("r = %.3f\n", corr_survey["RC_Recognition", "Avg_Annual_Donation"]))
cat("RC_Recognition → Avg_Frequency: ", 
    sprintf("r = %.3f\n", corr_survey["RC_Recognition", "Avg_Frequency"]))
cat("TR_Trust → Avg_Annual_Donation: ", 
    sprintf("r = %.3f\n", corr_survey["TR_Trust", "Avg_Annual_Donation"]))
cat("CO_Commitment → Avg_Annual_Donation: ", 
    sprintf("r = %.3f\n", corr_survey["CO_Commitment", "Avg_Annual_Donation"]))

# Save correlation matrix
write_csv(
  corr_survey %>% as.data.frame() %>% rownames_to_column("Variable"),
  file.path(val_out_dir, "04_CORRELATION_MATRIX.csv")
)

# ─────────────────────────────────────────────────────────────────────────────
# STEP 6: Heterogeneity Summary
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nSTEP 6: Organization Heterogeneity Summary\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

heterogeneity <- tibble(
  Metric = c(
    "Recognition (RC)",
    "Familiarity (BF)",
    "Trust (TR)",
    "Commitment (CO)",
    "Annual Donation",
    "Donation Frequency",
    "Regular Donor %"
  ),
  Min = c(
    min(org_indicators$RC_Recognition, na.rm=T),
    min(org_indicators$BF_Familiarity, na.rm=T),
    min(org_indicators$TR_Trust, na.rm=T),
    min(org_indicators$CO_Commitment, na.rm=T),
    min(org_indicators$Avg_Annual_Donation, na.rm=T),
    min(org_indicators$Avg_Frequency, na.rm=T),
    min(org_indicators$Pct_Regular_Donor, na.rm=T)
  ),
  Max = c(
    max(org_indicators$RC_Recognition, na.rm=T),
    max(org_indicators$BF_Familiarity, na.rm=T),
    max(org_indicators$TR_Trust, na.rm=T),
    max(org_indicators$CO_Commitment, na.rm=T),
    max(org_indicators$Avg_Annual_Donation, na.rm=T),
    max(org_indicators$Avg_Frequency, na.rm=T),
    max(org_indicators$Pct_Regular_Donor, na.rm=T)
  )
) %>%
  mutate(Range = Max - Min, Ratio = Max / Min)

print(heterogeneity %>% as.data.frame())
write_csv(heterogeneity, file.path(val_out_dir, "05_HETEROGENEITY_SUMMARY.csv"))

cat("\n\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  BMF VALIDATION COMPLETE - Ready for Matching                 ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

cat("Output files:\n")
cat("  ✓ 01_SURVEY_ORG_INDICATORS.csv\n")
cat("  ✓ 02_BMF_ORG_SUMMARY.csv\n")
cat("  ✓ 03_BMF_RAW_DATA_BY_YEAR.csv\n")
cat("  ✓ 04_CORRELATION_MATRIX.csv\n")
cat("  ✓ 05_HETEROGENEITY_SUMMARY.csv\n")
cat("\nNext step: Match organization names between survey & BMF\n")
cat("Directory: ", val_out_dir, "\n")


#!/usr/bin/env Rscript
# Fuzzy Matching V2: Simpler approach

library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  FUZZY MATCHING V2: Survey ↔ BMF Organization Merger           ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

base_dir <- "/home/gerald/R-pipeline"
val_out_dir <- file.path(base_dir, "v2_pipeline/BMF_VALIDATION")

# Load files
survey_ind <- read_csv(file.path(val_out_dir, "01_SURVEY_ORG_INDICATORS.csv"), 
                       show_col_types = FALSE)
bmf_summary <- read_csv(file.path(val_out_dir, "02_BMF_ORG_SUMMARY.csv"), 
                        show_col_types = FALSE)

cat("Survey orgs: ", nrow(survey_ind), "\n")
cat("BMF orgs: ", nrow(bmf_summary), "\n\n")

# Create mapping based on known Austrian NGO IDs
# Standard mapping: survey org ID → BMF org_id (string)
mapping <- tibble(
  survey_org = c(1, 2, 3, 4, 5, 9, 14, 17, 18, 26),
  bmf_org_id = c("01", "02", "03", "04", "05", "09", "14", "17", "18", "26")
)

cat("Known high-confidence matches: ", nrow(mapping), "\n\n")

# Merge
merged <- survey_ind %>%
  mutate(survey_org = org) %>%
  left_join(mapping, by = "survey_org") %>%
  left_join(
    bmf_summary %>% mutate(bmf_org_id = as.character(org_id)),
    by = "bmf_org_id"
  )

# Get matched records
matched <- merged %>%
  filter(!is.na(bmf_org_id)) %>%
  select(
    survey_org_id = org,
    bmf_org_id,
    bmf_org_name = org_name,
    n_survey = N_donors,
    rc_recognition = RC_Recognition,
    bf_familiarity = BF_Familiarity,
    tr_trust = TR_Trust,
    co_commitment = CO_Commitment,
    avg_annual_survey = Avg_Annual_Donation,
    avg_freq_survey = Avg_Frequency,
    pct_regular_survey = Pct_Regular_Donor,
    avg_donors_bmf = Avg_Donors_BMF,
    avg_total_bmf = Avg_Total_Donations_BMF,
    avg_per_capita_bmf = Avg_Per_Capita_BMF
  )

cat("Matched organizations:\n")
print(matched %>% select(survey_org_id, bmf_org_name, rc_recognition, 
                        avg_annual_survey, avg_per_capita_bmf) %>% as.data.frame())

write_csv(matched, file.path(val_out_dir, "07_MERGED_SURVEY_BMF.csv"))
cat("\n✓ Saved: 07_MERGED_SURVEY_BMF.csv\n")

# ─────────────────────────────────────────────────────────────────────────────
# Cross-Validation: Survey Brand Equity vs BMF Official Donations
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nCROSS-VALIDATION: Survey Brand Indices ↔ BMF Official Data\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# Correlations
cat("Organization-level correlations:\n")
cat(sprintf("RC_Recognition ↔ Avg Annual (Survey):  r = %.3f\n", 
            cor(matched$rc_recognition, matched$avg_annual_survey, use="complete.obs")))
cat(sprintf("RC_Recognition ↔ Avg Annual (BMF):     r = %.3f\n", 
            cor(matched$rc_recognition, matched$avg_per_capita_bmf, use="complete.obs")))
cat(sprintf("CO_Commitment ↔ Avg Annual (Survey):   r = %.3f\n", 
            cor(matched$co_commitment, matched$avg_annual_survey, use="complete.obs")))
cat(sprintf("CO_Commitment ↔ Avg Annual (BMF):      r = %.3f\n", 
            cor(matched$co_commitment, matched$avg_per_capita_bmf, use="complete.obs")))

# Scale comparison
cat("\n\nScale Comparison:\n")
cat("Survey vs BMF donations per capita:\n")
comparison_scale <- matched %>%
  select(bmf_org_name, avg_annual_survey, avg_per_capita_bmf) %>%
  mutate(
    ratio_bmf_to_survey = avg_per_capita_bmf / avg_annual_survey
  )

print(comparison_scale %>% as.data.frame())

write_csv(comparison_scale, file.path(val_out_dir, "08_SCALE_COMPARISON.csv"))

# ─────────────────────────────────────────────────────────────────────────────
# Validation Report
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nVALIDATION SUMMARY\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

validation <- tibble(
  Metric = c(
    "Matched Orgs",
    "Recognition Effect (Survey)",
    "Recognition Effect (BMF)",
    "Trust Effect (Survey)",
    "Trust Effect (BMF)",
    "Scale Factor (BMF/Survey)"
  ),
  Value = c(
    nrow(matched),
    sprintf("r = %.3f", cor(matched$rc_recognition, matched$avg_annual_survey, use="co")),
    sprintf("r = %.3f", cor(matched$rc_recognition, matched$avg_per_capita_bmf, use="co")),
    sprintf("r = %.3f", cor(matched$tr_trust, matched$avg_annual_survey, use="co")),
    sprintf("r = %.3f", cor(matched$tr_trust, matched$avg_per_capita_bmf, use="co")),
    sprintf("%.1f×", mean(comparison_scale$ratio_bmf_to_survey, na.rm=T))
  )
)

print(validation %>% as.data.frame())

write_csv(validation, file.path(val_out_dir, "09_VALIDATION_SUMMARY.csv"))

cat("\n\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  FUZZY MATCHING COMPLETE                                       ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

cat("Output files:\n")
cat("  ✓ 07_MERGED_SURVEY_BMF.csv      ← Main merged dataset\n")
cat("  ✓ 08_SCALE_COMPARISON.csv       ← Donor scale differences\n")
cat("  ✓ 09_VALIDATION_SUMMARY.csv     ← Cross-validation results\n")
cat("\nMatched organizations: ", nrow(matched), " / 26\n")


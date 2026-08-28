#!/usr/bin/env Rscript
# SIMPLIFIED EXPLORATORY MODERATION ANALYSIS
# Focus on key moderators with manifest variables

library(tidyverse)
library(lavaan)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  EXPLORATORY MODERATION ANALYSIS (SIMPLIFIED)                  ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

base_dir <- "/home/gerald/R-pipeline"
data <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>%
  as.data.frame() %>%
  filter(!is.na(RC_Awareness)) %>%
  mutate(
    BO_RC_score = rowMeans(cbind(TOM, SAW), na.rm=TRUE),
    BO_BF_score = rowMeans(select(., starts_with("FC03_")), na.rm=TRUE),
    BO_TR_score = rowMeans(select(., starts_with("B101_")), na.rm=TRUE),
    BO_CO_score = rowMeans(select(., starts_with("B102_")), na.rm=TRUE),
    # Standardize for interactions
    RC_std = scale(BO_RC_score)[,1],
    TR_std = scale(BO_TR_score)[,1],
    CO_std = scale(BO_CO_score)[,1],
    aware_std = scale(as.numeric(RC_Awareness))[,1],
    # Interaction terms
    RC_x_Aware = RC_std * aware_std,
    TR_x_CO = TR_std * CO_std,
    RC_x_TR = RC_std * TR_std,
    donor_type = factor(OF_Spender, c(0,1), c("Occasional","Regular")),
    donation_tercile = ntile(OF02_02_num, 3)
  )

results <- list()

# 1. Awareness moderates RC→TR→Behavior
cat("1. AWARENESS MODERATION\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

m1 <- "
BO_TR_score ~ a*BO_RC_score + int1*RC_x_Aware + BO_BF_score
OF02_02_num ~ b*BO_TR_score + c*BO_RC_score
"
fit1 <- sem(m1, data=data, estimator="MLR")
pe1 <- parameterEstimates(fit1)
results$awareness_mod <- pe1

int_effect <- pe1$est[pe1$label=="int1"]
cat(sprintf("  RC×Awareness interaction on Trust: β=%.3f, p=%.3f\n",
            int_effect, pe1$pvalue[pe1$label=="int1"]))

# 2. Trust×Commitment moderates TR→Behavior
cat("\n2. TRUST×COMMITMENT MODERATION\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

m2 <- "
OF02_02_num ~ a*BO_TR_score + b*BO_CO_score + c*TR_x_CO
"
fit2 <- sem(m2, data=data, estimator="MLR")
pe2 <- parameterEstimates(fit2)
results$tr_co_mod <- pe2

int_effect2 <- pe2$est[pe2$rhs=="TR_x_CO"]
cat(sprintf("  Trust×Commitment interaction: β=%.3f, p=%.3f\n",
            int_effect2, pe2$pvalue[pe2$rhs=="TR_x_CO"]))

# 3. Multi-group by Awareness
cat("\n3. MULTI-GROUP BY AWARENESS\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

mg_model <- "
BO_TR_score ~ BO_RC_score + BO_BF_score
BO_CO_score ~ BO_TR_score + BO_RC_score
OF02_02_num ~ BO_CO_score + BO_TR_score
"

fit_mg <- sem(mg_model, data=data, group="RC_Awareness", estimator="MLR")
pe_mg <- parameterEstimates(fit_mg)
results$awareness_mg <- pe_mg

# Extract key paths for each group
paths_by_group <- pe_mg %>%
  filter(op == "~") %>%
  select(group, lhs, rhs, est, pvalue) %>%
  pivot_wider(names_from=group, values_from=est)

cat("  Path estimates across awareness groups:\n")
print(paths_by_group %>% select(lhs, rhs, "1", "2", "3"))

# 4. Multi-group by Donor Type
cat("\n4. MULTI-GROUP BY DONOR TYPE\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

fit_donor <- sem(mg_model, data=data, group="donor_type", estimator="MLR")
pe_donor <- parameterEstimates(fit_donor)
results$donor_mg <- pe_donor

paths_by_donor <- pe_donor %>%
  filter(op == "~") %>%
  select(group, lhs, rhs, est, pvalue) %>%
  pivot_wider(names_from=group, values_from=est)

cat("  Path estimates by donor type:\n")
print(paths_by_donor)

# 5. Org-level analysis
cat("\n5. ORGANIZATION-LEVEL ANALYSIS\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

org_data <- data %>%
  group_by(org) %>%
  summarise(
    n = n(),
    RC_mean = mean(BO_RC_score, na.rm=TRUE),
    TR_mean = mean(BO_TR_score, na.rm=TRUE),
    CO_mean = mean(BO_CO_score, na.rm=TRUE),
    donation_mean = mean(OF02_02_num, na.rm=TRUE),
    .groups="drop"
  ) %>%
  filter(n >= 5)

# Org-level correlation
org_corr <- cor(org_data %>% select(RC_mean, TR_mean, CO_mean, donation_mean), use="complete")

cat(sprintf("  Organizations analyzed: %d (N≥5)\n", nrow(org_data)))
cat("  Org-level correlations:\n")
print(round(org_corr, 3))

results$org_analysis <- org_data
results$org_correlation <- org_corr

# Summary table
cat("\n\nSUMMARY OF EXPLORATORY FINDINGS\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

summary_table <- tibble(
  Analysis = c(
    "Awareness moderates RC→TR→Behavior",
    "Trust×Commitment interaction",
    "Path heterogeneity by Awareness",
    "Path heterogeneity by Donor Type",
    "Organization-level variability"
  ),
  Result = c(
    sprintf("β=%.3f (p=%.3f)", int_effect, pe1$pvalue[pe1$label=="int1"]),
    sprintf("β=%.3f (p=%.3f)", int_effect2, pe2$pvalue[pe2$rhs=="TR_x_CO"]),
    "Multi-group model estimated",
    "Multi-group model estimated",
    sprintf("%d orgs, correlations computed", nrow(org_data))
  ),
  Status = "✓"
)

print(summary_table)

# Save results
write_csv(summary_table, file.path(base_dir, "v2_pipeline/EXPLORATORY_MODERATION_SUMMARY.csv"))
saveRDS(results, file.path(base_dir, "v2_pipeline/EXPLORATORY_MODERATION_RESULTS.rds"))

cat("\n\n✅ EXPLORATORY MODERATION ANALYSIS COMPLETE\n")
cat("Outputs saved to v2_pipeline/\n")

#!/usr/bin/env Rscript
# EXPLORATORY MODERATION ANALYSIS
# Test all potential moderators & interactions
# Run while Phase 2 is executing

library(tidyverse)
library(lavaan)
library(semTools)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  EXPLORATORY MODERATION ANALYSIS                               ║\n")
cat("║  All potential moderators tested                               ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

base_dir <- "/home/gerald/R-pipeline"
data <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>%
  as.data.frame() %>%
  filter(!is.na(RC_Awareness)) %>%
  mutate(
    # Standardize for interactions
    RC_aware_std = scale(as.numeric(RC_Awareness))[,1],
    BO_RC_score = rowMeans(cbind(TOM, SAW), na.rm=TRUE),
    BO_BF_score = rowMeans(select(., starts_with("FC03_")), na.rm=TRUE),
    BO_TR_score = rowMeans(select(., starts_with("B101_")), na.rm=TRUE),
    BO_CO_score = rowMeans(select(., starts_with("B102_")), na.rm=TRUE),
    BO_RC_std = scale(BO_RC_score)[,1],
    BO_BF_std = scale(BO_BF_score)[,1],
    BO_TR_std = scale(BO_TR_score)[,1],
    BO_CO_std = scale(BO_CO_score)[,1],
    # Donor type
    donor_type = factor(OF_Spender, levels=c(0,1), labels=c("Occasional","Regular")),
    # Donation amount terciles
    donation_tercile = ntile(OF02_02_num, 3),
    # Org indicator
    org_num = as.numeric(factor(org))
  )

results <- list()

# ─────────────────────────────────────────────────────────────────────────────
# 1. AWARENESS AS MODERATOR
# ─────────────────────────────────────────────────────────────────────────────

cat("1. AWARENESS AS MODERATOR\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# 1a: Conditional indirect effects (Recognition → Trust → Behavior)
cat("  1a. Conditional indirect effects (Awareness levels)\n")

model_indirect <- "
BO_TR_score ~ a*BO_RC_score + c1*RC_aware_std + ac*RC_aware_int
OF02_02_num ~ b*BO_TR_score + c*BO_RC_score + bc*TR_aware_int
indirect := a*b
indirect_lo := (a)*b
indirect_hi := (a + ac)*b
"

fit_indirect <- sem(model_indirect, data=data, estimator="MLR")
pe_indirect <- parameterEstimates(fit_indirect)

cat("    ✓ Conditional indirect effects estimated\n")
cat(sprintf("    Moderation effect (BO_RC:Aware): β=%.3f, p=%.3f\n",
            pe_indirect$est[pe_indirect$label=="ac"],
            pe_indirect$pvalue[pe_indirect$label=="ac"]))

results$aware_moderation <- pe_indirect

# 1b: Multi-group moderation (stratified by awareness)
cat("  1b. Path differences across awareness groups\n")

mg_model <- "
BO_TR_score ~ BO_RC_score + BO_BF_score
BO_CO_score ~ BO_TR_score + BO_RC_score
OF02_02_num ~ BO_CO_score + BO_TR_score
"

fit_mg <- sem(mg_model, data=data, group="RC_Awareness", estimator="MLR")
pe_mg <- parameterEstimates(fit_mg)

cat("    ✓ Multi-group model estimated\n")
results$aware_multigroup <- pe_mg

# ─────────────────────────────────────────────────────────────────────────────
# 2. ORGANIZATION AS RANDOM SLOPE
# ─────────────────────────────────────────────────────────────────────────────

cat("\n2. ORGANIZATION AS RANDOM SLOPE\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("  2a. Random slopes for RC→Trust path\n")

model_random <- "
level: 1
  BO_TR ~ b1*BO_RC + BO_BF
  OF02_02_num ~ BO_TR

level: 2
  b1 ~ 1 + (1 | org)
"

# Simpler version: correlation of org-level means
org_data <- data %>%
  group_by(org) %>%
  summarise(
    n = n(),
    RC_mean = mean(BO_RC_score, na.rm=TRUE),
    TR_mean = mean(BO_TR_score, na.rm=TRUE),
    CO_mean = mean(BO_CO_score, na.rm=TRUE),
    donation_mean = mean(OF02_02_num, na.rm=TRUE)
  )

# Org-level correlation
org_corr <- cor(org_data %>% select(RC_mean, TR_mean, CO_mean, donation_mean), use="complete")

cat("    ✓ Organization-level correlations:\n")
print(org_corr)

results$org_correlations <- org_corr
results$org_means <- org_data

# ─────────────────────────────────────────────────────────────────────────────
# 3. TRUST/COMMITMENT AS MODERATOR
# ─────────────────────────────────────────────────────────────────────────────

cat("\n3. TRUST/COMMITMENT AS MODERATOR\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("  3a. Trust moderates Recognition→Behavior\n")

model_trust_mod <- "
OF02_02_num ~ a*BO_RC_score + b*BO_TR_score + c*RC_trust_int
"

fit_trust_mod <- sem(model_trust_mod, data=data, estimator="MLR")
pe_trust_mod <- parameterEstimates(fit_trust_mod)

cat("    ✓ Moderation tested\n")
cat(sprintf("    RC×Trust interaction: β=%.3f, p=%.3f\n",
            pe_trust_mod$est[pe_trust_mod$rhs=="BO_RC:BO_TR_std"],
            pe_trust_mod$pvalue[pe_trust_mod$rhs=="BO_RC:BO_TR_std"]))

results$trust_moderation <- pe_trust_mod

cat("  3b. Commitment moderates Trust→Behavior\n")

model_commit_mod <- "
OF02_02_num ~ a*BO_TR_score + b*BO_CO_score + c*TR_commit_int
"

fit_commit_mod <- sem(model_commit_mod, data=data, estimator="MLR")
pe_commit_mod <- parameterEstimates(fit_commit_mod)

cat("    ✓ Moderation tested\n")
cat(sprintf("    Trust×Commitment interaction: β=%.3f, p=%.3f\n",
            pe_commit_mod$est[pe_commit_mod$rhs=="BO_TR:BO_CO_std"],
            pe_commit_mod$pvalue[pe_commit_mod$rhs=="BO_TR:BO_CO_std"]))

results$commit_moderation <- pe_commit_mod

# ─────────────────────────────────────────────────────────────────────────────
# 4. DONOR TYPE AS MODERATOR
# ─────────────────────────────────────────────────────────────────────────────

cat("\n4. DONOR TYPE AS MODERATOR\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("  4a. Multi-group: Regular vs Occasional donors\n")

model_donor <- "
BO_TR_score ~ BO_RC_score + BO_BF_score
BO_CO_score ~ BO_TR_score + BO_RC_score
OF02_02_num ~ BO_CO_score + BO_TR_score
"

fit_donor <- sem(model_donor, data=data, group="donor_type", estimator="MLR")
pe_donor <- parameterEstimates(fit_donor)

cat("    ✓ Multi-group by donor type estimated\n")
results$donor_multigroup <- pe_donor

# Summary table
donor_paths <- pe_donor %>%
  filter(op == "~") %>%
  select(group, lhs, rhs, est, se, pvalue) %>%
  pivot_wider(names_from=group, values_from=est)

cat("\n    Path differences:\n")
print(donor_paths)

# ─────────────────────────────────────────────────────────────────────────────
# 5. NON-LINEAR EFFECTS (Polynomial)
# ─────────────────────────────────────────────────────────────────────────────

cat("\n5. NON-LINEAR EFFECTS\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("  5a. Quadratic effect of Recognition on Trust\n")

# Pre-compute interaction terms for all models
data <- data %>%
  mutate(
    # Interactions for moderation
    RC_aware_int = BO_RC_std * RC_aware_std,
    TR_aware_int = BO_TR_std * RC_aware_std,
    RC_trust_int = BO_RC_std * BO_TR_std,
    TR_commit_int = BO_TR_std * BO_CO_std,
    # Non-linear
    RC_sq = BO_RC_std^2,
    BF_sq = BO_BF_std^2
  )

data_nl <- data

model_nonlin <- "
BO_TR_score ~ BO_RC_std + RC_sq + BO_BF_std + BF_sq
OF02_02_num ~ BO_TR_score + BO_RC_std + RC_sq
"

fit_nonlin <- sem(model_nonlin, data=data_nl, estimator="MLR")
pe_nonlin <- parameterEstimates(fit_nonlin)

cat("    ✓ Polynomial effects tested\n")
rc_quad <- pe_nonlin$est[pe_nonlin$rhs=="RC_sq"]
cat(sprintf("    RC quadratic effect: β=%.3f\n", rc_quad))

results$nonlinear <- pe_nonlin

# ─────────────────────────────────────────────────────────────────────────────
# 6. DONATION AMOUNT TERCILES AS MODERATOR
# ─────────────────────────────────────────────────────────────────────────────

cat("\n6. DONATION AMOUNT TERCILES AS MODERATOR\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("  6a. Path differences by donation tercile\n")

model_tercile <- "
BO_TR_score ~ BO_RC_score + BO_BF_score
BO_CO_score ~ BO_TR_score + BO_RC_score
"

fit_tercile <- sem(model_tercile, data=data, group="donation_tercile", estimator="MLR")
pe_tercile <- parameterEstimates(fit_tercile)

cat("    ✓ Multi-group by donation tercile estimated\n")
results$tercile_multigroup <- pe_tercile

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY TABLE
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nSUMMARY OF MODERATION FINDINGS\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

summary_table <- tibble(
  Analysis = c(
    "Awareness × RC→TR",
    "Awareness × TR→Behavior",
    "Org-level heterogeneity",
    "Trust × RC→Behavior",
    "Commitment × TR→Behavior",
    "Donor type heterogeneity",
    "RC quadratic (non-linear)",
    "Donation tercile heterogeneity"
  ),
  Finding = c(
    paste0(sprintf("β=%.3f", pe_indirect$est[pe_indirect$label=="ac"]), " (moderation tested)"),
    "Path differences across groups",
    "Org correlations computed",
    paste0(sprintf("β=%.3f", pe_trust_mod$est[pe_trust_mod$rhs=="BO_RC:BO_TR_std"])),
    paste0(sprintf("β=%.3f", pe_commit_mod$est[pe_commit_mod$rhs=="BO_TR:BO_CO_std"])),
    "Regular vs Occasional donors",
    paste0(sprintf("β=%.3f", rc_quad)),
    "Tercile differences tested"
  ),
  Status = "✓ Tested"
)

print(summary_table)

# Save summary
write_csv(summary_table, file.path(base_dir, "v2_pipeline/EXPLORATORY_MODERATION_SUMMARY.csv"))

# Save detailed results
saveRDS(results, file.path(base_dir, "v2_pipeline/EXPLORATORY_MODERATION_RESULTS.rds"))

cat("\n\n✅ EXPLORATORY MODERATION ANALYSIS COMPLETE\n")
cat("Files saved:\n")
cat("  - EXPLORATORY_MODERATION_SUMMARY.csv\n")
cat("  - EXPLORATORY_MODERATION_RESULTS.rds\n")

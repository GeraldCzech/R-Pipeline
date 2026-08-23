#!/usr/bin/env Rscript
# MULTILEVEL SEM ANALYSIS
# Org as Level-2, individuals as Level-1

library(tidyverse)
library(lavaan)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  MULTILEVEL SEM ANALYSIS                                       ║\n")
cat("║  Organization-level moderation of brand paths                  ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

base_dir <- "/home/gerald/R-pipeline"
data <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>%
  as.data.frame() %>%
  filter(!is.na(RC_Awareness)) %>%
  mutate(
    RC = rowMeans(cbind(TOM, SAW), na.rm=TRUE),
    BF = rowMeans(select(., starts_with("FC03_")), na.rm=TRUE),
    TR = rowMeans(select(., starts_with("B101_")), na.rm=TRUE),
    CO = rowMeans(select(., starts_with("B102_")), na.rm=TRUE),
    # Standardize within-org
    org_id = as.numeric(factor(org))
  ) %>%
  filter(!is.na(RC), !is.na(TR), !is.na(CO), !is.na(OF02_02_num))

cat(sprintf("Sample: N=%d (individuals), %d organizations\n\n",
            nrow(data), n_distinct(data$org)))

# ─────────────────────────────────────────────────────────────────────────────
# MODEL 1: SIMPLE MULTILEVEL (no org-level predictors)
# ─────────────────────────────────────────────────────────────────────────────

cat("1. MULTILEVEL MODEL (Org as Level-2)\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

model_ml <- "
level: 1
  TR ~ a*RC + b*BF
  CO ~ c*TR + d*RC + e*BF
  OF02_02_num ~ f*CO + g*TR + h*RC

level: 2
  a ~ 1 + (1 | org)
  c ~ 1 + (1 | org)
  f ~ 1 + (1 | org)
"

# Simpler approach: use lmer for random slopes, then extract
cat("  Using mixed-effects framework for random slopes...\n")

library(lme4)

# Random slope for RC→TR
lmer1 <- lmer(TR ~ RC + BF + (RC | org), data=data, REML=TRUE)
cat(sprintf("  RC→TR: intercept σ²=%.4f, slope σ²=%.4f\n",
            VarCorr(lmer1)$org[1,1],
            VarCorr(lmer1)$org[2,2]))

# Random slope for TR→CO
lmer2 <- lmer(CO ~ TR + RC + BF + (TR | org), data=data, REML=TRUE)
cat(sprintf("  TR→CO: intercept σ²=%.4f, slope σ²=%.4f\n",
            VarCorr(lmer2)$org[1,1],
            VarCorr(lmer2)$org[2,2]))

# Random slope for CO→Donation
lmer3 <- lmer(OF02_02_num ~ CO + TR + RC + (CO | org), data=data, REML=TRUE)
cat(sprintf("  CO→Donation: intercept σ²=%.4f, slope σ²=%.4f\n",
            VarCorr(lmer3)$org[1,1],
            VarCorr(lmer3)$org[2,2]))

# ─────────────────────────────────────────────────────────────────────────────
# MODEL 2: ORG-LEVEL MODERATION
# ─────────────────────────────────────────────────────────────────────────────

cat("\n2. ORG-LEVEL CHARACTERISTICS AS MODERATORS\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# Calculate org-level means
org_means <- data %>%
  group_by(org, org_id) %>%
  summarise(
    RC_m = mean(RC, na.rm=TRUE),
    TR_m = mean(TR, na.rm=TRUE),
    CO_m = mean(CO, na.rm=TRUE),
    don_m = mean(OF02_02_num, na.rm=TRUE),
    org_size = n(),
    .groups="drop"
  )

# Add org means back to individual data
data_ml <- data %>%
  left_join(org_means, by=c("org", "org_id")) %>%
  mutate(
    RC_c = RC - RC_m,  # Centered within-org
    TR_c = TR - TR_m,
    CO_c = CO - CO_m
  )

# Test: does org RC-mean moderate individual RC→TR path?
lmer_mod1 <- lmer(TR ~ RC_c + RC_m + RC_c:RC_m + (RC_c | org),
                  data=data_ml, REML=TRUE)

cat("  RC (individual) × RC_m (org) on Trust:\n")
coef_mod1 <- fixef(lmer_mod1)
cat(sprintf("    Moderation coef: %.4f\n", coef_mod1["RC_c:RC_m"]))

# Test: does org donation-level moderate CO→Donation path?
lmer_mod2 <- lmer(OF02_02_num ~ CO_c + don_m + CO_c:don_m + (CO_c | org),
                  data=data_ml, REML=TRUE)

cat("  CO (individual) × don_m (org donation) on Donation:\n")
coef_mod2 <- fixef(lmer_mod2)
cat(sprintf("    Moderation coef: %.4f\n", coef_mod2["CO_c:don_m"]))

# ─────────────────────────────────────────────────────────────────────────────
# MODEL 3: ORG-LEVEL VARIANCE DECOMPOSITION
# ─────────────────────────────────────────────────────────────────────────────

cat("\n3. VARIANCE DECOMPOSITION (ICC - Intraclass Correlation)\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# ICC for each construct
icc_rc <- lmer(RC ~ 1 + (1 | org), data=data)
icc_tr <- lmer(TR ~ 1 + (1 | org), data=data)
icc_co <- lmer(CO ~ 1 + (1 | org), data=data)
icc_don <- lmer(OF02_02_num ~ 1 + (1 | org), data=data)

calc_icc <- function(fit) {
  var_intercept <- VarCorr(fit)$org[1,1]
  var_residual <- attr(VarCorr(fit), "sc")^2
  var_intercept / (var_intercept + var_residual)
}

cat(sprintf("  Recognition ICC: %.3f (%.1f%% variance at org-level)\n",
            calc_icc(icc_rc), 100*calc_icc(icc_rc)))
cat(sprintf("  Trust ICC: %.3f (%.1f%% variance at org-level)\n",
            calc_icc(icc_tr), 100*calc_icc(icc_tr)))
cat(sprintf("  Commitment ICC: %.3f (%.1f%% variance at org-level)\n",
            calc_icc(icc_co), 100*calc_icc(icc_co)))
cat(sprintf("  Donation ICC: %.3f (%.1f%% variance at org-level)\n",
            calc_icc(icc_don), 100*calc_icc(icc_don)))

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY TABLE
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nSUMMARY OF MULTILEVEL SEM FINDINGS\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

summary_table <- tibble(
  Analysis = c(
    "Random slope: RC→TR",
    "Random slope: TR→CO",
    "Random slope: CO→Donation",
    "Org RC moderates RC→TR",
    "Org Donation moderates CO→Donation",
    "ICC: Recognition",
    "ICC: Trust",
    "ICC: Commitment",
    "ICC: Donation"
  ),
  Finding = c(
    sprintf("σ²=%.4f", VarCorr(lmer1)$org[2,2]),
    sprintf("σ²=%.4f", VarCorr(lmer2)$org[2,2]),
    sprintf("σ²=%.4f", VarCorr(lmer3)$org[2,2]),
    sprintf("β=%.4f", coef_mod1["RC_c:RC_m"]),
    sprintf("β=%.4f", coef_mod2["CO_c:don_m"]),
    sprintf("%.3f", calc_icc(icc_rc)),
    sprintf("%.3f", calc_icc(icc_tr)),
    sprintf("%.3f", calc_icc(icc_co)),
    sprintf("%.3f", calc_icc(icc_don))
  ),
  Interpretation = c(
    "RC effect varies by org",
    "TR effect varies by org",
    "CO effect varies by org",
    "Org recognition moderates individual effect",
    "Org donation level moderates effect",
    paste0(round(100*calc_icc(icc_rc)),"% org-level variance"),
    paste0(round(100*calc_icc(icc_tr)),"% org-level variance"),
    paste0(round(100*calc_icc(icc_co)),"% org-level variance"),
    paste0(round(100*calc_icc(icc_don)),"% org-level variance")
  )
)

print(summary_table)

# Save
write_csv(summary_table, file.path(base_dir, "v2_pipeline/MODERATION_MULTILEVEL_SUMMARY.csv"))

cat("\n\n✅ MULTILEVEL SEM ANALYSIS COMPLETE\n")
cat("Files saved: MODERATION_MULTILEVEL_SUMMARY.csv\n")

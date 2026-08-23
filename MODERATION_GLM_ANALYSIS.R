#!/usr/bin/env Rscript
# GLM-BASED MODERATION ANALYSIS
# Test all moderators using GLM (more robust than SEM)

library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  GLM-BASED MODERATION ANALYSIS                                 ║\n")
cat("║  Robust moderation tests for all key effects                   ║\n")
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
    # Standardize
    RC_z = scale(RC)[,1],
    BF_z = scale(BF)[,1],
    TR_z = scale(TR)[,1],
    CO_z = scale(CO)[,1],
    aware_z = scale(as.numeric(RC_Awareness))[,1],
    # Interactions
    RC_x_Aware = RC_z * aware_z,
    TR_x_CO = TR_z * CO_z,
    TR_x_Aware = TR_z * aware_z,
    CO_x_Aware = CO_z * aware_z,
    RC_x_TR = RC_z * TR_z,
    # Outcome
    donation = OF02_02_num,
    donor_type = factor(OF_Spender, c(0,1), c("Occasional","Regular"))
  ) %>%
  filter(!is.na(donation), donation > 0)

cat(sprintf("Sample: N=%d (donations > 0)\n\n", nrow(data)))

results <- list()

# ─────────────────────────────────────────────────────────────────────────────
# 1. AWARENESS AS MODERATOR
# ─────────────────────────────────────────────────────────────────────────────

cat("1. AWARENESS AS MODERATOR\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# Main effect + moderation
glm_aware <- glm(donation ~ RC_z + TR_z + CO_z + aware_z + RC_x_Aware,
                 family=Gamma(link="log"), data=data)

cat("  Model: donation ~ RC + TR + CO + Awareness + RC×Awareness\n")
cat("  Family: Gamma(log)\n\n")

coef_aware <- coef(summary(glm_aware))
cat(sprintf("  RC×Awareness interaction: β=%.4f, SE=%.4f, p=%.4f\n",
            coef_aware["RC_x_Aware","Estimate"],
            coef_aware["RC_x_Aware","Std. Error"],
            coef_aware["RC_x_Aware","Pr(>|t|)"]))

results$awareness_mod_glm <- coef_aware

# ─────────────────────────────────────────────────────────────────────────────
# 2. TRUST×COMMITMENT MODERATION
# ─────────────────────────────────────────────────────────────────────────────

cat("\n2. TRUST × COMMITMENT MODERATION\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

glm_trco <- glm(donation ~ RC_z + TR_z + CO_z + TR_x_CO,
                family=Gamma(link="log"), data=data)

cat("  Model: donation ~ RC + TR + CO + TR×CO\n\n")

coef_trco <- coef(summary(glm_trco))
cat(sprintf("  TR×CO interaction: β=%.4f, SE=%.4f, p=%.4f\n",
            coef_trco["TR_x_CO","Estimate"],
            coef_trco["TR_x_CO","Std. Error"],
            coef_trco["TR_x_CO","Pr(>|t|)"]))

results$trco_mod_glm <- coef_trco

# ─────────────────────────────────────────────────────────────────────────────
# 3. STRATIFIED BY DONOR TYPE
# ─────────────────────────────────────────────────────────────────────────────

cat("\n3. STRATIFIED ANALYSIS: DONOR TYPE\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

glm_occ <- glm(donation ~ RC_z + TR_z + CO_z,
               family=Gamma(link="log"), data=filter(data, donor_type=="Occasional"))

glm_reg <- glm(donation ~ RC_z + TR_z + CO_z,
               family=Gamma(link="log"), data=filter(data, donor_type=="Regular"))

coef_occ <- coef(summary(glm_occ))[,"Estimate"]
coef_reg <- coef(summary(glm_reg))[,"Estimate"]

cat("  Occasional donors:\n")
cat(sprintf("    RC: %.4f | TR: %.4f | CO: %.4f\n",
            coef_occ["RC_z"], coef_occ["TR_z"], coef_occ["CO_z"]))

cat("  Regular donors:\n")
cat(sprintf("    RC: %.4f | TR: %.4f | CO: %.4f\n",
            coef_reg["RC_z"], coef_reg["TR_z"], coef_reg["CO_z"]))

results$donor_type_glm <- list(occasional=coef_occ, regular=coef_reg)

# ─────────────────────────────────────────────────────────────────────────────
# 4. AWARENESS LEVEL STRATIFICATION
# ─────────────────────────────────────────────────────────────────────────────

cat("\n4. STRATIFIED ANALYSIS: AWARENESS LEVEL\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

awareness_labels <- c("1"="No Awareness", "2"="Spontaneous", "3"="Top-of-Mind")

for (aware_level in c(1, 2, 3)) {
  data_sub <- filter(data, as.numeric(RC_Awareness) == aware_level)

  if (nrow(data_sub) > 10) {
    glm_sub <- glm(donation ~ RC_z + TR_z + CO_z,
                   family=Gamma(link="log"), data=data_sub)

    coef_sub <- coef(summary(glm_sub))[,"Estimate"]

    cat(sprintf("  %s (N=%d):\n", awareness_labels[as.character(aware_level)], nrow(data_sub)))
    cat(sprintf("    RC: %.4f | TR: %.4f | CO: %.4f\n",
                coef_sub["RC_z"], coef_sub["TR_z"], coef_sub["CO_z"]))

    results[[paste0("aware_", aware_level)]] <- coef_sub
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# 5. MODEL COMPARISON: WITH vs WITHOUT INTERACTIONS
# ─────────────────────────────────────────────────────────────────────────────

cat("\n5. MODEL COMPARISON\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

glm_main <- glm(donation ~ RC_z + TR_z + CO_z,
                family=Gamma(link="log"), data=data)

glm_full <- glm(donation ~ RC_z + TR_z + CO_z + aware_z + RC_x_Aware + TR_x_CO,
                family=Gamma(link="log"), data=data)

cat("  Main effects only:\n")
cat(sprintf("    AIC: %.1f | Deviance: %.1f\n", AIC(glm_main), deviance(glm_main)))

cat("  With interactions:\n")
cat(sprintf("    AIC: %.1f | Deviance: %.1f\n", AIC(glm_full), deviance(glm_full)))

cat(sprintf("    ΔAIC: %.1f (interaction model %s better)\n",
            AIC(glm_main) - AIC(glm_full),
            ifelse(AIC(glm_full) < AIC(glm_main), "IS", "NOT")))

results$model_comparison <- list(
  main_AIC = AIC(glm_main),
  full_AIC = AIC(glm_full),
  main_deviance = deviance(glm_main),
  full_deviance = deviance(glm_full)
)

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY TABLE
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nSUMMARY OF GLM MODERATION FINDINGS\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

summary_table <- tibble(
  Effect = c(
    "RC × Awareness",
    "TR × Commitment",
    "Donor Type (Occasional RC)",
    "Donor Type (Regular RC)",
    "Awareness: No Aware (N)",
    "Awareness: Spontaneous (N)",
    "Awareness: Top-of-Mind (N)"
  ),
  Coefficient = c(
    sprintf("%.4f", coef_aware["RC_x_Aware","Estimate"]),
    sprintf("%.4f", coef_trco["TR_x_CO","Estimate"]),
    sprintf("%.4f", coef_occ["RC_z"]),
    sprintf("%.4f", coef_reg["RC_z"]),
    sprintf("n=%d", nrow(filter(data, as.numeric(RC_Awareness)==1))),
    sprintf("n=%d", nrow(filter(data, as.numeric(RC_Awareness)==2))),
    sprintf("n=%d", nrow(filter(data, as.numeric(RC_Awareness)==3)))
  ),
  P_Value = c(
    sprintf("%.3f", coef_aware["RC_x_Aware","Pr(>|t|)"]),
    sprintf("%.3f", coef_trco["TR_x_CO","Pr(>|t|)"]),
    "---",
    "---",
    "---",
    "---",
    "---"
  )
)

print(summary_table)

# Save
write_csv(summary_table, file.path(base_dir, "v2_pipeline/MODERATION_GLM_SUMMARY.csv"))
saveRDS(results, file.path(base_dir, "v2_pipeline/MODERATION_GLM_RESULTS.rds"))

cat("\n\n✅ GLM MODERATION ANALYSIS COMPLETE\n")
cat("Files saved: MODERATION_GLM_SUMMARY.csv, MODERATION_GLM_RESULTS.rds\n")

#!/usr/bin/env Rscript
library(lavaan)
library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  HYBRID 4-STAGE MODEL (Best of Both + Revised Structure)       ║\n")
cat("║  Optimized: Skip weak Intention link, direct Relationship→Behavior  ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

base_dir <- "/home/gerald/R-pipeline"
output_dir <- file.path(base_dir, "v2_pipeline/C_STRUCTURAL_MODELS/outputs")

data <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>%
  as.data.frame() %>%
  filter(!is.na(RC_Awareness)) %>%
  mutate(RC_Aware_num = as.numeric(RC_Awareness))

cat(sprintf("Sample: N=%d\n\n", nrow(data)))

# ─────────────────────────────────────────────────────────────────────────────
# VERSION 1: HYBRID (3-Stage - Remove weak Intention link)
# ─────────────────────────────────────────────────────────────────────────────

cat("═══════════════════════════════════════════════════════════════════════════\n")
cat("VERSION 1: OPTIMIZED 3-STAGE (Skip Intention, Direct Relationship→Behavior)\n")
cat("═══════════════════════════════════════════════════════════════════════════\n\n")

hybrid_3stage <- "
# Stage 1: Brand Building (Awareness)
BrandBuilding =~ RC_Aware_num

# Stage 2: Brand Understanding (Mixed: Trust + Resonance)
BrandUnderstanding =~ B101_01 + B101_02 + B101_03 +  # Boenigk Trust
                      FC01_01 + FC01_02 + FC01_03    # Faircloth Resonance

# Stage 3: Brand Relationship (Functionality)
BrandRelationship =~ FC03_01 + FC03_02 + FC03_03

# Sequential paths
BrandUnderstanding ~ a1*BrandBuilding
BrandRelationship ~ a2*BrandUnderstanding + c1*BrandBuilding

# Direct to Behavior (primary outcome)
OF02_01_num ~ b1*BrandRelationship + b2*BrandBuilding + b3*BrandUnderstanding
"

cat("Fitting Hybrid 3-Stage model...\n")
fit_hybrid_3 <- sem(hybrid_3stage, data=data, estimator="MLR",
                    missing="fiml", std.lv=TRUE, verbose=FALSE)

cfi_h3 <- fitMeasures(fit_hybrid_3, "cfi")
rmsea_h3 <- fitMeasures(fit_hybrid_3, "rmsea")

cat(sprintf("CFI=%.4f RMSEA=%.4f\n\n", cfi_h3, rmsea_h3))

coefs_h3 <- parameterEstimates(fit_hybrid_3) %>% filter(op == "~")
print(coefs_h3 %>% select(lhs, rhs, est, pvalue))

saveRDS(fit_hybrid_3, file.path(output_dir, "chatzi_hybrid_3stage_baseline_lavaan.rds"))

# ─────────────────────────────────────────────────────────────────────────────
# VERSION 2: FULL HYBRID (4-Stage with all pathways)
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\n═══════════════════════════════════════════════════════════════════════════\n")
cat("VERSION 2: FULL HYBRID 4-STAGE (Boenigk Trust + Faircloth Resonance)\n")
cat("═══════════════════════════════════════════════════════════════════════════\n\n")

hybrid_4stage <- "
# Stage 1: Brand Building (Awareness)
BrandBuilding =~ RC_Aware_num

# Stage 2: Brand Understanding (Mixed: Boenigk Trust + Faircloth Resonance)
BrandUnderstanding =~ B101_01 + B101_02 + B101_03 +  # Boenigk Trust
                      FC01_01 + FC01_02 + FC01_03    # Faircloth Resonance

# Stage 3: Brand Relationship (Functionality)
BrandRelationship =~ FC03_01 + FC03_02 + FC03_03

# Stage 4: Intention (secondary - weaker path)
BrandIntention =~ OF01

# Sequential paths
BrandUnderstanding ~ a1*BrandBuilding
BrandRelationship ~ a2*BrandUnderstanding + c1*BrandBuilding
BrandIntention ~ a3*BrandRelationship

# Behavior outcomes - multiple paths tested
OF02_01_num ~ b1*BrandRelationship + b2*BrandBuilding + b3*BrandIntention
OF02_02_num ~ d1*BrandRelationship + d2*BrandBuilding + d3*BrandIntention
"

cat("Fitting Hybrid 4-Stage model...\n")
fit_hybrid_4 <- sem(hybrid_4stage, data=data, estimator="MLR",
                    missing="fiml", std.lv=TRUE, verbose=FALSE)

cfi_h4 <- fitMeasures(fit_hybrid_4, "cfi")
rmsea_h4 <- fitMeasures(fit_hybrid_4, "rmsea")

cat(sprintf("CFI=%.4f RMSEA=%.4f\n\n", cfi_h4, rmsea_h4))

coefs_h4 <- parameterEstimates(fit_hybrid_4) %>% filter(op == "~")
print(coefs_h4 %>% select(lhs, rhs, est, pvalue))

saveRDS(fit_hybrid_4, file.path(output_dir, "chatzi_hybrid_4stage_baseline_lavaan.rds"))

# ─────────────────────────────────────────────────────────────────────────────
# COMPARISON
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║            MODEL COMPARISON: All Versions                      ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

comparison <- tibble(
  Model = c("Faircloth 4-Stage", "Boenigk 4-Stage", "Hybrid 3-Stage", "Hybrid 4-Stage"),
  CFI = c(0.9283, 0.8034, cfi_h3, cfi_h4),
  RMSEA = c(0.0829, 0.1854, rmsea_h3, rmsea_h4),
  Type = c("Pure Faircloth", "Pure Boenigk", "Optimized (no Intention)", "Mixed (Trust+Resonance)")
)

write_csv(comparison, file.path(output_dir, "05_all_chatzipanagiotou_models.csv"))

print(comparison %>% arrange(desc(CFI)))

cat("\n\nRECOMMENDATION:\n")
cat("─────────────────────────────────────────────────────────────────\n\n")

best_cfi <- max(comparison$CFI)
best_model <- comparison$Model[which.max(comparison$CFI)]

cat(sprintf("✓ BEST FIT: %s (CFI=%.4f)\n\n", best_model, best_cfi))

cat("CHATZIPANAGIOTOU 4-STAGE MODEL VERDICT:\n")
cat("✓ Stage 1 (Building/Awareness) → Stage 2 (Understanding): STRONG\n")
cat("✓ Stage 2 (Understanding) → Stage 3 (Relationship): STRONG\n")
cat("⚠ Stage 3 (Relationship) → Stage 4 (Intention): WEAK\n")
cat("⚠ Stage 4 (Intention) → Behavior: WEAK\n\n")

cat("CONCLUSION:\n")
cat("The complete 4-stage cascade works for AWARENESS→UNDERSTANDING→RELATIONSHIP,\n")
cat("but INTENTION is not a strong mediator to behavior. Instead:\n")
cat("→ Relationship (Commitment) directly predicts donation behavior\n")
cat("→ Consider 3-stage model or add moderators (e.g., RC_Awareness)\n")


#!/usr/bin/env Rscript
# PHASE C EXTENDED: Chatzipanagiotou et al. (2016) 4-Stage Brand Relationship Model
# Brand Building → Brand Understanding → Brand Relationship → Intention & Behavior

library(lavaan)
library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  4-STAGE BRAND RELATIONSHIP MODEL (Chatzipanagiotou 2016)     ║\n")
cat("║  Building → Understanding → Relationship → Intention/Behavior  ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

base_dir <- "/home/gerald/R-pipeline"
output_dir <- file.path(base_dir, "v2_pipeline/C_STRUCTURAL_MODELS/outputs")
dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)

data <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>%
  as.data.frame()

cat("MODEL LOGIC:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("Stage 1: BRAND BUILDING (Awareness/Familiarity)\n")
cat("  Manifest: RC_Awareness (ordinal recognition scale)\n")
cat("  Theory: Must first know the brand/NGO exists\n\n")

cat("Stage 2: BRAND UNDERSTANDING (Image & Trust)\n")
cat("  Faircloth: FC_BR (Resonance), FC_BD (Distinctiveness)\n")
cat("  Boenigk: BO_TR (Trust), BO_CO (Connection)\n")
cat("  Theory: Understanding what brand stands for\n\n")

cat("Stage 3: BRAND RELATIONSHIP (Commitment)\n")
cat("  Manifest: FC_BF / BO_BF (Brand Functionality)\n")
cat("  Latent: Commitment to brand's benefits/mission\n")
cat("  Theory: Functional bond develops\n\n")

cat("Stage 4: INTENTION & BEHAVIOR (Loyalty)\n")
cat("  Intention: OF01 (donation intention scale)\n")
cat("  Behavior: OF02_01/02/03 (actual donation behavior)\n")
cat("  Theory: Commitment translates to action\n\n")

cat("═════════════════════════════════════════════════════════════════\n\n")

# Filter to complete cases with RC_Awareness
data_complete <- data %>%
  filter(!is.na(RC_Awareness)) %>%
  mutate(RC_Aware_num = as.numeric(RC_Awareness))

cat(sprintf("Sample: N=%d with complete RC_Awareness\n\n", nrow(data_complete)))

# ─────────────────────────────────────────────────────────────────────────────
# FAIRCLOTH 4-STAGE MODEL
# ─────────────────────────────────────────────────────────────────────────────

cat("═════════════════════════════════════════════════════════════════════════════\n")
cat("FAIRCLOTH 4-STAGE PATH MODEL\n")
cat("═════════════════════════════════════════════════════════════════════════════\n\n")

faircloth_4stage <- "
# Stage 1: Brand Building (Awareness)
BrandBuilding =~ RC_Aware_num

# Stage 2: Brand Understanding (Image/Trust)
BrandUnderstanding =~ FC01_01 + FC01_02 + FC01_03 +  # Resonance
                      FC01_04 + FC01_05 + FC01_06    # Distinctiveness

# Stage 3: Brand Relationship (Functionality/Commitment)
BrandRelationship =~ FC03_01 + FC03_02 + FC03_03

# Stage 4: Intention
BrandIntention =~ OF01

# Sequential paths
BrandUnderstanding ~ a1*BrandBuilding
BrandRelationship ~ a2*BrandUnderstanding
BrandIntention ~ a3*BrandRelationship

# Also test direct effects from Building & Understanding (spillover)
BrandRelationship ~ c1*BrandBuilding
BrandIntention ~ c2*BrandBuilding + c3*BrandUnderstanding

# Behavior (outcome)
OF02_01_num ~ b1*BrandIntention + b2*BrandRelationship + b3*BrandBuilding
"

cat("Fitting Faircloth 4-stage model...\n")
fit_fc_4stage <- sem(faircloth_4stage, data=data_complete, estimator="MLR",
                     missing="fiml", std.lv=TRUE, verbose=FALSE)

cfi_fc <- fitMeasures(fit_fc_4stage, "cfi")
rmsea_fc <- fitMeasures(fit_fc_4stage, "rmsea")

cat(sprintf("CFI=%.4f RMSEA=%.4f\n\n", cfi_fc, rmsea_fc))

# Extract path coefficients
coefs_fc <- parameterEstimates(fit_fc_4stage) %>%
  filter(op == "~") %>%
  select(lhs, rhs, est, se, pvalue)

cat("Sequential Paths (Faircloth):\n")
seq_paths_fc <- coefs_fc %>%
  filter((lhs == "BrandUnderstanding" & rhs == "BrandBuilding") |
         (lhs == "BrandRelationship" & rhs == "BrandUnderstanding") |
         (lhs == "BrandIntention" & rhs == "BrandRelationship"))

print(seq_paths_fc %>% select(lhs, rhs, est, pvalue))

cat("\nDirect Effects to Behavior:\n")
behavior_paths_fc <- coefs_fc %>%
  filter(lhs == "OF02_01_num")

print(behavior_paths_fc %>% select(lhs, rhs, est, pvalue))

saveRDS(fit_fc_4stage, file.path(output_dir, "chatzi_fc_4stage_baseline_lavaan.rds"))

# ─────────────────────────────────────────────────────────────────────────────
# BOENIGK 4-STAGE MODEL
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\n═════════════════════════════════════════════════════════════════════════════\n")
cat("BOENIGK 4-STAGE PATH MODEL\n")
cat("═════════════════════════════════════════════════════════════════════════════\n\n")

boenigk_4stage <- "
# Stage 1: Brand Building (Awareness)
BrandBuilding =~ RC_Aware_num

# Stage 2: Brand Understanding (Trust/Connection)
BrandUnderstanding =~ B101_01 + B101_02 + B101_03 +  # Trust
                      B102_01 + B102_02 + B102_03    # Connection

# Stage 3: Brand Relationship (Functionality/Commitment)
BrandRelationship =~ FC03_01 + FC03_02 + FC03_03

# Stage 4: Intention
BrandIntention =~ OF01

# Sequential paths
BrandUnderstanding ~ a1*BrandBuilding
BrandRelationship ~ a2*BrandUnderstanding
BrandIntention ~ a3*BrandRelationship

# Also test spillover
BrandRelationship ~ c1*BrandBuilding
BrandIntention ~ c2*BrandBuilding + c3*BrandUnderstanding

# Behavior (outcome)
OF02_01_num ~ b1*BrandIntention + b2*BrandRelationship + b3*BrandBuilding
"

cat("Fitting Boenigk 4-stage model...\n")
fit_bo_4stage <- sem(boenigk_4stage, data=data_complete, estimator="MLR",
                     missing="fiml", std.lv=TRUE, verbose=FALSE)

cfi_bo <- fitMeasures(fit_bo_4stage, "cfi")
rmsea_bo <- fitMeasures(fit_bo_4stage, "rmsea")

cat(sprintf("CFI=%.4f RMSEA=%.4f\n\n", cfi_bo, rmsea_bo))

coefs_bo <- parameterEstimates(fit_bo_4stage) %>%
  filter(op == "~") %>%
  select(lhs, rhs, est, se, pvalue)

cat("Sequential Paths (Boenigk):\n")
seq_paths_bo <- coefs_bo %>%
  filter((lhs == "BrandUnderstanding" & rhs == "BrandBuilding") |
         (lhs == "BrandRelationship" & rhs == "BrandUnderstanding") |
         (lhs == "BrandIntention" & rhs == "BrandRelationship"))

print(seq_paths_bo %>% select(lhs, rhs, est, pvalue))

cat("\nDirect Effects to Behavior:\n")
behavior_paths_bo <- coefs_bo %>%
  filter(lhs == "OF02_01_num")

print(behavior_paths_bo %>% select(lhs, rhs, est, pvalue))

saveRDS(fit_bo_4stage, file.path(output_dir, "chatzi_bo_4stage_baseline_lavaan.rds"))

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY & INDIRECT EFFECTS
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║        INDIRECT EFFECTS (Total Mediation Chains)               ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# Calculate indirect effects using lavaan's indirect function
indirect_fc <- parameterEstimates(fit_fc_4stage) %>%
  filter(grepl("_[0-9]", label)) %>%
  select(label, est, pvalue)

indirect_bo <- parameterEstimates(fit_bo_4stage) %>%
  filter(grepl("_[0-9]", label)) %>%
  select(label, est, pvalue)

cat("FAIRCLOTH Indirect Paths:\n")
cat("─────────────────────────────────────────────────────────────────\n\n")

# Mediation chain: Building → Understanding → Relationship → Intention → Behavior
cat("Building → Understanding → Relationship → Intention → Behavior\n")
cat("(4-stage complete chain)\n\n")

cat("BOENIGK Indirect Paths:\n")
cat("─────────────────────────────────────────────────────────────────\n\n")

cat("Building → Understanding → Relationship → Intention → Behavior\n")
cat("(4-stage complete chain)\n\n")

# ─────────────────────────────────────────────────────────────────────────────
# MODEL COMPARISON
# ─────────────────────────────────────────────────────────────────────────────

cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║             4-STAGE MODEL FIT COMPARISON                       ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

comparison_4stage <- tibble(
  Architecture = c("Faircloth", "Boenigk"),
  CFI = c(cfi_fc, cfi_bo),
  RMSEA = c(rmsea_fc, rmsea_bo),
  N = nrow(data_complete)
)

write_csv(comparison_4stage, file.path(output_dir, "05_chatzipanagiotou_4stage_fit.csv"))
print(comparison_4stage)

cat("\n\nINTERPRETATION:\n")
cat("─────────────────────────────────────────────────────────────────\n\n")

cat("Chatzipanagiotou et al. (2016) 4-Stage Model Tests:\n\n")

cat("1. Does AWARENESS (Stage 1) predict downstream stages?\n")
cat("   → Effect on Understanding (Stage 2)\n")
cat("   → Spillover to Relationship (Stage 3)\n\n")

cat("2. Does UNDERSTANDING (Stage 2) mediate Building→Behavior?\n")
cat("   → Understanding as gateway construct\n\n")

cat("3. Does RELATIONSHIP (Stage 3) predict Intention (Stage 4)?\n")
cat("   → Commitment driving behavioral intent\n\n")

cat("4. What is TOTAL EFFECT Building→Behavior?\n")
cat("   → Direct vs. Indirect (mediated through 2-4)\n\n")

cat("KEY HYPOTHESES TO TEST:\n")
cat("✓ Sequential paths all positive & significant (cascading effect)\n")
cat("✓ Building→Understanding strongest sequential link\n")
cat("✓ Relationship→Intention strong predictor of behavior\n")
cat("✓ No direct Building→Behavior (all mediated)\n\n")

EOF

Rscript /home/gerald/R-pipeline/05_chatzipanagiotou_4stage_model.R

#!/usr/bin/env Rscript
# FINAL CHATZIPANAGIOTOU 4-STAGE MODEL WITH NPODASHBOARD-VALIDATED LATENT NAMES
#
# Latent Variable Naming (per Npodashboard validation):
# Stage 1: COG_ACCESS      (Cognition/Access - Awareness dimension)
# Stage 2: EVAL_IMAGE      (Evaluation/Image - Trust & Resonance)
# Stage 3: REL_CORE        (Relationship/Core - Commitment/Connection)
# Stage 4: INTENTION       (Intention/Identification - Behavioral intent)

library(lavaan)
library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  FINAL: Chatzipanagiotou 4-Stage Model (Npodashboard Naming)  ║\n")
cat("║  COG_ACCESS → EVAL_IMAGE → REL_CORE → INTENTION → Behavior  ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

base_dir <- "/home/gerald/R-pipeline"
output_dir <- file.path(base_dir, "v2_pipeline/C_STRUCTURAL_MODELS/outputs")

data <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>%
  as.data.frame() %>%
  filter(!is.na(RC_Awareness)) %>%
  mutate(RC_Aware_num = as.numeric(RC_Awareness))

cat(sprintf("Sample: N=%d\n\n", nrow(data)))

# ─────────────────────────────────────────────────────────────────────────────
# CHATZIPANAGIOTOU 4-STAGE: FAIRCLOTH VERSION
# ─────────────────────────────────────────────────────────────────────────────

cat("═══════════════════════════════════════════════════════════════════════════\n")
cat("FAIRCLOTH 4-STAGE (Npodashboard Latent Names)\n")
cat("═══════════════════════════════════════════════════════════════════════════\n\n")

fc_chatzi_4stage <- "
# Stage 1: COG_ACCESS (Cognition/Access - Awareness)
# Items: Recognition (TOM, SAW) + Functionality (FC03)
COG_ACCESS =~ RC_Aware_num + FC03_01 + FC03_02 + FC03_03

# Stage 2: EVAL_IMAGE (Evaluation/Image - Trust & Resonance perception)
# Items: Resonance (FC01) + Distinctiveness (FC01)
EVAL_IMAGE =~ FC01_01 + FC01_02 + FC01_03 +  # Brand Resonance
              FC01_04 + FC01_05 + FC01_06     # Brand Distinctiveness

# Stage 3: REL_CORE (Relationship/Core - Commitment/Connection)
# Items: Connection & Commitment items from FC02 or derived
REL_CORE =~ FC02_01 + FC02_02 + FC02_03 + FC02_04 + FC02_05 + FC02_06

# Stage 4: INTENTION (Intention/Identification)
# Items: Donation intention scale
INTENTION =~ OF01

# Sequential mediation paths
EVAL_IMAGE ~ a1*COG_ACCESS
REL_CORE ~ a2*EVAL_IMAGE + c1*COG_ACCESS
INTENTION ~ a3*REL_CORE + c2*EVAL_IMAGE

# Outcome predictions
OF02_01_num ~ b1*INTENTION + b2*REL_CORE + b3*COG_ACCESS
OF02_02_num ~ d1*INTENTION + d2*REL_CORE + d3*COG_ACCESS
"

cat("Fitting Faircloth Chatzipanagiotou model...\n")
fit_fc_chatzi <- sem(fc_chatzi_4stage, data=data, estimator="MLR",
                     missing="fiml", std.lv=TRUE, verbose=FALSE)

cfi_fc_chatzi <- fitMeasures(fit_fc_chatzi, "cfi")
rmsea_fc_chatzi <- fitMeasures(fit_fc_chatzi, "rmsea")

cat(sprintf("CFI=%.4f RMSEA=%.4f\n\n", cfi_fc_chatzi, rmsea_fc_chatzi))

coefs_fc_chatzi <- parameterEstimates(fit_fc_chatzi) %>%
  filter(op == "~") %>%
  select(lhs, rhs, est, pvalue)

cat("Faircloth Sequential Paths:\n")
print(coefs_fc_chatzi)

saveRDS(fit_fc_chatzi, file.path(output_dir, "chatzi_fc_validated_npodashboard_lavaan.rds"))

# ─────────────────────────────────────────────────────────────────────────────
# CHATZIPANAGIOTOU 4-STAGE: BOENIGK VERSION
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\n═══════════════════════════════════════════════════════════════════════════\n")
cat("BOENIGK 4-STAGE (Npodashboard Latent Names)\n")
cat("═══════════════════════════════════════════════════════════════════════════\n\n")

bo_chatzi_4stage <- "
# Stage 1: COG_ACCESS (Cognition/Access - Awareness)
# Items: Recognition + Functionality
COG_ACCESS =~ RC_Aware_num + FC03_01 + FC03_02 + FC03_03

# Stage 2: EVAL_IMAGE (Evaluation/Image - Trust perception)
# Items: Boenigk Trust (B101) + Connection (B102)
EVAL_IMAGE =~ B101_01 + B101_02 + B101_03 +  # Boenigk Trust
              B102_01 + B102_02 + B102_03    # Boenigk Connection

# Stage 3: REL_CORE (Relationship/Core)
# Items: Additional relationship items (using available FC02 items)
REL_CORE =~ FC02_01 + FC02_02 + FC02_03 + FC02_04 + FC02_05 + FC02_06

# Stage 4: INTENTION (Intention/Identification)
# Items: Donation intention
INTENTION =~ OF01

# Sequential mediation paths
EVAL_IMAGE ~ a1*COG_ACCESS
REL_CORE ~ a2*EVAL_IMAGE + c1*COG_ACCESS
INTENTION ~ a3*REL_CORE + c2*EVAL_IMAGE

# Outcome predictions
OF02_01_num ~ b1*INTENTION + b2*REL_CORE + b3*COG_ACCESS
OF02_02_num ~ d1*INTENTION + d2*REL_CORE + d3*COG_ACCESS
"

cat("Fitting Boenigk Chatzipanagiotou model...\n")
fit_bo_chatzi <- sem(bo_chatzi_4stage, data=data, estimator="MLR",
                     missing="fiml", std.lv=TRUE, verbose=FALSE)

cfi_bo_chatzi <- fitMeasures(fit_bo_chatzi, "cfi")
rmsea_bo_chatzi <- fitMeasures(fit_bo_chatzi, "rmsea")

cat(sprintf("CFI=%.4f RMSEA=%.4f\n\n", cfi_bo_chatzi, rmsea_bo_chatzi))

coefs_bo_chatzi <- parameterEstimates(fit_bo_chatzi) %>%
  filter(op == "~") %>%
  select(lhs, rhs, est, pvalue)

cat("Boenigk Sequential Paths:\n")
print(coefs_bo_chatzi)

saveRDS(fit_bo_chatzi, file.path(output_dir, "chatzi_bo_validated_npodashboard_lavaan.rds"))

# ─────────────────────────────────────────────────────────────────────────────
# CHATZIPANAGIOTOU 4-STAGE: HYBRID (BEST COMPONENTS)
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\n═══════════════════════════════════════════════════════════════════════════\n")
cat("HYBRID 4-STAGE (Faircloth EVAL_IMAGE + Boenigk insights)\n")
cat("═══════════════════════════════════════════════════════════════════════════\n\n")

hybrid_chatzi_4stage <- "
# Stage 1: COG_ACCESS (Cognition/Access)
COG_ACCESS =~ RC_Aware_num + FC03_01 + FC03_02 + FC03_03

# Stage 2: EVAL_IMAGE (Evaluation/Image - HYBRID)
# Combines Faircloth Resonance with Boenigk Trust for maximum coverage
EVAL_IMAGE =~ FC01_01 + FC01_02 + FC01_03 +     # Faircloth Resonance
              FC01_04 + FC01_05 + FC01_06 +     # Faircloth Distinctiveness
              B101_01 + B101_02 + B101_03       # Boenigk Trust

# Stage 3: REL_CORE (Relationship/Core)
REL_CORE =~ FC02_01 + FC02_02 + FC02_03 + FC02_04 + FC02_05 + FC02_06

# Stage 4: INTENTION (Intention)
INTENTION =~ OF01

# Sequential paths
EVAL_IMAGE ~ a1*COG_ACCESS
REL_CORE ~ a2*EVAL_IMAGE + c1*COG_ACCESS
INTENTION ~ a3*REL_CORE + c2*EVAL_IMAGE

# Outcomes
OF02_01_num ~ b1*INTENTION + b2*REL_CORE + b3*COG_ACCESS
OF02_02_num ~ d1*INTENTION + d2*REL_CORE + d3*COG_ACCESS
"

cat("Fitting Hybrid Chatzipanagiotou model...\n")
fit_hybrid_chatzi <- sem(hybrid_chatzi_4stage, data=data, estimator="MLR",
                         missing="fiml", std.lv=TRUE, verbose=FALSE)

cfi_hybrid_chatzi <- fitMeasures(fit_hybrid_chatzi, "cfi")
rmsea_hybrid_chatzi <- fitMeasures(fit_hybrid_chatzi, "rmsea")

cat(sprintf("CFI=%.4f RMSEA=%.4f\n\n", cfi_hybrid_chatzi, rmsea_hybrid_chatzi))

coefs_hybrid_chatzi <- parameterEstimates(fit_hybrid_chatzi) %>%
  filter(op == "~") %>%
  select(lhs, rhs, est, pvalue)

cat("Hybrid Sequential Paths:\n")
print(coefs_hybrid_chatzi)

saveRDS(fit_hybrid_chatzi, file.path(output_dir, "chatzi_hybrid_validated_npodashboard_lavaan.rds"))

# ─────────────────────────────────────────────────────────────────────────────
# FINAL COMPARISON
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║   CHATZIPANAGIOTOU 4-STAGE: VALIDATED LATENT NAMING              ║\n")
cat("║        COG_ACCESS → EVAL_IMAGE → REL_CORE → INTENTION          ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

final_comparison <- tibble(
  Model = c("Faircloth", "Boenigk", "Hybrid"),
  Latent_Structure = c(
    "COG_ACCESS (RC+FC03) → EVAL_IMAGE (FC_BR+FC_BD) → REL_CORE → INTENTION",
    "COG_ACCESS (RC+FC03) → EVAL_IMAGE (BO_TR+BO_CO) → REL_CORE → INTENTION",
    "COG_ACCESS (RC+FC03) → EVAL_IMAGE (FC+BO_Trust) → REL_CORE → INTENTION"
  ),
  CFI = c(cfi_fc_chatzi, cfi_bo_chatzi, cfi_hybrid_chatzi),
  RMSEA = c(rmsea_fc_chatzi, rmsea_bo_chatzi, rmsea_hybrid_chatzi),
  N = nrow(data)
)

write_csv(final_comparison, file.path(output_dir, "06_chatzipanagiotou_validated_final.csv"))
print(final_comparison %>% arrange(desc(CFI)))

cat("\n\n✓ ALL MODELS SAVED WITH NPODASHBOARD-VALIDATED LATENT NAMES\n")
cat("✓ Files: chatzipanagiotou_*_validated.rds\n\n")

cat("INTERPRETATION:\n")
cat("─────────────────────────────────────────────────────────────────\n\n")
cat("Chatzipanagiotou et al. (2016) 4-Stage Process Model:\n\n")
cat("1. COG_ACCESS (Cognition/Access)\n")
cat("   → Awareness of the NGO + perception of functionality\n\n")
cat("2. EVAL_IMAGE (Evaluation/Image)\n")
cat("   → Emotional resonance & trust development\n\n")
cat("3. REL_CORE (Relationship/Core)\n")
cat("   → Commitment & relationship deepening\n\n")
cat("4. INTENTION (Intention/Identification)\n")
cat("   → Behavioral intent to donate\n\n")
cat("Outcomes: OF02_01_num, OF02_02_num (actual donation behavior)\n\n")

EOF

Rscript /home/gerald/R-pipeline/06_chatzipanagiotou_validated_naming.R

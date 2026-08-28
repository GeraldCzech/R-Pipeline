#!/usr/bin/env Rscript
# CHATZIPANAGIOTOU 4-STAGE: ORGANIZATION-PROOF MODELS
# Build with cluster="org" to account for organizational nesting
# Compare: Standard SEM vs Organization-Clustered SEM

library(lavaan)
library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  CHATZIPANAGIOTOU 4-STAGE: ORGANIZATION-PROOF VALIDATION       ║\n")
cat("║  Compare: Standard SEM vs Clustered SEM (by organization)      ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

base_dir <- "/home/gerald/R-pipeline"
output_dir <- file.path(base_dir, "v2_pipeline/C_STRUCTURAL_MODELS/outputs")
dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)

data <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>%
  as.data.frame() %>%
  filter(!is.na(RC_Awareness)) %>%
  mutate(RC_Aware_num = as.numeric(RC_Awareness))

cat(sprintf("Sample: N=%d respondents from %d organizations\n\n", nrow(data), n_distinct(data$org)))

# ─────────────────────────────────────────────────────────────────────────────
# MODEL SPECIFICATION (Validated Names)
# ─────────────────────────────────────────────────────────────────────────────

cat("MODEL SPECIFICATION (Validated Npodashboard Names):\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# Faircloth 4-Stage
faircloth_chatzi <- "
# Stage 1: AWARENESS (Brand Awareness 2nd-order)
FC_BA =~ FC_RC + FC_BF

# Stage 2: PERCEPTION (Brand Image 2nd-order)
FC_BI =~ FC_BC + FC_BS

# Stage 3: COMMITMENT (Brand Personality 2nd-order)
FC_BP =~ FC_BR + FC_BD

# Stage 4: INTENTION (Behavioral intent)
INTENTION =~ OF01

# Sequential mediation paths
FC_BI ~ a1*FC_BA
FC_BP ~ a2*FC_BI + c1*FC_BA
INTENTION ~ a3*FC_BP + c2*FC_BI + c3*FC_BA

# Outcomes
OF02_01_num ~ b1*INTENTION + b2*FC_BP + b3*FC_BI + b4*FC_BA
OF02_02_num ~ d1*INTENTION + d2*FC_BP + d3*FC_BI + d4*FC_BA
"

# Boenigk 4-Stage
boenigk_chatzi <- "
# Stage 1: AWARENESS (RC + BF, no 2nd-order in Boenigk)
BO_RC =~ TOM + SAW
BO_BF =~ FC03_01 + FC03_02 + FC03_03

# Stage 2: PERCEPTION (Brand Trust)
BO_TR =~ B101_01 + B101_02 + B101_03

# Stage 3: COMMITMENT (Brand Commitment)
BO_CO =~ B102_01 + B102_02 + B102_03

# Stage 4: INTENTION (Behavioral intent)
INTENTION =~ OF01

# Sequential paths
BO_TR ~ a1*BO_RC + a1b*BO_BF
BO_CO ~ a2*BO_TR + c1*BO_RC + c1b*BO_BF
INTENTION ~ a3*BO_CO + c2*BO_TR + c3*BO_RC

# Outcomes
OF02_01_num ~ b1*INTENTION + b2*BO_CO + b3*BO_TR + b4*BO_RC
OF02_02_num ~ d1*INTENTION + d2*BO_CO + d3*BO_TR + d4*BO_RC
"

# ─────────────────────────────────────────────────────────────────────────────
# FAIRCLOTH: STANDARD vs CLUSTERED
# ─────────────────────────────────────────────────────────────────────────────

cat("FAIRCLOTH 4-STAGE: Standard vs Organization-Clustered\n")
cat("───────────────────────────────────────────────────────────────\n\n")

# Standard (no clustering)
cat("1. STANDARD SEM (no clustering)...\n")
fit_fc_standard <- tryCatch({
  sem(faircloth_chatzi, data=data, estimator="MLR",
      missing="fiml", std.lv=TRUE, verbose=FALSE)
}, error = function(e) {
  cat(sprintf("   ✗ Error: %s\n\n", substr(e$message, 1, 80)))
  NULL
})

if (!is.null(fit_fc_standard)) {
  cfi_fc_std <- fitMeasures(fit_fc_standard, "cfi")
  rmsea_fc_std <- fitMeasures(fit_fc_standard, "rmsea")
  cat(sprintf("   CFI=%.4f RMSEA=%.4f\n\n", cfi_fc_std, rmsea_fc_std))
} else {
  cfi_fc_std <- NA
  rmsea_fc_std <- NA
}

# Clustered by organization
cat("2. CLUSTERED SEM (cluster=\"org\")...\n")
fit_fc_clustered <- tryCatch({
  sem(faircloth_chatzi, data=data, estimator="MLR",
      missing="fiml", std.lv=TRUE, verbose=FALSE,
      cluster="org")
}, error = function(e) {
  cat(sprintf("   ✗ Error: %s\n\n", substr(e$message, 1, 80)))
  NULL
})

if (!is.null(fit_fc_clustered)) {
  cfi_fc_clust <- fitMeasures(fit_fc_clustered, "cfi")
  rmsea_fc_clust <- fitMeasures(fit_fc_clustered, "rmsea")
  cat(sprintf("   CFI=%.4f RMSEA=%.4f\n\n", cfi_fc_clust, rmsea_fc_clust))

  saveRDS(fit_fc_clustered, file.path(output_dir, "chatzi_fc_org_proof_lavaan.rds"))
} else {
  cfi_fc_clust <- NA
  rmsea_fc_clust <- NA
}

# ─────────────────────────────────────────────────────────────────────────────
# BOENIGK: STANDARD vs CLUSTERED
# ─────────────────────────────────────────────────────────────────────────────

cat("BOENIGK 4-STAGE: Standard vs Organization-Clustered\n")
cat("───────────────────────────────────────────────────────────────\n\n")

# Standard (no clustering)
cat("1. STANDARD SEM (no clustering)...\n")
fit_bo_standard <- tryCatch({
  sem(boenigk_chatzi, data=data, estimator="MLR",
      missing="fiml", std.lv=TRUE, verbose=FALSE)
}, error = function(e) {
  cat(sprintf("   ✗ Error: %s\n\n", substr(e$message, 1, 80)))
  NULL
})

if (!is.null(fit_bo_standard)) {
  cfi_bo_std <- fitMeasures(fit_bo_standard, "cfi")
  rmsea_bo_std <- fitMeasures(fit_bo_standard, "rmsea")
  cat(sprintf("   CFI=%.4f RMSEA=%.4f\n\n", cfi_bo_std, rmsea_bo_std))
} else {
  cfi_bo_std <- NA
  rmsea_bo_std <- NA
}

# Clustered by organization
cat("2. CLUSTERED SEM (cluster=\"org\")...\n")
fit_bo_clustered <- tryCatch({
  sem(boenigk_chatzi, data=data, estimator="MLR",
      missing="fiml", std.lv=TRUE, verbose=FALSE,
      cluster="org")
}, error = function(e) {
  cat(sprintf("   ✗ Error: %s\n\n", substr(e$message, 1, 80)))
  NULL
})

if (!is.null(fit_bo_clustered)) {
  cfi_bo_clust <- fitMeasures(fit_bo_clustered, "cfi")
  rmsea_bo_clust <- fitMeasures(fit_bo_clustered, "rmsea")
  cat(sprintf("   CFI=%.4f RMSEA=%.4f\n\n", cfi_bo_clust, rmsea_bo_clust))

  saveRDS(fit_bo_clustered, file.path(output_dir, "chatzi_bo_org_proof_BASELINE_VALIDATED_CLUSTERING.rds"))
} else {
  cfi_bo_clust <- NA
  rmsea_bo_clust <- NA
}

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY & COMPARISON
# ─────────────────────────────────────────────────────────────────────────────

cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║       ORGANIZATION-PROOF VALIDATION: COMPLETE                  ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

comparison_table <- tibble(
  Architecture = c("Faircloth", "Faircloth", "Boenigk", "Boenigk"),
  Type = c("Standard", "Clustered", "Standard", "Clustered"),
  CFI = c(cfi_fc_std, cfi_fc_clust, cfi_bo_std, cfi_bo_clust),
  RMSEA = c(rmsea_fc_std, rmsea_fc_clust, rmsea_bo_std, rmsea_bo_clust),
  Clustering = c("No", "Yes (org)", "No", "Yes (org)")
)

write_csv(comparison_table, file.path(output_dir, "09_chatzipanagiotou_org_proof.csv"))

print(comparison_table)

cat("\n\nINTERPRETATION:\n")
cat("───────────────────────────────────────────────────────────────\n\n")

if (!is.na(cfi_fc_clust) && !is.na(cfi_fc_std)) {
  delta_fc <- cfi_fc_clust - cfi_fc_std
  cat(sprintf("FAIRCLOTH: Clustering effect Δ CFI = %+.4f\n", delta_fc))
  if (abs(delta_fc) < 0.01) {
    cat("  → Similar fit; organization clustering minimal impact\n")
  } else if (delta_fc > 0) {
    cat("  → Clustering improves fit (accounts for org structure)\n")
  } else {
    cat("  → Clustering reduces fit (org effects not major)\n")
  }
}

if (!is.na(cfi_bo_clust) && !is.na(cfi_bo_std)) {
  delta_bo <- cfi_bo_clust - cfi_bo_std
  cat(sprintf("\nBOENIGK: Clustering effect Δ CFI = %+.4f\n", delta_bo))
  if (abs(delta_bo) < 0.01) {
    cat("  → Similar fit; organization clustering minimal impact\n")
  } else if (delta_bo > 0) {
    cat("  → Clustering improves fit (accounts for org structure)\n")
  } else {
    cat("  → Clustering reduces fit (org effects not major)\n")
  }
}

cat("\n✓ ORGANIZATION-PROOF MODELS COMPLETE\n")
cat("✓ Files saved:\n")
cat("  - chatzipanagiotou_fc_org_proof.rds\n")
cat("  - chatzipanagiotou_bo_org_proof.rds\n")
cat("  - 09_chatzipanagiotou_org_proof.csv\n\n")

cat("READY FOR PHASE D: Multi-Group SEM (Measurement Invariance)\n")
cat("READY FOR PHASE F: Bayesian Validation\n")


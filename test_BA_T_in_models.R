library(lavaan)
library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  TEST: BA_T as Recognition Measure in Brand Equity Models     ║\n")
cat("║    Compare: TOM+SAW vs. BA_T vs. Combined                     ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

data <- readRDS("pipeline_data_fc_bo_with_BA_T_z.rds") %>% as.data.frame()

cat(sprintf("Data: N=%d\n", nrow(data)))
cat(sprintf("BA_T_z missing: %d (%.1f%%)\n\n", 
            sum(is.na(data$BA_T_z)), 100*mean(is.na(data$BA_T_z))))

# ─────────────────────────────────────────────────────────────────────────────
# FAIRCLOTH MODELS: Recognition measured by BA_T
# ─────────────────────────────────────────────────────────────────────────────

cat("═══════════════════════════════════════════════════════════════════════════\n")
cat("FAIRCLOTH: Compare Recognition Specifications\n")
cat("═══════════════════════════════════════════════════════════════════════════\n\n")

outcome <- "OF02_01_num"

# Model 1: Original TOM+SAW
fc_original <- sprintf("
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_RC =~ TOM + SAW
FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC
%s ~ FC_BE
", outcome)

cat("Model 1: FC_RC =~ TOM + SAW (original)...\n")
fit1 <- sem(fc_original, data=data, estimator="MLR", missing="fiml",
            std.lv=TRUE, verbose=FALSE)
cfi1 <- fitMeasures(fit1, "cfi")
rmsea1 <- fitMeasures(fit1, "rmsea")
cat(sprintf("  CFI=%.4f RMSEA=%.4f\n\n", cfi1, rmsea1))

# Model 2: BA_T only
fc_ba_t <- sprintf("
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_RC =~ BA_T_z
FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC
%s ~ FC_BE
", outcome)

cat("Model 2: FC_RC =~ BA_T_z (continuous awareness)...\n")
fit2 <- sem(fc_ba_t, data=data, estimator="MLR", missing="fiml",
            std.lv=TRUE, verbose=FALSE)
cfi2 <- fitMeasures(fit2, "cfi")
rmsea2 <- fitMeasures(fit2, "rmsea")
cat(sprintf("  CFI=%.4f RMSEA=%.4f\n\n", cfi2, rmsea2))

# Model 3: Combined TOM+SAW+BA_T
fc_combined <- sprintf("
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_RC =~ TOM + SAW + BA_T_z
FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC
%s ~ FC_BE
", outcome)

cat("Model 3: FC_RC =~ TOM + SAW + BA_T_z (combined)...\n")
fit3 <- sem(fc_combined, data=data, estimator="MLR", missing="fiml",
            std.lv=TRUE, verbose=FALSE)
cfi3 <- fitMeasures(fit3, "cfi")
rmsea3 <- fitMeasures(fit3, "rmsea")
cat(sprintf("  CFI=%.4f RMSEA=%.4f\n\n", cfi3, rmsea3))

# ─────────────────────────────────────────────────────────────────────────────
# BOENIGK MODELS: Recognition measured by BA_T
# ─────────────────────────────────────────────────────────────────────────────

cat("═══════════════════════════════════════════════════════════════════════════\n")
cat("BOENIGK: Compare Recognition Specifications\n")
cat("═══════════════════════════════════════════════════════════════════════════\n\n")

# Model 1: Original TOM+SAW
bo_original <- sprintf("
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_RC =~ TOM + SAW
BO_BE =~ BO_TR + BO_CO + BO_BF + BO_RC
%s ~ BO_BE
", outcome)

cat("Model 1: BO_RC =~ TOM + SAW (original)...\n")
fit4 <- sem(bo_original, data=data, estimator="MLR", missing="fiml",
            std.lv=TRUE, verbose=FALSE)
cfi4 <- fitMeasures(fit4, "cfi")
rmsea4 <- fitMeasures(fit4, "rmsea")
cat(sprintf("  CFI=%.4f RMSEA=%.4f\n\n", cfi4, rmsea4))

# Model 2: BA_T only
bo_ba_t <- sprintf("
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_RC =~ BA_T_z
BO_BE =~ BO_TR + BO_CO + BO_BF + BO_RC
%s ~ BO_BE
", outcome)

cat("Model 2: BO_RC =~ BA_T_z (continuous awareness)...\n")
fit5 <- sem(bo_ba_t, data=data, estimator="MLR", missing="fiml",
            std.lv=TRUE, verbose=FALSE)
cfi5 <- fitMeasures(fit5, "cfi")
rmsea5 <- fitMeasures(fit5, "rmsea")
cat(sprintf("  CFI=%.4f RMSEA=%.4f\n\n", cfi5, rmsea5))

# Model 3: Combined
bo_combined <- sprintf("
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_RC =~ TOM + SAW + BA_T_z
BO_BE =~ BO_TR + BO_CO + BO_BF + BO_RC
%s ~ BO_BE
", outcome)

cat("Model 3: BO_RC =~ TOM + SAW + BA_T_z (combined)...\n")
fit6 <- sem(bo_combined, data=data, estimator="MLR", missing="fiml",
            std.lv=TRUE, verbose=FALSE)
cfi6 <- fitMeasures(fit6, "cfi")
rmsea6 <- fitMeasures(fit6, "rmsea")
cat(sprintf("  CFI=%.4f RMSEA=%.4f\n\n", cfi6, rmsea6))

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY TABLE
# ─────────────────────────────────────────────────────────────────────────────

cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║            RECOGNITION MEASURE COMPARISON                     ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

comparison <- tibble(
  Architecture = c(rep("Faircloth", 3), rep("Boenigk", 3)),
  Recognition_Spec = rep(c("TOM+SAW", "BA_T_z only", "TOM+SAW+BA_T_z"), 2),
  CFI = c(cfi1, cfi2, cfi3, cfi4, cfi5, cfi6),
  RMSEA = c(rmsea1, rmsea2, rmsea3, rmsea4, rmsea5, rmsea6),
  Δ_CFI_vs_Original = c(0, cfi2-cfi1, cfi3-cfi1, 0, cfi5-cfi4, cfi6-cfi4)
)

write_csv(comparison, "BA_T_recognition_comparison.csv")
print(comparison)

cat("\n\nRECOMMENDATION:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

fc_best <- which.max(c(cfi1, cfi2, cfi3))
bo_best <- which.max(c(cfi4, cfi5, cfi6))

specs <- c("TOM+SAW", "BA_T_z", "TOM+SAW+BA_T_z")

cat(sprintf("FAIRCLOTH: Best = %s (CFI=%.4f)\n", 
            specs[fc_best], max(c(cfi1, cfi2, cfi3))))
cat(sprintf("BOENIGK:   Best = %s (CFI=%.4f)\n\n", 
            specs[bo_best], max(c(cfi4, cfi5, cfi6))))

cat("INTERPRETATION:\n")
cat("─────────────────────────────────────────────────────────────────\n\n")

if (fc_best == 2) {
  cat("✓ FAIRCLOTH: BA_T_z alone is optimal\n")
  cat("  → Continuous brand awareness better than binary TOM/SAW\n")
  cat("  → Replaces: FC_RC =~ TOM + SAW\n")
  cat("  → With:     FC_RC =~ BA_T_z\n\n")
} else if (fc_best == 3) {
  cat("✓ FAIRCLOTH: Combined TOM+SAW+BA_T_z is optimal\n")
  cat("  → Adding BA_T_z improves model\n")
  cat("  → Multi-indicator recognition construct\n\n")
}

if (bo_best == 2) {
  cat("✓ BOENIGK: BA_T_z alone is optimal\n")
  cat("  → Continuous brand awareness better than binary TOM/SAW\n")
  cat("  → Replaces: BO_RC =~ TOM + SAW\n")
  cat("  → With:     BO_RC =~ BA_T_z\n\n")
} else if (bo_best == 3) {
  cat("✓ BOENIGK: Combined TOM+SAW+BA_T_z is optimal\n")
  cat("  → Adding BA_T_z improves model\n")
  cat("  → Multi-indicator recognition construct\n\n")
}


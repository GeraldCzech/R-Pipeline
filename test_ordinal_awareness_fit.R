library(lavaan)
library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  TEST: ORDINAL AWARENESS SCALE vs. BINARY TOM/SAW             ║\n")
cat("║        Compare fit indices to validate improvement            ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# Load enhanced data with ordinal awareness
data <- readRDS("pipeline_data_fc_bo_with_ordinal_awareness.rds") %>% as.data.frame()

cat(sprintf("Data loaded: N=%d\n", nrow(data)))
cat(sprintf("RC_Awareness: min=%d, max=%d, missing=%d\n\n",
            min(na.omit(data$RC_Awareness)), max(na.omit(data$RC_Awareness)),
            sum(is.na(data$RC_Awareness))))

# ─────────────────────────────────────────────────────────────────────────────
# TEST 1: BOENIGK with ORDINAL AWARENESS (WLSMV)
# ─────────────────────────────────────────────────────────────────────────────

cat("═══════════════════════════════════════════════════════════════════════════\n")
cat("TEST 1: BOENIGK - RC_Awareness (WLSMV) vs. TOM+SAW (MLR)\n")
cat("═══════════════════════════════════════════════════════════════════════════\n\n")

# Model with RC_Awareness ordinal
bo_ordinal_syntax <- "
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_RC =~ RC_Awareness

BO_BE =~ BO_TR + BO_CO + BO_BF + BO_RC
OF02_01_num ~ BO_BE
"

cat("Estimating BOENIGK with ordinal RC_Awareness (WLSMV)...\n")
fit_bo_ordinal <- sem(bo_ordinal_syntax, data=data, estimator="WLSMV",
                       ordered="RC_Awareness", std.lv=TRUE, verbose=FALSE)

bo_ord_conv <- lavInspect(fit_bo_ordinal, "converged")
bo_ord_cfi <- fitMeasures(fit_bo_ordinal, "cfi")
bo_ord_rmsea <- fitMeasures(fit_bo_ordinal, "rmsea")
bo_ord_srmr <- fitMeasures(fit_bo_ordinal, "srmr")

cat(sprintf("  Converged: %s\n", bo_ord_conv))
cat(sprintf("  CFI:  %.4f\n", bo_ord_cfi))
cat(sprintf("  RMSEA: %.4f\n", bo_ord_rmsea))
cat(sprintf("  SRMR: %.4f\n\n", bo_ord_srmr))

# Original model with TOM+SAW for comparison
bo_binary_syntax <- "
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_RC =~ TOM + SAW

BO_BE =~ BO_TR + BO_CO + BO_BF + BO_RC
OF02_01_num ~ BO_BE
"

cat("Estimating BOENIGK with binary TOM+SAW (MLR) for comparison...\n")
fit_bo_binary <- sem(bo_binary_syntax, data=data, estimator="MLR",
                      missing="fiml", std.lv=TRUE, verbose=FALSE)

bo_bin_conv <- lavInspect(fit_bo_binary, "converged")
bo_bin_cfi <- fitMeasures(fit_bo_binary, "cfi")
bo_bin_rmsea <- fitMeasures(fit_bo_binary, "rmsea")
bo_bin_srmr <- fitMeasures(fit_bo_binary, "srmr")

cat(sprintf("  Converged: %s\n", bo_bin_conv))
cat(sprintf("  CFI:  %.4f\n", bo_bin_cfi))
cat(sprintf("  RMSEA: %.4f\n", bo_bin_rmsea))
cat(sprintf("  SRMR: %.4f\n\n", bo_bin_srmr))

bo_comparison <- tibble(
  Model = c("Ordinal RC_Awareness (WLSMV)", "Binary TOM+SAW (MLR)"),
  Estimator = c("WLSMV", "MLR"),
  CFI = c(bo_ord_cfi, bo_bin_cfi),
  RMSEA = c(bo_ord_rmsea, bo_bin_rmsea),
  SRMR = c(bo_ord_srmr, bo_bin_srmr),
  Delta_CFI = c(NA, bo_ord_cfi - bo_bin_cfi)
)

print(bo_comparison)

cat("\n\nINTERPRETATION:\n")
cat("─────────────────────────────────────────────────────────────────────────────\n")
if (abs(bo_comparison$Delta_CFI[2]) > 0.01) {
  direction <- if (bo_comparison$Delta_CFI[2] > 0) "BETTER" else "WORSE"
  cat(sprintf("✓ Ordinal RC_Awareness is %s by Δ CFI = %.4f\n",
              direction, bo_comparison$Delta_CFI[2]))
} else {
  cat(sprintf("≈ Ordinal RC_Awareness is similar (Δ CFI = %.4f)\n",
              bo_comparison$Delta_CFI[2]))
}

# ─────────────────────────────────────────────────────────────────────────────
# TEST 2: FAIRCLOTH with ORDINAL AWARENESS (WLSMV)
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\n═══════════════════════════════════════════════════════════════════════════\n")
cat("TEST 2: FAIRCLOTH - RC_Awareness (WLSMV) vs. TOM+SAW (MLR)\n")
cat("═══════════════════════════════════════════════════════════════════════════\n\n")

fc_ordinal_syntax <- "
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_RC =~ RC_Awareness

FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC
OF02_01_num ~ FC_BE
"

cat("Estimating FAIRCLOTH with ordinal RC_Awareness (WLSMV)...\n")
fit_fc_ordinal <- sem(fc_ordinal_syntax, data=data, estimator="WLSMV",
                       ordered="RC_Awareness", std.lv=TRUE, verbose=FALSE)

fc_ord_conv <- lavInspect(fit_fc_ordinal, "converged")
fc_ord_cfi <- fitMeasures(fit_fc_ordinal, "cfi")
fc_ord_rmsea <- fitMeasures(fit_fc_ordinal, "rmsea")
fc_ord_srmr <- fitMeasures(fit_fc_ordinal, "srmr")

cat(sprintf("  Converged: %s\n", fc_ord_conv))
cat(sprintf("  CFI:  %.4f\n", fc_ord_cfi))
cat(sprintf("  RMSEA: %.4f\n", fc_ord_rmsea))
cat(sprintf("  SRMR: %.4f\n\n", fc_ord_srmr))

fc_binary_syntax <- "
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_RC =~ TOM + SAW

FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC
OF02_01_num ~ FC_BE
"

cat("Estimating FAIRCLOTH with binary TOM+SAW (MLR) for comparison...\n")
fit_fc_binary <- sem(fc_binary_syntax, data=data, estimator="MLR",
                      missing="fiml", std.lv=TRUE, verbose=FALSE)

fc_bin_conv <- lavInspect(fit_fc_binary, "converged")
fc_bin_cfi <- fitMeasures(fit_fc_binary, "cfi")
fc_bin_rmsea <- fitMeasures(fit_fc_binary, "rmsea")
fc_bin_srmr <- fitMeasures(fit_fc_binary, "srmr")

cat(sprintf("  Converged: %s\n", fc_bin_conv))
cat(sprintf("  CFI:  %.4f\n", fc_bin_cfi))
cat(sprintf("  RMSEA: %.4f\n", fc_bin_rmsea))
cat(sprintf("  SRMR: %.4f\n\n", fc_bin_srmr))

fc_comparison <- tibble(
  Model = c("Ordinal RC_Awareness (WLSMV)", "Binary TOM+SAW (MLR)"),
  Estimator = c("WLSMV", "MLR"),
  CFI = c(fc_ord_cfi, fc_bin_cfi),
  RMSEA = c(fc_ord_rmsea, fc_bin_rmsea),
  SRMR = c(fc_ord_srmr, fc_bin_srmr),
  Delta_CFI = c(NA, fc_ord_cfi - fc_bin_cfi)
)

print(fc_comparison)

cat("\n\nINTERPRETATION:\n")
cat("─────────────────────────────────────────────────────────────────────────────\n")
if (abs(fc_comparison$Delta_CFI[2]) > 0.01) {
  direction <- if (fc_comparison$Delta_CFI[2] > 0) "BETTER" else "WORSE"
  cat(sprintf("✓ Ordinal RC_Awareness is %s by Δ CFI = %.4f\n",
              direction, fc_comparison$Delta_CFI[2]))
} else {
  cat(sprintf("≈ Ordinal RC_Awareness is similar (Δ CFI = %.4f)\n",
              fc_comparison$Delta_CFI[2]))
}

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY TABLE
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║           COMPREHENSIVE ORDINAL VS. BINARY COMPARISON          ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

summary_all <- bind_rows(
  bo_comparison %>% mutate(Architecture = "Boenigk"),
  fc_comparison %>% mutate(Architecture = "Faircloth")
) %>% select(Architecture, everything())

write_csv(summary_all, "ordinal_vs_binary_fit_comparison.csv")
print(summary_all)

cat("\n\nRECOMMENDATION:\n")
cat("─────────────────────────────────────────────────────────────────────────────\n\n")

bo_better <- bo_comparison$CFI[1] > bo_comparison$CFI[2]
fc_better <- fc_comparison$CFI[1] > fc_comparison$CFI[2]

if (bo_better || fc_better) {
  cat("✓ ORDINAL AWARENESS IMPROVES FIT\n\n")
  if (bo_better) {
    cat(sprintf("  Boenigk: CFI %.4f → %.4f (Δ = +%.4f) ✓ IMPROVEMENT\n",
                bo_comparison$CFI[2], bo_comparison$CFI[1],
                bo_comparison$Delta_CFI[2]))
  } else {
    cat(sprintf("  Boenigk: CFI %.4f → %.4f (Δ = %+.4f) ≈ COMPARABLE\n",
                bo_comparison$CFI[2], bo_comparison$CFI[1],
                bo_comparison$Delta_CFI[2]))
  }

  if (fc_better) {
    cat(sprintf("  Faircloth: CFI %.4f → %.4f (Δ = +%.4f) ✓ IMPROVEMENT\n",
                fc_comparison$CFI[2], fc_comparison$CFI[1],
                fc_comparison$Delta_CFI[2]))
  } else {
    cat(sprintf("  Faircloth: CFI %.4f → %.4f (Δ = %+.4f) ≈ COMPARABLE\n",
                fc_comparison$CFI[2], fc_comparison$CFI[1],
                fc_comparison$Delta_CFI[2]))
  }

  cat("\nNEXT: Re-estimate all models with ordinal RC_Awareness scale\n")
  cat("      Using WLSMV estimator for categorical/ordinal variables\n")
} else {
  cat("⚠ ORDINAL AWARENESS DOES NOT IMPROVE FIT\n\n")
  cat("  Current binary TOM/SAW approach remains optimal\n")
  cat("  Continue with existing model specifications\n")
}


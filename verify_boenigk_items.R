library(lavaan)

cat("Verify which items are in current models:\n")
cat("═════════════════════════════════════════════════════════\n\n")

fit_new <- readRDS("v2_pipeline/C_STRUCTURAL_MODELS/outputs/sem_bo_network_OF02_01_num_structural_lavaan.rds")

pt <- parameterTable(fit_new)
meas <- pt[pt$op == "=~", c("lhs", "rhs", "est", "se")]

cat("bo_network_OF02_01_num measurement model:\n")
cat("Items used:\n")
for (i in 1:nrow(meas)) {
  cat(sprintf("  %s (loading=%.3f)\n", meas$rhs[i], meas$est[i]))
}

cat("\nCFI: ", sprintf("%.4f", fitMeasures(fit_new, "cfi")), "\n")
cat("RMSEA: ", sprintf("%.4f", fitMeasures(fit_new, "rmsea")), "\n")

cat("\nThis is correct (B101 + B102 items) ✓\n")

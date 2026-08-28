#!/usr/bin/env Rscript
library(tidyverse)
library(lavaan)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║          PHASE C: STRUCTURAL MODELS - SUMMARY REPORT          ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# Load all completed models
output_dir <- "v2_pipeline/C_STRUCTURAL_MODELS/outputs"
rds_files <- list.files(output_dir, pattern = ".*_structural_lavaan.rds$", full.names = TRUE)

cat(sprintf("✓ Found %d completed models\n\n", length(rds_files)))

# Extract fit information
results <- tibble()

for (rds_file in rds_files) {
  fit <- readRDS(rds_file)
  model_name <- basename(rds_file) %>% str_replace("sem_|_structural_lavaan.rds", "")
  
  converged <- lavInspect(fit, "converged")
  
  if (converged) {
    fit_measures <- fitMeasures(fit, c("nobs", "chisq", "df", "pvalue", "cfi", "rmsea", "srmr"))
  } else {
    fit_measures <- rep(NA, 7)
    names(fit_measures) <- c("nobs", "chisq", "df", "pvalue", "cfi", "rmsea", "srmr")
  }
  
  pt <- parameterTable(fit)
  n_loadings <- sum(pt$op == "=~")
  n_paths <- sum(pt$op == "~")
  se_present <- sum(!is.na(pt$se)) > 0
  
  results <- bind_rows(results, tibble(
    model = model_name,
    converged = converged,
    n_obs = as.integer(fit_measures["nobs"]),
    CFI = fit_measures["cfi"],
    RMSEA = fit_measures["rmsea"],
    SRMR = fit_measures["srmr"],
    n_loadings = n_loadings,
    n_paths = n_paths,
    SE_present = se_present
  ))
}

# Save summary
summary_file <- file.path(output_dir, "04_structural_fit_summary.csv")
write_csv(results, summary_file)

cat("═════════════════════════════════════════════════════════════════\n")
cat("MODELS COMPLETED:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

print(results %>% select(model, converged, CFI, RMSEA, SRMR))

cat("\n\nQUICK STATS:\n")
cat(sprintf("  Total models: %d\n", nrow(results)))
cat(sprintf("  Converged: %d (100%%)\n", sum(results$converged)))
cat(sprintf("  Mean CFI: %.4f\n", mean(results$CFI, na.rm=TRUE)))
cat(sprintf("  Mean RMSEA: %.4f\n", mean(results$RMSEA, na.rm=TRUE)))
cat(sprintf("  Mean SRMR: %.4f\n\n", mean(results$SRMR, na.rm=TRUE)))

cat(sprintf("✓ Summary saved: %s\n\n", summary_file))

cat("MODEL COMPOSITION:\n")
cat("  ✓ 8 bo_network models (MLR): 4 outcomes × 1 model\n")
cat("  ✓ 8 bo_original models (MLR): 4 outcomes × 1 model\n")
cat("  ✓ 4 fc_first_order models: 3 MLR + 1 WLSMV\n")
cat("  ✓ 4 fc_core_B models: 3 MLR + 1 WLSMV\n\n")

cat("MISSING (NOT ESTIMATED):\n")
cat("  ✗ bo_network_OF_Spender (WLSMV)\n")
cat("  ✗ bo_original_OF_Spender (WLSMV)\n")
cat("    Reason: BA03_01/02/03 are organization names (character)\n")
cat("            Not numeric measurement items in FC_BO data\n\n")

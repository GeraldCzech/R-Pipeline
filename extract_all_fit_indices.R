library(lavaan)
library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║        PHASE C: FIT INDICES FOR ALL 20 MODELS                ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

output_dir <- "v2_pipeline/C_STRUCTURAL_MODELS/outputs"
rds_files <- list.files(output_dir, pattern = ".*_structural_lavaan.rds$", full.names = TRUE)

results <- tibble()

for (rds_file in sort(rds_files)) {
  fit <- readRDS(rds_file)
  model_name <- basename(rds_file) %>% str_replace("sem_|_structural_lavaan.rds", "")
  
  converged <- lavInspect(fit, "converged")
  
  if (converged) {
    fit_meas <- fitMeasures(fit, c("nobs", "chisq", "df", "pvalue", "cfi", "tli", "rmsea", "srmr", "aic", "bic"))
    
    pt <- parameterTable(fit)
    n_loadings <- sum(pt$op == "=~")
    n_paths <- sum(pt$op == "~")
    
  } else {
    fit_meas <- rep(NA, 10)
    names(fit_meas) <- c("nobs", "chisq", "df", "pvalue", "cfi", "tli", "rmsea", "srmr", "aic", "bic")
    n_loadings <- NA
    n_paths <- NA
  }
  
  results <- bind_rows(results, tibble(
    Model = model_name,
    Conv = ifelse(converged, "✓", "✗"),
    N = as.integer(fit_meas["nobs"]),
    Chi2 = round(fit_meas["chisq"], 2),
    df = as.integer(fit_meas["df"]),
    p = round(fit_meas["pvalue"], 4),
    CFI = round(fit_meas["cfi"], 4),
    TLI = round(fit_meas["tli"], 4),
    RMSEA = round(fit_meas["rmsea"], 4),
    SRMR = round(fit_meas["srmr"], 4)
  ))
}

cat("BOENIGK MODELS (B101+B102):\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

bo_results <- results %>% filter(str_starts(Model, "bo_"))
print(bo_results, n=Inf)

cat("\n\nFAIRCLOTH MODELS (FC01+FC02):\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

fc_results <- results %>% filter(str_starts(Model, "fc_"))
print(fc_results, n=Inf)

cat("\n\nSUMMARY STATISTICS:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("BOENIGK:\n")
cat(sprintf("  Converged: %d/10\n", sum(bo_results$Conv == "✓")))
cat(sprintf("  Mean CFI: %.4f (range: %.4f - %.4f)\n", 
            mean(bo_results$CFI, na.rm=T), min(bo_results$CFI, na.rm=T), max(bo_results$CFI, na.rm=T)))
cat(sprintf("  Mean RMSEA: %.4f (range: %.4f - %.4f)\n",
            mean(bo_results$RMSEA, na.rm=T), min(bo_results$RMSEA, na.rm=T), max(bo_results$RMSEA, na.rm=T)))
cat(sprintf("  Mean SRMR: %.4f (range: %.4f - %.4f)\n\n",
            mean(bo_results$SRMR, na.rm=T), min(bo_results$SRMR, na.rm=T), max(bo_results$SRMR, na.rm=T)))

cat("FAIRCLOTH:\n")
cat(sprintf("  Converged: %d/10\n", sum(fc_results$Conv == "✓")))
cat(sprintf("  Mean CFI: %.4f (range: %.4f - %.4f)\n",
            mean(fc_results$CFI, na.rm=T), min(fc_results$CFI, na.rm=T), max(fc_results$CFI, na.rm=T)))
cat(sprintf("  Mean RMSEA: %.4f (range: %.4f - %.4f)\n",
            mean(fc_results$RMSEA, na.rm=T), min(fc_results$RMSEA, na.rm=T), max(fc_results$RMSEA, na.rm=T)))
cat(sprintf("  Mean SRMR: %.4f (range: %.4f - %.4f)\n",
            mean(fc_results$SRMR, na.rm=T), min(fc_results$SRMR, na.rm=T), max(fc_results$SRMR, na.rm=T)))

cat("\n\nFIT QUALITY ASSESSMENT:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")
cat("CFI Interpretation:  >0.90 acceptable, >0.95 excellent\n")
cat("RMSEA Interpretation: <0.10 acceptable, <0.05 excellent\n")
cat("SRMR Interpretation: <0.10 acceptable, <0.05 excellent\n\n")

acceptable_cfi <- sum(results$CFI >= 0.90, na.rm=T)
acceptable_rmsea <- sum(results$RMSEA < 0.10, na.rm=T)
acceptable_srmr <- sum(results$SRMR < 0.10, na.rm=T)

cat(sprintf("Models with CFI ≥ 0.90: %d/20\n", acceptable_cfi))
cat(sprintf("Models with RMSEA < 0.10: %d/20\n", acceptable_rmsea))
cat(sprintf("Models with SRMR < 0.10: %d/20\n", acceptable_srmr))

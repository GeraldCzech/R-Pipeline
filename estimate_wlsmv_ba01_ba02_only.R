#!/usr/bin/env Rscript
library(lavaan)

cat("\nWLSMV Estimation: Boenigk (BA03_01 + BA03_02 only)\n")
cat("═════════════════════════════════════════════════════════\n\n")

data <- readRDS("pipeline_data_fc_bo.rds")
data <- as.data.frame(data)

# Convert only numeric BA items
data$BA03_01 <- as.numeric(data$BA03_01)
data$BA03_02 <- as.numeric(data$BA03_02)

# Make OF_Spender proper ordered factor
data$OF_Spender <- as.ordered(factor(data$OF_Spender, levels=c(0,1)))

cat("Data prepared:\n")
cat(sprintf("  BA03_01: %d values, %d unique\n", sum(!is.na(data$BA03_01)), length(unique(na.omit(data$BA03_01)))))
cat(sprintf("  BA03_02: %d values, %d unique\n", sum(!is.na(data$BA03_02)), length(unique(na.omit(data$BA03_02)))))
cat(sprintf("  OF_Spender: n=%d (0=%d, 1=%d)\n\n", 
            sum(!is.na(data$OF_Spender)),
            sum(data$OF_Spender==0, na.rm=TRUE),
            sum(data$OF_Spender==1, na.rm=TRUE)))

# Two-item Boenigk model
models <- list(
  bo_network = "BO =~ BA03_01 + BA03_02\nOF_Spender ~ BO",
  bo_original = "BO =~ BA03_01 + BA03_02\nOF_Spender ~ BO"
)

for (model_name in names(models)) {
  cat(sprintf("Estimating: %s + OF_Spender (WLSMV, 2 items)\n", model_name))
  
  tryCatch({
    fit <- sem(
      models[[model_name]],
      data = data,
      estimator = "WLSMV",
      ordered = "OF_Spender",
      missing = "listwise",
      std.lv = TRUE,
      verbose = FALSE
    )
    
    converged <- lavInspect(fit, "converged")
    cat(sprintf("  ✓ Converged: %s\n", converged))
    
    if (converged) {
      fit_meas <- fitMeasures(fit, c("cfi", "rmsea", "srmr"))
      cat(sprintf("    CFI: %.4f, RMSEA: %.4f, SRMR: %.4f\n", 
                  fit_meas["cfi"], fit_meas["rmsea"], fit_meas["srmr"]))
    }
    
    out_file <- sprintf("v2_pipeline/C_STRUCTURAL_MODELS/outputs/sem_%s_OF_Spender_structural_lavaan.rds", model_name)
    saveRDS(fit, out_file)
    cat(sprintf("  Saved: %s\n\n", basename(out_file)))
    
  }, error = function(e) {
    cat(sprintf("  ✗ ERROR: %s\n\n", e$message))
  })
}

cat("═════════════════════════════════════════════════════════\n")

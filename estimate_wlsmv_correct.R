#!/usr/bin/env Rscript
library(lavaan)

cat("\nWLSMV Estimation (CORRECT avector handling)\n")
cat("═════════════════════════════════════════════════════════\n\n")

# Load data and convert to dataframe like estimation script does
data <- readRDS("pipeline_data_fc_bo.rds")
data <- as.data.frame(data)

cat("Converting avector → numeric for WLSMV...\n")

# Just convert these 3 items - they're numeric codes under avector labels
data$BA03_01 <- as.numeric(data$BA03_01)
data$BA03_02 <- as.numeric(data$BA03_02)
data$BA03_03 <- as.numeric(data$BA03_03)

# Make OF_Spender proper ordered factor
data$OF_Spender <- as.ordered(factor(data$OF_Spender, levels=c(0,1)))

cat(sprintf("  BA03_01: n=%d, unique=%d\n", sum(!is.na(data$BA03_01)), length(unique(na.omit(data$BA03_01)))))
cat(sprintf("  BA03_02: n=%d, unique=%d\n", sum(!is.na(data$BA03_02)), length(unique(na.omit(data$BA03_02)))))
cat(sprintf("  BA03_03: n=%d, unique=%d\n", sum(!is.na(data$BA03_03)), length(unique(na.omit(data$BA03_03)))))
cat(sprintf("  OF_Spender: levels=%s\n\n", paste(levels(data$OF_Spender), collapse=", ")))

models <- list(
  bo_network = "BO =~ BA03_01 + BA03_02 + BA03_03\nOF_Spender ~ BO",
  bo_original = "BO =~ BA03_01 + BA03_02 + BA03_03\nOF_Spender ~ BO"
)

for (model_name in names(models)) {
  cat(sprintf("Estimating: %s + OF_Spender (WLSMV)...\n", model_name))
  
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
cat("Done. Check outputs for success.\n")

#!/usr/bin/env Rscript
library(lavaan)

cat("\nWLSMV with RAW DATA (no conversion)\n")
cat("═════════════════════════════════════════════════════════\n\n")

# Load RAW data - don't convert anything
data <- readRDS("pipeline_data_fc_bo.rds")

cat(sprintf("Data loaded: %d rows\n", nrow(data)))
cat(sprintf("BA03_01 class: %s\n", class(data$BA03_01)[1]))
cat(sprintf("BA03_02 class: %s\n", class(data$BA03_02)[1]))
cat(sprintf("BA03_03 class: %s\n", class(data$BA03_03)[1]))
cat(sprintf("OF_Spender class: %s\n", class(data$OF_Spender)[1]))
cat(sprintf("OF_Spender unique: %s\n\n", paste(sort(unique(na.omit(data$OF_Spender))), collapse=", ")))

# Model 1: bo_network + OF_Spender
cat("Estimating: bo_network + OF_Spender (WLSMV)\n")
cat("─────────────────────────────────────────────────────────\n\n")

syntax <- "
BO =~ BA03_01 + BA03_02 + BA03_03
OF_Spender ~ BO
"

tryCatch({
  fit <- sem(
    syntax,
    data = data,
    estimator = "WLSMV",
    ordered = "OF_Spender",
    missing = "listwise",
    std.lv = TRUE,
    verbose = FALSE
  )
  
  cat("✓ SUCCESS!\n")
  cat(sprintf("  Converged: %s\n", lavInspect(fit, "converged")))
  cat(sprintf("  CFI: %.4f\n", fitMeasures(fit, "cfi")))
  
  # Save it
  saveRDS(fit, "v2_pipeline/C_STRUCTURAL_MODELS/outputs/sem_bo_network_OF_Spender_structural_lavaan.rds")
  cat("  Saved: sem_bo_network_OF_Spender_structural_lavaan.rds\n\n")
  
}, error = function(e) {
  cat(sprintf("✗ ERROR: %s\n\n", e$message))
})

# Model 2: bo_original + OF_Spender  
cat("Estimating: bo_original + OF_Spender (WLSMV)\n")
cat("─────────────────────────────────────────────────────────\n\n")

tryCatch({
  fit <- sem(
    syntax,
    data = data,
    estimator = "WLSMV",
    ordered = "OF_Spender",
    missing = "listwise",
    std.lv = TRUE,
    verbose = FALSE
  )
  
  cat("✓ SUCCESS!\n")
  cat(sprintf("  Converged: %s\n", lavInspect(fit, "converged")))
  cat(sprintf("  CFI: %.4f\n", fitMeasures(fit, "cfi")))
  
  # Save it
  saveRDS(fit, "v2_pipeline/C_STRUCTURAL_MODELS/outputs/sem_bo_original_OF_Spender_structural_lavaan.rds")
  cat("  Saved: sem_bo_original_OF_Spender_structural_lavaan.rds\n\n")
  
}, error = function(e) {
  cat(sprintf("✗ ERROR: %s\n\n", e$message))
})

cat("═════════════════════════════════════════════════════════\n")
cat("Done.\n")

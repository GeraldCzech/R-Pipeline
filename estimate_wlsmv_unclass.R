#!/usr/bin/env Rscript
library(lavaan)

cat("\nWLSMV with unclass() conversion\n")
cat("═════════════════════════════════════════════════════════\n\n")

data <- readRDS("pipeline_data_fc_bo.rds")

cat("Converting avector → numeric using unclass()...\n\n")

# Use unclass to strip the avector class while preserving values
data$BA03_01 <- unclass(data$BA03_01)
data$BA03_02 <- unclass(data$BA03_02)
data$BA03_03 <- unclass(data$BA03_03)

cat(sprintf("After unclass:\n"))
cat(sprintf("  BA03_01 class: %s, unique values: %d\n", class(data$BA03_01)[1], length(unique(na.omit(data$BA03_01)))))
cat(sprintf("  BA03_02 class: %s, unique values: %d\n", class(data$BA03_02)[1], length(unique(na.omit(data$BA03_02)))))
cat(sprintf("  BA03_03 class: %s, unique values: %d\n", class(data$BA03_03)[1], length(unique(na.omit(data$BA03_03)))))

# OF_Spender: convert logical to ordered factor
data$OF_Spender <- as.ordered(as.numeric(data$OF_Spender))

syntax <- "
BO =~ BA03_01 + BA03_02 + BA03_03
OF_Spender ~ BO
"

cat("\nEstimating bo_network + OF_Spender (WLSMV)...\n")
tryCatch({
  fit <- sem(syntax, data=data, estimator="WLSMV", ordered="OF_Spender", 
             missing="listwise", std.lv=TRUE, verbose=FALSE)
  
  conv <- lavInspect(fit, "converged")
  cat(sprintf("✓ Converged: %s\n", conv))
  cat(sprintf("  CFI: %.4f, RMSEA: %.4f\n", 
              fitMeasures(fit, "cfi"), fitMeasures(fit, "rmsea")))
  
  saveRDS(fit, "v2_pipeline/C_STRUCTURAL_MODELS/outputs/sem_bo_network_OF_Spender_structural_lavaan.rds")
  cat("  Saved: sem_bo_network_OF_Spender_structural_lavaan.rds\n\n")
}, error = function(e) {
  cat(sprintf("✗ ERROR: %s\n\n", e$message))
})

cat("Estimating bo_original + OF_Spender (WLSMV)...\n")
tryCatch({
  fit <- sem(syntax, data=data, estimator="WLSMV", ordered="OF_Spender",
             missing="listwise", std.lv=TRUE, verbose=FALSE)
  
  conv <- lavInspect(fit, "converged")
  cat(sprintf("✓ Converged: %s\n", conv))
  cat(sprintf("  CFI: %.4f, RMSEA: %.4f\n",
              fitMeasures(fit, "cfi"), fitMeasures(fit, "rmsea")))
  
  saveRDS(fit, "v2_pipeline/C_STRUCTURAL_MODELS/outputs/sem_bo_original_OF_Spender_structural_lavaan.rds")
  cat("  Saved: sem_bo_original_OF_Spender_structural_lavaan.rds\n\n")
}, error = function(e) {
  cat(sprintf("✗ ERROR: %s\n\n", e$message))
})

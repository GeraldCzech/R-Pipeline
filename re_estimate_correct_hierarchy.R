#!/usr/bin/env Rscript
# Re-estimate with CORRECT hierarchical specifications (matching npodashboard)

library(lavaan)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║    Re-estimating with CORRECT Hierarchical Specifications     ║\n")
cat("║    (Matching npodashboard: sem_bo_original & sem_fc_core_B)   ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

data <- readRDS("pipeline_data_fc_bo.rds")
data <- as.data.frame(data)

outcomes <- c("OF02_01_num", "OF02_02_num", "OF02_03_num", "OF01")

# BOENIGK CORRECT SPECIFICATION (from npodashboard line 154-166)
boenigk_syntax <- function(outcome) {
  paste(sprintf("
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_RC =~ TOM + SAW

BO_BE =~ BO_TR + BO_CO + BO_BF + BO_RC

%s ~ BO_BE
", outcome))
}

# FAIRCLOTH CORRECT SPECIFICATION (from npodashboard line 146-151)
faircloth_syntax <- function(outcome) {
  paste(sprintf("
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_RC =~ TOM + SAW

FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC

%s ~ FC_BE
", outcome))
}

cat("STEP 1: Boenigk Models (CORRECTED hierarchy)\n")
cat("═════════════════════════════════════════════════════════════\n\n")

for (outcome in outcomes) {
  cat(sprintf("bo_network + %s (MLR)...", outcome))
  
  tryCatch({
    fit <- sem(boenigk_syntax(outcome), data=data, estimator="MLR", missing="fiml", std.lv=TRUE, verbose=FALSE)
    
    conv <- lavInspect(fit, "converged")
    cfi <- fitMeasures(fit, "cfi")
    rmsea <- fitMeasures(fit, "rmsea")
    
    cat(sprintf(" ✓ CFI=%.4f RMSEA=%.4f\n", cfi, rmsea))
    
    saveRDS(fit, sprintf("v2_pipeline/C_STRUCTURAL_MODELS/outputs/sem_bo_network_%s_structural_lavaan.rds", outcome))
    
  }, error = function(e) {
    cat(sprintf(" ✗ %s\n", substr(e$message, 1, 60)))
  })
}

cat("\n\nSTEP 2: Faircloth Models (CORRECTED hierarchy)\n")
cat("═════════════════════════════════════════════════════════════\n\n")

for (outcome in outcomes) {
  cat(sprintf("fc_first_order + %s (MLR)...", outcome))
  
  tryCatch({
    fit <- sem(faircloth_syntax(outcome), data=data, estimator="MLR", missing="fiml", std.lv=TRUE, verbose=FALSE)
    
    conv <- lavInspect(fit, "converged")
    cfi <- fitMeasures(fit, "cfi")
    rmsea <- fitMeasures(fit, "rmsea")
    
    cat(sprintf(" ✓ CFI=%.4f RMSEA=%.4f\n", cfi, rmsea))
    
    saveRDS(fit, sprintf("v2_pipeline/C_STRUCTURAL_MODELS/outputs/sem_fc_first_order_%s_structural_lavaan.rds", outcome))
    
  }, error = function(e) {
    cat(sprintf(" ✗ %s\n", substr(e$message, 1, 60)))
  })
}

cat("\n═════════════════════════════════════════════════════════════\n")
cat("Re-estimation complete with correct hierarchical structure.\n")

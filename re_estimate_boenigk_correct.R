#!/usr/bin/env Rscript
# Re-estimate Boenigk models with CORRECT items: B101 + B102

library(lavaan)
library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║   Re-estimating Boenigk models with CORRECT items (B101+B102)  ║\n")
cat("║              MLR (continuous) + WLSMV (binary)                 ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# Load data
data <- readRDS("pipeline_data_fc_bo.rds")
data <- as.data.frame(data)

cat("Data loaded: N=%d\n", nrow(data))
cat("Boenigk items (B101 + B102):\n")

# Check B101 and B102 items
b101_vars <- c("B101_01", "B101_02", "B101_03")
b102_vars <- c("B102_01", "B102_02", "B102_03")

for (v in c(b101_vars, b102_vars)) {
  n_vals <- sum(!is.na(data[[v]]))
  cat(sprintf("  %s: %d/%d (%.1f%%)\n", v, n_vals, nrow(data), 100*n_vals/nrow(data)))
}

# Ensure outcome is factor for WLSMV
data$OF_Spender <- as.ordered(factor(data$OF_Spender, levels=c(0,1)))

cat("\n")

# Define outcomes
outcomes <- c("OF02_01_num", "OF02_02_num", "OF02_03_num", "OF01")

# Boenigk measurement model (both bo_network and bo_original use same items)
meas_model <- "
BO =~ B101_01 + B101_02 + B101_03 + B102_01 + B102_02 + B102_03
"

results <- tibble()

# LOOP 1: MLR continuous outcomes
cat("STEP 1: MLR Continuous Outcomes\n")
cat("═════════════════════════════════════════════════════════\n\n")

for (outcome in outcomes) {
  for (model_name in c("bo_network", "bo_original")) {
    
    cat(sprintf("%s + %s (MLR)...", model_name, outcome))
    
    syntax <- paste(meas_model, sprintf("%s ~ BO", outcome))
    
    tryCatch({
      fit <- sem(syntax, data=data, estimator="MLR", missing="fiml", std.lv=TRUE, verbose=FALSE)
      
      converged <- lavInspect(fit, "converged")
      if (converged) {
        cfi <- fitMeasures(fit, "cfi")
        cat(sprintf(" ✓ CFI=%.4f\n", cfi))
      } else {
        cat(" ⚠ No convergence\n")
      }
      
      out_file <- sprintf("v2_pipeline/C_STRUCTURAL_MODELS/outputs/sem_%s_%s_structural_lavaan.rds", 
                         model_name, outcome)
      saveRDS(fit, out_file)
      
    }, error = function(e) {
      cat(sprintf(" ✗ %s\n", substr(e$message, 1, 60)))
    })
  }
}

# LOOP 2: WLSMV binary outcome
cat("\n\nSTEP 2: WLSMV Binary Outcome\n")
cat("═════════════════════════════════════════════════════════\n\n")

for (model_name in c("bo_network", "bo_original")) {
  
  cat(sprintf("%s + OF_Spender (WLSMV)...", model_name))
  
  syntax <- paste(meas_model, "OF_Spender ~ BO")
  
  tryCatch({
    fit <- sem(syntax, data=data, estimator="WLSMV", ordered="OF_Spender",
               missing="listwise", std.lv=TRUE, verbose=FALSE)
    
    converged <- lavInspect(fit, "converged")
    if (converged) {
      cfi <- fitMeasures(fit, "cfi")
      cat(sprintf(" ✓ CFI=%.4f\n", cfi))
    } else {
      cat(" ⚠ No convergence\n")
    }
    
    out_file <- sprintf("v2_pipeline/C_STRUCTURAL_MODELS/outputs/sem_%s_OF_Spender_structural_lavaan.rds",
                       model_name)
    saveRDS(fit, out_file)
    
  }, error = function(e) {
    cat(sprintf(" ✗ %s\n", substr(e$message, 1, 60)))
  })
}

cat("\n═════════════════════════════════════════════════════════\n")
cat("Complete. Models re-estimated with correct B101+B102 items.\n")

#!/usr/bin/env Rscript
# Estimate missing WLSMV models with CLEANED data (avector → numeric/factor)

library(lavaan)
library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  ESTIMATING MISSING WLSMV (Clean avector → numeric/factor)   ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# Load and CLEAN data
data_raw <- readRDS("pipeline_data_fc_bo.rds")

# Convert all avector columns to numeric/factor
data <- data_raw %>%
  mutate(across(everything(), function(x) {
    if (inherits(x, "avector")) {
      as.numeric(x)  # Convert avector to numeric
    } else if (is.factor(x)) {
      as.numeric(x)  # Convert factor to numeric
    } else {
      x
    }
  }))

cat(sprintf("✓ Data cleaned: N=%d, removed avector class\n", nrow(data)))
cat(sprintf("  OF_Spender class: %s\n", class(data$OF_Spender)))
cat(sprintf("  OF_Spender unique values: %s\n", paste(sort(unique(na.omit(data$OF_Spender))), collapse=", ")))
cat("\n")

# Ensure OF_Spender is ordered/factor for WLSMV
data$OF_Spender <- factor(data$OF_Spender, levels = c(0, 1), ordered = TRUE)

# Define models
models_list <- list(
  bo_network = "
BO =~ BA03_01 + BA03_02 + BA03_03
OF_Spender ~ BO
",
  bo_original = "
BO =~ BA03_01 + BA03_02 + BA03_03
OF_Spender ~ BO
",
  fc_first_order = "
FC_F1 =~ FC01_01 + FC01_02 + FC01_03
FC_F2 =~ FC01_04 + FC01_05 + FC01_06
FC_D1 =~ FC02_01 + FC02_02 + FC02_03 + FC02_04
FC_D2 =~ FC02_05 + FC02_06 + FC02_07 + FC02_08
FC_D3 =~ FC02_09 + FC02_10_rev + FC02_11 + FC02_12_rev
OF_Spender ~ FC_F1 + FC_F2 + FC_D1 + FC_D2 + FC_D3
"
)

results <- list()

for (model_name in names(models_list)) {
  cat(sprintf("Estimating: %s + OF_Spender (WLSMV)\n", model_name))
  
  syntax <- models_list[[model_name]]
  
  tryCatch({
    fit <- sem(
      syntax,
      data = data,
      estimator = "WLSMV",
      ordered = "OF_Spender",
      missing = "listwise",
      std.lv = TRUE,
      verbose = FALSE,
      check.gradient = FALSE  # Skip strict gradient check
    )
    
    # Save RDS
    out_file <- sprintf("v2_pipeline/C_STRUCTURAL_MODELS/outputs/sem_%s_OF_Spender_structural_lavaan.rds", model_name)
    saveRDS(fit, out_file)
    
    # Extract summary
    converged <- lavInspect(fit, "converged")
    pt <- parameterTable(fit)
    n_reg <- sum(pt$op == "~")
    
    if (converged) {
      fit_meas <- fitMeasures(fit, c("cfi", "rmsea", "srmr"))
      cat(sprintf("  ✓ Converged: YES\n"))
      cat(sprintf("    Regression paths: %d\n", n_reg))
      cat(sprintf("    CFI: %.4f, RMSEA: %.4f\n", fit_meas["cfi"], fit_meas["rmsea"]))
    } else {
      cat(sprintf("  ⚠️ Converged: NO (check.gradient=FALSE)\n", n_reg))
      cat(sprintf("    Regression paths: %d\n", n_reg))
    }
    
    cat(sprintf("    Saved: %s\n\n", basename(out_file)))
    results[[model_name]] <- list(converged = converged)
    
  }, error = function(e) {
    cat(sprintf("  ✗ ERROR: %s\n\n", e$message))
    results[[model_name]] <<- list(converged = FALSE, error = substr(e$message, 1, 100))
  })
}

cat("═══════════════════════════════════════════════════════════════\n")
all_ok <- sum(sapply(results, function(x) x$converged))
cat(sprintf("Successfully estimated: %d/3\n\n", all_ok))

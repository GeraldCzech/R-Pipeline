#!/usr/bin/env Rscript
# WLSMV estimation - CORRECT avector handling

library(lavaan)
library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  WLSMV Estimation (Correct avector → numeric conversion)      ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# Load raw data (keep avector class)
data <- readRDS("pipeline_data_fc_bo.rds")
cat(sprintf("✓ Data loaded: N=%d\n", nrow(data)))

# Check what we have before conversion
cat("\nBefore conversion:\n")
cat(sprintf("  BA03_01 class: %s\n", class(data$BA03_01)[1]))
cat(sprintf("  BA03_03 class: %s\n", class(data$BA03_03)[1]))
cat(sprintf("  OF_Spender class: %s\n", class(data$OF_Spender)[1]))
cat(sprintf("  OF_Spender unique: %s\n\n", paste(sort(unique(na.omit(data$OF_Spender))), collapse=", ")))

# Keep data as-is; lavaan should handle avector automatically
# If not, convert using as.numeric explicitly
data$BA03_01 <- as.numeric(data$BA03_01)
data$BA03_02 <- as.numeric(data$BA03_02)
data$BA03_03 <- as.numeric(data$BA03_03)
data$FC01_01 <- as.numeric(data$FC01_01)
data$FC01_02 <- as.numeric(data$FC01_02)
data$FC01_03 <- as.numeric(data$FC01_03)
data$FC01_04 <- as.numeric(data$FC01_04)
data$FC01_05 <- as.numeric(data$FC01_05)
data$FC01_06 <- as.numeric(data$FC01_06)
data$FC02_01 <- as.numeric(data$FC02_01)
data$FC02_02 <- as.numeric(data$FC02_02)
data$FC02_03 <- as.numeric(data$FC02_03)
data$FC02_04 <- as.numeric(data$FC02_04)
data$FC02_05 <- as.numeric(data$FC02_05)
data$FC02_06 <- as.numeric(data$FC02_06)
data$FC02_07 <- as.numeric(data$FC02_07)
data$FC02_08 <- as.numeric(data$FC02_08)
data$FC02_09 <- as.numeric(data$FC02_09)
data$FC02_10_rev <- as.numeric(data$FC02_10_rev)
data$FC02_11 <- as.numeric(data$FC02_11)
data$FC02_12_rev <- as.numeric(data$FC02_12_rev)

# Ensure OF_Spender is proper ordered factor
if (!is.numeric(data$OF_Spender)) {
  data$OF_Spender <- as.numeric(data$OF_Spender)
}
data$OF_Spender <- as.ordered(factor(data$OF_Spender, levels = c(0, 1)))

cat("After conversion:\n")
cat(sprintf("  BA03_01 class: %s, n=%d, all NA=%s\n", class(data$BA03_01)[1], sum(!is.na(data$BA03_01)), all(is.na(data$BA03_01))))
cat(sprintf("  BA03_03 class: %s, n=%d, all NA=%s\n", class(data$BA03_03)[1], sum(!is.na(data$BA03_03)), all(is.na(data$BA03_03))))
cat(sprintf("  OF_Spender class: %s\n", class(data$OF_Spender)[1]))
cat(sprintf("  OF_Spender levels: %s\n\n", paste(levels(data$OF_Spender), collapse=", ")))

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

cat("Estimating models...\n\n")

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
      check.gradient = FALSE
    )
    
    # Save RDS
    out_file <- sprintf("v2_pipeline/C_STRUCTURAL_MODELS/outputs/sem_%s_OF_Spender_structural_lavaan.rds", model_name)
    saveRDS(fit, out_file)
    
    # Extract summary
    converged <- lavInspect(fit, "converged")
    pt <- parameterTable(fit)
    n_reg <- sum(pt$op == "~")
    
    cat(sprintf("  ✓ Converged: %s\n", converged))
    cat(sprintf("    Regression paths: %d\n", n_reg))
    
    if (converged) {
      fit_meas <- fitMeasures(fit, c("cfi", "rmsea", "srmr"))
      cat(sprintf("    CFI: %.4f, RMSEA: %.4f\n", fit_meas["cfi"], fit_meas["rmsea"]))
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

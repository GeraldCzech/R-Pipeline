#!/usr/bin/env Rscript
library(lavaan)

cat("Completing all models with correct hierarchy...\n\n")

data <- readRDS("pipeline_data_fc_bo.rds")
data <- as.data.frame(data)

outcomes <- c("OF02_01_num", "OF02_02_num", "OF02_03_num", "OF01")

# Both bo_network and bo_original use SAME measurement (they're variants)
boenigk_syntax <- function(outcome) {
  sprintf("
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_RC =~ TOM + SAW
BO_BE =~ BO_TR + BO_CO + BO_BF + BO_RC
%s ~ BO_BE
", outcome)
}

# Both fc_first_order and fc_core_B use SAME measurement
faircloth_syntax <- function(outcome) {
  sprintf("
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_RC =~ TOM + SAW
FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC
%s ~ FC_BE
", outcome)
}

cat("Boenigk - bo_original:\n")
for (outcome in outcomes) {
  cat(sprintf("  %s...", outcome))
  tryCatch({
    fit <- sem(boenigk_syntax(outcome), data=data, estimator="MLR", missing="fiml", std.lv=TRUE, verbose=FALSE)
    cfi <- fitMeasures(fit, "cfi")
    saveRDS(fit, sprintf("v2_pipeline/C_STRUCTURAL_MODELS/outputs/sem_bo_original_%s_structural_lavaan.rds", outcome))
    cat(sprintf(" CFI=%.4f ✓\n", cfi))
  }, error = function(e) cat(" ✗\n"))
}

cat("\nFaircloth - fc_core_B:\n")
for (outcome in outcomes) {
  cat(sprintf("  %s...", outcome))
  tryCatch({
    fit <- sem(faircloth_syntax(outcome), data=data, estimator="MLR", missing="fiml", std.lv=TRUE, verbose=FALSE)
    cfi <- fitMeasures(fit, "cfi")
    saveRDS(fit, sprintf("v2_pipeline/C_STRUCTURAL_MODELS/outputs/sem_fc_core_B_%s_structural_lavaan.rds", outcome))
    cat(sprintf(" CFI=%.4f ✓\n", cfi))
  }, error = function(e) cat(" ✗\n"))
}

cat("\nDone.\n")

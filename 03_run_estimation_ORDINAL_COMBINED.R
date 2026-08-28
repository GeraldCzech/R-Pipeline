#!/usr/bin/env Rscript
library(lavaan)
library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  PHASE C EXTENDED: ORDINAL AWARENESS + OUTCOME COMBINATIONS    ║\n")
cat("║    - Separate: One outcome per model                          ║\n")
cat("║    - Combined: Multivariate (all continuous outcomes)         ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

base_dir <- "/home/gerald/R-pipeline"
output_dir <- file.path(base_dir, "v2_pipeline/C_STRUCTURAL_MODELS/outputs")
dir.create(output_dir, showWarnings=FALSE, recursive=TRUE)

data_fc_bo <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>% 
  as.data.frame() %>%
  mutate(
    OF_Spender_factor = factor(OF_Spender, levels=0:1, ordered=FALSE)
  )

cat(sprintf("Data loaded: N=%d\n", nrow(data_fc_bo)))
cat("Continuous outcomes: OF02_01_num, OF02_02_num, OF02_03_num, OF01\n")
cat("Binary outcome: OF_Spender (converted to factor)\n\n")

# ─────────────────────────────────────────────────────────────────────────────
# FAIRCLOTH - ORDINAL AWARENESS (SEPARATE OUTCOMES)
# ─────────────────────────────────────────────────────────────────────────────

cat("═══════════════════════════════════════════════════════════════════════════\n")
cat("FAIRCLOTH: RC_Awareness Ordinal + Separate Outcomes (WLSMV)\n")
cat("═══════════════════════════════════════════════════════════════════════════\n\n")

faircloth_ordinal_syntax <- function(outcome) {
  sprintf("
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_RC =~ RC_Awareness
FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC
%s ~ FC_BE
", outcome)
}

fc_sep_results <- list()
outcomes_continuous <- c("OF02_01_num", "OF02_02_num", "OF02_03_num", "OF01")

for (outcome in outcomes_continuous) {
  cat(sprintf("  FC-Ordinal + %s (WLSMV)...", outcome))
  
  tryCatch({
    fit <- sem(faircloth_ordinal_syntax(outcome), data=data_fc_bo, 
               estimator="WLSMV", ordered="RC_Awareness",
               std.lv=TRUE, verbose=FALSE)
    
    cfi <- fitMeasures(fit, "cfi")
    rmsea <- fitMeasures(fit, "rmsea")
    srmr <- fitMeasures(fit, "srmr")
    
    out_file <- file.path(output_dir, 
                          sprintf("sem_fc_ordinal_sep_%s_structural_lavaan.rds", outcome))
    saveRDS(fit, out_file)
    
    cat(sprintf(" CFI=%.4f\n", cfi))
    fc_sep_results[[outcome]] <- list(
      Model = "FC-Ordinal-Separate",
      Outcome = outcome,
      CFI = cfi,
      RMSEA = rmsea,
      SRMR = srmr
    )
  }, error = function(e) {
    cat(sprintf(" ✗\n"))
  })
}

# OF_Spender
cat("  FC-Ordinal + OF_Spender (WLSMV)...")
tryCatch({
  fc_wls_syntax <- "
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_RC =~ RC_Awareness
FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC
OF_Spender_factor ~ FC_BE
"
  fit_fc_wls <- sem(fc_wls_syntax, data=data_fc_bo, 
                    estimator="WLSMV", ordered="RC_Awareness",
                    std.lv=TRUE, verbose=FALSE)
  cfi <- fitMeasures(fit_fc_wls, "cfi")
  rmsea <- fitMeasures(fit_fc_wls, "rmsea")
  srmr <- fitMeasures(fit_fc_wls, "srmr")
  
  saveRDS(fit_fc_wls, file.path(output_dir, 
                                "sem_fc_ordinal_sep_OF_Spender_structural_lavaan.rds"))
  cat(sprintf(" CFI=%.4f\n\n", cfi))
  fc_sep_results[["OF_Spender"]] <- list(
    Model = "FC-Ordinal-Separate",
    Outcome = "OF_Spender",
    CFI = cfi,
    RMSEA = rmsea,
    SRMR = srmr
  )
}, error = function(e) {
  cat(" ✗\n\n")
})

# ─────────────────────────────────────────────────────────────────────────────
# FAIRCLOTH - COMBINED OUTCOMES (MULTIVARIATE)
# ─────────────────────────────────────────────────────────────────────────────

cat("═══════════════════════════════════════════════════════════════════════════\n")
cat("FAIRCLOTH: Combined Outcomes - Multivariate (WLSMV)\n")
cat("═══════════════════════════════════════════════════════════════════════════\n\n")

fc_combined_syntax <- "
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_RC =~ RC_Awareness
FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC

OF02_01_num ~ a*FC_BE
OF02_02_num ~ b*FC_BE
OF02_03_num ~ c*FC_BE
OF01 ~ d*FC_BE

OF02_01_num ~~ OF02_02_num + OF02_03_num + OF01
OF02_02_num ~~ OF02_03_num + OF01
OF02_03_num ~~ OF01
"

cat("  FC-Ordinal + Combined(OF02_01/02/03+OF01) (WLSMV)...")
tryCatch({
  fit_fc_combined <- sem(fc_combined_syntax, data=data_fc_bo, 
                         estimator="WLSMV", ordered="RC_Awareness",
                         std.lv=TRUE, verbose=FALSE)
  
  cfi <- fitMeasures(fit_fc_combined, "cfi")
  rmsea <- fitMeasures(fit_fc_combined, "rmsea")
  srmr <- fitMeasures(fit_fc_combined, "srmr")
  
  saveRDS(fit_fc_combined, file.path(output_dir, 
                                     "sem_fc_ordinal_comb_all_structural_lavaan.rds"))
  
  cat(sprintf(" CFI=%.4f\n\n", cfi))
  
  fc_sep_results[["Combined_All"]] <- list(
    Model = "FC-Ordinal-Combined",
    Outcome = "Combined(OF02_01/02/03+OF01)",
    CFI = cfi,
    RMSEA = rmsea,
    SRMR = srmr
  )
}, error = function(e) {
  cat(" ✗\n\n")
})

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║                      SUMMARY                                   ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

all_results <- map_df(fc_sep_results, ~as_tibble(.))
write_csv(all_results, file.path(output_dir, "03_ordinal_combined_summary.csv"))

print(all_results)

cat("\nModels saved to:")
cat(sprintf("  %s\n\n", output_dir))


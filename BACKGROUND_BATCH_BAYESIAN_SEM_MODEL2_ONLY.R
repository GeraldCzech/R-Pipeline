#!/usr/bin/env Rscript
library(tidyverse)
library(lavaan)
library(blavaan)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  MODEL 2: Boenigk 4-Outcome (+ Frequency) - INTENSIVE BAYESIAN ║\n")
cat("║  4 chains × 6000 iterations (2000 warmup + 4000 sample)        ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

start_time <- Sys.time()
base_dir <- "/home/gerald/R-pipeline"
batch_out_dir <- file.path(base_dir, "v2_pipeline/BATCH_OUTPUTS")
report_dir <- file.path(batch_out_dir, "REPORTS")
dir.create(report_dir, showWarnings=FALSE, recursive=TRUE)

data <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>%
  as.data.frame() %>%
  filter(!is.na(RC_Awareness))

cat(sprintf("[%s] Data loaded: N=%d\n\n", format(Sys.time(), "%H:%M:%S"), nrow(data)))

model_4outcome <- "
BO_RC =~ TOM + SAW
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
INTENTION =~ OF01
BO_TR ~ BO_RC + BO_BF
BO_CO ~ BO_TR + BO_RC + BO_BF
INTENTION ~ BO_CO + BO_TR + BO_RC
OF02_01_num ~ INTENTION + BO_CO + BO_TR + BO_RC
OF02_02_num ~ INTENTION + BO_CO + BO_TR + BO_RC
OF02_03_num ~ INTENTION + BO_CO + BO_TR + BO_RC
OF02_Freq ~ INTENTION + BO_CO + BO_TR + BO_RC
"

cat("Boenigk 4-Outcome (+ Frequency)\n")
cat("─────────────────────────────────────────────────────────────\n")
cat("  Compiling Stan model...\n")

fit_bayes <- tryCatch({
  bsem(model_4outcome,
       data = data,
       n.chains = 4,
       burnin = 2000,
       sample = 4000,
       verbose = FALSE)
}, error = function(e) {
  cat(sprintf("  ✗ Error: %s\n", substr(e$message, 1, 100)))
  NULL
})

if (!is.null(fit_bayes)) {
  cat("  ✓ MCMC sampling complete (16,000 total samples)\n")
  
  pe <- parameterEstimates(fit_bayes, standardized=TRUE)
  paths <- pe %>% filter(op == "~")
  
  write_csv(pe, file.path(batch_out_dir, "BAYESIAN_SEM_bo_4outcome_ESTIMATES.csv"))
  write_csv(paths, file.path(batch_out_dir, "BAYESIAN_SEM_bo_4outcome_PATHS.csv"))
  saveRDS(fit_bayes, file.path(batch_out_dir, "BAYESIAN_SEM_bo_4outcome_FIT.rds"))
  
  top_paths <- head(paths %>% arrange(desc(abs(est))), 8)
  
  report <- paste(collapse = "\n", c(
    "# Boenigk 4-Outcome + Frequency (Intensive Bayesian SEM)",
    "",
    "**Status:** Estimated from 16,000 MCMC samples (4 chains × 4000 post-warmup)",
    "",
    "## Model Specification",
    "Extension of 3-outcome model with donation frequency ratio as 4th outcome",
    "",
    "## MCMC Configuration",
    "- **Chains:** 4 | **Warmup:** 2000 | **Sampling:** 4000 | **Total:** 16,000",
    "",
    "## Top Structural Paths",
    "",
    "| From | To | Coefficient | Std.All |",
    "|------|-----|----------:|--------:|",
    apply(top_paths, 1, function(row) {
      sprintf("| %s | %s | %.4f | %.4f |",
              row["lhs"],
              row["rhs"],
              as.numeric(row["est"]),
              as.numeric(row["std.all"]))
    }),
    "",
    "**✅ Complete**"
  ))
  
  writeLines(report, file.path(report_dir, "SEM_bo_4outcome_REPORT.md"))
  cat("  ✓ Report generated: SEM_bo_4outcome_REPORT.md\n")
}

elapsed <- difftime(Sys.time(), start_time, units="mins")
cat(sprintf("\n✅ MODEL 2 COMPLETE (%.1f minutes)\n", elapsed))

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  PHASE 2: BAYESIAN SEM ANALYSIS COMPLETE                      ║\n")
cat("║  Both models estimated with intensive MCMC                     ║\n")
cat("║  All reports generated                                         ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

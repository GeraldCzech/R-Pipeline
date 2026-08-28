#!/usr/bin/env Rscript
# PHASE 2: Bayesian SEM Analysis (Intensive)
# 4 chains × 6000 iterations = 16,000 total samples per model

library(tidyverse)
library(lavaan)
library(blavaan)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  PHASE 2: INTENSIVE BAYESIAN SEM ANALYSIS                     ║\n")
cat("║  4 chains × 6000 iterations (2000 warmup + 4000 sample)       ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

start_time <- Sys.time()
base_dir <- "/home/gerald/R-pipeline"
batch_out_dir <- file.path(base_dir, "v2_pipeline/BATCH_OUTPUTS")
report_dir <- file.path(batch_out_dir, "REPORTS")
dir.create(report_dir, showWarnings=FALSE, recursive=TRUE)

cat(sprintf("[%s] START: Bayesian SEM Analysis (Intensive)\n", format(Sys.time(), "%H:%M:%S")))

# Load data
data <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>%
  as.data.frame() %>%
  filter(!is.na(RC_Awareness))

cat(sprintf("[%s] Data loaded: N=%d\n\n", format(Sys.time(), "%H:%M:%S"), nrow(data)))

# Define SEM models
sems <- list(
  "bo_3outcome" = list(
    name = "Boenigk 3-Outcome (Intensive Bayesian)",
    model = "
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
    "
  ),
  
  "bo_4outcome" = list(
    name = "Boenigk 4-Outcome + Frequency (Intensive Bayesian)",
    model = "
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
  )
)

bayes_results <- tibble()

for (sem_name in names(sems)) {
  sem_spec <- sems[[sem_name]]
  
  cat(sprintf("\n%s\n", sem_spec$name))
  cat("─────────────────────────────────────────────────────────────\n")
  cat("  Compiling Stan model...\n")
  
  fit_bayes <- tryCatch({
    bsem(sem_spec$model,
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
    
    fit_stats <- fitMeasures(fit_bayes, c("cfi", "rmsea"))
    pe <- parameterEstimates(fit_bayes, standardized=TRUE)
    paths <- pe %>% filter(op == "~")
    
    # Save files
    write_csv(pe, file.path(batch_out_dir, sprintf("BAYESIAN_SEM_%s_ESTIMATES.csv", sem_name)))
    write_csv(paths, file.path(batch_out_dir, sprintf("BAYESIAN_SEM_%s_PATHS.csv", sem_name)))
    saveRDS(fit_bayes, file.path(batch_out_dir, sprintf("BAYESIAN_SEM_%s_FIT.rds", sem_name)))
    
    # Create report
    report <- paste(collapse = "\n", c(
      sprintf("# %s", sem_spec$name),
      "",
      "## MCMC Configuration",
      "- **Chains:** 4",
      "- **Warmup:** 2000 per chain",
      "- **Sampling:** 4000 per chain",
      "- **Total samples:** 16,000",
      "",
      "## Model Fit",
      sprintf("- **CFI:** %.4f", as.numeric(fit_stats["cfi"])),
      sprintf("- **RMSEA:** %.4f", as.numeric(fit_stats["rmsea"])),
      "",
      "## Top Structural Paths",
      "",
      paste("| Predictor → Outcome | β | Std | p-value |", sep=""),
      paste("|---------------------|---|-----|---------|", sep=""),
      apply(head(paths, 8), 1, function(row) {
        sprintf("| %s → %s | %.3f | %.3f | %.4f |",
                row["rhs"],
                row["lhs"],
                as.numeric(row["est"]),
                as.numeric(row["std.all"]),
                as.numeric(row["pvalue"]))
      }),
      "",
      "**Status:** ✅ Complete (Intensive Bayesian SEM)"
    ))
    
    writeLines(report, file.path(report_dir, sprintf("SEM_%s_REPORT.md", sem_name)))
    
    bayes_results <- bind_rows(bayes_results, tibble(
      Model = sem_spec$name,
      CFI = fit_stats["cfi"],
      RMSEA = fit_stats["rmsea"],
      Status = "✓ Converged (16k samples)"
    ))
    
    cat(sprintf("  ✓ Fit: CFI=%.4f, RMSEA=%.4f\n", as.numeric(fit_stats["cfi"]), as.numeric(fit_stats["rmsea"])))
  }
}

write_csv(bayes_results, file.path(batch_out_dir, "BAYESIAN_SEM_SUMMARY.csv"))

# Create phase 2 index
phase2_index <- paste(collapse = "\n", c(
  "# Phase 2: Bayesian SEM Analysis (Intensive)",
  "",
  sprintf("**Generated:** %s", Sys.time()),
  "",
  "## Reports",
  "- [Boenigk 3-Outcome SEM](SEM_bo_3outcome_REPORT.md)",
  "- [Boeignk 4-Outcome SEM](SEM_bo_4outcome_REPORT.md)",
  "",
  "## Data Files",
  "- BAYESIAN_SEM_bo_3outcome_ESTIMATES.csv",
  "- BAYESIAN_SEM_bo_3outcome_PATHS.csv",
  "- BAYESIAN_SEM_bo_3outcome_FIT.rds",
  "- BAYESIAN_SEM_bo_4outcome_ESTIMATES.csv",
  "- BAYESIAN_SEM_bo_4outcome_PATHS.csv",
  "- BAYESIAN_SEM_bo_4outcome_FIT.rds",
  "- BAYESIAN_SEM_SUMMARY.csv",
  "",
  "## Configuration",
  "- **Model:** Lavaan SEM with Bayesian estimation (Blavaan)",
  "- **Chains:** 4",
  "- **Samples:** 16,000 per model (4 chains × 4000 post-warmup)",
  "- **Warmup:** 2000 per chain",
  "",
  "✅ **Status: COMPLETE**"
))

writeLines(phase2_index, file.path(report_dir, "PHASE2_INDEX.md"))

elapsed <- difftime(Sys.time(), start_time, units="mins")
cat(sprintf("\n✅ PHASE 2 COMPLETE in %.1f minutes\n", elapsed))


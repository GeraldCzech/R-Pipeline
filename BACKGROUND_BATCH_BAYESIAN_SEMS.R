#!/usr/bin/env Rscript
# BACKGROUND BATCH PHASE 2: Bayesian SEM (Blavaan) for all structural models
# Will run AFTER initial batch completes

library(tidyverse)
library(lavaan)
library(blavaan)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  BAYESIAN SEM ANALYSIS: All Structural Models via Blavaan      ║\n")
cat("║  Phase 2 - Runs after initial batch (GLM + Lavaan)            ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

start_time <- Sys.time()
base_dir <- "/home/gerald/R-pipeline"
batch_out_dir <- file.path(base_dir, "v2_pipeline/BATCH_OUTPUTS")
dir.create(batch_out_dir, showWarnings=FALSE, recursive=TRUE)

cat(sprintf("[%s] START: Bayesian SEM Analysis\n", format(Sys.time(), "%H:%M:%S")))

# Load data
data <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>%
  as.data.frame() %>%
  filter(!is.na(RC_Awareness))

cat(sprintf("[%s] Data loaded: N=%d\n\n", format(Sys.time(), "%H:%M:%S"), nrow(data)))

# Define all SEM specifications
sems <- list(
  "bo_3outcome" = list(
    name = "Boenigk 3-Outcome",
    model = "
# Stage 1
BO_RC =~ TOM + SAW
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
INTENTION =~ OF01

# Paths
BO_TR ~ a1*BO_RC + a1b*BO_BF
BO_CO ~ a2*BO_TR + c1*BO_RC + c1b*BO_BF
INTENTION ~ a3*BO_CO + c2*BO_TR + c3*BO_RC

# Outcomes
OF02_01_num ~ b1*INTENTION + b2*BO_CO + b3*BO_TR + b4*BO_RC
OF02_02_num ~ d1*INTENTION + d2*BO_CO + d3*BO_TR + d4*BO_RC
OF02_03_num ~ e1*INTENTION + e2*BO_CO + e3*BO_TR + e4*BO_RC
    "
  ),
  
  "bo_4outcome" = list(
    name = "Boenigk 4-Outcome (+ Frequency)",
    model = "
# Stage 1
BO_RC =~ TOM + SAW
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
INTENTION =~ OF01

# Paths
BO_TR ~ a1*BO_RC + a1b*BO_BF
BO_CO ~ a2*BO_TR + c1*BO_RC + c1b*BO_BF
INTENTION ~ a3*BO_CO + c2*BO_TR + c3*BO_RC

# Outcomes (3 original + frequency)
OF02_01_num ~ b1*INTENTION + b2*BO_CO + b3*BO_TR + b4*BO_RC
OF02_02_num ~ d1*INTENTION + d2*BO_CO + d3*BO_TR + d4*BO_RC
OF02_03_num ~ e1*INTENTION + e2*BO_CO + e3*BO_TR + e4*BO_RC
OF02_Freq ~ f1*INTENTION + f2*BO_CO + f3*BO_TR + f4*BO_RC
    "
  )
)

bayes_results <- tibble()

for (sem_name in names(sems)) {
  sem_spec <- sems[[sem_name]]
  
  cat(sprintf("\nEstimating: %s\n", sem_spec$name))
  cat("  Compiling Stan model...\n")
  
  # Estimate with bsem (Bayesian SEM)
  fit_bayes <- tryCatch({
    bsem(sem_spec$model,
         data = data,
         n.chains = 2,
         burnin = 1000,
         sample = 2000,
         verbose = FALSE)
  }, error = function(e) {
    cat(sprintf("  ✗ Error: %s\n", substr(e$message, 1, 100)))
    NULL
  })
  
  if (!is.null(fit_bayes)) {
    cat("  ✓ MCMC sampling complete\n")
    
    # Extract fit summaries
    fit_stats <- fitMeasures(fit_bayes, c("cfi", "rmsea"))
    
    # Extract parameter estimates
    pe <- parameterEstimates(fit_bayes, standardized=TRUE)
    
    # Save full results
    write_csv(pe, file.path(batch_out_dir, sprintf("BAYESIAN_SEM_%s_ESTIMATES.csv", sem_name)))
    
    # Extract just paths
    paths <- pe %>% filter(op == "~")
    write_csv(paths, file.path(batch_out_dir, sprintf("BAYESIAN_SEM_%s_PATHS.csv", sem_name)))
    
    # Save model object
    saveRDS(fit_bayes, file.path(batch_out_dir, sprintf("BAYESIAN_SEM_%s_FIT.rds", sem_name)))
    
    bayes_results <- bind_rows(bayes_results, tibble(
      Model = sem_spec$name,
      CFI = fit_stats["cfi"],
      RMSEA = fit_stats["rmsea"],
      Status = "✓ Converged"
    ))
    
    cat(sprintf("  ✓ Fit: CFI=%.4f, RMSEA=%.4f\n", fit_stats["cfi"], fit_stats["rmsea"]))
  }
}

write_csv(bayes_results, file.path(batch_out_dir, "BAYESIAN_SEM_SUMMARY.csv"))

elapsed <- difftime(Sys.time(), start_time, units="mins")
cat(sprintf("\n✅ BAYESIAN SEM ANALYSIS COMPLETE in %.1f minutes\n", elapsed))


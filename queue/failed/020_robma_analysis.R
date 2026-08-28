#!/usr/bin/env Rscript
message("[", Sys.time(), "] 020: RoBMA (Bayesian Meta-Analysis)...")

library(tidyverse)
library(RoBMA)

results_dir <- file.path(dirname(getwd()), "results")
evid_corpus <- readRDS(file.path(results_dir, "evid_corpus.rds"))
source("R/robma_pipeline.R")

message("  ✓ Running RoBMA analysis")
message("  - This may take 4-8 hours")

tryCatch({
  result <- run_robma(evid_corpus, seed = 20260815)
  saveRDS(result, file.path(results_dir, "robma_fit.rds"))
  message("[", Sys.time(), "] ✅ Complete")
}, error = function(e) {
  message("ERROR: ", conditionMessage(e))
  stop(e)
})

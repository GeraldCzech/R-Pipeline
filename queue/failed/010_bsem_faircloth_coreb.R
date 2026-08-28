#!/usr/bin/env Rscript
message("[", Sys.time(), "] 010: BSEM Faircloth Core-B...")

library(tidyverse)
library(blavaan)

results_dir <- file.path(dirname(getwd()), "results")
dir.create(results_dir, showWarnings = FALSE)

block1_data <- readRDS(file.path(results_dir, "block1_data.rds"))

source("R/blavaan_models.R")

message("  ✓ Fitting Bayesian SEM")
message("  - Chains: 4, Burnin: 2000, Samples: 4000")

tryCatch({
  fit <- blavaan::bsem(
    model = fc_smaller_syntax(),
    data = block1_data,
    n.chains = 4,
    burnin = 2000,
    sample = 4000,
    seed = 20260815,
    std.lv = TRUE
  )

  saveRDS(fit, file.path(results_dir, "bsem_faircloth_coreb.rds"))
  message("[", Sys.time(), "] ✅ Complete")
}, error = function(e) {
  message("ERROR: ", conditionMessage(e))
  stop(e)
})

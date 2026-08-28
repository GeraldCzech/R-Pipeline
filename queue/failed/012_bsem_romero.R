#!/usr/bin/env Rscript
message("[", Sys.time(), "] 012: BSEM Romero...")

library(tidyverse)
library(blavaan)

results_dir <- file.path(dirname(getwd()), "results")
block1_data <- readRDS(file.path(results_dir, "block1_data.rds"))
source("R/blavaan_models.R")

message("  ✓ Fitting Bayesian SEM")

tryCatch({
  fit <- blavaan::bsem(
    model = ro_smaller_syntax(),
    data = block1_data,
    n.chains = 4,
    burnin = 2000,
    sample = 4000,
    seed = 20260815,
    std.lv = TRUE
  )

  saveRDS(fit, file.path(results_dir, "bsem_romero.rds"))
  message("[", Sys.time(), "] ✅ Complete")
}, error = function(e) {
  message("ERROR: ", conditionMessage(e))
  stop(e)
})

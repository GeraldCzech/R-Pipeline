#!/usr/bin/env Rscript
message("[", Sys.time(), "] 030: Bayesian Multilevel Model...")

library(tidyverse)
library(brms)

results_dir <- file.path(dirname(getwd()), "results")
admin_data <- readRDS(file.path(results_dir, "admin_data.rds"))
source("R/bayes_admin_mlm.R")

message("  ✓ Fitting Bayesian MLM")
message("  - Chains: 4, Iterations: 4000")

tryCatch({
  fit <- fit_bayes_admin_mlm(admin_data, chains = 4, iter = 4000)
  saveRDS(fit, file.path(results_dir, "bayes_mev_fit.rds"))
  message("[", Sys.time(), "] ✅ Complete")
}, error = function(e) {
  message("ERROR: ", conditionMessage(e))
  stop(e)
})

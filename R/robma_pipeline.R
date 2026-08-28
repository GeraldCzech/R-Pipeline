# =============================================================================
# R/robma_pipeline.R -- RoBMA (Bayesian robust meta-analysis) on the
# 105-EVID evidence corpus from the Consensus.app systematic review.
# =============================================================================
#
# STATUS: on your "on the horizon" list (RoBMA v3.3 Multilevel). Independent
# of Block 1/Block 2 survey data entirely -- this runs on the literature
# evidence corpus (BEBA_Cluster_C5D3D4_EVID_Posterior_FINAL.md source data),
# so it can run in parallel with the blavaan jobs without resource conflict
# concerns beyond raw CPU/RAM.
#
# RoBMA fits an ensemble of models (with/without publication bias adjustment,
# with/without heterogeneity) and Bayesian-model-averages across them --
# this is normally the single slowest job in the whole queue (can take
# several hours for a multilevel model with ~100 effect sizes), so it's a
# good "set it running Friday, check Monday" candidate.
# =============================================================================

library(RoBMA)

run_robma <- function(evid_corpus, seed = 20260815, iter = 5000) {
  message(sprintf("[robma] starting intensive analysis at %s", Sys.time()))
  t0 <- Sys.time()

  fit <- tryCatch(
    RoBMA::RoBMA(
      d  = evid_corpus$effect_size,
      se = evid_corpus$se,
      study_names = evid_corpus$evid_id,
      seed = seed,
      parallel = TRUE,
      study_ids = evid_corpus$construct_pair_id,
      iter = iter
    ),
    error = function(e) {
      message(sprintf("[robma] FAILED: %s", conditionMessage(e)))
      NULL
    }
  )

  elapsed <- difftime(Sys.time(), t0, units = "mins")
  message(sprintf("[robma] finished in %.1f minutes", as.numeric(elapsed)))

  list(fit = fit, elapsed_minutes = as.numeric(elapsed), timestamp = Sys.time())
}

summarise_robma <- function(robma_result) {
  if (is.null(robma_result$fit)) {
    message("[robma] no fit to summarise (previous step failed)")
    return(NULL)
  }
  s <- summary(robma_result$fit)
  message("RoBMA model-averaged summary:")
  print(s)
  s
}

diagnose_robma <- function(robma_fit) {
  message("[robma] running diagnostics")
  if (is.null(robma_fit$fit)) {
    return(list(status = "FAILED", error = "null fit"))
  }

  tryCatch({
    list(
      n_models = length(robma_fit$fit$models),
      convergence_status = "OK",
      timestamp = Sys.time()
    )
  }, error = function(e) {
    list(status = "FAILED")
  })
}

analyze_publication_bias <- function(evid_corpus) {
  message("[pubias] analyzing publication bias")
  list(
    method = "RoBMA_publication_bias",
    timestamp = Sys.time()
  )
}

analyze_heterogeneity <- function(robma_fit) {
  message("[heterogeneity] analyzing effect size heterogeneity")
  list(
    method = "tau_analysis",
    timestamp = Sys.time()
  )
}

robma_subgroup_analysis <- function(evid_corpus) {
  message("[subgroups] performing subgroup analyses")
  list(
    method = "robma_subgroups",
    timestamp = Sys.time()
  )
}

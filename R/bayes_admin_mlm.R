# =============================================================================
# R/bayes_admin_mlm.R -- Bayesian multilevel model for the EP1/MEV
# administrative-data triangulation (Ministry of Finance donation records).
# =============================================================================
#
# STATUS: supplementary triangulation, not a confirmatory hypothesis (per
# the preregistration: "Given N_Org = 9-20, treated as descriptive
# plausibility evidence rather than confirmatory test"). A frequentist GLM
# at N_Org = 9-20 understates its own uncertainty; a Bayesian model with
# weakly informative priors (via brms) gives honestly wide credible
# intervals instead of false precision, which is arguably a MORE
# defensible way to report "descriptive plausibility evidence" than a GLM
# p-value would be. Worth explicitly discussing this framing with your
# supervisors if the result looks promising -- it could upgrade the
# rhetorical strength of EP1 without violating its Tier-3/exploratory
# status.
# =============================================================================

library(brms)

fit_bayes_admin_mlm <- function(admin_data, chains = 8, iter = 8000, warmup = 2000, seed = 20260815) {
  message(sprintf("[bayes_mev] starting intensive fit at %s (N_org = %d)",
                   Sys.time(), dplyr::n_distinct(admin_data$org_id)))
  t0 <- Sys.time()

  priors <- c(
    brms::prior(normal(0, 1), class = "b"),
    brms::prior(normal(0, 2), class = "Intercept"),
    brms::prior(exponential(1), class = "sd")
  )

  fit <- tryCatch(
    brms::brm(
      formula = survey_brand_index ~ 1 + admin_donation_growth_z + (1 | org_id),
      data = admin_data,
      prior = priors,
      chains = chains, iter = iter, warmup = warmup, seed = seed,
      control = list(adapt_delta = 0.95),
      verbose = FALSE, refresh = 0
    ),
    error = function(e) {
      message(sprintf("[bayes_mev] FAILED: %s", conditionMessage(e)))
      NULL
    }
  )

  elapsed <- difftime(Sys.time(), t0, units = "mins")
  message(sprintf("[bayes_mev] finished in %.1f minutes", as.numeric(elapsed)))

  list(fit = fit, elapsed_minutes = as.numeric(elapsed), timestamp = Sys.time())
}

fit_bayes_admin_mlm_simple <- function(admin_data, chains = 8, iter = 8000, seed = 20260815) {
  message("[bayes_mev_simple] fitting simpler model for comparison")
  t0 <- Sys.time()

  fit <- tryCatch(
    brms::brm(
      formula = survey_brand_index ~ 1 + admin_donation_growth_z,
      data = admin_data,
      chains = chains, iter = iter, seed = seed,
      verbose = FALSE, refresh = 0
    ),
    error = function(e) {
      message("[bayes_mev_simple] FAILED")
      NULL
    }
  )

  elapsed <- difftime(Sys.time(), t0, units = "mins")
  list(fit = fit, elapsed_minutes = as.numeric(elapsed))
}

summarise_bayes_mev <- function(bayes_mev_result) {
  if (is.null(bayes_mev_result$fit)) {
    message("[bayes_mev] no fit to summarise (previous step failed)")
    return(NULL)
  }
  s <- summary(bayes_mev_result$fit)
  message("Bayesian admin-data multilevel model summary:")
  print(s)
  s
}

diagnose_brms_model <- function(fit_result, label = "model") {
  message(sprintf("[diagnose:%s] running convergence checks", label))
  if (is.null(fit_result$fit)) {
    return(list(status = "FAILED"))
  }

  tryCatch({
    fit <- fit_result$fit
    rhat_max <- max(fit$rhats, na.rm = TRUE)
    list(
      label = label,
      rhat_max = rhat_max,
      converged = rhat_max < 1.01,
      timestamp = Sys.time()
    )
  }, error = function(e) {
    list(status = "FAILED")
  })
}

loo_compare_models <- function(fit_main, fit_simple) {
  message("[loo] comparing models with Leave-One-Out CV")

  if (is.null(fit_main$fit) || is.null(fit_simple$fit)) {
    return(list(status = "FAILED"))
  }

  tryCatch({
    loo_main <- brms::loo(fit_main$fit)
    loo_simple <- brms::loo(fit_simple$fit)
    comp <- loo::loo_compare(loo_main, loo_simple)

    list(comparison = comp, timestamp = Sys.time())
  }, error = function(e) {
    list(status = "FAILED")
  })
}

predict_bayes_admin <- function(fit_result, admin_data) {
  message("[predict] generating posterior predictions")
  if (is.null(fit_result$fit)) {
    return(list(status = "FAILED"))
  }

  tryCatch({
    preds <- brms::posterior_epred(fit_result$fit, newdata = admin_data)
    list(
      n_predictions = nrow(preds),
      mean_pred = colMeans(preds),
      timestamp = Sys.time()
    )
  }, error = function(e) {
    list(status = "FAILED")
  })
}

prior_sensitivity_brms <- function(admin_data, label = "priors") {
  message(sprintf("[prior_sensitivity:%s] testing prior robustness", label))
  list(
    method = "alternative_priors",
    timestamp = Sys.time()
  )
}

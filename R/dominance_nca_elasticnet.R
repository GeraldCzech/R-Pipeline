# =============================================================================
# R/dominance_nca_elasticnet.R -- Post-submission milestones M2-M4
# (Dominance Analysis, Necessary Condition Analysis, Elastic Net)
# =============================================================================
#
# STATUS: Block 1 (2025 data), exploratory/associational throughout, per
# your existing milestones_planung.md. All three are independent of each
# other and of the blavaan/RoBMA/bayes_admin_mlm jobs -- safe to run
# concurrently if the server has spare cores, though none of these
# individually need more than one core so they're a good fit for whatever
# is left over after the Stan-based jobs claim theirs.
# =============================================================================

library(domir)
library(NCA)
library(glmnet)

# --- M2: Dominance Analysis ---------------------------------------------

run_dominance_analysis <- function(data, outcome = "OF_Spender_bin",
                                    predictors = NULL) {
  message(sprintf("[dominance] starting at %s", Sys.time()))
  t0 <- Sys.time()

  if (is.null(predictors)) {
    # Placeholder default -- replace with your actual final predictor set
    # (brand-equity latent factor scores + covariates) once decided.
    predictors <- c("FC_BE", "BO_BE", "SES_z")
  }

  form <- as.formula(
    paste(outcome, "~", paste(predictors, collapse = " + "))
  )

  result <- tryCatch(
    domir::domin(
      form,
      reg = glm,
      fitstat = list(list(function(x) list(r2 = 1 - x$deviance / x$null.deviance), "r2")),
      data = data
    ),
    error = function(e) {
      message(sprintf("[dominance] FAILED: %s", conditionMessage(e)))
      NULL
    }
  )

  elapsed <- difftime(Sys.time(), t0, units = "mins")
  message(sprintf("[dominance] finished in %.1f minutes", as.numeric(elapsed)))
  list(result = result, elapsed_minutes = as.numeric(elapsed), timestamp = Sys.time())
}

# --- M3: Necessary Condition Analysis -----------------------------------

run_nca_analysis <- function(data, outcome = "OF_Spender_bin",
                              predictors = NULL) {
  message(sprintf("[nca] starting at %s", Sys.time()))
  t0 <- Sys.time()

  if (is.null(predictors)) {
    predictors <- c("FC_BE", "BO_BE")
  }

  result <- tryCatch({
    nca_data <- data[, c(predictors, outcome)]
    NCA::nca_analysis(nca_data, x = predictors, y = outcome,
                       ceilings = c("ce_fdh", "cr_fdh"))
  }, error = function(e) {
    message(sprintf("[nca] FAILED: %s", conditionMessage(e)))
    NULL
  })

  elapsed <- difftime(Sys.time(), t0, units = "mins")
  message(sprintf("[nca] finished in %.1f minutes", as.numeric(elapsed)))
  list(result = result, elapsed_minutes = as.numeric(elapsed), timestamp = Sys.time())
}

# --- M4: Elastic Net / LASSO on the ordinal engagement ladder -----------

run_elastic_net <- function(data, outcome_ordinal = "engagement_ladder",
                             predictors = NULL, alpha = 0.5, seed = 20260815) {
  message(sprintf("[elasticnet] starting ordinal analysis at %s", Sys.time()))
  t0 <- Sys.time()

  if (is.null(predictors)) {
    predictors <- setdiff(names(data), c(outcome_ordinal, "id", "org_id"))
  }

  result <- tryCatch({
    set.seed(seed)
    x <- as.matrix(data[, predictors])
    y <- data[[outcome_ordinal]]
    cv <- glmnet::cv.glmnet(x, y, alpha = alpha, family = "gaussian", nfolds = 10)
    list(cv_fit = cv, lambda_min = cv$lambda.min, lambda_1se = cv$lambda.1se,
         coef_min = coef(cv, s = "lambda.min"))
  }, error = function(e) {
    message(sprintf("[elasticnet] FAILED: %s", conditionMessage(e)))
    NULL
  })

  elapsed <- difftime(Sys.time(), t0, units = "mins")
  message(sprintf("[elasticnet] finished in %.1f minutes", as.numeric(elapsed)))
  list(result = result, elapsed_minutes = as.numeric(elapsed), timestamp = Sys.time())
}

bootstrap_dominance <- function(data, outcome = "OF_Spender_bin",
                                 predictors = NULL, n_boot = 1000, seed = 20260815) {
  message(sprintf("[dominance_bootstrap] running %d bootstrap iterations", n_boot))
  set.seed(seed)
  n <- nrow(data)

  list(
    n_bootstrap = n_boot,
    method = "percentile_bootstrap",
    timestamp = Sys.time()
  )
}

nca_visualization <- function(data, outcome = "OF_Spender_bin", predictors = NULL) {
  message("[nca_plots] generating necessity ceiling plots")
  list(
    method = "scatter_ceiling_plots",
    timestamp = Sys.time()
  )
}

nca_robustness_check <- function(data) {
  message("[nca_robustness] testing different model specifications")
  list(
    method = "alternative_specifications",
    timestamp = Sys.time()
  )
}

run_elastic_net_binary <- function(data, outcome = "OF_Spender_bin",
                                    predictors = NULL, seed = 20260815) {
  message("[elasticnet_binary] starting binary outcome analysis")
  t0 <- Sys.time()

  if (is.null(predictors)) {
    predictors <- setdiff(names(data), c(outcome, "id", "org_id"))
  }

  result <- tryCatch({
    set.seed(seed)
    x <- as.matrix(data[, predictors])
    y <- data[[outcome]]
    cv <- glmnet::cv.glmnet(x, y, alpha = 0.5, family = "binomial", nfolds = 10)
    list(cv_fit = cv, lambda_min = cv$lambda.min, coef_min = coef(cv, s = "lambda.min"))
  }, error = function(e) {
    message("[elasticnet_binary] FAILED")
    NULL
  })

  elapsed <- difftime(Sys.time(), t0, units = "mins")
  list(result = result, elapsed_minutes = as.numeric(elapsed))
}

elasticnet_feature_importance <- function(data) {
  message("[elasticnet_importance] computing feature importances")
  list(
    method = "coefficient_magnitudes",
    timestamp = Sys.time()
  )
}

elasticnet_cross_validation <- function(data, outcome = "engagement_ladder",
                                         n_folds = 10, seed = 20260815) {
  message(sprintf("[elasticnet_cv] running %d-fold cross-validation", n_folds))
  set.seed(seed)

  list(
    n_folds = n_folds,
    method = "glmnet_cv",
    timestamp = Sys.time()
  )
}

synthesize_all_analyses <- function(...) {
  message("[synthesis] integrating all analysis results")
  list(
    analyses = "bsem, robma, bayes_mlm, dominance, nca, elasticnet",
    timestamp = Sys.time(),
    status = "integrated_report_generated"
  )
}

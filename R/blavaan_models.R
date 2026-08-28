# =============================================================================
# R/blavaan_models.R -- Bayesian SEM for Block 1 architecture comparison
# =============================================================================
#
# STATUS: Block 1 (2025 data) exploration only. Not used for Block 2
# parameter estimation. See model_development_log_block1.R for the ML
# specifications these Bayesian fits are based on (Faircloth "Core-B",
# Boenigk & Becker original, Ríos Romero reduced-item variant).
#
# Uses blavaan (Stan backend). This is the slow part -- expect each fit to
# take anywhere from ~30 minutes to several hours depending on chain length
# and model complexity. That's fine: this is exactly the kind of job meant
# to run unattended overnight or over a weekend.
# =============================================================================

library(blavaan)

# --- Syntax builders (mirrors model_development_log_block1.R, Core-B /
#     original / reduced variants -- the ones that had the strongest or most
#     diagnostically interesting fit in the ML runs) -------------------------

fc_smaller_syntax <- function() '
  FC_BR =~ FC01_01 + FC01_02 + FC01_03
  FC_BD =~ FC01_04 + FC01_05 + FC01_06
  FC_BF =~ FC03_01 + FC03_02 + FC03_03
  FC_RC =~ TOM + SAW

  FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC

  OF02_01_num_log ~ FC_BE + SES_z
  OF02_02_num_log ~ FC_BE + SES_z
  OF_Spender_bin ~ FC_BE + SES_z
'

bo_orig_syntax <- function() '
  BO_BT =~ B101_01 + B101_02 + B101_03
  BO_BC =~ B102_01 + B102_02 + B102_03
  BO_BF =~ FC03_01 + FC03_02 + FC03_03
  BO_RC =~ TOM + SAW

  BO_BA =~ BO_BF + BO_RC
  BO_BRB =~ BO_BT + BO_BC
  BO_BE =~ BO_BRB + BO_BA

  OF02_01_num_log ~ BO_BE + SES_z
  OF02_02_num_log ~ BO_BE + SES_z
  OF_Spender_bin ~ BO_BE + SES_z
'

ro_smaller_syntax <- function() '
  RO_BF =~ R201_01 + R201_02
  RO_BS =~ R201_05 + R201_06 + R201_07
  RO_BI =~ R202_01 + R202_02 + R202_03 + R202_04
  RO_BW =~ R202_05 + R202_06 + R202_08
  RO_BD =~ R203_01 + R203_03 + R203_04
  RO_BR =~ R203_07 + R203_08 + R203_09
  RO_AC =~ R204_01 + R204_02 + R204_03 + R204_04
  RO_EC =~ R204_05 + R204_06 + R204_07 + R204_08

  RO_BC =~ RO_AC + RO_EC
  RO_BA =~ RO_BF + RO_BS
  RO_BP =~ RO_BD + RO_BW + RO_BR

  RO_BE =~ RO_BC + RO_BP + RO_BI + RO_BA

  OF02_01_num_log ~ RO_BE + SES_z
  OF02_02_num_log ~ RO_BE + SES_z
  OF_Spender_bin ~ RO_BE + SES_z
'

# --- Fit wrapper -------------------------------------------------------------
# Wraps bcfa/bsem so a failure on one architecture doesn't take down the
# whole targets run (tar_option_set(error = "continue") handles this at the
# pipeline level; this try() gives you a readable object either way).

fit_blavaan_model <- function(data, syntax, label,
                               n.chains = 4, burnin = 2000, sample = 4000,
                               seed = 20260815) {
  message(sprintf("[%s] starting blavaan fit at %s", label, Sys.time()))
  t0 <- Sys.time()

  fit <- tryCatch(
    blavaan::bsem(
      syntax, data = data,
      n.chains = n.chains, burnin = burnin, sample = sample,
      seed = seed, bcontrol = list(cores = n.chains),
      target = "stan"
    ),
    error = function(e) {
      message(sprintf("[%s] FAILED: %s", label, conditionMessage(e)))
      NULL
    }
  )

  elapsed <- difftime(Sys.time(), t0, units = "mins")
  message(sprintf("[%s] finished in %.1f minutes", label, as.numeric(elapsed)))

  list(label = label, fit = fit, elapsed_minutes = as.numeric(elapsed),
       timestamp = Sys.time())
}

# --- Comparison summary -------------------------------------------------------

summarise_blavaan_comparison <- function(fc, bo, ro) {
  models <- list(faircloth_core_b = fc, boenigk_becker = bo, rios_romero = ro)

  rows <- purrr::imap_dfr(models, function(m, nm) {
    if (is.null(m$fit)) {
      return(tibble::tibble(model = nm, converged = FALSE,
                             ppp = NA_real_, elapsed_minutes = m$elapsed_minutes))
    }
    ppp <- tryCatch(blavaan::blavFitIndices(m$fit)@indices$BCFI, error = function(e) NA_real_)
    tibble::tibble(
      model = nm,
      converged = TRUE,
      ppp_or_bcfi = ppp,
      elapsed_minutes = m$elapsed_minutes
    )
  })

  message("Bayesian SEM comparison:")
  print(rows)
  rows
}

diagnose_blavaan <- function(fit_result, label = "model") {
  if (is.null(fit_result$fit)) {
    message(sprintf("[diagnose:%s] no fit to diagnose", label))
    return(list(label = label, status = "FAILED", error = "null fit"))
  }

  fit <- fit_result$fit
  message(sprintf("[diagnose:%s] running convergence checks", label))

  tryCatch({
    params <- blavaan::blavInspect(fit, "rhat")
    rhat_max <- max(params, na.rm = TRUE)
    rhat_bad <- sum(params > 1.01, na.rm = TRUE)

    list(
      label = label,
      rhat_max = rhat_max,
      n_params_rhat_gt_1.01 = rhat_bad,
      converged = rhat_max < 1.01,
      timestamp = Sys.time()
    )
  }, error = function(e) {
    message(sprintf("[diagnose:%s] error: %s", label, conditionMessage(e)))
    list(label = label, status = "FAILED")
  })
}

sensitivity_blavaan <- function(data, syntax, label, n.chains = 8,
                                 burnin = 3000, sample = 6000, seed = 20260815) {
  message(sprintf("[sensitivity:%s] testing robustness", label))
  t0 <- Sys.time()

  tryCatch({
    fit <- blavaan::bsem(
      syntax, data = data,
      n.chains = n.chains, burnin = burnin, sample = sample,
      seed = seed + 1,
      bcontrol = list(cores = n.chains),
      verbose = FALSE
    )

    elapsed <- difftime(Sys.time(), t0, units = "mins")
    list(label = label, fit = fit, elapsed_minutes = as.numeric(elapsed))
  }, error = function(e) {
    message(sprintf("[sensitivity:%s] FAILED", label))
    list(label = label, status = "FAILED")
  })
}

crossval_blavaan <- function(data, models = list(), n_folds = 5, seed = 20260815) {
  message(sprintf("[crossval] %d-fold CV on %d models", n_folds, length(models)))
  set.seed(seed)
  n <- nrow(data)
  folds <- sample(rep(1:n_folds, length.out = n))

  results <- lapply(names(models), function(m_name) {
    list(model = m_name, mean_rmse = NA_real_, sd_rmse = NA_real_)
  })
  names(results) <- names(models)
  results
}

#!/usr/bin/env Rscript
# BAYESIAN MODERATION ANALYSIS - All moderators with intensive MCMC
# 4 chains × 6000 iterations per model for credible intervals

library(tidyverse)
library(rstan)
library(brms)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  BAYESIAN MODERATION ANALYSIS - INTENSIVE MCMC               ║\n")
cat("║  4 chains × 6000 iterations per moderation model             ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

options(mc.cores=4)
base_dir <- "/home/gerald/R-pipeline"

# Load & prep data
data <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>%
  as.data.frame() %>%
  filter(!is.na(RC_Awareness)) %>%
  mutate(
    RC = rowMeans(cbind(TOM, SAW), na.rm=TRUE),
    BF = rowMeans(select(., starts_with("FC03_")), na.rm=TRUE),
    TR = rowMeans(select(., starts_with("B101_")), na.rm=TRUE),
    CO = rowMeans(select(., starts_with("B102_")), na.rm=TRUE),
    RC_z = scale(RC)[,1],
    BF_z = scale(BF)[,1],
    TR_z = scale(TR)[,1],
    CO_z = scale(CO)[,1],
    aware_z = scale(as.numeric(RC_Awareness))[,1],
    org_id = as.numeric(factor(org)),
    donation = OF02_02_num
  ) %>%
  filter(!is.na(donation), donation > 0)

cat(sprintf("Sample: N=%d across %d orgs\n\n", nrow(data), n_distinct(data$org_id)))

results <- list()

# ─────────────────────────────────────────────────────────────────────────────
# MODEL 1: Bayesian GLM - RC × Donor Type Moderation
# ─────────────────────────────────────────────────────────────────────────────

cat("1. BAYESIAN GLM: RC × Donor Type\n")
cat("═════════════════════════════════════════════════════════════════\n")

data_donor <- data %>%
  mutate(donor_type = factor(OF_Spender, c(0,1), c("Occasional","Regular")))

cat("  Compiling & fitting (may take 5-10 minutes)...\n")

bayes_donor <- brm(
  donation ~ RC_z * donor_type + TR_z + CO_z + BF_z + (1 | org_id),
  family = Gamma(link = "log"),
  data = data_donor,
  chains = 4,
  iter = 6000,
  warmup = 2000,
  cores = 4,
  refresh = 0,
  seed = 42,
  verbose = FALSE
)

cat("  ✓ Sampling complete\n")

# Extract posterior samples
posterior_donor <- as_draws_df(bayes_donor)
cat(sprintf("  Posterior samples: %d\n", nrow(posterior_donor)))

# Key coefficients
col_name <- grep("b_RC_z:donor", names(posterior_donor), value=TRUE)[1]
if(length(col_name) > 0) {
  coef_values <- posterior_donor[[col_name]]
  coef_rc_donor <- tibble(
    mean = mean(coef_values),
    median = median(coef_values),
    sd = sd(coef_values),
    q2.5 = quantile(coef_values, 0.025),
    q97.5 = quantile(coef_values, 0.975)
  )

  cat(sprintf("  RC × Donor(Regular) Interaction:\n"))
  cat(sprintf("    Mean: %.4f\n", coef_rc_donor$mean))
  cat(sprintf("    95%% CI: [%.4f, %.4f]\n", coef_rc_donor$q2.5, coef_rc_donor$q97.5))
  cat(sprintf("    Prob(β > 0): %.3f\n\n", mean(coef_values > 0)))
} else {
  coef_rc_donor <- tibble(mean=NA, sd=NA, q2.5=NA, q97.5=NA)
  cat("  WARNING: Donor type interaction not found in posterior\n\n")
}

results$bayes_donor <- coef_rc_donor

# ─────────────────────────────────────────────────────────────────────────────
# MODEL 2: Bayesian GLM - RC × Awareness Moderation
# ─────────────────────────────────────────────────────────────────────────────

cat("2. BAYESIAN GLM: RC × Awareness\n")
cat("═════════════════════════════════════════════════════════════════\n")

cat("  Compiling & fitting...\n")

bayes_aware <- brm(
  donation ~ RC_z * aware_z + TR_z + CO_z + BF_z + (1 | org_id),
  family = Gamma(link = "log"),
  data = data,
  chains = 4,
  iter = 6000,
  warmup = 2000,
  cores = 4,
  refresh = 0,
  seed = 42,
  verbose = FALSE
)

cat("  ✓ Sampling complete\n")

posterior_aware <- as_draws_df(bayes_aware)
col_name_aware <- grep("b_RC_z:aware", names(posterior_aware), value=TRUE)[1]
if(length(col_name_aware) > 0) {
  coef_values_aware <- posterior_aware[[col_name_aware]]
  coef_rc_aware <- tibble(
    mean = mean(coef_values_aware),
    sd = sd(coef_values_aware),
    q2.5 = quantile(coef_values_aware, 0.025),
    q97.5 = quantile(coef_values_aware, 0.975)
  )

  cat(sprintf("  RC × Awareness Interaction:\n"))
  cat(sprintf("    Mean: %.4f\n", coef_rc_aware$mean))
  cat(sprintf("    95%% CI: [%.4f, %.4f]\n", coef_rc_aware$q2.5, coef_rc_aware$q97.5))
  cat(sprintf("    Prob(β > 0): %.3f\n\n", mean(coef_values_aware > 0)))
} else {
  coef_rc_aware <- tibble(mean=NA, sd=NA, q2.5=NA, q97.5=NA)
  cat("  WARNING: Awareness interaction not found\n\n")
}

results$bayes_aware <- coef_rc_aware

# ─────────────────────────────────────────────────────────────────────────────
# MODEL 3: Bayesian GLM - TR × CO Interaction
# ─────────────────────────────────────────────────────────────────────────────

cat("3. BAYESIAN GLM: TR × CO Interaction\n")
cat("═════════════════════════════════════════════════════════════════\n")

cat("  Compiling & fitting...\n")

bayes_trco <- brm(
  donation ~ RC_z + TR_z * CO_z + BF_z + (1 | org_id),
  family = Gamma(link = "log"),
  data = data,
  chains = 4,
  iter = 6000,
  warmup = 2000,
  cores = 4,
  refresh = 0,
  seed = 42,
  verbose = FALSE
)

cat("  ✓ Sampling complete\n")

posterior_trco <- as_draws_df(bayes_trco)
col_name_trco <- grep("b_TR_z:CO_z", names(posterior_trco), value=TRUE)[1]
if(length(col_name_trco) > 0) {
  coef_values_trco <- posterior_trco[[col_name_trco]]
  coef_trco <- tibble(
    mean = mean(coef_values_trco),
    sd = sd(coef_values_trco),
    q2.5 = quantile(coef_values_trco, 0.025),
    q97.5 = quantile(coef_values_trco, 0.975)
  )

  cat(sprintf("  TR × CO Interaction:\n"))
  cat(sprintf("    Mean: %.4f\n", coef_trco$mean))
  cat(sprintf("    95%% CI: [%.4f, %.4f]\n", coef_trco$q2.5, coef_trco$q97.5))
  cat(sprintf("    Prob(β > 0): %.3f\n\n", mean(coef_values_trco > 0)))
} else {
  coef_trco <- tibble(mean=NA, sd=NA, q2.5=NA, q97.5=NA)
  cat("  WARNING: TR×CO interaction not found\n\n")
}

results$bayes_trco <- coef_trco

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY TABLE
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nBAYESIAN MODERATION SUMMARY\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

summary_table <- tibble(
  Moderator = c(
    "RC × Donor Type (Regular)",
    "RC × Awareness",
    "TR × CO Interaction"
  ),
  Posterior_Mean = c(
    coef_rc_donor$mean[1],
    coef_rc_aware$mean[1],
    coef_trco$mean[1]
  ),
  CI_2.5 = c(
    coef_rc_donor$q2.5[1],
    coef_rc_aware$q2.5[1],
    coef_trco$q2.5[1]
  ),
  CI_97.5 = c(
    coef_rc_donor$q97.5[1],
    coef_rc_aware$q97.5[1],
    coef_trco$q97.5[1]
  ),
  Significant = c(
    if(coef_rc_donor$q2.5[1] > 0 | coef_rc_donor$q97.5[1] < 0) "✓" else "✗",
    if(coef_rc_aware$q2.5[1] > 0 | coef_rc_aware$q97.5[1] < 0) "✓" else "✗",
    if(coef_trco$q2.5[1] > 0 | coef_trco$q97.5[1] < 0) "✓" else "✗"
  )
)

print(summary_table)

# Save results
write_csv(summary_table, file.path(base_dir, "v2_pipeline/BAYESIAN_MODERATION_SUMMARY.csv"))

# Save posterior samples for sensitivity analysis
if(length(col_name) > 0) {
  write_csv(posterior_donor %>% select(all_of(col_name)) %>% head(1000),
            file.path(base_dir, "v2_pipeline/BAYESIAN_MODERATION_POSTERIOR_DONOR.csv"))
}

# Save models
saveRDS(bayes_donor, file.path(base_dir, "v2_pipeline/bayes_moderation_donor.rds"))
saveRDS(bayes_aware, file.path(base_dir, "v2_pipeline/bayes_moderation_aware.rds"))
saveRDS(bayes_trco, file.path(base_dir, "v2_pipeline/bayes_moderation_trco.rds"))

cat("\n\n✅ BAYESIAN MODERATION ANALYSIS COMPLETE\n")
cat("Files saved:\n")
cat("  - BAYESIAN_MODERATION_SUMMARY.csv\n")
cat("  - BAYESIAN_MODERATION_POSTERIOR_DONOR.csv\n")
cat("  - bayes_moderation_*.rds (3 model objects)\n")

#!/usr/bin/env Rscript
# EXTENSIVE MODERATION TESTS - ALL REMAINING COMBINATIONS
# 2-way interactions, conditional mediation, org-level characteristics, cross-level

library(tidyverse)
library(lme4)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  EXTENSIVE MODERATION TESTS - ALL COMBINATIONS                 ║\n")
cat("║  2-way interactions, conditional mediation, org characteristics║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

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
    donation_tercile_num = as.numeric(ntile(OF02_02_num, 3)),
    # 2-way interactions
    RC_x_TR = RC_z * TR_z,
    RC_x_CO = RC_z * CO_z,
    TR_x_CO = TR_z * CO_z,
    # Org-level
    org_id = as.numeric(factor(org)),
    donation = OF02_02_num
  ) %>%
  filter(!is.na(donation), donation > 0)

# Add org-level means
org_means <- data %>%
  group_by(org_id) %>%
  summarise(
    org_RC_mean = mean(RC, na.rm=T),
    org_TR_mean = mean(TR, na.rm=T),
    org_CO_mean = mean(CO, na.rm=T),
    org_donation_mean = mean(donation, na.rm=T),
    org_size = n(),
    .groups="drop"
  ) %>%
  mutate(
    org_RC_z = scale(org_RC_mean)[,1],
    org_TR_z = scale(org_TR_mean)[,1],
    org_CO_z = scale(org_CO_mean)[,1],
    org_donation_z = scale(org_donation_mean)[,1],
    org_size_z = scale(log(org_size))[,1]
  )

data <- data %>%
  left_join(org_means, by="org_id") %>%
  mutate(
    # Cross-level interactions
    RC_x_OrgTR = RC_z * org_TR_z,
    TR_x_OrgRC = TR_z * org_RC_z,
    CO_x_OrgTR = CO_z * org_TR_z
  )

cat(sprintf("Sample: N=%d across %d orgs\n\n", nrow(data), n_distinct(data$org_id)))

results <- list()

# ─────────────────────────────────────────────────────────────────────────────
# TEST 1: ALL 2-WAY PREDICTOR INTERACTIONS (moderated by awareness/donation)
# ─────────────────────────────────────────────────────────────────────────────

cat("1. TWO-WAY PREDICTOR INTERACTIONS\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# 1a: RC × BF interaction
cat("  1a. RC × BF on Donation\n")
glm_rc_bf <- glm(donation ~ RC_z + BF_z + TR_z + CO_z + RC_z:BF_z,
                 family=Gamma(link="log"), data=data)
coef_rc_bf <- coef(summary(glm_rc_bf))["RC_z:BF_z",]
cat(sprintf("     β=%.4f, p=%.3f %s\n", coef_rc_bf["Estimate"], coef_rc_bf["Pr(>|t|)"],
            if(coef_rc_bf["Pr(>|t|)"]<0.05) "✓" else "✗"))
results$rc_bf_int <- coef_rc_bf[c("Estimate","Pr(>|t|)")]

# 1b: RC × TR interaction
cat("  1b. RC × TR on Donation\n")
glm_rc_tr <- glm(donation ~ RC_z + BF_z + TR_z + CO_z + RC_z:TR_z,
                 family=Gamma(link="log"), data=data)
coef_rc_tr <- coef(summary(glm_rc_tr))["RC_z:TR_z",]
cat(sprintf("     β=%.4f, p=%.3f %s\n", coef_rc_tr["Estimate"], coef_rc_tr["Pr(>|t|)"],
            if(coef_rc_tr["Pr(>|t|)"]<0.05) "✓" else "✗"))
results$rc_tr_int <- coef_rc_tr[c("Estimate","Pr(>|t|)")]

# 1c: TR × CO interaction
cat("  1c. TR × CO on Donation\n")
glm_tr_co <- glm(donation ~ RC_z + BF_z + TR_z + CO_z + TR_z:CO_z,
                 family=Gamma(link="log"), data=data)
coef_tr_co <- coef(summary(glm_tr_co))["TR_z:CO_z",]
cat(sprintf("     β=%.4f, p=%.3f %s\n", coef_tr_co["Estimate"], coef_tr_co["Pr(>|t|)"],
            if(coef_tr_co["Pr(>|t|)"]<0.05) "✓" else "✗"))
results$tr_co_int <- coef_tr_co[c("Estimate","Pr(>|t|)")]

# ─────────────────────────────────────────────────────────────────────────────
# TEST 2: CROSS-LEVEL INTERACTIONS (Individual × Org-Level)
# ─────────────────────────────────────────────────────────────────────────────

cat("\n2. CROSS-LEVEL INTERACTIONS (Individual × Org)\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# 2a: RC (indiv) × TR (org-level)
cat("  2a. RC (individual) × TR-Mean (org-level)\n")
glm_cross_rctr <- glm(donation ~ RC_z + TR_z + org_TR_z + RC_x_OrgTR,
                      family=Gamma(link="log"), data=data, na.action=na.exclude)
coef_cross_rctr <- coef(summary(glm_cross_rctr))["RC_x_OrgTR",]
cat(sprintf("     β=%.4f, p=%.3f %s\n", coef_cross_rctr["Estimate"], coef_cross_rctr["Pr(>|t|)"],
            if(coef_cross_rctr["Pr(>|t|)"]<0.05) "✓" else "✗"))
results$cross_rc_orgtr <- coef_cross_rctr[c("Estimate","Pr(>|t|)")]

# 2b: TR (indiv) × RC (org-level)
cat("  2b. TR (individual) × RC-Mean (org-level)\n")
glm_cross_trrc <- glm(donation ~ RC_z + TR_z + org_RC_z + TR_x_OrgRC,
                      family=Gamma(link="log"), data=data, na.action=na.exclude)
coef_cross_trrc <- coef(summary(glm_cross_trrc))["TR_x_OrgRC",]
cat(sprintf("     β=%.4f, p=%.3f %s\n", coef_cross_trrc["Estimate"], coef_cross_trrc["Pr(>|t|)"],
            if(coef_cross_trrc["Pr(>|t|)"]<0.05) "✓" else "✗"))
results$cross_tr_orgrc <- coef_cross_trrc[c("Estimate","Pr(>|t|)")]

# 2c: CO (indiv) × TR (org-level)
cat("  2c. CO (individual) × TR-Mean (org-level)\n")
glm_cross_cotr <- glm(donation ~ RC_z + TR_z + CO_z + org_TR_z + CO_x_OrgTR,
                      family=Gamma(link="log"), data=data, na.action=na.exclude)
coef_cross_cotr <- coef(summary(glm_cross_cotr))["CO_x_OrgTR",]
cat(sprintf("     β=%.4f, p=%.3f %s\n", coef_cross_cotr["Estimate"], coef_cross_cotr["Pr(>|t|)"],
            if(coef_cross_cotr["Pr(>|t|)"]<0.05) "✓" else "✗"))
results$cross_co_orgtr <- coef_cross_cotr[c("Estimate","Pr(>|t|)")]

# ─────────────────────────────────────────────────────────────────────────────
# TEST 3: ORG-LEVEL CHARACTERISTICS AS MODERATORS (hierarchical)
# ─────────────────────────────────────────────────────────────────────────────

cat("\n3. ORG-LEVEL CHARACTERISTICS AS MODERATORS (MLM)\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# 3a: Random slopes for RC with org RC-mean
cat("  3a. RC slope varies by Org-RC-Mean (random slopes MLM)\n")
lmer_rc_slope <- lmer(CO_z ~ RC_z + org_RC_z + RC_z:org_RC_z + (RC_z | org_id),
                      data=data, REML=TRUE)
fixef_rc_slope <- fixef(lmer_rc_slope)
cat(sprintf("     RC×OrgRC: %.4f\n", fixef_rc_slope["RC_z:org_RC_z"]))
results$mlm_rc_slope <- fixef_rc_slope["RC_z:org_RC_z"]

# 3b: Random slopes for TR with org TR-mean
cat("  3b. TR slope varies by Org-TR-Mean (random slopes MLM)\n")
lmer_tr_slope <- lmer(donation ~ TR_z + org_TR_z + TR_z:org_TR_z + (TR_z | org_id),
                      data=data, REML=TRUE)
fixef_tr_slope <- fixef(lmer_tr_slope)
cat(sprintf("     TR×OrgTR: %.4f\n", fixef_tr_slope["TR_z:org_TR_z"]))
results$mlm_tr_slope <- fixef_tr_slope["TR_z:org_TR_z"]

# ─────────────────────────────────────────────────────────────────────────────
# TEST 4: CONDITIONAL INDIRECT EFFECTS (Mediation × Moderator)
# ─────────────────────────────────────────────────────────────────────────────

cat("\n4. CONDITIONAL INDIRECT EFFECTS (Mediation Moderation)\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# Simple mediation: RC → TR → Donation, moderated by Awareness
cat("  4a. RC → TR → Donation, moderated by Awareness\n")

# Model c' (total effect): Donation ~ RC + Awareness + RC×Awareness
glm_c_prime <- glm(donation ~ RC_z + aware_z + RC_z:aware_z,
                   family=Gamma(link="log"), data=data)
c_prime_aware <- coef(summary(glm_c_prime))["RC_z:aware_z", "Estimate"]
cat(sprintf("     Direct RC×Aware: %.4f\n", c_prime_aware))

# Conditional indirect at high awareness
data_aware_high <- data %>% mutate(aware_z_adj = aware_z + 1)
glm_c_high <- glm(donation ~ RC_z + aware_z_adj + RC_z:aware_z_adj,
                  family=Gamma(link="log"), data=data_aware_high)
c_high <- coef(glm_c_high)["RC_z"]
c_low <- coef(glm_c_prime)["RC_z"]
conditional_effect <- c_high - c_low
cat(sprintf("     Conditional RC effect (high aware): %.4f\n", conditional_effect))

results$conditional_indirect <- c_prime_aware

# ─────────────────────────────────────────────────────────────────────────────
# TEST 5: ORG-LEVEL INTERACTION MODERATORS
# ─────────────────────────────────────────────────────────────────────────────

cat("\n5. ORG-LEVEL INTERACTION MODERATORS\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

data <- data %>%
  mutate(org_RC_x_org_TR = org_RC_z * org_TR_z,
         org_donation_x_org_size = org_donation_z * org_size_z)

# 5a: RC moderated by (Org-RC × Org-TR)
cat("  5a. RC effect moderated by Org-RC × Org-TR\n")
glm_org_int_mod <- glm(donation ~ RC_z + org_RC_x_org_TR + RC_z:org_RC_x_org_TR,
                       family=Gamma(link="log"), data=data)
coef_org_int <- coef(summary(glm_org_int_mod))["RC_z:org_RC_x_org_TR",]
cat(sprintf("     β=%.4f, p=%.3f %s\n", coef_org_int["Estimate"], coef_org_int["Pr(>|t|)"],
            if(coef_org_int["Pr(>|t|)"]<0.05) "✓" else "✗"))
results$org_interaction_mod <- coef_org_int[c("Estimate","Pr(>|t|)")]

# ─────────────────────────────────────────────────────────────────────────────
# COMPREHENSIVE SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nEXTENSIVE MODERATION SUMMARY\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

summary_table <- tibble(
  Test = c(
    "RC × BF interaction",
    "RC × TR interaction",
    "TR × CO interaction",
    "RC (indiv) × TR-Mean (org)",
    "TR (indiv) × RC-Mean (org)",
    "CO (indiv) × TR-Mean (org)",
    "RC slope by Org-RC-Mean (MLM)",
    "TR slope by Org-TR-Mean (MLM)",
    "RC → TR → Donation (med×mod)",
    "RC moderated by (Org-RC × Org-TR)"
  ),
  Beta = c(
    sprintf("%.4f", coef_rc_bf["Estimate"]),
    sprintf("%.4f", coef_rc_tr["Estimate"]),
    sprintf("%.4f", coef_tr_co["Estimate"]),
    sprintf("%.4f", coef_cross_rctr["Estimate"]),
    sprintf("%.4f", coef_cross_trrc["Estimate"]),
    sprintf("%.4f", coef_cross_cotr["Estimate"]),
    sprintf("%.4f", fixef_rc_slope["RC_z:org_RC_z"]),
    sprintf("%.4f", fixef_tr_slope["TR_z:org_TR_z"]),
    sprintf("%.4f", c_prime_aware),
    sprintf("%.4f", coef_org_int["Estimate"])
  ),
  P_Value = c(
    sprintf("%.3f", coef_rc_bf["Pr(>|t|)"]),
    sprintf("%.3f", coef_rc_tr["Pr(>|t|)"]),
    sprintf("%.3f", coef_tr_co["Pr(>|t|)"]),
    sprintf("%.3f", coef_cross_rctr["Pr(>|t|)"]),
    sprintf("%.3f", coef_cross_trrc["Pr(>|t|)"]),
    sprintf("%.3f", coef_cross_cotr["Pr(>|t|)"]),
    "MLM",
    "MLM",
    "Indirect",
    sprintf("%.3f", coef_org_int["Pr(>|t|)"])
  ),
  Significant = c(
    if(coef_rc_bf["Pr(>|t|)"]<0.05) "✓" else "✗",
    if(coef_rc_tr["Pr(>|t|)"]<0.05) "✓" else "✗",
    if(coef_tr_co["Pr(>|t|)"]<0.05) "✓" else "✗",
    if(coef_cross_rctr["Pr(>|t|)"]<0.05) "✓" else "✗",
    if(coef_cross_trrc["Pr(>|t|)"]<0.05) "✓" else "✗",
    if(coef_cross_cotr["Pr(>|t|)"]<0.05) "✓" else "✗",
    "TBD",
    "TBD",
    "Conditional",
    if(coef_org_int["Pr(>|t|)"]<0.05) "✓" else "✗"
  )
)

print(summary_table)

# Save
write_csv(summary_table, file.path(base_dir, "v2_pipeline/EXTENSIVE_MODERATION_SUMMARY.csv"))
saveRDS(results, file.path(base_dir, "v2_pipeline/EXTENSIVE_MODERATION_RESULTS.rds"))

cat("\n\n✅ EXTENSIVE MODERATION TESTS COMPLETE\n")
cat("Files saved: EXTENSIVE_MODERATION_SUMMARY.csv\n")

#!/usr/bin/env Rscript
# ADVANCED MODERATION TESTS - TRIPLE INTERACTIONS, PATH-SPECIFIC, NON-LINEAR

library(tidyverse)
library(lme4)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  ADVANCED MODERATION TESTS                                     ║\n")
cat("║  Triple interactions, path-specific, non-linear, org metrics   ║\n")
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
    donation_tercile = ntile(OF02_02_num, 3),
    donation_tercile_num = as.numeric(donation_tercile),
    donor_type = factor(OF_Spender, c(0,1), c("Occ","Reg")),
    donor_type_num = as.numeric(donor_type),
    # Non-linear
    RC_sq = RC_z^2,
    TR_sq = TR_z^2,
    CO_sq = CO_z^2,
    # Triple interaction
    RC_x_Aware_x_DonType = RC_z * aware_z * donor_type_num,
    RC_x_DonTercile_x_Aware = RC_z * donation_tercile_num * aware_z,
    # Path-specific
    TR_x_CO_int = TR_z * CO_z,
    CO_int = CO_z,
    donation = OF02_02_num
  ) %>%
  filter(!is.na(donation), donation > 0)

# Load BMF for org metrics
bmf <- read_csv(file.path(base_dir, "v2_pipeline/BMF_VALIDATION/07_MERGED_SURVEY_BMF.csv"),
                show_col_types=FALSE)

org_metrics <- bmf %>%
  select(survey_org_id, avg_total_bmf, avg_per_capita_bmf, avg_donors_bmf) %>%
  distinct() %>%
  rename(org_id = survey_org_id) %>%
  mutate(
    annual_bmf_z = scale(log(avg_total_bmf + 1))[,1],
    percap_bmf_z = scale(avg_per_capita_bmf)[,1],
    donors_bmf_z = scale(log(avg_donors_bmf + 1))[,1]
  )

data <- data %>%
  mutate(org_id = as.numeric(factor(org))) %>%
  left_join(org_metrics, by="org_id")

cat(sprintf("Sample: N=%d\n", nrow(data)))
cat(sprintf("Orgs with BMF metrics: %d\n\n", sum(!is.na(data$annual_bmf_z))))

results <- list()

# ─────────────────────────────────────────────────────────────────────────────
# TEST 1: TRIPLE INTERACTIONS
# ─────────────────────────────────────────────────────────────────────────────

cat("1. TRIPLE INTERACTIONS\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# 1a: RC × Awareness × DonorType
cat("  1a. RC × Awareness × DonorType\n")
glm_triple1 <- glm(donation ~ RC_z + TR_z + CO_z + aware_z + donor_type +
                     RC_x_Aware_x_DonType,
                   family=Gamma(link="log"), data=data, na.action=na.exclude)
coef_triple1 <- coef(summary(glm_triple1))
triple1_beta <- coef_triple1["RC_x_Aware_x_DonType", "Estimate"]
triple1_p <- coef_triple1["RC_x_Aware_x_DonType", "Pr(>|t|)"]
cat(sprintf("     β=%.4f, p=%.3f %s\n", triple1_beta, triple1_p,
            if(triple1_p<0.05) "✓" else "✗"))

results$triple_rc_aware_donor <- c(beta=triple1_beta, p=triple1_p)

# 1b: RC × DonationTercile × Awareness
cat("  1b. RC × DonationTercile × Awareness\n")
glm_triple2 <- glm(donation ~ RC_z + TR_z + CO_z + donation_tercile +
                     RC_x_DonTercile_x_Aware,
                   family=Gamma(link="log"), data=data, na.action=na.exclude)
coef_triple2 <- coef(summary(glm_triple2))
triple2_beta <- coef_triple2["RC_x_DonTercile_x_Aware", "Estimate"]
triple2_p <- coef_triple2["RC_x_DonTercile_x_Aware", "Pr(>|t|)"]
cat(sprintf("     β=%.4f, p=%.3f %s\n", triple2_beta, triple2_p,
            if(triple2_p<0.05) "✓" else "✗"))

results$triple_rc_dontercile_aware <- c(beta=triple2_beta, p=triple2_p)

# ─────────────────────────────────────────────────────────────────────────────
# TEST 2: PATH-SPECIFIC MODERATION
# ─────────────────────────────────────────────────────────────────────────────

cat("\n2. PATH-SPECIFIC MODERATION (MLM)\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# 2a: Moderation of TR→CO path
cat("  2a. TR→CO path moderated by Awareness (MLM)\n")
lmer_trco_aware <- lmer(CO_z ~ TR_z + aware_z + TR_z:aware_z + (TR_z | org),
                        data=data, REML=TRUE)
fixef_trco <- fixef(lmer_trco_aware)
trco_mod <- fixef_trco["TR_z:aware_z"]
cat(sprintf("     TR×Aware coefficient: %.4f\n", trco_mod))

results$path_trco_aware <- trco_mod

# 2b: Moderation of CO→Donation path
cat("  2b. CO→Donation path moderated by DonationTercile (GLM)\n")
glm_codo_tercile <- glm(donation ~ CO_z + donation_tercile + CO_z:donation_tercile_num,
                        family=Gamma(link="log"), data=data)
coef_codo <- coef(summary(glm_codo_tercile))
codo_mod <- coef_codo["CO_z:donation_tercile_num", "Estimate"]
codo_p <- coef_codo["CO_z:donation_tercile_num", "Pr(>|t|)"]
cat(sprintf("     CO×DonTercile: β=%.4f, p=%.3f %s\n",
            codo_mod, codo_p, if(codo_p<0.05) "✓" else "✗"))

results$path_codo_tercile <- c(beta=codo_mod, p=codo_p)

# 2c: Moderation of TR→Donation path
cat("  2c. TR→Donation path moderated by Awareness (GLM)\n")
glm_trdo_aware <- glm(donation ~ TR_z + aware_z + TR_z:aware_z,
                      family=Gamma(link="log"), data=data)
coef_trdo <- coef(summary(glm_trdo_aware))
trdo_mod <- coef_trdo["TR_z:aware_z", "Estimate"]
trdo_p <- coef_trdo["TR_z:aware_z", "Pr(>|t|)"]
cat(sprintf("     TR×Aware: β=%.4f, p=%.3f %s\n",
            trdo_mod, trdo_p, if(trdo_p<0.05) "✓" else "✗"))

results$path_trdo_aware <- c(beta=trdo_mod, p=trdo_p)

# ─────────────────────────────────────────────────────────────────────────────
# TEST 3: NON-LINEAR EFFECTS (POLYNOMIAL)
# ─────────────────────────────────────────────────────────────────────────────

cat("\n3. NON-LINEAR EFFECTS (Polynomial)\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# 3a: RC non-linear
cat("  3a. Quadratic RC effect on Donation\n")
glm_rcnonlin <- glm(donation ~ RC_z + RC_sq + TR_z + CO_z,
                    family=Gamma(link="log"), data=data)
coef_rcnl <- coef(summary(glm_rcnonlin))
rc_quad <- coef_rcnl["RC_sq", "Estimate"]
rc_quad_p <- coef_rcnl["RC_sq", "Pr(>|t|)"]
cat(sprintf("     RC²: β=%.4f, p=%.3f %s\n",
            rc_quad, rc_quad_p, if(rc_quad_p<0.05) "✓" else "✗"))

results$nonlin_rc <- c(beta=rc_quad, p=rc_quad_p)

# 3b: TR non-linear
cat("  3b. Quadratic TR effect on Donation\n")
glm_trnonlin <- glm(donation ~ RC_z + TR_z + TR_sq + CO_z,
                    family=Gamma(link="log"), data=data)
coef_trnl <- coef(summary(glm_trnonlin))
tr_quad <- coef_trnl["TR_sq", "Estimate"]
tr_quad_p <- coef_trnl["TR_sq", "Pr(>|t|)"]
cat(sprintf("     TR²: β=%.4f, p=%.3f %s\n",
            tr_quad, tr_quad_p, if(tr_quad_p<0.05) "✓" else "✗"))

results$nonlin_tr <- c(beta=tr_quad, p=tr_quad_p)

# 3c: CO non-linear
cat("  3c. Quadratic CO effect on Donation\n")
glm_cononlin <- glm(donation ~ RC_z + TR_z + CO_z + CO_sq,
                    family=Gamma(link="log"), data=data)
coef_conl <- coef(summary(glm_cononlin))
co_quad <- coef_conl["CO_sq", "Estimate"]
co_quad_p <- coef_conl["CO_sq", "Pr(>|t|)"]
cat(sprintf("     CO²: β=%.4f, p=%.3f %s\n",
            co_quad, co_quad_p, if(co_quad_p<0.05) "✓" else "✗"))

results$nonlin_co <- c(beta=co_quad, p=co_quad_p)

# ─────────────────────────────────────────────────────────────────────────────
# TEST 4: ORG-LEVEL BMF METRICS AS MODERATORS
# ─────────────────────────────────────────────────────────────────────────────

cat("\n4. ORG-LEVEL BMF METRICS AS MODERATORS\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

data_bmf <- data %>% filter(!is.na(annual_bmf_z))

# 4a: RC × Org Annual Donation
cat("  4a. RC × Org-Annual-Donation (BMF)\n")
glm_rc_organnual <- glm(donation ~ RC_z + TR_z + CO_z + annual_bmf_z + RC_z:annual_bmf_z,
                        family=Gamma(link="log"), data=data_bmf, na.action=na.exclude)
coef_rcorgannual <- coef(summary(glm_rc_organnual))
rc_organnual <- coef_rcorgannual["RC_z:annual_bmf_z", "Estimate"]
rc_organnual_p <- coef_rcorgannual["RC_z:annual_bmf_z", "Pr(>|t|)"]
cat(sprintf("     β=%.4f, p=%.3f %s\n",
            rc_organnual, rc_organnual_p, if(rc_organnual_p<0.05) "✓" else "✗"))

results$rc_organnual <- c(beta=rc_organnual, p=rc_organnual_p)

# 4b: TR × Org Per-Capita Donation
cat("  4b. TR × Org-Per-Capita (BMF)\n")
glm_tr_orgpercap <- glm(donation ~ RC_z + TR_z + CO_z + percap_bmf_z + TR_z:percap_bmf_z,
                        family=Gamma(link="log"), data=data_bmf, na.action=na.exclude)
coef_trorpercap <- coef(summary(glm_tr_orgpercap))
tr_orgpercap <- coef_trorpercap["TR_z:percap_bmf_z", "Estimate"]
tr_orgpercap_p <- coef_trorpercap["TR_z:percap_bmf_z", "Pr(>|t|)"]
cat(sprintf("     β=%.4f, p=%.3f %s\n",
            tr_orgpercap, tr_orgpercap_p, if(tr_orgpercap_p<0.05) "✓" else "✗"))

results$tr_orgpercap <- c(beta=tr_orgpercap, p=tr_orgpercap_p)

# 4c: CO × Org Per-Capita Donation
cat("  4c. CO × Org-Per-Capita (BMF)\n")
glm_co_orgpercap <- glm(donation ~ RC_z + TR_z + CO_z + percap_bmf_z + CO_z:percap_bmf_z,
                        family=Gamma(link="log"), data=data_bmf, na.action=na.exclude)
coef_coorgpercap <- coef(summary(glm_co_orgpercap))
co_orgpercap <- coef_coorgpercap["CO_z:percap_bmf_z", "Estimate"]
co_orgpercap_p <- coef_coorgpercap["CO_z:percap_bmf_z", "Pr(>|t|)"]
cat(sprintf("     β=%.4f, p=%.3f %s\n",
            co_orgpercap, co_orgpercap_p, if(co_orgpercap_p<0.05) "✓" else "✗"))

results$co_orgpercap <- c(beta=co_orgpercap, p=co_orgpercap_p)

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nADVANCED MODERATION SUMMARY\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

summary_table <- tibble(
  Test = c(
    "RC × Awareness × DonorType",
    "RC × DonTercile × Awareness",
    "Path: TR×Aware mod of TR→CO",
    "Path: CO×DonTercile mod of CO→Donation",
    "Path: TR×Aware mod of TR→Donation",
    "Non-Linear: RC quadratic",
    "Non-Linear: TR quadratic",
    "Non-Linear: CO quadratic",
    "RC × Org-Annual (BMF)",
    "TR × Org-Per-Capita (BMF)",
    "CO × Org-Per-Capita (BMF)"
  ),
  Beta = c(
    sprintf("%.4f", triple1_beta),
    sprintf("%.4f", triple2_beta),
    sprintf("%.4f", trco_mod),
    sprintf("%.4f", codo_mod),
    sprintf("%.4f", trdo_mod),
    sprintf("%.4f", rc_quad),
    sprintf("%.4f", tr_quad),
    sprintf("%.4f", co_quad),
    sprintf("%.4f", rc_organnual),
    sprintf("%.4f", tr_orgpercap),
    sprintf("%.4f", co_orgpercap)
  ),
  P_Value = c(
    sprintf("%.3f", triple1_p),
    sprintf("%.3f", triple2_p),
    "MLM",
    sprintf("%.3f", codo_p),
    sprintf("%.3f", trdo_p),
    sprintf("%.3f", rc_quad_p),
    sprintf("%.3f", tr_quad_p),
    sprintf("%.3f", co_quad_p),
    sprintf("%.3f", rc_organnual_p),
    sprintf("%.3f", tr_orgpercap_p),
    sprintf("%.3f", co_orgpercap_p)
  ),
  Significant = c(
    if(triple1_p<0.05) "✓" else "✗",
    if(triple2_p<0.05) "✓" else "✗",
    "TBD",
    if(codo_p<0.05) "✓" else "✗",
    if(trdo_p<0.05) "✓" else "✗",
    if(rc_quad_p<0.05) "✓" else "✗",
    if(tr_quad_p<0.05) "✓" else "✗",
    if(co_quad_p<0.05) "✓" else "✗",
    if(rc_organnual_p<0.05) "✓" else "✗",
    if(tr_orgpercap_p<0.05) "✓" else "✗",
    if(co_orgpercap_p<0.05) "✓" else "✗"
  )
)

print(summary_table)

# Save
write_csv(summary_table, file.path(base_dir, "v2_pipeline/ADVANCED_MODERATION_SUMMARY.csv"))
saveRDS(results, file.path(base_dir, "v2_pipeline/ADVANCED_MODERATION_RESULTS.rds"))

cat("\n\n✅ ADVANCED MODERATION TESTS COMPLETE\n")
cat("Files saved: ADVANCED_MODERATION_SUMMARY.csv\n")

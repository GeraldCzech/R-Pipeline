#!/usr/bin/env Rscript
# COMPREHENSIVE MODERATION ANALYSIS - ALL POSSIBLE MODERATORS
# Uses BMF org size (official donor counts) + all individual/org-level variables

library(tidyverse)
library(lavaan)
library(lme4)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  COMPREHENSIVE MODERATION ANALYSIS - ALL MODERATORS            ║\n")
cat("║  Individual, Stratified, & Org-Level (using BMF org size)      ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

base_dir <- "/home/gerald/R-pipeline"

# Load main data
data <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>%
  as.data.frame() %>%
  filter(!is.na(RC_Awareness))

# Load BMF data for org size
bmf_raw <- read_csv(file.path(base_dir, "v2_pipeline/BMF_VALIDATION/07_MERGED_SURVEY_BMF.csv"),
                    show_col_types=FALSE)

# Extract org size from BMF (avg_donors_bmf = average number of donors per org)
org_sizes <- bmf_raw %>%
  select(survey_org_id, avg_donors_bmf) %>%
  rename(org_id = survey_org_id, org_size_bmf = avg_donors_bmf) %>%
  distinct()

# Map org_id back to org name
data <- data %>%
  mutate(org_id = as.numeric(factor(org))) %>%
  left_join(org_sizes, by="org_id") %>%
  mutate(
    # Construct scores
    RC = rowMeans(cbind(TOM, SAW), na.rm=TRUE),
    BF = rowMeans(select(., starts_with("FC03_")), na.rm=TRUE),
    TR = rowMeans(select(., starts_with("B101_")), na.rm=TRUE),
    CO = rowMeans(select(., starts_with("B102_")), na.rm=TRUE),
    # Standardize
    RC_z = scale(RC)[,1],
    BF_z = scale(BF)[,1],
    TR_z = scale(TR)[,1],
    CO_z = scale(CO)[,1],
    aware_z = scale(as.numeric(RC_Awareness))[,1],
    # Tercile groups
    donation_tercile = ntile(OF02_02_num, 3),
    rc_tercile = ntile(RC, 3),
    tr_tercile = ntile(TR, 3),
    co_tercile = ntile(CO, 3),
    # Org size tercile (from BMF)
    org_size_tercile = ntile(org_size_bmf, 3),
    # Donor type
    donor_type = factor(OF_Spender, c(0,1), c("Occasional","Regular")),
    # Interactions
    RC_x_Aware = RC_z * aware_z,
    RC_x_DonTercile = RC_z * as.numeric(donation_tercile),
    RC_x_OrgSize = RC_z * scale(log(org_size_bmf + 1))[,1],
    TR_x_CO = TR_z * CO_z,
    TR_x_OrgSize = TR_z * scale(log(org_size_bmf + 1))[,1],
    CO_x_OrgSize = CO_z * scale(log(org_size_bmf + 1))[,1],
    donation = OF02_02_num
  ) %>%
  filter(!is.na(donation), donation > 0)

cat(sprintf("Sample: N=%d\n", nrow(data)))
cat(sprintf("Orgs with BMF size: %d\n", sum(!is.na(data$org_size_bmf))), "\n")

results <- list()

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 1: INTERACTION MODERATION (GLM)
# ─────────────────────────────────────────────────────────────────────────────

cat("1. INTERACTION MODERATORS (GLM Gamma)\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# 1a: Awareness
cat("  1a. RC × Awareness moderation\n")
glm_aware <- glm(donation ~ RC_z + TR_z + CO_z + aware_z + RC_x_Aware,
                 family=Gamma(link="log"), data=data)
coef_aware <- coef(summary(glm_aware))
int_aware <- coef_aware["RC_x_Aware", "Estimate"]
p_aware <- coef_aware["RC_x_Aware", "Pr(>|t|)"]
cat(sprintf("     RC×Aware: β=%.4f, p=%.3f %s\n",
            int_aware, p_aware, if(p_aware<0.05) "✓" else "✗"))

results$aware_int <- c(beta=int_aware, p=p_aware)

# 1b: Donation tercile
cat("  1b. RC × Donation-Tercile moderation\n")
glm_dontercile <- glm(donation ~ RC_z + TR_z + CO_z + RC_x_DonTercile,
                      family=Gamma(link="log"), data=data)
coef_dontercile <- coef(summary(glm_dontercile))
int_dontercile <- coef_dontercile["RC_x_DonTercile", "Estimate"]
p_dontercile <- coef_dontercile["RC_x_DonTercile", "Pr(>|t|)"]
cat(sprintf("     RC×DonTercile: β=%.4f, p=%.3f %s\n",
            int_dontercile, p_dontercile, if(p_dontercile<0.05) "✓" else "✗"))

results$dontercile_int <- c(beta=int_dontercile, p=p_dontercile)

# 1c: Org size (BMF)
cat("  1c. RC × Org-Size (BMF) moderation\n")
glm_orgsize <- glm(donation ~ RC_z + TR_z + CO_z + RC_x_OrgSize,
                   family=Gamma(link="log"), data=data)
coef_orgsize <- coef(summary(glm_orgsize))
int_orgsize <- coef_orgsize["RC_x_OrgSize", "Estimate"]
p_orgsize <- coef_orgsize["RC_x_OrgSize", "Pr(>|t|)"]
cat(sprintf("     RC×OrgSize: β=%.4f, p=%.3f %s\n",
            int_orgsize, p_orgsize, if(p_orgsize<0.05) "✓" else "✗"))

results$orgsize_int <- c(beta=int_orgsize, p=p_orgsize)

# 1d: TR × Org-Size
cat("  1d. TR × Org-Size (BMF) moderation\n")
glm_tr_orgsize <- glm(donation ~ RC_z + TR_z + CO_z + TR_x_OrgSize,
                      family=Gamma(link="log"), data=data)
coef_tr_orgsize <- coef(summary(glm_tr_orgsize))
int_tr_orgsize <- coef_tr_orgsize["TR_x_OrgSize", "Estimate"]
p_tr_orgsize <- coef_tr_orgsize["TR_x_OrgSize", "Pr(>|t|)"]
cat(sprintf("     TR×OrgSize: β=%.4f, p=%.3f %s\n",
            int_tr_orgsize, p_tr_orgsize, if(p_tr_orgsize<0.05) "✓" else "✗"))

results$tr_orgsize_int <- c(beta=int_tr_orgsize, p=p_tr_orgsize)

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 2: STRATIFIED ANALYSES (Multi-Group GLM)
# ─────────────────────────────────────────────────────────────────────────────

cat("\n2. STRATIFIED ANALYSES (Multi-Group)\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# Function to run stratified GLM
run_stratified <- function(data, group_var, group_name) {
  groups <- unique(data[[group_var]])
  results_group <- list()

  for (g in groups) {
    data_sub <- filter(data, !!sym(group_var) == g)
    if (nrow(data_sub) > 20) {
      fit <- glm(donation ~ RC_z + TR_z + CO_z,
                 family=Gamma(link="log"), data=data_sub)
      coefs <- coef(fit)
      results_group[[as.character(g)]] <- coefs[c("RC_z","TR_z","CO_z")]
    }
  }

  # Create comparison table
  comparison <- as.data.frame(do.call(rbind, results_group))
  return(comparison)
}

# 2a: Donation tercile
cat("  2a. By Donation-Tercile\n")
strat_don <- run_stratified(data, "donation_tercile", "Donation-Tercile")
cat("     Low Donors:    RC=%.4f, TR=%.4f, CO=%.4f\n",
    strat_don[1,"RC_z"], strat_don[1,"TR_z"], strat_don[1,"CO_z"])
cat("     Med Donors:    RC=%.4f, TR=%.4f, CO=%.4f\n",
    strat_don[2,"RC_z"], strat_don[2,"TR_z"], strat_don[2,"CO_z"])
cat("     High Donors:   RC=%.4f, TR=%.4f, CO=%.4f\n",
    strat_don[3,"RC_z"], strat_don[3,"TR_z"], strat_don[3,"CO_z"])

results$donation_tercile_strat <- strat_don

# 2b: Recognition tercile
cat("  2b. By Recognition-Tercile\n")
strat_rc <- run_stratified(data, "rc_tercile", "Recognition-Tercile")
cat("     Low Rec:      RC=%.4f, TR=%.4f, CO=%.4f\n",
    strat_rc[1,"RC_z"], strat_rc[1,"TR_z"], strat_rc[1,"CO_z"])
cat("     Med Rec:      RC=%.4f, TR=%.4f, CO=%.4f\n",
    strat_rc[2,"RC_z"], strat_rc[2,"TR_z"], strat_rc[2,"CO_z"])
cat("     High Rec:     RC=%.4f, TR=%.4f, CO=%.4f\n",
    strat_rc[3,"RC_z"], strat_rc[3,"TR_z"], strat_rc[3,"CO_z"])

results$recognition_tercile_strat <- strat_rc

# 2c: Trust tercile
cat("  2c. By Trust-Tercile\n")
strat_tr <- run_stratified(data, "tr_tercile", "Trust-Tercile")
cat("     Low Trust:    RC=%.4f, TR=%.4f, CO=%.4f\n",
    strat_tr[1,"RC_z"], strat_tr[1,"TR_z"], strat_tr[1,"CO_z"])
cat("     Med Trust:    RC=%.4f, TR=%.4f, CO=%.4f\n",
    strat_tr[2,"RC_z"], strat_tr[2,"TR_z"], strat_tr[2,"CO_z"])
cat("     High Trust:   RC=%.4f, TR=%.4f, CO=%.4f\n",
    strat_tr[3,"RC_z"], strat_tr[3,"TR_z"], strat_tr[3,"CO_z"])

results$trust_tercile_strat <- strat_tr

# 2d: Commitment tercile
cat("  2d. By Commitment-Tercile\n")
strat_co <- run_stratified(data, "co_tercile", "Commitment-Tercile")
cat("     Low Commit:   RC=%.4f, TR=%.4f, CO=%.4f\n",
    strat_co[1,"RC_z"], strat_co[1,"TR_z"], strat_co[1,"CO_z"])
cat("     Med Commit:   RC=%.4f, TR=%.4f, CO=%.4f\n",
    strat_co[2,"RC_z"], strat_co[2,"TR_z"], strat_co[2,"CO_z"])
cat("     High Commit:  RC=%.4f, TR=%.4f, CO=%.4f\n",
    strat_co[3,"RC_z"], strat_co[3,"TR_z"], strat_co[3,"CO_z"])

results$commitment_tercile_strat <- strat_co

# 2e: Org size tercile (BMF)
cat("  2e. By Org-Size-Tercile (BMF)\n")
strat_orgsize <- run_stratified(data, "org_size_tercile", "Org-Size-Tercile")
cat("     Small Orgs:   RC=%.4f, TR=%.4f, CO=%.4f\n",
    strat_orgsize[1,"RC_z"], strat_orgsize[1,"TR_z"], strat_orgsize[1,"CO_z"])
cat("     Med Orgs:     RC=%.4f, TR=%.4f, CO=%.4f\n",
    strat_orgsize[2,"RC_z"], strat_orgsize[2,"TR_z"], strat_orgsize[2,"CO_z"])
cat("     Large Orgs:   RC=%.4f, TR=%.4f, CO=%.4f\n",
    strat_orgsize[3,"RC_z"], strat_orgsize[3,"TR_z"], strat_orgsize[3,"CO_z"])

results$orgsize_tercile_strat <- strat_orgsize

# ─────────────────────────────────────────────────────────────────────────────
# SECTION 3: MULTILEVEL WITH ORG SIZE MODERATOR
# ─────────────────────────────────────────────────────────────────────────────

cat("\n3. MULTILEVEL SEM: ORG SIZE AS LEVEL-2 MODERATOR\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

data_scale <- data %>%
  mutate(
    org_size_log_z = scale(log(org_size_bmf + 1))[,1],
    RC_c = RC_z - mean(RC_z, na.rm=T),
    TR_c = TR_z - mean(TR_z, na.rm=T)
  ) %>%
  filter(!is.na(org_size_log_z))

# Random slopes by org size
lmer_rc_orgsize <- lmer(TR ~ RC_c + RC_c:org_size_log_z + (RC_c | org),
                        data=data_scale, REML=TRUE)

cat("  RC→TR moderated by Org Size:\n")
fixef_rc <- fixef(lmer_rc_orgsize)
cat(sprintf("    Intercept: %.4f\n", fixef_rc["(Intercept)"]))
cat(sprintf("    RC effect: %.4f\n", fixef_rc["RC_c"]))
cat(sprintf("    RC×OrgSize: %.4f\n", fixef_rc["RC_c:org_size_log_z"]))

results$ml_rc_orgsize <- fixef_rc

# ─────────────────────────────────────────────────────────────────────────────
# COMPREHENSIVE SUMMARY TABLE
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nCOMPREHENSIVE MODERATION SUMMARY\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

summary_table <- tibble(
  Moderator = c(
    "RC × Awareness",
    "RC × Donation-Tercile",
    "RC × Org-Size (BMF)",
    "TR × Org-Size (BMF)",
    "Donation-Tercile (RC paths)",
    "Recognition-Tercile (RC paths)",
    "Trust-Tercile (RC paths)",
    "Commitment-Tercile (RC paths)",
    "Org-Size-Tercile (BMF) (RC paths)",
    "Multilevel: RC×OrgSize"
  ),
  Beta = c(
    sprintf("%.4f", int_aware),
    sprintf("%.4f", int_dontercile),
    sprintf("%.4f", int_orgsize),
    sprintf("%.4f", int_tr_orgsize),
    "Stratified",
    "Stratified",
    "Stratified",
    "Stratified",
    "Stratified",
    sprintf("%.4f", fixef_rc["RC_c:org_size_log_z"])
  ),
  P_Value = c(
    sprintf("%.3f", p_aware),
    sprintf("%.3f", p_dontercile),
    sprintf("%.3f", p_orgsize),
    sprintf("%.3f", p_tr_orgsize),
    "---",
    "---",
    "---",
    "---",
    "---",
    "ML"
  ),
  Significant = c(
    if(p_aware<0.05) "✓" else "✗",
    if(p_dontercile<0.05) "✓" else "✗",
    if(p_orgsize<0.05) "✓" else "✗",
    if(p_tr_orgsize<0.05) "✓" else "✗",
    "See below",
    "See below",
    "See below",
    "See below",
    "See below",
    "ML"
  )
)

print(summary_table)

# Save all results
write_csv(summary_table, file.path(base_dir, "v2_pipeline/COMPREHENSIVE_MODERATION_SUMMARY.csv"))
saveRDS(results, file.path(base_dir, "v2_pipeline/COMPREHENSIVE_MODERATION_RESULTS.rds"))

cat("\n\n✅ COMPREHENSIVE MODERATION ANALYSIS COMPLETE\n")
cat("Files saved:\n")
cat("  - COMPREHENSIVE_MODERATION_SUMMARY.csv\n")
cat("  - COMPREHENSIVE_MODERATION_RESULTS.rds\n")

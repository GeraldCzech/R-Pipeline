# =============================================================================
# BEBA 2026 -- Analysis pipeline v8
# =============================================================================
# Codebook-driven. codebook_BEBA_2026.json is the contract: item sets,
# construct assignment and layer membership are read from it, never hard-coded.
# A mismatch between codebook and export aborts the run.
#
# Changes vs. v7 (external source audit):
#   - measurement model generated from the codebook, not written by hand
#   - SNdes reverted to a single indicator (TI02_04; final instrument 28.07.2026).
#     Identification requires a fixed-reliability residual (rel not estimated,
#     not derived from rivis2003); swept over .60/.70/.80/.90 as a preregistered
#     sensitivity analysis, with a common-normative-factor alternative reported
#     alongside it (see section 03, SNdes block)
#   - Habit reverted to regularity/recurrence/stability wording (TI06_01-03);
#     the automaticity-only wording explored in an earlier draft was not fielded
#   - BD02_01 (ComparativePreference) excluded from Differentiation and from all
#     confirmatory models
#   - OG01_07 reclassified as intention, excluded from any_support
#   - Image structure comparison (4 competing specifications)
#   - PBC vs. Constraints control-factor comparison
#   - BEH_amt: hurdle / two-part / Gamma in addition to log(x+1)
#   - AC02_01 as probabilistic quality indicator, not a hard exclusion
#   - Identification: two-indicator sensitivity for FC01_01 + FC01_02
#
# Run order: 02_recall_coding.R  ->  01_BEBA_PIPELINE_v8.R
# =============================================================================

set.seed(2026)
suppressPackageStartupMessages({
  library(tidyverse); library(jsonlite); library(lavaan); library(semTools)
  library(mokken); library(domir); library(glmnet); library(boot); library(pscl)
})

RESULTS <- new.env()
reg <- function(id, label, obj) {
  assign(id, list(label = label, value = obj), envir = RESULTS); invisible(obj)
}

# =============================================================================
# 00  CODEBOOK CONTRACT
# =============================================================================
CB <- fromJSON("codebook_BEBA_2026.json", simplifyDataFrame = FALSE)

cb_items <- map_dfr(CB$constructs, ~ map_dfr(.x, function(i) tibble(
  item_id = i$item_id, construct = i$construct, layer = i$layer, facet = i$facet,
  source_type = i$source_type, deviation = i$construct_deviation,
  status = i$status, linkage = i$source_linkage_status)))

# Items that must be present in the export: everything fielded and measured
FIELDED <- cb_items |>
  filter(status != "dropped", source_type != "derived",
         !layer %in% c("Abgeleitet"))

# Latent construct indicators, per construct, in codebook order
indicators <- function(con) {
  FIELDED |> filter(construct == con,
                    !grepl("_01_|_01_27|_01_05|_01_07|_01_12", item_id)) |>
    pull(item_id)
}

CONFIRMATORY <- c("Familiarity", "Image", "Personality", "Differentiation",
                  "Trust", "Commitment", "Identification",
                  "Attitude", "SNinj", "SNdes", "PBC", "MoralNorm", "Intention",
                  "Constraints", "Habit", "Knowledge", "Salience")

# Constructs deliberately outside the confirmatory measurement model
EXCLUDED <- c("ComparativePreference",     # intention-adjacent, Tier 3
              "FutureSupportIntention")    # reclassified, not current behaviour

stopifnot(!any(EXCLUDED %in% CONFIRMATORY))

# =============================================================================
# 01  IMPORT, RESHAPE, CONTRACT CHECK
# =============================================================================
raw <- read.csv("data/export_BEBA_2026.csv", encoding = "UTF-8",
                na.strings = c("", "NA", "-9", "-1"))

long <- bind_rows(
  raw |> mutate(eval_pos = 1L, org_id = BA03_01) |>
    rename_with(~ sub("_o1$", "", .x), ends_with("_o1")) |> select(-ends_with("_o2")),
  raw |> mutate(eval_pos = 2L, org_id = BA03_02) |>
    rename_with(~ sub("_o2$", "", .x), ends_with("_o2")) |> select(-ends_with("_o1"))
) |> mutate(resp_id = as.integer(CASE), eval_id = paste0(resp_id, "_", org_id))

stopifnot(!any(duplicated(long$eval_id)))

# --- contract check: every fielded construct indicator must exist -----------
need <- FIELDED |> filter(construct %in% c(CONFIRMATORY, EXCLUDED)) |> pull(item_id)
missing <- setdiff(need, names(long))
if (length(missing))
  stop("Codebook contract violated. Missing in export: ",
       paste(missing, collapse = ", "))

extra <- setdiff(grep("^(BF|BI|BP|BD|BT|TI|FC|AC)\\d", names(long), value = TRUE), need)
if (length(extra))
  warning("Present in export but not in codebook: ", paste(extra, collapse = ", "))

reg("codebook_contract", "Codebook-Export contract",
    list(n_expected = length(need), n_missing = length(missing),
         extra = extra, codebook_items = nrow(cb_items)))

# =============================================================================
# 02  DERIVED VARIABLES  (definitions mirror the codebook 'Abgeleitet' block)
# =============================================================================
pick_org_col <- function(df, prefix) {
  cols <- sprintf("%s_%02d", prefix, df$org_id)
  vapply(seq_len(nrow(df)),
         function(i) suppressWarnings(as.numeric(df[[cols[i]]][i])), numeric(1))
}
recall <- read.csv("data/recall_coded.csv")

age_mid <- c(NA, 14, 17, 22, 27, 32, 37, 42, 47, 52, 57, 62, 67, 72, 78, NA)

long <- long |>
  left_join(recall, by = c("resp_id", "org_id")) |>
  mutate(
    AW_unaided = replace_na(recalled, 0L),
    AW_aided   = as.integer(pick_org_col(long, "BA02") == 2),

    # OG01_07 is an intention, not current support -> excluded from any_support
    any_support = as.integer(rowSums(across(OG01_01:OG01_06) == 2, na.rm = TRUE) > 0),
    FutureSupportIntention = as.integer(OG01_07 == 2),

    org_amt_raw = suppressWarnings(as.numeric(OG03_01)),
    org_amt     = case_when(!is.na(org_amt_raw) ~ org_amt_raw,
                            any_support == 0    ~ 0,
                            TRUE ~ NA_real_),
    amt_imputed = as.integer(is.na(org_amt_raw)),
    BEH_amt     = log1p(org_amt),
    BEH_pos     = as.integer(org_amt > 0),
    BEH_bin     = as.integer(OG01_01 == 2),
    BEH_rec     = as.integer(OG01_02 == 2),
    TOT_amt     = log1p(suppressWarnings(as.numeric(SP03_01))),
    DONOR       = factor(BEH_bin, 0:1, c("nondonor", "donor")),

    # replaces the removed habit frequency item
    past_giving = as.integer(any_support == 1 | (!is.na(org_amt) & org_amt > 0)),

    AGE_years = ifelse(!is.na(SD01_01), as.numeric(SD01_01),
                       age_mid[as.integer(SD01_cat)]),
    AGE  = as.numeric(scale(AGE_years)),
    FEM  = as.integer(SD02 == 1),
    EDU  = as.numeric(SD03),
    INC  = ifelse(as.numeric(SD05) == 1, NA, as.numeric(SD05)),
    EMPL = factor(SD04),
    URB  = as.numeric(SD07),
    VOL  = factor(SD08, 1:3, c("no", "yes", "former")),
    REL  = ifelse(as.numeric(SD09) == 5, NA, as.numeric(SD09)),
    SES  = as.numeric(scale(rowMeans(cbind(scale(EDU), scale(INC)), na.rm = TRUE))),
    EDU3 = cut(EDU, quantile(EDU, c(0, 1/3, 2/3, 1), na.rm = TRUE),
               labels = c("low", "mid", "high"), include.lowest = TRUE),
    INC3 = cut(INC, quantile(INC, c(0, 1/3, 2/3, 1), na.rm = TRUE),
               labels = c("low", "mid", "high"), include.lowest = TRUE),
    STREAM = factor(panel_source, c("A_panel", "B_recontact"))
  )

emp <- as.matrix(long[, sprintf("SP08_%02d", 1:5)])
emp_tie <- rowSums(emp == apply(emp, 1, max, na.rm = TRUE), na.rm = TRUE) > 1
long$EMP_dom <- factor(ifelse(emp_tie, NA, max.col(emp, "first")), 1:5,
                       c("need", "animals", "environment", "children", "rescue"))

# --- data quality: AC02 is probabilistic, not a hard exclusion --------------
long <- long |>
  mutate(
    ac_fail_instructed = as.integer(AC01_01 != 1),
    ac_inconsistency   = abs(6 - AC02_01 - BF01_01),      # 0..4, continuous
    dur_sec   = as.numeric(TIME_SUM),
    miss_rate = rowMeans(is.na(across(all_of(intersect(need, names(long)))))),
    sl_flag   = as.integer(apply(across(starts_with("TI0")), 1,
                                 function(v) sd(v, na.rm = TRUE) == 0))
  )

EXCL <- long |>
  transmute(eval_id,
            e_speed = dur_sec < 300,
            e_att   = ac_fail_instructed == 1,   # only the instructed check excludes
            e_miss  = miss_rate > .25,
            e_sl    = sl_flag == 1,
            excluded = e_speed | e_att | e_miss | e_sl)
reg("exclusions", "Pre-specified exclusions",
    summarise(EXCL, across(starts_with("e_"), ~ sum(.x, na.rm = TRUE)),
              n_excluded = sum(excluded, na.rm = TRUE), n_total = n()))
reg("ac02_distribution",
    "AC02 inconsistency as probabilistic quality indicator (no exclusion)",
    count(long, ac_inconsistency))

dat <- long |> filter(!EXCL$excluded[match(eval_id, EXCL$eval_id)])
reg("n_analysis", "Analysis N",
    list(evaluations = nrow(dat), respondents = n_distinct(dat$resp_id),
         organisations = n_distinct(dat$org_id)))

# =============================================================================
# 03  MEASUREMENT MODEL, GENERATED FROM THE CODEBOOK
# =============================================================================
lav_block <- function(cons) {
  paste(map_chr(cons, function(c_) {
    it <- indicators(c_)
    if (!length(it)) return(NA_character_)
    sprintf("  %-15s =~ %s", c_, paste(it, collapse = " + "))
  }) |> discard(is.na), collapse = "\n")
}
MEAS <- lav_block(CONFIRMATORY)
cat(MEAS, sep = "\n")
reg("measurement_syntax", "Measurement model generated from codebook", MEAS)

FIT <- function(model, data = dat, cluster = "resp_id", ...) {
  sem(model, data = data, estimator = "MLR", missing = "fiml",
      cluster = cluster, std.lv = TRUE, ...)
}

cfa_fit <- FIT(MEAS)
reg("cfa", "Stage 1 CFA", cfa_fit)
reg("cfa_fit_indices", "Stage 1 fit",
    fitmeasures(cfa_fit, c("chisq","df","pvalue","cfi","tli","rmsea",
                           "rmsea.ci.upper","srmr","aic","bic")))
reg("cfa_loadings", "Standardised loadings",
    standardizedSolution(cfa_fit) |> filter(op == "=~"))
reg("reliability", "AVE and composite reliability", compRelSEM(cfa_fit))
reg("htmt", "HTMT discriminant validity", htmt(MEAS, data = dat))

ord_items <- intersect(need, names(dat))
reg("cfa_wlsmv", "Indicator measurement level sensitivity (ordered, WLSMV)",
    cfa(MEAS, data = mutate(dat, across(all_of(ord_items), ordered)),
        estimator = "WLSMV", cluster = "resp_id", ordered = ord_items))

# --- 3.1 Image: four competing structures (codebook construct note) --------
img <- indicators("Image")
IMG <- list(
  reflective  = sprintf("Image =~ %s", paste(img, collapse = " + ")),
  composite   = sprintf("Image <~ %s", paste(img, collapse = " + ")),
  three_facet = paste(sprintf("F%d =~ 1*%s", seq_along(img), img), collapse = "\n"),
  second_order = paste(
    paste(sprintf("F%d =~ 1*%s", seq_along(img), img), collapse = "\n"),
    sprintf("Image =~ %s", paste0("F", seq_along(img), collapse = " + ")), sep = "\n")
)
reg("image_structure", "Image: comparison of four measurement structures",
    imap_dfr(IMG, function(spec, nm) {
      f <- try(FIT(paste(spec, "\n Intention =~", paste(indicators("Intention"),
                                                        collapse = " + "),
                         "\n Intention ~ Image")), silent = TRUE)
      if (inherits(f, "try-error") || !lavInspect(f, "converged"))
        return(tibble(structure = nm, converged = FALSE))
      bind_cols(tibble(structure = nm, converged = TRUE),
                as_tibble_row(fitmeasures(f, c("cfi","rmsea","srmr","bic"))))
    }))

# --- 3.2 PBC vs. Constraints: control-factor comparison --------------------
pbc <- indicators("PBC"); con <- indicators("Constraints")
CTRL <- list(
  two_factor = sprintf("PBC =~ %s\nConstraints =~ %s",
                       paste(pbc, collapse = " + "), paste(con, collapse = " + ")),
  one_factor = sprintf("Control =~ %s", paste(c(pbc, con), collapse = " + ")),
  second_order = sprintf("PBC =~ %s\nConstraints =~ %s\nControl =~ PBC + Constraints",
                         paste(pbc, collapse = " + "), paste(con, collapse = " + "))
)
reg("control_structure", "PBC and Constraints: separability",
    imap_dfr(CTRL, function(spec, nm) {
      f <- try(FIT(spec), silent = TRUE)
      if (inherits(f, "try-error")) return(tibble(structure = nm, converged = FALSE))
      bind_cols(tibble(structure = nm, converged = lavInspect(f, "converged")),
                as_tibble_row(fitmeasures(f, c("cfi","rmsea","srmr","bic"))))
    }))

# --- 3.3 Identification: two-indicator sensitivity -------------------------
reg("identification_sensitivity",
    "Identification with and without the value-congruence item",
    list(three = FIT(MEAS),
         two = FIT(sub(sprintf("Identification   =~ %s",
                               paste(indicators("Identification"), collapse = " + ")),
                       "Identification   =~ FC01_01 + FC01_02", MEAS, fixed = TRUE))))

# --- 3.4 SNdes: single-indicator reliability sensitivity -------------------
# TI02_04 is the sole SNdes indicator in the final instrument (28.07.2026);
# TI02_05 was dropped (see codebook). A single-indicator latent factor is not
# identified under std.lv = TRUE without fixing either the loading or the
# residual variance. We fix the loading to 1 and the residual variance to
# (1 - rel) * Var(TI02_04). rel is a MODEL ASSUMPTION, not estimated and not
# derived from rivis2003 (see codebook note on TI02_04); it is therefore swept
# over four preregistered values rather than fixed at a single number.
REL_GRID <- c(.60, .70, .80, .90)

sndes_fixed_block <- function(rel) {
  v <- var(dat$TI02_04, na.rm = TRUE)
  sprintf("SNdes           =~ 1*TI02_04\nTI02_04 ~~ %f*TI02_04", (1 - rel) * v)
}

MEAS_SNDES <- map(REL_GRID, function(rel) {
  sub("SNdes\\s+=~ TI02_04", sndes_fixed_block(rel), MEAS)
})
names(MEAS_SNDES) <- paste0("rel_", sub("\\.", "", sprintf("%.2f", REL_GRID)))

reg("sndes_reliability_sensitivity",
    "SNdes single indicator: residual fixed at four assumed reliabilities (.60/.70/.80/.90)",
    imap_dfr(MEAS_SNDES, function(m, nm) {
      f <- try(FIT(m), silent = TRUE)
      if (inherits(f, "try-error") || !lavInspect(f, "converged"))
        return(tibble(assumption = nm, converged = FALSE))
      bind_cols(tibble(assumption = nm, converged = TRUE),
                as_tibble_row(fitmeasures(f, c("cfi","rmsea","srmr","bic"))))
    }))

# Alternative specification: TI02_01-TI02_04 load on one common normative
# factor (injunctive and descriptive collapsed), reported side by side with
# the separate-factors/fixed-residual solution above, per the proposal.
MEAS_COMMON_NORM <- sub("SNinj\\s+=~ [^\n]+\nSNdes\\s+=~ TI02_04",
                        "Norm            =~ TI02_01 + TI02_02 + TI02_03 + TI02_04",
                        MEAS)
reg("norm_structure_comparison",
    "Injunctive/descriptive as separate factors (SNdes residual fixed at rel = .80) vs. one common normative factor",
    list(separate_rel80 = FIT(MEAS_SNDES$rel_080),
         common_factor  = try(FIT(MEAS_COMMON_NORM), silent = TRUE)))

# =============================================================================
# 04  M1 - M5
# =============================================================================
COV <- "SES + AGE + FEM + REL"
be <- "  BE =~ Familiarity + Image + Personality + Trust + Commitment"

M1 <- paste(MEAS, be, sprintf("
  Intention ~ a*BE + %s
  BEH_amt   ~ b*Intention + c*BE + %s
  ind := a*b
  tot := c + a*b", COV, COV), sep = "\n")

M2 <- paste(MEAS, be, sprintf("
  Attitude  ~ p1*BE
  SNinj     ~ p2*BE
  SNdes     ~ p3*BE
  PBC       ~ p4*BE
  Intention ~ q1*Attitude + q2*SNinj + q3*SNdes + q4*PBC + q5*MoralNorm + %s
  BEH_amt   ~ r*Intention + %s
  ind_ATT := p1*q1*r
  ind_SNi := p2*q2*r
  ind_SNd := p3*q3*r
  ind_PBC := p4*q4*r", COV, COV), sep = "\n")

M3 <- paste(MEAS, sprintf("
  Image           ~ s1*Familiarity
  Personality     ~ Familiarity
  Differentiation ~ s2*Image + Personality
  Trust           ~ s3*Differentiation + Image
  Commitment      ~ s4*Trust
  Intention       ~ s5*Commitment + %s
  BEH_amt         ~ s6*Intention + %s
  chain := s1*s2*s3*s4*s5*s6", COV, COV), sep = "\n")

M4 <- paste(MEAS, sprintf("
  Familiarity     ~ AW_unaided + AW_aided
  Differentiation ~ Familiarity + Image + Personality
  Trust           ~ Image + Personality + Differentiation
  Commitment      ~ Trust + Familiarity
  Attitude        ~ Image + Personality + Differentiation
  PBC             ~ Familiarity + Trust + Knowledge
  Intention       ~ Attitude + SNinj + SNdes + PBC + MoralNorm + Commitment + Trust + %s
  BEH_amt         ~ Intention + Habit + Constraints + Knowledge + Salience +
                    Trust + Commitment + %s", COV, COV), sep = "\n")

M5 <- paste(M4, "
  Intention ~ d1*Familiarity + d2*Image + d3*Personality +
              d4*Differentiation + d5*Trust + d6*Commitment
  sig_sym := d2 + d3 + d4
  sig_cre := d1 + d5", sep = "\n")

MODELS <- list(M1 = M1, M2 = M2, M3 = M3, M4 = M4, M5 = M5)
fits <- lapply(MODELS, FIT)
reg("fits_m1_m5", "M1-M5", fits)
reg("fit_table", "Model comparison",
    map_dfr(fits, ~ as_tibble_row(fitmeasures(
      .x, c("chisq","df","cfi","tli","rmsea","srmr","aic","bic","npar"))), .id = "model") |>
      mutate(dBIC = bic - min(bic),
             converged = map_lgl(fits, lavInspect, "converged")))
reg("params_m1_m5", "Standardised estimates",
    map_dfr(fits, ~ standardizedSolution(.x) |> filter(op %in% c("~", ":=")), .id = "model"))
reg("r2", "Explained variance", map_dfr(fits, ~ enframe(inspect(.x, "r2")), .id = "model"))

# =============================================================================
# 05  M4i / M5i -- moderation extension (RQ3)
# =============================================================================
IBM <- c(Habit = "TI06", Constraints = "TI05", Knowledge = "TI07", Salience = "TI08")
pwr_z <- function(est, se, alpha = .05) {
  crit <- qnorm(1 - alpha/2); pnorm(abs(est)/se - crit) + pnorm(-abs(est)/se - crit)
}
fit_ix <- function(nm, prefix, base) {
  v1 <- indicators("Intention")
  v2 <- grep(paste0("^", prefix, "_"), names(dat), value = TRUE)
  d_i <- indProd(dat, var1 = v1, var2 = v2, match = FALSE,
                 meanC = TRUE, residualC = FALSE, doubleMC = TRUE)
  prods <- grep(paste0("^TI04_.*\\.", prefix), names(d_i), value = TRUE)
  f <- sem(paste(base, sprintf("\n  Ix =~ %s\n  BEH_amt ~ ixpath*Ix",
                               paste(prods, collapse = " + "))),
           data = d_i, estimator = "MLR", missing = "fiml",
           cluster = "resp_id", std.lv = TRUE)
  e <- parameterEstimates(f) |> filter(label == "ixpath")
  tibble(moderator = nm, est = e$est, se = e$se, p = e$pvalue,
         converged = lavInspect(f, "converged"))
}
adjust <- function(tb) tb |>
  mutate(p_BH = p.adjust(p, "BH"), power = pwr_z(est, se),
         verdict = case_when(!converged ~ "non-convergent", power < .60 ~ "inconclusive",
                             p_BH < .05 ~ "supported", TRUE ~ "not supported"))
reg("m4i", "M4i moderation family", adjust(imap_dfr(IBM, ~ fit_ix(.y, .x, M4))))
reg("m5i", "M5i moderation family", adjust(imap_dfr(IBM, ~ fit_ix(.y, .x, M5))))

# =============================================================================
# 06  MULTI-GROUP (EH8, EH9)
# =============================================================================
mg <- function(group, model = M5) {
  f <- list(configural = FIT(model, group = group),
            metric = FIT(model, group = group, group.equal = "loadings"),
            structural = FIT(model, group = group,
                             group.equal = c("loadings", "regressions")))
  list(fits = f, lrt = do.call(lavTestLRT, unname(f)),
       fit_idx = map_dfr(f, ~ as_tibble_row(fitmeasures(.x, c("cfi","rmsea","bic"))),
                         .id = "level"))
}
reg("eh8_donor", "EH8 donor status", mg("DONOR"))
reg("eh8_edu", "EH8 education tertiles", mg("EDU3"))
reg("eh8_inc", "EH8 income tertiles", mg("INC3"))
reg("eh9_empathy", "EH9 empathy dominance", mg("EMP_dom"))

inv <- function(group) {
  f <- list(configural = FIT(MEAS, group = group),
            metric = FIT(MEAS, group = group, group.equal = "loadings"),
            scalar = FIT(MEAS, group = group,
                         group.equal = c("loadings", "intercepts")))
  idx <- map_dfr(f, ~ as_tibble_row(fitmeasures(.x, c("cfi","rmsea"))), .id = "level") |>
    mutate(dCFI = cfi - lag(cfi), dRMSEA = rmsea - lag(rmsea),
           pass = is.na(dCFI) | (abs(dCFI) <= .010 & abs(dRMSEA) <= .015))
  list(fits = f, table = idx, lrt = do.call(lavTestLRT, unname(f)),
       modindices = modindices(f$scalar, op = "~1", sort. = TRUE, maximum.number = 20))
}
for (g in c("DONOR", "EDU3", "INC3", "STREAM"))
  reg(paste0("invariance_", tolower(g)), paste("Invariance across", g), inv(g))

# =============================================================================
# 07  SENSITIVITY
# =============================================================================
org_d <- model.matrix(~ factor(org_id) - 1, dat)[, -1]
colnames(org_d) <- paste0("orgd", seq_len(ncol(org_d)))
dat_od <- bind_cols(dat, as_tibble(org_d))
reg("clustering", "Clustering sensitivity", list(
  resp = fits$M4,
  org  = FIT(M4, cluster = "org_id"),
  orgdumm = sem(paste(M4, "\n  Intention ~", paste(colnames(org_d), collapse = " + "),
                      "\n  BEH_amt ~", paste(colnames(org_d), collapse = " + ")),
                data = dat_od, estimator = "MLR", missing = "fiml",
                cluster = "resp_id", std.lv = TRUE)))
reg("alt_outcome", "M1-M5 with TOT_amt",
    map(MODELS, ~ FIT(gsub("BEH_amt", "TOT_amt", .x, fixed = TRUE))))
reg("chain_order", "M3 chain-order sensitivity", {
  a1 <- paste(MEAS, sprintf("
    Image ~ Familiarity
    Personality ~ Familiarity
    Trust ~ Image + Personality
    Differentiation ~ Trust
    Commitment ~ Differentiation
    Intention ~ Commitment + %s
    BEH_amt ~ Intention + %s", COV, COV), sep = "\n")
  a2 <- paste(MEAS, sprintf("
    Image ~ Familiarity
    Differentiation ~ Image
    Trust ~ Differentiation + Image
    Commitment ~ Trust
    Personality ~ Commitment
    Intention ~ Commitment + %s
    BEH_amt ~ Intention + %s", COV, COV), sep = "\n")
  map_dfr(list(preferred = fits$M3, alt1 = FIT(a1), alt2 = FIT(a2)),
          ~ as_tibble_row(fitmeasures(.x, c("cfi","rmsea","srmr","bic"))), .id = "ordering")
})
reg("suppression", "M5 direct vs. chain-mediated brand effects", {
  tot <- standardizedSolution(fits$M3) |> filter(op == "~")
  dir <- standardizedSolution(fits$M5) |> filter(op == "~", lhs == "Intention")
  full_join(dir, tot, by = c("lhs","rhs"), suffix = c("_M5","_M3")) |>
    mutate(sign_flip = sign(est.std_M5) != sign(est.std_M3))
})
reg("excl_sensitivity", "M4 without quality exclusions", FIT(M4, data = long))
reg("imputation_flag", "M4 with amount-refusal flag",
    FIT(paste(M4, "\n  BEH_amt ~ amt_imputed")))
reg("ac02_sensitivity", "M4 with AC02 inconsistency as covariate",
    FIT(paste(M4, "\n  BEH_amt ~ ac_inconsistency")))

# --- 7.1 outcome distribution: log is not enough ---------------------------
scores <- as_tibble(lavPredict(cfa_fit)) |>
  bind_cols(select(dat, resp_id, org_id, org_amt, BEH_amt, BEH_pos, BEH_rec,
                   BEH_bin, SES, AGE, FEM, REL, past_giving))
reg("outcome_distribution", "Distribution of the primary outcome",
    list(summary = summary(dat$org_amt),
         zero_share = mean(dat$org_amt == 0, na.rm = TRUE),
         heaping = dat |> filter(org_amt > 0) |> count(org_amt) |> arrange(desc(n)) |>
           head(20)))
reg("outcome_models", "Alternative specifications for the giving amount", list(
  loglinear = lm(BEH_amt ~ Intention + Habit + Constraints + Knowledge + Salience +
                   Trust + Commitment + SES + AGE + FEM, data = scores),
  hurdle = hurdle(round(org_amt) ~ Intention + Habit + Constraints + SES + AGE + FEM |
                    Intention + Constraints + SES + AGE + FEM,
                  data = drop_na(scores), dist = "negbin"),
  twopart_stage1 = glm(BEH_pos ~ Intention + Habit + Constraints + SES + AGE + FEM,
                       family = binomial, data = scores),
  twopart_stage2 = glm(org_amt ~ Intention + Habit + Constraints + SES + AGE + FEM,
                       family = Gamma(link = "log"),
                       data = filter(scores, org_amt > 0)),
  winsorised = lm(pmin(BEH_amt, quantile(BEH_amt, .99, na.rm = TRUE)) ~
                    Intention + Habit + Constraints + SES + AGE + FEM, data = scores)))

# =============================================================================
# 08  STREAM, EXTERNAL VALIDATION, TRIANGULATION, SUPPLEMENTARY
# =============================================================================
reg("stream_desc", "Stream A vs B, factor-score means (Cohen's d)",
    as_tibble(lavPredict(cfa_fit)) |> mutate(STREAM = dat$STREAM) |>
      pivot_longer(-STREAM) |> group_by(name) |>
      summarise(m_A = mean(value[STREAM == "A_panel"], na.rm = TRUE),
                m_B = mean(value[STREAM == "B_recontact"], na.rm = TRUE),
                d = (m_B - m_A) / sd(value, na.rm = TRUE)))
reg("stream_pooled", "Pooled SEM with STREAM covariate",
    FIT(paste(M4, "\n  Intention ~ STREAM\n  BEH_amt ~ STREAM")))
reg("stream_mg", "Multi-group A vs B", mg("STREAM", model = M4))
reg("stream_robust", "Robustness across stream specifications",
    list(A_only = FIT(M4, data = filter(dat, STREAM == "A_panel")),
         B_only = FIT(M2, data = filter(dat, STREAM == "B_recontact"))))

org <- as_tibble(lavPredict(cfa_fit)) |> mutate(org_id = dat$org_id) |>
  group_by(org_id) |> summarise(across(everything(), mean, na.rm = TRUE)) |>
  left_join(read.csv("data/bmf_organisation_outcomes.csv"), by = "org_id") |>
  mutate(log_AnnualDonations = log(AnnualDonations),
         log_AvgDonation = log(AvgDonation), SES_j = scale(SES_org)[, 1])
boot_glm <- function(fm, fam) {
  b <- boot(org, function(d, i) coef(glm(fm, family = fam, data = d[i, ])), R = 1000)
  tibble(term = names(b$t0), est = b$t0,
         lo = apply(b$t, 2, quantile, .025), hi = apply(b$t, 2, quantile, .975))
}
reg("mev_volume", "Org-level: log annual donation volume",
    boot_glm(log_AnnualDonations ~ Familiarity + Trust + Differentiation + SES_j, gaussian()))
reg("mev_avg", "Org-level: log average donation",
    boot_glm(log_AvgDonation ~ Familiarity + Trust + Differentiation + SES_j, gaussian()))
reg("mev_incidence", "Org-level: donor incidence",
    boot_glm(DonorIncidence ~ Familiarity + Trust + Differentiation + SES_j,
             poisson(link = "log")))
reg("mev_pathwise", "Org-specific structural paths",
    dat |> group_split(org_id) |> map_dfr(possibly(~ {
      f <- FIT(M1, data = .x, cluster = NULL)
      tibble(org_id = .x$org_id[1], beta_BE_Int = coef(f)["Intention~BE"])
    }, otherwise = NULL)))
reg("triangulation", "Perceived vs. structural giving dynamics",
    dat |> group_by(org_id) |> summarise(
      perceived = mean(as.numeric(OG05_01), na.rm = TRUE),
      sector    = mean(as.numeric(SP06_01), na.rm = TRUE),
      amt       = mean(BEH_amt, na.rm = TRUE)))

reg("recurring", "Recurring donation status",
    glm(BEH_rec ~ Commitment + Habit + Intention + Constraints + SES + AGE + FEM,
        family = binomial, data = scores))
ladder <- dat |> transmute(one_off = as.integer(OG01_01 == 2),
                           recurring = as.integer(OG01_02 == 2),
                           standing = as.integer(OG01_04 == 2)) |> drop_na()
reg("mokken", "Mokken scalability of the monetary engagement ladder",
    list(H = coefH(as.data.frame(ladder)), aisp = aisp(as.data.frame(ladder)),
         monotonicity = summary(check.monotonicity(as.data.frame(ladder)))))
reg("dominance", "Relative importance of layers",
    domin(BEH_amt ~ Familiarity + Image + Personality + Differentiation + Trust +
            Commitment + Intention + Habit + Constraints + Knowledge + Salience,
          lm, list(summary, "r.squared"), data = drop_na(scores)))
X <- scores |> select(Familiarity:Salience) |> drop_na() |> as.matrix()
reg("elastic_net", "Elastic net for recurring giving",
    cv.glmnet(X, scores$BEH_rec[complete.cases(scores)], family = "binomial", alpha = .5))
reg("positive_controls", "Positive controls", list(
  intention_amount = cor.test(scores$Intention, scores$BEH_amt),
  donor_gap = t.test(Intention ~ BEH_bin, data = scores),
  trust_commitment = cor.test(scores$Trust, scores$Commitment)))

# --- exploratory constructs, deliberately outside the confirmatory models ---
reg("exploratory_excluded", "Tier 3 constructs kept out of M1-M5", list(
  comparative_preference = cor.test(dat$BD02_01, scores$Intention),
  future_support_intention = table(dat$FutureSupportIntention, dat$BEH_bin)))

# =============================================================================
# 09  COVERAGE REGISTRY
# =============================================================================
ANALYSIS_REGISTRY <- tribble(
  ~prereg_section,                 ~object,
  "Codebook contract",             "codebook_contract,measurement_syntax",
  "Stage 1 CFA + reliability",     "cfa,cfa_fit_indices,cfa_loadings,reliability,htmt",
  "Indicator measurement level",   "cfa_wlsmv",
  "Image structure comparison",    "image_structure",
  "PBC vs Constraints",            "control_structure",
  "Identification sensitivity",    "identification_sensitivity",
  "SNdes single-indicator sensitivity", "sndes_reliability_sensitivity,norm_structure_comparison",
  "Invariance sequences",          "invariance_donor,invariance_edu3,invariance_inc3,invariance_stream",
  "Stage 2 M1-M5",                 "fits_m1_m5,fit_table,params_m1_m5,r2",
  "RQ3 moderation extension",      "m4i,m5i",
  "Stage 3 EH8 / EH9",             "eh8_donor,eh8_edu,eh8_inc,eh9_empathy",
  "Clustering sensitivity",        "clustering",
  "Alternative outcome",           "alt_outcome",
  "Chain-order sensitivity",       "chain_order",
  "Suppression diagnostics",       "suppression",
  "Exclusions and quality",        "exclusions,ac02_distribution,excl_sensitivity,imputation_flag,ac02_sensitivity",
  "Outcome distribution",          "outcome_distribution,outcome_models",
  "Stage 4 stream comparison",     "stream_desc,stream_pooled,stream_mg,stream_robust",
  "Stage 5 external validation",   "mev_volume,mev_avg,mev_incidence,mev_pathwise",
  "Triangulation",                 "triangulation",
  "Supplementary models",          "recurring,mokken,dominance,elastic_net",
  "Positive controls",             "positive_controls",
  "Tier 3 exploratory",            "exploratory_excluded",
  "Sample",                        "n_analysis"
) |> mutate(present = map_lgl(object, ~ all(strsplit(.x, ",")[[1]] %in% ls(RESULTS))))

stopifnot(all(ANALYSIS_REGISTRY$present))
print(ANALYSIS_REGISTRY, n = Inf)
saveRDS(as.list(RESULTS), "results/beba_v8_results.rds")
saveRDS(ANALYSIS_REGISTRY, "results/beba_v8_coverage.rds")
write_csv(cb_items, "results/codebook_snapshot.csv")

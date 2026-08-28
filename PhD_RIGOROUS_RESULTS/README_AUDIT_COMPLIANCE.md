# AUDIT COMPLIANCE README
## Critical Requirements Before Any Analysis

**Audit Document:** R-Pipeline_Dissertationsaudit_2026-08-26.md  
**Status:** ⚠️ **BLOCKING ITEMS** identified  
**Date:** 2026-08-26

---

## BLOCKING ITEMS (Must Resolve Before Analysis)

### BLOCKER #1: Person-ID Reconstruction
**Audit Finding:** Current `person_id = row_number()` is NOT a true person identifier.

**What's Missing:**
- [ ] True person_id from survey module linkage (CASE, REF, module sequence)
- [ ] Module-to-person mapping (Start01 → qnr1/qnr2 → qnr4/qnr5 branching)
- [ ] Verification that each row maps to ONE unique person-module-org evaluation

**Current State:**
- RDS file: `pipeline_data_fc_bo_with_ordinal_awareness.rds` exists
- Crosswalk: NOT YET extracted
- Verification: NOT YET performed

**Action Required:**
```r
# Step 1: Load RDS and inspect raw structure
data_raw <- readRDS("pipeline_data_fc_bo_with_ordinal_awareness.rds")

# Step 2: Identify which columns encode:
#   - Person (e.g., CASE, respondent_id, respondent_uuid)
#   - Module (e.g., module_name, survey_block)
#   - Organization (e.g., org_name, org_id)
#   - Evaluation (unique rating instance)

# Step 3: Create explicit crosswalk:
#   person_id | module_id | org_id | evaluation_id | [other fields]

# Step 4: Verify:
#   - Each row is unique (person × org × evaluation)
#   - No person appears twice for same org (unless intentional)
#   - Module sequence is logical

# Step 5: Document in PERSON_MODULE_ORG_CROSSWALK.csv
#   This is MANDATORY for the dissertation appendix
```

**Blocker Status:** 🔴 **NOT RESOLVED** — Cannot proceed without this.

---

### BLOCKER #2: Missing Code Recode Log
**Audit Finding:** Missing codes (-9, -1, etc. per codebook) must be explicitly recoded to NA.

**What's Missing:**
- [ ] Codebook consulted and all missing codes identified
- [ ] Explicit recode rules written out
- [ ] Recode applied and logged
- [ ] Validation checks performed

**Current State:**
- Codebook exists: [PATH TBD]
- Recode rules: NOT DOCUMENTED
- Applied to data: UNKNOWN (RDS may or may not have done this)

**Action Required:**
```r
# Step 1: Load codebook and extract missing code definitions
# Example output:
#   Variable: B101_01
#   Missing codes: -9 (not answered), -1 (skipped)
#   Value range: 1-7 (likert), 8 (no opinion)

# Step 2: Check RDS data for these codes
table(data_raw$B101_01)  # Do we see -9, -1, 8, etc?

# Step 3: Apply recodes
#   -9, -1, 8 → NA for Likert items
#   Document in RECODE_LOG.csv

# Step 4: Validate
#   sum(is.na(B101_01)) after recode
#   Compare to raw counts

# Step 5: Freeze recoded data as:
#   data_clean <- [recoded version]
#   saveRDS(data_clean, "data_clean/data_cleaned_2026-08-26.rds")
```

**Blocker Status:** 🔴 **NOT RESOLVED** — Cannot trust outcome until this is done.

---

### BLOCKER #3: Outcome Validation & Transformation
**Audit Finding:** OF02_02 (past-year donation amount) has not been fully cleaned or validated.

**What's Missing:**
- [ ] Outcome variable explicitly extracted from RDS
- [ ] Data types confirmed (numeric, no text strings)
- [ ] Currency standardization (€, euro, EUR, etc.)
- [ ] Outlier review (>99th percentile flagged for domain review)
- [ ] Validation: min, max, median, missing counts
- [ ] Decision: how to handle >99th percentile (keep, remove, Winsorize)

**Current State:**
- OF02_02 in RDS: [EXISTS / UNKNOWN]
- Format: [NUMERIC / TEXT / MIXED]
- Outliers reviewed: NO
- Log transformation: NOT YET APPLIED

**Action Required:**
```r
# Step 1: Extract and inspect
outcome_raw <- data_clean$OF02_02_num
str(outcome_raw)
summary(outcome_raw)

# Step 2: Check for text strings, special characters
typeof(outcome_raw)  # Should be numeric
unique(outcome_raw[is.na(outcome_raw)])  # Any patterns?

# Step 3: Univariate validation
cat("Mean:", mean(outcome_raw, na.rm=T), "\n")
cat("Median:", median(outcome_raw, na.rm=T), "\n")
cat("Min/Max:", min(outcome_raw, na.rm=T), "/", max(outcome_raw, na.rm=T), "\n")
cat("% missing:", 100*sum(is.na(outcome_raw))/length(outcome_raw), "%\n")

# Step 4: Outlier review
q99 <- quantile(outcome_raw, 0.99, na.rm=T)
outliers <- outcome_raw > q99
# Review these with domain knowledge—keep or remove?

# Step 5: Create binary outcome
donated_binary <- ifelse(outcome_raw > 0, 1, 0)
table(donated_binary, useNA="always")

# Step 6: Document
write_csv(
  tibble(
    variable = "OF02_02 (past-year donation)",
    n_obs = length(outcome_raw),
    n_missing = sum(is.na(outcome_raw)),
    n_zero = sum(outcome_raw == 0, na.rm=T),
    n_positive = sum(outcome_raw > 0, na.rm=T),
    mean_positive = mean(outcome_raw[outcome_raw > 0], na.rm=T),
    median_positive = median(outcome_raw[outcome_raw > 0], na.rm=T),
    p99 = q99,
    n_outliers_gt_p99 = sum(outliers, na.rm=T),
    outlier_review_status = "REQUIRES DOMAIN REVIEW"
  ),
  "OUTCOME_VALIDATION.csv"
)
```

**Blocker Status:** 🔴 **NOT RESOLVED** — This determines sample size, outcome models, everything downstream.

---

### BLOCKER #4: Sample Size Determination
**Audit Finding:** Audit identified discrepancies: 2.038 claimed vs. actual ~1.337 evaluations.

**What's Missing:**
- [ ] Flowchart: invited → started → linked → complete → final N (separate per model)
- [ ] N persons (true unique respondents)
- [ ] N evaluations (person × org pairs)
- [ ] N organizations
- [ ] N organizations with N ≥ 30 (sufficient for org-level inference)

**Current State:**
- Claimed: 2.038 individuals, 26 organizations
- Actual: [UNKNOWN — must reconstruct from crosswalk]

**Action Required:**
```r
# Step 1: Determine analysis unit
n_persons <- n_distinct(data_analysis$person_id)
n_evaluations <- nrow(data_analysis)
n_orgs <- n_distinct(data_analysis$org_id)

# Step 2: Check org imbalance (AUDIT CRITICAL)
org_sizes <- data_analysis %>%
  group_by(org_id) %>%
  summarise(n_evals = n(), .groups="drop") %>%
  arrange(n_evals)

cat("Organization sizes:\n")
print(org_sizes)
cat("\nOrgs with N >= 30:", sum(org_sizes$n_evals >= 30), "\n")
cat("Orgs with N < 30:", sum(org_sizes$n_evals < 30), "\n")
cat("Orgs with N < 15:", sum(org_sizes$n_evals < 15), "\n")

# Step 3: Document per-model sample sizes
# (Models may use different data subsets due to missing data)

write_csv(
  tibble(
    model = c("CFA", "Binary Outcome GLMM", "Amount Outcome GLMM"),
    n_persons = c("[CFA: n_persons]", "[GLM1: n_persons]", "[GLM2: n_persons]"),
    n_evaluations = c("[CFA: n_evals]", "[GLM1: n_evals]", "[GLM2: n_evals]"),
    n_orgs = c("[CFA: n_orgs]", "[GLM1: n_orgs]", "[GLM2: n_orgs]"),
    inclusion_criteria = "[document]",
    missing_data_strategy = "[document]"
  ),
  "SAMPLE_SIZE_BY_MODEL.csv"
)
```

**Blocker Status:** 🔴 **NOT RESOLVED** — Dissertation cannot claim "N=2,038" without explaining real structure.

---

### BLOCKER #5: RDS Provenance & Data Hash
**Audit Finding:** No way to verify data integrity or reproduce exactly which version was analyzed.

**What's Missing:**
- [ ] Raw CSV path and SHA-256 hash documented
- [ ] RDS creation script (raw CSV → RDS) in version control
- [ ] RDS file hash documented
- [ ] Complete data lineage: raw → cleaned → analysis datasets

**Current State:**
- RDS exists: Yes (pipeline_data_fc_bo_with_ordinal_awareness.rds)
- Creation script in repo: [UNKNOWN]
- Hash: [NOT DOCUMENTED]
- Reproducibility: **BLOCKED** (cannot rebuild without raw CSV)

**Action Required:**
```bash
# Step 1: Find raw CSV
find . -name "*.csv" | grep -i "rdata\|raw\|survey" | head -20

# Step 2: Document file hashes
sha256sum pipeline_data_fc_bo_with_ordinal_awareness.rds
sha256sum [raw-csv-file]

# Step 3: Ensure RDS creation script is in repo
# Should show: raw CSV → recodes → RDS
# File: data_preparation.R or similar

# Step 4: Add to Git with .gitattributes if > 100 MB
# Or document external storage location
```

**Blocker Status:** 🟡 **PARTIAL** — RDS exists, but creation script may be missing.

---

## CONTINGENT ITEMS (Blocked Until Blockers #1–4 Resolved)

### CONTINGENT A: CFA Fit & Reporting
**Depends on:** Blockers #1, #2, #3 (data must be clean and persons identified)

- [ ] Load analysis dataset
- [ ] Fit Boenigk CFA with ordinal items (WLSMV)
- [ ] Export full output: loadings, residuals, fit indices
- [ ] Report: CFI, TLI, RMSEA with CI, SRMR
- [ ] AVE and CR for both factors

**Action Blocked Until:** Clean data with true person_id and valid outcomes

---

### CONTINGENT B: Outcome Model Fitting
**Depends on:** Contingent A (measurement model confirmed)

- [ ] Fit binary outcome GLMM (logit)
- [ ] Fit amount outcome GLMM (Gamma log, subset to donors)
- [ ] Export: coefficients, SE, CI, p-values, diagnostics
- [ ] Check: convergence, Hessian, random intercepts

**Action Blocked Until:** CFA fit acceptable and outcomes validated

---

### CONTINGENT C: Sensitivity Checks
**Depends on:** Contingent B (outcome models fitted)

- [ ] Complete-case vs. imputation (if applicable)
- [ ] Random intercept vs. slope models
- [ ] Latent vs. manifest predictors
- [ ] Outlier inclusion/exclusion

**Action Blocked Until:** Primary outcome models converge

---

## WHAT NOT TO DO

❌ **Do NOT:**
- Assume person_id = row_number() is correct
- Skip missing-code recode
- Treat OF02_Freq (quotient) as outcome
- Report N=2,038 without explaining structure
- Run CFA before data is clean
- Make any claims without seeing data first

❌ **Do NOT create:**
- Fictional sample sizes or org imbalances
- Estimated effect sizes
- Hypothetical missing-data patterns
- Guessed fit indices

---

## TIMELINE & RESPONSIBILITY

| Task | Responsibility | Status | Due Date |
|------|-----------------|--------|----------|
| Load RDS & inspect | Data specialist | 🔴 | ASAP |
| Reconstruct person_id | Data specialist | 🔴 | ASAP |
| Missing code recode | Data specialist + analyst | 🔴 | [+2 days] |
| Outcome validation | Analyst | 🔴 | [+3 days] |
| Sample size determination | Analyst | 🔴 | [+4 days] |
| CFA fit | Analyst | 🟡 | [+5 days] |
| Outcome models | Analyst | 🟡 | [+7 days] |
| Final report | Analyst | 🟡 | [+10 days] |

---

## DISCIPLINE RULES

**Every finding must answer:**
1. How many observations is this based on? (Report exact N)
2. Are there missing values? (Exact count and %)
3. What was excluded and why? (Complete flowchart)
4. Can someone else rebuild this exactly? (All code in repo, data hash documented)

**If you cannot answer all four:** Do not report the finding.

---

## NEXT STEPS

1. **Immediately:** Load RDS and run BLOCKER #1 diagnostic
2. **Document:** Write PERSON_MODULE_ORG_CROSSWALK.csv
3. **Clean:** Apply all missing-code recodes with log
4. **Validate:** Run outcome univariate checks
5. **Report:** Create SAMPLE_SIZE_BY_MODEL.csv

**ONLY THEN:** Proceed to CFA and outcome models.

---

*This README exists to prevent hallucination, assumption, and fiction.*  
*Every number reported must be traced back to data inspection, never estimation.*

# Next Steps - Execution Checklist

**Current Date:** 2026-08-22  
**Status:** Ready to proceed with Phase D & F

---

## 🎯 IMMEDIATE ACTIONS (This Week)

### ✅ Phase D: Multi-Group SEM (Measurement Invariance)

**What:** Test whether Chatzipanagiotou 4-stage model measurements are equivalent across 3 awareness groups

**Status:** ✅ Script ready

**Execute:**
```bash
# Run the script
Rscript /home/gerald/R-pipeline/v2_pipeline/D_MULTIGROUP_SEM/01_mgsem_by_awareness_REVISED.R

# Expected output: 
# - mgsem_results_by_awareness.rds
# - D_MGSEM_FIT_COMPARISON.csv
# - D_MGSEM_PATHS_BY_GROUP.csv

# Expected runtime: 30-60 minutes
```

**Script location:** `/home/gerald/R-pipeline/v2_pipeline/D_MULTIGROUP_SEM/01_mgsem_by_awareness_REVISED.R`

**Input:** `chatzi_bo_org_proof_BASELINE_VALIDATED_CLUSTERING.rds`

**Output files to expect:**
- Fit indices (CFI, RMSEA for each group)
- Δ CFI for invariance levels (should all be < 0.01 for good match)
- By-group structural path coefficients
- P-values for group differences

**Key results to check:**
- [ ] Configural invariance: unconstrained model fits data
- [ ] Metric invariance: equal factor loadings across groups (ΔCFI < 0.01)
- [ ] Scalar invariance: equal intercepts across groups (ΔCFI < 0.01)
- [ ] By-group effects: Do structural paths differ meaningfully?

---

### ▶️ Phase F: Bayesian MCMC Estimation (Run in Background)

**What:** Validate frequentist findings with Bayesian posterior distributions

**Status:** ✅ Script ready

**Execute:**
```bash
# Run in background (will take 2-4 hours)
nohup Rscript /home/gerald/R-pipeline/v2_pipeline/F_BAYES_PRODUCTION/02_blavaan_hierarchical_all.R > blavaan.log 2>&1 &

# OR run directly if you have time:
Rscript /home/gerald/R-pipeline/v2_pipeline/F_BAYES_PRODUCTION/02_blavaan_hierarchical_all.R

# Monitor progress:
tail -f blavaan.log

# Expected runtime: 2-4 hours
```

**Script location:** `/home/gerald/R-pipeline/v2_pipeline/F_BAYES_PRODUCTION/02_blavaan_hierarchical_all.R`

**Input:** `chatzi_bo_org_proof_BASELINE_VALIDATED_CLUSTERING.rds`

**Output files to expect:**
- `blavaan_full_fit.rds` (Bayesian model object)
- `F_BLAVAAN_SUMMARY.csv` (posterior summaries)
- `F_BLAVAAN_DIAGNOSTICS.csv` (Rhat, ESS, divergences)

**Key diagnostics to check:**
- [ ] All Rhat < 1.01 (convergence)
- [ ] All ESS > 400 (sufficient effective samples)
- [ ] Divergences = 0 (no estimation issues)
- [ ] Posterior credible intervals reasonable width

---

## 📋 After Phase F Completes (Usually next day)

### Phase E: Model Comparisons

**What:** Create comprehensive table comparing all model versions

**Status:** Script framework needed

**Action:** Run after both D and F are complete

```bash
# Once Phase D and F outputs exist, run:
Rscript /home/gerald/R-pipeline/v2_pipeline/E_COMPARISON/01_aggregate_all_fits.R

# Expected outputs:
# - E_ALL_MODELS_FIT_COMPARISON.csv
# - E_EFFECT_SIZES_COMPARISON.csv
# - E_FREQUENTIST_VS_BAYESIAN.csv
```

**Comparison table will show:**
- All baseline models (FC, BO, FC-HIGHER, etc.)
- Chatzipanagiotou 4-stage (primary)
- MGSEM results (by-group)
- Blavaan results (posterior vs frequentist)

---

### Phase H: Quality Gates Validation

**What:** Verify all models meet quality standards

**Status:** Framework ready

```bash
# Once all results exist, run:
Rscript /home/gerald/R-pipeline/v2_pipeline/H_TESTS/01_QUALITY_GATES.R

# Expected output:
# - H_QUALITY_REPORT.md (PASS/FAIL for each check)
# - H_DIAGNOSTIC_PLOTS.pdf (visualization of issues if any)
```

**Checks performed:**
- Convergence: All models converged? Any error codes?
- Standard errors: Reasonable range (not near 0, not huge)?
- Fit indices: In expected range (CFI > 0.90, RMSEA < 0.10)?
- Bayesian diagnostics: Rhat, ESS, divergences OK?
- Multi-group: Invariance tests pass?

---

## 🏁 Final Phase: Z (Last)

### Phase Z: Final Reporting & Sensitivity Analysis

**What:** Create publication-ready tables and test robustness

```bash
# Run after all other phases complete:
Rscript /home/gerald/R-pipeline/v2_pipeline/Z_REPORTING/01_final_report.R

# Expected outputs:
# - Z_PUBLICATION_TABLE_FIT_INDICES.xlsx
# - Z_PUBLICATION_TABLE_PARAMETERS.xlsx
# - Z_SENSITIVITY_ANALYSIS_ORG26.csv
# - Z_FINAL_REPORT.md
```

**Includes:**
- [ ] Publication-ready fit table (all models)
- [ ] Standardized path coefficients (all models)
- [ ] Effect sizes (small/medium/large)
- [ ] Sensitivity analysis: With/without Org 26
- [ ] Supplementary: Model diagrams, fit comparisons

---

## 📊 Model/Output Dependency Chain

```
Phase C (Complete)
├── chatzi_bo_org_proof_BASELINE_VALIDATED_CLUSTERING.rds
├── sem_fc_EXACT_LITERATURE_5factor_lavaan.rds
└── sem_bo_EXACT_LITERATURE_with2ndorder_lavaan.rds

    ↓↓↓ INPUT FOR NEXT PHASES ↓↓↓

Phase D: MGSEM
├── Input: chatzi_bo_org_proof_BASELINE_VALIDATED_CLUSTERING.rds
├── Output: D_MGSEM_FIT_COMPARISON.csv
└── Output: D_MGSEM_PATHS_BY_GROUP.csv

Phase F: Blavaan (parallel)
├── Input: chatzi_bo_org_proof_BASELINE_VALIDATED_CLUSTERING.rds
├── Output: blavaan_full_fit.rds
├── Output: F_BLAVAAN_SUMMARY.csv
└── Output: F_BLAVAAN_DIAGNOSTICS.csv

    ↓↓↓ INPUT FOR FINAL PHASES ↓↓↓

Phase E: Comparisons
├── Input: D outputs + F outputs + Cache models
└── Output: E_ALL_MODELS_FIT_COMPARISON.csv

Phase H: Quality Gates
├── Input: All D, E, F outputs
└── Output: H_QUALITY_REPORT.md

Phase Z: Final Report
├── Input: All previous outputs + sensitivity checks
└── Output: Publication tables + final report
```

---

## ⏱️ Timeline & Parallelization

**Optimal execution:**

**Day 1 (Today):**
- ⏰ 9:00 - Start Phase D (30-60 min)
- ⏰ 10:00 - Phase D should be done
- ⏰ 10:05 - Start Phase F in background (`nohup ... &`)
- ⏰ Continue work on other tasks while F runs

**Day 2 (Tomorrow):**
- ⏰ Check Phase F log (`tail blavaan.log`)
- ⏰ Once F is complete: Run Phase E (30 min)
- ⏰ Run Phase H (30 min)
- ⏰ Review all quality reports

**Day 3:**
- ⏰ Run Phase Z sensitivity analysis (1-2 hours)
- ⏰ Create publication tables
- ⏰ Final review

---

## 🔍 Sanity Checks Before Running

Before you start Phase D and F, verify:

```bash
# Check Phase C output exists and is valid
ls -lh /home/gerald/R-pipeline/v2_pipeline/C_STRUCTURAL_MODELS/outputs/chatzi_bo_org_proof_BASELINE_VALIDATED_CLUSTERING.rds

# Check script files exist
ls -lh /home/gerald/R-pipeline/v2_pipeline/D_MULTIGROUP_SEM/01_mgsem_by_awareness_REVISED.R
ls -lh /home/gerald/R-pipeline/v2_pipeline/F_BAYES_PRODUCTION/02_blavaan_hierarchical_all.R

# Check data file exists
ls -lh /home/gerald/R-pipeline/pipeline_data_fc_bo_with_ordinal_awareness.rds
```

---

## 📝 Notes & Caveats

### Phase D (MGSEM)
- **Group sizes:** Check if each awareness group has N > 100 (for stable estimation)
- **Expected results:** Measurement should be invariant across groups (ΔCFI < 0.01)
- **If problems:** Check for missing data patterns by group

### Phase F (Blavaan)
- **Long runtime:** Can take 2-4 hours. Run in background overnight if needed
- **Convergence:** If issues occur, may need more iterations (increase warmup/iter)
- **Priors:** Check if informed priors from Phase C are appropriate

### Phase E (Comparisons)
- **Only run after both D and F complete**
- **Table format:** Will aggregate 50+ models - may be large Excel file

### Phase Z (Sensitivity)
- **Org 26:** Dropping 29.8% of sample - results should be robust
- **Important check:** Are conclusions the same with/without Org 26?

---

## 🚨 Troubleshooting

**If Phase D fails:**
- Check RC_Awareness variable distribution
- Verify group sample sizes (N by awareness level)
- Check for perfect multicollinearity

**If Phase F fails/converges slowly:**
- May need to increase iterations (change `nchain` or `control` args)
- Check data for outliers
- Run with fewer parameters first, then add back

**If quality gates fail:**
- Review error messages carefully
- May indicate problematic model specification
- Consider simplifying model or reviewing data quality

---

## ✅ Sign-off Checklist

Before considering pipeline complete:

- [ ] Phase D: MGSEM script ran successfully
- [ ] Phase D: All 3 invariance levels tested
- [ ] Phase D: Δ CFI values documented
- [ ] Phase F: Blavaan fit completed
- [ ] Phase F: All Rhat < 1.01
- [ ] Phase F: All ESS > 400
- [ ] Phase F: Divergences = 0
- [ ] Phase E: Comparison table created
- [ ] Phase H: All quality gates pass
- [ ] Phase Z: Sensitivity analysis complete
- [ ] Phase Z: Publication tables created

---

## 📧 Questions/Blockers

If any issues arise:
1. Check the R script output first (error messages are usually descriptive)
2. Review the corresponding phase documentation
3. Check data with `str(data)` if estimation fails
4. See troubleshooting section above

---

**Ready to proceed? Start with Phase D! 🚀**


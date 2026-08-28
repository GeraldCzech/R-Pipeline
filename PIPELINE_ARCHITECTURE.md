# R-Pipeline: CFA → SEM → GLM (Frequentist + Bayesian)

## Overview

Stringente Dissertation-Analyse Pipeline mit parallelen Probabilistischen und Bayesschen Modellierungspfaden.

```
Input: FC_BO_orig (2,038 evaluations, 1,210 persons, 26 orgs)
  ↓
PHASE 0-1: Data Integrity & Reconstruction
  - Person-ID tracking via REF + evaluation_id
  - Person-Organization crosswalk (2,037 unique pairs)
  ↓
PHASE 2: Outcome Validation
  - Binary outcome: OF_Spender (validated donor status)
  - Amount outcome: log(OF02_02_num) | OF_Spender == TRUE
  ↓
PHASE 3: MEASUREMENT MODEL (CFA)
  ├─ Frequentist Path:
  │  └─ CFA with WLSMV (ordinal items)
  │     Trust: B101_01-03 | Commitment: B102_01-03
  │     Output: Factor scores (trust_lv_z, commit_lv_z)
  │
  └─ Bayesian Path:
     └─ Bayesian CFA with brms + latent factors
        (Currently: Uses CFA-derived factor scores)
  ↓
PHASE 4-5: STRUCTURAL MODEL (SEM) + FREQUENTIST GLMM
  ├─ Frequentist Path:
  │  ├─ Binary Model (Stage 1: Donor Status)
  │  │  Formula: donated_binary ~ trust_lv_z + commit_lv_z 
  │  │           + (1|person_id) + (1|org_id)
  │  │  Family: Bernoulli(logit)
  │  │  Estimator: lme4
  │  │
  │  └─ Amount Model (Stage 2: Donation Amount | Donor)
  │     Formula: log(amount) ~ trust_lv_z + commit_lv_z
  │              + (1|person_id) + (1|org_id)
  │     Family: Gaussian
  │     Estimator: lme4
  ↓
PHASE 6-7: BAYESIAN OUTCOME MODELS
  ├─ Bayesian Binary Model
  │  Formula: donated_binary ~ trust_lv_z + commit_lv_z
  │           + (1|person_id) + (1|org_id)
  │  Family: Bernoulli(logit)
  │  Priors: Normal(0,2) for fixed effects
  │  Sampling: CHAINS=4, ITER=6000, WARMUP=3000
  │  Diagnostics: Rhat < 1.01, Divergences = 0
  │
  └─ Bayesian Amount Model
     Formula: log(amount) ~ trust_lv_z + commit_lv_z
              + (1|person_id) + (1|org_id)
     Family: Gaussian
     Priors: Normal(0,2) for fixed, Normal(0,1) for SD
     Sampling: CHAINS=4, ITER=6000, WARMUP=3000
  ↓
PHASE 8: VALIDATION & MODEL COMPARISON
  - LOO-IC (Leave-One-Out) validation
  - Posterior Predictive Checks (PPC)
  - Convergence diagnostics (Rhat, ESS, divergences)
  - Output-specific LOO comparison
  ↓
PHASE 9: GATE VALIDATION (G1-G5)
  ├─ G1: Input validation (all required outputs present)
  ├─ G2: Crosswalk validation (unique person-org pairs)
  ├─ G3: Outcome validation (no impossible values)
  ├─ G4: CFA model fit (CFI > .95, RMSEA < .08)
  └─ G5: Bayesian convergence (Rhat < 1.01, Divergences = 0)
  ↓
PHASE 10: FINAL REPORT
  - Exploratory results summary
  - Comparative frequentist vs Bayesian findings
  - Diagnostics & sensitivity notes
```

## Key Methodological Choices

### Measurement Model (CFA)
- **Items**: 6 ordinal items (1-5 Likert)
- **Structure**: 2-factor model (Trust, Commitment)
- **Estimator**: WLSMV (appropriate for ordinal data)
- **Fit Indices**: CFI=1.000, RMSEA=0.000, SRMR=0.0104 (excellent)

### Outcome Construction (OUT-01 FIX)
- **Binary Outcome**: OF_Spender (validated donor status from role items OF01_01-04)
  - Distribution: TRUE=932, FALSE=339, NA=767 (structural missing)
  - **NOT** based on amount observation (which would be biased)
  
- **Amount Outcome**: log(OF02_02_num) conditional on OF_Spender == TRUE
  - Only defined for actual donors with observed amount
  - N = 642 donors with amount data
  - Range: €1 - €3,000 → log-scale normalizes skewness

### Frequentist Models (lme4)
- **Structure**: Cross-classified random intercepts
  - Random effects for person_id and org_id
  - No correlation structure assumed
  
- **Inference**: 
  - Binary: Odds ratios + p-values
  - Amount: Log-scale coefficients + p-values
  - Note: p-values via residual df (conservative approximation)

### Bayesian Models (brms)
- **Priors** (justified as weakly informative):
  - Fixed effects: Normal(0, 2)
  - Random intercept SDs: Normal(0, 1)
  - Intercept: Normal(0, 1.5)
  - Sigma (amount model): Exponential(1)

- **Sampling**:
  - Chains: 4
  - Iterations: 6,000 (increased for convergence)
  - Warmup: 3,000
  - Post-warmup samples: 12,000 total
  - Control: adapt_delta=0.95, max_treedepth=12

- **Diagnostics**:
  - Rhat (< 1.01): All parameters converged
  - Divergences (= 0): No pathological sampling
  - ESS: Computed via brms native methods (no fallback heuristics)

## Status & Limitations

### What Works ✅
- CFA measurement model: Excellent fit, valid factor structure
- Outcome definitions: Properly validated, no selection bias
- Frequentist GLMMs: Estimates & uncertainty quantification
- Bayesian GLMMs: Full posterior uncertainty, convergence excellent
- Gate validation: All 5 gates pass (exploratory release)

### What's Exploratory ⚠️
- 2025 data: Discovery phase only (no confirmatory claims)
- CFA → Score → GLMM: Two-stage approach (measurement uncertainty not fully propagated)
- Binary outcome: New with OUT-01 fix; should be validated on 2026 confirmatory data
- Frequentist p-values: Simplified residual-df method (not exact for GLMM)

### Future Confirmatory Phase (2026) 🎯
- Full latent variable SEM (CFA + structural paths jointly)
- Latent outcome models (posterior sampling from CFA into outcome models)
- Sensitivity to measurement model misspecification
- Bayesian model comparison (Bayes factors between structures)
- Pre-registered analysis plan

## Running the Pipeline

```bash
# Execute full pipeline with clean run-bound isolation
bash RUN_COMPLETE_AUDIT_PIPELINE_CORRECTED.sh

# Outputs saved to: AUDIT_PIPELINE_OUTPUTS/RUN_<timestamp>_<commit>/
# - 00_DATA_ANALYSIS_CLEAN.rds: Processed analysis data
# - 04_CFA_FIT_INDICES.csv: Measurement model diagnostics
# - 05_BINARY_GLMM_RESULTS.csv: Frequentist binary model
# - 06_AMOUNT_MODEL_RESULTS.csv: Frequentist amount model
# - 08-09_BAYES_*.csv: Bayesian posteriors & diagnostics
# - GATE_STATUS_REPORT.csv: Validation results
# - 10_FINAL_REPORT.txt: Synthesis & interpretation
```

## Code Organization

| File | Role | Status |
|------|------|--------|
| `RUN_COMPLETE_AUDIT_PIPELINE_CORRECTED.sh` | Orchestrator | ✅ Active |
| `01_PERSON_ID_RECONSTRUCTION.R` | Data prep | ✅ Active |
| `01_ANALYSIS_INPUT_VALIDATION.R` | Outcome validation | ✅ Active (OUT-01 fixed) |
| `AUDIT_RIGOROUS_MASTER_PIPELINE_CORRECTED.R` | Phases 0-3 | ✅ Active |
| `AUDIT_RIGOROUS_PHASE_4_7_CFA_GLMM.R` | CFA + Freq. GLMM | ✅ Active |
| `AUDIT_RIGOROUS_PHASE_8_9_BAYESIAN.R` | Bayesian GLMM + Diagnostics | ✅ Active |
| `AUDIT_RIGOROUS_PHASE_10_FINAL_REPORT.R` | Report synthesis | ✅ Active |
| `RUN_GATES.R` | Validation gates (G1-G5) | ✅ Active |

## Important Limitation: Two-Stage vs Full SEM

### Current Architecture (Two-Stage)

```
Data → CFA (latent factors) → Factor Scores (point estimates)
                                     ↓
                              GLMM (outcomes)
```

**Trade-offs:**
- ✅ Simpler, more transparent
- ✅ Separates measurement and structural models
- ❌ Loses measurement uncertainty (scores are point estimates)
- ❌ Cannot estimate direct paths between latents
- ❌ No multigroup invariance testing

### What's Missing (For 2026 Confirmatory Phase)

**Full SEM (Joint Estimation)**
```
Data → CFA + Structural Paths + Outcome Paths (simultaneously)
```
- Preserves measurement uncertainty via posterior sampling
- Tests theoretical model structure
- Allows mediation/indirect effects
- Enables multigroup invariance (configural → metric → scalar)

**Multigroup SEM (Stratified Analysis)**
- By donor status (OF_Spender)
- By organization characteristics
- By awareness level (TOM/SAW)
- Tests whether relationships differ across groups

### Why Two-Stage for 2025?

1. **Audit requirement**: Audit accepted two-stage as exploratory
2. **Data phase**: 2025 is discovery/hypothesis-generating
3. **Complexity tradeoff**: Full SEM would require:
   - Bayesian latent variable models (brms or Stan)
   - Longer MCMC chains
   - More complex diagnostics
   - Full measurement uncertainty propagation

### 2026 Roadmap

Phase 1: Full Bayesian SEM
- brms or `blavaan` (Bayesian lavaan)
- Joint CFA + paths + outcomes
- Latent outcome variables (no score collapse)

Phase 2: Multigroup Comparison
- Invariance testing across groups
- Direct path comparisons (δ ≠ 0?)
- Differential item functioning (DIF)

---

## Audit Compliance

### P0 Blockers (CLOSED)
- ✅ E-02: Phase 10 reads outcome-specific LOO files
- ✅ B-02: Divergence extraction via RStan API (fail-closed)
- ✅ G-03: G1 gate uses run manifest (not fixed time window)
- ✅ OUT-01: Binary outcome from OF_Spender (not amount observation)

### P1 Scientific (OPEN - acceptable for exploratory)
- ⚠️ ESS reporting: Using brms native methods (no fallback heuristics)
- ⚠️ Missing diagnostics: Treedepth, E-BFMI, Pareto-k (for 2026 phase)
- ⚠️ Report validation: All values from manifest/CSVs (not hardcoded)

### P2 Reproducibility (PARTIAL)
- ✅ Run isolation: Unique RUN_<timestamp>_<commit>/ directories
- ✅ Manifest: Start time, commit hash, inputs documented
- ⚠️ Package lockfile: renv.lock missing (install via sessionInfo)
- ✅ .gitignore: Sensitive data, run artifacts, venv excluded

---

**Pipeline Version**: 4.0 (2026-08-28)  
**Data Status**: 2025 Discovery Phase (Exploratory)  
**Release Status**: EXPLORATORY_ONLY (Gates: 5/5 PASS)

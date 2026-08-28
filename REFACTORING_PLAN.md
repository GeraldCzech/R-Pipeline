# Refactoring Plan - Schritt 2: Architektur & Registry

**Ziel:** Explizite Modell-Registry + strukturierter Dateibaum statt Dateinamen-Logik

---

## A. GEPLANTER DATEIBAUM (v2 Pipeline)

```
/home/gerald/R-pipeline/
├── 00_IST_ANALYSE.R                    (✓ Completed)
├── REFACTORING_PLAN.md                 (This file)
│
├── v2_pipeline/                        (NEW: v2 Implementation)
│   ├── 01_model_registry.yaml          (Master configuration)
│   ├── 02_outcome_mapping.csv          (Outcome ↔ Variable mapping)
│   │
│   ├── A_DATA_QC/
│   │   ├── A1_data_quality_checks.R
│   │   ├── outputs/
│   │   │   └── data_quality_report.csv
│   │   └── logs/
│   │
│   ├── B_MEASUREMENT_MODELS/
│   │   ├── B1_fit_cfa_models.R
│   │   ├── B2_extract_measurement_indices.R
│   │   ├── outputs/
│   │   │   ├── measurement_fit.csv
│   │   │   ├── measurement_loadings.csv
│   │   │   ├── reliability_ave_htmt.csv
│   │   │   └── latent_correlations_vif.csv
│   │   └── logs/
│   │
│   ├── C_STRUCTURAL_MODELS/
│   │   ├── C1_fit_structural_models.R
│   │   ├── C2_extract_structural_paths.R
│   │   ├── outputs/
│   │   │   ├── structural_paths.csv
│   │   │   ├── mlr_diagnostics.csv
│   │   │   └── outcome_r2_prediction.csv
│   │   └── logs/
│   │
│   ├── D_MEDIATION_MODELS/
│   │   ├── D1_fit_mediation.R
│   │   ├── outputs/
│   │   │   └── direct_indirect_total_effects.csv
│   │   └── logs/
│   │
│   ├── E_MODEL_COMPARISONS/
│   │   ├── E1_compare_models.R
│   │   ├── outputs/
│   │   │   ├── model_comparisons.csv
│   │   │   └── loo_pareto_diagnostics.csv
│   │   └── logs/
│   │
│   ├── F_BAYES_PRODUCTION/
│   │   ├── F1_fit_bayesian_models.R
│   │   ├── outputs/
│   │   │   └── bayes_diagnostics.csv
│   │   └── logs/
│   │
│   ├── G_QUALITY_GATES/
│   │   ├── G1_apply_quality_gates.R
│   │   ├── outputs/
│   │   │   └── interpretability_status.csv
│   │   └── logs/
│   │
│   ├── H_TESTS/
│   │   ├── test_model_registry.R
│   │   ├── test_outcome_mapping.R
│   │   ├── test_structural_validation.R
│   │   ├── test_quality_gates.R
│   │   └── logs/
│   │
│   ├── Z_REPORTING/
│   │   ├── Z1_generate_manifest.R
│   │   └── outputs/
│   │       ├── model_inventory.csv
│   │       ├── analysis_manifest.json
│   │       └── final_report.md
│   │
│   └── RUN_ALL.R                       (Main orchestration)
│
├── results/
│   ├── export/                         (✓ Raw fits)
│   ├── analysis/                       (✓ IST-Analysis)
│   └── v2_outputs/                     (NEW: v2 Results)
│       ├── data_quality/
│       ├── measurement/
│       ├── structural/
│       ├── mediation/
│       ├── comparisons/
│       ├── bayesian/
│       ├── quality_gates/
│       └── reports/
│
└── cache/                              (existing, unchanged)
```

---

## B. MODELL-REGISTRY (YAML Format)

**File:** `v2_pipeline/01_model_registry.yaml`

```yaml
# SEM Pipeline Model Registry
# Master configuration for all models
# Last updated: 2026-08-21

metadata:
  schema_version: "2.0"
  last_updated: "2026-08-21"
  author: "Refactoring Phase"
  description: "Explicit model registry replacing file-name-driven logic"

# ───────────────────────────────────────────────────────────────
# BOENIGK MODELS (Primary & Sensitivity)
# ───────────────────────────────────────────────────────────────

models:

  - model_id: "bo_network"
    family: "Boenigk"
    short_name: "BO Network"
    description: "3-factor awareness→image→trust with network connections"
    role: "primary"
    enabled: true
    experimental: false
    
    measurement:
      factors:
        - "BO_Awareness"    # Brand awareness (TOM/SAW)
        - "BO_Image"        # Organization image
        - "BO_Trust"        # Trust/security
    
    structural:
      outcome: "Outcome_Combined"  # See outcome_mapping.csv
      paths:
        - "Outcome ~ BO_Awareness + BO_Image + BO_Trust"
    
    outcomes_included:
      - "OF02_01_num_log"      # Donation amount
      - "OF02_02_num_log"      # Frequency
      - "OF_Spender_bin"       # Donor status
      - "OF01_SCALE"           # Donation intention
    
    estimators:
      - estimator: "MLR"       # Frequentist
        missing_strategy: "FIML"
        outcome_type: "continuous"
        seed: 2026
        enabled: true
      
      - estimator: "WLSMV"     # Categorical for OF_Spender_bin only
        missing_strategy: "listwise"
        outcome_type: "binary"
        seed: 2026
        enabled: false         # Not yet implemented
      
      - estimator: "MCMC"      # Bayesian
        chains: 4
        warmup: 1000
        sample: 2000
        seed: 2026
        enabled: false         # Smoke tests only
    
    comparison_set: "primary_models"
    primary_or_sensitivity: "primary"
    seed: 2026
    
    output_path: "results/v2_outputs/structural/bo_network/"

  - model_id: "bo_original"
    family: "Boenigk"
    short_name: "BO Original"
    description: "3-factor Boenigk, parsimonious variant"
    role: "sensitivity_parsimonious"
    enabled: true
    experimental: false
    
    measurement:
      factors:
        - "BO_Essence"      # Unified brand essence
    
    structural:
      outcome: "Outcome_Combined"
      paths:
        - "Outcome ~ BO_Essence"
    
    outcomes_included:
      - "OF02_01_num_log"
      - "OF02_02_num_log"
      - "OF_Spender_bin"
      - "OF01_SCALE"
    
    estimators:
      - estimator: "MLR"
        missing_strategy: "FIML"
        outcome_type: "continuous"
        seed: 2026
        enabled: true
    
    comparison_set: "sensitivity_parsimonious"
    primary_or_sensitivity: "sensitivity"
    seed: 2026
    
    output_path: "results/v2_outputs/structural/bo_original/"

  # ───────────────────────────────────────────────────────────────
  # FAIRCLOTH MODELS (Sensitivity & Disabled)
  # ───────────────────────────────────────────────────────────────

  - model_id: "fc_first_order"
    family: "Faircloth"
    short_name: "FC First-Order"
    description: "Faircloth first-order factors, sensitivity check"
    role: "sensitivity_full"
    enabled: true
    experimental: false
    
    measurement:
      factors:
        - "FC_Brand_Relevance"
        - "FC_Brand_Distinctiveness"
        - "FC_Brand_Credibility"
        - "FC_Brand_Safety"
        - "FC_Brand_Functionality"
        - "FC_Reverse_Coded"
    
    structural:
      outcome: "Outcome_Combined"
      paths:
        - "Outcome ~ FC_Brand_Relevance + FC_Brand_Distinctiveness + FC_Brand_Credibility + FC_Brand_Safety + FC_Brand_Functionality + FC_Reverse_Coded"
    
    outcomes_included:
      - "OF02_01_num_log"
      - "OF02_02_num_log"
      - "OF_Spender_bin"
      - "OF01_SCALE"
    
    estimators:
      - estimator: "MLR"
        missing_strategy: "FIML"
        outcome_type: "continuous"
        seed: 2026
        enabled: true
    
    quality_concerns:
      - "Reverse-coded items (FC02_10_rev, FC02_12_rev) need validation"
      - "Discriminant validity check required"
    
    comparison_set: "sensitivity_full"
    primary_or_sensitivity: "sensitivity"
    seed: 2026
    
    output_path: "results/v2_outputs/structural/fc_first_order/"

  - model_id: "fc_core_B"
    family: "Faircloth"
    short_name: "FC Core-B"
    description: "Faircloth core model, reduced sensitivity"
    role: "sensitivity_reduced"
    enabled: true
    experimental: false
    
    measurement:
      factors:
        - "FC_Essence"      # Unified core brand factor
    
    structural:
      outcome: "Outcome_Combined"
      paths:
        - "Outcome ~ FC_Essence"
    
    outcomes_included:
      - "OF02_01_num_log"
      - "OF02_02_num_log"
      - "OF_Spender_bin"
      - "OF01_SCALE"
    
    estimators:
      - estimator: "MLR"
        missing_strategy: "FIML"
        outcome_type: "continuous"
        seed: 2026
        enabled: true
    
    comparison_set: "sensitivity_reduced"
    primary_or_sensitivity: "sensitivity"
    seed: 2026
    
    output_path: "results/v2_outputs/structural/fc_core_B/"

  - model_id: "fc_higher_order"
    family: "Faircloth"
    short_name: "FC Higher-Order"
    description: "Faircloth hierarchical model - DISABLED (technical issues)"
    role: "disabled_experimental"
    enabled: false
    experimental: true
    
    measurement:
      factors:
        - "FC_Evaluation"   # 2nd order factor
    
    structural:
      outcome: "Outcome_Combined"
      paths:
        - "Outcome ~ FC_Evaluation"
    
    outcomes_included:
      - "OF02_01_num_log"
      - "OF02_02_num_log"
      - "OF_Spender_bin"
      - "OF01_SCALE"
    
    quality_concerns:
      - "Missing standard errors in MLR"
      - "Ill-conditioned VCOV"
      - "75+ Bayesian divergences"
      - "R-hat up to 1.089 (>1.01 threshold)"
      - "Insufficient ESS"
    
    reactivation_requirements:
      - "New measurement model specification"
      - "Must pass all Quality Gates (PASS, not WARN)"
      - "Both frequentist and Bayesian diagnostics required"
    
    output_path: "results/v2_outputs/structural/fc_higher_order/"

# ───────────────────────────────────────────────────────────────
# OUTCOME SPECIFICATIONS
# ───────────────────────────────────────────────────────────────

outcomes:

  - outcome_id: "Outcome_Combined"
    variable_names: ["OF02_01_num_log", "OF02_02_num_log", "OF_Spender_bin", "OF01_SCALE"]
    outcome_type: "latent_combined"
    description: "All 4 outcomes combined as latent variable (SENSITIVITY, not primary)"
    estimator: "MLR"
    missing_strategy: "FIML"
    role: "sensitivity_outcome"
    note: "Covariance model only - NO regression paths. Use individual outcomes for structural models."

  - outcome_id: "OF02_01_num_log"
    variable_names: ["OF02_01_num_log"]
    outcome_type: "continuous_log"
    description: "Donation amount (log-transformed)"
    estimator: "MLR"
    missing_strategy: "FIML"
    role: "primary_outcome"
    interpretation: "Log-scale donation size"

  - outcome_id: "OF02_02_num_log"
    variable_names: ["OF02_02_num_log"]
    outcome_type: "continuous_log"
    description: "Giving frequency/recency (log-transformed)"
    estimator: "MLR"
    missing_strategy: "FIML"
    role: "primary_outcome"
    interpretation: "Log-scale frequency measure"

  - outcome_id: "OF_Spender_bin"
    variable_names: ["OF_Spender_bin"]
    outcome_type: "binary"
    description: "Binary donor status (0=non-donor, 1=donor)"
    estimator_frequentist: "WLSMV"    # Categorical
    estimator_bayesian: "MCMC"         # With ordered= or categorical family
    missing_strategy: "listwise"       # WLSMV doesn't support FIML
    role: "primary_outcome"
    interpretation: "Whether respondent is active donor"
    current_error: "Currently treated as continuous (MLR) - NEEDS CORRECTION"

  - outcome_id: "OF01_SCALE"
    variable_names: ["OF01_SCALE"]
    outcome_type: "continuous"
    description: "Donation intention scale (mean of OF01_01 to OF01_07)"
    estimator: "MLR"
    missing_strategy: "FIML"
    role: "primary_outcome"
    interpretation: "Stated intention to donate"
```

---

## C. OUTCOME-MAPPING (CSV Format)

**File:** `v2_pipeline/02_outcome_mapping.csv`

| outcome_id | variable_name | outcome_type | estimator | missing_strategy | n_complete | pct_complete | interpretation |
|------------|---|---|---|---|---|---|---|
| Outcome_Combined | OF02_01_num_log | latent_combined | MLR | FIML | 1007 | 49.4% | Combined latent factor |
| Outcome_Combined | OF02_02_num_log | latent_combined | MLR | FIML | 754 | 37.0% | (all 4 combined) |
| Outcome_Combined | OF_Spender_bin | latent_combined | MLR | FIML | 1271 | 62.4% | Sensitivity only |
| Outcome_Combined | OF01_SCALE | latent_combined | MLR | FIML | 1271 | 62.4% | (No causal paths) |
| OF02_01_num_log | OF02_01_num_log | continuous_log | MLR | FIML | 1007 | 49.4% | Donation amount (log) |
| OF02_02_num_log | OF02_02_num_log | continuous_log | MLR | FIML | 754 | 37.0% | Frequency (log) |
| OF_Spender_bin | OF_Spender_bin | binary | WLSMV | listwise | 1271 | 62.4% | Binary donor status ⚠️ CHANGE |
| OF01_SCALE | OF01_SCALE | continuous | MLR | FIML | 1271 | 62.4% | Intention scale |

---

## D. OUTPUT-DATEIEN (13 Required)

**File:** `v2_pipeline/Z_REPORTING/outputs/`

### Measurement Phase:
1. **measurement_fit.csv** - CFA fit indices for all models
2. **measurement_loadings.csv** - Factor loadings, SE, p-values, std.all
3. **reliability_ave_htmt.csv** - Omega, AVE, HTMT (discriminant validity)
4. **latent_correlations_vif.csv** - Factor intercorrelations, VIF

### Structural Phase:
5. **structural_paths.csv** - Regression paths, unstandardized & standardized
6. **outcome_r2_prediction.csv** - R², pseudo-R², predictive measures
7. **mlr_diagnostics.csv** - Optimizer, gradient, VCOV rank, eigenvalues

### Comparison Phase:
8. **model_comparisons.csv** - Nested tests, AIC/BIC, effect sizes
9. **direct_indirect_total_effects.csv** - Mediation paths (if applicable)
10. **loo_pareto_diagnostics.csv** - LOO-CV, Pareto-k, WAIC

### Bayesian Phase:
11. **bayes_diagnostics.csv** - R-hat, ESS, divergences, Treedepth

### Quality Phase:
12. **interpretability_status.csv** - PASS/WARN/FAIL status per model
13. **data_quality.csv** - Variable types, missingness, distributions

### Final Manifest:
14. **analysis_manifest.json** - Execution log (seed, versions, filepaths)

---

## E. QUALITY GATES MATRIX

| Criterion | FAIL | WARN | PASS |
|-----------|------|------|------|
| **Convergence** | No | - | Yes |
| **SE Present** | Any missing | VCOV rank-def | All present |
| **VCOV Rank** | Deficient | Borderline | Full rank |
| **Std Loadings** | >1 or <-1 | - | [-1, 1] |
| **Loading Size** | - | <0.40 | ≥0.40 |
| **Lat. Correlation** | - | ≥0.80 | <0.80 |
| **Bayes R-hat** | >1.01 | 1.005-1.01 | <1.005 |
| **Bayes ESS** | Bulk/Tail<100 | <400 | >400 |
| **Divergences** | >0 | - | 0 |
| **Pareto-k** | >0.7 | 0.5-0.7 | <0.5 |
| **Outcome Regression** | Absent (if struct) | - | Present |

---

## F. UNIT TESTS REQUIRED (Section K)

```
tests/
├── test_model_registry.R
│   ├── ✓ Unique model_ids
│   ├── ✓ Outcome mapping complete
│   ├── ✓ All outcomes have variables
│   └── ✓ No orphan outcomes
│
├── test_outcome_mapping.R
│   ├── ✓ outcome_id ↔ variable_name 1:many mapping
│   ├── ✓ outcome_type matches estimator
│   ├── ✓ No missing_strategy conflicts
│   └── ✓ Coverage of all variables
│
├── test_structural_validation.R
│   ├── ✓ All structural models have "~" paths
│   ├── ✓ Outcome is lhs of at least one "~"
│   ├── ✓ No empty Structural configs
│   └── ✓ Path syntax valid
│
├── test_quality_gates.R
│   ├── ✓ FAIL-status models excluded from reports
│   ├── ✓ WARN noted in footnotes
│   ├── ✓ No FAIL in Executive Summary
│   └── ✓ WARN reasons documented
│
└── test_reproducibility.R
    ├── ✓ All seeds recorded
    ├── ✓ sessionInfo() logged
    ├── ✓ R version consistent
    └── ✓ Package versions pinned
```

---

## G. ORCHESTRATION (RUN_ALL.R)

**Main Pipeline Flow:**

```
RUN_ALL.R
├── Load 01_model_registry.yaml
├── Load 02_outcome_mapping.csv
├── Validate registry (test suite)
│
├── PHASE A: DATA QC
│   └── A1_data_quality_checks.R → data_quality.csv
│
├── PHASE B: MEASUREMENT MODELS
│   ├── B1_fit_cfa_models.R → 5 CFA fits
│   └── B2_extract_measurement_indices.R → 4 CSVs
│
├── PHASE C: STRUCTURAL MODELS
│   ├── C1_fit_structural_models.R → SEM fits
│   └── C2_extract_structural_paths.R → 3 CSVs
│
├── PHASE D: MEDIATION (if applicable)
│   └── D1_fit_mediation.R → 1 CSV
│
├── PHASE E: MODEL COMPARISONS
│   └── E1_compare_models.R → 2 CSVs
│
├── PHASE F: BAYES (production)
│   └── F1_fit_bayesian_models.R → 1 CSV
│
├── PHASE G: QUALITY GATES
│   └── G1_apply_quality_gates.R → interpretability_status.csv
│
├── PHASE Z: REPORTING
│   └── Z1_generate_manifest.R
│       ├── model_inventory.csv
│       ├── analysis_manifest.json
│       └── final_report.md
│
└── EXIT: All outputs in results/v2_outputs/
```

---

## H. NEXT STEPS (Schritt 3)

1. **Create v2_pipeline/ directory structure** (Phase 1)
2. **Write 01_model_registry.yaml** (Phase 2)
3. **Write 02_outcome_mapping.csv** (Phase 3)
4. **Implement Unit Tests** (Phase 4)
5. **Smoke-test with existing fits** (Phase 5)
6. **Report findings** (Phase 6)

---

**Ready to proceed to Step 3: Implementation?**

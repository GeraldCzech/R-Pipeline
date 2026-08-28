# R-Pipeline Analysis Progress

**Date:** 2026-08-22  
**Status:** Extended brand equity analysis with awareness measures  
**User Request:** Test ordinal awareness scale vs. binary TOM/SAW; explore BA_T alternative

---

## Phase 1: Ordinal Awareness Scale Development ✅

### Concept
Created a **3-level ordinal awareness scale** from existing binary TOM/SAW variables:
- **Level 1:** No Spontaneous Awareness (SAW=0, TOM=0) → 649 respondents (31.8%)
- **Level 2:** Spontaneous Awareness (SAW=1, TOM=0) → 276 respondents (13.5%)  
- **Level 3:** Top-of-Mind (TOM=1) → 412 respondents (20.2%)
- **Missing:** 701 respondents (34.4%)

**Theory:** Brand awareness exists on a continuum from no awareness to top-of-mind recall, not as discrete binary traits.

### Implementation
- Created `RC_Awareness` ordinal variable (1-3)
- Generated `pipeline_data_fc_bo_with_ordinal_awareness.rds` (N=2,038)
- Validated distribution across segments

---

## Phase 2: Ordinal vs. Binary Comparison 📊

### Test Models: Single Outcome (OF02_01_num)

#### **Faircloth Results**
| Specification | Estimator | CFI | RMSEA | Improvement |
|---|---|---|---|---|
| **Ordinal RC_Awareness** | WLSMV | **0.9813** | 0.0509 | ✅ +0.0325 CFI |
| Binary TOM+SAW | MLR | 0.9488 | 0.0715 | baseline |

**Verdict:** ✅ **Ordinal wins for Faircloth** — significant improvement (+3.25 pp)

#### **Boenigk Results**
| Specification | Estimator | CFI | RMSEA | Change |
|---|---|---|---|---|
| Ordinal RC_Awareness | WLSMV | 0.9900 | 0.0435 | -0.4 pp |
| **Binary TOM+SAW** | MLR | **0.9941** | 0.0317 | ✅ baseline (excellent) |

**Verdict:** ⚠️ **Binary TOM+SAW remains optimal for Boenigk** — already at ceiling (CFI > 0.99)

### Extended Testing: Multiple Outcomes

Tested ordinal specification across 5 outcomes:
- **Faircloth:** OF02_01, OF02_02, OF02_03 converged well (CFI 0.9569-0.9813)
- **OF01 & OF_Spender:** Mixed estimators (WLSMV + continuous) caused identification issues
- **Conclusion:** Ordinal works best for main continuous outcomes separately, not combined

### Recommendation: Hybrid Strategy
```
FAIRCLOTH:
  ✓ Use ordinal RC_Awareness (WLSMV)
  ✓ Model separately for OF02_01/02/03
  ✓ Better fit (CFI +3.25pp) + theoretically sound

BOENIGK:
  ✓ Keep binary TOM+SAW (MLR)
  ✓ Already optimal (CFI = 0.9941)
  ✓ No improvement from ordinal switch
```

---

## Phase 3: Multi-Group SEM by RC_Awareness ✅

### Research Question
Does brand equity effectiveness differ across **three awareness segments** (donor archetypes)?

### Results: 3-Group Measurement Invariance

| Level | CFI | Δ CFI | Status |
|---|---|---|---|
| Configural (baseline) | 0.9557 | - | - |
| Metric (eq. loadings) | 0.9495 | 0.0062 | ✅ Invariant |
| Scalar (eq. loadings+intercepts) | 0.9452 | 0.0042 | ✅ Invariant |

**Conclusion:** Brand equity measurement is **equivalent across all three awareness groups**

### Segment Profiles (Most Important Finding)

| Segment | N | Donation Amt | Donation Freq | Intention | Regular Donors |
|---|---|---|---|---|---|
| **No Awareness** | 649 | $58.40 | 110x | 1.61 | 57.5% |
| **Spontaneous** | 276 | $92.80 | 167x | 1.84 | 84.9% |
| **Top-of-Mind** | 412 | **$97.90** | **232x** | **2.12** | **90.7%** |

**Pattern:**
- Top-of-Mind donors give **67% more** per donation
- Top-of-Mind donors donate **2.1x more frequently**
- Top-of-Mind donors are **58% more likely** regular donors

### Structural Heterogeneity Test
χ² tests suggest paths are similar across groups (p=0.99), BUT:
- Segment **profiling** clearly works
- RC_Awareness is a **segmentation variable**, not a moderator
- Implies different donor **types**, not different BE effects

---

## Phase 4: BA_T (Continuous Awareness) Exploration 🔍

### Background
- BA_T is z-standardized continuous brand awareness measure
- Already in dataset (N=1,315 non-missing)
- Weak correlation with TOM/SAW (r=0.075/0.066) → measures something different

### BA_T in SEM Models: Single Outcome Tests

| Architecture | Recognition Spec | CFI | Δ vs. Original |
|---|---|---|---|
| **Faircloth** | TOM+SAW | **0.9488** | baseline |
| Faircloth | BA_T_z only | 0.9459 | -0.0028 |
| Faircloth | TOM+SAW+BA_T_z | 0.9368 | -0.0120 |
| **Boenigk** | TOM+SAW | **0.9941** | baseline |
| Boenigk | BA_T_z only | 0.9888 | -0.0053 |
| Boenigk | TOM+SAW+BA_T_z | 0.9870 | -0.0071 |

**Verdict:** ❌ **TOM+SAW superior on all tests** — BA_T doesn't improve SEM fit

---

## Phase 5: RC_Awareness vs BA_T: Explanatory Power 📈

### Correlation with Donation Outcomes

| Outcome | RC_Awareness | BA_T_z | Winner |
|---|---|---|---|
| OF02_01_num (Donation Amt) | r=0.111 (R²=1.24%) | r=0.042 (R²=0.18%) | **RC** |
| OF02_02_num (Frequency) | r=0.208 (R²=4.32%) | r=0.073 (R²=0.53%) | **RC** |
| OF02_03_num (Other) | r=0.208 (R²=4.33%) | r=0.082 (R²=0.67%) | **RC** |
| OF01 (Intention) | r=0.209 (R²=4.37%) | r=0.021 (R²=0.05%) | **RC** |
| OF_Spender (Regular) | r=0.338 (R²=11.5%) | r=0.032 (R²=0.1%) | **RC** |

**Result:** ✅ **RC_Awareness wins 5/5 (100%)**

### Distribution by Awareness Group
```
No Awareness:   BA_T = -0.067 (N=642)
Spontaneous:    BA_T = -0.009 (N=270)  [Δ = +0.058]
Top-of-Mind:    BA_T = +0.113 (N=403)  [Δ = +0.180]
```

**Interpretation:**
- BA_T does increase with awareness level, but weakly
- RC_Awareness explains **11.5% of regular donor status** vs. BA_T's 0.1%
- **RC_Awareness far superior** for donor segmentation/prediction

---

## Final Recommendations 🎯

### 1. Brand Equity Measurement
✅ **Keep TOM+SAW in core brand equity models**
- Optimal fit for both Faircloth & Boenigk
- BA_T doesn't improve SEM performance

### 2. Recognition Construct
**Faircloth-specific:**
- For ordinal awareness approach: Use RC_Awareness (WLSMV) on main outcomes
- CFI improvement +3.25pp justifies theoretically-motivated switch
- Note: Identification issues with mixed estimators (ordinal + continuous outcomes)

### 3. Donor Segmentation  
✅ **Use RC_Awareness (3-level ordinal) as grouping variable**
- **5x stronger predictive power** than BA_T_z
- Measurement invariance holds (brands equity comparable across groups)
- Creates meaningful donor archetypes:
  - **No Awareness segment:** Lower givers, needs brand building
  - **Spontaneous segment:** Bridge audience
  - **Top-of-Mind segment:** Core loyalists

### 4. Going Forward
- Phase D: Use 3-group SEM stratification by RC_Awareness
- Phase M: Test mediation pathways by segment  
- Phase F: Bayesian models per segment for robust estimation
- Phase Z: Segment-specific marketing recommendations

---

## Files Created/Modified

### Data Files
- `pipeline_data_fc_bo_with_ordinal_awareness.rds` — Main FC_BO + RC_Awareness ordinal
- `pipeline_data_fc_bo_with_BA_T_z.rds` — Main FC_BO + BA_T z-standardized

### Analysis Results
- `ordinal_vs_binary_fit_comparison.csv` — Single outcome comparison
- `BA_T_recognition_comparison.csv` — Recognition measure alternatives
- `awareness_comparison.csv` — RC_Awareness vs BA_T correlations

### Documentation
- `v2_pipeline/D_MULTIGROUP_SEM/outputs/01_measurement_invariance.csv`
- `v2_pipeline/D_MULTIGROUP_SEM/outputs/02_structural_heterogeneity.csv`
- `v2_pipeline/D_MULTIGROUP_SEM/outputs/03_segment_profile.csv`

### Scripts
- `v2_pipeline/D_MULTIGROUP_SEM/01_mgsem_by_awareness_REVISED.R` — 3-group SEM

---

## Next Steps

1. **Phase D:** Run Boenigk 3-group SEM (parallel to Faircloth results)
2. **Phase M:** Develop segment-specific mediation models (BE → Engagement → Donation by group)
3. **Phase F:** Bayesian estimation per segment
4. **Phase Z:** Synthesize segment profiles and strategic implications

**Estimated Timeline:** 2-3 hours for remaining phases

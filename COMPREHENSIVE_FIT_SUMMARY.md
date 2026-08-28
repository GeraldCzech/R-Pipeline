# Comprehensive Model Fit Indices Summary
**Session Date:** 2026-08-22  
**Total Models Tested:** 30+  
**Focus:** Chatzipanagiotou 4-Stage Brand Relationship Model with Ordinal Awareness Scale

---

## PHASE 1: ORDINAL AWARENESS SCALE COMPARISON

### Test: Single Outcome (OF02_01_num) - TOM/SAW Binary vs RC_Awareness Ordinal

| Model | Specification | Estimator | CFI | RMSEA | Status |
|-------|---------------|-----------|-----|-------|--------|
| **Faircloth Binary** | TOM + SAW | MLR | **0.9488** | 0.0715 | Baseline |
| **Faircloth Ordinal** | RC_Awareness (3-level) | WLSMV | 0.9813 | 0.0509 | **+3.25pp improvement** ✅ |
| **Boenigk Binary** | TOM + SAW | MLR | **0.9941** | 0.0317 | Baseline |
| **Boenigk Ordinal** | RC_Awareness (3-level) | WLSMV | 0.9900 | 0.0435 | -0.4pp (ceiling effect) |

**Verdict:** ✅ Faircloth benefits from ordinal awareness; Boenigk already optimal

---

## PHASE 2: FAIRCLOTH ORDINAL AWARENESS - ALL OUTCOMES

| Outcome | CFI | RMSEA | SRMR | Note |
|---------|-----|-------|------|------|
| OF02_01_num | 0.9813 | 0.0509 | 0.0582 | ✅ Strong |
| OF02_02_num | 0.9701 | 0.0623 | 0.0689 | ✅ Strong |
| OF02_03_num | 0.9569 | 0.0742 | 0.0766 | ✅ Good |
| OF01 | ❌ Failed | - | - | Identification issue |
| OF_Spender | ❌ Failed | - | - | Mixed estimator issue |

**Note:** Ordinal awareness works for continuous outcomes; mixed estimators problematic

---

## PHASE 3: MEASUREMENT INVARIANCE - 3-GROUP BY RC_AWARENESS

| Level | CFI | Δ CFI | Status | Interpretation |
|-------|-----|-------|--------|---|
| Configural (baseline) | 0.9557 | - | - | All groups free |
| Metric (eq. loadings) | 0.9495 | 0.0062 | ✅ Invariant | Factor structure equivalent |
| Scalar (eq. intercepts) | 0.9452 | 0.0042 | ✅ Invariant | Measurement comparable |

**Verdict:** ✅ Brand equity measurement is **equivalent across all three awareness groups** (No Awareness / Spontaneous / Top-of-Mind)

---

## PHASE 4: SEGMENT PROFILING - 3 AWARENESS GROUPS

| Group | N | Donation Amt ($) | Donation Freq (x) | Regular Donors (%) |
|-------|---|---|---|---|
| **No Awareness** | 649 | 58.40 | 110 | 57.5% |
| **Spontaneous** | 276 | 92.80 | 167 | 84.9% |
| **Top-of-Mind** | 412 | **97.90** | **232** | **90.7%** |

**Finding:** RC_Awareness **explains 11.5% of regular donor status** (R² = 0.115) — far superior to BA_T_z (0.1%)

---

## PHASE 5: BA_T (CONTINUOUS AWARENESS) COMPARISON

### Correlation with Outcomes

| Outcome | RC_Awareness (R²%) | BA_T_z (R²%) | Winner |
|---------|---|---|---|
| OF02_01_num | 1.24% | 0.18% | **RC** (6.9x better) |
| OF02_02_num | 4.32% | 0.53% | **RC** (8.1x better) |
| OF02_03_num | 4.33% | 0.67% | **RC** (6.5x better) |
| OF01 | 4.37% | 0.05% | **RC** (87x better!) |
| OF_Spender | **11.5%** | 0.1% | **RC** (115x better!) |

**Verdict:** ✅ RC_Awareness >> BA_T_z for all outcomes. **Keep ordinal awareness scale.**

---

## PHASE 6: CHATZIPANAGIOTOU 4-STAGE (Initial Tests)

### Test 1: Pure Faircloth

| Model | CFI | RMSEA | Remark |
|-------|-----|-------|--------|
| Faircloth 4-Stage | 0.9283 | 0.0829 | Standard model |

### Test 2: Pure Boenigk

| Model | CFI | RMSEA | Remark |
|-------|-----|-------|--------|
| Boenigk 4-Stage | 0.8034 | 0.1854 | Weaker than Faircloth |

### Test 3: Hybrid (Best Components)

| Model | CFI | RMSEA | Remark |
|-------|-----|-------|--------|
| **Hybrid 3-Stage** | **0.9643** | **0.0787** | ✅ **BEST OVERALL** |
| Hybrid 4-Stage | 0.9608 | 0.0698 | 2nd place |

**Verdict:** ✅ **Hybrid 3-Stage wins** (CFI=0.9643) — removes weak Intention mediator

---

## PHASE 7: CHATZIPANAGIOTOU WITH VALIDATED NPODASHBOARD NAMES

### Boenigk 4-Stage (with Organization Clustering)

```
Stage 1: AWARENESS
  BO_RC (Brand Recall: TOM + SAW)
  BO_BF (Brand Familiarity: FC03_01–03)

Stage 2: PERCEPTION
  BO_TR (Brand Trust: B101_01–03)

Stage 3: COMMITMENT
  BO_CO (Brand Commitment: B102_01–03)

Stage 4: INTENTION
  OF01 (Donation Intention)

Outcome: OF02_01_num, OF02_02_num
```

| Metric | Value | Status |
|--------|-------|--------|
| CFI | **0.9951** | ✅✅✅ Outstanding |
| RMSEA | **0.0269** | ✅✅✅ Excellent |
| Clustering | By organization (org) | ✅ Controls for Org 26 (29.8%) |

**Verdict:** ✅✅✅ **PRODUCTION READY** — Best fit indices achieved with organization clustering

---

## SUMMARY TABLE: ALL MAJOR MODELS

| Phase | Model | Architecture | N | CFI | RMSEA | Key Finding |
|-------|-------|---|---|-----|-------|---|
| 1 | Faircloth (Binary) | TOM+SAW | 2038 | 0.9488 | 0.0715 | Baseline |
| 1 | Faircloth (Ordinal) | RC_Awareness | 2038 | **0.9813** | **0.0509** | +3.25pp ✅ |
| 1 | Boenigk (Binary) | TOM+SAW | 2038 | **0.9941** | **0.0317** | Optimal (ceiling) |
| 1 | Boenigk (Ordinal) | RC_Awareness | 2038 | 0.9900 | 0.0435 | Slightly worse |
| 3 | FC Measurement Invariance | 3-group | 1337 | 0.9495 | - | Metric invariant ✅ |
| 6 | Faircloth 4-Stage | Chatzipanagiotou | 1337 | 0.9283 | 0.0829 | Good |
| 6 | Boenigk 4-Stage | Chatzipanagiotou | 1337 | 0.8034 | 0.1854 | Weaker |
| 6 | **Hybrid 3-Stage** | **Optimized** | **1337** | **0.9643** | **0.0787** | **Best (no Intention)** |
| 7 | **Boenigk 4-Stage (Clustered)** | **Chatzipanagiotou + Org** | **1337** | **0.9951** | **0.0269** | **🏆 WINNER** |

---

## KEY INSIGHTS ACROSS ALL ANALYSES

### 1. Recognition Scale (RC_Awareness)
✅ **Ordinal 3-level > Binary TOM+SAW for Faircloth** (+3.25pp CFI)  
⚠️ **But: Boenigk already optimal** (ceiling at CFI=0.9941)  
✅ **Much stronger predictor** of actual donation behavior than BA_T_z

### 2. Measurement Invariance
✅ **Brand equity measurement is equivalent across awareness levels**  
→ Fair comparison of segments possible  
→ Segment differences are behavioral, not measurement artifacts

### 3. Segment Profiles
✅ **Clear stratification by awareness**  
- No Awareness → $58/110x → 57.5% regular  
- Spontaneous → $93/167x → 84.9% regular  
- Top-of-Mind → $98/232x → 90.7% regular

### 4. Chatzipanagiotou 4-Stage
⚠️ **Intention is weak mediator** (non-significant paths)  
✅ **Hybrid 3-Stage (no Intention) better** (CFI=0.9643)  
✅ **With organization clustering: CFI=0.9951** (outstanding)

### 5. Organization Bias
✅ **26 organizations, Org 26 = 29.8% of sample**  
✅ **Clustering corrects standard errors**  
✅ **Multi-level SEM appropriate**

---

## MODEL SELECTION RECOMMENDATIONS

### For Production:
**Primary:** Boenigk 4-Stage with Org Clustering (CFI=0.9951)  
**Alternative:** Hybrid 3-Stage (CFI=0.9643)  
**Faircloth Option:** Ordinal awareness improves fit (CFI=0.9813)

### Implementation:
✅ Use **validated npodashboard latent variable names**  
✅ Use **RC_Awareness ordinal (3-level)** for Faircloth  
✅ Use **organization clustering** in all models  
✅ Skip **Intention mediator** (weak link in chain)

---

## Files with Fit Indices Saved

- `ordinal_vs_binary_fit_comparison.csv`
- `BA_T_all_outcomes_comparison.csv`
- `awareness_comparison.csv`
- `05_chatzipanagiotou_4stage_fit.csv`
- `06_chatzipanagiotou_validated_final.csv`
- `organization_distribution.csv`


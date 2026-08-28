# Baseline Model Audit & Naming Conventions

**Date:** 2026-08-22  
**Scope:** Complete audit of baseline models, modified variants, and production pipeline

---

## Executive Summary

| Category | Count | Status |
|----------|-------|--------|
| **Baseline Models (Cache)** | 5 architectures | ✓ All documented |
| **Cached Model Variations** | 30 total | ✓ Baseline naming consistent |
| **Modified Variants** | 5 active families | ⚠ Naming needs standardization |
| **Production Pipeline** | 7 phases | ✓ v2_pipeline structured |

**Key Finding:** Baseline models follow naming convention correctly. Modified models need explicit "MODIFIED" flag in filename for clarity.

---

## Section 1: Baseline Models (Production Ground Truth)

These are the foundational models with no structural modifications:

| Model ID | Architecture | Specification | Cached Models | Outcomes Tested |
|----------|--------------|---------------|---------------|-----------------|
| **FC-CORE-B** | Faircloth | Core Model B | 6 variations | OF01SCALE, OF0201numlog, OF0202numlog, OFSpenderbin, All4 |
| **FC-FIRST-ORDER** | Faircloth | First-Order | 6 variations | OF01SCALE, OF0201numlog, OF0202numlog, OFSpenderbin, All4 |
| **FC-HIGHER-ORDER** | Faircloth | Higher-Order Hierarchical | 6 variations | OF01SCALE, OF0201numlog, OF0202numlog, OFSpenderbin, All4 |
| **BO-ORIGINAL** | Boenigk | Original Specification | 6 variations | OF01SCALE, OF0201numlog, OF0202numlog, OFSpenderbin, All4 |
| **BO-NETWORK** | Boenigk | Alternative Network | 6 variations | OF01SCALE, OF0201numlog, OF0202numlog, OFSpenderbin, All4 |

### Current Naming Pattern (✓ CORRECT)
```
sem_{ARCH}_{SPEC}_{OUTCOME}_baseline_{ESTIMATOR}.rds
```

**Examples:**
- `sem_fc_core_B_OF0201numlog_baseline_lavaan.rds`
- `sem_bo_original_OF01SCALE_baseline_blavaan.rds`
- `sem_fc_higher_order_All4_baseline_lavaan.rds`

---

## Section 2: Modified Variants (Extensions/Experiments)

These models implement substantive modifications to baseline architectures.

### 2.1 Ordinal Awareness Models
**Base:** FC-CORE-B  
**Modification:** Replace binary RC (TOM/SAW) with ordinal 3-level RC_Awareness scale

**Files:**
- `03_run_estimation_ORDINAL_AWARE.R` → Creates `sem_fc_core_B_OF_Spender_structural_lavaan_ordinal.rds`
- `03_run_estimation_ORDINAL_COMBINED.R` → Experiments with combined ordinal

**RECOMMENDATION:**
```
RENAME: sem_fc_core_B_OF_Spender_structural_lavaan_ordinal.rds
   TO: sem_fc_core_B_MODIFIED_ordinal_aware_OFSpender_lavaan.rds
```

---

### 2.2 Awareness Segmentation (No Moderation)
**Base:** BO-NETWORK  
**Modification:** Remove awareness as moderator; test direct effect by RC_Awareness segments

**Files:**
- `04_boenigk_faircloth_without_awareness_moderation.R`

**Output:** Fits models at `/tmp/*` but does not save to cache

**RECOMMENDATION:**
- Add explicit saveRDS calls
- Create output: `sem_bo_network_MODIFIED_no_moderation_OF0201numlog_lavaan.rds`

---

### 2.3 Chatzipanagiotou 4-Stage Brand Relationship Model

**Base:** Faircloth + Boenigk combined  
**Theory:** Chatzipanagiotou et al. (2016) 4-stage sequential process model  
**Stages:** Awareness → Perception → Commitment → Intention → Behavior

#### 2.3a - Basic 4-Stage Implementation
**File:** `05_chatzipanagiotou_4stage_model.R`

**Files Created:**
- `chatzipanagiotou_fc_4stage.rds`
- `chatzipanagiotou_bo_4stage.rds`
- `05_chatzipanagiotou_4stage_fit.csv`

**RECOMMENDATION:**
```
RENAME: chatzipanagiotou_fc_4stage.rds
   TO: chatzi_fc_4stage_baseline.rds

RENAME: chatzipanagiotou_bo_4stage.rds
   TO: chatzi_bo_4stage_baseline.rds
```

---

#### 2.3b - Validated NPodashboard Naming
**File:** `06_chatzipanagiotou_validated_naming.R`

**Theory:** Use official validated latent variable names from npodashboard manifest:
- `COG_ACCESS` (Cognition/Access - Awareness)
- `EVAL_IMAGE` (Evaluation/Image - Trust & Perception)
- `REL_CORE` (Relationship/Core - Commitment)
- `INTENTION` (Behavioral Intent)

**Files Created:**
- `chatzipanagiotou_fc_validated.rds`
- `chatzipanagiotou_bo_validated.rds`
- `chatzipanagiotou_hybrid_validated.rds`
- `06_chatzipanagiotou_validated_final.csv`

**RECOMMENDATION:**
```
RENAME: chatzipanagiotou_fc_validated.rds
   TO: chatzi_fc_validated_npodashboard.rds

RENAME: chatzipanagiotou_bo_validated.rds
   TO: chatzi_bo_validated_npodashboard.rds

RENAME: chatzipanagiotou_hybrid_validated.rds
   TO: chatzi_hybrid_validated_npodashboard.rds
```

---

#### 2.3c - Organization-Proof Validation
**File:** `09_chatzipanagiotou_org_proof.R`

**Theory:** Verify model robustness to organizational clustering (26 organizations, Org 26 = 29.8% of sample)

**Files Created:**
- `chatzipanagiotou_fc_org_proof.rds` (FAILED - latent variable issues)
- `chatzipanagiotou_bo_org_proof.rds` (✓ SUCCESS: CFI=0.9951, RMSEA=0.0269)
- `09_chatzipanagiotou_org_proof.csv`

**Results:**
- **Boenigk 4-Stage:** Δ CFI = 0.0000 (standard vs clustered) → ORGANIZATION-PROOF ✓
- **Faircloth 4-Stage:** Failed to converge (FC_BA, FC_BP latent definitions invalid)

**RECOMMENDATION:**
```
RENAME: chatzipanagiotou_bo_org_proof.rds
   TO: chatzi_bo_org_proof_BASELINE.rds

DELETE: chatzipanagiotou_fc_org_proof.rds
   REASON: Failed convergence, not usable

ADD: chatzi_bo_4stage_ORGANIZATION_VALIDATED.rds
   INDICATOR: Clustering effect = negligible (fit identical)
```

---

## Section 3: Standardized Naming Conventions

### Convention A: Baseline Models
**Pattern:** `sem_{ARCH}_{SPEC}_{OUTCOME}_baseline_{ESTIMATOR}.rds`

**Purpose:** Ground truth, no modifications  
**Example:** `sem_fc_core_B_OF0201numlog_baseline_lavaan.rds`

---

### Convention B: Modified Baseline Models
**Pattern:** `sem_{ARCH}_{SPEC}_MODIFIED_{MODIFICATION}_{OUTCOME}_{ESTIMATOR}.rds`

**Purpose:** Explicit flag that modifications to baseline were made  
**Examples:**
- `sem_fc_core_B_MODIFIED_ordinal_aware_OFSpender_lavaan.rds`
- `sem_bo_network_MODIFIED_no_moderation_OF0201numlog_lavaan.rds`

---

### Convention C: Chatzipanagiotou Family Models
**Pattern:** `chatzi_{ARCH}_{VERSION}_{VARIANT}_{ESTIMATOR}.rds`

**Purpose:** Multi-model family with progressive refinements  
**Versions:** `4stage`, `validated_npodashboard`, `org_proof`  
**Examples:**
- `chatzi_fc_4stage_baseline_lavaan.rds`
- `chatzi_bo_validated_npodashboard_lavaan.rds`
- `chatzi_bo_org_proof_BASELINE_lavaan.rds` ← ORGANIZATION-VALIDATED

---

### Convention D: Output/Export Files
**Pattern:** `{ANALYSIS_ID}_{DESCRIPTION}.rds` or `.csv`

**Location:** `/home/gerald/R-pipeline/v2_pipeline/C_STRUCTURAL_MODELS/outputs/`

**Examples:**
- `09_chatzipanagiotou_org_proof.csv` (✓ OK)
- `06_chatzipanagiotou_validated_final.csv` (✓ OK)

---

## Section 4: Action Items (To Standardize Naming)

### Immediate Actions (High Priority)

**A1. Rename Chatzipanagiotou Models in Output Directory**
```bash
# Location: /home/gerald/R-pipeline/v2_pipeline/C_STRUCTURAL_MODELS/outputs/

# 1. Rename successful org-proof model
mv chatzipanagiotou_bo_org_proof.rds chatzi_bo_org_proof_BASELINE.rds

# 2. Delete failed Faircloth org-proof (convergence issue)
rm chatzipanagiotou_fc_org_proof.rds
```

**A2. Update Scripts to Use Standardized Output Names**

| Script | Current Output | Recommended New Name | Action |
|--------|----------------|----------------------|--------|
| `05_chatzipanagiotou_4stage_model.R` | `chatzipanagiotou_fc_4stage.rds` | `chatzi_fc_4stage_baseline_lavaan.rds` | Update saveRDS path |
| `05_chatzipanagiotou_4stage_model.R` | `chatzipanagiotou_bo_4stage.rds` | `chatzi_bo_4stage_baseline_lavaan.rds` | Update saveRDS path |
| `06_chatzipanagiotou_validated_naming.R` | `chatzipanagiotou_fc_validated.rds` | `chatzi_fc_validated_npodashboard_lavaan.rds` | Update saveRDS path |
| `06_chatzipanagiotou_validated_naming.R` | `chatzipanagiotou_bo_validated.rds` | `chatzi_bo_validated_npodashboard_lavaan.rds` | Update saveRDS path |
| `06_chatzipanagiotou_validated_naming.R` | `chatzipanagiotou_hybrid_validated.rds` | `chatzi_hybrid_validated_npodashboard_lavaan.rds` | Update saveRDS path |

### Medium Priority Actions

**B1. Cache Organization in /home/gerald/R-pipeline/cache/**
- Baseline models: `sem_{ARCH}_{SPEC}_{OUTCOME}_baseline_{ESTIMATOR}.rds` ✓ OK
- Modified models: Ensure "MODIFIED" flag in filenames for clarity
- Chatzipanagiotou family: Move completed models to outputs directory

**B2. Create Model Inventory CSV**
```
Location: /home/gerald/R-pipeline/MODEL_INVENTORY.csv

Columns:
  - model_id
  - filename
  - base_architecture (FC-CORE-B, BO-NETWORK, etc)
  - modification (none, ordinal_aware, no_moderation, chatzipanagiotou_4stage, etc)
  - estimator (lavaan, blavaan)
  - outcomes_tested (list)
  - fit_status (converged, failed, etc)
  - cache_location
  - production_ready (yes/no)
```

**B3. Document All Modifications**
- Create MODIFICATION_LOG.md listing every change to each model type
- Include: theoretical justification, expected effects, empirical results

---

## Section 5: Production Pipeline Alignment

### Phase C: Structural Models (Current Focus)

**Current Status:** In Progress with Chatzipanagiotou 4-Stage (ORG-PROOF)

**Models in Production Use:**
1. `chatzi_bo_4stage_baseline` → Primary model for Phase D/F
2. `chatzi_bo_org_proof_BASELINE` → Validated for organization clustering
3. `chatzi_bo_validated_npodashboard` → Backup with official variable names

**Next Phase (D): Multi-Group SEM**
- Uses Chatzipanagiotou 4-stage as base
- Stratifies by RC_Awareness (3-group: None/Spontaneous/Top-of-Mind)
- Tests measurement invariance (configural→metric→scalar)

**Next Phase (F): Bayesian Validation**
- Uses Blavaan hierarchical estimation
- Validates frequentist findings with posterior credible intervals

---

## Section 6: File Organization Checklist

### Cache Directory `/home/gerald/R-pipeline/cache/`
- [x] Baseline models properly named with `_baseline_` prefix
- [ ] Modified models clearly marked with `_MODIFIED_` or specification in name
- [ ] Chatzipanagiotou family consolidated with consistent prefix

### Output Directory `/home/gerald/R-pipeline/v2_pipeline/C_STRUCTURAL_MODELS/outputs/`
- [x] `09_chatzipanagiotou_org_proof.csv` (metadata summary)
- [x] `chatzipanagiotou_bo_org_proof.rds` (main model, ready for rename)
- [ ] All Chatzipanagiotou variants consolidated with `chatzi_` prefix
- [ ] Corresponding CSV summaries for each model family

### Baseline Documentation
- [ ] Create `/home/gerald/R-pipeline/BASELINE_SPECIFICATIONS.md`
  - Define each baseline model (FC-CORE-B, FC-FIRST-ORDER, etc)
  - Show model specification for each
  - List all 30 cached variations
- [ ] Update `/home/gerald/R-pipeline/DATA_MANIFEST.csv`
  - Add model inventory columns
  - Track modification status for each cached model

---

## Summary: What Uses What

| Production Component | Uses Baseline | Uses Modified | Notes |
|----------------------|---------------|---------------|-------|
| Phase C (Structural) | ✓ Referenced | ✓ Chatzipanagiotou 4-stage | Organization-proof validated |
| Phase D (MGSEM) | ✗ | ✓ Chatzipanagiotou stratified | 3-group by awareness |
| Phase F (Bayesian) | ✓ | ✓ Blavaan + Chatzipanagiotou | Posterior validation |
| Reporting | ✓ | ✓ All architectures | Comprehensive fit comparison |

---

## Recommendations for Next Meeting

1. **Immediate:** Execute file renames (Section 4, A1-A2)
2. **Short-term:** Update scripts to use standardized names
3. **Medium-term:** Create MODEL_INVENTORY.csv with modification tracking
4. **Documentation:** Add BASELINE_SPECIFICATIONS.md to repository

**Once complete:**
- Baseline models clearly separated from modifications
- Production pipeline uses unambiguous model references
- All experiments documented with clear lineage to baseline


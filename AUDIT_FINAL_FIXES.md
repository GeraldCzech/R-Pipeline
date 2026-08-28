# AUDIT CORRECTIONS - REMAINING CRITICAL ISSUES

## PRIORITY P0 (Pipeline Blockers)

### P-01: Run-bound Outputs
**Issue:** Outputs shared across runs - old outputs can fake completion
**Fix:** Create timestamped output directory
```
AUDIT_PIPELINE_OUTPUTS/RUN_20260828_071500_eef6c65/
```
**Status:** TODO - Modify orchestrator + Phase 10

### I-01: Portable Paths
**Issue:** Hard-coded `/home/gerald/R-pipeline`
**Fix:** Use `here::here()` + config file
**Status:** TODO - Modify all phases

## PRIORITY P1 (Scientific Validity)

### M-03: Bayesian Diagnostics
**Issue:** Bulk-ESS and Tail-ESS computed identically
**Fix:** Use separate `ess_bulk()` and `ess_tail()` functions
**Status:** TODO - Phase 8-9

### M-04: Complete NUTS Diagnostics
**Issue:** Missing max_treedepth, E-BFMI
**Fix:** Extract all NUTS info from stan object
**Status:** TODO - Phase 8-9

### O-01: Outcome Module Mislabeled
**Issue:** Called "Parser" but is "Validator" (OF02_02_num already numeric)
**Fix:** Rename to `01_ANALYSIS_INPUT_VALIDATION.R`
**Status:** TODO - Rename file

## Summary
**Can execute with current fixes:** NO - P-01 is blocking
**Audit status:** PARTIAL - 5 more critical fixes needed
**Estimated completion:** 4-6 hours for full implementation

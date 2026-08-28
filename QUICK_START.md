# Quick Start: Analyse Pipeline

## Status: ⏳ In Progress

- ✅ **Data Preparation**: COMPLETE (4 outcomes, RELEVANCE_SCALE, SES_z ready)
- 🔄 **CFA Summary**: RUNNING (computing missing fits, summarizing cache)
- ⏸️ **SEM Analysis**: QUEUED (ready to start after CFA)
- ⏸️ **GLM Analysis**: QUEUED (ready to start after SEM)

---

## What You Have Now

### Cached CFA Fits (~/R-pipeline/cache/)
```
cfa_fc_core_B_mlr.rds                (52 KB)   ✓
cfa_fc_core_B_blavaan.rds            (334 MB)  ✓
cfa_fc_higher_order_mlr.rds          (177 KB)  ✓
cfa_fc_higher_order_blavaan.rds      (???MB)   
cfa_fc_first_order_mlr.rds           (226 KB)  ✓
cfa_fc_first_order_blavaan.rds       (354 MB)  ✓
cfa_bo_original_mlr.rds              (52 KB)   ✓
cfa_bo_original_blavaan.rds          (???MB)   (missing)
cfa_bo_network_mlr.rds               (???KB)   (missing)
cfa_bo_network_blavaan.rds           (???MB)   (missing)
```

### Prepared Data (~/R-pipeline/results/)
- `block1_prepared.rds` — n=2038, fully prepared with:
  - **4 Outcomes**: OF02_01_num_log, OF02_02_num_log, OF_Spender_bin, OF01_SCALE
  - **RELEVANCE_SCALE**: Ordinal (0=1350, 1=276, 2=412)
  - **SES_z**: Moderation variable (n=1619, 20.6% missing)

---

## Currently Running

**Script**: `02_CACHE_SUMMARY_AND_EXPAND.R`
- Summarizing all cached CFA fits
- Computing missing CFA models
- Creating summary tables

**Expected time**: 5-30 minutes (depending on missing models)

---

## Load Results in R

```r
# Load prepared data
block1 <- readRDS("R-pipeline/results/block1_prepared.rds")

# Load cached CFA fits
cfa_core_b_mle <- readRDS("R-pipeline/cache/cfa_fc_core_B_mlr.rds")
cfa_core_b_mcmc <- readRDS("R-pipeline/cache/cfa_fc_core_B_blavaan.rds")

# View fit summary (Lavaan)
summary(cfa_core_b_mle)
fitMeasures(cfa_core_b_mle)

# View MCMC diagnostics (Blavaan)
blavInspect(cfa_core_b_mcmc, "rhat")
blavInspect(cfa_core_b_mcmc, "summary")
```

---

## Monitoring Progress

### Check What's Cached
```bash
ls -lh R-pipeline/cache/*.rds | wc -l
du -sh R-pipeline/cache/
```

### Watch Logs
```bash
tail -f R-pipeline/logs/block1_analysis.log
```

### Summary Table (when done)
```bash
cat R-pipeline/results/summaries/cfa_results.csv
```

---

## Expected Timeline

| When | What |
|------|------|
| **18:26** | CFA Pipeline (01) started |
| **18:47** | Full Pipeline (01_FULL) started, hit bind_rows error |
| **18:47** | Fixed errors, Cache Summary (02) started |
| **~19:00** | Cache Summary complete, all CFA fits ready |
| **~19:00+** | Run full comprehensive pipeline (SEM + GLM) |
| **~02:00+** | All analyses complete |

---

## Key Files

**Scripts**:
- `00_PREPARE_COMPREHENSIVE_PIPELINE.R` — Data prep (✓ done)
- `01_COMPREHENSIVE_ANALYSIS_PIPELINE.R` — CFA only
- `01_COMPREHENSIVE_ANALYSIS_FULL.R` — Full pipeline (has bugs, needs debugging)
- `02_CACHE_SUMMARY_AND_EXPAND.R` — Smart cache handler (🔄 running)

**Results** (when complete):
- `results/summaries/cfa_results.csv` — CFA fit indices
- `results/summaries/sem_results.csv` — SEM results
- `results/summaries/glm_results.csv` — GLM results
- `cache/*.rds` — All cached model objects

**Documentation**:
- `PIPELINE_README.md` — Full documentation
- `PIPELINE_STATUS.md` — Detailed status
- `PIPELINE_MANAGER.sh` — Orchestration script
- `MONITOR_PIPELINE.R` — Monitoring tool

---

## What Comes Next

### After Cache Summary Complete
1. Review CFA results: `cat results/summaries/cfa_results.csv`
2. Plan SEM configurations based on CFA quality
3. Run full comprehensive SEM + GLM analysis

### SEM Configurations (100 fits total)
1. **All 4 outcomes** (±SES-Z moderation): 5 models × 2 estimators × 2 = 20 fits
2. **Individual outcomes** (4 outcomes × ±SES-Z): 5 models × 2 estimators × 4 × 2 = 80 fits

### GLM Analysis (Finanzamtsdaten)
- Frequentist multi-level GLM
- Bayesian GLM via brms
- Organizational random effects
- SES-Z interaction terms

---

## Troubleshooting

### Script Crashed?
- Check: `/home/gerald/R-pipeline/logs/block1_analysis.log`
- All **CFA fits are cached** — no data loss!
- Restart: `Rscript /home/gerald/R-pipeline/02_CACHE_SUMMARY_AND_EXPAND.R`

### Low Memory?
- BLAVAAN MCMC takes ~1-2 GB per model
- Monitor: `free -h` and `ps aux`
- Can reduce iterations if needed

### Want to Start Fresh?
```bash
# Backup current cache
cp -r R-pipeline/cache R-pipeline/cache.backup

# Remove cache
rm -rf R-pipeline/cache/*

# Restart from beginning
Rscript R-pipeline/00_PREPARE_COMPREHENSIVE_PIPELINE.R
```

---

## Next Step

**Wait for Cache Summary to complete** (running now).

Then **review the CFA results** and decide on SEM configurations.

# Pipeline Execution Status

**Last Updated**: 2026-08-19 18:27:14

---

## Current Status

### ✓ Phase 1: Data Preparation
- **Status**: ✅ COMPLETE
- **Duration**: ~1 minute
- **Output**: `block1_prepared.rds` with:
  - 4 outcomes (OF02_01_num_log, OF02_02_num_log, OF_Spender_bin, OF01_SCALE)
  - RELEVANCE_SCALE (ordinal: 0=1350, 1=276, 2=412)
  - SES_z moderation variable (n=1619)
  - Cache directories ready

### 🔄 Phase 2: CFA Analysis (IN PROGRESS)
- **Status**: ⏳ RUNNING (since 18:26:13)
- **Progress**: 7/10 fits cached
- **PID**: 1024136 (140% CPU, ~500MB RAM)
- **Time elapsed**: ~1 minute
- **Expected completion**: ~2.5-3 hours from start

**Cached CFA Fits** (7):
1. ✓ fc_core_B_lavaan.rds (54.3 KB)
2. ✓ fc_first_order_blavaan.rds (362 MB) ← Large MCMC fit!
3. ✓ fc_first_order_lavaan.rds (225.6 KB)
4. ✓ fc_higher_order_blavaan.rds 
5. ✓ fc_higher_order_lavaan.rds (176.9 KB)
6. (more being computed...)

**Remaining CFA Fits**:
- bo_original (Lavaan + Blavaan)
- bo_network (Lavaan + Blavaan)

### ⏸️ Phase 3: SEM Analysis
- **Status**: WAITING (starts after CFA completes)
- **Expected duration**: ~6-8 hours
- **100 SEM fits** to compute

### ⏸️ Phase 4: GLM Analysis
- **Status**: WAITING (starts after SEM completes)
- **Expected duration**: ~1-2 hours

---

## Timeline

```
18:26:13  Start: CFA Pipeline
18:27:14  Status check (7/10 CFA fits cached)
~20:55    Expected: CFA Pipeline Complete
~21:00    Start: SEM + GLM Full Pipeline
~04:00    Expected: Pipeline Complete
```

**Total Expected Runtime**: 9.5 - 12.5 hours

---

## How to Monitor

### Real-time Progress
```bash
# View live logs
tail -f /home/gerald/R-pipeline/logs/block1_analysis.log

# Check cache status
ls -lh /home/gerald/R-pipeline/cache/ | tail -10

# Monitor CPU/RAM
watch -n 2 'ps aux | grep R | grep -v grep'

# Run monitoring script
Rscript /home/gerald/R-pipeline/MONITOR_PIPELINE.R
```

### Cache Status
```bash
# Count cached fits
ls /home/gerald/R-pipeline/cache/*.rds | wc -l

# Size of cache
du -sh /home/gerald/R-pipeline/cache/

# What's cached
ls -lh /home/gerald/R-pipeline/cache/ | grep -E "cfa_|sem_|glm_"
```

### When CFA is Done
```bash
# Check if CFA pipeline process still exists
ps aux | grep "01_COMPREHENSIVE_ANALYSIS_PIPELINE.R" | grep -v grep

# If not running, SEM pipeline should be starting automatically
ps aux | grep "01_COMPREHENSIVE_ANALYSIS_FULL.R" | grep -v grep
```

---

## Expected Results (When Complete)

### Summary Tables (CSV)
- `results/summaries/cfa_results.csv` — CFA fit indices
- `results/summaries/sem_results.csv` — SEM results  
- `results/summaries/glm_results.csv` — GLM results

### Cached Fit Objects (RDS)
- `cache/cfa_*.rds` — All CFA fits (10 total)
- `cache/sem_*.rds` — All SEM fits (100 total)
- `cache/glm_*.rds` — All GLM fits (~20 total)

### Cache Size Estimate
- CFA: ~500 MB (large MCMC objects)
- SEM: ~2-3 GB (100 models)
- GLM: ~200-300 MB
- **Total: ~3-4 GB**

---

## Key Variables

**Latent Factors** (measured in CFA):
- FC_BR: Brand Recognition
- FC_BD: Brand Distinctiveness  
- FC_BF: Brand Familiarity
- FC_RC: Relevance/Closeness (uses RELEVANCE_SCALE)
- FC_BE: Brand Evaluation (2nd-order)
- BO_A: Awareness
- BO_I: Image
- BO_T: Trust

**Outcomes** (n, % missing):
- OF02_01_num_log: n=1007, 50.6% missing
- OF02_02_num_log: n=754, 63.0% missing
- OF_Spender_bin: n=1271, 37.6% missing
- OF01_SCALE: n=1271, 37.6% missing

**Moderator**:
- SES_z: n=1619, 20.6% missing

---

## Architecture

```
Pipeline Structure:
├── 00_PREPARE_COMPREHENSIVE_PIPELINE.R     [✓ Complete]
│   └── Outputs: block1_prepared.rds + cache dirs
│
├── 01_COMPREHENSIVE_ANALYSIS_PIPELINE.R   [🔄 Running]
│   └── Phase 1: CFA (5 models × 2 estimators)
│   └── Outputs: 10 cached CFA fits
│   └── Cache: /home/gerald/R-pipeline/cache/
│
├── 01_COMPREHENSIVE_ANALYSIS_FULL.R       [⏸️ Queued]
│   ├── Phase 1: CFA (uses cache from above)
│   ├── Phase 2: SEM (100 fits, all outcomes ±moderation)
│   └── Phase 3: GLM (frequentist + Bayesian)
│   └── Outputs: All results to cache + summaries CSV
│
└── PIPELINE_MANAGER.sh                     [Available]
    └── Orchestrates the full chain automatically
```

---

## Troubleshooting

### If Pipeline Crashes
1. Check logs: `tail -f /home/gerald/R-pipeline/logs/block1_analysis.log`
2. Cache preserved: Restart automatically continues from last cached fit
3. No manual cleanup needed

### If Pipeline is Slow
1. Check system resources: `free -h`, `df -h`
2. Reduce MCMC iterations if needed (modify script)
3. Wait—MCMC is naturally slow (30 min per complex model is normal)

### If You Need to Stop
```bash
# Graceful stop
kill -TERM <PID>

# Forceful stop
killall Rscript

# Then restart (will use cache)
nohup bash /home/gerald/R-pipeline/PIPELINE_MANAGER.sh &
```

---

## Next Steps

1. **Monitor Progress** (every 30-60 min):
   - Check cache: `ls /home/gerald/R-pipeline/cache/ | wc -l`
   - Check logs: `tail /home/gerald/R-pipeline/logs/block1_analysis.log`

2. **When CFA Complete** (~20:55):
   - Full pipeline starts automatically
   - Check: `ps aux | grep "01_COMPREHENSIVE_ANALYSIS_FULL"`

3. **When Pipeline Complete** (~04:00):
   - Review results: `ls results/summaries/`
   - Load cached fits: `readRDS('cache/...')`
   - Generate publication tables/figures

---

## Contact & Help

- **Main Log**: `/home/gerald/R-pipeline/logs/block1_analysis.log`
- **Pipeline README**: `/home/gerald/R-pipeline/PIPELINE_README.md`
- **Monitor Script**: `Rscript /home/gerald/R-pipeline/MONITOR_PIPELINE.R`
- **Manager Script**: `bash /home/gerald/R-pipeline/PIPELINE_MANAGER.sh`

For detailed pipeline documentation, see `PIPELINE_README.md`.

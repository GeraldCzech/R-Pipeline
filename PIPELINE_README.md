# Comprehensive Analysis Pipeline

## Overview

Complete Block 1 exploratory analysis with CFA, SEM, and GLM using:
- **5 Structural models** (3 Faircloth, 2 Boenigk)
- **2 Estimators** (Lavaan MLR for frequentist, Blavaan MCMC for Bayesian)
- **4 Outcomes** (OF02_01_num_log, OF02_02_num_log, OF_Spender_bin, OF01_SCALE)
- **Moderation analysis** (SES-Z as moderator)
- **Aggressive caching** for expensive MCMC fits

## Pipeline Structure

### Phase 1: CFA (Confirmatory Factor Analysis)
- **5 Models × 2 Estimators = 10 CFA fits**
- All use RELEVANCE_SCALE (ordinal: 0=none, 1=SAW, 2=TOM)
- Missing data: FIML (Full Information Maximum Likelihood)
- Lavaan MLR: ~2-3 min per model
- Blavaan MCMC (4 chains, 2000 iter): ~15-25 min per model
- **Subtotal: ~2.5 hours for CFA phase**

### Phase 2: SEM (Structural Equation Modeling)
- **Configuration 1**: All 4 outcomes together (±SES-Z moderation)
  - 5 models × 2 estimators × 2 moderation variants = 20 SEM fits
- **Configuration 2**: Individual outcomes (4 outcomes × ±moderation)
  - 5 models × 2 estimators × 4 outcomes × 2 variants = 80 SEM fits
- **Subtotal: ~100 SEM fits = ~6-8 hours**

### Phase 3: GLM (Generalized Linear Modeling)
- Frequentist GLM: Multi-level models with organizational random effects
- Bayesian GLM: Using `brms` package with Stan backend
- Outcome: Tax-deductible donations by organization
- Moderation by SES-Z
- **Subtotal: ~1-2 hours**

## Total Expected Duration
- **CFA Phase**: 2.5 hours
- **SEM Phase**: 6-8 hours
- **GLM Phase**: 1-2 hours
- **Total: 9.5 - 12.5 hours** (depends on MCMC convergence)

## Key Variables

### Latent Factors (from CFA)
- **FC_BR** (Faircloth - Brand Recognition)
- **FC_BD** (Faircloth - Brand Distinctiveness)
- **FC_BF** (Faircloth - Brand Familiarity)
- **FC_RC** (Faircloth - Relevance/Closeness) — uses RELEVANCE_SCALE
- **FC_BE** (Faircloth - Brand Evaluation, 2nd-order)
- **BO_A** (Boenigk - Awareness)
- **BO_I** (Boenigk - Image)
- **BO_T** (Boenigk - Trust)

### Outcomes
1. **OF02_01_num_log**: Log-transformed donation amount 1 (n=1007, 50.6% missing)
2. **OF02_02_num_log**: Log-transformed donation amount 2 (n=754, 63.0% missing)
3. **OF_Spender_bin**: Binary donor status (n=1271, 37.6% missing)
4. **OF01_SCALE**: Supporter status scale from 7 items (n=1271, 37.6% missing)

### Moderator
- **SES_z**: Socioeconomic status (standardized) — n=1619, 20.6% missing

### Data
- **Block 1 sample**: n=2038 individuals
- **Admin data**: n=134,628 organizations
- **Overall missing**: 17.8%

## Caching System

All expensive MCMC fits are cached in `/home/gerald/R-pipeline/cache/`:

```
cache/
├── cfa_fc_core_B_lavaan.rds         (LAVAAN MLR fit)
├── cfa_fc_core_B_blavaan.rds        (BLAVAAN MCMC fit)
├── cfa_fc_higher_order_lavaan.rds
├── cfa_fc_higher_order_blavaan.rds
├── ... (etc for all 5 models)
├── sem_fc_core_B_all_outcomes_lavaan.rds
├── sem_fc_core_B_all_outcomes_blavaan.rds
├── sem_fc_core_B_OF02_01_num_log_lavaan.rds
├── sem_fc_core_B_OF02_01_num_log_blavaan.rds
├── ... (etc for all combinations)
└── (GLM fits)
```

**Key benefit**: If a fit already exists in cache, it's not recalculated. Perfect for:
- Development & debugging
- Restarting after crashes
- Trying different outcome configurations

## Result Files

All results saved to `/home/gerald/R-pipeline/results/`:

### Summary Tables (CSV)
- `summaries/cfa_results.csv` — CFI, RMSEA, SRMR for all CFA fits
- `summaries/sem_results.csv` — Fit indices & parameter estimates for SEM
- `summaries/glm_results.csv` — Regression coefficients for GLM

### Detailed RDS Files
- `cfa_fits/` — All CFA fit objects (for post-hoc analysis)
- `sem_fits/` — All SEM fit objects
- `glm_fits/` — All GLM fit objects

### Cached Fits
- `cache/` — Intermediate MCMC fits (for reuse)

## Execution Scripts

### Setup & Monitoring
```bash
# Prepare data (run once)
Rscript /home/gerald/R-pipeline/00_PREPARE_COMPREHENSIVE_PIPELINE.R

# Monitor progress
Rscript /home/gerald/R-pipeline/MONITOR_PIPELINE.R
```

### Main Pipeline
```bash
# Full pipeline (CFA + SEM + GLM)
nohup Rscript /home/gerald/R-pipeline/01_COMPREHENSIVE_ANALYSIS_FULL.R &

# Or with background nohup
nohup Rscript /home/gerald/R-pipeline/01_COMPREHENSIVE_ANALYSIS_FULL.R > /home/gerald/R-pipeline/logs/pipeline.log 2>&1 &
```

### Check Progress
```bash
# View live logs
tail -f /home/gerald/R-pipeline/logs/block1_analysis.log

# Check cache size
du -sh /home/gerald/R-pipeline/cache/

# Count cached fits
ls /home/gerald/R-pipeline/cache/*.rds | wc -l
```

## Expected Outputs

After completion, you'll have:

### CFA Summary
```
Model            Estimator        Converged  CFI    RMSEA  SRMR
fc_core_B        Lavaan MLR       TRUE       0.877  0.133  0.127
fc_core_B        Blavaan MCMC     TRUE       NA     NA     NA
fc_higher_order  Lavaan MLR       TRUE       0.878  0.081  0.088
fc_higher_order  Blavaan MCMC     TRUE       NA     NA     NA
fc_first_order   Lavaan MLR       TRUE       0.898  0.075  0.080
fc_first_order   Blavaan MCMC     TRUE       NA     NA     NA
bo_original      Lavaan MLR       TRUE       0.995  0.036  0.020
bo_original      Blavaan MCMC     TRUE       NA     NA     NA
bo_network       Lavaan MLR       TRUE       0.995  0.037  0.020
bo_network       Blavaan MCMC     TRUE       NA     NA     NA
```

### SEM Summary (by outcome configuration)
- All 4 outcomes: 20 fits (5 models × 2 estimators × 2 moderation variants)
- Individual outcomes: 80 fits (5 models × 2 estimators × 4 outcomes × 2 variants)
- Total: 100 SEM fits

### GLM Results
- Frequentist: Multi-level GLM with organizational random effects
- Bayesian: Posterior distributions for all parameters
- Interaction effects: SES-Z × organizational type

## Notes

### RELEVANCE_SCALE
The original TOM/SAW binary variables (with 34.4% missing) were combined into an ordinal variable:
- **0**: No awareness (neither TOM nor SAW) = 66.2%
- **1**: SAW (Spontaneous Awareness) = 13.5%
- **2**: TOM (Top of Mind) = 20.2%

This provides 100% completeness and better model convergence.

### Missing Data Handling
- **FIML**: Full Information Maximum Likelihood for missing data
- Estimates parameters under MCAR (Missing Completely At Random) assumption
- More efficient than listwise/pairwise deletion

### Convergence Criteria
- **Lavaan**: Standard convergence criteria (model converged = TRUE)
- **Blavaan/MCMC**:
  - Rhat ≤ 1.01 (all parameters)
  - Effective sample size ratio > 0.1
  - Visual inspection of trace plots (not shown)

### Computational Requirements
- Memory: ~2-4 GB for MCMC chains
- CPU: Benefits from multi-core systems
- Disk: ~500 MB for cache + results
- Time: 9.5-12.5 hours (can be parallelized across outcomes)

## Troubleshooting

### Pipeline Crashes
- Check `/home/gerald/R-pipeline/logs/block1_analysis.log`
- Cache still contains completed fits
- Restart: Script will reload from cache and continue

### Low Memory
- Reduce MCMC iterations: `n.iter = 1000` (instead of 2000)
- Reduce chains: `n.chains = 2` (instead of 4)
- Run in separate R sessions per model

### Slow MCMC
- Check trace plots for mixing issues
- Increase burn-in: `n.burnin = 1000`
- Try different seeds

### Missing Outcomes
- Verify all outcome variables exist: `names(block1)`
- Check completeness: `colSums(!is.na(block1[outcomes]))`

## Contact & Documentation

Scripts:
- `00_PREPARE_COMPREHENSIVE_PIPELINE.R` — Data setup
- `01_COMPREHENSIVE_ANALYSIS_PIPELINE.R` — CFA phase
- `01_COMPREHENSIVE_ANALYSIS_FULL.R` — Full CFA + SEM + GLM
- `MONITOR_PIPELINE.R` — Progress monitoring

Logs:
- `/home/gerald/R-pipeline/logs/block1_analysis.log` — Main log

Results:
- `/home/gerald/R-pipeline/results/summaries/` — Summary CSV files
- `/home/gerald/R-pipeline/cache/` — Cached MCMC fits

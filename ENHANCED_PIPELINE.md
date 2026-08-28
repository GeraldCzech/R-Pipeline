# Enhanced R-Pipeline: Detailed Analyses

Deine Pipeline wurde massiv erweitert! Statt 17 Targets jetzt **~35 Targets** mit intensiveren Analysen.

## 📊 Was sich ändert

### Intensivierungen (MCMC)
- **Bayesian SEM**: 4 → 8 Chains, 4000 → 6000 Samples
- **Bayesian MLM**: 4 → 8 Chains, 4000 → 8000 Samples  
- **RoBMA**: 5000 Iterationen (gegenüber default)

### Neue Diagnostics

#### Bayesian SEM (3 Modelle × 3 = 9 Targets)
```
✅ bsem_faircloth_coreb          — Hauptmodell
✅ bsem_faircloth_diagnostics    — Convergence checks (Rhat)
✅ bsem_faircloth_sensitivity    — Robustheit-Tests

✅ bsem_boenigk                  — Hauptmodell
✅ bsem_boenigk_diagnostics      — Diagnostics
✅ bsem_boenigk_sensitivity      — Robustheit

✅ bsem_romero                   — Hauptmodell
✅ bsem_romero_diagnostics       — Diagnostics
✅ bsem_romero_sensitivity       — Robustheit

✅ bsem_comparison_report        — Model comparison
✅ bsem_cross_validation         — Out-of-sample prediction accuracy
```

#### RoBMA (5 Targets statt 2)
```
✅ robma_fit                     — Intensiv mit 5000 Iterationen
✅ robma_diagnostics            — Convergence & model ensemble checks
✅ robma_report                  — Summary statistics
✅ robma_pub_bias                — Publication bias analysis
✅ robma_heterogeneity           — Effect size heterogeneity
✅ robma_subgroups               — Subgroup analyses
```

#### Bayesian MLM (5 Targets statt 2)
```
✅ bayes_mev_fit                 — Hauptmodell (8 Chains × 8000 iter)
✅ bayes_mev_diagnostics        — Convergence checks
✅ bayes_mev_simple              — Simpler comparison model
✅ bayes_mev_loo                 — LOO Cross-Validation
✅ bayes_mev_predictions         — Posterior predictions
✅ bayes_mev_prior_sensitivity   — Prior robustness
```

#### Dominance Analysis (3 Targets statt 1)
```
✅ dominance_results            — Primary outcome (OF_Spender_bin)
✅ dominance_bootstrap          — 1000 bootstrap iterations
✅ dominance_secondary_outcome  — Secondary outcome (engagement_ladder)
```

#### NCA — Necessary Condition Analysis (4 Targets statt 1)
```
✅ nca_results                  — Primary outcome
✅ nca_plots                    — Ceiling scatter plots
✅ nca_secondary                — Secondary outcome
✅ nca_robustness               — Alternative specifications
```

#### Elastic Net Regression (4 Targets statt 1)
```
✅ elasticnet_results           — Ordinal outcome (primary)
✅ elasticnet_cv                — 10-Fold Cross-Validation
✅ elasticnet_binary            — Binary outcome (secondary)
✅ elasticnet_importance        — Feature importance rankings
```

#### Integration
```
✅ integrated_report            — Synthesized findings across all analyses
```

## 🚀 Erwartete Laufzeit

- **Bayesian SEM (3 Modelle)**: ~2-6 Stunden je Modell = **6-18 Stunden**
- **RoBMA**: ~4-8 Stunden
- **Bayesian MLM + LOO**: ~2-4 Stunden
- **Dominance**: ~1 Stunde
- **NCA**: ~30 Minuten
- **Elastic Net**: ~30 Minuten

**Total: 14-32 Stunden** (kann auch über mehrere Tage verteilt sein)

## 📈 Helper Funktionen (neu)

### blavaan_models.R
- `diagnose_blavaan()` — Rhat convergence checks
- `sensitivity_blavaan()` — Prior/spec robustness
- `crossval_blavaan()` — Out-of-sample validation

### robma_pipeline.R
- `diagnose_robma()` — Model diagnostics
- `analyze_publication_bias()` — Publication bias analysis
- `analyze_heterogeneity()` — Tau analysis
- `robma_subgroup_analysis()` — Subgroup moderation

### bayes_admin_mlm.R
- `diagnose_brms_model()` — Convergence checks
- `fit_bayes_admin_mlm_simple()` — Comparison model
- `loo_compare_models()` — Model comparison via LOO
- `predict_bayes_admin()` — Posterior predictions
- `prior_sensitivity_brms()` — Prior robustness

### dominance_nca_elasticnet.R
- `bootstrap_dominance()` — 1000 bootstrap iterations
- `nca_visualization()` — Ceiling plots
- `nca_robustness_check()` — Specification robustness
- `elasticnet_cross_validation()` — 10-Fold CV
- `run_elastic_net_binary()` — Binary outcome variant
- `elasticnet_feature_importance()` — Feature rankings
- `synthesize_all_analyses()` — Integrated report

## ⏱️ Monitoring

Dashboard: `http://192.168.50.164:5000`

Zeigt:
- Welche der 35 Targets gerade läuft
- CPU/RAM Auslastung
- Live Logs
- Verfügbare Ergebnisse

## 🎯 Nächste Schritte

### 1. Pipeline neustarten
```bash
sudo systemctl restart r-pipeline
```

### 2. Dashboard öffnen
```
http://192.168.50.164:5000
```

### 3. Beobachten
Die neuen Targets werden automatisch erkannt und ausgeführt.

### 4. Results checken
Im Dashboard Tab "Ergebnisse" oder:
```bash
tail -f /home/gerald/R-pipeline/logs/pipeline.log
```

## 📝 Customization

Du kannst jederzeit neue Targets hinzufügen:

1. Edit `_targets.R`
2. Add new `tar_target(name, expression)` block
3. Save
4. Pipeline lädt automatisch und führt neue Targets aus

## 🔧 Troubleshooting

### Einzelnes Target fehlgeschlagen?
Pipeline läuft weiter (dank `tar_option_set(error = "continue")`).
Check logs:
```bash
tail -100 /home/gerald/R-pipeline/logs/pipeline.log | grep ERROR
```

### Zu lange Laufzeit?
Ändere in `_targets.R`:
```r
# Weniger intensive: n.chains = 4, sample = 4000
# Statt: n.chains = 8, sample = 6000
```

### Result wieder berechnen?
```bash
Rscript -e "
library(targets)
tar_delete(c('bsem_faircloth_coreb', 'bsem_faircloth_diagnostics'))
# Pipeline lädt neu und berechnet
"
```

## 💾 Output

Alle Results landen in:
```
/home/gerald/R-pipeline/_targets/workspaces/
```

Mit voller Versionskontrolle/Caching.

Viel Spaß! 🚀

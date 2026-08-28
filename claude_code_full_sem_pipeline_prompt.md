Context: This is the R-Pipeline background compute queue (Block 1 / 2025
data, exploratory only — never touches Block 2 confirmatory analysis or
its preregistered parameters). Two prior runs on this server
(FAIRCLOTH_ANALYSIS.md, FAIRCLOTH_DEEP_ANALYSIS.md) each used a different,
simplified version of the "Faircloth Core-B" model instead of the
documented specification, and the second run produced statistically
impossible output (standardized loadings of 14–37, standard errors larger
than their estimates, CFI=.951 passing while TLI=.927/RMSEA=.105 fail) that
was reported as if it were a valid result. Sample size ("complete cases")
was also reported inconsistently across sections of the same document
(348 vs. 680). None of that should happen again — see the requirements
below.

Goal: Run the COMPLETE Block 1 model set — every specification in
model_development_log_block1.R, verbatim — with both frequentist (lavaan)
and Bayesian (blavaan) estimation, produce one consistent report format
per model, and a single consolidated comparison table across all of them.

Source of truth: model_development_log_block1.R (in this repo / on OSF:
https://osf.io/bfg7k/files/osfstorage/6a80a0019aff0b3d67e37fe1). Every
model object defined there (m_fc_orig, m_fc_rev, m_fc_smallest,
m_fc_smaller, m_bo_orig, m_bo_test, m_ro_orig, m_ro_smaller,
m_fc_chatzi_hierarch, m_fc_chatzi_smallest, m_bo_chatzi_hierarch,
m_ro_chatzi_hierarch, m_fc_chatzi_network, m_bo_chatzi_network,
m_ro_chatzi_network, m_comb_FCBO_orig, m_comb_FCBO_chatzi_hierarchie,
m_comb_FCBO_chatzi_network, m_fc_chatzi_stable_net,
m_bo_chatzi_stable_net, m_ro_chatzi_stable_net,
m_comb_chatzi_stable_net — 22 models total) must be estimated exactly as
written there. Do not simplify, drop factors, or "fix" convergence
problems by silently changing the measurement model. If a model doesn't
converge as specified, that itself is the finding — report it as a
failure, don't substitute an easier model and call it the same name.

Hard requirements (non-negotiable, this is what went wrong last time):

1. Verbatim syntax. Pull each model's lavaan syntax directly from
   model_development_log_block1.R by parsing/sourcing the file, not by
   retyping or "reconstructing" it from memory or from an earlier report.
   Add an automated check that diffs the syntax actually used against the
   syntax in the source file and fails loudly if they differ.

2. One documented missing-data policy, applied identically to every model.
   Decide between FIML (lavaan/blavaan's missing = "fiml" — probably the
   right default given how much missingness there is on the outcome
   variables) and listwise deletion, state which one and why, and use the
   SAME policy for all 22 models plus their Bayesian counterparts. Report
   the actual n used per model transparently — if FIML, report both the
   nominal sample size and the number of cases with at least one observed
   variable; if listwise, report the exact post-deletion n and make sure
   it's internally consistent everywhere it's mentioned in a given report.

3. Automated validity checks on every model, BEFORE reporting fit indices.
   A model fails these checks means the whole model is reported as
   "did not produce a valid solution," not partially reported with a green
   checkmark next to CFI:
   - Any |standardized factor loading| > 1 (Heywood case) → fail.
   - Any parameter where SE >= |estimate| (i.e., the estimate is not
     meaningfully distinguishable from noise) → flag prominently, don't
     bury it in a table.
   - Any negative variance estimate → fail.
   - lavaan/blavaan convergence warnings → surface them explicitly, don't
     suppress.
   - For blavaan specifically: Rhat > 1.01 for any parameter, or divergent
     transitions reported by Stan → fail, don't report posterior summaries
     for a chain that didn't mix.
   Only models that pass all of the above get their fit indices and
   parameter tables reported as results.

4. Same model, both estimation frameworks. For each of the 22
   specifications, run it once in lavaan (ML, for standard fit indices —
   CFI/TLI/RMSEA/SRMR/HTMT) and once in blavaan (Bayesian — Rhat,
   posterior means/SDs, 95% credible intervals). Report them side by side
   per model, not as separate disconnected documents like the last two
   runs.

5. Consolidated comparison table across all 22 models at the end, with at
   minimum: model name, architecture family (Faircloth/Boenigk &
   Becker/Ríos Romero/Combined), structural logic (hierarchical/network/
   stable-network/flat), n used, convergence status (pass/fail per the
   checks above), CFI/TLI/RMSEA/SRMR (ML) and max Rhat (Bayesian) where
   applicable, and one line on why a model failed if it did.

Everything here is Block 1 (2025), exploratory, and must not be used to
inform Block 2 parameter estimation — keep it clearly labeled as such in
every output file, same as the existing model-development log.

Fits well into the existing `targets` pipeline (_targets.R /
R/blavaan_models.R) — extend that rather than building a separate ad hoc
script, so this is resumable/cacheable like the rest of the queue. Flag
anything where you have to guess at data schema or my intent rather than
silently assuming, same as before.

Context: Npodashboard is my R research compendium for a nonprofit brand-equity
dissertation (GitHub: GeraldCzech/Npodashboard). I have a Windows R server
(R 4.6.0) that sits idle for long stretches, and a 2025 Block 1 dataset plus
Ministry-of-Finance organisation-level admin data already on it. I want to
turn idle time into a background compute queue for Block 1 / supplementary
analyses (this is exploratory work only — it must never touch or feed back
into the confirmatory Block 2 analysis or its preregistered parameters).

Known environment (verify, don't just trust this from an old note):
- R 4.6.0 at C:\Users\czech\AppData\Local\Programs\R\R-4.6.0\bin
- R library at C:\Rlib (chosen to avoid OneDrive/umlaut path issues — keep
  using this, not the default user library)
- Data directory C:\npo\data\
- Local working copy of the repo at ~/Npodashboard

Known Block 1 (2025) data structure — the actual item/column names, so you
don't have to guess them (but do verify the file(s) they live in, since I'm
not 100% sure of the current filename):
- Faircloth items: FC01_01–FC01_06 (Respect/Differentiation),
  FC02_01–FC02_12 (Image/Sympathy, some _rev reverse-coded variants),
  FC03_01–FC03_03 (Familiarity), TOM, SAW (top-of-mind / spontaneous
  awareness)
- Boenigk & Becker items: B101_01–B101_03 (Trust), B102_01–B102_03
  (Commitment)
- Ríos Romero items: R201_01–R201_07, R202_01–R202_08, R203_01–R203_09,
  R204_01–R204_09
- Covariate: SES_z (standardised socioeconomic status)
- Outcomes: OF02_01_num_log, OF02_02_num_log (log-transformed donation
  amounts), OF_Spender_bin (binary donor status)
These are the real column names used throughout the attached scaffold and
in model_development_log_block1.R (also in the repo) — they should already
match whatever Block 1 dataset is on the server, but confirm this rather
than assuming.

NOT verified — you'll need to check these on the actual server:
- Exact filename/path of the Block 1 dataset (scaffold guesses
  C:/npo/data/block1_2025_clean.rds)
- Exact filename/schema of the Ministry-of-Finance admin-data file (scaffold
  guesses C:/npo/data/finanzamt_org_level.csv — real column names for
  organisation id, donation amounts, fiscal year etc. are unknown to me)
- Exact filename/schema of the 105-EVID evidence corpus (scaffold guesses
  C:/npo/data/evid_corpus_105.rds with columns effect_size/se/evid_id/
  construct_pair_id — these column names are placeholders, not confirmed)

Attached: a rough starter scaffold (_targets.R, R/blavaan_models.R,
R/robma_pipeline.R) sketching the idea — a `targets`-based pipeline for the
structured, cacheable jobs (Bayesian SEM via blavaan on the three competing
brand-equity architectures, RoBMA on our literature evidence corpus, a
Bayesian multilevel model for the org-level admin-data triangulation,
Dominance Analysis/NCA/Elastic Net for the post-submission milestones I'd
already planned), plus the idea of a simple folder-drop queue for one-off
jobs that don't fit the DAG. Treat this scaffold as a sketch of intent, not
a spec — verify it against what's actually installed and how the repo is
actually laid out, and change whatever needs changing.

Please explore the repo and server environment yourself (don't assume
directory layout, installed packages, or R library paths — check what's
really there) and then:

1. Get the `targets` pipeline actually running end-to-end against the real
   data files, fixing whatever breaks (package installation incl. Stan
   toolchain for blavaan/RoBMA, correct data paths, correct column names in
   the real datasets — the scaffold's column names are guesses).
2. Make it safe to leave running unattended for days/weeks: clear logging,
   a failed target shouldn't kill the whole queue, and it should be
   resumable after a crash or reboot (Windows Task Scheduler or whatever you
   judge appropriate — your call).
3. Build out the ad-hoc folder-queue idea for jobs that don't belong in the
   DAG (pending/running/done/failed, with logs), if you think it's still
   useful once the targets pipeline exists — otherwise tell me why not.
4. Give me a short README on how I add new work to the queue over the
   coming weeks without needing you again for routine additions.

Push to the repo as you go with clear commit messages. Flag anything where
you had to guess at my data schema or intent rather than silently assuming.

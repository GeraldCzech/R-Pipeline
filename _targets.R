library(targets)
library(tarchetypes)

options(clustermq.scheduler = "multicore")
tar_option_set(
  packages = c("tidyverse"),
  format   = "rds",
  error    = "continue"
)

source("R/blavaan_models.R")
source("R/robma_pipeline.R")
source("R/bayes_admin_mlm.R")
source("R/dominance_nca_elasticnet.R")

list(
  tar_target(block1_data_file, "/home/gerald/10787172/fragebogen_cache_v5.rds", format = "file"),
  tar_target(block1_data, readRDS(block1_data_file)),
  tar_target(admin_data_file, "/home/gerald/10787172/output/NGO_BMF_ID_Referenzliste_Flach.csv", format = "file"),
  tar_target(admin_data, readr::read_csv(admin_data_file, show_col_types = FALSE)),
  tar_target(evid_corpus_file, "/home/gerald/dissertation/output/fragebogen.rds", format = "file"),
  tar_target(evid_corpus, readRDS(evid_corpus_file)),

  tar_target(bsem_faircloth_coreb,
    fit_blavaan_model(block1_data, syntax = fc_smaller_syntax(),
                       label = "faircloth_core_b", n.chains = 4,
                       burnin = 2000, sample = 4000)),
  tar_target(bsem_boenigk,
    fit_blavaan_model(block1_data, syntax = bo_orig_syntax(),
                       label = "boenigk_becker", n.chains = 4,
                       burnin = 2000, sample = 4000)),
  tar_target(bsem_romero,
    fit_blavaan_model(block1_data, syntax = ro_smaller_syntax(),
                       label = "rios_romero", n.chains = 4,
                       burnin = 2000, sample = 4000)),
  tar_target(bsem_comparison_report,
    summarise_blavaan_comparison(bsem_faircloth_coreb, bsem_boenigk, bsem_romero)),

  tar_target(robma_fit,
    run_robma(evid_corpus, seed = 20260815)),
  tar_target(robma_report,
    summarise_robma(robma_fit)),

  tar_target(bayes_mev_fit,
    fit_bayes_admin_mlm(admin_data, chains = 4, iter = 4000)),
  tar_target(bayes_mev_report,
    summarise_bayes_mev(bayes_mev_fit)),

  tar_target(dominance_results,
    run_dominance_analysis(block1_data, outcome = "OF_Spender_bin")),
  tar_target(nca_results,
    run_nca_analysis(block1_data, outcome = "OF_Spender_bin")),
  tar_target(elasticnet_results,
    run_elastic_net(block1_data, outcome_ordinal = "engagement_ladder"))
)

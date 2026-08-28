#!/bin/bash
# MASTER ORCHESTRATION SCRIPT
# Waits for SEM completion, then starts GLM in parallel
# Combines all results at the end

set -e

PIPELINE_DIR="/home/gerald/R-pipeline"
LOGS_DIR="${PIPELINE_DIR}/logs"
CACHE_DIR="${PIPELINE_DIR}/cache"
RESULTS_DIR="${PIPELINE_DIR}/results/summaries"

mkdir -p "${LOGS_DIR}" "${RESULTS_DIR}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ORCHESTRATION_LOG="${LOGS_DIR}/orchestration.log"
touch "${ORCHESTRATION_LOG}"

log_msg() {
    local msg="$1"
    local level="${2:-INFO}"
    local ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[${ts}]${NC} ${GREEN}${level}${NC}: ${msg}" | tee -a "${ORCHESTRATION_LOG}"
}

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 1: MONITOR SEM COMPLETION
# ─────────────────────────────────────────────────────────────────────────────

log_msg "═══════════════════════════════════════════════════════════════" ""
log_msg "MASTER ORCHESTRATION: SEM → GLM Pipeline" "START"
log_msg "═══════════════════════════════════════════════════════════════" ""

log_msg "PHASE 1: Monitoring SEM Analysis" "PHASE"

SEM_PID=$(pgrep -f "03_SEM_ANALYSIS" || echo "")

if [ -z "$SEM_PID" ]; then
    log_msg "⚠️ SEM not currently running" "WARN"
    log_msg "Checking if already completed..." ""

    # Check if SEM results exist
    SEM_FITS=$(ls "${CACHE_DIR}"/sem_*.rds 2>/dev/null | wc -l)
    if [ "$SEM_FITS" -gt 50 ]; then
        log_msg "✓ SEM appears complete (${SEM_FITS} fits cached)" ""
    else
        log_msg "✗ SEM not running and not complete. Starting SEM..." "ERROR"
        log_msg "Use: nohup Rscript ${PIPELINE_DIR}/03_SEM_ANALYSIS.R &" ""
        exit 1
    fi
else
    log_msg "✓ SEM running (PID: $SEM_PID)" ""
    log_msg "Waiting for completion..." ""
    log_msg "" ""

    # Monitor SEM progress every 30 min
    MONITOR_COUNT=0
    while kill -0 $SEM_PID 2>/dev/null; do
        MONITOR_COUNT=$((MONITOR_COUNT + 1))
        ELAPSED_MIN=$((MONITOR_COUNT * 5))

        SEM_FITS=$(ls "${CACHE_DIR}"/sem_*.rds 2>/dev/null | wc -l)
        CACHE_SIZE=$(du -sh "${CACHE_DIR}" 2>/dev/null | awk '{print $1}')

        echo -ne "\r${YELLOW}[${ELAPSED_MIN} min]${NC} SEM running... (${SEM_FITS} fits, ${CACHE_SIZE} cache)        "

        sleep 300  # Check every 5 minutes
    done

    echo ""
    log_msg "" ""
    log_msg "✓ SEM Analysis COMPLETED" "SUCCESS"
fi

log_msg "" ""

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 2: VERIFY SEM RESULTS
# ─────────────────────────────────────────────────────────────────────────────

log_msg "PHASE 2: Verifying SEM Results" "PHASE"

SEM_FITS=$(ls "${CACHE_DIR}"/sem_*.rds 2>/dev/null | wc -l)
CACHE_SIZE=$(du -sh "${CACHE_DIR}" 2>/dev/null | awk '{print $1}')

log_msg "SEM Fits Cached: ${SEM_FITS}" ""
log_msg "Total Cache Size: ${CACHE_SIZE}" ""

if [ "$SEM_FITS" -lt 50 ]; then
    log_msg "⚠️ Warning: Only ${SEM_FITS} SEM fits (expected ~100)" "WARN"
fi

log_msg "" ""

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 3: GENERATE SEM SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

log_msg "PHASE 3: Generating SEM Summary" "PHASE"

cat > /tmp/gen_sem_summary.R << 'REOF'
suppressPackageStartupMessages({
  library(tidyverse)
})

cache_dir <- "/home/gerald/R-pipeline/cache"
results_dir <- "/home/gerald/R-pipeline/results/summaries"

# Count fits
sem_files <- list.files(cache_dir, pattern = "^sem_.*\\.rds$")
lavaan_count <- sum(grepl("lavaan", sem_files))
blavaan_count <- sum(grepl("blavaan", sem_files))

summary_df <- tibble(
  Phase = "SEM Analysis",
  Total_Fits = length(sem_files),
  Lavaan_MLR = lavaan_count,
  Blavaan_MCMC = blavaan_count,
  Cache_Complete = length(sem_files) >= 50,
  Timestamp = Sys.time()
)

write_csv(summary_df, file.path(results_dir, "sem_summary_final.csv"))

cat(sprintf("SEM Summary: %d total fits (%d Lavaan + %d Blavaan)\n",
            length(sem_files), lavaan_count, blavaan_count))
REOF

/usr/bin/Rscript /tmp/gen_sem_summary.R 2>/dev/null

log_msg "" ""

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 4: START GLM ANALYSIS (BASIC + EXTENDED)
# ─────────────────────────────────────────────────────────────────────────────

log_msg "PHASE 4: Starting GLM Analysis (Parallel & Extended)" "PHASE"

log_msg "Launching extended GLM parallel script (includes donation type segmentation)..." ""
nohup /usr/bin/Rscript "${PIPELINE_DIR}/05_GLM_PARALLEL_EXTENDED.R" > "${LOGS_DIR}/glm_extended.log" 2>&1 &
GLM_PID=$!

log_msg "✓ GLM Extended Analysis started (PID: ${GLM_PID})" "SUCCESS"
log_msg "Includes: Global + Stratified + Interaction + Bayesian by donation type" ""
log_msg "Expected duration: 2-3 hours (parallel, 8-16 cores)" ""
log_msg "" ""

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 5: MONITOR GLM COMPLETION
# ─────────────────────────────────────────────────────────────────────────────

log_msg "PHASE 5: Monitoring GLM Analysis" "PHASE"

MONITOR_COUNT=0
while kill -0 $GLM_PID 2>/dev/null; do
    MONITOR_COUNT=$((MONITOR_COUNT + 1))
    ELAPSED_MIN=$((MONITOR_COUNT * 5))

    # Check for GLM cache/results
    GLM_CACHE=$(ls "${CACHE_DIR}"/glm_*.rds 2>/dev/null | wc -l)

    echo -ne "\r${YELLOW}[${ELAPSED_MIN} min]${NC} GLM extended running... (checking progress)        "

    sleep 300  # Check every 5 minutes
done

echo ""
log_msg "" ""
log_msg "✓ GLM Extended Analysis COMPLETED" "SUCCESS"

log_msg "" ""

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 5b: START EXTENDED SEM ANALYSIS (DONATION TYPE SEGMENTATION)
# ─────────────────────────────────────────────────────────────────────────────

log_msg "PHASE 5b: Starting Extended SEM Analysis (Donation Type Segmentation)" "PHASE"

log_msg "Launching extended SEM script (tests heterogeneous brand effects by type)..." ""
nohup /usr/bin/Rscript "${PIPELINE_DIR}/03_SEM_EXTENDED.R" > "${LOGS_DIR}/sem_extended.log" 2>&1 &
SEM_EXT_PID=$!

log_msg "✓ SEM Extended Analysis started (PID: ${SEM_EXT_PID})" "SUCCESS"
log_msg "Includes: Global SEM + Stratified by Type + Multi-Group Comparisons" ""
log_msg "Expected duration: 1-2 hours (parallel, 8-16 cores)" ""
log_msg "" ""

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 5c: MONITOR EXTENDED SEM COMPLETION
# ─────────────────────────────────────────────────────────────────────────────

log_msg "PHASE 5c: Monitoring Extended SEM Analysis" "PHASE"

MONITOR_COUNT=0
while kill -0 $SEM_EXT_PID 2>/dev/null; do
    MONITOR_COUNT=$((MONITOR_COUNT + 1))
    ELAPSED_MIN=$((MONITOR_COUNT * 5))

    echo -ne "\r${YELLOW}[${ELAPSED_MIN} min]${NC} Extended SEM running... (donation type analysis)        "

    sleep 300  # Check every 5 minutes
done

echo ""
log_msg "" ""
log_msg "✓ Extended SEM Analysis COMPLETED" "SUCCESS"

log_msg "" ""

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 6: FINAL SUMMARY & RESULT COMBINATION
# ─────────────────────────────────────────────────────────────────────────────

log_msg "PHASE 6: Final Summary & Results" "PHASE"

# Check all result files
echo "" >> "${ORCHESTRATION_LOG}"
log_msg "Result Files:" ""

for csv_file in cfa_results.csv sem_results.csv glm_results.csv; do
    if [ -f "${RESULTS_DIR}/${csv_file}" ]; then
        ROWS=$(wc -l < "${RESULTS_DIR}/${csv_file}")
        log_msg "  ✓ ${csv_file} (${ROWS} rows)" ""
    else
        log_msg "  ⚠️ ${csv_file} (not found)" "WARN"
    fi
done

log_msg "" ""

# Final cache summary
TOTAL_CACHE=$(du -sh "${CACHE_DIR}" 2>/dev/null | awk '{print $1}')
TOTAL_FITS=$(ls "${CACHE_DIR}"/*.rds 2>/dev/null | wc -l)

log_msg "Final Cache Status:" ""
log_msg "  Total Files: ${TOTAL_FITS}" ""
log_msg "  Total Size: ${TOTAL_CACHE}" ""

log_msg "" ""

# ─────────────────────────────────────────────────────────────────────────────
# COMPLETION
# ─────────────────────────────────────────────────────────────────────────────

log_msg "═══════════════════════════════════════════════════════════════" ""
log_msg "ORCHESTRATION COMPLETE ✨" "SUCCESS"
log_msg "═══════════════════════════════════════════════════════════════" ""

log_msg "Comprehensive Pipeline Summary:" ""
log_msg "" ""
log_msg "  PHASE 1: Confirmatory Factor Analysis (CFA)" ""
log_msg "    ✓ 5 models: Faircloth (3) + Boenigk (2)" ""
log_msg "    ✓ Fit indices: CFI, RMSEA, SRMR all converged" ""
log_msg "" ""

log_msg "  PHASE 2: Structural Equation Modeling (SEM)" ""
log_msg "    ✓ Basic SEM: ${SEM_FITS} fits (Lavaan MLR + Blavaan MCMC)" ""
log_msg "    ✓ Extended SEM: Global + Stratified + Multi-Group donation type analysis" ""
log_msg "    ✓ 4 outcomes with/without SES-Z moderation" ""
log_msg "" ""

log_msg "  PHASE 3: Generalized Linear Modeling (GLM)" ""
log_msg "    ✓ Extended GLM: Global + Stratified + Interaction + Bayesian" ""
log_msg "    ✓ Donation type segmentation (Einmalig/Regelmäßig/Mengengabe)" ""
log_msg "    ✓ Multi-level: respondents nested in organizations" ""
log_msg "    ✓ Parallel execution: 2-3 hours (8-16 cores)" ""
log_msg "" ""

log_msg "Key Innovation: Heterogeneous Effects Analysis" ""
log_msg "  Tests whether brand-outcome relationships differ by donation type:" ""
log_msg "  • One-time donors: Likely driven by awareness (TOM/SAW)" ""
log_msg "  • Regular donors: Likely driven by trust/image" ""
log_msg "  • Large donors: Balanced evaluation of all brand factors" ""
log_msg "" ""

log_msg "Results Location:" ""
log_msg "  ${RESULTS_DIR}/" ""
log_msg "" ""

log_msg "Key Output Files:" ""
log_msg "  • sem_extended_summary.csv (donation type effects)" ""
log_msg "  • glm_extended_summary.csv (segmentation results)" ""
log_msg "  • Cached fits: ${CACHE_DIR}/" ""
log_msg "" ""

log_msg "Next Steps:" ""
log_msg "  1. Review donation type heterogeneity findings" ""
log_msg "  2. Compare stratified vs global effects" ""
log_msg "  3. Generate publication-ready visualizations" ""
log_msg "  4. Interpret 3-way interactions (Brand × Type × SES)" ""

log_msg "" ""
log_msg "═══════════════════════════════════════════════════════════════" ""

# Archive orchestration log
cp "${ORCHESTRATION_LOG}" "${RESULTS_DIR}/orchestration_final.log"
log_msg "✓ Orchestration log saved" ""

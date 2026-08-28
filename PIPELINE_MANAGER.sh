#!/bin/bash
# Pipeline Manager: Orchestrates CFA → SEM → GLM execution chain
# Usage: bash /home/gerald/R-pipeline/PIPELINE_MANAGER.sh

set -e

PIPELINE_DIR="/home/gerald/R-pipeline"
LOGS_DIR="${PIPELINE_DIR}/logs"
CACHE_DIR="${PIPELINE_DIR}/cache"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_msg() {
    local msg="$1"
    local level="${2:-INFO}"
    local ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[${ts}]${NC} ${GREEN}${level}${NC}: ${msg}"
}

# ─────────────────────────────────────────────────────────────────────────────
# INITIALIZATION
# ─────────────────────────────────────────────────────────────────────────────

log_msg "═══════════════════════════════════════════════════════════════" "HEADER"
log_msg "PIPELINE MANAGER: CFA → SEM → GLM Analysis Chain" "START"
log_msg "═══════════════════════════════════════════════════════════════" "HEADER"

mkdir -p "${LOGS_DIR}"
mkdir -p "${CACHE_DIR}"

PIPELINE_LOG="${LOGS_DIR}/pipeline_manager.log"
touch "${PIPELINE_LOG}"

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 1: CFA PIPELINE
# ─────────────────────────────────────────────────────────────────────────────

log_msg "" ""
log_msg "PHASE 1: CFA Pipeline (All 5 Models × 2 Estimators)" "PHASE"
log_msg "Expected duration: ~2.5-3 hours" ""

log_msg "Checking for existing CFA cache..." ""
CACHED_FITS=$(ls -1 "${CACHE_DIR}"/cfa_*.rds 2>/dev/null | wc -l)
log_msg "Found ${CACHED_FITS} cached CFA fits" ""

# Check if CFA pipeline is already running
if pgrep -f "01_COMPREHENSIVE_ANALYSIS_PIPELINE.R" > /dev/null; then
    log_msg "CFA pipeline already running (PID: $(pgrep -f '01_COMPREHENSIVE_ANALYSIS_PIPELINE.R'))" "WARN"
    log_msg "Waiting for it to complete..." ""
else
    log_msg "Starting CFA pipeline..." ""
    nohup /usr/bin/Rscript "${PIPELINE_DIR}/01_COMPREHENSIVE_ANALYSIS_PIPELINE.R" \
        >> "${LOGS_DIR}/cfa_pipeline.log" 2>&1 &
    CFA_PID=$!
    log_msg "CFA pipeline started (PID: ${CFA_PID})" "SUCCESS"
fi

# Wait for CFA pipeline to complete
log_msg "Monitoring CFA progress..." ""
max_wait=14400  # 4 hours max
elapsed=0
check_interval=60

while [ $elapsed -lt $max_wait ]; do
    if pgrep -f "01_COMPREHENSIVE_ANALYSIS_PIPELINE.R" > /dev/null; then
        # Still running
        CACHE_COUNT=$(ls -1 "${CACHE_DIR}"/cfa_*.rds 2>/dev/null | wc -l)
        ELAPSED_MIN=$(( elapsed / 60 ))
        printf "\r${YELLOW}[%03d min]${NC} CFA pipeline running... (${CACHE_COUNT} fits cached)        "
        sleep $check_interval
        elapsed=$(( elapsed + check_interval ))
    else
        # Completed
        break
    fi
done

if pgrep -f "01_COMPREHENSIVE_ANALYSIS_PIPELINE.R" > /dev/null; then
    log_msg "CFA pipeline timeout after 4 hours!" "ERROR"
    log_msg "Check logs: ${LOGS_DIR}/cfa_pipeline.log" ""
    exit 1
else
    FINAL_CACHE=$(ls -1 "${CACHE_DIR}"/cfa_*.rds 2>/dev/null | wc -l)
    log_msg "" ""
    log_msg "✓ CFA PIPELINE COMPLETE (${FINAL_CACHE} fits cached)" "SUCCESS"
fi

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 2: FULL PIPELINE (SEM + GLM)
# ─────────────────────────────────────────────────────────────────────────────

log_msg "" ""
log_msg "PHASE 2: Full SEM + GLM Pipeline" "PHASE"
log_msg "Expected duration: ~7-10 hours" ""
log_msg "Starting comprehensive analysis..." ""

nohup /usr/bin/Rscript "${PIPELINE_DIR}/01_COMPREHENSIVE_ANALYSIS_FULL.R" \
    >> "${LOGS_DIR}/full_pipeline.log" 2>&1 &
FULL_PID=$!

log_msg "Full pipeline started (PID: ${FULL_PID})" "SUCCESS"

# Monitor full pipeline
max_wait=36000  # 10 hours max
elapsed=0
check_interval=120

while [ $elapsed -lt $max_wait ]; do
    if ps -p $FULL_PID > /dev/null 2>&1; then
        # Still running
        ELAPSED_MIN=$(( elapsed / 60 ))
        printf "\r${YELLOW}[%03d min]${NC} Full pipeline running...                    "
        sleep $check_interval
        elapsed=$(( elapsed + check_interval ))
    else
        # Completed
        break
    fi
done

if ps -p $FULL_PID > /dev/null 2>&1; then
    log_msg "Full pipeline timeout after 10 hours!" "ERROR"
    log_msg "Check logs: ${LOGS_DIR}/full_pipeline.log" ""
    exit 1
else
    log_msg "" ""
    log_msg "✓ FULL PIPELINE COMPLETE" "SUCCESS"
fi

# ─────────────────────────────────────────────────────────────────────────────
# FINAL SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

log_msg "" ""
log_msg "ANALYSIS COMPLETE" "SUCCESS"
log_msg "═══════════════════════════════════════════════════════════════" "HEADER"

log_msg "Results location: ${PIPELINE_DIR}/results/" ""
log_msg "Summary tables:" ""
ls -lh "${PIPELINE_DIR}/results/summaries/"*.csv 2>/dev/null || echo "  (not yet available)"

log_msg "" ""
log_msg "Logs:" ""
ls -lh "${LOGS_DIR}"/*.log 2>/dev/null | tail -5

log_msg "" ""
log_msg "Cache status:" ""
CACHE_SIZE=$(du -sh "${CACHE_DIR}" 2>/dev/null | cut -f1)
CACHE_COUNT=$(ls -1 "${CACHE_DIR}"/*.rds 2>/dev/null | wc -l)
log_msg "  Size: ${CACHE_SIZE} | Fits: ${CACHE_COUNT}" ""

log_msg "" ""
log_msg "Next steps:" ""
log_msg "  1. Review summary tables: results/summaries/*.csv" ""
log_msg "  2. Load RDS fits for detailed analysis: readRDS('cache/...')" ""
log_msg "  3. Generate publication-ready tables & figures" ""

log_msg "═══════════════════════════════════════════════════════════════" "HEADER"

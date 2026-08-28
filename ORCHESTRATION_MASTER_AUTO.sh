#!/bin/bash
# AUTO-ORCHESTRATION: SEM baseline → GLM Extended + SEM Extended (parallel)

set -e

PIPELINE_DIR="/home/gerald/R-pipeline"
LOGS_DIR="${PIPELINE_DIR}/logs"
CACHE_DIR="${PIPELINE_DIR}/cache"
RESULTS_DIR="${PIPELINE_DIR}/results/summaries"

mkdir -p "${LOGS_DIR}" "${RESULTS_DIR}"

log_msg() {
    local msg="$1"
    local level="${2:-INFO}"
    local ts=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${ts}] ${level}: ${msg}" >> "${LOGS_DIR}/orchestration_auto.log"
    echo "[${ts}] ${level}: ${msg}"
}

log_msg "═══════════════════════════════════════════════════════════════" ""
log_msg "AUTO-ORCHESTRATION: Phase Control" "START"
log_msg "SEM Baseline COMPLETE → Launching Extended Analyses" ""
log_msg "═══════════════════════════════════════════════════════════════" ""

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 1: Verify SEM Baseline Complete
# ─────────────────────────────────────────────────────────────────────────────

log_msg "PHASE 1: Verifying SEM Baseline" "PHASE"

SEM_BASELINE_FITS=$(ls "${CACHE_DIR}"/sem_*baseline*.rds 2>/dev/null | wc -l)
log_msg "SEM Baseline fits: ${SEM_BASELINE_FITS}" ""

if [ "${SEM_BASELINE_FITS}" -lt 20 ]; then
    log_msg "ERROR: Expected >20 baseline fits, found ${SEM_BASELINE_FITS}" "ERROR"
    exit 1
fi

log_msg "✓ SEM Baseline verified (${SEM_BASELINE_FITS} fits)" "SUCCESS"
log_msg "" ""

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 2: Start GLM Extended (parallel with SEM Extended)
# ─────────────────────────────────────────────────────────────────────────────

log_msg "PHASE 2: Launching GLM Extended Analysis" "PHASE"
log_msg "Donation type stratification (Einmalig/Regelmäßig/Mengengabe)" ""

nohup /usr/bin/Rscript "${PIPELINE_DIR}/05_GLM_PARALLEL_EXTENDED.R" \
    > "${LOGS_DIR}/glm_extended.log" 2>&1 &
GLM_PID=$!

log_msg "✓ GLM Extended started (PID: ${GLM_PID})" "SUCCESS"
log_msg "Expected duration: 2-3 hours" ""
log_msg "" ""

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 3: Start SEM Extended (parallel)
# ─────────────────────────────────────────────────────────────────────────────

log_msg "PHASE 3: Launching SEM Extended Analysis" "PHASE"
log_msg "Stratification: By Donation Type + By Organization" ""

nohup /usr/bin/Rscript "${PIPELINE_DIR}/03_SEM_EXTENDED.R" \
    > "${LOGS_DIR}/sem_extended.log" 2>&1 &
SEM_EXT_PID=$!

log_msg "✓ SEM Extended started (PID: ${SEM_EXT_PID})" "SUCCESS"
log_msg "Expected duration: 1-2 hours" ""
log_msg "" ""

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 4: Monitor Parallel Execution
# ─────────────────────────────────────────────────────────────────────────────

log_msg "PHASE 4: Monitoring Parallel Execution" "PHASE"
log_msg "GLM Extended (PID: ${GLM_PID}) + SEM Extended (PID: ${SEM_EXT_PID})" ""
log_msg "" ""

MONITOR_COUNT=0
GLM_DONE=0
SEM_EXT_DONE=0

while [ $GLM_DONE -eq 0 ] || [ $SEM_EXT_DONE -eq 0 ]; do
    MONITOR_COUNT=$((MONITOR_COUNT + 1))
    ELAPSED_MIN=$((MONITOR_COUNT * 5))

    # Check if processes still running
    if ! kill -0 $GLM_PID 2>/dev/null; then
        GLM_DONE=1
        log_msg "✓ GLM Extended completed" "SUCCESS"
    else
        echo -ne "\r[${ELAPSED_MIN} min] GLM Extended running...        " 2>&1 | tee -a "${LOGS_DIR}/orchestration_auto.log"
    fi

    if ! kill -0 $SEM_EXT_PID 2>/dev/null; then
        SEM_EXT_DONE=1
        log_msg "✓ SEM Extended completed" "SUCCESS"
    fi

    sleep 300  # Check every 5 minutes
done

echo ""
log_msg "" ""

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 5: Final Summary
# ─────────────────────────────────────────────────────────────────────────────

log_msg "PHASE 5: Final Summary" "PHASE"

TOTAL_CACHE=$(du -sh "${CACHE_DIR}" 2>/dev/null | awk '{print $1}')
TOTAL_FITS=$(ls "${CACHE_DIR}"/*.rds 2>/dev/null | wc -l)

log_msg "" ""
log_msg "═══════════════════════════════════════════════════════════════" ""
log_msg "ORCHESTRATION COMPLETE ✨" "SUCCESS"
log_msg "═══════════════════════════════════════════════════════════════" ""

log_msg "" ""
log_msg "Pipeline Results:" ""
log_msg "  ✓ CFA: 5 models" ""
log_msg "  ✓ SEM Baseline: ${SEM_BASELINE_FITS} fits" ""
log_msg "  ✓ GLM Extended: Global + Stratified + Interaction + Bayesian" ""
log_msg "  ✓ SEM Extended: By Type + By Organization + Multi-Group" ""
log_msg "" ""

log_msg "Cache Summary:" ""
log_msg "  Total Files: ${TOTAL_FITS}" ""
log_msg "  Total Size: ${TOTAL_CACHE}" ""
log_msg "" ""

log_msg "Stratification Analyses:" ""
log_msg "  • Donation Type: Einmalig vs Regelmäßig vs Mengengabe" ""
log_msg "  • Organization: Top 10 organizations" ""
log_msg "  • Multi-Group: Formal tests of type differences" ""
log_msg "" ""

log_msg "Results Location:" ""
log_msg "  ${RESULTS_DIR}/" ""
log_msg "" ""

log_msg "═══════════════════════════════════════════════════════════════" ""


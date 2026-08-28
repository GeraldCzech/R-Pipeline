#!/bin/bash
#
# AUDIT-RIGOROUS MASTER PIPELINE ORCHESTRATOR
# Runs all 10 phases automatically with logging
#
# Usage: bash RUN_COMPLETE_AUDIT_PIPELINE.sh
#

set -e  # Exit on error

BASE_DIR="/home/gerald/R-pipeline"
LOG_DIR="${BASE_DIR}/AUDIT_PIPELINE_LOGS"
OUTPUT_DIR="${BASE_DIR}/AUDIT_PIPELINE_OUTPUTS"

mkdir -p "$LOG_DIR"
mkdir -p "$OUTPUT_DIR"

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Logging function
log_phase() {
  local phase_num=$1
  local phase_name=$2
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "${BLUE}[${timestamp}] STARTING PHASE ${phase_num}: ${phase_name}${NC}"
}

log_success() {
  local phase_num=$1
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "${GREEN}[${timestamp}] ✓ PHASE ${phase_num} COMPLETE${NC}"
}

log_error() {
  local phase_num=$1
  local error_msg=$2
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "${RED}[${timestamp}] ✗ PHASE ${phase_num} FAILED: ${error_msg}${NC}"
  exit 1
}

# Header
cat << "EOF"

╔════════════════════════════════════════════════════════════════════════════╗
║  AUDIT-RIGOROUS MASTER PIPELINE ORCHESTRATOR                             ║
║  Fully automated, reproducible, PhD-level analysis                        ║
║  Date: 2026-08-26                                                        ║
╚════════════════════════════════════════════════════════════════════════════╝

EOF

echo "Configuration:"
echo "  Base directory: $BASE_DIR"
echo "  Log directory: $LOG_DIR"
echo "  Output directory: $OUTPUT_DIR"
echo ""

# Track start time
START_TIME=$(date +%s)

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 0-3: DATA PREPARATION
# ═════════════════════════════════════════════════════════════════════════════

log_phase "0-3" "Data Preparation & Integrity"

if Rscript "$BASE_DIR/AUDIT_RIGOROUS_MASTER_PIPELINE.R" > "$LOG_DIR/phase_0_3.log" 2>&1; then
  log_success "0-3"
else
  log_error "0-3" "See $LOG_DIR/phase_0_3.log for details"
fi

echo ""

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 4-7: CFA & FREQUENTIST GLMM
# ═════════════════════════════════════════════════════════════════════════════

log_phase "4-7" "CFA & Multilevel GLMMs"

if Rscript "$BASE_DIR/AUDIT_RIGOROUS_PHASE_4_7_CFA_GLMM.R" > "$LOG_DIR/phase_4_7.log" 2>&1; then
  log_success "4-7"
else
  log_error "4-7" "See $LOG_DIR/phase_4_7.log for details"
fi

echo ""

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 8-9: BAYESIAN VALIDATION
# ═════════════════════════════════════════════════════════════════════════════

log_phase "8-9" "Bayesian Validation with Full Diagnostics"
echo "  WARNING: This phase takes 30-60 minutes"
echo ""

if Rscript "$BASE_DIR/AUDIT_RIGOROUS_PHASE_8_9_BAYESIAN.R" > "$LOG_DIR/phase_8_9.log" 2>&1; then
  log_success "8-9"
else
  log_error "8-9" "See $LOG_DIR/phase_8_9.log for details"
fi

echo ""

# ═════════════════════════════════════════════════════════════════════════════
# PHASE 10: FINAL REPORTING
# ═════════════════════════════════════════════════════════════════════════════

log_phase "10" "Final Results Synthesis"

if Rscript "$BASE_DIR/AUDIT_RIGOROUS_PHASE_10_FINAL_REPORT.R" > "$LOG_DIR/phase_10.log" 2>&1; then
  log_success "10"
else
  log_error "10" "See $LOG_DIR/phase_10.log for details"
fi

echo ""

# ═════════════════════════════════════════════════════════════════════════════
# COMPLETION
# ═════════════════════════════════════════════════════════════════════════════

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
DURATION_MIN=$((DURATION / 60))
DURATION_SEC=$((DURATION % 60))

echo ""
cat << "EOF"

╔════════════════════════════════════════════════════════════════════════════╗
║  PIPELINE COMPLETE: ALL 10 PHASES EXECUTED SUCCESSFULLY                  ║
╚════════════════════════════════════════════════════════════════════════════╝

EOF

echo -e "${GREEN}✓ FULL PIPELINE EXECUTION SUCCESSFUL${NC}"
echo ""
echo "Summary:"
echo "  Total duration: ${DURATION_MIN}m ${DURATION_SEC}s"
echo "  Output directory: $OUTPUT_DIR"
echo "  Log directory: $LOG_DIR"
echo ""
echo "Generated files:"
echo "  - PERSON_MODULE_ORG_CROSSWALK.csv (data integrity)"
echo "  - 04_CFA_FIT_INDICES.csv (measurement model)"
echo "  - 05_BINARY_GLMM_RESULTS.csv (donation decision)"
echo "  - 06_AMOUNT_MODEL_RESULTS.csv (donation amount)"
echo "  - 08_BAYES_*_FIXED_EFFECTS.csv (Bayesian posterior estimates)"
echo "  - bayes_*_POSTERIOR_DRAWS.csv (4,000 posterior samples each)"
echo "  - 09_COMPREHENSIVE_BAYESIAN_DIAGNOSTICS.csv (full convergence report)"
echo "  - 10_FINAL_REPORT.txt (complete synthesis)"
echo ""
echo "Next steps:"
echo "  1. Review: head -100 $OUTPUT_DIR/10_FINAL_REPORT.txt"
echo "  2. Inspect: ls -lh $OUTPUT_DIR/"
echo "  3. Check logs: tail -50 $LOG_DIR/phase_*.log"
echo "  4. Commit to git: git add $OUTPUT_DIR/ && git commit -m 'Audit-rigorous pipeline complete'"
echo ""


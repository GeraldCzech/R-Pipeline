#!/bin/bash
set -euo pipefail

BASE_DIR="/home/gerald/R-pipeline"
COMMIT_HASH=$(git rev-parse --short HEAD)
RUN_ID=$(date +%Y%m%d_%H%M%S)_${COMMIT_HASH}
LOG_DIR="${BASE_DIR}/AUDIT_PIPELINE_LOGS"
OUTPUT_DIR="${BASE_DIR}/AUDIT_PIPELINE_OUTPUTS/RUN_${RUN_ID}"
RUN_LOG="${LOG_DIR}/RUN_${RUN_ID}.log"

mkdir -p "$LOG_DIR" "$OUTPUT_DIR"

run_phase() {
  local phase_name="$1"
  local script="$2"
  local log_file="$3"
  
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $phase_name" | tee -a "$RUN_LOG"
  
  if RUN_OUTPUT_DIR="$OUTPUT_DIR" Rscript "$script" >> "$log_file" 2>&1; then
    echo "✓ $phase_name COMPLETE" | tee -a "$RUN_LOG"
  else
    echo "✗ $phase_name FAILED" | tee -a "$RUN_LOG"
    exit 1
  fi
}

cat << "EOF" | tee "$RUN_LOG"
╔════════════════════════════════════════════════════════════════════════════╗
║  AUDIT-RIGOROUS PIPELINE WITH ALL P0 FIXES                               ║
║  Run-Bound Output Isolation | Robust Bayesian Diagnostics                ║
╚════════════════════════════════════════════════════════════════════════════╝
EOF

echo "RUN ID: $RUN_ID" | tee -a "$RUN_LOG"
echo "Output: $OUTPUT_DIR" | tee -a "$RUN_LOG"
echo ""

run_phase "PREFLIGHT" "${BASE_DIR}/00_PREFLIGHT_AUDIT.R" "${LOG_DIR}/preflight.log"
run_phase "RECONSTRUCTION 01" "${BASE_DIR}/01_PERSON_ID_RECONSTRUCTION.R" "${LOG_DIR}/reconstruction_01.log"
run_phase "RECONSTRUCTION 02" "${BASE_DIR}/01_ANALYSIS_INPUT_VALIDATION.R" "${LOG_DIR}/reconstruction_02.log"
run_phase "PHASE 0-3" "${BASE_DIR}/AUDIT_RIGOROUS_MASTER_PIPELINE_CORRECTED.R" "${LOG_DIR}/phase_0_3.log"
run_phase "PHASE 4-7" "${BASE_DIR}/AUDIT_RIGOROUS_PHASE_4_7_CFA_GLMM.R" "${LOG_DIR}/phase_4_7.log"
run_phase "PHASE 8-9" "${BASE_DIR}/AUDIT_RIGOROUS_PHASE_8_9_BAYESIAN.R" "${LOG_DIR}/phase_8_9.log"
run_phase "RUN GATES" "${BASE_DIR}/RUN_GATES.R" "${LOG_DIR}/run_gates.log"
run_phase "PHASE 10" "${BASE_DIR}/AUDIT_RIGOROUS_PHASE_10_FINAL_REPORT.R" "${LOG_DIR}/phase_10.log"

echo "" | tee -a "$RUN_LOG"
echo "✓ ALL PHASES COMPLETE" | tee -a "$RUN_LOG"
echo "Output: $OUTPUT_DIR" | tee -a "$RUN_LOG"

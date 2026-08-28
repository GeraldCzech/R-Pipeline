#!/bin/bash

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║      LAUNCHING COMPLETE REFACTORING PIPELINE (Phase C-Z+GLM)  ║"
echo "║       With Real Data (5,617 respondents) + Monitoring         ║"
echo "║                                                                ║"
echo "║  Output: ORCHESTRATION_RESULTS/                              ║"
echo "║  Monitor: tail -f ORCHESTRATION_RESULTS/STATUS.txt           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Launch main orchestration in background
nohup Rscript ORCHESTRATION_WITH_MONITORING.R > ORCHESTRATION_RESULTS/orchestration.log 2>&1 &
PID=$!

echo "✓ Pipeline started with PID: $PID"
echo "✓ Logging to: ORCHESTRATION_RESULTS/orchestration.log"
echo ""
echo "Monitor progress with:"
echo "  tail -f ORCHESTRATION_RESULTS/STATUS.txt"
echo "  or"
echo "  tail -f ORCHESTRATION_RESULTS/orchestration.log"
echo ""
echo "Status updates every 30 minutes in ORCHESTRATION_RESULTS/"

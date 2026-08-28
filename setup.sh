#!/bin/bash
# R-Pipeline Complete Setup Script

set -e

echo "================================================"
echo "  R-PIPELINE COMPLETE SETUP"
echo "================================================"
echo ""

# 1. Kill old processes
echo "[1/7] Killing old processes..."
sudo pkill -9 python3 2>/dev/null || true
sudo pkill -9 Rscript 2>/dev/null || true
sleep 2

# 2. Clean caches
echo "[2/7] Cleaning caches..."
rm -rf /home/gerald/R-pipeline/_targets
rm -rf /home/gerald/R-pipeline/.RData
rm -rf /home/gerald/R-pipeline/.Rhistory
echo "✅ Caches deleted"

# 3. Stop services
echo "[3/7] Stopping services..."
sudo systemctl stop r-pipeline 2>/dev/null || true
sudo systemctl stop r-pipeline-dashboard 2>/dev/null || true
sleep 3

# 4. Start main pipeline
echo "[4/7] Starting r-pipeline service..."
sudo systemctl start r-pipeline
sleep 5
systemctl status r-pipeline --no-pager | head -5

# 5. Start dashboard
echo "[5/7] Starting r-pipeline-dashboard service..."
sudo systemctl start r-pipeline-dashboard
sleep 5
systemctl status r-pipeline-dashboard --no-pager | head -5

# 6. Check pipeline
echo "[6/7] Checking pipeline status..."
tail -10 /home/gerald/R-pipeline/logs/pipeline.log
echo ""

# 7. Test dashboard
echo "[7/7] Testing dashboard API..."
sleep 2
if curl -s http://localhost:5000/api/status > /dev/null 2>&1; then
    echo "✅ Dashboard responding on http://localhost:5000"
    curl -s http://localhost:5000/api/status | jq '.pipeline.status' 2>/dev/null || echo "✅ Dashboard is up"
else
    echo "❌ Dashboard not responding yet, wait a moment..."
fi

echo ""
echo "================================================"
echo "  SETUP COMPLETE!"
echo "================================================"
echo ""
echo "Dashboard: http://192.168.50.164:5000"
echo "Check logs: tail -f /home/gerald/R-pipeline/logs/pipeline.log"
echo ""

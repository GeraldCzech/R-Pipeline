#!/bin/bash

echo "🔄 Restarting R-Pipeline System..."
echo ""

# Kill all old processes
echo "[1/5] Killing old processes..."
sudo pkill -9 python3 2>/dev/null || true
sudo pkill -9 Rscript 2>/dev/null || true
sleep 2
echo "✅ Done"

# Clean caches
echo "[2/5] Cleaning caches..."
sudo rm -rf /home/gerald/R-pipeline/_targets
sudo rm -rf /home/gerald/R-pipeline/.RData
echo "✅ Done"

# Restart services
echo "[3/5] Restarting services..."
sudo systemctl stop r-pipeline 2>/dev/null || true
sudo systemctl stop r-pipeline-dashboard 2>/dev/null || true
sleep 2

sudo systemctl start r-pipeline
sleep 3
echo "✅ Pipeline started"

sudo systemctl start r-pipeline-dashboard
sleep 3
echo "✅ Dashboard started"

# Check status
echo ""
echo "[4/5] Service Status:"
systemctl status r-pipeline --no-pager | grep "Active:"
systemctl status r-pipeline-dashboard --no-pager | grep "Active:"

# Test
echo ""
echo "[5/5] Testing..."
sleep 2
if curl -s http://localhost:5000/api/status > /dev/null 2>&1; then
    echo "✅ Dashboard responding!"
else
    echo "⏳ Dashboard starting, check in a few seconds..."
fi

echo ""
echo "================================================"
echo "✅ SYSTEM READY!"
echo "================================================"
echo ""
echo "📊 Dashboard: http://192.168.50.164:5000"
echo "📋 Logs: tail -f /home/gerald/R-pipeline/logs/pipeline.log"
echo ""

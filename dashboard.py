#!/usr/bin/env python3
"""
R-Pipeline Dashboard
Real-time monitoring of background analysis pipeline
"""

from flask import Flask, render_template_string, jsonify
import json
import os
import re
from datetime import datetime
from pathlib import Path
import psutil

app = Flask(__name__)

PIPELINE_DIR = Path("/home/gerald/R-pipeline")
LOG_FILE = PIPELINE_DIR / "logs" / "analyses.log"
RESULTS_DIR = PIPELINE_DIR / "results"

# ============================================================================
# Parse logs
# ============================================================================

def parse_logs():
    """Parse analysis logs and extract status."""
    if not LOG_FILE.exists():
        return {"status": "waiting", "message": "Pipeline not started yet"}

    try:
        with open(LOG_FILE, "r") as f:
            lines = f.readlines()
    except:
        return {"status": "error", "message": "Cannot read log file"}

    # Extract current phase
    phases = []
    current_phase = None
    phase_start_time = None
    completed_jobs = []
    failed_jobs = []
    in_progress_job = None

    for line in lines:
        # Check for phase markers
        if "PHASE:" in line:
            match = re.search(r"PHASE: (.+?)(?:\s|$)", line)
            if match:
                phase_name = match.group(1)
                if "Expected time:" in line:
                    # Extract time estimate
                    time_match = re.search(r"Expected time: ([^,]+)", line)
                    current_phase = {"name": phase_name, "time": time_match.group(1) if time_match else ""}
                else:
                    current_phase = {"name": phase_name, "time": ""}

        # Track completed jobs
        if "DONE: ✅" in line or "CHECKPOINT: ✅" in line:
            match = re.search(r"(DONE|CHECKPOINT): ✅ (.+?)(?:\(|$)", line)
            if match:
                job_name = match.group(2).strip()
                time_match = re.search(r"\((.+?)\)", line)
                duration = time_match.group(1) if time_match else "?"
                completed_jobs.append({"name": job_name, "duration": duration})

        # Track failed jobs
        if "ERROR: ❌" in line:
            match = re.search(r"ERROR: ❌ (.+?)(?:\s-|$)", line)
            if match:
                failed_jobs.append(match.group(1).strip())

        # Track in-progress
        if "START: Starting:" in line:
            match = re.search(r"START: Starting: (.+?)$", line)
            if match:
                in_progress_job = match.group(1)

    # Determine overall status
    if "SUCCESS: 🎉" in "".join(lines):
        overall_status = "complete"
    elif in_progress_job:
        overall_status = "running"
    elif len(completed_jobs) > 0 or len(failed_jobs) > 0:
        overall_status = "in_progress"
    else:
        overall_status = "waiting"

    return {
        "status": overall_status,
        "phase": current_phase,
        "completed": len(completed_jobs),
        "completed_jobs": completed_jobs[-5:],  # Last 5
        "failed": len(failed_jobs),
        "failed_jobs": failed_jobs,
        "in_progress_job": in_progress_job,
        "total_jobs": len(completed_jobs) + len(failed_jobs),
    }

# ============================================================================
# Get system stats
# ============================================================================

def get_system_stats():
    """Get CPU and memory usage."""
    try:
        r_process = None
        for proc in psutil.process_iter(["pid", "name", "cpu_percent", "memory_info"]):
            if "R" in proc.info["name"] or "Rscript" in proc.info["name"]:
                r_process = proc
                break

        if r_process:
            return {
                "cpu_percent": r_process.cpu_percent(),
                "memory_mb": r_process.memory_info().rss / 1024 / 1024,
                "pid": r_process.pid,
                "running": True,
            }
        else:
            return {"running": False}
    except:
        return {"running": False}

# ============================================================================
# Get results
# ============================================================================

def get_results():
    """List completed result files."""
    if not RESULTS_DIR.exists():
        return []

    results = []
    for rds_file in sorted(RESULTS_DIR.glob("*.rds")):
        size_mb = rds_file.stat().st_size / 1024 / 1024
        results.append({
            "name": rds_file.name,
            "size_mb": f"{size_mb:.2f}",
            "mtime": datetime.fromtimestamp(rds_file.stat().st_mtime).strftime("%H:%M:%S"),
        })
    return results

# ============================================================================
# API endpoints
# ============================================================================

@app.route("/api/status")
def api_status():
    """Get current pipeline status."""
    logs = parse_logs()
    system = get_system_stats()
    results = get_results()

    return jsonify({
        "pipeline": logs,
        "system": system,
        "results": results,
        "timestamp": datetime.now().isoformat(),
    })

# ============================================================================
# Web interface
# ============================================================================

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>R-Pipeline Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
        }
        h1 {
            color: white;
            margin-bottom: 30px;
            text-align: center;
            font-size: 2.5em;
            text-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        .card {
            background: white;
            border-radius: 12px;
            padding: 25px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .card:hover { transform: translateY(-5px); box-shadow: 0 15px 40px rgba(0,0,0,0.3); }
        .card h2 {
            color: #667eea;
            font-size: 1em;
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 15px;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }
        .status-badge {
            display: inline-block;
            padding: 8px 16px;
            border-radius: 20px;
            font-weight: bold;
            font-size: 0.9em;
            margin-bottom: 10px;
        }
        .status-running { background: #10b981; color: white; }
        .status-complete { background: #3b82f6; color: white; }
        .status-waiting { background: #f59e0b; color: white; }
        .status-error { background: #ef4444; color: white; }
        .stat-row {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #eee;
        }
        .stat-row:last-child { border-bottom: none; }
        .stat-label { color: #666; font-weight: 500; }
        .stat-value { color: #333; font-weight: bold; }
        .progress-bar {
            background: #eee;
            height: 30px;
            border-radius: 8px;
            overflow: hidden;
            margin: 15px 0;
        }
        .progress-fill {
            background: linear-gradient(90deg, #667eea, #764ba2);
            height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            transition: width 0.3s;
        }
        .job-list {
            list-style: none;
            max-height: 200px;
            overflow-y: auto;
        }
        .job-item {
            padding: 10px;
            background: #f9fafb;
            border-left: 3px solid #667eea;
            margin-bottom: 5px;
            border-radius: 4px;
            font-size: 0.9em;
        }
        .job-item.failed {
            border-left-color: #ef4444;
        }
        .job-time {
            color: #999;
            font-size: 0.8em;
        }
        .cpu-meter {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .cpu-bar {
            flex: 1;
            background: #eee;
            height: 20px;
            border-radius: 10px;
            overflow: hidden;
        }
        .cpu-fill {
            background: linear-gradient(90deg, #10b981, #f59e0b, #ef4444);
            height: 100%;
            transition: width 0.5s;
        }
        .update-time {
            text-align: center;
            color: #999;
            font-size: 0.8em;
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid #eee;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 R-Pipeline Dashboard</h1>

        <div class="grid">
            <!-- Status Card -->
            <div class="card">
                <h2>Status</h2>
                <div id="status-badge" class="status-badge status-waiting">⏳ Waiting</div>
                <div class="stat-row">
                    <span class="stat-label">Phase</span>
                    <span class="stat-value" id="phase">-</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Current Job</span>
                    <span class="stat-value" id="current-job" style="font-size: 0.9em;">-</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Completed</span>
                    <span class="stat-value"><span id="completed">0</span> / <span id="total">0</span></span>
                </div>
            </div>

            <!-- Progress Card -->
            <div class="card">
                <h2>Progress</h2>
                <div class="progress-bar">
                    <div class="progress-fill" id="progress-fill" style="width: 0%">0%</div>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Success</span>
                    <span class="stat-value" id="success-count">0</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Failed</span>
                    <span class="stat-value" id="failed-count">0</span>
                </div>
            </div>

            <!-- System Resources Card -->
            <div class="card">
                <h2>Resources</h2>
                <div class="stat-row">
                    <span class="stat-label">R Process</span>
                    <span class="stat-value" id="process-status">🔴 Offline</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">CPU</span>
                    <span class="stat-value cpu-meter">
                        <div class="cpu-bar"><div class="cpu-fill" id="cpu-fill" style="width: 0%"></div></div>
                        <span id="cpu-percent">0%</span>
                    </span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Memory</span>
                    <span class="stat-value" id="memory-mb">-</span>
                </div>
            </div>
        </div>

        <!-- Results Card -->
        <div class="card">
            <h2>Results</h2>
            <div id="results-list" style="font-size: 0.9em; max-height: 300px; overflow-y: auto;">
                <p style="color: #999;">No results yet...</p>
            </div>
        </div>

        <!-- Log Tail -->
        <div class="card">
            <h2>Recent Jobs</h2>
            <ul class="job-list" id="job-list">
                <li style="color: #999;">No jobs yet...</li>
            </ul>
        </div>

        <div class="update-time">
            Last update: <span id="update-time">-</span>
        </div>
    </div>

    <script>
        async function updateDashboard() {
            try {
                const response = await fetch("/api/status");
                const data = await response.json();

                // Update status
                const pipeline = data.pipeline;
                const statusBadge = document.getElementById("status-badge");
                statusBadge.className = "status-badge status-" + pipeline.status;
                statusBadge.textContent = {
                    "running": "▶️ Running",
                    "complete": "✅ Complete",
                    "waiting": "⏳ Waiting",
                    "in_progress": "⏳ In Progress",
                }[pipeline.status] || "❓ Unknown";

                // Update phase
                document.getElementById("phase").textContent = pipeline.phase?.name || "-";
                document.getElementById("current-job").textContent = pipeline.in_progress_job || "-";
                document.getElementById("completed").textContent = pipeline.completed;
                document.getElementById("total").textContent = pipeline.total_jobs || "?";

                // Update progress bar
                const progress = pipeline.total_jobs > 0 ? (pipeline.completed / pipeline.total_jobs * 100) : 0;
                const progressFill = document.getElementById("progress-fill");
                progressFill.style.width = progress + "%";
                progressFill.textContent = Math.round(progress) + "%";

                // Update counts
                document.getElementById("success-count").textContent = pipeline.completed;
                document.getElementById("failed-count").textContent = pipeline.failed;

                // Update system
                const system = data.system;
                if (system.running) {
                    document.getElementById("process-status").textContent = "🟢 Running (PID " + system.pid + ")";
                    document.getElementById("cpu-percent").textContent = Math.round(system.cpu_percent) + "%";
                    document.getElementById("cpu-fill").style.width = Math.min(system.cpu_percent, 100) + "%";
                    document.getElementById("memory-mb").textContent = Math.round(system.memory_mb) + " MB";
                } else {
                    document.getElementById("process-status").textContent = "🔴 Offline";
                }

                // Update results
                const resultsList = document.getElementById("results-list");
                if (data.results.length > 0) {
                    resultsList.innerHTML = data.results.map(r =>
                        `<div style="padding: 8px; border-bottom: 1px solid #eee;">
                            <strong>${r.name}</strong> (${r.size_mb} MB) <span style="color: #999;">${r.mtime}</span>
                        </div>`
                    ).join("");
                } else {
                    resultsList.innerHTML = '<p style="color: #999;">No results yet...</p>';
                }

                // Update job list
                const jobList = document.getElementById("job-list");
                if (pipeline.completed_jobs.length > 0) {
                    jobList.innerHTML = pipeline.completed_jobs.map(j =>
                        `<li class="job-item">✅ ${j.name} <span class="job-time">(${j.duration})</span></li>`
                    ).join("") + (pipeline.failed_jobs.length > 0 ?
                        pipeline.failed_jobs.map(j =>
                            `<li class="job-item failed">❌ ${j}</li>`
                        ).join("") : "");
                }

                // Update time
                document.getElementById("update-time").textContent = new Date().toLocaleTimeString();
            } catch (error) {
                console.error("Error updating dashboard:", error);
            }
        }

        // Update every 3 seconds
        updateDashboard();
        setInterval(updateDashboard, 3000);
    </script>
</body>
</html>
"""

@app.route("/")
def dashboard():
    """Serve dashboard."""
    return render_template_string(HTML_TEMPLATE)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)

#!/usr/bin/env python3
"""
R-Pipeline Web Dashboard
Displays pipeline progress, cached targets, and results
"""

import os
import json
import subprocess
from datetime import datetime
from pathlib import Path
from flask import Flask, render_template, jsonify
import psutil

app = Flask(__name__, template_folder=".", static_folder=".")

PIPELINE_DIR = Path("/home/gerald/R-pipeline")
TARGETS_DIR = PIPELINE_DIR / "_targets"
LOG_FILE = PIPELINE_DIR / "logs" / "pipeline.log"
DAEMON_LOG = PIPELINE_DIR / "logs" / "daemon.log"

def get_pipeline_status():
    """Get service status"""
    try:
        result = subprocess.run(
            ["systemctl", "status", "r-pipeline"],
            capture_output=True,
            text=True,
            timeout=5
        )
        is_running = "active (running)" in result.stdout
        return {
            "running": is_running,
            "status": "Running" if is_running else "Stopped"
        }
    except Exception as e:
        return {"running": False, "status": f"Error: {e}"}

def get_targets_status():
    """Get targets cache status"""
    workspaces_dir = TARGETS_DIR / "workspaces"

    if not workspaces_dir.exists():
        return {"total": 0, "completed": 0, "targets": []}

    targets = []
    for item in sorted(workspaces_dir.iterdir()):
        targets.append({
            "name": item.name,
            "type": "data" if "_file" in item.name or "_data" in item.name else "result",
            "completed": True
        })

    return {
        "total": len(targets),
        "completed": len(targets),
        "targets": targets
    }

def get_resource_usage():
    """Get CPU and memory usage"""
    try:
        # Find R pipeline processes
        r_process = None
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
            try:
                if 'Rscript' in proc.info['name'] or 'R' in proc.info['name']:
                    r_process = proc.info
                    break
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass

        if r_process:
            return {
                "cpu": r_process.get('cpu_percent', 0),
                "memory": r_process.get('memory_percent', 0),
                "active": True
            }
        return {"cpu": 0, "memory": 0, "active": False}
    except Exception as e:
        return {"cpu": 0, "memory": 0, "active": False, "error": str(e)}

def get_recent_logs(n=20):
    """Get recent log lines"""
    logs = {"pipeline": [], "daemon": []}

    if LOG_FILE.exists():
        try:
            with open(LOG_FILE, 'r') as f:
                logs["pipeline"] = f.readlines()[-n:]
        except:
            pass

    if DAEMON_LOG.exists():
        try:
            with open(DAEMON_LOG, 'r') as f:
                logs["daemon"] = f.readlines()[-n:]
        except:
            pass

    return logs

def get_target_results():
    """Get available result files"""
    results = []

    # Look for output files
    output_dirs = [
        PIPELINE_DIR / "output",
        PIPELINE_DIR / "results",
        TARGETS_DIR / "workspaces"
    ]

    for output_dir in output_dirs:
        if output_dir.exists():
            for item in output_dir.rglob("*"):
                if item.is_file() and not item.name.startswith("."):
                    size = item.stat().st_size
                    size_str = f"{size / (1024*1024):.1f} MB" if size > 1024*1024 else f"{size / 1024:.1f} KB"
                    results.append({
                        "name": item.name,
                        "path": str(item.relative_to(PIPELINE_DIR)),
                        "size": size_str,
                        "modified": datetime.fromtimestamp(item.stat().st_mtime).strftime("%Y-%m-%d %H:%M:%S")
                    })

    return sorted(results, key=lambda x: x['modified'], reverse=True)[:20]

@app.route('/')
def index():
    """Serve dashboard HTML"""
    return render_template('dashboard.html')

@app.route('/api/status')
def api_status():
    """API: Get full status"""
    return jsonify({
        "timestamp": datetime.now().isoformat(),
        "pipeline": get_pipeline_status(),
        "targets": get_targets_status(),
        "resources": get_resource_usage(),
        "logs": get_recent_logs(15),
        "results": get_target_results()
    })

@app.route('/api/pipeline')
def api_pipeline():
    """API: Pipeline status only"""
    return jsonify(get_pipeline_status())

@app.route('/api/targets')
def api_targets():
    """API: Targets status"""
    return jsonify(get_targets_status())

@app.route('/api/resources')
def api_resources():
    """API: Resource usage"""
    return jsonify(get_resource_usage())

@app.route('/api/logs')
def api_logs():
    """API: Recent logs"""
    return jsonify(get_recent_logs(30))

@app.route('/api/results')
def api_results():
    """API: Available results"""
    return jsonify(get_target_results())

if __name__ == '__main__':
    print("Starting R-Pipeline Dashboard on http://localhost:5000")
    app.run(host='0.0.0.0', port=5000, debug=False)

#!/usr/bin/env python3
"""
Smart Queue System - Main Daemon
Combines queue_runner + queue_analyzer into one manageable system
"""

import os
import sys
import subprocess
import time
import logging
import shutil
import signal
from pathlib import Path
from datetime import datetime
import threading

# Setup paths
PIPELINE_ROOT = Path("/home/gerald/R-pipeline")
QUEUE_DIR = PIPELINE_ROOT / "queue"
PENDING_DIR = QUEUE_DIR / "pending"
RUNNING_DIR = QUEUE_DIR / "running"
DONE_DIR = QUEUE_DIR / "done"
FAILED_DIR = QUEUE_DIR / "failed"
RESULTS_DIR = PIPELINE_ROOT / "results"
LOG_DIR = PIPELINE_ROOT / "logs"

# Ensure directories exist
for d in [PENDING_DIR, RUNNING_DIR, DONE_DIR, FAILED_DIR, RESULTS_DIR, LOG_DIR]:
    d.mkdir(parents=True, exist_ok=True)

# Logging
log_file = LOG_DIR / "queue_system.log"
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s: %(message)s",
    handlers=[
        logging.FileHandler(log_file),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Global state
current_job = None
running_process = None


def signal_handler(sig, frame):
    """Handle Ctrl+C gracefully."""
    logger.info("Shutdown signal received")
    if running_process:
        logger.info("Killing running job...")
        running_process.terminate()
        time.sleep(2)
        if running_process.poll() is None:
            running_process.kill()
    sys.exit(0)


signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)


def get_queue_status():
    """Get current queue status."""
    try:
        pending = list(PENDING_DIR.glob("*.R"))
        running = list(RUNNING_DIR.glob("*.R"))
        done = list(DONE_DIR.glob("*.R"))
        failed = list(FAILED_DIR.glob("*.R"))

        return {
            "pending": len(pending),
            "running": len(running),
            "done": len(done),
            "failed": len(failed),
            "total": len(pending) + len(running) + len(done) + len(failed),
        }
    except Exception as e:
        logger.error(f"Error getting queue status: {e}")
        return {}


def run_job(script_path):
    """Execute an R script."""
    global running_process

    script_name = script_path.name
    logger.info(f"Starting: {script_name}")

    start_time = time.time()

    try:
        running_process = subprocess.Popen(
            ["Rscript", str(script_path)],
            cwd=str(PIPELINE_ROOT),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        stdout, stderr = running_process.communicate(timeout=3600)
        elapsed = time.time() - start_time

        success = running_process.returncode == 0

        if success:
            logger.info(f"✅ Success: {script_name} ({elapsed:.1f}s)")
        else:
            logger.error(f"❌ Failed: {script_name} (exit {running_process.returncode}, {elapsed:.1f}s)")

        running_process = None
        return success, stdout, stderr, elapsed

    except subprocess.TimeoutExpired:
        logger.error(f"⏱️  Timeout: {script_name} (>1 hour)")
        running_process.kill()
        running_process = None
        return False, "", "Timeout", 3600
    except Exception as e:
        logger.error(f"💥 Error: {e}")
        running_process = None
        return False, "", str(e), 0


def save_job_log(script_name, success, stdout, stderr, elapsed):
    """Save job output to log file."""
    output_dir = DONE_DIR if success else FAILED_DIR
    log_path = output_dir / f"{script_name}.log"

    try:
        with open(log_path, "w") as f:
            f.write("=" * 70 + "\n")
            f.write(f"Job: {script_name}\n")
            f.write(f"Status: {'SUCCESS' if success else 'FAILED'}\n")
            f.write(f"Time: {datetime.now().isoformat()}\n")
            f.write(f"Duration: {elapsed:.1f}s\n")
            f.write("=" * 70 + "\n\n")
            f.write("--- STDOUT ---\n")
            f.write(stdout)
            f.write("\n\n--- STDERR ---\n")
            f.write(stderr)
            f.write("\n")
    except Exception as e:
        logger.error(f"Error saving log: {e}")


def process_job(script_path):
    """Process a single job: run it, save output, move to done/failed."""
    global current_job

    script_name = script_path.name
    running_path = RUNNING_DIR / script_name

    try:
        # Move to running
        shutil.move(str(script_path), str(running_path))
        current_job = script_name

        # Run job
        success, stdout, stderr, elapsed = run_job(running_path)

        # Save logs
        save_job_log(script_name, success, stdout, stderr, elapsed)

        # Move script to final location
        dest_dir = DONE_DIR if success else FAILED_DIR
        shutil.move(str(running_path), str(dest_dir / script_name))

        current_job = None
        return success

    except Exception as e:
        logger.error(f"Error processing {script_name}: {e}")
        if running_path.exists():
            shutil.move(str(running_path), str(FAILED_DIR / script_name))
        current_job = None
        return False


def get_next_job():
    """Get next pending job."""
    try:
        jobs = sorted(PENDING_DIR.glob("*.R"))
        return jobs[0] if jobs else None
    except Exception as e:
        logger.error(f"Error listing jobs: {e}")
        return None


def write_status_file():
    """Write current status to a JSON file for dashboard."""
    try:
        status = get_queue_status()
        status["current_job"] = current_job
        status["timestamp"] = datetime.now().isoformat()

        status_file = PIPELINE_ROOT / "queue_status.json"
        with open(status_file, "w") as f:
            import json
            json.dump(status, f, indent=2)
    except Exception as e:
        logger.warning(f"Error writing status file: {e}")


def main_loop():
    """Main queue processing loop."""
    logger.info("=" * 70)
    logger.info("SMART QUEUE SYSTEM STARTED")
    logger.info("=" * 70)
    logger.info(f"Queue dir: {QUEUE_DIR}")
    logger.info(f"Results dir: {RESULTS_DIR}")

    iteration = 0
    empty_iterations = 0

    while True:
        iteration += 1

        # Get next job
        job = get_next_job()

        if not job:
            empty_iterations += 1
            if empty_iterations % 6 == 1:  # Log every 3 minutes (6 * 30s)
                status = get_queue_status()
                logger.info(
                    f"[Iteration {iteration}] Queue empty. "
                    f"Stats: {status['done']} done, {status['failed']} failed"
                )
            write_status_file()
            time.sleep(30)
            continue

        empty_iterations = 0

        # Process job
        status = get_queue_status()
        logger.info(
            f"[Iteration {iteration}] Processing: {job.name} "
            f"(Queue: {status['pending']} pending)"
        )

        process_job(job)
        write_status_file()

        # Brief pause between jobs
        time.sleep(2)


if __name__ == "__main__":
    try:
        main_loop()
    except KeyboardInterrupt:
        logger.info("Queue system stopped by user")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)

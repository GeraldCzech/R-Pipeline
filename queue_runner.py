#!/usr/bin/env python3
"""
Queue Runner: Executes R scripts from queue/pending/ one by one.
- Monitors queue/pending/ for .R files
- Executes them in order
- Moves to queue/done/ (success) or queue/failed/ (error)
- Runs continuously
"""

import os
import sys
import subprocess
import time
import logging
import shutil
from pathlib import Path
from datetime import datetime

# Setup
PIPELINE_ROOT = "/home/gerald/R-pipeline"
QUEUE_DIR = Path(PIPELINE_ROOT) / "queue"
PENDING_DIR = QUEUE_DIR / "pending"
RUNNING_DIR = QUEUE_DIR / "running"
DONE_DIR = QUEUE_DIR / "done"
FAILED_DIR = QUEUE_DIR / "failed"
META_DIR = QUEUE_DIR / "meta"
LOG_DIR = Path(PIPELINE_ROOT) / "logs"

# Ensure directories exist
for d in [PENDING_DIR, RUNNING_DIR, DONE_DIR, FAILED_DIR, META_DIR, LOG_DIR]:
    d.mkdir(parents=True, exist_ok=True)

# Logging
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s: %(message)s",
    handlers=[
        logging.FileHandler(LOG_DIR / "queue_runner.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


def get_pending_jobs():
    """Get list of pending .R files, sorted by name."""
    try:
        jobs = sorted([f for f in PENDING_DIR.glob("*.R")])
        return jobs
    except Exception as e:
        logger.error(f"Error listing pending jobs: {e}")
        return []


def run_job(script_path):
    """
    Run an R script.
    Returns (success: bool, output: str, error: str)
    """
    script_name = script_path.name
    logger.info(f"Starting: {script_name}")

    try:
        start_time = time.time()

        # Run R script
        result = subprocess.run(
            ["Rscript", str(script_path)],
            cwd=PIPELINE_ROOT,
            capture_output=True,
            text=True,
            timeout=3600  # 1 hour timeout per job
        )

        elapsed = time.time() - start_time

        if result.returncode == 0:
            logger.info(f"✅ Success: {script_name} ({elapsed:.1f}s)")
            return True, result.stdout, result.stderr
        else:
            logger.error(f"❌ Failed: {script_name} (exit code {result.returncode})")
            return False, result.stdout, result.stderr

    except subprocess.TimeoutExpired:
        logger.error(f"⏱️  Timeout: {script_name} (>1 hour)")
        return False, "", "Script execution timeout (>1 hour)"
    except Exception as e:
        logger.error(f"💥 Error running {script_name}: {e}")
        return False, "", str(e)


def process_job(script_path):
    """Process a single job: run it, save output, move to done/failed."""
    script_name = script_path.name
    running_path = RUNNING_DIR / script_name

    try:
        # Move to running
        shutil.move(str(script_path), str(running_path))

        # Run
        success, stdout, stderr = run_job(running_path)

        # Save output
        output_dir = DONE_DIR if success else FAILED_DIR
        output_path = output_dir / f"{script_name}.log"

        with open(output_path, "w") as f:
            f.write(f"{'='*60}\n")
            f.write(f"Job: {script_name}\n")
            f.write(f"Status: {'SUCCESS' if success else 'FAILED'}\n")
            f.write(f"Time: {datetime.now().isoformat()}\n")
            f.write(f"{'='*60}\n\n")
            f.write("=== STDOUT ===\n")
            f.write(stdout)
            f.write("\n\n=== STDERR ===\n")
            f.write(stderr)

        # Move script to done/failed
        dest_dir = DONE_DIR if success else FAILED_DIR
        shutil.move(str(running_path), str(dest_dir / script_name))

        # Call analyzer if successful
        if success:
            try:
                from queue_analyzer import analyze_results
                analyze_results(script_name, stdout, stderr)
            except Exception as e:
                logger.warning(f"Analyzer failed for {script_name}: {e}")

        return success

    except Exception as e:
        logger.error(f"Error processing job {script_name}: {e}")
        # Try to move back from running to failed
        if running_path.exists():
            shutil.move(str(running_path), str(FAILED_DIR / script_name))
        return False


def queue_status():
    """Return queue status as dict."""
    return {
        "pending": len(list(PENDING_DIR.glob("*.R"))),
        "running": len(list(RUNNING_DIR.glob("*.R"))),
        "done": len(list(DONE_DIR.glob("*.R"))),
        "failed": len(list(FAILED_DIR.glob("*.R"))),
    }


def main():
    """Main queue runner loop."""
    logger.info("=" * 60)
    logger.info("Queue Runner Started")
    logger.info("=" * 60)

    iteration = 0
    consecutive_empty = 0

    while True:
        iteration += 1

        # Check for pending jobs
        pending = get_pending_jobs()

        if not pending:
            consecutive_empty += 1
            status = queue_status()
            if consecutive_empty <= 5:  # Log every 5 empty checks
                logger.info(
                    f"[Iteration {iteration}] No pending jobs. "
                    f"Status: {status['done']} done, {status['failed']} failed"
                )

            # Wait before checking again
            time.sleep(30)
            consecutive_empty = consecutive_empty % 5  # Reset counter every 5
            continue

        consecutive_empty = 0

        # Process first pending job
        job = pending[0]
        status_before = queue_status()
        logger.info(
            f"[Iteration {iteration}] Processing: {job.name} "
            f"(Queue: {status_before['pending']} pending)"
        )

        process_job(job)

        # Small delay between jobs
        time.sleep(2)


if __name__ == "__main__":
    main()

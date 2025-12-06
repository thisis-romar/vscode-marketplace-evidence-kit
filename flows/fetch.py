"""Fetch all Microsoft VS Code extensions from Marketplace."""
import subprocess
from pathlib import Path

from prefect import task, get_run_logger
from prefect.tasks import task_input_hash
from datetime import timedelta


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


@task(
    name="fetch-all-extensions",
    description="Fetch all Microsoft VS Code extensions from Marketplace API",
    retries=2,
    retry_delay_seconds=30,
    cache_key_fn=task_input_hash,
    cache_expiration=timedelta(hours=6),
)
def fetch_all_extensions() -> int:
    """Run fetch_all_extensions.ps1 to pull Microsoft extension data."""
    logger = get_run_logger()
    repo_root = _repo_root()
    script = repo_root / "src" / "scripts" / "fetch_all_extensions.ps1"

    if not script.exists():
        logger.error(f"Missing script: {script}")
        raise FileNotFoundError(f"Script not found: {script}")

    logger.info(f"Running: {script}")
    result = subprocess.run(
        ["pwsh", "-File", str(script)],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        logger.error(f"Script failed:\n{result.stderr}")
        raise RuntimeError(f"fetch_all_extensions.ps1 failed with code {result.returncode}")

    logger.info(result.stdout[-2000:] if len(result.stdout) > 2000 else result.stdout)
    return result.returncode


@task(
    name="fetch-verified-publishers",
    description="Fetch all verified VS Code extension publishers",
    retries=2,
    retry_delay_seconds=30,
    cache_key_fn=task_input_hash,
    cache_expiration=timedelta(hours=6),
)
def fetch_verified_publishers() -> int:
    """Run fetch_verified_publishers.ps1 to pull verified publisher data."""
    logger = get_run_logger()
    repo_root = _repo_root()
    script = repo_root / "src" / "scripts" / "fetch_verified_publishers.ps1"

    if not script.exists():
        logger.error(f"Missing script: {script}")
        raise FileNotFoundError(f"Script not found: {script}")

    logger.info(f"Running: {script}")
    result = subprocess.run(
        ["pwsh", "-File", str(script)],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        logger.error(f"Script failed:\n{result.stderr}")
        raise RuntimeError(f"fetch_verified_publishers.ps1 failed with code {result.returncode}")

    logger.info(result.stdout[-2000:] if len(result.stdout) > 2000 else result.stdout)
    return result.returncode


@task(
    name="fetch-unverified-publishers",
    description="Fetch all unverified VS Code extension publishers",
    retries=2,
    retry_delay_seconds=30,
    cache_key_fn=task_input_hash,
    cache_expiration=timedelta(hours=6),
)
def fetch_unverified_publishers() -> int:
    """Run fetch_unverified_publishers.ps1 to pull unverified publisher data."""
    logger = get_run_logger()
    repo_root = _repo_root()
    script = repo_root / "src" / "scripts" / "fetch_unverified_publishers.ps1"

    if not script.exists():
        logger.error(f"Missing script: {script}")
        raise FileNotFoundError(f"Script not found: {script}")

    logger.info(f"Running: {script}")
    result = subprocess.run(
        ["pwsh", "-File", str(script)],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        logger.error(f"Script failed:\n{result.stderr}")
        raise RuntimeError(f"fetch_unverified_publishers.ps1 failed with code {result.returncode}")

    logger.info(result.stdout[-2000:] if len(result.stdout) > 2000 else result.stdout)
    return result.returncode


if __name__ == "__main__":
    # Allow standalone execution for testing
    fetch_all_extensions()
    fetch_verified_publishers()
    fetch_unverified_publishers()

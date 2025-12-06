"""Validate Microsoft publishers in extension data."""
import subprocess
from pathlib import Path

from prefect import task, get_run_logger


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


@task(
    name="validate-publishers",
    description="Validate that extensions are from verified Microsoft publishers",
    retries=1,
    retry_delay_seconds=10,
)
def validate_publishers() -> int:
    """Run validate_publishers.ps1 to verify publisher authenticity."""
    logger = get_run_logger()
    repo_root = _repo_root()
    script = repo_root / "src" / "scripts" / "validate_publishers.ps1"

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
        logger.warning(f"Validation issues:\n{result.stderr}")
        # Don't fail the pipeline on validation warnings
    
    logger.info(result.stdout[-2000:] if len(result.stdout) > 2000 else result.stdout)
    return result.returncode


if __name__ == "__main__":
    validate_publishers()

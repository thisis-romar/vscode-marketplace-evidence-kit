"""Render markdown documentation from extension data."""
import subprocess
from pathlib import Path

from prefect import task, get_run_logger


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


@task(
    name="generate-ms-extensions-md",
    description="Generate Microsoft_VSCode_Extensions.md from processed data",
    retries=1,
    retry_delay_seconds=5,
)
def generate_ms_extensions_markdown() -> int:
    """Run generate_markdown.ps1 to create Microsoft extensions doc."""
    logger = get_run_logger()
    repo_root = _repo_root()
    script = repo_root / "src" / "scripts" / "generate_markdown.ps1"

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
        raise RuntimeError(f"generate_markdown.ps1 failed with code {result.returncode}")

    logger.info(result.stdout[-1500:] if len(result.stdout) > 1500 else result.stdout)
    return result.returncode


@task(
    name="generate-verified-publishers-md",
    description="Generate Verified_VSCode_Publishers.md from processed data",
    retries=1,
    retry_delay_seconds=5,
)
def generate_verified_publishers_markdown() -> int:
    """Run generate_verified_markdown.ps1 to create verified publishers doc."""
    logger = get_run_logger()
    repo_root = _repo_root()
    script = repo_root / "src" / "scripts" / "generate_verified_markdown.ps1"

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
        raise RuntimeError(f"generate_verified_markdown.ps1 failed with code {result.returncode}")

    logger.info(result.stdout[-1500:] if len(result.stdout) > 1500 else result.stdout)
    return result.returncode


if __name__ == "__main__":
    generate_ms_extensions_markdown()
    generate_verified_publishers_markdown()

"""Render markdown documentation from extension data."""
import os
import subprocess
from pathlib import Path

from prefect import task, get_run_logger


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def _get_ci_env() -> dict:
    """Get CI/CD environment variables to pass to PowerShell scripts."""
    ci_vars = {}
    for var in ["GITHUB_SHA", "GITHUB_RUN_ID", "GITHUB_REPOSITORY", "GITHUB_RUN_NUMBER"]:
        if os.environ.get(var):
            ci_vars[var] = os.environ[var]
    return {**os.environ, **ci_vars}  # Merge with existing env


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
        env=_get_ci_env(),
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
        env=_get_ci_env(),
    )

    if result.returncode != 0:
        logger.error(f"Script failed:\n{result.stderr}")
        raise RuntimeError(f"generate_verified_markdown.ps1 failed with code {result.returncode}")

    logger.info(result.stdout[-1500:] if len(result.stdout) > 1500 else result.stdout)
    return result.returncode


if __name__ == "__main__":
    generate_ms_extensions_markdown()
    generate_verified_publishers_markdown()

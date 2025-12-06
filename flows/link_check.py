"""Link checking for generated documentation."""
import subprocess
import shutil
from pathlib import Path

from prefect import task, get_run_logger


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


@task(
    name="check-links",
    description="Verify all links in generated markdown docs using lychee",
    retries=1,
    retry_delay_seconds=10,
)
def check_links() -> int:
    """Run lychee link checker on docs/public."""
    logger = get_run_logger()
    repo_root = _repo_root()
    docs_public = repo_root / "docs" / "public"

    if not docs_public.exists():
        logger.error(f"Missing docs dir: {docs_public}")
        raise FileNotFoundError(f"Docs directory not found: {docs_public}")

    lychee = shutil.which("lychee")
    if not lychee:
        logger.warning("lychee not found in PATH. Skipping link check.")
        logger.info("To enable, install lychee: https://github.com/lycheeverse/lychee")
        return 0  # Don't fail pipeline if tool is missing locally

    cmd = [
        lychee,
        "--no-progress",
        "--cache",
        "--exclude", "^mailto:",
        "--exclude", "^tel:",
        "--exclude", r"https://marketplace\.visualstudio\.com/items\?itemName=.*#",
        "--exclude", r"https://img\.shields\.io/.*",
        str(docs_public),
    ]

    logger.info(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        logger.warning(f"Link check found issues:\n{result.stdout}\n{result.stderr}")
        # Return code but don't raise - link issues shouldn't block publish
    else:
        logger.info("All links OK")

    return result.returncode


if __name__ == "__main__":
    check_links()

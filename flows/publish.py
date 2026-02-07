"""Publish updated docs: hash-gate and commit changes."""
import hashlib
import json
import subprocess
from datetime import datetime
from pathlib import Path

from prefect import task, get_run_logger


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def _sha256_of_paths(paths: list[Path]) -> str:
    """Compute stable SHA256 hash of file contents."""
    h = hashlib.sha256()
    for p in sorted(paths):
        if p.is_file():
            h.update(p.read_bytes())
            h.update(str(p).encode())
    return h.hexdigest()


@task(
    name="publish-docs",
    description="Commit and push docs if content changed (hash-gated)",
    retries=1,
    retry_delay_seconds=10,
)
def publish_docs() -> dict:
    """Commit changed docs to repo if hash differs from last run."""
    logger = get_run_logger()
    repo_root = _repo_root()
    docs_public = repo_root / "docs" / "public"

    if not docs_public.exists():
        logger.error(f"Missing docs dir: {docs_public}")
        raise FileNotFoundError(f"Docs directory not found: {docs_public}")

    # Compute hash of all markdown files
    all_md = list(docs_public.rglob("*.md"))
    digest = _sha256_of_paths(all_md)
    logger.info(f"Current docs hash: {digest[:12]}...")

    # Load previous run log
    run_log = repo_root / "data" / "run-log.json"
    run_log.parent.mkdir(parents=True, exist_ok=True)
    prev = {}
    if run_log.exists():
        try:
            prev = json.loads(run_log.read_text(encoding="utf-8"))
        except Exception:
            prev = {}

    # Check if content changed
    if prev.get("docs_hash") == digest:
        logger.info("No changes detected; skipping commit.")
        return {"changed": False, "hash": digest}

    # Update run log
    run_log.write_text(
        json.dumps({
            "docs_hash": digest,
            "updated_at": datetime.utcnow().isoformat(),
            "files_count": len(all_md),
        }, indent=2),
        encoding="utf-8",
    )
    logger.info(f"Updated run-log.json with new hash")

    # Commit and push
    logger.info("Committing changes...")
    subprocess.run(["git", "config", "user.name", "github-actions"], check=True)
    subprocess.run(["git", "config", "user.email", "github-actions@github.com"], check=True)
    
    status = subprocess.run(["git", "status", "--porcelain"], capture_output=True, text=True)
    if status.stdout.strip():
        subprocess.run(["git", "add", "-A", str(docs_public), str(run_log)], check=True)
        subprocess.run(
            ["git", "commit", "-m", "docs: refresh marketplace data [skip ci]"],
            check=True,
        )
        subprocess.run(["git", "push"], check=True)
        logger.info("Changes committed and pushed.")
    else:
        logger.info("No git changes to commit.")

    return {"changed": True, "hash": digest}


if __name__ == "__main__":
    result = publish_docs()
    print(result)

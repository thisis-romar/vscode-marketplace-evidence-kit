"""Publish updated docs: hash-gate and optional git commit/push."""

from __future__ import annotations

import hashlib
import json
import os
import subprocess
from datetime import datetime, timezone
from pathlib import Path

from prefect import task, get_run_logger

from flows.runtime import repo_root


def _sha256_of_paths(paths: list[Path]) -> str:
    """Compute stable SHA256 hash of file contents."""
    h = hashlib.sha256()
    for p in sorted(paths):
        if p.is_file():
            h.update(p.read_bytes())
            h.update(str(p).encode())
    return h.hexdigest()


def _env_enabled(var_name: str, default: str = "false") -> bool:
    """Parse boolean environment variable in a permissive way."""
    value = os.getenv(var_name, default).strip().lower()
    return value in {"1", "true", "yes", "on"}


def _current_branch() -> str:
    """Return current git branch name, or empty string when unavailable."""
    result = subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        return ""
    return result.stdout.strip()


def _git_commit_and_push_if_enabled(logger, docs_public: Path, run_log: Path) -> dict:
    """Commit/push guarded by environment toggles; safe by default."""
    commit_enabled = _env_enabled("PIPELINE_COMMIT_DOCS", "false")
    push_enabled = _env_enabled("PIPELINE_PUSH_DOCS", "false")

    if not commit_enabled:
        logger.info("Commit/push disabled (set PIPELINE_COMMIT_DOCS=true to enable).")
        return {"committed": False, "pushed": False}

    # Commit is enabled
    subprocess.run(["git", "config", "user.name", "github-actions"], check=True)
    subprocess.run(["git", "config", "user.email", "github-actions@github.com"], check=True)

    status = subprocess.run(["git", "status", "--porcelain"], capture_output=True, text=True, check=True)
    if not status.stdout.strip():
        logger.info("No git changes to commit.")
        return {"committed": False, "pushed": False}

    subprocess.run(["git", "add", "-A", str(docs_public), str(run_log)], check=True)
    subprocess.run(["git", "commit", "-m", "docs: refresh marketplace data [skip ci]"], check=True)

    if not push_enabled:
        logger.info("Push disabled (set PIPELINE_PUSH_DOCS=true to enable).")
        return {"committed": True, "pushed": False}

    allowed_branches = {
        b.strip() for b in os.getenv("PIPELINE_PUSH_BRANCH_ALLOWLIST", "main").split(",") if b.strip()
    }
    branch = _current_branch()
    if branch and branch not in allowed_branches:
        logger.warning(
            "Push skipped: branch '%s' not in allowlist %s", branch, sorted(allowed_branches)
        )
        return {"committed": True, "pushed": False}

    subprocess.run(["git", "push"], check=True)
    logger.info("Changes committed and pushed.")
    return {"committed": True, "pushed": True}


@task(
    name="publish-docs",
    description="Hash-gate docs update and optionally commit/push when enabled",
    retries=1,
    retry_delay_seconds=10,
)
def publish_docs() -> dict:
    """Commit changed docs to repo if hash differs from last run."""
    logger = get_run_logger()
    root = repo_root()
    docs_public = root / "docs" / "public"

    if not docs_public.exists():
        logger.error(f"Missing docs dir: {docs_public}")
        raise FileNotFoundError(f"Docs directory not found: {docs_public}")

    # Compute hash of all markdown files
    all_md = list(docs_public.rglob("*.md"))
    digest = _sha256_of_paths(all_md)
    logger.info(f"Current docs hash: {digest[:12]}...")

    # Load previous run log
    run_log = root / "data" / "run-log.json"
    run_log.parent.mkdir(parents=True, exist_ok=True)
    prev = {}
    if run_log.exists():
        try:
            prev = json.loads(run_log.read_text(encoding="utf-8"))
        except Exception:
            prev = {}

    # Check if content changed
    if prev.get("docs_hash") == digest:
        logger.info("No changes detected; skipping commit/push.")
        return {"changed": False, "hash": digest, "committed": False, "pushed": False}

    # Update run log
    run_log.write_text(
        json.dumps(
            {
                "docs_hash": digest,
                "updated_at": datetime.now(timezone.utc).isoformat(),
                "files_count": len(all_md),
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    logger.info("Updated run-log.json with new hash")

    git_result = _git_commit_and_push_if_enabled(logger, docs_public, run_log)
    return {"changed": True, "hash": digest, **git_result}


if __name__ == "__main__":
    result = publish_docs()
    print(result)

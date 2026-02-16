"""Tests for guarded publish behavior."""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from flows import publish


class DummyLogger:
    def info(self, *_args, **_kwargs):
        pass

    def warning(self, *_args, **_kwargs):
        pass

    def error(self, *_args, **_kwargs):
        pass


def _prepare_repo(tmp_path: Path) -> Path:
    root = tmp_path
    (root / "docs" / "public").mkdir(parents=True)
    (root / "docs" / "public" / "sample.md").write_text("# hello", encoding="utf-8")
    (root / "data").mkdir(parents=True)
    return root


def test_publish_default_does_not_run_git(monkeypatch, tmp_path: Path):
    root = _prepare_repo(tmp_path)
    monkeypatch.setattr(publish, "repo_root", lambda: root)
    monkeypatch.setattr(publish, "get_run_logger", lambda: DummyLogger())

    calls = []

    def fake_run(cmd, **kwargs):
        calls.append(cmd)

        class Result:
            returncode = 0
            stdout = ""
            stderr = ""

        return Result()

    monkeypatch.setattr(publish.subprocess, "run", fake_run)

    result = publish.publish_docs.fn()

    assert result["changed"] is True
    assert result["committed"] is False
    assert result["pushed"] is False
    assert calls == []


def test_publish_commit_enabled_without_push(monkeypatch, tmp_path: Path):
    root = _prepare_repo(tmp_path)
    monkeypatch.setattr(publish, "repo_root", lambda: root)
    monkeypatch.setattr(publish, "get_run_logger", lambda: DummyLogger())
    monkeypatch.setenv("PIPELINE_COMMIT_DOCS", "true")
    monkeypatch.setenv("PIPELINE_PUSH_DOCS", "false")

    calls = []

    def fake_run(cmd, **kwargs):
        calls.append(cmd)

        class Result:
            returncode = 0
            stdout = " M docs/public/sample.md"
            stderr = ""

        if cmd[:3] == ["git", "status", "--porcelain"]:
            return Result()
        return Result()

    monkeypatch.setattr(publish.subprocess, "run", fake_run)

    result = publish.publish_docs.fn()

    assert result["committed"] is True
    assert result["pushed"] is False
    assert ["git", "commit", "-m", "docs: refresh marketplace data [skip ci]"] in calls
    assert ["git", "push"] not in calls


def test_publish_skips_when_hash_unchanged(monkeypatch, tmp_path: Path):
    root = _prepare_repo(tmp_path)
    monkeypatch.setattr(publish, "repo_root", lambda: root)
    monkeypatch.setattr(publish, "get_run_logger", lambda: DummyLogger())

    md = [root / "docs" / "public" / "sample.md"]
    digest = publish._sha256_of_paths(md)
    run_log = root / "data" / "run-log.json"
    run_log.write_text(json.dumps({"docs_hash": digest}), encoding="utf-8")

    result = publish.publish_docs.fn()

    assert result["changed"] is False
    assert result["committed"] is False
    assert result["pushed"] is False

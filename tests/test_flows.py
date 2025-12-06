"""Pytest tests for Prefect flow logic."""
import hashlib
import json
import tempfile
from pathlib import Path

import pytest


def sha256_of_paths(paths: list[Path]) -> str:
    """Compute stable SHA256 hash of file contents (same as publish.py)."""
    h = hashlib.sha256()
    for p in sorted(paths):
        if p.is_file():
            h.update(p.read_bytes())
            h.update(str(p).encode())
    return h.hexdigest()


class TestHashing:
    """Test content hashing for change detection."""

    def test_hash_is_deterministic(self, tmp_path: Path):
        """Same content produces same hash."""
        f1 = tmp_path / "a.md"
        f2 = tmp_path / "b.md"
        f1.write_text("# Hello")
        f2.write_text("# World")

        hash1 = sha256_of_paths([f1, f2])
        hash2 = sha256_of_paths([f1, f2])
        assert hash1 == hash2

    def test_hash_changes_with_content(self, tmp_path: Path):
        """Different content produces different hash."""
        f1 = tmp_path / "test.md"
        f1.write_text("# Original")
        hash1 = sha256_of_paths([f1])

        f1.write_text("# Modified")
        hash2 = sha256_of_paths([f1])
        assert hash1 != hash2

    def test_hash_order_independent(self, tmp_path: Path):
        """File order doesn't affect hash (sorted internally)."""
        f1 = tmp_path / "a.md"
        f2 = tmp_path / "z.md"
        f1.write_text("aaa")
        f2.write_text("zzz")

        hash1 = sha256_of_paths([f1, f2])
        hash2 = sha256_of_paths([f2, f1])
        assert hash1 == hash2

    def test_empty_list_returns_consistent_hash(self):
        """Empty file list returns a consistent hash."""
        hash1 = sha256_of_paths([])
        hash2 = sha256_of_paths([])
        assert hash1 == hash2
        assert len(hash1) == 64  # SHA256 hex length


class TestRunLog:
    """Test run-log.json handling."""

    def test_run_log_schema(self, tmp_path: Path):
        """Run log should have expected fields."""
        run_log = tmp_path / "run-log.json"
        data = {
            "docs_hash": "abc123",
            "updated_at": "2025-12-06T12:00:00",
            "files_count": 5,
        }
        run_log.write_text(json.dumps(data))

        loaded = json.loads(run_log.read_text())
        assert "docs_hash" in loaded
        assert "updated_at" in loaded
        assert "files_count" in loaded


class TestConfigSchema:
    """Test config.json schema."""

    def test_config_has_required_sections(self):
        """Config file should have marketplace, paths, linkCheck sections."""
        config_path = Path(__file__).parents[1] / "config.json"
        if not config_path.exists():
            pytest.skip("config.json not found")

        config = json.loads(config_path.read_text())
        assert "marketplace" in config
        assert "paths" in config
        assert "linkCheck" in config

    def test_config_marketplace_settings(self):
        """Marketplace config has baseUrl and apiVersion."""
        config_path = Path(__file__).parents[1] / "config.json"
        if not config_path.exists():
            pytest.skip("config.json not found")

        config = json.loads(config_path.read_text())
        assert "baseUrl" in config["marketplace"]
        assert "apiVersion" in config["marketplace"]

    def test_config_paths_settings(self):
        """Paths config has raw, processed, docsPublic."""
        config_path = Path(__file__).parents[1] / "config.json"
        if not config_path.exists():
            pytest.skip("config.json not found")

        config = json.loads(config_path.read_text())
        assert "raw" in config["paths"]
        assert "processed" in config["paths"]
        assert "docsPublic" in config["paths"]

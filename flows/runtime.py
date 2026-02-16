"""Runtime helpers for flow/task environment checks."""

from __future__ import annotations

import shutil
from pathlib import Path


class RuntimeDependencyError(RuntimeError):
    """Raised when a required runtime dependency is unavailable."""


def repo_root() -> Path:
    """Return repository root from current package location."""
    return Path(__file__).resolve().parents[1]


def ensure_pwsh_available() -> str:
    """Return resolved pwsh executable path or raise a clear error."""
    pwsh = shutil.which("pwsh")
    if not pwsh:
        raise RuntimeDependencyError(
            "PowerShell executable 'pwsh' is required but was not found in PATH. "
            "Install PowerShell 7+ and retry."
        )
    return pwsh

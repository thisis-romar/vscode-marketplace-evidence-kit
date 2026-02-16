# Branch Audit Report

- **Repository:** `vscode-marketplace-evidence-kit`
- **Branch:** `work`
- **Audit date:** 2026-02-16 (UTC)
- **Auditor:** Codex (GPT-5.2-Codex)

## Scope

This audit covered:

1. Pipeline orchestration (`flows/*.py`)
2. CI configuration (`.github/workflows/ci.yml`)
3. Dependency and environment setup (`requirements.txt`, `prefect.yaml`, `config.json`)
4. Existing automated tests (`tests/*`)
5. Basic static risk patterns and runtime checks

## Commands Executed

- `pytest -q`
- `pwsh -NoLogo -NoProfile -Command "Invoke-Pester tests/Pipeline.Tests.ps1 -Output Detailed"`
- `pip check`
- `python -m compileall -q flows tests`
- `python -m pip install -q pip-audit && pip-audit -r requirements.txt`
- `rg -n "shell=True|subprocess\.Popen|eval\(|exec\(|pickle\.loads|yaml\.load\(" flows src tests .github README.md`

## Executive Summary

The branch is generally healthy for Python unit coverage and basic dependency consistency, but there are **operational and governance risks** around PowerShell runtime coupling, in-flow Git push behavior, and dependency pinning strategy.

- ✅ **Current Python tests pass** (8/8).
- ⚠️ **PowerShell/Pester tests could not be executed** in this Linux environment due to missing `pwsh`.
- ⚠️ **Security dependency audit tool (`pip-audit`) could not be installed** due to network/proxy restrictions.
- ⚠️ **Pipeline publish stage performs direct Git commit/push from task code**; this is effective but high side-effect and can be dangerous outside CI.

## Findings

## 1) High: Publish task performs write operations to Git remote from runtime flow

**Evidence:** `flows/publish.py` configures git identity, commits, and pushes in task code.

**Risk:**
- Running the flow outside CI may cause unexpected commits/pushes.
- Failures mid-flow can leave partial state changes.
- Least-privilege principle is weakened when application logic directly mutates VCS state.

**Recommendation:**
- Gate push behavior behind explicit environment checks (`CI=true` + allowlist branch).
- Split publish logic into:
  - deterministic hash/update logic in Python task
  - commit/push in CI workflow step only
- Add dry-run mode default for local execution.

## 2) Medium: Cross-platform runtime fragility due to required `pwsh`

**Evidence:** All fetch/validate/render tasks invoke PowerShell scripts via `pwsh`.

**Risk:**
- Local development and some Linux runners fail without PowerShell.
- Limits reproducibility for contributors without Windows/PowerShell setup.

**Recommendation:**
- Add startup preflight in pipeline to check `pwsh` availability and fail with actionable message.
- Document platform requirements prominently.
- Consider gradual migration of critical scripts to Python for portable execution.

## 3) Medium: Dependency version ranges are broad and not reproducibility-focused

**Evidence:** `requirements.txt` uses minimal lower bounds (`prefect>=3.0`, etc.).

**Risk:**
- Different installs can resolve to different major/minor versions.
- Potential unexpected behavior drift over time.

**Recommendation:**
- Introduce a lock strategy (`pip-tools` or pinned `requirements-lock.txt`) for CI.
- Keep human-edited `requirements.in` (or equivalent) and compile pinned transitive deps for deterministic builds.

## 4) Medium: Test coverage is mainly utility/schema-level, limited integration coverage for task execution

**Evidence:** `tests/test_flows.py` validates hashing and config schema but not runtime orchestration with subprocess invocation or failure pathways.

**Risk:**
- Regressions in task command invocation, error handling, and sequencing could slip through.

**Recommendation:**
- Add pytest tests with monkeypatch for `subprocess.run` in `flows/fetch.py`, `flows/render.py`, `flows/validate.py`, and `flows/publish.py`.
- Add explicit tests for non-zero return codes and missing script behavior.

## 5) Low: Link-check install and runtime behavior is permissive by design

**Evidence:** CI installs `lychee` with `continue-on-error: true`; runtime check returns success when lychee is unavailable.

**Risk:**
- Broken links may go undetected for periods if tooling install fails.

**Recommendation:**
- Keep permissive behavior for non-blocking docs generation if desired, but emit clear CI annotations/warnings when link checks are skipped.
- Optionally require periodic strict link-check runs (e.g., weekly strict job).

## Checks and Results

| Check | Result | Notes |
|---|---|---|
| Python unit tests (`pytest`) | PASS | 8 passed |
| PowerShell tests (Pester) | WARN | `pwsh` not available in this environment |
| Python dependency consistency (`pip check`) | PASS | No broken requirements |
| Bytecode compilation (`compileall`) | PASS | No compile errors in `flows/` and `tests/` |
| Security dependency scan (`pip-audit`) | WARN | Install blocked by proxy/network restrictions |
| Dangerous dynamic execution pattern scan | PASS | No `shell=True` / `eval` / `exec` usage found in scanned paths |

## Priority Remediation Plan

1. **Immediate (High):** Move commit/push to CI workflow layer and add guarded publish modes.
2. **Near-term:** Add `pwsh` preflight + contributor setup guidance.
3. **Near-term:** Introduce dependency lockfile process for CI determinism.
4. **Near-term:** Add subprocess-focused unit tests for flow modules.
5. **Later:** Harden link-check observability and optionally add strict periodic validation.

---

If you want, I can implement the top two remediations in this branch next (publish guardrails + PowerShell preflight) in a follow-up change set.

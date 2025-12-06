# VSCode Marketplace Evidence Kit

[![Docs Pipeline](https://github.com/thisis-romar/vscode-marketplace-evidence-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/thisis-romar/vscode-marketplace-evidence-kit/actions/workflows/ci.yml)

**Catalog, verify, and document VS Code extensions and verified publishers**  
**Last Updated:** 2025-12-06  
**Status:** 🧪 Prototype Branch (`feat/dir-architecture-prototype`)

> Data-backed verification outputs for the VS Code Marketplace ecosystem.  
> Automated via **Prefect** orchestration with nightly CI refresh.

---

## 📁 Directory Structure

```
.
├── README.md                    # This file
├── config.json                  # Pipeline configuration
├── requirements.txt             # Python dependencies
├── prefect.yaml                 # Prefect deployment config
├── flows/                       # Prefect orchestration flows
│   ├── __init__.py
│   ├── pipeline.py              # Main @flow entrypoint
│   ├── fetch.py                 # Fetch tasks (@task)
│   ├── validate.py              # Validation tasks
│   ├── render.py                # Markdown generation tasks
│   ├── link_check.py            # Link checking task
│   └── publish.py               # Hash-gated publish task
├── src/
│   └── scripts/                 # PowerShell data scripts
│       ├── fetch_all_extensions.ps1
│       ├── fetch_verified_publishers.ps1
│       ├── generate_markdown.ps1
│       ├── generate_verified_markdown.ps1
│       ├── validate_publishers.ps1
│       ├── check_links.ps1
│       └── check_links_quick.ps1
├── data/
│   ├── raw/                     # Timestamped snapshots
│   ├── processed/               # Curated latest data
│   └── run-log.json             # Hash gate log
├── docs/
│   └── public/                  # Generated markdown (published)
│       ├── Microsoft_VSCode_Extensions.md
│       └── Verified_VSCode_Publishers.md
├── tests/
│   ├── Pipeline.Tests.ps1       # Pester tests (PowerShell)
│   └── test_flows.py            # pytest tests (Python)
└── .github/
    └── workflows/
        └── ci.yml               # GitHub Actions (nightly + manual)
```

### Scripts (`src/scripts/`)

| Script | Purpose |
|--------|---------|
| `fetch_all_extensions.ps1` | Fetch Microsoft VS Code extensions |
| `fetch_verified_publishers.ps1` | Fetch ALL verified publishers |
| `generate_markdown.ps1` | Generate Microsoft extensions markdown |
| `generate_verified_markdown.ps1` | Generate verified publishers catalog |
| `validate_publishers.ps1` | Validate publisher authenticity |
| `check_links.ps1` | Comprehensive link checker |
| `check_links_quick.ps1` | Quick marketplace link validator |

### Data (`data/`)

| Path | Contents |
|------|----------|
| `data/raw/` | Raw API responses (all_verified_extensions.json) |
| `data/processed/` | Processed summaries (verified_publishers.json) |
| `data/all_extensions.json` | Microsoft-only extensions (legacy path) |

### Documentation (`docs/`)

| Path | Contents |
|------|----------|
| `docs/public/` | Generated markdown for publishing |
| `docs/Microsoft_VSCode_Extensions.md` | Microsoft catalog (legacy path) |
| `docs/REMOVED_EXTENSIONS.md` | Removed/unpublished extensions tracking |

### Archive (`Archive/`)

Git-ignored folder containing backups and old versions:
- `scripts/` - Old/utility scripts
- `data/` - Backup data files
- `docs/` - Old documentation versions
- `backup_*/` - Timestamped full backups

---

## 🏗️ Architecture

### Prefect Orchestration

The pipeline uses **Prefect** for orchestration with `@task` and `@flow` decorators:

```
┌─────────────────────────────────────────────────────────────┐
│                   docs_pipeline (@flow)                     │
├─────────────────────────────────────────────────────────────┤
│  fetch_all_extensions (@task)                               │
│  fetch_verified_publishers (@task)                          │
│           ↓                                                 │
│  validate_publishers (@task)                                │
│           ↓                                                 │
│  generate_ms_extensions_markdown (@task)                    │
│  generate_verified_publishers_markdown (@task)              │
│           ↓                                                 │
│  check_links (@task) ─ lychee                               │
│           ↓                                                 │
│  publish_docs (@task) ─ hash-gated commit                   │
└─────────────────────────────────────────────────────────────┘
```

**Key features:**
- ✅ Automatic retries with backoff
- ✅ Structured logging via Prefect
- ✅ Hash-gated publishing (skip if unchanged)
- ✅ Caching for expensive fetch tasks
- ✅ Build metadata in generated docs (commit SHA, run ID, timestamps)

### CI/CD Schedule

| Trigger | Time | Description |
|---------|------|-------------|
| Cron | `03:17 UTC` daily | Nightly refresh |
| Manual | `workflow_dispatch` | On-demand via GitHub UI |

### Path Management
All scripts use **dynamic path resolution** via `Get-RepoRoot` function:
- ✅ Computes repository root by walking up to find `README.md`
- ✅ Works whether scripts are in root or `src/scripts/`
- ✅ No hardcoded absolute paths
- ✅ Safe to relocate scripts

### Script Execution Flow

**Microsoft Extensions Flow:**
```
src/scripts/fetch_all_extensions.ps1
    ↓ Filters by isDomainVerified + microsoft.com domain
    ↓ Saves to data/all_extensions.json
src/scripts/generate_markdown.ps1
    ↓ Reads data/all_extensions.json
    ↓ Outputs docs/Microsoft_VSCode_Extensions.md
```

**All Verified Publishers Flow:**
```
src/scripts/fetch_verified_publishers.ps1
    ↓ Fetches top 5000 extensions by install count
    ↓ Filters by isDomainVerified=true (any domain)
    ↓ Saves to data/raw/all_verified_extensions.json
    ↓ Saves to data/processed/verified_publishers.json
src/scripts/generate_verified_markdown.ps1
    ↓ Reads data/processed/verified_publishers.json
    ↓ Outputs docs/public/Verified_VSCode_Publishers.md
```

---

## 🚀 Quick Start

### Prerequisites

```powershell
# Python 3.12+ with pip
python --version

# PowerShell 7+
pwsh --version

# (Optional) lychee for link checking
# https://github.com/lycheeverse/lychee
```

### Install Dependencies

```powershell
pip install -r requirements.txt
```

### Run the Full Pipeline (Prefect)

```powershell
# Run the Prefect flow locally
python -m flows.pipeline
```

### Run Individual Steps (PowerShell)

```powershell
# Fetch Microsoft-verified extensions
.\src\scripts\fetch_all_extensions.ps1

# Fetch ALL verified publishers
.\src\scripts\fetch_verified_publishers.ps1

# Generate markdown docs
.\src\scripts\generate_markdown.ps1
.\src\scripts\generate_verified_markdown.ps1
```

### Run Tests

```powershell
# Python tests
pytest tests/

# PowerShell tests (Pester)
Invoke-Pester -Path .\tests\
```

---

## 🔧 Troubleshooting

### Pipeline Fails on Fetch

- **Rate limiting:** The Marketplace API may throttle requests. Retries are built-in (2 attempts, 30s backoff).
- **Network issues:** Check connectivity to `marketplace.visualstudio.com`.

### Link Check Warnings

- lychee may report false positives for dynamic pages. Excludes are configured in `flows/link_check.py`.
- To skip link check locally, comment out the `check_links()` call in `flows/pipeline.py`.

### Hash Gate Skipping Publish

- If `data/run-log.json` shows the same `docs_hash`, no changes were detected.
- Delete `run-log.json` to force a fresh publish.

### Prefect Logs

- Set `PREFECT_LOGGING_LEVEL=DEBUG` for verbose output.
- Logs are structured and can be viewed in Prefect UI if connected to Prefect Cloud.

---

## 🔧 Maintenance

### Archived Tools

Legacy maintenance tools are available in `Archive/scripts/`:
- `fix_script_paths.ps1` - Detects and fixes hardcoded paths
- `restructure_project.ps1` - Project restructuring utility

These tools were used during initial development and are preserved for reference.

---

## 📊 Statistics

### All Verified Publishers (New)
- **Verified Publishers:** 304
- **Total Extensions:** 710+
- **Unique Domains:** 245
- **Total Installs:** ~3B

### Microsoft Extensions (Legacy)
- **Total Extensions:** 329
- **Unpublished/Removed:** 135
- **Categories:** 25

---

## 🔄 Workflow

### Verified Publishers Workflow (Recommended)
1. **Fetch** → `.\src\scripts\fetch_verified_publishers.ps1`
2. **Generate** → `.\src\scripts\generate_verified_markdown.ps1`
3. **Validate** → `.\src\scripts\check_links_quick.ps1`
4. **Review** → Check `docs/public/Verified_VSCode_Publishers.md`

### Microsoft-Only Workflow (Legacy)
1. **Fetch** → `.\src\scripts\fetch_all_extensions.ps1`
2. **Generate** → `.\src\scripts\generate_markdown.ps1`
3. **Review** → Check `docs/Microsoft_VSCode_Extensions.md`

---

## ✨ Features

### Fetch Script
- ✅ Dynamic page fetching (no hard-coded limits)
- ✅ Filters out unpublished extensions (prevents 404s)
- ✅ API total count validation
- ✅ Detailed progress logging

### Markdown Generator
- ✅ 25 categories with auto-categorization
- ✅ Sorted by install count within categories
- ✅ Enhanced TOC with icons and statistics
- ✅ Dual numbering (per-category + global)
- ✅ Resources, Categories, Tags, Platform compatibility
- ✅ Back-to-TOC navigation links

### Build Traceability
Generated markdown documents include CI/CD build metadata for auditability:

**Visible in header:**
```markdown
*Last Updated: December 6, 2025 at 03:17:00 UTC*
[`abc1234`](https://github.com/.../commit/abc1234) • [Run #42](https://github.com/.../actions/runs/42)
```

**Hidden metadata block:**
```html
<!-- BUILD_METADATA
timestamp: 2025-12-06T03:17:00Z
commit: abc1234
run_id: 42
data_source: 2025-12-05T22:29:53Z
publishers: 304
extensions: 711
-->
```

**Environment variables used:**
| Variable | Purpose |
|----------|--------|
| `GITHUB_SHA` | Git commit hash (truncated to 7 chars) |
| `GITHUB_RUN_ID` | GitHub Actions run identifier |
| `GITHUB_REPOSITORY` | Repo for building links |

> 💡 Local runs display `Build: local • Run: manual` instead of linked values.

### Link Checkers
- ✅ Validates marketplace links
- ✅ Detects 404 pages with 200 status codes
- ✅ Progress tracking
- ✅ Detailed reporting

---

## 📝 File Descriptions

### Scripts (`src/scripts/`)

| File | Purpose |
|------|---------|
| `fetch_all_extensions.ps1` | Fetches Microsoft extensions from Marketplace API |
| `fetch_verified_publishers.ps1` | Fetches all verified publishers (any domain) |
| `generate_markdown.ps1` | Generates Microsoft extensions markdown |
| `generate_verified_markdown.ps1` | Generates verified publishers catalog |
| `validate_publishers.ps1` | Validates publisher authenticity |
| `check_links.ps1` | Comprehensive URL link checker |
| `check_links_quick.ps1` | Quick marketplace link validator |

### Data Files

| File | Location | Purpose |
|------|----------|---------|
| `all_verified_extensions.json` | `data/raw/` | Raw API output (710+ extensions) |
| `verified_publishers.json` | `data/processed/` | Publisher summary (304 publishers) |
| `all_extensions.json` | `data/` | Microsoft extensions (legacy) |

### Documentation

| File | Location | Purpose |
|------|----------|---------|
| `Verified_VSCode_Publishers.md` | `docs/public/` | Complete verified publishers catalog |
| `Microsoft_VSCode_Extensions.md` | `docs/` | Microsoft extensions catalog (legacy) |
| `REMOVED_EXTENSIONS.md` | `docs/` | Removed/unpublished tracking |

---

## 🗂️ Archive

Old versions and utility tools are kept in the `Archive/` folder (git-ignored):
- `scripts/` - Legacy analysis and maintenance scripts
- `data/` - Backup data files and old snapshots
- `docs/` - Previous documentation versions
- `backup_*/` - Timestamped full project backups

---

## 📚 Related Links

- [VS Code Marketplace](https://marketplace.visualstudio.com/vscode)
- [VS Code Extension API](https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery)
- [Publisher Verification Docs](https://code.visualstudio.com/api/working-with-extensions/publishing-extension#verify-a-publisher)

---

## 🌿 Branch Information

**Current Branch:** `feat/dir-architecture-prototype`

This branch prototypes a new directory architecture:
- Scripts moved to `src/scripts/`
- Data split into `data/raw/` and `data/processed/`
- Published docs in `docs/public/`
- Dynamic `Get-RepoRoot` path resolution

To return to the stable version:
```powershell
git checkout main
```

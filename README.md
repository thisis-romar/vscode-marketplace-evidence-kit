# VSCode Marketplace Evidence Kit

**Catalog, verify, and document VS Code extensions and verified publishers**  
**Last Updated:** 2025-12-05  
**Status:** 🧪 Prototype Branch (`feat/dir-architecture-prototype`)

> Data-backed verification outputs for the VS Code Marketplace ecosystem.

---

## 📁 Directory Structure

```
.
├── README.md                    # This file
├── src/
│   └── scripts/                 # All active PowerShell scripts
│       ├── fetch_all_extensions.ps1
│       ├── fetch_verified_publishers.ps1
│       ├── generate_markdown.ps1
│       ├── generate_verified_markdown.ps1
│       ├── validate_publishers.ps1
│       ├── check_links.ps1
│       └── check_links_quick.ps1
├── data/
│   ├── raw/                     # Raw API outputs
│   │   └── all_verified_extensions.json
│   ├── processed/               # Processed summaries
│   │   └── verified_publishers.json
│   └── all_extensions.json      # Microsoft-only extensions (legacy)
├── docs/
│   ├── public/                  # Generated markdown for publishing
│   │   └── Verified_VSCode_Publishers.md
│   ├── Microsoft_VSCode_Extensions.md  # Microsoft catalog (legacy)
│   └── REMOVED_EXTENSIONS.md
└── Archive/                     # Backups and old versions (git-ignored)
    ├── scripts/
    ├── data/
    ├── docs/
    └── backup_*/
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

### Microsoft Extensions Only
```powershell
# Fetch Microsoft-verified extensions
.\src\scripts\fetch_all_extensions.ps1

# Generate Microsoft extensions documentation
.\src\scripts\generate_markdown.ps1
```

### All Verified Publishers
```powershell
# Fetch ALL verified publishers from marketplace
.\src\scripts\fetch_verified_publishers.ps1

# Generate verified publishers catalog
.\src\scripts\generate_verified_markdown.ps1
```

### Validate Links
```powershell
# Quick validation (marketplace links only)
.\src\scripts\check_links_quick.ps1

# Comprehensive validation (all links)
.\src\scripts\check_links.ps1
```

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

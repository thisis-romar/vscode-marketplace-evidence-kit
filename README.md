# Project Directory - README

**VS Code Extensions Documentation Project**  
**Last Updated:** 2025-12-05  
**Status:** ✅ Production Ready

---

## 📁 Directory Structure

### Root Directory (Tools & Scripts)

**Microsoft Extensions Tools:**
- `fetch_all_extensions.ps1` - Fetches all Microsoft VS Code extensions from marketplace
- `generate_markdown.ps1` - Generates Microsoft extensions markdown documentation
- `validate_publishers.ps1` - Validates Microsoft publisher authenticity

**All Verified Publishers Tools:**
- `fetch_verified_publishers.ps1` - Fetches ALL verified publishers from marketplace
- `generate_verified_markdown.ps1` - Generates verified publishers markdown catalog

**Link Validation Tools:**
- `check_links.ps1` - Comprehensive link checker for all URLs
- `check_links_quick.ps1` - Quick marketplace link validator

**Project Documentation:**
- `README.md` - This file

### Data Directory (`data/`)

**Microsoft Extensions Data:**
- `all_extensions.json` - Microsoft extensions data (329 verified extensions)

**All Verified Publishers Data:**
- `all_verified_extensions.json` - All verified extensions (710+ extensions)
- `verified_publishers.json` - Publisher summary with domain stats (300+ publishers)

### Documentation Directory (`docs/`)

**Generated Documentation:**
- `Microsoft_VSCode_Extensions.md` - Microsoft extensions catalog (329 extensions, 25 categories)
- `Verified_VSCode_Publishers.md` - All verified publishers catalog (300+ publishers, 240+ domains)
- `REMOVED_EXTENSIONS.md` - Tracking removed/unpublished extensions

### Archive Directory (`Archive/`)

**Organized by type:**
- `scripts/` - Old/utility scripts
- `data/` - Backup data files  
- `docs/` - Old documentation versions
- `backup_20251205_121654/` - Full project backup

---

## 🏗️ Architecture

### Path Management
All scripts use **dynamic paths** based on `$PSScriptRoot` to ensure portability:
- ✅ No hardcoded absolute paths
- ✅ Works regardless of installation directory
- ✅ Safe to move or restructure

### Script Execution Flow

**Microsoft Extensions Flow:**
```
fetch_all_extensions.ps1
    ↓ Filters by isDomainVerified + microsoft.com domain
    ↓ Saves to data/all_extensions.json
generate_markdown.ps1
    ↓ Reads data/all_extensions.json
    ↓ Outputs docs/Microsoft_VSCode_Extensions.md
```

**All Verified Publishers Flow:**
```
fetch_verified_publishers.ps1
    ↓ Fetches top 5000 extensions by install count
    ↓ Filters by isDomainVerified=true (any domain)
    ↓ Saves to data/all_verified_extensions.json
    ↓ Saves to data/verified_publishers.json
generate_verified_markdown.ps1
    ↓ Reads data/verified_publishers.json
    ↓ Outputs docs/Verified_VSCode_Publishers.md
```

---

## 🚀 Quick Start

### Microsoft Extensions Only
```powershell
# Fetch Microsoft-verified extensions
.\fetch_all_extensions.ps1

# Generate Microsoft extensions documentation
.\generate_markdown.ps1
```

### All Verified Publishers
```powershell
# Fetch ALL verified publishers from marketplace
.\fetch_verified_publishers.ps1

# Generate verified publishers catalog
.\generate_verified_markdown.ps1
```

### Validate Links
```powershell
# Quick validation (marketplace links only)
.\check_links_quick.ps1

# Comprehensive validation (all links)
.\check_links.ps1
```

---

## 🔧 Maintenance Tools

### Path Correction Tool
```powershell
# Analyze scripts for hardcoded paths (dry-run)
.\fix_script_paths.ps1 -DryRun

# Fix hardcoded paths in all scripts
.\fix_script_paths.ps1
```
- Automatically detects hardcoded paths in PowerShell scripts
- Converts them to dynamic `$PSScriptRoot`-based paths
- Creates backups before making changes
- Safe to run multiple times

### Complete Restructuring Tool
```powershell
# Restructure entire project (creates backup automatically)
.\restructure_project.ps1
```
- Creates organized directory structure (data\, docs\, output\)
- Fixes all hardcoded paths in scripts
- Moves files to appropriate locations
- Validates all changes
- Creates automatic backup

---

## 📊 Statistics

- **Total Extensions:** 331 (Microsoft publishers only)
- **Unpublished/Removed:** 135 extensions
- **Categories:** 25
- **Total Links:** 1,525 unique URLs
- **Documentation Size:** 545KB

---

## 🔄 Workflow

1. **Fetch** → Run `fetch_all_extensions.ps1` to get latest data
2. **Generate** → Run `generate_markdown.ps1` to create documentation
3. **Validate** → Run `check_links_quick.ps1` to verify all links work
4. **Review** → Check `Microsoft_VSCode_Extensions.md` for accuracy

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

| File | Purpose | Size |
|------|---------|------|
| `all_extensions.json` | Current extension data | 2.85MB |
| `fetch_all_extensions.ps1` | Extension fetcher | 4KB |
| `generate_markdown.ps1` | Documentation generator | 22KB |
| `check_links.ps1` | Comprehensive link checker | 9KB |
| `check_links_quick.ps1` | Quick link validator | 6KB |
| `Microsoft_VSCode_Extensions.md` | Main documentation | 545KB |
| `REMOVED_EXTENSIONS.md` | Removed extensions list | 7KB |

---

## 🗂️ Archive

Old versions and analysis tools are kept in the `Archive/` folder for reference:
- Version 1 markdown generator and documentation
- Old extension data
- Analysis tools used during development

---

## 📚 Related Links

- [VS Code Marketplace](https://marketplace.visualstudio.com/publishers/Microsoft)
- [VS Code Extension API](https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery)

---

**Total Project Size:** 3.44MB (active) + 1.11MB (archive)  
**Space Saved by Cleanup:** 10.21MB

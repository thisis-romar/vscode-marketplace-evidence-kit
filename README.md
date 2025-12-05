# Project Directory - README

**Microsoft VS Code Extensions Documentation Project**  
**Last Updated:** 2025-12-05  
**Status:** ✅ Restructured & Production Ready

---

## 📁 Directory Structure

### Root Directory (Tools & Scripts)

**Core Tools:**
- `fetch_all_extensions.ps1` - Fetches all Microsoft VS Code extensions from marketplace
- `generate_markdown.ps1` - Generates comprehensive markdown documentation
- `check_links.ps1` - Comprehensive link checker for all URLs
- `check_links_quick.ps1` - Quick marketplace link validator

**Maintenance Tools:**
- `fix_script_paths.ps1` - Detects and fixes hardcoded paths in PowerShell scripts
- `restructure_project.ps1` - Complete project restructuring automation

**Project Documentation:**
- `README.md` - This file

### Data Directory (`data\`)

**Extension Data:**
- `all_extensions.json` (1.92MB) - Current extension data (331 Microsoft-published extensions)

### Documentation Directory (`docs\`)

**Generated Documentation:**
- `Microsoft_VSCode_Extensions.md` - Complete reference guide (331 Microsoft extensions)
- `REMOVED_EXTENSIONS.md` - List of unpublished/removed extensions (135 extensions)

### Output Directory (`output\`)

**Generated Reports:**
- `link_check_report.json` - Link validation results (generated when check_links.ps1 runs)

### Archive Directory (`Archive\`)

**Old Versions:**
- `generate_markdown.ps1` - Version 1 markdown generator
- `Microsoft_VSCode_Extensions.md` - Version 1 documentation (uncategorized)
- `extensions_data.json` - Old extension data

**Analysis Tools:**
- `analyze_extension_fields.ps1` - Extension field analysis tool

---

## 🏗️ Architecture

### Path Management
All scripts use **dynamic paths** based on `$PSScriptRoot` to ensure portability:
- ✅ No hardcoded absolute paths
- ✅ Works regardless of installation directory
- ✅ Safe to move or restructure

### Script Execution Flow
```
fetch_all_extensions.ps1
    ↓ Saves to data\all_extensions.json
generate_markdown.ps1
    ↓ Reads from data\all_extensions.json
    ↓ Outputs to docs\Microsoft_VSCode_Extensions.md
check_links_quick.ps1
    ↓ Validates links in docs\Microsoft_VSCode_Extensions.md
    ↓ Reports to output\link_check_report.json
```

---

## 🚀 Quick Start

### Fetch Latest Extensions
```powershell
.\fetch_all_extensions.ps1
```
- Fetches all published Microsoft VS Code extensions
- Filters out unpublished extensions
- Saves to `all_extensions.json`

### Generate Documentation
```powershell
```powershell
# Generate documentation
.\generate_markdown.ps1
```
```
- Reads `all_extensions.json`
- Generates categorized markdown documentation
- Saves to `Microsoft_VSCode_Extensions.md`

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

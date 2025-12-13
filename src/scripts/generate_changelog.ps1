# Get script directory
if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }

# Determine Repo Root
$RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

$diffFile = Join-Path $RepoRoot "data\diff_report.json"
$removedHistoryFile = Join-Path $RepoRoot "data\removed_extensions_history.json"
$changelogFile = Join-Path $RepoRoot "docs\CHANGELOG.md"
$removedMdFile = Join-Path $RepoRoot "docs\REMOVED_EXTENSIONS.md"

if (-not (Test-Path $diffFile)) {
    Write-Host "No diff report found at $diffFile. Skipping changelog generation." -ForegroundColor Yellow
    exit
}

$diffData = Get-Content $diffFile -Raw | ConvertFrom-Json
$today = (Get-Date).ToString("yyyy-MM-dd")

# ==========================================
# 1. Update Removed Extensions History
# ==========================================
$removedHistory = @()
if (Test-Path $removedHistoryFile) {
    $removedHistory = Get-Content $removedHistoryFile -Raw | ConvertFrom-Json
}

if ($diffData.removed.Count -gt 0) {
    Write-Host "Processing $($diffData.removed.Count) removed extensions..." -ForegroundColor Cyan
    foreach ($ext in $diffData.removed) {
        $id = "$($ext.publisher.publisherName).$($ext.extensionName)"
        
        # Check if already in history
        $existing = $removedHistory | Where-Object { $_.id -eq $id }
        if (-not $existing) {
            $removedHistory += @{
                id = $id
                name = $ext.displayName
                publisher = $ext.publisher.publisherName
                removedDate = $today
                lastVersion = $ext.versions[0].version
                url = "https://marketplace.visualstudio.com/items?itemName=$id"
            }
        }
    }
    
    $removedHistory | ConvertTo-Json -Depth 5 | Out-File -FilePath $removedHistoryFile -Encoding UTF8
    Write-Host "Updated removed extensions history." -ForegroundColor Green
}

# ==========================================
# 2. Generate/Update CHANGELOG.md
# ==========================================
$changelogEntry = ""
if ($diffData.stats.added -gt 0 -or $diffData.stats.removed -gt 0 -or $diffData.stats.updated -gt 0) {
    $changelogEntry += "## $today`n`n"
    
    if ($diffData.stats.added -gt 0) {
        $changelogEntry += "### 🆕 Added ($($diffData.stats.added))`n"
        foreach ($ext in $diffData.added) {
            $changelogEntry += "- **[$($ext.displayName)](https://marketplace.visualstudio.com/items?itemName=$($ext.publisher.publisherName).$($ext.extensionName))** ($($ext.publisher.publisherName))`n"
        }
        $changelogEntry += "`n"
    }
    
    if ($diffData.stats.removed -gt 0) {
        $changelogEntry += "### ❌ Removed ($($diffData.stats.removed))`n"
        foreach ($ext in $diffData.removed) {
            $changelogEntry += "- **$($ext.displayName)** ($($ext.publisher.publisherName))`n"
        }
        $changelogEntry += "`n"
    }
    
    if ($diffData.stats.updated -gt 0) {
        $changelogEntry += "### 🔄 Updated ($($diffData.stats.updated))`n"
        foreach ($item in $diffData.updated) {
            $changelogEntry += "- **$($item.extension.displayName)**: $($item.previousVersion) → $($item.newVersion)`n"
        }
        $changelogEntry += "`n"
    }
    
    $changelogEntry += "---`n`n"
}

if ($changelogEntry) {
    $currentContent = ""
    if (Test-Path $changelogFile) {
        $currentContent = Get-Content $changelogFile -Raw
    } else {
        $currentContent = "# Changelog`n`nTracking daily changes to the Microsoft VS Code Extensions catalog.`n`n"
    }
    
    # Insert new entry after header
    if ($currentContent -match "# Changelog\s+(.*)") {
        $header = "# Changelog`n`nTracking daily changes to the Microsoft VS Code Extensions catalog.`n`n"
        $rest = $currentContent.Replace($header, "")
        $newContent = $header + $changelogEntry + $rest
    } else {
        $newContent = "# Changelog`n`nTracking daily changes to the Microsoft VS Code Extensions catalog.`n`n" + $changelogEntry + $currentContent
    }
    
    $newContent | Out-File -FilePath $changelogFile -Encoding UTF8
    Write-Host "Updated CHANGELOG.md" -ForegroundColor Green
} else {
    Write-Host "No changes to record in Changelog." -ForegroundColor Gray
}

# ==========================================
# 3. Regenerate REMOVED_EXTENSIONS.md
# ==========================================
if ($removedHistory.Count -gt 0) {
    $md = "# Removed Microsoft VS Code Extensions`n`n"
    $md += "**Total Removed:** $($removedHistory.Count)`n`n"
    $md += "This list tracks extensions that were previously in the catalog but have been removed.`n`n"
    $md += "---`n`n"
    
    # Group by date descending
    $grouped = $removedHistory | Group-Object removedDate | Sort-Object Name -Descending
    
    foreach ($group in $grouped) {
        $md += "## Removed on $($group.Name)`n`n"
        foreach ($item in $group.Group) {
            $md += "- **$($item.name)** (`$($item.id)`) - Last Ver: $($item.lastVersion)`n"
        }
        $md += "`n"
    }
    
    $md | Out-File -FilePath $removedMdFile -Encoding UTF8
    Write-Host "Regenerated REMOVED_EXTENSIONS.md" -ForegroundColor Green
}

# Get script directory
if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }

# Compute repository root by walking up to find README.md
function Get-RepoRoot {
    param([string]$start)
    $current = $start
    for ($i = 0; $i -lt 5; $i++) {
        if (Test-Path (Join-Path $current "README.md")) { return (Resolve-Path $current).Path }
        $parent = Split-Path -Parent $current
        if ([string]::IsNullOrEmpty($parent)) { break }
        $current = $parent
    }
    return (Resolve-Path $start).Path
}

$repoRoot = Get-RepoRoot -start $PSScriptRoot

# Generate markdown catalog for ALL verified VS Code extension publishers
# Enhanced for readability with collapsible sections, better navigation, and visual hierarchy
# Reads: data/verified_publishers.json
# Outputs: docs/Verified_VSCode_Publishers.md

$dataFile = Join-Path $repoRoot "data\processed\verified_publishers.json"
$outputFile = Join-Path $repoRoot "docs\public\Verified_VSCode_Publishers.md"

# Ensure docs/public exists
$docsPublicDir = Split-Path -Parent $outputFile
New-Item -ItemType Directory -Path $docsPublicDir -Force | Out-Null

Write-Host "Loading verified publishers data from: $dataFile" -ForegroundColor Cyan
$data = Get-Content $dataFile -Raw | ConvertFrom-Json

$publishers = $data.publishers
$domainStats = $data.domainStats
$metadata = $data.metadata

Write-Host "Loaded $($publishers.Count) publishers across $($domainStats.Count) domains" -ForegroundColor Green

#region Helper Functions

# Format install count with K/M suffix
function Format-InstallCount {
    param([double]$value)
    if ($value -ge 1000000) {
        return [math]::Round($value / 1000000, 1).ToString() + "M"
    } elseif ($value -ge 1000) {
        return [math]::Round($value / 1000, 0).ToString() + "K"
    } else {
        return $value.ToString()
    }
}

# Convert text to anchor-safe ID
function ConvertTo-Anchor {
    param([string]$text)
    return $text.ToLower() -replace '[^a-z0-9]+', '-' -replace '^-|-$', ''
}

# Extract domain name for display
function Get-DomainDisplay {
    param([string]$domain)
    if ([string]::IsNullOrEmpty($domain)) { return "Unknown Domain" }
    return $domain -replace '^https?://(www\.)?', '' -replace '/$', ''
}

# Get medal emoji for top rankings
function Get-RankBadge {
    param([int]$rank)
    switch ($rank) {
        1 { return "🥇" }
        2 { return "🥈" }
        3 { return "🥉" }
        default { return "$rank." }
    }
}

# Clean and truncate description
function Format-Description {
    param([string]$desc, [int]$maxLength = 55)
    if ([string]::IsNullOrEmpty($desc)) { return "—" }
    $clean = $desc -replace '\|', '/' -replace '\[.*?\]\(.*?\)', '' -replace '`', "'" -replace '\n|\r', ' '
    if ($clean.Length -gt $maxLength) {
        return $clean.Substring(0, $maxLength).TrimEnd() + "…"
    }
    return $clean
}

#endregion

Write-Host "Generating markdown content..." -ForegroundColor Cyan

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$timestampISO = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
$datestamp = Get-Date -Format "MMMM d, yyyy"

# CI/CD build metadata (from GitHub Actions environment variables)
$commitSHA = if ($env:GITHUB_SHA) { $env:GITHUB_SHA.Substring(0, 7) } else { "local" }
$runID = if ($env:GITHUB_RUN_ID) { $env:GITHUB_RUN_ID } else { "manual" }
$repoOwner = if ($env:GITHUB_REPOSITORY) { $env:GITHUB_REPOSITORY } else { "thisis-romar/vscode-marketplace-evidence-kit" }

# Calculate total installs
$totalInstalls = ($publishers | Measure-Object -Property totalInstalls -Sum).Sum
$totalInstallsFormatted = Format-InstallCount -value $totalInstalls

#region Build Markdown

$markdown = @"
# 🔐 Verified VS Code Extension Publishers

> **Complete Catalog of Domain-Verified Publishers on the VS Code Marketplace**

<div align="center">

![Publishers](https://img.shields.io/badge/Publishers-$($publishers.Count)-blue?style=for-the-badge)
![Extensions](https://img.shields.io/badge/Extensions-$($metadata.totalExtensions)-green?style=for-the-badge)
![Domains](https://img.shields.io/badge/Domains-$($domainStats.Count)-purple?style=for-the-badge)
![Installs](https://img.shields.io/badge/Installs-$totalInstallsFormatted-orange?style=for-the-badge)

*Last Updated: $datestamp at $($timestamp.Split(' ')[1]) UTC*

$(if ($commitSHA -ne 'local') { "[``$commitSHA``](https://github.com/$repoOwner/commit/$($env:GITHUB_SHA)) • [Run #$runID](https://github.com/$repoOwner/actions/runs/$runID)" } else { "*Build: ``$commitSHA`` • Run: ``$runID``*" })

</div>

<!-- BUILD_METADATA
timestamp: $timestampISO
commit: $commitSHA
run_id: $runID
data_source: $($metadata.fetchDate)
publishers: $($publishers.Count)
extensions: $($metadata.totalExtensions)
domains: $($domainStats.Count)
-->

---

## 📑 Table of Contents

- [📊 Quick Stats](#-quick-stats)
- [🏆 Top 20 Publishers](#-top-20-publishers-by-total-installs)
- [🌐 Top 20 Domains](#-top-20-domains-by-extension-count)
- [📚 All Domains Directory](#-all-domains-directory)
- [🔗 Extensions by Domain](#-extensions-by-domain)
- [ℹ️ About This Document](#-about-this-document)

---

## 📊 Quick Stats

<table>
<tr>
<td width="25%" align="center">

### 👥 Publishers
**$($publishers.Count)**
*verified*

</td>
<td width="25%" align="center">

### 📦 Extensions
**$($metadata.totalExtensions)**
*total*

</td>
<td width="25%" align="center">

### 🌐 Domains
**$($domainStats.Count)**
*unique*

</td>
<td width="25%" align="center">

### ⬇️ Installs
**$totalInstallsFormatted**
*combined*

</td>
</tr>
</table>

> 💡 **What is verification?** Verified publishers have proven domain ownership by adding a TXT record to their DNS configuration. This provides an extra layer of trust for extension users.

---

## 🏆 Top 20 Publishers (by Total Installs)

| Rank | Publisher | Display Name | Domain | Ext. | Installs |
|:----:|-----------|--------------|--------|:----:|:--------:|
"@

$markdown += "`n"
$rank = 0
$publishers | Select-Object -First 20 | ForEach-Object {
    $rank++
    $badge = Get-RankBadge -rank $rank
    $domainDisplay = Get-DomainDisplay -domain $_.domain
    $installs = Format-InstallCount -value $_.totalInstalls
    $anchor = ConvertTo-Anchor -text $_.publisherName
    $markdown += "| $badge | [**$($_.publisherName)**](#$anchor) | $($_.displayName) | ``$domainDisplay`` | $($_.extensionCount) | **$installs** |`n"
}

$markdown += @"

<p align="right"><a href="#-table-of-contents">⬆️ Back to Top</a></p>

---

## 🌐 Top 20 Domains (by Extension Count)

| Rank | Domain | Publishers | Extensions | Navigate |
|:----:|--------|:----------:|:----------:|:--------:|
"@

$markdown += "`n"
$rank = 0
$domainStats | Select-Object -First 20 | ForEach-Object {
    $rank++
    $badge = Get-RankBadge -rank $rank
    $domainDisplay = Get-DomainDisplay -domain $_.domain
    $anchor = ConvertTo-Anchor -text $domainDisplay
    $markdown += "| $badge | ``$domainDisplay`` | $($_.publisherCount) | $($_.extensionCount) | [**→ View**](#domain-$anchor) |`n"
}

$markdown += @"

<p align="right"><a href="#-table-of-contents">⬆️ Back to Top</a></p>

---

## 📚 All Domains Directory

<details>
<summary><strong>📂 Click to expand all $($domainStats.Count) domains</strong></summary>

<br>

| # | Domain | Publishers | Extensions | Share |
|--:|--------|:----------:|:----------:|------:|
"@

$markdown += "`n"
$rank = 0
$domainStats | ForEach-Object {
    $rank++
    $domainDisplay = Get-DomainDisplay -domain $_.domain
    $percentage = [math]::Round(($_.extensionCount / $metadata.totalExtensions) * 100, 1)
    $anchor = ConvertTo-Anchor -text $domainDisplay
    $fire = if ($_.extensionCount -ge 20) { " 🔥" } elseif ($_.extensionCount -ge 10) { " ⭐" } else { "" }
    $markdown += "| $rank | [``$domainDisplay``](#domain-$anchor)$fire | $($_.publisherCount) | $($_.extensionCount) | $percentage% |`n"
}

$markdown += @"

</details>

> **Legend:** 🔥 = 20+ extensions | ⭐ = 10+ extensions

<p align="right"><a href="#-table-of-contents">⬆️ Back to Top</a></p>

---

# 🔗 Extensions by Domain

"@

# Generate domain sections
$domainIndex = 0
foreach ($domainStat in $domainStats) {
    $domainIndex++
    $domainDisplay = Get-DomainDisplay -domain $domainStat.domain
    $anchor = ConvertTo-Anchor -text $domainDisplay
    
    # Get publishers for this domain sorted by installs
    $domainPublishers = $publishers | Where-Object { $_.domain -eq $domainStat.domain } | Sort-Object -Property totalInstalls -Descending
    
    $markdown += @"

---

## <a id="domain-$anchor"></a>🏢 $domainDisplay

<table>
<tr>
<td>🔗 <strong>Domain:</strong> <code>$($domainStat.domain)</code></td>
<td>👥 <strong>Publishers:</strong> $($domainStat.publisherCount)</td>
<td>📦 <strong>Extensions:</strong> $($domainStat.extensionCount)</td>
</tr>
</table>

"@
    
    foreach ($pub in $domainPublishers) {
        $pubAnchor = ConvertTo-Anchor -text $pub.publisherName
        $pubInstalls = Format-InstallCount -value $pub.totalInstalls
        $marketplaceUrl = "https://marketplace.visualstudio.com/publishers/$($pub.publisherName)"
        
        # Build publisher links section
        $pubLinksArray = @()
        $pubLinksArray += "[🏪 Marketplace]($marketplaceUrl)"
        
        if ($pub.links) {
            # Get first/primary link from each category
            if ($pub.links.github -and $pub.links.github.Count -gt 0) {
                $pubLinksArray += "[📂 GitHub]($($pub.links.github[0]))"
            }
            if ($pub.links.support -and $pub.links.support.Count -gt 0) {
                $pubLinksArray += "[🐛 Issues]($($pub.links.support[0]))"
            }
            if ($pub.links.sponsor -and $pub.links.sponsor.Count -gt 0) {
                $pubLinksArray += "[💖 Sponsor]($($pub.links.sponsor[0]))"
            }
        }
        $pubLinksLine = $pubLinksArray -join " · "
        
        # Use collapsible for publishers with many extensions
        $useDetails = $pub.extensionCount -gt 5
        
        if ($useDetails) {
            $markdown += @"

<details>
<summary><strong><a id="$pubAnchor"></a>📦 $($pub.publisherName)</strong> — $($pub.displayName) — <em>$($pub.extensionCount) extensions</em> — <strong>$pubInstalls installs</strong></summary>

<br>

> $pubLinksLine

| Extension | Installs | Version | Links | Description |
|:----------|:--------:|:-------:|:-----:|:-----------|
"@
            $markdown += "`n"
        } else {
            $markdown += @"

### <a id="$pubAnchor"></a>📦 $($pub.publisherName)

> **$($pub.displayName)** — $($pub.extensionCount) extension(s) — **$pubInstalls total installs**
> 
> $pubLinksLine

| Extension | Installs | Version | Links | Description |
|:----------|:--------:|:-------:|:-----:|:-----------|
"@
            $markdown += "`n"
        }
        
        # Sort extensions by install count
        $sortedExts = $pub.extensions | Sort-Object -Property installCount -Descending
        
        foreach ($ext in $sortedExts) {
            $extInstalls = Format-InstallCount -value $ext.installCount
            $desc = Format-Description -desc $ext.shortDescription
            $extUrl = "https://marketplace.visualstudio.com/items?itemName=$($pub.publisherName).$($ext.extensionName)"
            $extLink = "[**$($ext.displayName)**]($extUrl)"
            
            # Build extension links
            $extLinksArray = @()
            if ($ext.links) {
                if ($ext.links.github) { $extLinksArray += "[📂]($($ext.links.github) `"GitHub`")" }
                elseif ($ext.links.source) { $extLinksArray += "[📂]($($ext.links.source) `"Source`")" }
                if ($ext.links.support) { $extLinksArray += "[🐛]($($ext.links.support) `"Issues`")" }
            }
            $extLinksCell = if ($extLinksArray.Count -gt 0) { $extLinksArray -join " " } else { "—" }
            
            $markdown += "| $extLink | $extInstalls | ``$($ext.version)`` | $extLinksCell | $desc |`n"
        }
        
        if ($useDetails) {
            $markdown += "`n</details>`n"
        } else {
            $markdown += "`n"
        }
    }
    
    $markdown += @"

<p align="right"><a href="#-table-of-contents">⬆️ Back to Top</a></p>
"@
}

# Add footer
$markdown += @"

---

## ℹ️ About This Document

### What is Publisher Verification?

This catalog lists all **verified publishers** on the VS Code Marketplace. A verified publisher has proven domain ownership by adding a TXT record to their DNS configuration.

<details>
<summary><strong>📋 How Verification Works</strong></summary>

<br>

1. Publisher adds a TXT record to their domain's DNS configuration
2. VS Code Marketplace verifies the DNS record
3. Publisher receives the "verified" badge after validation
4. Badge displays as: *"✅ This publisher has verified ownership of [domain]"*

**Benefits of Verification:**
- ✅ Proven domain ownership
- ✅ Higher trust level for users
- ✅ Professional credibility

For more details, see the [VS Code Publishing Documentation](https://code.visualstudio.com/api/working-with-extensions/publishing-extension#verify-a-publisher).

</details>

### Data Source

| Property | Value |
|----------|-------|
| **API** | VS Code Marketplace Extension Query API |
| **Filter** | ``isDomainVerified = true`` |
| **Sort** | By install count (most popular first) |
| **Generated** | $timestamp |
| **Build** | ``$commitSHA`` / Run ``$runID`` |

### Generation Scripts

- [`fetch_verified_publishers.ps1`](../fetch_verified_publishers.ps1) — Fetches data from Marketplace API
- [`generate_verified_markdown.ps1`](../generate_verified_markdown.ps1) — Generates this document

---

<div align="center">

**🔐 Verified VS Code Publishers Catalog**

*Generated automatically from the VS Code Marketplace API*

<sub>$($publishers.Count) publishers • $($metadata.totalExtensions) extensions • $($domainStats.Count) domains</sub>

</div>
"@

#endregion

# Save markdown
Write-Host "Saving markdown to: $outputFile" -ForegroundColor Cyan
$markdown | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "`n✅ SUCCESS: Verified Publishers catalog created!" -ForegroundColor Green
Write-Host "   📄 Output file: $outputFile" -ForegroundColor Green
Write-Host "   👥 Total publishers: $($publishers.Count)" -ForegroundColor Green
Write-Host "   🌐 Total domains: $($domainStats.Count)" -ForegroundColor Green
Write-Host "   📦 Total extensions: $($metadata.totalExtensions)" -ForegroundColor Green

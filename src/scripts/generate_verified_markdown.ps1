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

# Escape pipe characters for markdown table cells
function Escape-TableCell {
    param([string]$text)
    if ([string]::IsNullOrEmpty($text)) { return "" }
    return $text -replace '\|', '∣'  # Replace pipe with similar-looking Unicode character
}

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

# Build a global list of all verified extensions (flattened from publishers)
function Build-GlobalExtensionsList {
    param($publishers)
    $allExts = @()
    foreach ($pub in $publishers) {
        foreach ($ext in $pub.extensions) {
            $allExts += [PSCustomObject]@{
                name = Escape-TableCell -text $ext.displayName
                id = "$($pub.publisherName).$($ext.extensionName)"
                publisher = $pub.publisherName
                publisherDisplay = $pub.displayName
                domain = $pub.domain
                installs = $ext.installCount
                rating = $ext.rating  # Source JSON field is 'rating' not 'averageRating'
                reviews = $null       # ratingCount not available in source data
                lastUpdated = $ext.lastUpdated
                categories = $ext.categories
                version = $ext.version
                links = $ext.links
            }
        }
    }
    return $allExts
}

# Group extensions by category
function Group-ExtensionsByCategory {
    param($globalExts)
    $byCat = @{}
    foreach ($ext in $globalExts) {
        if ($ext.categories) {
            foreach ($cat in $ext.categories) {
                if (-not $byCat.ContainsKey($cat)) { $byCat[$cat] = @() }
                $byCat[$cat] += $ext
            }
        }
    }
    return $byCat
}

# Get sorted list of unique categories
function Get-UniqueCategories {
    param($globalExts)
    $allCats = @()
    foreach ($ext in $globalExts) {
        if ($ext.categories) { $allCats += $ext.categories }
    }
    return ($allCats | Sort-Object -Unique)
}

# Format extension table row for Popular/TopRated/RecentlyUpdated sections
function Format-ExtensionTableRow {
    param($ext, [switch]$IncludeRank, [int]$rank = 0)
    $anchor = ConvertTo-Anchor -text $ext.publisher
    $extUrl = "https://marketplace.visualstudio.com/items?itemName=$($ext.id)"
    $pubLink = "[$($ext.publisher)](#$anchor)"
    $domain = Get-DomainDisplay -domain $ext.domain
    $installs = Format-InstallCount -value $ext.installs
    $rating = if ($ext.rating) { "⭐ " + [math]::Round($ext.rating, 1) } else { "—" }
    $updated = if ($ext.lastUpdated) { ([DateTime]$ext.lastUpdated).ToString("yyyy-MM-dd") } else { "—" }
    if ($IncludeRank) {
        $badge = Get-RankBadge -rank $rank
        return "| $badge | [**$($ext.name)**]($extUrl) | $pubLink | ``$domain`` | **$installs** | $rating | $updated |"
    }
    return "| [**$($ext.name)**]($extUrl) | $pubLink | ``$domain`` | **$installs** | $rating | $updated |"
}

#endregion

Write-Host "Generating markdown content..." -ForegroundColor Cyan

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$timestampISO = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
$datestamp = Get-Date -Format "MMMM d, yyyy"

# CI/CD build metadata (from GitHub Actions environment variables or local git)
$repoOwner = if ($env:GITHUB_REPOSITORY) { $env:GITHUB_REPOSITORY } else { "thisis-romar/vscode-marketplace-evidence-kit" }

# Get commit SHA: prefer CI env var, fallback to local git
# Also verify if the commit is on a remote branch (to avoid 404 links)
$commitIsOnRemote = $false

if ($env:GITHUB_SHA) {
    # CI environment: commit is being pushed, so it will be on remote
    $fullCommitSHA = $env:GITHUB_SHA
    $commitSHA = $env:GITHUB_SHA.Substring(0, 7)
    $commitIsOnRemote = $true
} else {
    # Try to get from local git repository
    try {
        $fullCommitSHA = (git rev-parse HEAD 2>$null)
        if ($fullCommitSHA) {
            $fullCommitSHA = $fullCommitSHA.Trim()
            $commitSHA = $fullCommitSHA.Substring(0, 7)
            
            # Check if this commit exists on any remote branch
            $remoteBranches = git branch -r --contains $fullCommitSHA 2>$null
            if ($remoteBranches -and $remoteBranches.Trim()) {
                $commitIsOnRemote = $true
                Write-Host "  Commit $commitSHA is on remote: $($remoteBranches.Trim() -join ', ')" -ForegroundColor Green
            } else {
                Write-Host "  Commit $commitSHA is NOT on any remote branch (link will be local)" -ForegroundColor Yellow
                $commitIsOnRemote = $false
            }
        } else {
            $fullCommitSHA = $null
            $commitSHA = "local"
        }
    } catch {
        $fullCommitSHA = $null
        $commitSHA = "local"
    }
}

$runID = if ($env:GITHUB_RUN_ID) { $env:GITHUB_RUN_ID } else { $null }

# Build the provenance line based on available info
if ($fullCommitSHA -and $runID) {
    # Full CI context: show commit link and run link
    $provenanceLine = "[``$commitSHA``](https://github.com/$repoOwner/commit/$fullCommitSHA) • [Run #$runID](https://github.com/$repoOwner/actions/runs/$runID)"
} elseif ($fullCommitSHA -and $commitIsOnRemote) {
    # Local git with commit on remote: show commit link
    $provenanceLine = "[``$commitSHA``](https://github.com/$repoOwner/commit/$fullCommitSHA)"
} elseif ($fullCommitSHA) {
    # Local git but commit NOT on remote: show local indicator (no broken link)
    $provenanceLine = "``$commitSHA`` *(local, unpublished)*"
} else {
    # No git info: plain text
    $provenanceLine = "*Local build*"
}

# Calculate total installs
$totalInstalls = ($publishers | Measure-Object -Property totalInstalls -Sum).Sum
$totalInstallsFormatted = Format-InstallCount -value $totalInstalls

# Pre-calculate ratings statistics (globalExts built later, use publishers directly)
$allExtensions = foreach ($pub in $publishers) { $pub.extensions }
$ratedExtensions = $allExtensions | Where-Object { $_.rating -and $_.rating -gt 0 }
$ratedCount = @($ratedExtensions).Count
$avgRating = if ($ratedCount -gt 0) { [math]::Round(($ratedExtensions | Measure-Object -Property rating -Average).Average, 2) } else { 0 }
$ratingCoverage = [math]::Round(($ratedCount / $metadata.totalExtensions) * 100, 1)

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

$provenanceLine

</div>

<!-- BUILD_METADATA
timestamp: $timestampISO
commit: $commitSHA
run_id: $runID
data_source: $($metadata.fetchDate)
publishers: $($publishers.Count)
extensions: $($metadata.totalExtensions)
domains: $($domainStats.Count)
rated_extensions: $ratedCount
avg_rating: $avgRating
rating_coverage: $ratingCoverage%
-->

---

## 📑 Table of Contents

- [📊 Quick Stats](#-quick-stats)
- [🔥 Popular Extensions](#-popular-extensions)
- [⭐ Top Rated Extensions](#-top-rated-extensions)
- [🆕 Recently Updated](#-recently-updated)
- [🏷️ Extensions by Category](#-extensions-by-category)
- [🔎 Identifier Index](#-identifier-index)
- [🏅 Domain Leaderboards](#-domain-leaderboards)
- [🏆 Top 20 Publishers](#-top-20-publishers-by-total-installs)
- [🌐 Top 20 Domains](#-top-20-domains-by-extension-count)
- [📚 All Domains Directory](#-all-domains-directory)
- [🔗 Extensions by Domain](#-extensions-by-domain)
- [ℹ️ About This Document](#-about-this-document)

---

## 📊 Quick Stats

<table>
<tr>
<td width="20%" align="center">

### 👥 Publishers
**$($publishers.Count)**
*verified*

</td>
<td width="20%" align="center">

### 📦 Extensions
**$($metadata.totalExtensions)**
*total*

</td>
<td width="20%" align="center">

### 🌐 Domains
**$($domainStats.Count)**
*unique*

</td>
<td width="20%" align="center">

### ⬇️ Installs
**$totalInstallsFormatted**
*combined*

</td>
<td width="20%" align="center">

### ⭐ Avg Rating
**$avgRating**
*$ratedCount rated ($ratingCoverage%)*

</td>
</tr>
</table>

> 💡 **What is verification?** Verified publishers have proven domain ownership by adding a TXT record to their DNS configuration. This provides an extra layer of trust for extension users.

"@

# Build global extensions list for new sections
$globalExts = Build-GlobalExtensionsList -publishers $publishers

#region Popular Extensions Section
$markdown += @"

---

## 🔥 Popular Extensions

> **Top 50 verified extensions by total installs** — mirrors Marketplace ``@sort:installs``

| Rank | Extension | Publisher | Domain | Installs | Rating | Last Updated |
|:----:|-----------|-----------|--------|:--------:|:------:|:------------:|
"@
$markdown += "`n"
$popularExts = $globalExts | Sort-Object -Property installs -Descending
$rank = 0
$popularExts | Select-Object -First 50 | ForEach-Object {
    $rank++
    $row = Format-ExtensionTableRow -ext $_ -IncludeRank -rank $rank
    $markdown += "$row`n"
}

$markdown += @"

<details>
<summary><strong>📂 View all $($globalExts.Count) extensions by installs</strong></summary>

| Rank | Extension | Publisher | Domain | Installs | Rating | Last Updated |
|:----:|-----------|-----------|--------|:--------:|:------:|:------------:|
"@
$markdown += "`n"
$rank = 0
$popularExts | ForEach-Object {
    $rank++
    $row = Format-ExtensionTableRow -ext $_ -IncludeRank -rank $rank
    $markdown += "$row`n"
}

$markdown += @"

</details>

<p align="right"><a href="#-table-of-contents">⬆️ Back to Top</a></p>
"@
#endregion

#region Top Rated Extensions Section
$markdown += @"

---

## ⭐ Top Rated Extensions

> **Top 50 verified extensions by average rating** — mirrors Marketplace ``@sort:rating`` (tie-break: installs)

| Rank | Extension | Publisher | Domain | Rating | Installs | Reviews |
|:----:|-----------|-----------|--------|:------:|:--------:|:-------:|
"@
$markdown += "`n"
$topRatedExts = $globalExts | Where-Object { $_.rating -gt 0 } | Sort-Object -Property @{Expression={$_.rating};Descending=$true}, @{Expression={$_.installs};Descending=$true}
$rank = 0
$topRatedExts | Select-Object -First 50 | ForEach-Object {
    $rank++
    $badge = Get-RankBadge -rank $rank
    $anchor = ConvertTo-Anchor -text $_.publisher
    $extUrl = "https://marketplace.visualstudio.com/items?itemName=$($_.id)"
    $pubLink = "[$($_.publisher)](#$anchor)"
    $domain = Get-DomainDisplay -domain $_.domain
    $rating = "⭐ " + [math]::Round($_.rating, 1)
    $installs = Format-InstallCount -value $_.installs
    $reviews = if ($_.reviews) { Format-InstallCount -value $_.reviews } else { "—" }
    $escapedName = $_.name
    $markdown += "| $badge | [**$escapedName**]($extUrl) | $pubLink | ``$domain`` | **$rating** | $installs | $reviews |`n"
}

$markdown += @"

<p align="right"><a href="#-table-of-contents">⬆️ Back to Top</a></p>
"@
#endregion

#region Recently Updated Section
$markdown += @"

---

## 🆕 Recently Updated

> **Extensions updated in the last 30 days** — mirrors Marketplace ``@sort:updateDate``

| Extension | Publisher | Domain | Last Updated | Version | Installs |
|-----------|-----------|--------|:------------:|:-------:|:--------:|
"@
$markdown += "`n"
$thirtyDaysAgo = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")
$recentExts = $globalExts | Where-Object { $_.lastUpdated -and $_.lastUpdated -ge $thirtyDaysAgo } | Sort-Object -Property lastUpdated -Descending
$recentExts | Select-Object -First 100 | ForEach-Object {
    $anchor = ConvertTo-Anchor -text $_.publisher
    $extUrl = "https://marketplace.visualstudio.com/items?itemName=$($_.id)"
    $pubLink = "[$($_.publisher)](#$anchor)"
    $domain = Get-DomainDisplay -domain $_.domain
    $updated = if ($_.lastUpdated) { ([DateTime]$_.lastUpdated).ToString("yyyy-MM-dd") } else { "—" }
    $version = if ($_.version) { "``$($_.version)``" } else { "—" }
    $installs = Format-InstallCount -value $_.installs
    $markdown += "| [**$($_.name)**]($extUrl) | $pubLink | ``$domain`` | $updated | $version | $installs |`n"
}

if ($recentExts.Count -gt 100) {
    $markdown += @"

<details>
<summary><strong>📂 View all $($recentExts.Count) recently updated extensions</strong></summary>

| Extension | Publisher | Domain | Last Updated | Version | Installs |
|-----------|-----------|--------|:------------:|:-------:|:--------:|
"@
    $markdown += "`n"
    $recentExts | ForEach-Object {
        $anchor = ConvertTo-Anchor -text $_.publisher
        $extUrl = "https://marketplace.visualstudio.com/items?itemName=$($_.id)"
        $pubLink = "[$($_.publisher)](#$anchor)"
        $domain = Get-DomainDisplay -domain $_.domain
        $updated = if ($_.lastUpdated) { ([DateTime]$_.lastUpdated).ToString("yyyy-MM-dd") } else { "—" }
        $version = if ($_.version) { "``$($_.version)``" } else { "—" }
        $installs = Format-InstallCount -value $_.installs
        $escapedName = $_.name
        $markdown += "| [**$escapedName**]($extUrl) | $pubLink | ``$domain`` | $updated | $version | $installs |`n"
    }
    $markdown += "`n</details>`n"
}

$markdown += @"

<p align="right"><a href="#-table-of-contents">⬆️ Back to Top</a></p>

"@
#endregion

#region Extensions by Category Section
$markdown += @"

---

## 🏷️ Extensions by Category

> **Browse verified extensions grouped by Marketplace category** — mirrors ``@category:"..."``

### Category Index

| Category | Extensions | Top Extension |
|----------|:----------:|---------------|
"@
$markdown += "`n"
$categoryGroups = Group-ExtensionsByCategory -globalExts $globalExts
$categories = Get-UniqueCategories -globalExts $globalExts

foreach ($cat in $categories) {
    $catExts = $categoryGroups[$cat] | Sort-Object -Property installs -Descending
    $topExt = $catExts | Select-Object -First 1
    $topExtInfo = if ($topExt) { "$($topExt.name) ($(Format-InstallCount -value $topExt.installs))" } else { "—" }
    $anchor = ConvertTo-Anchor -text $cat
    $markdown += "| [$cat](#category-$anchor) | $($catExts.Count) | $topExtInfo |`n"
}

$markdown += @"

<p align="right"><a href="#-table-of-contents">⬆️ Back to Top</a></p>

"@

# Render each category subsection
foreach ($cat in $categories) {
    $anchor = ConvertTo-Anchor -text $cat
    $catExts = $categoryGroups[$cat] | Sort-Object -Property installs -Descending
    
    $markdown += @"

---

### <a id="category-$anchor"></a>📂 $cat

"@
    
    if ($catExts.Count -gt 20) {
        $markdown += @"
<details>
<summary><strong>$($catExts.Count) extensions in this category</strong></summary>

| Extension | Publisher | Installs | Rating |
|-----------|-----------|:--------:|:------:|
"@
    $markdown += "`n"
    } else {
        $markdown += @"
| Extension | Publisher | Installs | Rating |
|-----------|-----------|:--------:|:------:|
"@
    $markdown += "`n"
    }
    
    foreach ($ext in $catExts) {
        $pubAnchor = ConvertTo-Anchor -text $ext.publisher
        $extUrl = "https://marketplace.visualstudio.com/items?itemName=$($ext.id)"
        $pubLink = "[$($ext.publisher)](#$pubAnchor)"
        $installs = Format-InstallCount -value $ext.installs
        $rating = if ($ext.rating) { "⭐ " + [math]::Round($ext.rating, 1) } else { "—" }
        $markdown += "| [**$($ext.name)**]($extUrl) | $pubLink | $installs | $rating |`n"
    }
    
    if ($catExts.Count -gt 20) {
        $markdown += "`n</details>`n"
    }
    
    $markdown += "`n<p align=`"right`"><a href=`"#-extensions-by-category`">⬆️ Back to Categories</a> · <a href=`"#-table-of-contents`">⬆️ Back to Top</a></p>`n"
}
#endregion

#region Identifier Index Section
$markdown += @"

---

## 🔎 Identifier Index

> **Alphabetical listing by extension identifier** — use with Marketplace ``@id:publisher.extension``

<details>
<summary><strong>📂 Click to expand all $($globalExts.Count) identifiers (A–Z)</strong></summary>

| # | Identifier | Name | Publisher | Links |
|--:|------------|------|-----------|:-----:|
"@
$markdown += "`n"
$sortedById = $globalExts | Sort-Object -Property id
$idx = 0
foreach ($ext in $sortedById) {
    $idx++
    $pubAnchor = ConvertTo-Anchor -text $ext.publisher
    $extUrl = "https://marketplace.visualstudio.com/items?itemName=$($ext.id)"
    $pubLink = "[$($ext.publisher)](#$pubAnchor)"
    $markdown += "| $idx | ``$($ext.id)`` | $($ext.name) | $pubLink | [🏪]($extUrl) |`n"
}

$markdown += @"

</details>

<p align="right"><a href="#-table-of-contents">⬆️ Back to Top</a></p>

---

## 🏅 Domain Leaderboards

> **Verified domains ranked by total install count** — aggregate of all extensions per domain

| Rank | Domain | Publishers | Extensions | Total Installs | Top Extension |
|:----:|--------|:----------:|:----------:|:--------------:|---------------|
"@
$markdown += "`n"
# Aggregate installs by domain
$domainInstalls = @{}
$domainTopExt = @{}
foreach ($ext in $globalExts) {
    $domain = Get-DomainDisplay -domain $ext.domain
    if (-not $domainInstalls.ContainsKey($domain)) {
        $domainInstalls[$domain] = 0
        $domainTopExt[$domain] = $ext
    }
    $domainInstalls[$domain] += $ext.installs
    if ($ext.installs -gt $domainTopExt[$domain].installs) {
        $domainTopExt[$domain] = $ext
    }
}

# Sort domains by total installs and render
$sortedDomains = $domainInstalls.GetEnumerator() | Sort-Object -Property Value -Descending
$rank = 0
$sortedDomains | Select-Object -First 30 | ForEach-Object {
    $rank++
    $domain = $_.Key
    $totalInstalls = Format-InstallCount -value $_.Value
    $domainStat = $domainStats | Where-Object { (Get-DomainDisplay -domain $_.domain) -eq $domain } | Select-Object -First 1
    $pubCount = if ($domainStat) { $domainStat.publisherCount } else { 1 }
    $extCount = if ($domainStat) { $domainStat.extensionCount } else { 1 }
    $topExt = $domainTopExt[$domain]
    $topExtInfo = "$($topExt.name) ($(Format-InstallCount -value $topExt.installs))"
    $badge = Get-RankBadge -rank $rank
    $anchor = ConvertTo-Anchor -text $domain
    $markdown += "| $badge | [``$domain``](#domain-$anchor) | $pubCount | $extCount | **$totalInstalls** | $topExtInfo |`n"
}

$markdown += @"

<p align="right"><a href="#-table-of-contents">⬆️ Back to Top</a></p>

---

## 🏆 Top 20 Publishers (by Total Installs)

| Rank | Publisher | Display Name | Domain | Ext. | Installs |
|:----:|-----------|--------------|--------|:----:|:--------:|
"@
#endregion

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
            $escapedDisplayName = Escape-TableCell -text $ext.displayName
            $extLink = "[**$escapedDisplayName**]($extUrl)"
            
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

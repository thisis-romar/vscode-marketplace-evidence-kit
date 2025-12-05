# Get script directory
if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }

# Generate markdown catalog for ALL verified VS Code extension publishers
# Reads: data/verified_publishers.json
# Outputs: docs/Verified_VSCode_Publishers.md

$dataFile = Join-Path $PSScriptRoot "data\verified_publishers.json"
$outputFile = Join-Path $PSScriptRoot "docs\Verified_VSCode_Publishers.md"

Write-Host "Loading verified publishers data from: $dataFile" -ForegroundColor Cyan
$data = Get-Content $dataFile -Raw | ConvertFrom-Json

$publishers = $data.publishers
$domainStats = $data.domainStats
$metadata = $data.metadata

Write-Host "Loaded $($publishers.Count) publishers across $($domainStats.Count) domains" -ForegroundColor Green

# Format install count
function Format-InstallCount {
    param([double]$value)
    if ($value -ge 1000000) {
        return [math]::Round($value / 1000000, 2).ToString() + "M"
    } elseif ($value -ge 1000) {
        return [math]::Round($value / 1000, 0).ToString() + "K"
    } else {
        return $value.ToString()
    }
}

# Convert text to anchor
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

Write-Host "Generating markdown content..." -ForegroundColor Cyan

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Calculate total installs
$totalInstalls = ($publishers | Measure-Object -Property totalInstalls -Sum).Sum
$totalInstallsFormatted = Format-InstallCount -value $totalInstalls

# Start building markdown
$markdown = @"
# Verified VS Code Extension Publishers - Complete Catalog

**Comprehensive listing of all verified publishers on the VS Code Marketplace**

> ✅ All publishers listed have verified domain ownership via DNS TXT record validation

---

## 📊 Quick Stats

| Metric | Value |
|--------|-------|
| **Verified Publishers** | $($publishers.Count) |
| **Total Extensions** | $($metadata.totalExtensions) |
| **Unique Domains** | $($domainStats.Count) |
| **Total Installs** | $totalInstallsFormatted |
| **Generated** | $timestamp |

---

## 🏆 Top 20 Publishers (by Total Installs)

| # | Publisher | Display Name | Domain | Extensions | Total Installs |
|---|-----------|--------------|--------|------------|----------------|
"@

$rank = 0
$publishers | Select-Object -First 20 | ForEach-Object {
    $rank++
    $domainDisplay = Get-DomainDisplay -domain $_.domain
    $installs = Format-InstallCount -value $_.totalInstalls
    $anchor = ConvertTo-Anchor -text $_.publisherName
    $markdown += "| $rank | [$($_.publisherName)](#$anchor) | $($_.displayName) | $domainDisplay | $($_.extensionCount) | $installs |`n"
}

$markdown += @"

---

## 🌐 Top 20 Domains (by Extension Count)

| # | Domain | Publishers | Extensions | Jump |
|---|--------|------------|------------|------|
"@

$rank = 0
$domainStats | Select-Object -First 20 | ForEach-Object {
    $rank++
    $domainDisplay = Get-DomainDisplay -domain $_.domain
    $anchor = ConvertTo-Anchor -text $domainDisplay
    $markdown += "| $rank | $domainDisplay | $($_.publisherCount) | $($_.extensionCount) | [View →](#domain-$anchor) |`n"
}

$markdown += @"

---

## 📚 All Domains (by Extension Count)

| # | Domain | Publishers | Extensions | % |
|---|--------|------------|------------|---|
"@

$rank = 0
$domainStats | ForEach-Object {
    $rank++
    $domainDisplay = Get-DomainDisplay -domain $_.domain
    $percentage = [math]::Round(($_.extensionCount / $metadata.totalExtensions) * 100, 1)
    $anchor = ConvertTo-Anchor -text $domainDisplay
    $fire = if ($_.extensionCount -ge 20) { " 🔥" } else { "" }
    $markdown += "| $rank | [$domainDisplay](#domain-$anchor)$fire | $($_.publisherCount) | $($_.extensionCount) | $percentage% |`n"
}

$markdown += "`n**Total: $($metadata.totalExtensions) extensions from $($publishers.Count) verified publishers across $($domainStats.Count) domains**`n"

# Generate domain sections
$markdown += @"

---

# 🌐 Extensions by Domain

"@

foreach ($domainStat in $domainStats) {
    $domainDisplay = Get-DomainDisplay -domain $domainStat.domain
    $anchor = ConvertTo-Anchor -text $domainDisplay
    
    $markdown += @"

---

## <a id="domain-$anchor"></a>🔗 $domainDisplay

> **$($domainStat.publisherCount) publisher(s)** | **$($domainStat.extensionCount) extension(s)** | Domain: ``$($domainStat.domain)``

"@
    
    # Get publishers for this domain sorted by installs
    $domainPublishers = $publishers | Where-Object { $_.domain -eq $domainStat.domain } | Sort-Object -Property totalInstalls -Descending
    
    foreach ($pub in $domainPublishers) {
        $pubAnchor = ConvertTo-Anchor -text $pub.publisherName
        $pubInstalls = Format-InstallCount -value $pub.totalInstalls
        
        $markdown += @"

### <a id="$pubAnchor"></a>📦 $($pub.publisherName) ($($pub.displayName))

> **$($pub.extensionCount) extensions** | **$pubInstalls total installs** | [Marketplace](https://marketplace.visualstudio.com/publishers/$($pub.publisherName))

| Extension | Installs | Rating | Version | Description |
|-----------|----------|--------|---------|-------------|
"@
        
        # Sort extensions by install count
        $sortedExts = $pub.extensions | Sort-Object -Property installCount -Descending
        
        foreach ($ext in $sortedExts) {
            $extInstalls = Format-InstallCount -value $ext.installCount
            $ratingStars = if ($ext.rating -gt 0) { "⭐ $($ext.rating)" } else { "-" }
            $desc = if ($ext.shortDescription) { 
                $ext.shortDescription.Substring(0, [Math]::Min(60, $ext.shortDescription.Length))
                if ($ext.shortDescription.Length -gt 60) { "..." }
            } else { "-" }
            $extLink = "[$($ext.displayName)](https://marketplace.visualstudio.com/items?itemName=$($pub.publisherName).$($ext.extensionName))"
            
            $markdown += "| $extLink | $extInstalls | $ratingStars | $($ext.version) | $desc |`n"
        }
        
        $markdown += "`n"
    }
}

# Add footer
$markdown += @"

---

## 📋 About This Document

This catalog lists all **verified publishers** on the VS Code Marketplace. A verified publisher has proven domain ownership by adding a TXT record to their DNS configuration, as described in the [VS Code Publishing Documentation](https://code.visualstudio.com/api/working-with-extensions/publishing-extension#verify-a-publisher).

### Verification Badge
When you see "✅ This publisher has verified ownership of [domain]" on an extension page, it means:
- The publisher owns the domain they claim
- They've maintained the verification for at least 6 months (for the badge to appear)
- The extension is more trustworthy than unverified publishers

### Data Source
- **API**: VS Code Marketplace Extension Query API
- **Filter**: ``isDomainVerified = true``
- **Sort**: By install count (most popular first)

---

*Generated by [fetch_verified_publishers.ps1](../fetch_verified_publishers.ps1) and [generate_verified_markdown.ps1](../generate_verified_markdown.ps1)*
"@

# Save markdown
Write-Host "Saving markdown to: $outputFile" -ForegroundColor Cyan
$markdown | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "`n✓ SUCCESS: Verified Publishers catalog created!" -ForegroundColor Green
Write-Host "✓ Output file: $outputFile" -ForegroundColor Green
Write-Host "✓ Total publishers: $($publishers.Count)" -ForegroundColor Green
Write-Host "✓ Total domains: $($domainStats.Count)" -ForegroundColor Green
Write-Host "✓ Total extensions: $($metadata.totalExtensions)" -ForegroundColor Green

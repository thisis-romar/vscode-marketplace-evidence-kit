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

# Ensure target directories exist
$rawDir = Join-Path $repoRoot "data\raw"
$processedDir = Join-Path $repoRoot "data\processed"
New-Item -ItemType Directory -Path $rawDir -Force | Out-Null
New-Item -ItemType Directory -Path $processedDir -Force | Out-Null

# Script to fetch ALL UNVERIFIED VS Code extension publishers from the Marketplace
# Collects extensions from unverified publishers (isDomainVerified=false)
# Outputs: data/all_unverified_extensions.json, data/unverified_publishers.json

$apiUrl = "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
$allExtensions = @()

$headers = @{
    "Content-Type" = "application/json"
    "Accept" = "application/json;api-version=7.1-preview.1"
}

# Flags for maximum metadata: 991 = versions + files + categories/tags + statistics etc.

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "  FETCH ALL UNVERIFIED PUBLISHERS" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Fetching extensions from ALL unverified publishers..." -ForegroundColor Gray
Write-Host "Filter: isDomainVerified = false (no domain verification)" -ForegroundColor Gray
Write-Host "Sort: By install count (most popular first)`n" -ForegroundColor Gray

$page = 1
$hasMorePages = $true
$totalResultCount = $null
$startTime = Get-Date
$maxPages = 50  # Safety limit - can be increased if needed

while ($hasMorePages -and $page -le $maxPages) {
    Write-Host "Fetching page $page..." -ForegroundColor Yellow
    
    # Query all VS Code extensions sorted by install count (sortBy=4)
    $body = @{
        filters = @(
            @{
                criteria = @(
                    @{ filterType = 8; value = "Microsoft.VisualStudio.Code" }
                )
                pageNumber = $page
                pageSize = 100
                sortBy = 4  # Install count (most popular first)
                sortOrder = 0  # Descending
            }
        )
        flags = 991
    } | ConvertTo-Json -Depth 10 -Compress

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $body -Headers $headers
        
        if ($null -eq $totalResultCount -and $response.results[0].resultMetadata) {
            $metadataItem = $response.results[0].resultMetadata | Where-Object { $_.metadataType -eq "ResultCount" }
            if ($metadataItem) {
                $totalResultCount = $metadataItem.metadataItems[0].count
                Write-Host "API reports total extensions: $totalResultCount" -ForegroundColor Cyan
            }
        }
        
        $pageExtensions = $response.results[0].extensions
        
        if ($pageExtensions -and $pageExtensions.Count -gt 0) {
            Write-Host "  + Found $($pageExtensions.Count) extensions on page $page" -ForegroundColor Green
            $allExtensions += $pageExtensions
            $page++
            Start-Sleep -Milliseconds 400  # Rate limiting
        } else {
            Write-Host "  + No more extensions found." -ForegroundColor Green
            $hasMorePages = $false
        }
    } catch {
        Write-Host "  x Error fetching page $page : $_" -ForegroundColor Red
        $hasMorePages = $false
    }
}

$elapsed = (Get-Date) - $startTime
Write-Host "`n+ Fetch complete! ($([Math]::Round($elapsed.TotalSeconds, 1))s)" -ForegroundColor Green
Write-Host "Total fetched: $($allExtensions.Count) extensions" -ForegroundColor Cyan

# Filter to UNVERIFIED publishers only (isDomainVerified = false OR null)
Write-Host "`nFiltering to unverified publishers only..." -ForegroundColor Cyan
$unverifiedExtensions = @($allExtensions | Where-Object { $_.publisher.isDomainVerified -ne $true })
$verifiedCount = $allExtensions.Count - $unverifiedExtensions.Count
Write-Host "  + Unverified publishers: $($unverifiedExtensions.Count) extensions" -ForegroundColor Green
Write-Host "  + Filtered out: $verifiedCount verified" -ForegroundColor Yellow

# Filter unpublished
Write-Host "`nFiltering unpublished extensions..." -ForegroundColor Cyan
$publishedExtensions = @($unverifiedExtensions | Where-Object { $_.flags -notmatch 'unpublished' })
$unpublishedCount = $unverifiedExtensions.Count - $publishedExtensions.Count
Write-Host "  + Published: $($publishedExtensions.Count) (filtered $unpublishedCount unpublished)" -ForegroundColor Green

# Build publisher summary
Write-Host "`nBuilding publisher summary..." -ForegroundColor Cyan

$publisherMap = @{}

foreach ($ext in $publishedExtensions) {
    $pubName = $ext.publisher.publisherName
    
    # Get install count
    $installCount = 0
    if ($ext.statistics) {
        $installStat = $ext.statistics | Where-Object { $_.statisticName -eq "install" }
        if ($installStat) { $installCount = $installStat.value }
    }
    
    # Get rating
    $rating = 0
    if ($ext.statistics) {
        $ratingStat = $ext.statistics | Where-Object { $_.statisticName -eq "averagerating" }
        if ($ratingStat) { $rating = [math]::Round($ratingStat.value, 1) }
    }
    
    # Get categories
    $categories = @()
    if ($ext.categories) { $categories = $ext.categories }
    
    # Extract links from extension properties
    $links = @{
        github = $null
        source = $null
        support = $null
        learn = $null
        sponsor = $null
        qna = $null
    }
    if ($ext.versions -and $ext.versions.Count -gt 0 -and $ext.versions[0].properties) {
        $props = $ext.versions[0].properties
        foreach ($prop in $props) {
            switch ($prop.key) {
                "Microsoft.VisualStudio.Services.Links.GitHub" { $links.github = $prop.value }
                "Microsoft.VisualStudio.Services.Links.Source" { $links.source = $prop.value }
                "Microsoft.VisualStudio.Services.Links.Support" { $links.support = $prop.value }
                "Microsoft.VisualStudio.Services.Links.Learn" { $links.learn = $prop.value }
                "Microsoft.VisualStudio.Code.SponsorLink" { $links.sponsor = $prop.value }
                "Microsoft.VisualStudio.Services.CustomerQnALink" { 
                    if ($prop.value -ne "false" -and $prop.value -ne "") { 
                        $links.qna = $prop.value 
                    }
                }
            }
        }
    }
    
    # Initialize publisher entry if new
    if (-not $publisherMap.ContainsKey($pubName)) {
        # For unverified publishers, domain may be null/empty - normalize it
        $domain = $ext.publisher.domain
        if ([string]::IsNullOrWhiteSpace($domain)) {
            $domain = "(no domain)"
        }
        
        $publisherMap[$pubName] = @{
            publisherName = $ext.publisher.publisherName
            displayName = $ext.publisher.displayName
            domain = $domain
            isDomainVerified = $false
            extensionCount = 0
            totalInstalls = 0
            extensions = @()
            links = @{
                github = @()
                source = @()
                support = @()
                learn = @()
                sponsor = @()
                qna = @()
            }
        }
    }
    
    # Aggregate unique links per publisher
    if ($links.github -and $links.github -notin $publisherMap[$pubName].links.github) {
        $publisherMap[$pubName].links.github += $links.github
    }
    if ($links.source -and $links.source -notin $publisherMap[$pubName].links.source) {
        $publisherMap[$pubName].links.source += $links.source
    }
    if ($links.support -and $links.support -notin $publisherMap[$pubName].links.support) {
        $publisherMap[$pubName].links.support += $links.support
    }
    if ($links.learn -and $links.learn -notin $publisherMap[$pubName].links.learn) {
        $publisherMap[$pubName].links.learn += $links.learn
    }
    if ($links.sponsor -and $links.sponsor -notin $publisherMap[$pubName].links.sponsor) {
        $publisherMap[$pubName].links.sponsor += $links.sponsor
    }
    if ($links.qna -and $links.qna -notin $publisherMap[$pubName].links.qna) {
        $publisherMap[$pubName].links.qna += $links.qna
    }
    
    # Add extension to publisher
    $publisherMap[$pubName].extensionCount++
    $publisherMap[$pubName].totalInstalls += $installCount
    $publisherMap[$pubName].extensions += @{
        extensionName = $ext.extensionName
        displayName = $ext.displayName
        installCount = $installCount
        rating = $rating
        categories = $categories
        shortDescription = $ext.shortDescription
        lastUpdated = if ($ext.versions -and $ext.versions.Count -gt 0) { $ext.versions[0].lastUpdated } else { $null }
        version = if ($ext.versions -and $ext.versions.Count -gt 0) { $ext.versions[0].version } else { "" }
        links = $links
    }
}

# Convert to array and sort by total installs
$publisherSummary = $publisherMap.Values | Sort-Object -Property totalInstalls -Descending

# Calculate domain statistics (including "(no domain)" category)
$domainStats = $publisherSummary | Group-Object -Property domain | ForEach-Object {
    @{
        domain = $_.Name
        publisherCount = $_.Count
        extensionCount = ($_.Group | Measure-Object -Property extensionCount -Sum).Sum
        totalInstalls = ($_.Group | Measure-Object -Property totalInstalls -Sum).Sum
        publishers = $_.Group.publisherName
    }
} | Sort-Object -Property extensionCount -Descending

Write-Host "  + Found $($publisherSummary.Count) unique unverified publishers" -ForegroundColor Green
Write-Host "  + Across $($domainStats.Count) unique domains (including no-domain)" -ForegroundColor Green

# Save all unverified extensions
$timestamp = (Get-Date).ToString("yyyyMMddHHmm")
$extensionsHistoryPath = Join-Path $repoRoot "data\history\all_unverified_extensions_$timestamp.json"
$extensionsLatestPath = Join-Path $repoRoot "data\processed\all_unverified_extensions.json"

$extensionsOutput = @{
    metadata = @{
        fetchDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        totalFetched = $allExtensions.Count
        verifiedFiltered = $verifiedCount
        unpublishedFiltered = $unpublishedCount
        finalCount = $publishedExtensions.Count
        uniquePublishers = $publisherSummary.Count
        uniqueDomains = $domainStats.Count
        verificationMethod = "isDomainVerified=false (unverified publishers)"
    }
    extensions = $publishedExtensions
}
$extensionsJson = $extensionsOutput | ConvertTo-Json -Depth 20 -Compress
$extensionsJson | Out-File -FilePath $extensionsHistoryPath -Encoding UTF8
$extensionsJson | Out-File -FilePath $extensionsLatestPath -Encoding UTF8
Write-Host "`n+ Extensions saved to:" -ForegroundColor Green
Write-Host "  History: $extensionsHistoryPath" -ForegroundColor Gray
Write-Host "  Latest:  $extensionsLatestPath" -ForegroundColor Gray

# Save publisher summary
$publishersHistoryPath = Join-Path $repoRoot "data\history\unverified_publishers_$timestamp.json"
$publishersLatestPath = Join-Path $repoRoot "data\processed\unverified_publishers.json"

$publishersOutput = @{
    metadata = @{
        fetchDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        totalPublishers = $publisherSummary.Count
        totalExtensions = $publishedExtensions.Count
        totalDomains = $domainStats.Count
    }
    domainStats = $domainStats
    publishers = $publisherSummary
}
$publishersJson = $publishersOutput | ConvertTo-Json -Depth 20 -Compress
$publishersJson | Out-File -FilePath $publishersHistoryPath -Encoding UTF8
$publishersJson | Out-File -FilePath $publishersLatestPath -Encoding UTF8
Write-Host "+ Publisher summary saved to:" -ForegroundColor Green
Write-Host "  History: $publishersHistoryPath" -ForegroundColor Gray
Write-Host "  Latest:  $publishersLatestPath" -ForegroundColor Gray

# Print summary
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Total unverified extensions: $($publishedExtensions.Count)" -ForegroundColor Magenta
Write-Host "Unique unverified publishers: $($publisherSummary.Count)" -ForegroundColor Magenta
Write-Host "Unique domains (incl. no-domain): $($domainStats.Count)" -ForegroundColor Magenta

Write-Host "`nTop 10 Unverified Publishers by Installs:" -ForegroundColor Yellow
$publisherSummary | Select-Object -First 10 | ForEach-Object {
    $installs = if ($_.totalInstalls -ge 1000000) { "$([math]::Round($_.totalInstalls / 1000000, 1))M" } 
                elseif ($_.totalInstalls -ge 1000) { "$([math]::Round($_.totalInstalls / 1000, 0))K" }
                else { $_.totalInstalls }
    Write-Host "  $($_.publisherName) ($($_.displayName)) - $($_.extensionCount) exts, $installs installs"
}

Write-Host "`nTop 10 Domains by Extension Count:" -ForegroundColor Yellow
$domainStats | Select-Object -First 10 | ForEach-Object {
    Write-Host "  $($_.domain) - $($_.publisherCount) publishers, $($_.extensionCount) extensions"
}

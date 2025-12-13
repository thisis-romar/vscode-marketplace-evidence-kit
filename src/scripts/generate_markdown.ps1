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

# Generate markdown document v2 with improved categorization, numbering, and TOC
# Enhanced version with publisher-based categorization and sequential numbering

$dataFile = Join-Path $repoRoot "data\all_extensions.json"
# Output file path
$outputFile = Join-Path $repoRoot "docs\public\Microsoft_VSCode_Extensions.md"

# Ensure output directory exists
$outputDir = Split-Path $outputFile -Parent
if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }

Write-Host "Loading extension data from: $dataFile" -ForegroundColor Cyan
$data = Get-Content $dataFile -Raw | ConvertFrom-Json
Write-Host "Loaded $($data.Count) extensions" -ForegroundColor Green

# Load diff report for NEW badges
$diffFile = Join-Path $repoRoot "data\diff_report.json"
$addedIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
if (Test-Path $diffFile) {
    try {
        $diffData = Get-Content $diffFile -Raw | ConvertFrom-Json
        if ($diffData.added) {
            foreach ($item in $diffData.added) {
                # Handle potential object structure differences
                $pubName = if ($item.publisher.publisherName) { $item.publisher.publisherName } else { $item.publisher }
                $id = "$pubName.$($item.extensionName)"
                $addedIds.Add($id) | Out-Null
            }
        }
        Write-Host "Loaded diff report: $($addedIds.Count) new extensions" -ForegroundColor Cyan
    } catch {
        Write-Host "Warning: Failed to load diff report: $_" -ForegroundColor Yellow
    }
}

# Enhanced category inference based on publisher patterns (most reliable)
function Get-InferredCategory {
    param($displayName, $extensionName, $publisherName, $shortDescription)
    
    $pubName = if ($publisherName) { $publisherName.ToLower() } else { "" }
    $extName = if ($extensionName) { $extensionName.ToLower() } else { "" }
    $name = if ($displayName) { $displayName.ToLower() } else { "" }
    $desc = if ($shortDescription) { $shortDescription.ToLower() } else { "" }
    
    # Priority 1: Publisher-based categorization (most reliable)
    switch -Regex ($pubName) {
        '^ms-python'                    { return "Python Development" }
        '^ms-dotnettools'               { return ".NET Development" }
        '^ms-azuretools'                { return "Azure & Cloud Services" }
        '^ms-vscode-remote'             { return "Remote Development" }
        '^ms-kubernetes-tools'          { return "Containers & Kubernetes" }
        '^ms-toolsai'                   { return "AI & Machine Learning" }
        '^github'                       { return "GitHub Integration" }
        '^ms-vscode\.azure'             { return "Azure & Cloud Services" }
        '^ms-vscode\.vscode-node'       { return "Node.js Development" }
        '^ms-vscode\.cpptools'          { return "C/C++ Development" }
        '^ms-vscode\.powershell'        { return "PowerShell Development" }
        '^msjsdiag'                     { return "JavaScript & TypeScript" }
        '^ms-vsliveshare'               { return "Collaboration Tools" }
        '^ms-iot'                       { return "IoT & Hardware" }
        '^ms-dynamics-smb'              { return "Business Central (AL)" }
        '^quantum'                      { return "Quantum Computing" }
    }
    
    # Priority 2: Extension name patterns
    switch -Regex ($extName) {
        'python|pylance'                { return "Python Development" }
        'jupyter|ipynb'                 { return "Data Science & Notebooks" }
        'csharp|dotnet|csdevkit'        { return ".NET Development" }
        'azure|cosmos|appservice'       { return "Azure & Cloud Services" }
        'remote-ssh|remote-wsl|remote-containers' { return "Remote Development" }
        'docker|kubernetes|helm'        { return "Containers & Kubernetes" }
        'copilot|intellicode|vscode-ai' { return "AI & Machine Learning" }
        'debugger|node-debug'           { return "Debugging Tools" }
        'git|github|gitlab'             { return "Version Control" }
        'edge-devtools|chrome'          { return "Web Development" }
        'theme|color|icon'              { return "Themes & Appearance" }
        'test|pytest|unittest'          { return "Testing Tools" }
        'eslint|tslint|prettier'        { return "Linters & Formatters" }
        'pack|bundle'                   { return "Extension Packs" }
        'language-pack'                 { return "Language Packs" }
        'arduino|raspberry|iot'         { return "IoT & Hardware" }
        '^al$|business-central'         { return "Business Central (AL)" }
    }
    
    # Priority 3: Display name patterns
    if ($name -match 'python|pylance') { return "Python Development" }
    if ($name -match 'jupyter|notebook') { return "Data Science & Notebooks" }
    if ($name -match 'c#|\.net|csharp') { return ".NET Development" }
    if ($name -match 'azure|cloud') { return "Azure & Cloud Services" }
    if ($name -match 'remote|ssh|wsl') { return "Remote Development" }
    if ($name -match 'docker|kubernetes|container') { return "Containers & Kubernetes" }
    if ($name -match 'copilot|ai|intellicode|machine learning') { return "AI & Machine Learning" }
    if ($name -match 'javascript|typescript|node') { return "JavaScript & TypeScript" }
    if ($name -match 'c\+\+|cpp') { return "C/C++ Development" }
    if ($name -match 'powershell') { return "PowerShell Development" }
    if ($name -match 'java(?!script)') { return "Java Development" }
    if ($name -match 'git|github') { return "Version Control" }
    if ($name -match 'edge|chrome|browser|web') { return "Web Development" }
    if ($name -match 'theme') { return "Themes & Appearance" }
    if ($name -match 'test|testing') { return "Testing Tools" }
    if ($name -match 'deprecated|retired') { return "Deprecated Extensions" }
    if ($name -match 'pack|collection') { return "Extension Packs" }
    if ($name -match 'language pack') { return "Language Packs" }
    if ($name -match 'education|learn|student') { return "Education & Learning" }
    if ($name -match 'iot|arduino|hardware') { return "IoT & Hardware" }
    if ($name -match '\bal\b|business central|dynamics') { return "Business Central (AL)" }
    if ($name -match 'quantum') { return "Quantum Computing" }
    
    # Priority 4: Description patterns
    if ($desc -match 'azure') { return "Azure & Cloud Services" }
    if ($desc -match 'remote development') { return "Remote Development" }
    if ($desc -match 'jupyter|notebook') { return "Data Science & Notebooks" }
    
    return "Other Extensions"
}

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

# Convert category name to anchor
function ConvertTo-Anchor {
    param([string]$text)
    return $text.ToLower() -replace '[^a-z0-9]+', '-' -replace '^-|-$', ''
}

Write-Host "Processing extensions and grouping by category..." -ForegroundColor Cyan

# Group extensions by inferred category
$extensionsByCategory = @{}
$allExtensions = @()

foreach ($ext in $data) {
    $displayName = $ext.displayName
    $publisherName = $ext.publisher.publisherName
    $extensionName = $ext.extensionName
    $shortDesc = $ext.shortDescription
    
    # Get version and other metadata
    $version = ""
    $lastUpdated = ""
    $installs = ""
    $rating = ""
    $installCount = 0
    $publishedDate = ""
    
    if ($ext.versions -and $ext.versions.Count -gt 0) {
        $latestVersion = $ext.versions[0]
        $version = $latestVersion.version
        $lastUpdated = $latestVersion.lastUpdated
    }
    
    if ($ext.publishedDate) {
        $publishedDate = $ext.publishedDate
    }
    
    # Get statistics
    $ratingCount = 0
    if ($ext.statistics) {
        foreach ($stat in $ext.statistics) {
            if ($stat.statisticName -eq "install") {
                $installCount = $stat.value
                $installs = Format-InstallCount -value $stat.value
            }
            if ($stat.statisticName -eq "averagerating") {
                $rating = [math]::Round($stat.value, 1)
            }
            if ($stat.statisticName -eq "ratingcount") {
                $ratingCount = $stat.value
            }
        }
    }
    
    # Extract resource links from properties
    $supportUrl = ""
    $issuesUrl = ""
    $repositoryUrl = ""
    $homepageUrl = ""
    $licenseUrl = ""
    $changelogUrl = ""
    $vsCodeEngine = ""
    
    # Extract target platforms
    $targetPlatforms = @()
    if ($ext.versions) {
        $targetPlatforms = $ext.versions | Where-Object { $_.targetPlatform } | Select-Object -ExpandProperty targetPlatform -Unique
        if ($targetPlatforms.Count -eq 0) {
            $targetPlatforms = @("universal")
        }
    }
    
    # Extract marketplace categories and tags
    $marketplaceCategories = @()
    $extensionTags = @()
    
    if ($ext.categories) {
        $marketplaceCategories = $ext.categories
    }
    
    if ($ext.tags) {
        $extensionTags = $ext.tags
    }
    
    if ($ext.versions -and $ext.versions.Count -gt 0 -and $ext.versions[0].properties) {
        foreach ($prop in $ext.versions[0].properties) {
            switch ($prop.key) {
                "Microsoft.VisualStudio.Services.Links.Support" { $supportUrl = $prop.value }
                "Microsoft.VisualStudio.Services.Links.GitHub" { $repositoryUrl = $prop.value }
                "Microsoft.VisualStudio.Services.Links.Source" { 
                    if (-not $repositoryUrl) { $repositoryUrl = $prop.value }
                }
                "Microsoft.VisualStudio.Services.Links.Learn" { $homepageUrl = $prop.value }
                "Microsoft.VisualStudio.Services.Content.License" { $licenseUrl = $prop.value }
                "Microsoft.VisualStudio.Services.Content.Changelog" { $changelogUrl = $prop.value }
                "Microsoft.VisualStudio.Code.Engine" { $vsCodeEngine = $prop.value }
            }
        }
        # If Issues URL not found, try to derive from repository
        if ($repositoryUrl -and -not $issuesUrl) {
            if ($repositoryUrl -match 'github\.com') {
                $cleanUrl = ($repositoryUrl -replace '\.git$', '') -replace '/$', ''
                $issuesUrl = "$cleanUrl/issues"
            }
        }
        # Support URL often points to issues
        if ($supportUrl -match '/issues') {
            $issuesUrl = $supportUrl
        }
    }
    
    # Build extension URL
    $url = "https://marketplace.visualstudio.com/items?itemName=$publisherName.$extensionName"
    
    # Infer category
    $category = Get-InferredCategory -displayName $displayName -extensionName $extensionName -publisherName $publisherName -shortDescription $shortDesc
    
    # Create extension object
    $extObj = [PSCustomObject]@{
        DisplayName = $displayName
        ExtensionName = $extensionName
        PublisherName = $publisherName
        ShortDescription = $shortDesc
        Version = $version
        LastUpdated = $lastUpdated
        PublishedDate = $publishedDate
        Installs = $installs
        InstallCount = $installCount
        Rating = $rating
        RatingCount = $ratingCount
        URL = $url
        Category = $category
        SupportUrl = $supportUrl
        IssuesUrl = $issuesUrl
        RepositoryUrl = $repositoryUrl
        HomepageUrl = $homepageUrl
        LicenseUrl = $licenseUrl
        ChangelogUrl = $changelogUrl
        VSCodeEngine = $vsCodeEngine
        TargetPlatforms = $targetPlatforms
        MarketplaceCategories = $marketplaceCategories
        Tags = $extensionTags
    }
    
    $allExtensions += $extObj
    
    if (-not $extensionsByCategory.ContainsKey($category)) {
        $extensionsByCategory[$category] = @()
    }
    $extensionsByCategory[$category] += $extObj
}

Write-Host "Categorized into $($extensionsByCategory.Keys.Count) categories" -ForegroundColor Green

# Sort categories by count (descending) - most popular first
$sortedCategories = $extensionsByCategory.Keys | Sort-Object -Property { $extensionsByCategory[$_].Count } -Descending

# Start building markdown
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

$markdown = @"
# Microsoft VS Code Extensions - Complete Catalog

**Comprehensive listing of all Microsoft Visual Studio Code extensions**

*Last Updated: $datestamp at $($timestamp.Split(' ')[1]) UTC*

$provenanceLine

<!-- BUILD_METADATA
timestamp: $timestampISO
commit: $commitSHA
run_id: $runID
extensions: $($data.Count)
categories: $($sortedCategories.Count)
-->

---

## 📊 Quick Stats

- **Total Extensions:** $($data.Count)
- **Categories:** $($sortedCategories.Count)
- **Generated:** $timestamp
- **Source:** [Microsoft Publisher Page](https://marketplace.visualstudio.com/publishers/Microsoft)

---

## 🏆 Top 10 Most Installed Extensions

"@

# Get top 10 by install count
$top10 = $allExtensions | Sort-Object -Property InstallCount -Descending | Select-Object -First 10
$rank = 0
foreach ($ext in $top10) {
    $rank++
    $markdown += "$rank. **[$($ext.DisplayName)]($($ext.URL))** - $($ext.Installs) installs`n"
}

$markdown += "`n---`n`n"

# Add Table of Contents
$markdown += "## 📑 Table of Contents`n`n"

# Add category icons mapping
$categoryIcons = @{
    ".NET Development" = "⚡"
    "AI & Machine Learning" = "🤖"
    "Azure & Cloud Services" = "☁️"
    "Business Central (AL)" = "📊"
    "C/C++ Development" = "🔧"
    "Collaboration Tools" = "👥"
    "Containers & Kubernetes" = "🐳"
    "Data Science & Notebooks" = "📈"
    "Debugging Tools" = "🐛"
    "Deprecated Extensions" = "⚠️"
    "Education & Learning" = "🎓"
    "Extension Packs" = "📦"
    "IoT & Hardware" = "🔌"
    "Java Development" = "☕"
    "JavaScript & TypeScript" = "📜"
    "Linters & Formatters" = "✨"
    "Other Extensions" = "🔮"
    "PowerShell Development" = "💻"
    "Python Development" = "🐍"
    "Quantum Computing" = "⚛️"
    "Remote Development" = "🌐"
    "Testing Tools" = "🧪"
    "Themes & Appearance" = "🎨"
    "Version Control" = "🔀"
    "Web Development" = "🌍"
}

# Calculate category statistics
$categoryStats = @()
foreach ($category in $sortedCategories) {
    $count = $extensionsByCategory[$category].Count
    $percentage = [math]::Round(($count / $data.Count) * 100, 1)
    $categoryStats += [PSCustomObject]@{
        Category = $category
        Count = $count
        Percentage = $percentage
    }
}

# Sort by count to identify top categories
$topCategories = $categoryStats | Sort-Object -Property Count -Descending | Select-Object -First 3

$markdown += "### 🔥 Popular Categories (Top 3)`n`n"
foreach ($cat in $topCategories) {
    $icon = if ($categoryIcons.ContainsKey($cat.Category)) { $categoryIcons[$cat.Category] } else { "📁" }
    $anchor = ConvertTo-Anchor -text $cat.Category
    $markdown += "- $icon **[$($cat.Category)](#$anchor)** → $($cat.Count) extensions ($($cat.Percentage)%)`n"
}

$markdown += "`n### 📚 All Categories (by Count)`n`n"
$markdown += "| # | Icon | Category | Count | % | Jump |`n"
$markdown += "|---|:---:|----------|------:|---:|------|`n"

$catNum = 0
$totalCount = 0
foreach ($category in $sortedCategories) {
    $catNum++
    $count = $extensionsByCategory[$category].Count
    $totalCount += $count
    $percentage = [math]::Round(($count / $data.Count) * 100, 1)
    $anchor = ConvertTo-Anchor -text $category
    $icon = if ($categoryIcons.ContainsKey($category)) { $categoryIcons[$category] } else { "📁" }
    
    # Add popular badge for top 3 categories
    $badge = ""
    if ($topCategories.Category -contains $category) {
        $badge = " 🔥"
    }
    
    $markdown += "| $catNum | $icon | **$category**$badge | $count | $percentage% | [View →](#$anchor) |`n"
}

$markdown += "`n**Total: $totalCount extensions across $($sortedCategories.Count) categories**`n`n"

# Add quick navigation for developer-focused categories
$markdown += "### 🚀 Quick Navigation`n`n"
$devCategories = @(
    "Python Development",
    ".NET Development", 
    "JavaScript & TypeScript",
    "Azure & Cloud Services",
    "Remote Development",
    "AI & Machine Learning"
)

foreach ($devCat in $devCategories) {
    if ($extensionsByCategory.ContainsKey($devCat)) {
        $anchor = ConvertTo-Anchor -text $devCat
        $count = $extensionsByCategory[$devCat].Count
        $icon = if ($categoryIcons.ContainsKey($devCat)) { $categoryIcons[$devCat] } else { "📁" }
        $markdown += "- $icon [$devCat](#$anchor) ($count)`n"
    }
}

$markdown += "`n[Back to Top](#microsoft-vs-code-extensions---complete-reference-guide)`n`n"

# Add complete extension index section
$markdown += "---`n`n"
$markdown += "### 📋 Complete Extension Index`n`n"
$markdown += "*All 492 extensions organized by category - Click any extension name to jump to its marketplace page*`n`n"

foreach ($category in $sortedCategories) {
    $catExtensions = $extensionsByCategory[$category]
    $count = $catExtensions.Count
    $percentage = [math]::Round(($count / $data.Count) * 100, 1)
    $anchor = ConvertTo-Anchor -text $category
    $icon = if ($categoryIcons.ContainsKey($category)) { $categoryIcons[$category] } else { "📁" }
    
    # Get all extensions sorted by install count
    $allExts = $catExtensions | Sort-Object -Property InstallCount -Descending
    
    $markdown += "#### $icon $category`n`n"
    $markdown += "**$count extensions** ($percentage%) | [View Full Category →](#$anchor)`n`n"
    
    if ($allExts.Count -gt 0) {
        $extNum = 1
        foreach ($ext in $allExts) {
            $installs = Format-InstallCount -value $ext.InstallCount
            $markdown += "$extNum. **[$($ext.DisplayName)]($($ext.URL))** - $installs installs`n"
            $extNum++
        }
    }
    
    $markdown += "`n"
}

$markdown += "---`n`n"
$markdown += "[⬆ Back to Table of Contents](#-table-of-contents)`n`n"
$markdown += "---`n`n"

Write-Host "Generating markdown content for each category..." -ForegroundColor Cyan

# Generate markdown for each category
$globalNumber = 0
foreach ($category in $sortedCategories) {
    $anchor = ConvertTo-Anchor -text $category
    $markdown += "## $category`n`n"
    
    # Add category stats
    $catExtensions = $extensionsByCategory[$category]
    $totalInstalls = ($catExtensions | Measure-Object -Property InstallCount -Sum).Sum
    $avgRating = ($catExtensions | Where-Object { $_.Rating -gt 0 } | Measure-Object -Property Rating -Average).Average
    
    $markdown += "**Category Stats:** $($catExtensions.Count) extensions"
    if ($totalInstalls -gt 0) {
        $markdown += " | Total Installs: $(Format-InstallCount -value $totalInstalls)"
    }
    if ($avgRating -gt 0) {
        $markdown += " | Avg Rating: $([math]::Round($avgRating, 1))⭐"
    }
    $markdown += "`n`n"
    
    # Add back to TOC link at the beginning of each section
    $markdown += "[⬆ Back to Table of Contents](#-table-of-contents)`n`n"
    $markdown += "---`n`n"
    
    # Sort extensions by install count (popular first), then by name
    $extensions = $catExtensions | Sort-Object -Property @{Expression={$_.InstallCount}; Descending=$true}, DisplayName
    
    $categoryNumber = 0
    foreach ($ext in $extensions) {
        $globalNumber++
        $categoryNumber++
        
        # Extension header with dual numbering
        $id = "$($ext.PublisherName).$($ext.ExtensionName)"
        $newBadge = if ($addedIds.Contains($id)) { " ![NEW](https://img.shields.io/badge/NEW-brightgreen)" } else { "" }
        $markdown += "### $categoryNumber. [$($ext.DisplayName)]($($ext.URL))$newBadge`n"
        $markdown += "*Extension #$globalNumber of $($data.Count)*`n`n"
        
        if ($ext.ShortDescription) {
            $markdown += "$($ext.ShortDescription)`n`n"
        }
        
        $markdown += "**Details:**`n`n"
        $markdown += "- **Extension ID:** ``$($ext.PublisherName).$($ext.ExtensionName)```n"
        if ($ext.Version) { $markdown += "- **Version:** $($ext.Version)`n" }
        if ($ext.Installs) { $markdown += "- **Installs:** $($ext.Installs)`n" }
        if ($ext.Rating) { 
            $ratingDisplay = "⭐ $($ext.Rating)/5"
            if ($ext.RatingCount -gt 0) {
                $ratingDisplay += " ($($ext.RatingCount) ratings)"
            }
            $markdown += "- **Rating:** $ratingDisplay`n"
        }
        if ($ext.PublishedDate) {
            $datePublished = [DateTime]::Parse($ext.PublishedDate).ToString("yyyy-MM-dd")
            $markdown += "- **Published:** $datePublished`n"
        }
        if ($ext.LastUpdated) { 
            $dateUpdated = [DateTime]::Parse($ext.LastUpdated).ToString("yyyy-MM-dd")
            $markdown += "- **Last Updated:** $dateUpdated`n" 
        }
        if ($ext.VSCodeEngine) {
            $markdown += "- **VS Code Engine:** $($ext.VSCodeEngine)`n"
        }
        $markdown += "- **Marketplace:** $($ext.URL)`n"
        
        # Add Resources section if any links are available
        $hasResources = $ext.SupportUrl -or $ext.IssuesUrl -or $ext.RepositoryUrl -or $ext.HomepageUrl -or $ext.LicenseUrl -or $ext.ChangelogUrl
        if ($hasResources) {
            $markdown += "`n**Resources:**`n`n"
            if ($ext.RepositoryUrl) { $markdown += "- 📦 [Repository]($($ext.RepositoryUrl))`n" }
            if ($ext.IssuesUrl) { $markdown += "- 🐛 [Issues]($($ext.IssuesUrl))`n" }
            if ($ext.SupportUrl -and $ext.SupportUrl -ne $ext.IssuesUrl) { $markdown += "- 💬 [Support]($($ext.SupportUrl))`n" }
            if ($ext.HomepageUrl) { $markdown += "- 🏠 [Homepage]($($ext.HomepageUrl))`n" }
            if ($ext.ChangelogUrl) { $markdown += "- 📝 [Changelog]($($ext.ChangelogUrl))`n" }
            if ($ext.LicenseUrl) { $markdown += "- ⚖️ [License]($($ext.LicenseUrl))`n" }
        }
        
        # Add Marketplace Categories section
        if ($ext.MarketplaceCategories -and $ext.MarketplaceCategories.Count -gt 0) {
            $markdown += "`n**Marketplace Categories:**`n`n"
            $markdown += "$($ext.MarketplaceCategories -join ', ')`n"
        }
        
        # Add Tags section
        if ($ext.Tags -and $ext.Tags.Count -gt 0) {
            $markdown += "`n**Tags:**`n`n"
            $markdown += "$($ext.Tags -join ', ')`n"
        }
        
        # Add Works With (Target Platforms) section
        if ($ext.TargetPlatforms -and $ext.TargetPlatforms.Count -gt 0) {
            $markdown += "`n**Works With:**`n`n"
            $platformNames = @{
                "universal" = "All Platforms"
                "web" = "Web"
                "win32-x64" = "Windows x64"
                "win32-arm64" = "Windows ARM64"
                "win32-ia32" = "Windows x86"
                "linux-x64" = "Linux x64"
                "linux-arm64" = "Linux ARM64"
                "linux-armhf" = "Linux ARM"
                "darwin-x64" = "macOS Intel"
                "darwin-arm64" = "macOS Apple Silicon"
                "alpine-x64" = "Alpine Linux x64"
                "alpine-arm64" = "Alpine Linux ARM64"
            }
            
            $platformList = $ext.TargetPlatforms | ForEach-Object {
                if ($platformNames.ContainsKey($_)) { $platformNames[$_] } else { $_ }
            }
            $markdown += "$($platformList -join ', ')`n"
        }
        
        $markdown += "`n---`n`n"
    }
    
    # Back to top link after each category
    $markdown += "[⬆ Back to Table of Contents](#-table-of-contents)`n`n"
    $markdown += "---`n`n"
}

# Add footer
$markdown += "`n## 📄 Document Information`n`n"
$markdown += "- **Version:** 2.0`n"
$markdown += "- **Total Extensions:** $($data.Count)`n"
$markdown += "- **Categories:** $($sortedCategories.Count)`n"
$markdown += "- **Generated:** $timestamp`n"
$markdown += "- **Build:** ``$commitSHA`` / Run ``$runID```n"
$markdown += "- **Script:** generate_markdown.ps1`n`n"
$markdown += "---`n`n"
$markdown += "*This document was automatically generated from the Visual Studio Code Marketplace API.*`n"
$markdown += "*For the most up-to-date information, visit the [Microsoft Publisher Page](https://marketplace.visualstudio.com/publishers/Microsoft).*`n"

# Save markdown file
Write-Host "Saving markdown to: $outputFile" -ForegroundColor Cyan
$markdown | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "`n✓ SUCCESS: Markdown v2 document created!" -ForegroundColor Green
Write-Host "✓ Output file: $outputFile" -ForegroundColor Green
Write-Host "✓ Total extensions: $($data.Count)" -ForegroundColor Green
Write-Host "✓ Total categories: $($sortedCategories.Count)" -ForegroundColor Green

Write-Host "`nCategory Breakdown:" -ForegroundColor Yellow
$sortedCategories | ForEach-Object {
    $count = $extensionsByCategory[$_].Count
    $percentage = [math]::Round(($count / $data.Count) * 100, 1)
    Write-Host "  - ${_}: $count extensions ($percentage%)" -ForegroundColor White
}

Write-Host "`nFile saved successfully! Opening in VS Code..." -ForegroundColor Cyan

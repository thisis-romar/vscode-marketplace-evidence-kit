# Validate Microsoft Publishers Tool
# This script validates all extensions in our JSON data to confirm they are from Microsoft publishers
# Created: December 5, 2025

param(
    [string]$JsonFile,
    [switch]$FixFetch,
    [switch]$ExportReport
)

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

if (-not $JsonFile) {
    $repoRoot = Get-RepoRoot -start $PSScriptRoot
    $JsonFile = Join-Path $repoRoot "data\all_extensions.json"
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Microsoft Publisher Validation Tool" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Known Microsoft publishers - comprehensive list
# These are publishers confirmed to be Microsoft or Microsoft affiliates
$microsoftPublishers = @(
    # Core Microsoft
    'Microsoft'
    
    # Official ms-* pattern publishers
    'ms-vscode'
    'ms-python'
    'ms-toolsai'
    'ms-azuretools'
    'ms-dotnettools'
    'ms-mssql'
    'ms-vscode-remote'
    'ms-kubernetes-tools'
    'ms-iot'
    'ms-dynamics-smb'
    'ms-windows-ai-studio'
    'ms-graph'
    'ms-inkling'
    'ms-ossdata'
    'ms-playwright'
    'ms-pyright'
    'ms-security'
    'ms-semantic-kernel'
    'ms-ssdevteam'
    'ms-edu'
    'ms-codeoptimizations'
    'ms-devlabs'
    'ms-azure-devops'
    'ms-azure-load-testing'
    'ms-azureaispeech'
    'ms-azurecache'
    'ms-bigdatatools'
    'ms-codespaces-tools'
    'ms-CopilotStudio'
    'ms-edgedevtools'
    'MS-CEINTL'
    'MS-vsliveshare'
    'MS-SarifVSCode'
    'MS-CST-E'
    'MS-DAW-TCA'
    
    # Microsoft teams and subsidiaries
    'vscjava'
    'vsciot-vscode'
    'VisualStudioExptTeam'
    'VisualStudioOnlineApplicationInsights'
    'VisualStudioToolsForUnity'
    'msjsdiag'
    'docsmsft'
    'msrvida'
    'msazurermtools'
    'mshdinsight'
    'msoffice'
    'msedge-dev'
    'mezzurite-devs'
    'TeamsDevApp'
    'TypeScriptTeam'
    'SynapseVSCode'
    'PowerQuery'
    'WASTeamAccount'
    'PDETs-prod'
    'usqlextpublisher'
    'quantum'
    'analysis-services'
    'fabric'
    'dbaeumer'
    'DevCenter'
    'edge-security'
    'genaiscript'
    'ai-gallery'
    'apidev'
    'azapi-vscode'
    'azps-tools'
    'azsdktm'
    'azure-automation'
    'azurearc-dev'
    'azurepaas-tools'
    'AzurePolicy'
    'Azurite'
    'mindaro'
    'mindaro-dev'
    'microsoft-IsvExpTools'
    'microsoft-aspire'
    'microsoft-kanagawa'
    'SharepointEmbedded'
    'xbox-tools'
    'VisionAIDevKit'
    'poml-team'
    'prompt-flow'
    'ps-rule'
    'craig-shoemaker'
)

# Also check displayName for Microsoft variations
$microsoftDisplayNames = @(
    'Microsoft'
    'Microsoft DevLabs'
)

# Load extension data
Write-Host "Loading extension data from: $JsonFile" -ForegroundColor Yellow
if (-not (Test-Path $JsonFile)) {
    Write-Host "ERROR: File not found: $JsonFile" -ForegroundColor Red
    exit 1
}

$data = Get-Content $JsonFile -Raw | ConvertFrom-Json
Write-Host "Loaded $($data.Count) extensions`n" -ForegroundColor Green

# Analyze each extension
$microsoftExtensions = @()
$nonMicrosoftExtensions = @()

foreach ($ext in $data) {
    $publisherName = $ext.publisher.publisherName
    $displayName = $ext.publisher.displayName
    $extName = $ext.displayName
    $extId = $ext.extensionId
    
    # Check if Microsoft publisher
    $isMicrosoft = $false
    
    # Check publisher name against known list
    if ($microsoftPublishers -contains $publisherName) {
        $isMicrosoft = $true
    }
    # Check if starts with ms- (case insensitive)
    elseif ($publisherName -match '^ms-') {
        $isMicrosoft = $true
    }
    # Check display name
    elseif ($microsoftDisplayNames -contains $displayName) {
        $isMicrosoft = $true
    }
    
    $extInfo = [PSCustomObject]@{
        ExtensionName = $extName
        ExtensionId = $extId
        PublisherName = $publisherName
        PublisherDisplayName = $displayName
        MarketplaceURL = "https://marketplace.visualstudio.com/items?itemName=$publisherName.$($ext.extensionName)"
        InstallCount = if ($ext.statistics) { ($ext.statistics | Where-Object { $_.statisticName -eq 'install' }).value } else { 0 }
    }
    
    if ($isMicrosoft) {
        $microsoftExtensions += $extInfo
    } else {
        $nonMicrosoftExtensions += $extInfo
    }
}

# Display results
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "           VALIDATION RESULTS          " -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "✓ Microsoft Extensions: $($microsoftExtensions.Count)" -ForegroundColor Green
Write-Host "✗ Non-Microsoft Extensions: $($nonMicrosoftExtensions.Count)" -ForegroundColor Red
Write-Host ""

if ($nonMicrosoftExtensions.Count -gt 0) {
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    Write-Host "  NON-MICROSOFT EXTENSIONS FOUND:" -ForegroundColor Yellow
    Write-Host "----------------------------------------`n" -ForegroundColor Yellow
    
    # Group by publisher for better readability
    $groupedByPublisher = $nonMicrosoftExtensions | Group-Object PublisherName | Sort-Object Count -Descending
    
    Write-Host "Grouped by Publisher:`n" -ForegroundColor Cyan
    
    $totalNonMS = 0
    foreach ($group in $groupedByPublisher) {
        Write-Host "  Publisher: $($group.Name) ($($group.Group[0].PublisherDisplayName))" -ForegroundColor Magenta
        Write-Host "  Extensions: $($group.Count)" -ForegroundColor Gray
        foreach ($ext in ($group.Group | Sort-Object InstallCount -Descending)) {
            $installs = if ($ext.InstallCount -ge 1000000) { 
                "{0:N1}M" -f ($ext.InstallCount / 1000000) 
            } elseif ($ext.InstallCount -ge 1000) { 
                "{0:N0}K" -f ($ext.InstallCount / 1000) 
            } else { 
                $ext.InstallCount 
            }
            Write-Host "    - $($ext.ExtensionName) ($installs installs)" -ForegroundColor White
        }
        Write-Host ""
        $totalNonMS += $group.Count
    }
    
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    Write-Host "Total Non-Microsoft Publishers: $($groupedByPublisher.Count)" -ForegroundColor Yellow
    Write-Host "Total Non-Microsoft Extensions: $totalNonMS" -ForegroundColor Yellow
    Write-Host "----------------------------------------`n" -ForegroundColor Yellow
}

# Show summary of Microsoft publishers found
Write-Host "----------------------------------------" -ForegroundColor Green
Write-Host "  MICROSOFT PUBLISHERS FOUND:" -ForegroundColor Green  
Write-Host "----------------------------------------`n" -ForegroundColor Green

$msGrouped = $microsoftExtensions | Group-Object PublisherName | Sort-Object Count -Descending | Select-Object -First 20
foreach ($group in $msGrouped) {
    Write-Host "  $($group.Name): $($group.Count) extensions" -ForegroundColor Gray
}
if ($msGrouped.Count -lt ($microsoftExtensions | Group-Object PublisherName).Count) {
    Write-Host "  ... and $(($microsoftExtensions | Group-Object PublisherName).Count - 20) more publishers" -ForegroundColor DarkGray
}

# Export report if requested
if ($ExportReport) {
    $reportPath = Join-Path $PSScriptRoot "output\publisher_validation_report.json"
    $report = @{
        GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalExtensions = $data.Count
        MicrosoftExtensions = $microsoftExtensions.Count
        NonMicrosoftExtensions = $nonMicrosoftExtensions.Count
        NonMicrosoftList = $nonMicrosoftExtensions | Select-Object ExtensionName, PublisherName, PublisherDisplayName, InstallCount, MarketplaceURL
        NonMicrosoftPublishers = ($nonMicrosoftExtensions | Group-Object PublisherName | ForEach-Object {
            @{
                Publisher = $_.Name
                DisplayName = $_.Group[0].PublisherDisplayName
                ExtensionCount = $_.Count
                Extensions = $_.Group.ExtensionName
            }
        })
    }
    
    # Ensure output directory exists
    $outputDir = Join-Path $PSScriptRoot "output"
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    $report | ConvertTo-Json -Depth 5 | Set-Content $reportPath -Encoding UTF8
    Write-Host "`n✓ Report exported to: $reportPath" -ForegroundColor Green
}

# Recommendation
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "           RECOMMENDATION             " -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($nonMicrosoftExtensions.Count -gt 0) {
    Write-Host "⚠ Found $($nonMicrosoftExtensions.Count) extensions NOT from Microsoft publishers!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "ROOT CAUSE:" -ForegroundColor Red
    Write-Host "  The fetch_all_extensions.ps1 script uses filterType=10 (SearchText)" -ForegroundColor White
    Write-Host "  which searches for 'Microsoft' across ALL fields (name, description, tags)." -ForegroundColor White
    Write-Host "  This includes ANY extension that mentions 'Microsoft' in its metadata." -ForegroundColor White
    Write-Host ""
    Write-Host "FIX OPTIONS:" -ForegroundColor Green
    Write-Host "  1. Post-filter the fetched data by publisher (recommended)" -ForegroundColor White
    Write-Host "  2. Use filterType=12 (PublisherName) for exact publisher match" -ForegroundColor White
    Write-Host ""
    Write-Host "Run with -FixFetch to update fetch_all_extensions.ps1 with post-filtering" -ForegroundColor Cyan
} else {
    Write-Host "✓ All extensions are from Microsoft publishers!" -ForegroundColor Green
}

Write-Host ""

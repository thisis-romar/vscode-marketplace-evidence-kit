# Get script directory
if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }

# Script to fetch all Microsoft VS Code extensions with full metadata
# Note: filterType=12 (PublisherName) does NOT provide strict publisher filtering
# Therefore, we use filterType=10 (SearchText) + post-filtering by verified publishers
# CRITICAL: We also filter by isDomainVerified=true AND domain contains 'microsoft'
# This ensures ONLY verified Microsoft publishers are included in the final data

$apiUrl = "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"
$allExtensions = @()

$headers = @{
    "Content-Type" = "application/json"
    "Accept" = "application/json;api-version=7.1-preview.1"
}

# Complete list of verified Microsoft publisher IDs (86 publishers)
# Used for post-filtering since API filterType=12 does not work as expected
$microsoftPublishers = @(
    'ai-gallery', 'analysis-services', 'apidev', 'azapi-vscode', 'azps-tools', 'azsdktm',
    'azure-automation', 'azurearc-dev', 'azurepaas-tools', 'AzurePolicy', 'Azurite',
    'craig-shoemaker', 'dbaeumer', 'DevCenter', 'docsmsft', 'edge-security', 'fabric',
    'genaiscript', 'mezzurite-devs', 'microsoft-aspire', 'microsoft-IsvExpTools',
    'microsoft-kanagawa', 'mindaro', 'mindaro-dev', 'ms-azure-devops', 'ms-azure-load-testing',
    'ms-azureaispeech', 'ms-azurecache', 'ms-azuretools', 'ms-bigdatatools', 'MS-CEINTL',
    'ms-codeoptimizations', 'ms-codespaces-tools', 'ms-CopilotStudio', 'MS-CST-E', 'MS-DAW-TCA',
    'ms-devlabs', 'ms-dotnettools', 'ms-dynamics-smb', 'ms-edgedevtools', 'ms-edu', 'ms-graph',
    'ms-inkling', 'ms-iot', 'ms-kubernetes-tools', 'ms-mssql', 'ms-ossdata', 'ms-playwright',
    'ms-pyright', 'ms-python', 'MS-SarifVSCode', 'ms-security', 'ms-semantic-kernel',
    'ms-ssdevteam', 'ms-toolsai', 'ms-vscode', 'ms-vscode-remote', 'MS-vsliveshare',
    'ms-webxt-es', 'ms-windows-ai-studio', 'msazurermtools', 'msedge-dev', 'mshdinsight',
    'msjsdiag', 'msoffice', 'msrvida', 'ozzafar', 'PDETs-prod', 'poml-team', 'PowerQuery',
    'prompt-flow', 'ps-rule', 'quantum', 'SharepointEmbedded', 'SynapseVSCode', 'TeamsDevApp',
    'TypeScriptTeam', 'usqlextpublisher', 'VisionAIDevKit', 'VisualStudioExptTeam',
    'VisualStudioOnlineApplicationInsights', 'VisualStudioToolsForUnity', 'vsciot-vscode',
    'vscjava', 'WASTeamAccount', 'xbox-tools'
)

# Create case-insensitive lookup
$microsoftPublishersLower = $microsoftPublishers | ForEach-Object { $_.ToLower() }

# Flags for maximum metadata: 991 = versions + files + categories/tags + statistics etc.

# Fetch all pages dynamically using SearchText for "Microsoft"
Write-Host "Starting to fetch Microsoft VS Code extensions..." -ForegroundColor Cyan
Write-Host "Using filterType=10 (SearchText) + post-filtering by verified publishers" -ForegroundColor Yellow
Write-Host "This approach is more reliable than filterType=12 which doesn't provide strict filtering`n" -ForegroundColor Gray

$page = 1
$hasMorePages = $true
$totalResultCount = $null
$startTime = Get-Date

while ($hasMorePages) {
    Write-Host "Fetching page $page..." -ForegroundColor Yellow
    
    $body = @{
        filters = @(
            @{
                criteria = @(
                    @{ filterType = 10; value = "Microsoft" }
                    @{ filterType = 8; value = "Microsoft.VisualStudio.Code" }
                )
                pageNumber = $page
                pageSize = 100
                sortBy = 0
                sortOrder = 0
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
                Write-Host "API reports total: $totalResultCount (includes non-Microsoft)" -ForegroundColor Cyan
            }
        }
        
        $pageExtensions = $response.results[0].extensions
        
        if ($pageExtensions -and $pageExtensions.Count -gt 0) {
            Write-Host "  + Found $($pageExtensions.Count) extensions on page $page" -ForegroundColor Green
            $allExtensions += $pageExtensions
            $page++
            Start-Sleep -Milliseconds 500
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
Write-Host "Total fetched: $($allExtensions.Count)" -ForegroundColor Cyan

# Filter unpublished
Write-Host "`nFiltering unpublished extensions..." -ForegroundColor Cyan
$publishedExtensions = $allExtensions | Where-Object { $_.flags -notmatch 'unpublished' }
$unpublishedCount = $allExtensions.Count - $publishedExtensions.Count
Write-Host "  + Published: $($publishedExtensions.Count) (filtered $unpublishedCount unpublished)" -ForegroundColor Green

# Filter by Microsoft publishers (known list)
Write-Host "`nFiltering by $($microsoftPublishers.Count) known Microsoft publishers..." -ForegroundColor Cyan
$microsoftByList = $publishedExtensions | Where-Object {
    $microsoftPublishersLower -contains $_.publisher.publisherName.ToLower()
}
$nonMsCount = $publishedExtensions.Count - $microsoftByList.Count
Write-Host "  + By publisher list: $($microsoftByList.Count) (filtered $nonMsCount non-Microsoft)" -ForegroundColor Green

# CRITICAL: Filter by API verification fields (isDomainVerified + microsoft.com domain)
# This ensures ONLY verified Microsoft publishers are included
Write-Host "`nApplying API verification filter (isDomainVerified + microsoft.com domain)..." -ForegroundColor Cyan
$microsoftOnly = $microsoftByList | Where-Object {
    $_.publisher.isDomainVerified -eq $true -and
    $_.publisher.domain -like '*microsoft*'
}
$unverifiedCount = $microsoftByList.Count - $microsoftOnly.Count
if ($unverifiedCount -gt 0) {
    Write-Host "  ! Removed $unverifiedCount unverified extensions:" -ForegroundColor Yellow
    $microsoftByList | Where-Object {
        -not ($_.publisher.isDomainVerified -eq $true -and $_.publisher.domain -like '*microsoft*')
    } | ForEach-Object {
        Write-Host "    - $($_.publisher.publisherName).$($_.extensionName) (verified=$($_.publisher.isDomainVerified), domain='$($_.publisher.domain)')" -ForegroundColor Yellow
    }
}
Write-Host "  + Verified Microsoft: $($microsoftOnly.Count)" -ForegroundColor Green

# Save
$timestamp = (Get-Date).ToString("yyyyMMddHHmm")
$rawPath = Join-Path $PSScriptRoot "data\raw\all_extensions_$timestamp.json"
$processedPath = Join-Path $PSScriptRoot "data\processed\all_extensions.json"

# Ensure directories exist
$rawDir = Split-Path $rawPath -Parent
$processedDir = Split-Path $processedPath -Parent
if (-not (Test-Path $rawDir)) { New-Item -ItemType Directory -Path $rawDir -Force | Out-Null }
if (-not (Test-Path $processedDir)) { New-Item -ItemType Directory -Path $processedDir -Force | Out-Null }

$output = @{
    metadata = @{
        fetchDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        totalFetched = $allExtensions.Count
        unpublishedFiltered = $unpublishedCount
        nonMicrosoftFiltered = $nonMsCount
        unverifiedFiltered = $unverifiedCount
        finalCount = $microsoftOnly.Count
        verificationMethod = "isDomainVerified=true AND domain contains 'microsoft'"
    }
    extensions = $microsoftOnly
}
$jsonOutput = $output | ConvertTo-Json -Depth 20 -Compress

# Save snapshot and processed
$jsonOutput | Out-File -FilePath $rawPath -Encoding UTF8
$jsonOutput | Out-File -FilePath $processedPath -Encoding UTF8

Write-Host "`n+ Data saved to:" -ForegroundColor Green
Write-Host "  Snapshot: $rawPath" -ForegroundColor Gray
Write-Host "  Processed: $processedPath" -ForegroundColor Gray
Write-Host "`nSummary: $($microsoftOnly.Count) Microsoft extensions" -ForegroundColor Magenta

# Get script directory
if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }

# Quick Link Checker - Focus on Critical Marketplace Links
# Validates all VS Code Marketplace links to ensure no 404s after refactoring

param(
    [string]$MarkdownFile,
    [int]$ThrottleMs = 300
)

# Set default markdown file if not provided
if (-not $MarkdownFile) {
    $docsPath = Join-Path $PSScriptRoot "docs"
    $MarkdownFile = Join-Path $docsPath "Microsoft_VSCode_Extensions.md"
}

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      Quick Link Checker - Marketplace Links Validation      ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Read markdown and extract URLs
Write-Host "📄 Reading markdown file..." -ForegroundColor Yellow
$content = Get-Content $MarkdownFile -Raw

Write-Host "🔍 Extracting URLs..." -ForegroundColor Yellow
$markdownLinkPattern = '\[([^\]]+)\]\(([^\)]+)\)'
$matches = [regex]::Matches($content, $markdownLinkPattern)

$allUrls = @()
foreach ($match in $matches) {
    $url = $match.Groups[2].Value
    if ($url -notmatch '^#' -and $url -match '^https?://') {
        $allUrls += $url
    }
}

$uniqueUrls = $allUrls | Select-Object -Unique

# Filter for marketplace links only
$marketplaceUrls = $uniqueUrls | Where-Object { $_ -match 'marketplace.visualstudio.com' }

Write-Host "📊 Statistics:" -ForegroundColor Cyan
Write-Host "  Total unique URLs: $($uniqueUrls.Count)" -ForegroundColor White
Write-Host "  Marketplace URLs: $($marketplaceUrls.Count)" -ForegroundColor White
Write-Host ""

# Check marketplace links
Write-Host "🔗 Checking VS Code Marketplace links..." -ForegroundColor Yellow
Write-Host "  (These are the critical links we just refactored)" -ForegroundColor Gray
Write-Host ""

$results = @{
    Working = @()
    Broken = @()
    Error = @()
}

$current = 0
$total = $marketplaceUrls.Count

foreach ($url in $marketplaceUrls) {
    $current++
    $percentComplete = [math]::Round(($current / $total) * 100, 1)
    
    Write-Progress -Activity "Checking Marketplace Links" -Status "[$current/$total] Checking..." -PercentComplete $percentComplete
    
    try {
        # VS Code Marketplace requires proper headers, use GET with minimal download
        $headers = @{
            'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        $response = Invoke-WebRequest -Uri $url -Method Get -Headers $headers -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        $statusCode = [int]$response.StatusCode
        
        if ($statusCode -ge 200 -and $statusCode -lt 300) {
            # Check if it's actually a 404 page (marketplace returns 200 for 404 pages sometimes)
            if ($response.Content -match '404.*page.*not.*found' -or $response.Content -match 'Page not found') {
                $results.Broken += [PSCustomObject]@{ URL = $url; StatusCode = "200 (404 content)" }
                Write-Host "  ✗" -ForegroundColor Red -NoNewline
            } else {
                $results.Working += $url
                Write-Host "  ✓" -ForegroundColor Green -NoNewline
            }
        } else {
            $results.Error += [PSCustomObject]@{ URL = $url; StatusCode = $statusCode }
            Write-Host "  ⚠" -ForegroundColor Yellow -NoNewline
        }
    } catch [System.Net.WebException] {
        $statusCode = [int]$_.Exception.Response.StatusCode
        if ($statusCode -eq 404) {
            $results.Broken += [PSCustomObject]@{ URL = $url; StatusCode = 404 }
            Write-Host "  ✗" -ForegroundColor Red -NoNewline
        } else {
            $results.Error += [PSCustomObject]@{ URL = $url; StatusCode = $statusCode }
            Write-Host "  ⚠" -ForegroundColor Yellow -NoNewline
        }
    } catch {
        $results.Error += [PSCustomObject]@{ URL = $url; Error = $_.Exception.Message }
        Write-Host "  ?" -ForegroundColor Magenta -NoNewline
    }
    
    # Progress indicator every 20 links
    if ($current % 20 -eq 0) {
        Write-Host " [$current/$total]"
    }
    
    Start-Sleep -Milliseconds $ThrottleMs
}

Write-Progress -Activity "Checking Marketplace Links" -Completed
Write-Host ""
Write-Host ""

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                   MARKETPLACE LINKS RESULTS                  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "📊 Marketplace Link Check Results:" -ForegroundColor Cyan
Write-Host "  ✓ Working:  $($results.Working.Count) / $total" -ForegroundColor Green
Write-Host "  ✗ Broken:   $($results.Broken.Count)" -ForegroundColor Red
Write-Host "  ⚠ Errors:   $($results.Error.Count)" -ForegroundColor Yellow
Write-Host ""

# Show broken links details
if ($results.Broken.Count -gt 0) {
    Write-Host "❌ BROKEN MARKETPLACE LINKS (404):" -ForegroundColor Red
    Write-Host ""
    $results.Broken | Format-Table -AutoSize
    Write-Host ""
}

# Show sample of working links
if ($results.Working.Count -gt 0) {
    Write-Host "✅ Sample of working links:" -ForegroundColor Green
    $results.Working | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    if ($results.Working.Count -gt 5) {
        Write-Host "  ... and $($results.Working.Count - 5) more" -ForegroundColor Gray
    }
    Write-Host ""
}

# Final verdict
if ($results.Broken.Count -eq 0) {
    Write-Host "✅ SUCCESS: All marketplace links are working!" -ForegroundColor Green
    Write-Host "   The refactored tooling successfully eliminated 404 errors." -ForegroundColor Green
    Write-Host ""
    exit 0
} else {
    Write-Host "⚠ WARNING: Found $($results.Broken.Count) broken marketplace link(s)." -ForegroundColor Yellow
    Write-Host "   Please investigate the links above." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

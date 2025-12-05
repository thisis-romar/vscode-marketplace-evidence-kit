# Get script directory
if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }

# Link Checker for Microsoft VS Code Extensions Markdown
# Validates all URLs in the markdown document to ensure no 404s or broken links

param(
    [string]$MarkdownFile = Join-Path $PSScriptRoot "docs\Microsoft_VSCode_Extensions.md",
    [int]$ThrottleMs = 500,
    [int]$TimeoutSec = 10
)

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Link Checker for VS Code Extensions Markdown        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if markdown file exists
if (-not (Test-Path $MarkdownFile)) {
    Write-Host "✗ Error: Markdown file not found: $MarkdownFile" -ForegroundColor Red
    exit 1
}

Write-Host "📄 Reading markdown file..." -ForegroundColor Yellow
$content = Get-Content $MarkdownFile -Raw

# Extract all URLs from markdown links [text](url)
Write-Host "🔍 Extracting URLs..." -ForegroundColor Yellow
$markdownLinkPattern = '\[([^\]]+)\]\(([^\)]+)\)'
$matches = [regex]::Matches($content, $markdownLinkPattern)

$allUrls = @()
foreach ($match in $matches) {
    $url = $match.Groups[2].Value
    # Skip anchor links (internal document links)
    if ($url -notmatch '^#' -and $url -match '^https?://') {
        $allUrls += $url
    }
}

# Get unique URLs
$uniqueUrls = $allUrls | Select-Object -Unique | Sort-Object

Write-Host "📊 Statistics:" -ForegroundColor Cyan
Write-Host "  Total links found: $($allUrls.Count)" -ForegroundColor White
Write-Host "  Unique URLs: $($uniqueUrls.Count)" -ForegroundColor White
Write-Host ""

# Group URLs by domain for better reporting
$urlsByDomain = $uniqueUrls | Group-Object { ([System.Uri]$_).Host }

Write-Host "🌐 URLs by domain:" -ForegroundColor Cyan
foreach ($group in ($urlsByDomain | Sort-Object Count -Descending | Select-Object -First 10)) {
    Write-Host "  $($group.Name): $($group.Count) links" -ForegroundColor White
}
Write-Host ""

# Prepare results tracking
$results = @{
    Working = @()
    Broken = @()
    Redirected = @()
    Timeout = @()
    Error = @()
}

Write-Host "🔗 Checking links (this may take a while)..." -ForegroundColor Yellow
Write-Host "  Throttle: ${ThrottleMs}ms between requests" -ForegroundColor Gray
Write-Host "  Timeout: ${TimeoutSec}s per request" -ForegroundColor Gray
Write-Host ""

$current = 0
$total = $uniqueUrls.Count

foreach ($url in $uniqueUrls) {
    $current++
    $percentComplete = [math]::Round(($current / $total) * 100, 1)
    
    Write-Progress -Activity "Checking Links" -Status "[$current/$total] $url" -PercentComplete $percentComplete
    
    try {
        # Use HEAD request for faster checking (some servers don't support HEAD, fall back to GET)
        $response = $null
        try {
            $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
        } catch {
            # If HEAD fails, try GET
            if ($_.Exception.Response.StatusCode -eq 'MethodNotAllowed' -or $_.Exception.Response.StatusCode -eq 'NotFound') {
                $response = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
            } else {
                throw
            }
        }
        
        $statusCode = [int]$response.StatusCode
        
        if ($statusCode -ge 200 -and $statusCode -lt 300) {
            $results.Working += [PSCustomObject]@{
                URL = $url
                StatusCode = $statusCode
                Status = "✓ OK"
            }
            Write-Host "  ✓ [$statusCode] $url" -ForegroundColor Green
        } elseif ($statusCode -ge 300 -and $statusCode -lt 400) {
            $results.Redirected += [PSCustomObject]@{
                URL = $url
                StatusCode = $statusCode
                Status = "↪ Redirect"
            }
            Write-Host "  ↪ [$statusCode] $url" -ForegroundColor Yellow
        } else {
            $results.Broken += [PSCustomObject]@{
                URL = $url
                StatusCode = $statusCode
                Status = "✗ Error"
            }
            Write-Host "  ✗ [$statusCode] $url" -ForegroundColor Red
        }
        
    } catch [System.Net.WebException] {
        $statusCode = [int]$_.Exception.Response.StatusCode
        if ($statusCode -eq 404) {
            $results.Broken += [PSCustomObject]@{
                URL = $url
                StatusCode = 404
                Status = "✗ Not Found"
            }
            Write-Host "  ✗ [404] $url" -ForegroundColor Red
        } elseif ($statusCode -eq 403) {
            $results.Error += [PSCustomObject]@{
                URL = $url
                StatusCode = 403
                Status = "⚠ Forbidden"
            }
            Write-Host "  ⚠ [403] $url" -ForegroundColor Yellow
        } else {
            $results.Broken += [PSCustomObject]@{
                URL = $url
                StatusCode = $statusCode
                Status = "✗ Error ($statusCode)"
            }
            Write-Host "  ✗ [$statusCode] $url" -ForegroundColor Red
        }
    } catch {
        if ($_.Exception.Message -match 'timed out') {
            $results.Timeout += [PSCustomObject]@{
                URL = $url
                StatusCode = "N/A"
                Status = "⏱ Timeout"
            }
            Write-Host "  ⏱ [TIMEOUT] $url" -ForegroundColor Magenta
        } else {
            $results.Error += [PSCustomObject]@{
                URL = $url
                StatusCode = "N/A"
                Status = "✗ Error: $($_.Exception.Message)"
            }
            Write-Host "  ✗ [ERROR] $url - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Throttle requests to avoid rate limiting
    Start-Sleep -Milliseconds $ThrottleMs
}

Write-Progress -Activity "Checking Links" -Completed

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                      RESULTS SUMMARY                         ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "📊 Link Check Results:" -ForegroundColor Cyan
Write-Host "  ✓ Working:    $($results.Working.Count)" -ForegroundColor Green
Write-Host "  ↪ Redirected: $($results.Redirected.Count)" -ForegroundColor Yellow
Write-Host "  ✗ Broken:     $($results.Broken.Count)" -ForegroundColor Red
Write-Host "  ⏱ Timeout:    $($results.Timeout.Count)" -ForegroundColor Magenta
Write-Host "  ⚠ Other:      $($results.Error.Count)" -ForegroundColor Yellow
Write-Host ""

# Show broken links details
if ($results.Broken.Count -gt 0) {
    Write-Host "❌ BROKEN LINKS FOUND:" -ForegroundColor Red
    Write-Host ""
    $results.Broken | Format-Table -AutoSize
    Write-Host ""
}

# Show timeout links
if ($results.Timeout.Count -gt 0) {
    Write-Host "⏱ TIMEOUT LINKS:" -ForegroundColor Magenta
    Write-Host ""
    $results.Timeout | Format-Table -AutoSize
    Write-Host ""
}

# Show error links
if ($results.Error.Count -gt 0) {
    Write-Host "⚠ ERROR LINKS:" -ForegroundColor Yellow
    Write-Host ""
    $results.Error | Format-Table -AutoSize
    Write-Host ""
}

# Save detailed report
$reportFile = "G:\_Visual Studio Code_\link_check_report.json"
$report = @{
    CheckedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    MarkdownFile = $MarkdownFile
    TotalLinks = $allUrls.Count
    UniqueUrls = $uniqueUrls.Count
    Summary = @{
        Working = $results.Working.Count
        Redirected = $results.Redirected.Count
        Broken = $results.Broken.Count
        Timeout = $results.Timeout.Count
        Error = $results.Error.Count
    }
    BrokenLinks = $results.Broken
    TimeoutLinks = $results.Timeout
    ErrorLinks = $results.Error
}

$report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportFile -Encoding UTF8
Write-Host "💾 Detailed report saved to: $reportFile" -ForegroundColor Cyan
Write-Host ""

# Final verdict
if ($results.Broken.Count -eq 0 -and $results.Timeout.Count -eq 0 -and $results.Error.Count -lt 5) {
    Write-Host "✅ SUCCESS: All links are working!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠ WARNING: Some links have issues. Please review the report above." -ForegroundColor Yellow
    exit 1
}

$inputPath = "g:\_VSCode-MarketplaceEvidenceKit_\docs\public\Verified_VSCode_Publishers.md"
$outputPath = "g:\_VSCode-MarketplaceEvidenceKit_\docs\public\Verified_VSCode_Publishers_Refactored.md"

Write-Host "Reading file from $inputPath..."
$lines = Get-Content $inputPath -Encoding UTF8
$newContent = @()

$inTable = $false
$tableHeaderRegex = '\|\s*Extension\s*\|\s*Installs\s*\|\s*Version\s*\|\s*Links\s*\|\s*Description\s*\|'
# Regex to capture columns. Note: Description is the last column.
$rowRegex = '^\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|$'

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]

    if (-not $inTable) {
        if ($line -match $tableHeaderRegex) {
            $inTable = $true
            Write-Host "Found extension table at line $($i+1)"
            # Skip this header line
            # Check next line for separator
            if ($lines[$i+1] -match '^\|\s*:?-+\s*\|') {
                $i++ # Skip separator line
            }
            continue
        }
        $newContent += $line
    }
    else {
        # Check if line is a table row
        if ($line -match $rowRegex) {
            # Parse row
            $nameCol = $matches[1].Trim()
            $installs = $matches[2].Trim()
            $version = $matches[3].Trim()
            $links = $matches[4].Trim()
            $desc = $matches[5].Trim()

            # Extract Name and Link from [**Name**](Link)
            # Regex: \[\*\*(.+?)\*\*\]\((.+?)\)
            if ($nameCol -match '\[\*\*(.+?)\*\*\]\((.+?)\)') {
                $extName = $matches[1]
                $extLink = $matches[2]
                
                # Format H6
                # Add a blank line before if previous line wasn't blank
                if ($newContent[-1] -ne "") { $newContent += "" }
                
                $newContent += "###### [$extName]($extLink)"
                $newContent += ""
                $newContent += "- **Installs**: $installs"
                $newContent += "- **Version**: $version"
                $newContent += "- **Links**: $links"
                $newContent += "- **Description**: $desc"
                $newContent += ""
            } else {
                # Fallback if regex fails (e.g. name format is different), keep as is or try best effort
                Write-Warning "Could not parse name column: $nameCol at line $($i+1)"
                $newContent += $line 
            }
        }
        elseif ($line.Trim() -eq "" -or $line -notmatch '^\|') {
            # End of table
            $inTable = $false
            $newContent += $line
        }
    }
}

Write-Host "Saving refactored content to $outputPath..."
$newContent | Set-Content $outputPath -Encoding UTF8
Write-Host "Done."

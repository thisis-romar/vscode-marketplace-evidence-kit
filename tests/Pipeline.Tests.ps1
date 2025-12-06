# Pester tests for VS Code Marketplace Evidence Kit
# Run with: Invoke-Pester -Path .\tests\

BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $dataProcessed = Join-Path $repoRoot "data\processed"
    $docsPublic = Join-Path $repoRoot "docs\public"
}

Describe "Data Directory Structure" {
    It "data/processed directory exists" {
        Test-Path $dataProcessed | Should -Be $true
    }

    It "docs/public directory exists" {
        Test-Path $docsPublic | Should -Be $true
    }
}

Describe "Processed Data Schema" {
    Context "all_extensions.json" {
        BeforeAll {
            $extFile = Join-Path $dataProcessed "all_extensions.json"
            if (Test-Path $extFile) {
                $extData = Get-Content $extFile -Raw | ConvertFrom-Json
            }
        }

        It "file exists" {
            Test-Path (Join-Path $dataProcessed "all_extensions.json") | Should -Be $true
        }

        It "has metadata object" -Skip:(-not $extData) {
            $extData.metadata | Should -Not -BeNullOrEmpty
        }

        It "metadata has fetchDate" -Skip:(-not $extData) {
            $extData.metadata.fetchDate | Should -Not -BeNullOrEmpty
        }

        It "has extensions array" -Skip:(-not $extData) {
            $extData.extensions | Should -BeOfType [System.Array]
        }

        It "extensions have required fields" -Skip:(-not $extData -or $extData.extensions.Count -eq 0) {
            $ext = $extData.extensions[0]
            $ext.extensionName | Should -Not -BeNullOrEmpty
            $ext.publisher | Should -Not -BeNullOrEmpty
            $ext.publisher.publisherName | Should -Not -BeNullOrEmpty
        }
    }

    Context "verified_publishers.json" {
        BeforeAll {
            $pubFile = Join-Path $dataProcessed "verified_publishers.json"
            if (Test-Path $pubFile) {
                $pubData = Get-Content $pubFile -Raw | ConvertFrom-Json
            }
        }

        It "file exists" {
            Test-Path (Join-Path $dataProcessed "verified_publishers.json") | Should -Be $true
        }

        It "has metadata object" -Skip:(-not $pubData) {
            $pubData.metadata | Should -Not -BeNullOrEmpty
        }

        It "has publishers array" -Skip:(-not $pubData) {
            $pubData.publishers | Should -BeOfType [System.Array]
        }

        It "has domainStats array" -Skip:(-not $pubData) {
            $pubData.domainStats | Should -BeOfType [System.Array]
        }

        It "publishers have required fields" -Skip:(-not $pubData -or $pubData.publishers.Count -eq 0) {
            $pub = $pubData.publishers[0]
            $pub.publisherName | Should -Not -BeNullOrEmpty
            $pub.domain | Should -Not -BeNullOrEmpty
            $pub.isDomainVerified | Should -Be $true
        }
    }
}

Describe "Generated Markdown" {
    Context "Microsoft_VSCode_Extensions.md" {
        BeforeAll {
            $mdFile = Join-Path $docsPublic "Microsoft_VSCode_Extensions.md"
            if (Test-Path $mdFile) {
                $mdContent = Get-Content $mdFile -Raw
            }
        }

        It "file exists" {
            Test-Path (Join-Path $docsPublic "Microsoft_VSCode_Extensions.md") | Should -Be $true
        }

        It "has title header" -Skip:(-not $mdContent) {
            $mdContent | Should -Match "# Microsoft VS Code Extensions"
        }

        It "has table of contents" -Skip:(-not $mdContent) {
            $mdContent | Should -Match "Table of Contents"
        }

        It "has quick stats section" -Skip:(-not $mdContent) {
            $mdContent | Should -Match "Quick Stats"
        }
    }

    Context "Verified_VSCode_Publishers.md" {
        BeforeAll {
            $mdFile = Join-Path $docsPublic "Verified_VSCode_Publishers.md"
            if (Test-Path $mdFile) {
                $mdContent = Get-Content $mdFile -Raw
            }
        }

        It "file exists" {
            Test-Path (Join-Path $docsPublic "Verified_VSCode_Publishers.md") | Should -Be $true
        }

        It "has title header" -Skip:(-not $mdContent) {
            $mdContent | Should -Match "Verified VS Code Extension Publishers"
        }

        It "has domains directory" -Skip:(-not $mdContent) {
            $mdContent | Should -Match "Domains Directory"
        }
    }
}

Describe "Deterministic Sorting" {
    Context "Publishers are sorted by installs" {
        BeforeAll {
            $pubFile = Join-Path $dataProcessed "verified_publishers.json"
            if (Test-Path $pubFile) {
                $pubData = Get-Content $pubFile -Raw | ConvertFrom-Json
            }
        }

        It "publishers sorted descending by totalInstalls" -Skip:(-not $pubData -or $pubData.publishers.Count -lt 2) {
            $installs = $pubData.publishers | ForEach-Object { $_.totalInstalls }
            for ($i = 0; $i -lt $installs.Count - 1; $i++) {
                $installs[$i] | Should -BeGreaterOrEqual $installs[$i + 1]
            }
        }
    }
}

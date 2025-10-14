# Test Runner for TextToSpeech Generator v3.2
# Executes all test suites and generates comprehensive reports

param(
    [string[]]$TestSuites = @("Unit", "Integration", "Performance"),
    [string]$OutputPath = "TestResults",
    [switch]$GenerateReport,
    [switch]$FailFast
)

# Ensure Pester is available
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installing Pester testing framework..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Initialize test environment
$TestRoot = $PSScriptRoot
$ModuleRoot = Split-Path $TestRoot -Parent
$OutputDirectory = Join-Path $TestRoot $OutputPath

# Create output directory
if (-not (Test-Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

Write-Host "=== TextToSpeech Generator v3.2 Test Suite ===" -ForegroundColor Cyan
Write-Host "Test Root: $TestRoot" -ForegroundColor Gray
Write-Host "Module Root: $ModuleRoot" -ForegroundColor Gray
Write-Host "Output Directory: $OutputDirectory" -ForegroundColor Gray
Write-Host ""

$totalResults = @{
    TestSuites = @()
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    SkippedTests = 0
    Duration = [TimeSpan]::Zero
    OverallResult = "Unknown"
}

$overallStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($suite in $TestSuites) {
    Write-Host "Running $suite Tests..." -ForegroundColor Yellow
    
    $suiteStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $suitePath = Join-Path $TestRoot $suite
    
    if (-not (Test-Path $suitePath)) {
        Write-Host "Test suite path not found: $suitePath" -ForegroundColor Red
        continue
    }
    
    # Configure Pester for this suite
    $pesterConfig = [PesterConfiguration]::Default
    $pesterConfig.Run.Path = $suitePath
    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Output.Verbosity = "Normal"
    
    if ($GenerateReport) {
        $reportPath = Join-Path $OutputDirectory "$suite-TestResults.xml"
        $pesterConfig.TestResult.Enabled = $true
        $pesterConfig.TestResult.OutputPath = $reportPath
        $pesterConfig.TestResult.OutputFormat = "NUnitXml"
    }
    
    try {
        $result = Invoke-Pester -Configuration $pesterConfig
        $suiteStopwatch.Stop()
        
        $suiteResult = @{
            Name = $suite
            TotalCount = $result.TotalCount
            PassedCount = $result.PassedCount
            FailedCount = $result.FailedCount
            SkippedCount = $result.SkippedCount
            Duration = $suiteStopwatch.Elapsed
            Result = if ($result.FailedCount -eq 0) { "Passed" } else { "Failed" }
            Details = $result
        }
        
        $totalResults.TestSuites += $suiteResult
        $totalResults.TotalTests += $result.TotalCount
        $totalResults.PassedTests += $result.PassedCount
        $totalResults.FailedTests += $result.FailedCount
        $totalResults.SkippedTests += $result.SkippedCount
        
        # Display suite results
        $color = if ($suiteResult.Result -eq "Passed") { "Green" } else { "Red" }
        Write-Host "$suite Tests: " -NoNewline
        Write-Host $suiteResult.Result -ForegroundColor $color
        Write-Host "  Total: $($result.TotalCount), Passed: $($result.PassedCount), Failed: $($result.FailedCount), Skipped: $($result.SkippedCount)"
        Write-Host "  Duration: $($suiteStopwatch.Elapsed.TotalSeconds.ToString('F2'))s"
        
        if ($result.FailedCount -gt 0) {
            Write-Host "  Failed Tests:" -ForegroundColor Red
            foreach ($test in $result.Tests | Where-Object { $_.Result -eq "Failed" }) {
                Write-Host "    - $($test.Name): $($test.ErrorRecord.Exception.Message)" -ForegroundColor Red
            }
        }
        
        Write-Host ""
        
        # Fail fast if requested and there are failures
        if ($FailFast -and $result.FailedCount -gt 0) {
            Write-Host "Stopping execution due to test failures (FailFast enabled)" -ForegroundColor Red
            break
        }
    }
    catch {
        Write-Host "Error running $suite tests: $($_.Exception.Message)" -ForegroundColor Red
        $suiteStopwatch.Stop()
        
        $suiteResult = @{
            Name = $suite
            TotalCount = 0
            PassedCount = 0
            FailedCount = 1
            SkippedCount = 0
            Duration = $suiteStopwatch.Elapsed
            Result = "Error"
            Error = $_.Exception.Message
        }
        
        $totalResults.TestSuites += $suiteResult
        $totalResults.FailedTests += 1
    }
}

$overallStopwatch.Stop()
$totalResults.Duration = $overallStopwatch.Elapsed
$totalResults.OverallResult = if ($totalResults.FailedTests -eq 0) { "Passed" } else { "Failed" }

# Display overall results
Write-Host "=== Overall Test Results ===" -ForegroundColor Cyan
$resultColor = if ($totalResults.OverallResult -eq "Passed") { "Green" } else { "Red" }
Write-Host "Status: " -NoNewline
Write-Host $totalResults.OverallResult -ForegroundColor $resultColor
Write-Host "Total Tests: $($totalResults.TotalTests)"
Write-Host "Passed: $($totalResults.PassedTests)" -ForegroundColor Green
Write-Host "Failed: $($totalResults.FailedTests)" -ForegroundColor Red
Write-Host "Skipped: $($totalResults.SkippedTests)" -ForegroundColor Yellow
Write-Host "Total Duration: $($totalResults.Duration.TotalSeconds.ToString('F2'))s"
Write-Host ""

# Generate summary report if requested
if ($GenerateReport) {
    $summaryPath = Join-Path $OutputDirectory "TestSummary.json"
    $totalResults | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryPath -Encoding UTF8
    
    Write-Host "Test reports generated:" -ForegroundColor Green
    Write-Host "  Summary: $summaryPath"
    foreach ($suite in $totalResults.TestSuites) {
        if ($suite.Name -ne "Error") {
            $reportPath = Join-Path $OutputDirectory "$($suite.Name)-TestResults.xml"
            if (Test-Path $reportPath) {
                Write-Host "  $($suite.Name): $reportPath"
            }
        }
    }
    Write-Host ""
}

# Set exit code based on results
if ($totalResults.OverallResult -eq "Failed") {
    Write-Host "Some tests failed. Check the output above for details." -ForegroundColor Red
    exit 1
} else {
    Write-Host "All tests passed successfully!" -ForegroundColor Green
    exit 0
}
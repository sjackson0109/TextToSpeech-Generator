# TextToSpeech Generator v3.2 - Main Application Launcher
# PowerShell 5.1 Compatible Version

param(
    [string]$ConfigProfile = "Development",
    [switch]$RunTests,
    [switch]$GenerateReport,
    [switch]$EnablePerformanceMonitoring = $true,
    [switch]$EnableSecureStorage = $true,
    [switch]$TestMode,
    [switch]$DryRun,
    [switch]$Verbose,
    [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
    [string]$LogLevel = "INFO",
    [string]$ConfigPath,
    [switch]$ValidateOnly,
    [switch]$ShowHelp
)

$ErrorActionPreference = "Continue"

function Show-ApplicationHelp {
    Write-Host @"
TextToSpeech Generator v3.2 - Command Line Reference

USAGE:
  .\StartTTS.ps1 [OPTIONS]

OPTIONS:
  -ConfigProfile <string>     Configuration profile (Development, Production, Testing)
  -RunTests                   Run test suites during initialization
  -GenerateReport            Generate detailed test reports
  -TestMode                  Run in test mode only (validate system)
  -DryRun                    Validate configuration without API calls
  -ValidateOnly              Only validate configuration
  -LogLevel <string>         Set logging level (DEBUG, INFO, WARNING, ERROR)
  -ConfigPath <string>       Path to configuration file
  -EnablePerformanceMonitoring   Enable performance monitoring
  -EnableSecureStorage           Enable secure credential storage
  -Verbose                   Enable verbose output
  -ShowHelp                  Show this help message

EXAMPLES:
  .\StartTTS.ps1
  .\StartTTS.ps1 -ConfigProfile "Production" -RunTests
  .\StartTTS.ps1 -ValidateOnly -LogLevel "DEBUG"
  
"@ -ForegroundColor White
}

# Show help if requested
if ($ShowHelp) {
    Show-ApplicationHelp
    exit 0
}

# Set verbose preference
if ($Verbose) {
    $VerbosePreference = "Continue"
}

Write-Host "=== TextToSpeech Generator v3.2 ===" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "DRY RUN MODE - No API calls will be made" -ForegroundColor Yellow
}
if ($ValidateOnly) {
    Write-Host "VALIDATION ONLY - System validation check" -ForegroundColor Yellow
}
Write-Host "Initializing modular system..." -ForegroundColor Gray

try {
    # Import all modules with error handling
    Write-Host "Loading modules..." -ForegroundColor Yellow
    
    $ModulesToLoad = @(
    "Modules\Logging\EnhancedLogging.psm1",
    "Modules\Security\EnhancedSecurity.psm1", 
    "Modules\Configuration\AdvancedConfiguration.psm1",
    "Modules\Configuration\ConfigurationValidator.psm1",
    "Modules\TTS\AllProviders.psm1",
    "Modules\Utilities\UtilityFunctions.psm1",
    "Modules\ErrorRecovery\ErrorRecovery.psm1",
    "Modules\ErrorRecovery\StandardErrorHandling.psm1"
    )
    
    foreach ($Module in $ModulesToLoad) {
        try {
            $modulePath = Join-Path $PSScriptRoot $Module
            if (Test-Path $modulePath) {
                Import-Module $modulePath -Force -ErrorAction Stop
                Write-Host "  OK $Module" -ForegroundColor Green
            }
            else {
                Write-Warning "  MISSING $Module - Check file path: $modulePath"
                Write-ApplicationLog -Message "Module not found: $modulePath" -Level "WARNING"
            }
        }
        catch {
            Write-Warning "  FAILED $Module : $($_.Exception.Message)"
            Write-ApplicationLog -Message "Failed to load $Module : $($_.Exception.Message)" -Level "ERROR"
        }
    }
    
    if ($EnablePerformanceMonitoring) {
        $perfModule = Join-Path $PSScriptRoot "Modules\PerformanceMonitoring\PerformanceMonitoring.psm1"
        if (Test-Path $perfModule) {
            Import-Module $perfModule -Force -ErrorAction SilentlyContinue
        }
    }
    
    Write-Host "All modules loaded" -ForegroundColor Green
    
    # Initialize systems
    Write-Host "Initializing systems..." -ForegroundColor Yellow
    
    $logPath = Join-Path $PSScriptRoot "application.log"
    Initialize-LoggingSystem -LogPath $logPath -Level $LogLevel -MaxSizeMB 10 -MaxFiles 5
    Write-ApplicationLog -Message "TextToSpeech Generator v3.2 starting" -Level "INFO"
    
    if ($EnableSecureStorage) {
        Initialize-SecuritySystem -EnableSecureStorage $true
        Write-ApplicationLog -Message "Security system initialized" -Level "INFO"
    }
    
    $configPath = if ($ConfigPath) { $ConfigPath } else { Join-Path $PSScriptRoot "config.json" }
    $configManager = New-AdvancedConfigurationManager -ConfigPath $configPath
    Write-ApplicationLog -Message "Configuration manager initialized" -Level "INFO"
    $configManager.SetCurrentProfile($ConfigProfile)
    Write-ApplicationLog -Message "Configuration profile: $ConfigProfile" -Level "INFO"
    
    if ($EnablePerformanceMonitoring) {
        try {
            Start-OperationMonitoring -OperationName "ApplicationStartup"
            Write-ApplicationLog -Message "Performance monitoring enabled" -Level "INFO"
        }
        catch {
            Write-ApplicationLog -Message "Performance monitoring unavailable" -Level "WARNING"
        }
    }
    
    Write-Host "All systems initialized" -ForegroundColor Green
    
    # Test system requirements
    Write-Host "Testing system requirements..." -ForegroundColor Yellow
    $requirements = Test-SystemRequirements
    
    if ($requirements.OverallStatus) {
        Write-Host "System requirements met" -ForegroundColor Green
    }
    else {
        Write-Host "Some requirements not optimal:" -ForegroundColor Yellow
        foreach ($req in $requirements.GetEnumerator()) {
            if ($req.Value -is [hashtable] -and -not $req.Value.Met) {
                Write-Host "  - $($req.Key): Required $($req.Value.Required), Current $($req.Value.Current)" -ForegroundColor Yellow
            }
        }
    }
    
    # Test TTS providers
    Write-Host "Testing TTS providers..." -ForegroundColor Yellow
    
    # Check if the function is available
    if (Get-Command Test-TTSProviderCapabilities -ErrorAction SilentlyContinue) {
        $providerCapabilities = Test-TTSProviderCapabilities
        
        foreach ($provider in $providerCapabilities.Keys) {
            $status = $providerCapabilities[$provider]
            $color = if ($status.Status -eq "Available") { "Green" } else { "Red" }
            Write-Host "  $provider : " -NoNewline
            Write-Host $status.Status -ForegroundColor $color
        }
    }
    else {
        Write-Host "  TTS Provider module not loaded - provider testing skipped" -ForegroundColor Yellow
        Write-ApplicationLog -Message "TTSProviders module not available - skipping provider tests" -Level "WARNING"
        
        # Create a minimal providers list for status display
        $providerCapabilities = @{
            "Microsoft Azure" = @{ Status = "Module Missing" }
            "Google Cloud" = @{ Status = "Module Missing" }
            "AWS Polly" = @{ Status = "Module Missing" }
            "CloudPronouncer" = @{ Status = "Module Missing" }
            "Twilio" = @{ Status = "Module Missing" }
            "VoiceForge" = @{ Status = "Module Missing" }
        }
        
        foreach ($provider in $providerCapabilities.Keys) {
            Write-Host "  $provider : " -NoNewline
            Write-Host "Module Missing" -ForegroundColor Yellow
        }
    }
    
    # Run tests if requested
    if ($RunTests) {
        Write-Host "`nRunning test suite..." -ForegroundColor Yellow
        $testPath = Join-Path $PSScriptRoot "Tests\RunTests.ps1"
        if (Test-Path $testPath) {
            $testArgs = @{
                TestSuites = @("Unit", "Integration")
                GenerateReport = $GenerateReport
            }
            $testResult = & $testPath @testArgs
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "All tests passed" -ForegroundColor Green
            }
            else {
                Write-Host "Some tests failed" -ForegroundColor Red
                Write-ApplicationLog -Message "Test suite completed with failures" -Level "WARNING"
            }
        }
        else {
            Write-Host "Test runner not found - skipping tests" -ForegroundColor Yellow
        }
    }
    
    # Check security configuration
    Write-Host "Testing security configuration..." -ForegroundColor Yellow
    $securityTest = Test-SecurityConfiguration
    
    if ($securityTest.OverallStatus -eq "Pass") {
        Write-Host "Security configuration valid" -ForegroundColor Green
    }
    else {
        Write-Host "Security configuration issues detected:" -ForegroundColor Yellow
        if ($securityTest.Tests) {
            foreach ($test in $securityTest.Tests) {
                if ($test.Status -ne "Pass") {
                    Write-Host "  - $($test.Name): $($test.Status) - $($test.Details)" -ForegroundColor Yellow
                }
            }
        }
    }
    
    if ($EnablePerformanceMonitoring) {
        try {
            $startupMetrics = Stop-OperationMonitoring -OperationName "ApplicationStartup"
            $startupTime = $startupMetrics.Duration.TotalSeconds.ToString('F2')
            Write-ApplicationLog -Message "Application startup completed in ${startupTime}s" -Level "INFO"
        }
        catch {
            # Ignore if monitoring unavailable
        }
    }
    
    Write-Host "`n=== System Status Summary ===" -ForegroundColor Cyan
    Write-Host "Configuration Profile: $ConfigProfile"
    Write-Host "Logging: Enabled (Level: $LogLevel, Path: $logPath)"
    $securityStatus = if ($EnableSecureStorage) { 'Enabled with encryption' } else { 'Basic' }
    Write-Host "Security: $securityStatus"
    $perfStatus = if ($EnablePerformanceMonitoring) { 'Enabled' } else { 'Disabled' }
    Write-Host "Performance Monitoring: $perfStatus"
    Write-Host "Available Providers: $($providerCapabilities.Keys.Count)"
    Write-Host ""
    
    # Exit if validation only
    if ($ValidateOnly) {
        Write-Host "Validation complete. Exiting." -ForegroundColor Green
        exit 0
    }
    
    # Load main application UI (skip in test mode)
    if (-not $TestMode) {
        Write-Host "Loading main application..." -ForegroundColor Yellow
        
        $guiScriptPath = Join-Path $PSScriptRoot "TextToSpeech-Generator.ps1"
        if (Test-Path $guiScriptPath) {
            Add-Type -AssemblyName PresentationFramework
            Add-Type -AssemblyName System.Windows.Forms
            
            Write-ApplicationLog -Message "Loading GUI application" -Level "INFO"
            
            # Execute the GUI script
            & $guiScriptPath
            
            Write-Host "Application loaded successfully" -ForegroundColor Green
        }
        else {
            Write-Host "Main application script not found - test mode only" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Test mode - skipping main application" -ForegroundColor Green
    }
    
}
catch {
    Write-Host "Failed to initialize application: $($_.Exception.Message)" -ForegroundColor Red
    
    try {
        Write-ApplicationLog -Message "Application initialization failed: $($_.Exception.Message)" -Level "ERROR"
    }
    catch {
        Write-Host "Unable to log error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    if ($EnablePerformanceMonitoring) {
        try {
            Stop-OperationMonitoring -OperationName "ApplicationStartup"
        }
        catch {
            # Ignore cleanup errors
        }
    }
    
    exit 1
}

# Generate final report if requested
if ($GenerateReport -and $EnablePerformanceMonitoring) {
    try {
        Write-Host "`nGenerating performance report..." -ForegroundColor Yellow
        $report = Get-PerformanceReport
        $reportPath = Join-Path $PSScriptRoot "performance-report.json"
        $report | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath
        Write-Host "Performance report saved to: $reportPath" -ForegroundColor Green
        
        if ($report.OperationSummary.Count -gt 0) {
            Write-Host "`nKey Performance Metrics:" -ForegroundColor Cyan
            foreach ($op in $report.OperationSummary.Keys) {
                $summary = $report.OperationSummary[$op]
                Write-Host "  $op : Avg $($summary.AverageDurationMs)ms, Count: $($summary.Count)" -ForegroundColor Gray
            }
        }
        
        if ($report.Recommendations.Count -gt 0) {
            Write-Host "`nPerformance Recommendations:" -ForegroundColor Yellow
            foreach ($rec in $report.Recommendations) {
                Write-Host "  - $rec" -ForegroundColor Yellow
            }
        }
        
    }
    catch {
        Write-Host "Failed to generate performance report: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

try {
    Write-ApplicationLog -Message "Application session completed" -Level "INFO"
}
catch {
    # Ignore logging errors during shutdown
}

Write-Host "`n=== Application Ready ===" -ForegroundColor Green
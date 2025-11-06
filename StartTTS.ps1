# TextToSpeech Generator v3.2 - Main Application Launcher
# PowerShell 5.1 Compatible Version

param(
    [string]$ConfigProfile,
    [switch]$RunTests,
    [switch]$GenerateReport,
    [switch]$EnablePerformanceMonitoring,
    [switch]$EnableSecureStorage,
    [switch]$TestMode,
    [switch]$DryRun,
    [switch]$Verbose,
    [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR")]
    [string]$LogLevel,
    [string]$ConfigPath,
    [switch]$ValidateOnly,
    [switch]$ShowHelp
)

# Ensure script is running in STA mode for WPF GUI support
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Write-Host "ERROR: This script must be run in Single Threaded Apartment (STA) mode for GUI support. Please start PowerShell with the -STA switch." -ForegroundColor Red
    exit 1
}

# Set default values
if (-not $ConfigProfile) { $ConfigProfile = "Development" }
if (-not $LogLevel) { $LogLevel = "INFO" }
if (-not $EnablePerformanceMonitoring) { $EnablePerformanceMonitoring = $true }
if (-not $EnableSecureStorage) { $EnableSecureStorage = $true }


# Import required modules once at the top

# Import Logging module and ensure Add-ApplicationLog is available
if (Get-Command New-LoggingSystem -ErrorAction SilentlyContinue) {
    Remove-Item Function:New-LoggingSystem -ErrorAction SilentlyContinue
}
Import-Module (Resolve-Path (Join-Path $PSScriptRoot 'Modules\Logging.psm1')).Path -Force
Import-Module (Resolve-Path (Join-Path $PSScriptRoot 'Modules\Optimisation.psm1')).Path -Force

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Module = "StartTTS"
    )
    if (Get-Command Add-ApplicationLog -ErrorAction SilentlyContinue) {
        Add-ApplicationLog -Module $Module -Message $Message -Level $Level
    } else {
        Write-Host "[$Level] [$Module] $Message" -ForegroundColor Yellow
    }
}

# Initialise global optimisation objects

# Initialise global optimisation objects with approved verbs
# Initialise global optimisation objects with approved verbs
$Global:ConnectionPool = New-OptimisationConnectionPool -Provider 'Default' -MinSize 2 -MaxSize 10
$Global:AsyncManager = New-OptimisationAsyncManager -MaxConcurrency 5
Write-Log -Message "Performance optimisation module loaded." -Level "INFO"
# Example usage (can be replaced with real logic):
$exampleConn = New-OptimisationConnection -Provider 'example-conn'
Remove-OptimisationConnection $Global:ConnectionPool $exampleConn
$connCount = $Global:ConnectionPool.Available.Count + $Global:ConnectionPool.Active.Count
$conn = Get-OptimisationConnection $Global:ConnectionPool
$asyncResult = Get-OptimisationAsyncSlot $Global:AsyncManager
Write-Log -Message "ConnectionPool count: $connCount, Got: $conn, Async result: $asyncResult" -Level "DEBUG"

$ErrorActionPreference = "Continue"

function Show-ApplicationHelp {
    Write-Host @"
TextToSpeech Generator v3.2 - Command Line Reference

USAGE:
  .\StartTTS.ps1 [OPTIONS]

OPTIONS:
  -ConfigProfile <string>     Configuration profile (Development, Production, Testing)
  -RunTests                   Run test suites during initialisation
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

Add-ApplicationLog -Module "StartTTS" -Message "=== TextToSpeech Generator v3.2 ===" -Level "INFO"
Write-Log -Message "=== TextToSpeech Generator v3.2 ===" -Level "INFO"
if ($DryRun) {
    Write-Log -Message "DRY RUN MODE - No API calls will be made" -Level "WARNING"
}
if ($ValidateOnly) {
    Write-Log -Message "VALIDATION ONLY - System validation check" -Level "WARNING"
}
Write-Log -Message "Initialising modular system..." -Level "INFO"

try {
    # Import all modules with error handling
    Write-Log -Message "Loading modules..." -Level "INFO"
    
    $ModulesToLoad = @(
        "Modules\Security.psm1",
        "Modules\Performance.psm1",
        # "Modules\Optimisation.psm1", # Already imported above
        "Modules\Utilities.psm1",
        "Modules\Configuration.psm1",
        "Modules\Validator.psm1",
        "Modules\ErrorHandling.psm1",
        "Modules\ErrorRecovery.psm1",
        "Modules\CircuitBreaker.psm1",
        "Modules\Providers.psm1",
        "Modules\GUI.psm1"
    )
    
    foreach ($Module in $ModulesToLoad) {
        try {
            $modulePath = Join-Path $PSScriptRoot $Module
            if (Test-Path $modulePath) {
                Import-Module $modulePath -Force -ErrorAction Stop
                Write-Log -Message "OK $Module" -Level "INFO"
            }
            else {
                Write-Log -Message "MISSING $Module - Check file path: $modulePath" -Level "WARNING"
                Write-Log -Message "Module not found: $modulePath" -Level "WARNING"
            }
        }
        catch {
            Write-Log -Message "FAILED $Module : $($_.Exception.Message)" -Level "WARNING"
            Write-Log -Message "Failed to load $Module : $($_.Exception.Message)" -Level "ERROR"
        }
    }
    
    if ($EnablePerformanceMonitoring) {
        $perfModule = Join-Path $PSScriptRoot "Modules\PerformanceMonitoring\PerformanceMonitoring.psm1"
        if (Test-Path $perfModule) {
            Import-Module $perfModule -Force -ErrorAction SilentlyContinue
        }
    }
    
    Add-ApplicationLog -Module "StartTTS" -Message "All modules loaded" -Level "INFO"
    
    # Initialise systems
    Add-ApplicationLog -Module "StartTTS" -Message "Initialising systems..." -Level "INFO"
    

    $logPath = Join-Path $PSScriptRoot "application.log"
    if (Get-Command New-LoggingSystem -ErrorAction SilentlyContinue) {
        Remove-Item Function:New-LoggingSystem -ErrorAction SilentlyContinue
    }
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot 'Modules\Logging.psm1')).Path -Force
    $cmd = Get-Command New-LoggingSystem -ErrorAction SilentlyContinue
    if ($cmd) {
        $signature = ($cmd | Format-List * | Out-String)
        Write-Log -Message "New-LoggingSystem full signature:`n$signature" -Level "INFO"
        New-LoggingSystem -LogPath $logPath -Level $LogLevel -MaxSizeMB 10 -MaxFiles 5
    } else {
        Write-Log -Message "New-LoggingSystem function not found. Logging system initialisation skipped." -Level "ERROR"
    }
    Add-ApplicationLog -Module "StartTTS" -Message "TextToSpeech Generator v3.2 starting" -Level "INFO"
    
    if ($EnableSecureStorage) {
        Start-SecuritySystem -EnableSecureStorage $true
    Add-ApplicationLog -Module "StartTTS" -Message "Security system initialised" -Level "INFO"
    }
    
    $configPath = if ($ConfigPath) { $ConfigPath } else { Join-Path $PSScriptRoot "config.json" }
    $configManager = New-AdvancedConfigurationManager -ConfigPath $configPath
    Add-ApplicationLog -Module "StartTTS" -Message "Configuration manager initialised" -Level "INFO"
    $configManager.SetCurrentProfile($ConfigProfile)
    Add-ApplicationLog -Module "StartTTS" -Message "Configuration profile: $ConfigProfile" -Level "INFO"
    
    if ($EnablePerformanceMonitoring) {
        try {
            Start-OperationMonitoring -OperationName "ApplicationStartup"
            Add-ApplicationLog -Module "StartTTS" -Message "Performance monitoring enabled" -Level "INFO"
        }
        catch {
            Add-ApplicationLog -Module "StartTTS" -Message "Performance monitoring unavailable" -Level "WARNING"
        }
    }
    
    Add-ApplicationLog -Module "StartTTS" -Message "All systems initialised" -Level "INFO"
    
    # Test system requirements
    Add-ApplicationLog -Module "StartTTS" -Message "Testing system requirements..." -Level "INFO"
    $requirements = Test-SystemRequirements
    
    if ($requirements.OverallStatus) {
    Add-ApplicationLog -Module "StartTTS" -Message "System requirements met" -Level "INFO"
    }
    else {
    Add-ApplicationLog -Module "StartTTS" -Message "Some requirements not optimal:" -Level "WARNING"
        foreach ($req in $requirements.GetEnumerator()) {
            if ($req.Value -is [hashtable] -and -not $req.Value.Met) {
                Add-ApplicationLog -Module "StartTTS" -Message "- $($req.Key): Required $($req.Value.Required), Current $($req.Value.Current)" -Level "WARNING"
            }
        }
    }
    
    # Test TTS providers
    Add-ApplicationLog -Module "StartTTS" -Message "Testing TTS providers..." -Level "INFO"
    
    # Check if the function is available
    if (Get-Command Test-TTSProviderCapabilities -ErrorAction SilentlyContinue) {
        $providerCapabilities = Test-TTSProviderCapabilities
        
        foreach ($provider in $providerCapabilities.Keys) {
            $status = $providerCapabilities[$provider]
            $color = if ($status.Status -eq "Available") { "Green" } else { "Red" }
            Add-ApplicationLog -Module "StartTTS" -Message "$provider : $($status.Status)" -Level "INFO"
        }
    }
    else {
    Add-ApplicationLog -Module "StartTTS" -Message "TTS Provider module not loaded - provider testing skipped" -Level "WARNING"
    Add-ApplicationLog -Module "StartTTS" -Message "TTSProviders module not available - skipping provider tests" -Level "WARNING"
        
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
            Add-ApplicationLog -Module "StartTTS" -Message "$provider : Module Missing" -Level "WARNING"
        }
    }
    
    # Run tests if requested
    if ($RunTests) {
    Add-ApplicationLog -Module "StartTTS" -Message "Running test suite..." -Level "INFO"
        $testPath = Join-Path $PSScriptRoot "Tests\RunTests.ps1"
        if (Test-Path $testPath) {
            $testArgs = @{
                TestSuites = @("Unit", "Integration")
                GenerateReport = $GenerateReport
            }
            $testResult = & $testPath @testArgs
            
            if ($LASTEXITCODE -eq 0) {
                Add-ApplicationLog -Module "StartTTS" -Message "All tests passed" -Level "INFO"
            }
            else {
                Add-ApplicationLog -Module "StartTTS" -Message "Some tests failed" -Level "ERROR"
                Add-ApplicationLog -Module "StartTTS" -Message "Test suite completed with failures" -Level "WARNING"
            }
        }
        else {
            Add-ApplicationLog -Module "StartTTS" -Message "Test runner not found - skipping tests" -Level "WARNING"
        }
    }
    
    # Check security configuration
    Add-ApplicationLog -Module "StartTTS" -Message "Testing security configuration..." -Level "INFO"
    $securityTest = Test-SecurityConfiguration
    
    if ($securityTest.OverallStatus -eq "Pass") {
    Add-ApplicationLog -Module "StartTTS" -Message "Security configuration valid" -Level "INFO"
    }
    else {
    Add-ApplicationLog -Module "StartTTS" -Message "Security configuration issues detected:" -Level "WARNING"
        if ($securityTest.Tests) {
            foreach ($test in $securityTest.Tests) {
                if ($test.Status -ne "Pass") {
                    Add-ApplicationLog -Module "StartTTS" -Message "- $($test.Name): $($test.Status) - $($test.Details)" -Level "WARNING"
                }
            }
        }
    }
    
    if ($EnablePerformanceMonitoring) {
        try {
            $startupMetrics = Stop-OperationMonitoring -OperationName "ApplicationStartup"
            $startupTime = $startupMetrics.Duration.TotalSeconds.ToString('F2')
            Add-ApplicationLog -Module "StartTTS" -Message "Application startup completed in ${startupTime}s" -Level "INFO"
        }
        catch {
            # Ignore if monitoring unavailable
        }
    }
    
    Add-ApplicationLog -Module "StartTTS" -Message "=== System Status Summary ===" -Level "INFO"
    Add-ApplicationLog -Module "StartTTS" -Message "Configuration Profile: $ConfigProfile" -Level "INFO"
    Add-ApplicationLog -Module "StartTTS" -Message "Logging: Enabled (Level: $LogLevel, Path: $logPath)" -Level "INFO"
    $securityStatus = if ($EnableSecureStorage) { 'Enabled with encryption' } else { 'Basic' }
    Add-ApplicationLog -Module "StartTTS" -Message "Security: $securityStatus" -Level "INFO"
    $perfStatus = if ($EnablePerformanceMonitoring) { 'Enabled' } else { 'Disabled' }
    Add-ApplicationLog -Module "StartTTS" -Message "Performance Monitoring: $perfStatus" -Level "INFO"
    Add-ApplicationLog -Module "StartTTS" -Message "Available Providers: $($providerCapabilities.Keys.Count)" -Level "INFO"
    
    # Exit if validation only
    if ($ValidateOnly) {
    Add-ApplicationLog -Module "StartTTS" -Message "Validation complete. Exiting." -Level "INFO"
        exit 0
    }
    
    # Load main application UI (skip in test mode)
    if (-not $TestMode) {
    Add-ApplicationLog -Module "StartTTS" -Message "Loading main application..." -Level "INFO"
        
        $guiScriptPath = Join-Path $PSScriptRoot "TextToSpeech-Generator.ps1"
        if (Test-Path $guiScriptPath) {
            Add-Type -AssemblyName PresentationFramework
            Add-Type -AssemblyName System.Windows.Forms
            
            Add-ApplicationLog -Module "StartTTS" -Message "Loading GUI application" -Level "INFO"
            
            # Execute the GUI script
            & $guiScriptPath
            
            Add-ApplicationLog -Module "StartTTS" -Message "Application loaded successfully" -Level "INFO"
        }
        else {
                Write-Log -Message "Main application script not found - test mode only" -Level "WARNING"
        }
    }
    else {
        Write-Log -Message "Test mode - skipping main application" -Level "INFO"
    }
    
}
catch {
        Write-Log -Message "Failed to Initialise application: $($_.Exception.Message)" -Level "ERROR"
        try {
            Write-Log -Message "Application initialisation failed: $($_.Exception.Message)" -Level "ERROR"
        }
        catch {
            Write-Log -Message "Unable to log error: $($_.Exception.Message)" -Level "ERROR"
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
    Add-ApplicationLog -Module "StartTTS" -Message "Generating performance report..." -Level "INFO"
        $report = Get-PerformanceReport
        $reportPath = Join-Path $PSScriptRoot "performance-report.json"
        $report | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath
    Add-ApplicationLog -Module "StartTTS" -Message "Performance report saved to: $reportPath" -Level "INFO"
        
        if ($report.OperationSummary.Count -gt 0) {
            Add-ApplicationLog -Module "StartTTS" -Message "Key Performance Metrics:" -Level "INFO"
            foreach ($op in $report.OperationSummary.Keys) {
                $summary = $report.OperationSummary[$op]
                Add-ApplicationLog -Module "StartTTS" -Message "$op : Avg $($summary.AverageDurationMs)ms, Count: $($summary.Count)" -Level "INFO"
            }
        }
        
        if ($report.Recommendations.Count -gt 0) {
            Add-ApplicationLog -Module "StartTTS" -Message "Performance Recommendations:" -Level "INFO"
            foreach ($rec in $report.Recommendations) {
                Add-ApplicationLog -Module "StartTTS" -Message "- $rec" -Level "INFO"
            }
        }
        
    }
    catch {
    Add-ApplicationLog -Module "StartTTS" -Message "Failed to generate performance report: $($_.Exception.Message)" -Level "WARNING"
    }
}

try {
    Add-ApplicationLog -Module "StartTTS" -Message "Application session completed" -Level "INFO"
}
catch {
    # Ignore logging errors during shutdown
}

Write-Log -Message "=== Application Ready ===" -Level "INFO"
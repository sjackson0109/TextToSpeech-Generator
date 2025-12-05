# TextToSpeech Generator v3.2 - Main Application Launcher
# PowerShell 5.1 Compatible Version

# Suppress PSScriptAnalyzer warnings for custom verbs in CircuitBreaker module
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
param(
    [string]$ConfigProfile,
    [switch]$RunTests,
    [switch]$GenerateReport,
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
$EnablePerformanceMonitoring = $true
if (-not $EnableSecureStorage) { $EnableSecureStorage = $true }

# Suppress verb warnings for CircuitBreaker module (uses custom UK English verbs)
$WarningPreference = 'SilentlyContinue'


# Logging helper for script scope (before Logging module is available)
function Write-ApplicationLog {
    param(
        [string]$Message,
        [string]$Module = "StartTTS",
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $colour = switch ($Level) {
        "DEBUG" { "Gray" }
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "CRITICAL" { "Magenta" }
        default { "White" }
    }
    
    $output = "[$timestamp] [$Level] [$Module] $Message"
    Write-Host $output -ForegroundColor $colour
}

# Import Logging.psm1 - before any modules need it.
try {
    $loggingModulePath = (Resolve-Path (Join-Path $PSScriptRoot 'Modules\Logging.psm1')).Path
    if (Get-Module -Name Logging) {
        Remove-Module -Name Logging -Force
    }
    Import-Module $loggingModulePath -Force -Global
} catch {
    Write-Host "ERROR: Failed to import Logging.psm1 - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Import-Module (Resolve-Path (Join-Path $PSScriptRoot 'Modules\Optimisation.psm1')).Path -Force
Import-Module (Resolve-Path (Join-Path $PSScriptRoot 'Modules\Performance.psm1')).Path -Force


# Import ShowUIHelper if available
try {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot 'Modules\ShowUIHelper.psm1')).Path -ErrorAction Stop
    $ShowUIAvailable = $true
    Write-ApplicationLog -Message "ShowUIHelper module loaded successfully." -Level "INFO"
} catch {
    $ShowUIAvailable = $false
    Write-ApplicationLog -Message "ShowUIHelper module not available (ShowUI not installed). Using fallback GUI." -Level "INFO"
}

# Initialise global optimisation objects
$Global:ConnectionPool = New-OptimisationConnectionPool -Provider 'Default' -MinSize 2 -MaxSize 10
$Global:AsyncManager = New-OptimisationAsyncManager -MaxConcurrency 5
Write-ApplicationLog -Message "Performance optimisation module loaded." -Level "INFO"
# Example usage (can be replaced with real logic):
$exampleConn = New-OptimisationConnection -Provider 'example-conn'
Remove-OptimisationConnection $Global:ConnectionPool $exampleConn
$connCount = $Global:ConnectionPool.Available.Count + $Global:ConnectionPool.Active.Count
$conn = Get-OptimisationConnection $Global:ConnectionPool
$asyncResult = Get-OptimisationAsyncSlot $Global:AsyncManager
Write-ApplicationLog -Message "ConnectionPool count: $connCount, Got: $conn, Async result: $asyncResult" -Level "DEBUG"

$ErrorActionPreference = "Continue"

# Show GUI using ShowUI if available
if ($ShowUIAvailable -and -not $RunTests -and -not $ValidateOnly -and -not $ShowHelp) {
    Write-ApplicationLog -Message "Launching GUI using ShowUI..." -Level "INFO"
    $null = Show-TTSGeneratorGUI -Profile $ConfigProfile
    return
}

function Show-ApplicationHelp {
    Write-Host @"
TextToSpeech Generator - Command Line Reference

USAGE:
  .\StartTTS.ps1 [OPTIONS]

OPTIONS:
  -ConfigProfile <string>       Configuration profile (Development, Production, Testing)
  -RunTests                     Run test suites during initialisation
  -GenerateReport               Generate detailed test reports
  -TestMode                     Run in test mode only (validate system)
  -DryRun                       Validate configuration without API calls
  -ValidateOnly                 Only validate configuration
  -LogLevel <string>            Set logging level (DEBUG, INFO, WARNING, ERROR)
  -ConfigPath <string>          Path to configuration file
  -EnablePerformanceMonitoring  Enable performance monitoring
  -EnableSecureStorage          Enable secure credential storage
  -Verbose                      Enable verbose output
  -ShowHelp                     Show this help message

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

# ===========================================================================
# Start application initialisation
# ============================================================================


Write-ApplicationLog -Message "=== TextToSpeech Generator ===" -Level "INFO"
if ($DryRun) {
    Write-ApplicationLog -Message "DRY RUN MODE - No API calls will be made" -Level "WARNING"
}
if ($ValidateOnly) {
    Write-ApplicationLog -Message "VALIDATION ONLY - System validation check" -Level "WARNING"
}

try {
    # Import all modules with error handling
    Write-ApplicationLog -Message "Importing modules..." -Level "INFO"

    $ModulesPath = Join-Path $PSScriptRoot "modules"
    $ModulesToLoad = @(
        "Security.psm1", "Utilities.psm1", "Configuration.psm1", "Validator.psm1",
        "CircuitBreaker.psm1", "ErrorHandling.psm1", "ErrorRecovery.psm1", "Providers.psm1"
    )
    if ($EnablePerformanceMonitoring) {
        $ModulesToLoad += "Performance.psm1"
    }
    foreach ($Module in $ModulesToLoad) {
        try {
            $ModulePath = Join-Path $ModulesPath $Module
            $ModuleName = $($Module -Replace ".psm1", "")
            if (Test-Path $ModulePath) {
                Import-Module $ModulePath -Force -Global -ErrorAction Stop -WarningAction SilentlyContinue 3>$null
                Write-ApplicationLog -Message "Module $ModuleName loaded successfully" -Level "INFO"
            }
            else {
                Write-ApplicationLog -Message "Module file '$ModulePath' not found" -Level "WARNING"
            }
        }
        catch {
            Write-ApplicationLog -Message "Module '$ModuleName' failed: $($_.Exception.Message)" -Level "WARNING"
        }
    }

    
    # Dynamically import GUI module using clean code pattern
    $guiModuleName = "GUI.psm1"
    $guiModulePath = Join-Path $ModulesPath $guiModuleName
    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
        if (Test-Path $guiModulePath) {
            try {
                Import-Module $guiModulePath -Force -Global -ErrorAction Stop -WarningAction SilentlyContinue 3>$null
                Write-ApplicationLog -Message "Module 'GUI' loaded successfully" -Level "INFO"
            } catch {
                Write-ApplicationLog -Message "Module 'GUI' failed: $($_.Exception.Message)" -Level "WARNING"
            }
        } else {
            Write-ApplicationLog -Message "Module file '$guiModulePath' not found" -Level "WARNING"
        }
    } catch {
        Write-ApplicationLog -Message "WPF PresentationFramework assembly not available. GUI will be disabled. CLI mode only." -Level "WARNING"
    }
    
    
    Write-ApplicationLog -Message "All modules loaded" -Level "INFO"
    
    # Initialise systems
    Write-ApplicationLog -Message "Initialising systems..." -Level "INFO"
    

    # Initialise logging system properly
    $LogPath = Join-Path $PSScriptRoot "application.log"
    $LogLevel = if ($LogLevel) { $LogLevel } else { "INFO" }
    try {
        # Call New-LoggingSystem with proper named parameters
        New-LoggingSystem -LogPath $LogPath -Level $LogLevel -MaxSizeMB 10 -MaxFiles 5
        Write-ApplicationLog -Message "Logging system initialised successfully" -Level "INFO"
    } catch {
        Write-ApplicationLog -Message "Logging system already initialised - appending to existing log" -Level "INFO"
    }
    

    Write-host "Before EnableSecureStorag [$EnableSecureStorage]"
    if ($EnableSecureStorage) {
        Start-SecuritySystem -EnableSecureStorage $true
        Write-ApplicationLog -Message "Secure Storage Initialised" -Level "INFO"
    } else {
        Start-SecuritySystem -EnableSecureStorage $false
        Write-ApplicationLog -Message "Secure Storage not Initialised" -Level "INFO"
    }
    
    Write-host "Before ConfigPath"
    $configPath = if ($ConfigPath) { $ConfigPath } else { Join-Path $PSScriptRoot "config.json" }
    Write-ApplicationLog -Message "Configuration file path: $configPath" -Level "DEBUG"
    $configManager = New-AdvancedConfigurationManager -ConfigPath $configPath
    Write-ApplicationLog -Message "Configuration manager initialised" -Level "INFO"

    Write-host "Before SetCurrentProfile"
    $configManager.SetCurrentProfile($ConfigProfile)
    Write-ApplicationLog -Message "Configuration profile: $ConfigProfile" -Level "INFO"
    
    if ($EnablePerformanceMonitoring) {
        
        Write-Host "here"
        try {
            if (Get-Command Start-OperationMonitoring -ErrorAction SilentlyContinue) {
                Start-OperationMonitoring -OperationName "ApplicationStartup"
                Write-ApplicationLog -Message "Performance monitoring enabled" -Level "INFO"
            } else {
                Write-ApplicationLog -Message "Performance monitoring disabled (function not available)" -Level "INFO"
            }
        }
        catch {
            Write-ApplicationLog -Message "Performance monitoring disabled (initialisation failed)" -Level "INFO"
        }
    }
    
    Write-ApplicationLog -Message "All systems initialised" -Level "INFO"
    
    # Test system requirements
    Write-ApplicationLog -Message "Testing system requirements..." -Level "INFO"
    $requirements = Test-SystemRequirements
    
    if ($requirements.OverallStatus) {
    Write-ApplicationLog -Message "System requirements met" -Level "INFO"
    }
    else {
    Write-ApplicationLog -Message "Some requirements not optimal:" -Level "WARNING"
        foreach ($req in $requirements.GetEnumerator()) {
            if ($req.Value -is [hashtable] -and -not $req.Value.Met) {
                Write-ApplicationLog -Message "- $($req.Key): Required $($req.Value.Required), Current $($req.Value.Current)" -Level "WARNING"
            }
        }
    }
    
    # Test TTS providers
    Write-ApplicationLog -Message "Testing TTS providers..." -Level "INFO"
    
    # Check if the function is available
    if (Get-Command Test-TTSProviderCapabilities -ErrorAction SilentlyContinue) {
        $providerCapabilities = Test-TTSProviderCapabilities
        
        foreach ($provider in $providerCapabilities.Keys) {
            $status = $providerCapabilities[$provider]
            $colour = if ($status.Status -eq "Available") { "Green" } else { "Red" }
            Write-ApplicationLog -Message "$provider : $($status.Status)" -Level "INFO"
        }
    }
    else {
    Write-ApplicationLog -Message "TTS Provider module not loaded - provider testing skipped" -Level "WARNING"

        # Use Providers.psm1 to get available providers for capability reporting
        if (Get-Command Get-AvailableProviders -ErrorAction SilentlyContinue) {
            $providerList = Get-AvailableProviders
            $providerCapabilities = @{}
            foreach ($providerName in $providerList) {
                $providerCapabilities[$providerName] = @{ Status = "Module Missing" }
            }
        } else {
            Write-ApplicationLog -Message "Get-AvailableProviders function not found in Providers.psm1." -Level "WARNING"
            $providerCapabilities = @{}
        }
    if ($providerCapabilities.Count -eq 0) {
        Write-ApplicationLog -Message "No provider modules found in ./providers/ directory." -Level "WARNING"
    }
    foreach ($provider in $providerCapabilities.Keys) {
        Write-ApplicationLog -Message "$provider : Module Missing" -Level "WARNING"
    }
    }
    
    # Run tests if requested
    if ($RunTests) {
    Write-ApplicationLog -Message "Running test suite..." -Level "INFO"
        $testPath = Join-Path $PSScriptRoot "Tests\RunTests.ps1"
        if (Test-Path $testPath) {
            $testArgs = @{
                TestSuites = @("Unit", "Integration")
                GenerateReport = $GenerateReport
            }
            $testResult = & $testPath @testArgs
            
            if ($LASTEXITCODE -eq 0) {
                Write-ApplicationLog -Message "All tests passed" -Level "INFO"
            }
            else {
                Write-ApplicationLog -Message "Some tests failed" -Level "ERROR"
                Write-ApplicationLog -Message "Test suite completed with failures" -Level "WARNING"
            }
        }
        else {
            Write-ApplicationLog -Message "Test runner not found - skipping tests" -Level "WARNING"
        }
    }
    
    # Check security configuration
    Write-ApplicationLog -Message "Testing security configuration..." -Level "INFO"
    $securityTest = Test-SecurityConfiguration
    
    if ($securityTest.OverallStatus -eq "Pass") {
    Write-ApplicationLog -Message "Security configuration valid" -Level "INFO"
    }
    else {
        Write-ApplicationLog -Message "Security configuration issues detected:" -Level "WARNING"
        if ($securityTest.Tests) {
            foreach ($test in $securityTest.Tests) {
                if ($test.Status -ne "Pass") {
                    Write-ApplicationLog -Message "- $($test.Name): $($test.Status) - $($test.Details)" -Level "WARNING"
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
    
    Write-ApplicationLog -Message "=== System Status Summary ===" -Level "INFO"
    Write-ApplicationLog -Message "Configuration Profile: $ConfigProfile" -Level "INFO"
    Write-ApplicationLog -Message "Logging: Enabled (Level: $LogLevel, Path: $LogPath)" -Level "INFO"
    $securityStatus = if ($EnableSecureStorage) { 'Enabled with encryption' } else { 'Basic' }
    Write-ApplicationLog -Message "Security: $securityStatus" -Level "INFO"
    $perfStatus = if ($EnablePerformanceMonitoring) { 'Enabled' } else { 'Disabled' }
    Write-ApplicationLog -Message "Performance Monitoring: $perfStatus" -Level "INFO"
    Write-ApplicationLog -Message "Available Providers: $($providerCapabilities.Keys.Count)" -Level "INFO"
    
    # Exit if validation only
    if ($ValidateOnly) {
    Write-ApplicationLog -Message "Validation complete. Exiting." -Level "INFO"
        exit 0
    }
    

    # Load main application UI (skip in test mode)
    if (-not $TestMode) {
        Write-ApplicationLog -Message "Loading main application..." -Level "INFO"

        # Get provider names from Get-AvailableProviders
        $providerNames = @()
        if (Get-Command Get-AvailableProviders -ErrorAction SilentlyContinue) {
            $providerTable = Get-AvailableProviders
            $providerNames = $providerTable | Select-Object -ExpandProperty Name
            Write-ApplicationLog -Message "Passing provider names to GUI: $($providerNames -join ', ')" -Level "DEBUG"
        } else {
            Write-ApplicationLog -Message "Get-AvailableProviders function not found. Provider list will be empty." -Level "WARNING"
        }

        # Incorporate main GUI launch logic directly
        $guiModulePath = Join-Path $PSScriptRoot 'modules/GUI.psm1'
        $wpfAvailable = $false
        if (Test-Path $guiModulePath) {
            try {
                Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
                $wpfAvailable = $true
            } catch {
                Write-ApplicationLog -Message "WPF PresentationFramework assembly not available. GUI will be disabled. CLI mode only." -Level "WARNING"
            }
            if ($wpfAvailable) {
                try {
                    Import-Module $guiModulePath -Force -ErrorAction Stop
                    Write-ApplicationLog -Message "Creating GUI instance..." -Level "INFO"
                    $gui = New-GUI -Profile "Default"

                    # Show the GUI and keep the application alive
                    if ($gui -ne $null) {
                        Write-ApplicationLog -Message "GUI object created, checking Window property..." -Level "INFO"
                        if ($gui.Window -ne $null) {
                            Write-ApplicationLog -Message "GUI.Window type: $($gui.Window.GetType().FullName)" -Level "DEBUG"
                        } else {
                            Write-ApplicationLog -Message "GUI.Window is null - XAML conversion failed" -Level "ERROR"
                        }
                        if ($gui.Window) {
                            Write-ApplicationLog -Message "Bringing GUI window into focus" -Level "INFO"
                            $gui.Window.Topmost = $true
                        } else {
                            Write-ApplicationLog -Message "GUI window creation failed - Window property is null" -Level "ERROR"
                        }
                    } else {
                        Write-ApplicationLog -Message "GUI creation failed - New-GUI returned null" -Level "ERROR"
                    }
                } catch {
                    Write-ApplicationLog -Message "Main GUI launch failed: $($_.Exception.Message)" -Level "ERROR"
                }
            } else {
                Write-ApplicationLog -Message "GUI module present but WPF unavailable. Running in CLI mode only." -Level "WARNING"
            }
        } else {
            Write-ApplicationLog -Message "GUI module not found. Running in CLI mode only." -Level "WARNING"
        }
    } else {
        Write-ApplicationLog -Message "Test mode - skipping main application" -Level "INFO"
    }
    
}
catch {
    Write-ApplicationLog -Message "Failed to Initialise application: $($_.Exception.Message)" -Level "ERROR"
    if ($EnablePerformanceMonitoring) {
        try {
            Stop-OperationMonitoring -OperationName "ApplicationStartup"
            Write-ApplicationLog -Message "Application OperationMonitoring Stopping" -Level "INFO"
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
        Write-ApplicationLog -Message "Generating performance report..." -Level "INFO"
        $report = Get-PerformanceReport
        $reportPath = Join-Path $PSScriptRoot "performance-report.json"
        $report | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath
        Write-ApplicationLog -Message "Performance report saved to: $($reportPath)" -Level "INFO"
        
        if ($report.OperationSummary.Count -gt 0) {
            Write-ApplicationLog -Message "Key Performance Metrics:" -Level "INFO"
            foreach ($op in $report.OperationSummary.Keys) {
                $summary = $report.OperationSummary[$op]
                Write-ApplicationLog -Message "$op : Avg $($summary.AverageDurationMs)ms, Count: $($summary.Count)" -Level "INFO"
            }
        }
        
        if ($report.Recommendations.Count -gt 0) {
            Write-ApplicationLog -Message "Performance Recommendations:" -Level "INFO"
            foreach ($rec in $report.Recommendations) {
                Write-ApplicationLog -Message "- $rec" -Level "INFO"
            }
        }
        
    }
    catch {
    Write-ApplicationLog -Message "Failed to generate performance report: $($_.Exception.Message)" -Level "WARNING"
    }
}

try {
    Write-ApplicationLog -Message "Application session completed" -Level "INFO"
}
catch {
    # Ignore logging errors during shutdown
}

Write-ApplicationLog -Message "=== Application Ready ===" -Level "INFO"
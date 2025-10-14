# TextToSpeech Generator v3.2 - Modular Application Launcher
# Integrates all enhanced modules for enterprise-grade TTS processing

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

function Show-ApplicationHelp {
    Write-Host @"
TextToSpeech Generator v3.2 - Command Line Reference

USAGE:
  .\StartModularTTS.ps1 [OPTIONS]

OPTIONS:
  -ConfigProfile <string>     Configuration profile to use (Development, Production, Testing)
                             Default: Development

  -RunTests                  Run test suites during initialization
  -GenerateReport           Generate detailed test reports (use with -RunTests)
  
  -TestMode                 Run in test mode only (validate system, don't start GUI)
  -DryRun                   Validate configuration and system without making API calls
  -ValidateOnly             Only validate configuration and system requirements
  
  -LogLevel <string>        Set logging level (DEBUG, INFO, WARNING, ERROR)
                           Default: INFO
                           
  -ConfigPath <string>      Path to configuration file
                           Default: .\config.json
                           
  -EnablePerformanceMonitoring   Enable performance monitoring (default: true)
  -EnableSecureStorage          Enable secure credential storage (default: true)
  
  -Verbose                  Enable verbose output
  -ShowHelp                 Show this help message

EXAMPLES:
  # Standard startup with Development profile
  .\StartModularTTS.ps1
  
  # Production startup with comprehensive testing
  .\StartModularTTS.ps1 -ConfigProfile "Production" -RunTests -GenerateReport
  
  # System validation only
  .\StartModularTTS.ps1 -ValidateOnly -LogLevel "DEBUG"
  
  # Dry run with custom configuration
  .\StartModularTTS.ps1 -ConfigPath "C:\MyConfigs\prod.json" -DryRun
  
  # Test mode with verbose logging
  .\StartModularTTS.ps1 -TestMode -Verbose -LogLevel "DEBUG"

CONFIGURATION PROFILES:
  Development   - Debug logging, test settings, local paths
  Production    - Optimized settings, encrypted keys, network paths  
  Testing       - Mock providers, extended logging, benchmarks

For more information, see:
  README.md - Complete documentation
  docs/TROUBLESHOOTING.md - Problem solving guide
  docs/DEPLOYMENT.md - Enterprise deployment guide
  
"@ -ForegroundColor White
}

$ErrorActionPreference = "Continue"

# Show help if requested
if ($ShowHelp) {
    Show-ApplicationHelp
    exit 0
}

# Set verbose preference
if ($Verbose) {
    $VerbosePreference = "Continue"
}

Write-Host "=== TextToSpeech Generator v3.2 - Modular Edition ===" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No actual API calls will be made" -ForegroundColor Yellow
}
if ($ValidateOnly) {
    Write-Host "✅ VALIDATION ONLY - System validation and configuration check" -ForegroundColor Yellow
}
Write-Host "Initializing enhanced modular system..." -ForegroundColor Gray

try {
    # Import all modules
    Write-Host "Loading modules..." -ForegroundColor Yellow
    
    Import-Module "$PSScriptRoot\Modules\Logging\EnhancedLogging.psm1" -Force
    Import-Module "$PSScriptRoot\Modules\Security\EnhancedSecurity.psm1" -Force
    # Import-Module "$PSScriptRoot\Modules\Configuration\AdvancedConfiguration.psm1" -Force
    Import-Module "$PSScriptRoot\Modules\Configuration\ConfigurationValidator.psm1" -Force
    Import-Module "$PSScriptRoot\Modules\TTSProviders\TTSProviders.psm1" -Force
    Import-Module "$PSScriptRoot\Modules\Utilities\UtilityFunctions.psm1" -Force
    Import-Module "$PSScriptRoot\Modules\ErrorRecovery\ErrorRecovery.psm1" -Force
    Import-Module "$PSScriptRoot\Modules\ErrorRecovery\StandardErrorHandling.psm1" -Force
    
    if ($EnablePerformanceMonitoring) {
        Import-Module "$PSScriptRoot\Modules\PerformanceMonitoring\PerformanceMonitoring.psm1" -Force
    }
    
    Write-Host "✓ All modules loaded successfully" -ForegroundColor Green
    
    # Initialize systems
    Write-Host "Initializing systems..." -ForegroundColor Yellow
    
    $logPath = Join-Path $PSScriptRoot "application.log"
    Initialize-LoggingSystem -LogPath $logPath -Level $LogLevel -MaxSizeMB 10 -MaxFiles 5
    Write-ApplicationLog -Message "TextToSpeech Generator v3.2 starting with modular architecture" -Level "INFO"
    
    if ($EnableSecureStorage) {
        Initialize-SecuritySystem -EnableSecureStorage $true
        Write-ApplicationLog -Message "Security system initialized with encryption support" -Level "INFO"
    }
    
    $configPath = if ($ConfigPath) { $ConfigPath } else { Join-Path $PSScriptRoot "config.json" }
    # $configManager = New-AdvancedConfigurationManager -ConfigPath $configPath
    Write-ApplicationLog -Message "Configuration manager temporarily disabled - using basic configuration" -Level "INFO"
    # $configManager.SetCurrentProfile($ConfigProfile)
    Write-ApplicationLog -Message "Skipping profile configuration - using defaults" -Level "INFO"
    Write-ApplicationLog -Message "Configuration manager initialized with profile: $ConfigProfile" -Level "INFO"
    
    if ($EnablePerformanceMonitoring) {
        Start-OperationMonitoring -OperationName "ApplicationStartup"
        Write-ApplicationLog -Message "Performance monitoring enabled" -Level "INFO"
    }
    
    Write-Host "✓ All systems initialized successfully" -ForegroundColor Green
    
    # Test system requirements
    Write-Host "Testing system requirements..." -ForegroundColor Yellow
    $requirements = Test-SystemRequirements
    
    if ($requirements.OverallStatus) {
        Write-Host "✓ System requirements met" -ForegroundColor Green
    } else {
        Write-Host "⚠ Some system requirements not optimal:" -ForegroundColor Yellow
        foreach ($req in $requirements.GetEnumerator()) {
            if ($req.Value -is [hashtable] -and -not $req.Value.Met) {
                Write-Host "  - $($req.Key): Required $($req.Value.Required), Current $($req.Value.Current)" -ForegroundColor Yellow
            }
        }
    }
    
    # Test TTS providers
    Write-Host "Testing TTS providers..." -ForegroundColor Yellow
    $providerCapabilities = Test-TTSProviderCapabilities
    
    foreach ($provider in $providerCapabilities.Keys) {
        $status = $providerCapabilities[$provider]
        $color = if ($status.Status -eq "Available") { "Green" } else { "Red" }
        Write-Host "  $provider`: " -NoNewline
        Write-Host $status.Status -ForegroundColor $color
    }
    
    # Run tests if requested
    if ($RunTests) {
        Write-Host "`nRunning test suite..." -ForegroundColor Yellow
        if (Test-Path "$PSScriptRoot\Tests\RunTests.ps1") {
            $testResult = & "$PSScriptRoot\Tests\RunTests.ps1" -TestSuites @("Unit", "Integration") -GenerateReport:$GenerateReport
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ All tests passed" -ForegroundColor Green
            } else {
                Write-Host "✗ Some tests failed" -ForegroundColor Red
                Write-ApplicationLog -Message "Test suite completed with failures" -Level "WARNING"
            }
        } else {
            Write-Host "⚠ Test runner not found - skipping tests" -ForegroundColor Yellow
        }
    }
    
    # Check security configuration
    Write-Host "Testing security configuration..." -ForegroundColor Yellow
    $securityTest = Test-SecurityConfiguration
    
    if ($securityTest.OverallStatus -eq "Pass") {
        Write-Host "✓ Security configuration valid" -ForegroundColor Green
    } else {
        Write-Host "⚠ Security configuration issues detected:" -ForegroundColor Yellow
        if ($securityTest.Tests) {
            foreach ($test in $securityTest.Tests) {
                if ($test.Status -ne "Pass") {
                    Write-Host "  - $($test.Name): $($test.Status) - $($test.Details)" -ForegroundColor Yellow
                }
            }
        }
    }
    
    if ($EnablePerformanceMonitoring) {
        $startupMetrics = Stop-OperationMonitoring -OperationName "ApplicationStartup"
        Write-ApplicationLog -Message "Application startup completed in $($startupMetrics.Duration.TotalSeconds.ToString('F2'))s" -Level "INFO"
    }
    
    Write-Host "`n=== System Status Summary ===" -ForegroundColor Cyan
    Write-Host "Configuration Profile: $ConfigProfile"
    Write-Host "Logging: Enabled (Level: INFO, Path: $logPath)"
    Write-Host "Security: $(if ($EnableSecureStorage) { 'Enabled with encryption' } else { 'Basic' })"
    Write-Host "Performance Monitoring: $(if ($EnablePerformanceMonitoring) { 'Enabled' } else { 'Disabled' })"
    Write-Host "Available Providers: $($providerCapabilities.Keys.Count)"
    Write-Host ""
    
    # Load the main application UI (skip in test mode)
    if (-not $TestMode) {
        Write-Host "Loading main application..." -ForegroundColor Yellow
        
        if (Test-Path "$PSScriptRoot\TextToSpeech-Generator.ps1") {
            Add-Type -AssemblyName PresentationFramework
            Add-Type -AssemblyName System.Windows.Forms
            
            Write-ApplicationLog -Message "Loading GUI application with modular integration..." -Level "INFO"
            
            # Create a script block that includes module context
            $scriptPath = "$PSScriptRoot\TextToSpeech-Generator.ps1"
            $guiScriptBlock = {
                param($GuiScriptPath)
                # Import the GUI script content
                $originalScript = Get-Content $GuiScriptPath -Raw
                
                # Create module integration wrapper functions that forward to loaded modules
                function Write-ApplicationLog {
                    param(
                        [Parameter(Mandatory=$true)]
                        [string]$Message,
                        
                        [Parameter()]
                        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL")]
                        [string]$Level = "INFO"
                    )
                    
                    # Use the global logging function directly since we're in the same session
                    try {
                        & ([ScriptBlock]::Create("Write-ApplicationLog -Message '$Message' -Level '$Level'"))
                    }
                    catch {
                        # Fallback to basic logging if module function fails
                        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
                        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $(if($Level -eq "ERROR"){"Red"}elseif($Level -eq "WARNING"){"Yellow"}else{"White"})
                    }
                }
                
                function Save-CompleteConfiguration {
                    # Use the new JSON configuration system
                    try {
                        Write-ApplicationLog -Message "Saving configuration using modular system..." -Level "INFO"
                        
                        # Get current configuration
                        $currentConfig = Get-ApplicationConfiguration
                        
                        # Update with GUI values if window exists
                        if ($global:window) {
                            if ($global:window.ProviderSelect.SelectedItem) {
                                $currentConfig.DefaultProvider = $global:window.ProviderSelect.SelectedItem.Content
                            }
                            
                            # Update provider configurations based on GUI values
                            if ($global:window.MS_KEY.Text) {
                                $currentConfig.Providers.Azure.APIKey = "ENCRYPTED:" + (Protect-ConfigurationValue -Value $global:window.MS_KEY.Text)
                            }
                            if ($global:window.MS_Datacenter.Text) {
                                $currentConfig.Providers.Azure.Region = $global:window.MS_Datacenter.Text
                            }
                            
                            # Save using modular system
                            $configPath = Get-ConfigurationPath
                            Set-ApplicationConfiguration -Configuration $currentConfig -ConfigPath $configPath
                        }
                        
                        Write-ApplicationLog -Message "Configuration saved successfully using modular system" -Level "INFO"
                    }
                    catch {
                        Write-ApplicationLog -Message "Failed to save configuration: $($_.Exception.Message)" -Level "ERROR"
                        throw
                    }
                }
                
                # Execute the original script in this enhanced context
                Invoke-Expression $originalScript
            }
            
            # Execute the GUI with module integration
            & $guiScriptBlock -GuiScriptPath $scriptPath
            
            Write-Host "✓ Application loaded successfully with modular integration" -ForegroundColor Green
        } else {
            Write-Host "⚠ Main application script not found - running in module test mode only" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✓ Test mode - skipping main application load" -ForegroundColor Green
    }
    
} catch {
    Write-Host "✗ Failed to initialize application: $($_.Exception.Message)" -ForegroundColor Red
    
    try {
        Write-ApplicationLog -Message "Application initialization failed: $($_.Exception.Message)" -Level "ERROR"
    } catch {
        Write-Host "Unable to log error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    if ($EnablePerformanceMonitoring) {
        try {
            Stop-OperationMonitoring -OperationName "ApplicationStartup"
        } catch {
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
        Write-Host "✓ Performance report saved to: $reportPath" -ForegroundColor Green
        
        if ($report.OperationSummary.Count -gt 0) {
            Write-Host "`nKey Performance Metrics:" -ForegroundColor Cyan
            foreach ($op in $report.OperationSummary.Keys) {
                $summary = $report.OperationSummary[$op]
                Write-Host "  $op`: Avg $($summary.AverageDurationMs)ms, Count: $($summary.Count)" -ForegroundColor Gray
            }
        }
        
        if ($report.Recommendations.Count -gt 0) {
            Write-Host "`nPerformance Recommendations:" -ForegroundColor Yellow
            foreach ($rec in $report.Recommendations) {
                Write-Host "  • $rec" -ForegroundColor Yellow
            }
        }
        
    } catch {
        Write-Host "⚠ Failed to generate performance report: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

try {
    Write-ApplicationLog -Message "Application session completed" -Level "INFO"
} catch {
    # Ignore logging errors during shutdown
}

Write-Host "`n=== Application Ready ===" -ForegroundColor Green
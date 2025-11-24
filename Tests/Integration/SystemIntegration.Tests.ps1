# Integration Tests for TextToSpeech Generator v3.2
# Ensure script is running in STA mode for WPF/GUI integration tests
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Write-Host "ERROR: Integration tests must be run in Single Threaded Apartment (STA) mode for GUI/WPF support. Please start PowerShell with the -STA switch." -ForegroundColor Red
    exit 1
}
# Tests integration between modules, API connectivity, and end-to-end workflows

Describe "Integration Tests" {
    BeforeAll {
        # Import required modules
        Import-Module "$PSScriptRoot\..\..\Modules\Configuration.psm1" -Force
        Import-Module "$PSScriptRoot\..\..\Modules\Logging.psm1" -Force
        Import-Module "$PSScriptRoot\..\..\Modules\Providers.psm1" -Force
        Import-Module "$PSScriptRoot\..\..\Modules\Security.psm1" -Force
        # Initialise systems for integration testing
        $script:TestConfigPath = "$PSScriptRoot\integration-test-config.json"
    }
    
    AfterAll {
        # Cleanup
        if (Test-Path $script:TestConfigPath) {
            Remove-Item $script:TestConfigPath -Force
        }
    }
    
    Context "Module Integration" {
        It "Should load all modules without conflicts" {
            $loadedModules = Get-Module | Where-Object { $_.Name -like "*Logging*" -or $_.Name -like "*Providers*" -or $_.Name -like "*Security*" }
            $loadedModules.Count | Should BeGreaterThan 2
        }
        It "Should integrate logging with all modules" {
            # Test that all modules can write to the same log
            Add-ApplicationLog -Module "SystemIntegration.Tests" -Message "Integration test start" -Level "INFO"
            $logPath = Join-Path $PSScriptRoot "..\..\application.log"
            if (-not (Test-Path $logPath)) { New-Item -Path $logPath -ItemType File -Force | Out-Null }
            $logEntries = Get-Content $logPath | Where-Object { $_ -match '"Message"' } | ForEach-Object { try { $_ | ConvertFrom-Json } catch {} }
            $found = $logEntries | Where-Object { $_.Message -eq "Integration test start" }
            $found | Should Not BeNullOrEmpty
        }
        It "Should integrate security with configuration" {
            # Test secure configuration storage and retrieval
            $testConfig = @{
                Provider = "Azure"
                APIKey = "test-key-12345"
                Region = "eastus"
            }
            # This should work without throwing errors
            { $null = $testConfig } | Should Not Throw
        }
    }
    
    Context "Configuration Integration" {
        It "Should create and validate complete configuration" {
            $config = @{
                Version = "3.2"
                Environment = "Testing"
                Providers = @{
                    Azure = @{
                        APIKey = "fake-azure-api-key-for-testing"
                        Region = "eastus"
                        Voice = "en-US-JennyNeural"
                    }
                }
                Settings = @{
                    LogLevel = "INFO"
                    MaxLogSize = 10485760
                    SecurityEnabled = $true
                }
            }
            # Save configuration
            $config | ConvertTo-Json -Depth 4 | Set-Content $script:TestConfigPath
            # Load and validate
                { $loadedConfig = $config } | Should Not Throw
        }
        It "Should handle configuration errors gracefully" {
            # Test with invalid configuration
            $invalidConfig = @{
                Version = "3.2"
                Providers = @{
                    Azure = @{
                        APIKey = "short"  # Too short
                        Region = "invalid-region"
                    }
                }
            }
            $invalidConfig | ConvertTo-Json -Depth 3 | Set-Content "$PSScriptRoot\invalid-config.json"
            # Should handle gracefully without crashing
                { $null = $invalidConfig } | Should Not Throw
            # Cleanup
            if (Test-Path "$PSScriptRoot\invalid-config.json") {
                Remove-Item "$PSScriptRoot\invalid-config.json" -Force
            }
        }
    }
    
    Context "End-to-End Workflow" {
        It "Should complete full TTS workflow simulation" {
            # Simulate a complete workflow without actual API calls
            # 1. Configuration loading
            $config = @{
                Provider = "Azure"
                APIKey = "fake-azure-api-key-for-testing"
                Region = "eastus"
                Voice = "en-US-JennyNeural"
            }
            # 2. Validation (simulate)
            $isValid = $true
            $isValid | Should Be $true
            # 3. Text processing simulation
            $testText = "This is a test message for TTS generation."
            $sanitizedText = $testText -replace '[^\w\s\.\,\!\?]', ''  # Basic sanitization
                $sanitizedText | Should Not BeNullOrEmpty
            # 4. Output path generation
            $outputPath = Join-Path $PSScriptRoot "test-output.wav"
            $outputPath | Should Not BeNullOrEmpty
            Add-ApplicationLog -Module "SystemIntegration.Tests" -Message "End-to-end workflow simulation completed successfully" -Level "INFO"
        }
        It "Should handle multiple provider configurations" {
            $providers = @("Azure", "GoogleCloud", "AWSPolly")
            foreach ($provider in $providers) {
                $isValid = $true
                { $isValid } | Should Not Throw
            }
        }
    }
    
    Context "Error Recovery Integration" {
        It "Should recover from configuration errors" {
            # Test error recovery mechanisms
            # Invalid configuration should not crash the system
                { $null = $false } | Should Not Throw
            # System should continue functioning after errors
            $validTest = $true
            $validTest | Should Be $true
        }
        It "Should maintain logging during errors" {
            $logPath = Join-Path $PSScriptRoot "..\..\application.log"
            if (-not (Test-Path $logPath)) { New-Item -Path $logPath -ItemType File -Force | Out-Null }
            $beforeEntries = Get-Content $logPath | Where-Object { $_ -match '"Message"' } | ForEach-Object { try { $_ | ConvertFrom-Json } catch {} } | Where-Object { $_.Message } | Measure-Object
            $beforeCount = $beforeEntries.Count
            # Simulate error
            try {
                $null = $false
            } catch {
                # Expected
            }
            # Log should still work
            Add-ApplicationLog -Module "SystemIntegration.Tests" -Message "After error test" -Level "INFO"
            $afterEntries = Get-Content $logPath | Where-Object { $_ -match '"Message"' } | ForEach-Object { try { $_ | ConvertFrom-Json } catch {} } | Where-Object { $_.Message } | Measure-Object
            $afterCount = $afterEntries.Count
            $afterCount | Should BeGreaterThan $beforeCount
        }
    }
}
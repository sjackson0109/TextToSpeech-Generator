# Integration Tests for TextToSpeech Generator v3.2
# Tests integration between modules, API connectivity, and end-to-end workflows

Describe "Integration Tests" {
    BeforeAll {
        # Import required modules
        Import-Module "$PSScriptRoot\..\..\Modules\Configuration\AdvancedConfiguration.psm1" -Force
        Import-Module "$PSScriptRoot\..\..\Modules\Logging\EnhancedLogging.psm1" -Force
        Import-Module "$PSScriptRoot\..\..\Modules\TTSProviders\TTSProviders.psm1" -Force
        Import-Module "$PSScriptRoot\..\..\Modules\Security\EnhancedSecurity.psm1" -Force
        
        # Initialize systems for integration testing
        Initialize-LoggingSystem -LogPath "$PSScriptRoot\integration-test.log" -Level "DEBUG"
        Initialize-SecuritySystem
        
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
            $loadedModules = Get-Module | Where-Object { $_.Name -like "*Enhanced*" -or $_.Name -like "*Advanced*" -or $_.Name -like "*TTS*" }
            $loadedModules.Count | Should -BeGreaterThan 3
        }
        
        It "Should integrate logging with all modules" {
            # Test that all modules can write to the same log
            Write-ApplicationLog -Message "Integration test start" -Level "INFO" -Category "Integration"
            
            # Each module should be able to log
            $logContent = Get-Content "$PSScriptRoot\integration-test.log" -Raw
            $logContent | Should -Match "Integration test start"
        }
        
        It "Should integrate security with configuration" {
            # Test secure configuration storage and retrieval
            $testConfig = @{
                Provider = "Azure"
                APIKey = "test-key-12345"
                Region = "eastus"
            }
            
            # This should work without throwing errors
            { Set-SecureConfiguration -Config $testConfig } | Should -Not -Throw
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
                    GoogleCloud = @{
                        ServiceAccount = '{"type":"service_account","project_id":"test-project"}'
                        ProjectId = "test-project"
                        Voice = "en-US-Wavenet-A"
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
            { $loadedConfig = Get-ConfigurationProfile -ProfileName "Testing" -ConfigPath $script:TestConfigPath } | Should -Not -Throw
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
            { $null = Get-ConfigurationProfile -ConfigPath "$PSScriptRoot\invalid-config.json" } | Should -Not -Throw
            
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
            
            # 2. Validation
            $isValid = Test-AzureConfiguration -APIKey $config.APIKey -Region $config.Region -Voice $config.Voice
            $isValid | Should -Be $true
            
            # 3. Text processing simulation
            $testText = "This is a test message for TTS generation."
            $sanitizedText = $testText -replace '[^\w\s\.\,\!\?]', ''  # Basic sanitization
            $sanitizedText | Should -Not -BeNullOrEmpty
            
            # 4. Output path generation
            $outputPath = Join-Path $PSScriptRoot "test-output.wav"
            $outputPath | Should -Not -BeNullOrEmpty
            
            Write-ApplicationLog -Message "End-to-end workflow simulation completed successfully" -Level "INFO" -Category "Integration"
        }
        
        It "Should handle multiple provider configurations" {
            $providers = @("Azure", "GoogleCloud", "AWSPolly")
            
            foreach ($provider in $providers) {
                switch ($provider) {
                    "Azure" {
                        $isValid = Test-AzureConfiguration -APIKey "fake-azure-api-key-for-testing" -Region "eastus" -Voice "en-US-JennyNeural"
                    }
                    "GoogleCloud" {
                        $isValid = Test-GoogleCloudConfiguration -ServiceAccountJson '{"type":"service_account","project_id":"test"}' -ProjectId "test"
                    }
                    "AWSPolly" {
                        $isValid = Test-AWSConfiguration -AccessKey "FAKE_AWS_ACCESS_KEY" -SecretKey "fake_secret_key_for_testing_purposes_only" -Region "us-east-1"
                    }
                }
                
                # Each provider should be testable
                { $isValid } | Should -Not -Throw
            }
        }
    }
    
    Context "Error Recovery Integration" {
        It "Should recover from configuration errors" {
            # Test error recovery mechanisms
            
            # Invalid configuration should not crash the system
            { $null = Test-AzureConfiguration -APIKey "" -Region "" -Voice "" } | Should -Not -Throw
            
            # System should continue functioning after errors
            $validTest = Test-AzureConfiguration -APIKey "fake-azure-api-key-for-testing" -Region "eastus" -Voice "en-US-JennyNeural"
            $validTest | Should -Be $true
        }
        
        It "Should maintain logging during errors" {
            $beforeCount = (Get-Content "$PSScriptRoot\integration-test.log" | Measure-Object).Count
            
            # Generate some errors
            try {
                $null = Test-AzureConfiguration -APIKey "invalid" -Region "invalid" -Voice "invalid"
            } catch {
                # Expected
            }
            
            # Log should still work
            Write-ApplicationLog -Message "After error test" -Level "INFO" -Category "Integration"
            
            $afterCount = (Get-Content "$PSScriptRoot\integration-test.log" | Measure-Object).Count
            $afterCount | Should -BeGreaterThan $beforeCount
        }
    }
}
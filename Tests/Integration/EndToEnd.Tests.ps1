# Integration Tests for TextToSpeech Generator
# Tests end-to-end functionality with real API calls (mocked for safety)

Describe "TTS Integration Tests" {
    BeforeAll {
        # Import all modules
        Import-Module "$PSScriptRoot\..\..\Modules\TTSProviders\TTSProviders.psm1" -Force
        Import-Module "$PSScriptRoot\..\..\Modules\Configuration\AdvancedConfiguration.psm1" -Force
        Import-Module "$PSScriptRoot\..\..\Modules\Logging\EnhancedLogging.psm1" -Force
        Import-Module "$PSScriptRoot\..\..\Modules\Security\EnhancedSecurity.psm1" -Force
        
        # Initialize systems
        Initialize-LoggingSystem -LogPath "$PSScriptRoot\integration-test.log" -Level "DEBUG"
        Initialize-SecuritySystem -EnableSecureStorage $true
        
        # Test configuration
        $script:TestOutputDir = "$PSScriptRoot\output"
        if (-not (Test-Path $script:TestOutputDir)) {
            New-Item -ItemType Directory -Path $script:TestOutputDir -Force | Out-Null
        }
    }
    
    AfterAll {
        # Cleanup
        if (Test-Path $script:TestOutputDir) {
            Remove-Item $script:TestOutputDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        Get-ChildItem "$PSScriptRoot" -Filter "*test*" | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    
    Context "Module Integration" {
        It "Should load all modules successfully" {
            { Get-TTSProvider -ProviderName "Microsoft Azure" } | Should -Not -Throw
            { New-AdvancedConfigurationManager -ConfigPath "$PSScriptRoot\test.json" } | Should -Not -Throw
            { Test-SecurityConfiguration } | Should -Not -Throw
        }
        
        It "Should integrate logging across modules" {
            Write-ApplicationLog -Message "Integration test message" -Level "INFO"
            $stats = Get-LogStatistics
            $stats.LogFilePath | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Configuration and Security Integration" {
        It "Should create secure configuration with encryption" {
            $configPath = "$PSScriptRoot\secure-integration-test.json"
            $secureManager = New-SecureConfigurationManager -ConfigPath $configPath
            $configManager = New-AdvancedConfigurationManager -ConfigPath $configPath
            
            # Create configuration with sensitive data
            $config = @{
                APIKey = "test-secret-key-123"
                Region = "eastus"
                Voice = "en-US-JennyNeural"
            }
            
            { $secureManager.SaveSecureConfiguration($config) } | Should -Not -Throw
            
            # Verify file exists and is encrypted
            Test-Path $configPath | Should -Be $true
            $content = Get-Content $configPath -Raw
            $content | Should -Not -Match "test-secret-key-123" # Should be encrypted
        }
        
        It "Should validate configuration through providers" {
            $azureProvider = Get-TTSProvider -ProviderName "Microsoft Azure"
            $config = @{
                APIKey = "12345678901234567890123456789012"
                Region = "eastus"
                Voice = "en-US-JennyNeural"
            }
            
            $providerValidation = $azureProvider.ValidateConfiguration($config)
            $moduleValidation = Test-ConfigurationValid -Provider "Microsoft Azure" -Configuration $config
            
            $providerValidation | Should -Be $true
            $moduleValidation.IsValid | Should -Be $true
        }
    }
    
    Context "TTS Provider Integration" {
        It "Should handle provider switching seamlessly" {
            $azureProvider = Get-TTSProvider -ProviderName "Microsoft Azure"
            $googleProvider = Get-TTSProvider -ProviderName "Google Cloud"
            
            $azureProvider.Name | Should -Be "Microsoft Azure"
            $googleProvider.Name | Should -Be "Google Cloud"
            
            # Both should have different capabilities
            $azureCaps = $azureProvider.GetCapabilities()
            $googleCaps = $googleProvider.GetCapabilities()
            
            $azureCaps.SupportsNeuralVoices | Should -Be $true
            $googleCaps.SupportsWaveNet | Should -Be $true
        }
        
        It "Should provide comprehensive provider status" {
            $capabilities = Test-TTSProviderCapabilities
            
            $capabilities.Keys.Count | Should -BeGreaterThan 0
            foreach ($provider in $capabilities.Keys) {
                $capabilities[$provider].Status | Should -BeIn @("Available", "Error")
                $capabilities[$provider] | Should -HaveProperty "Capabilities"
            }
        }
    }
}

Describe "API Connectivity Integration" {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\..\Modules\Configuration\AdvancedConfiguration.psm1" -Force
    }
    
    Context "Mock API Testing" {
        It "Should handle API connectivity testing gracefully" {
            # Test with invalid configuration (should fail gracefully)
            $invalidConfig = @{
                APIKey = "invalid-key"
                Region = "invalid-region"
            }
            
            $result = Test-APIConnectivity -Provider "Microsoft Azure" -Configuration $invalidConfig
            $result.IsConnected | Should -Be $false
            $result.ErrorMessage | Should -Not -BeNullOrEmpty
            $result.Recommendations.Count | Should -BeGreaterThan 0
        }
        
        It "Should provide meaningful error messages" {
            $emptyConfig = @{}
            
            $validationResult = Test-ConfigurationValid -Provider "Microsoft Azure" -Configuration $emptyConfig
            $validationResult.IsValid | Should -Be $false
            $validationResult.Errors.Count | Should -BeGreaterThan 0
            $validationResult.Errors[0] | Should -Match "required"
        }
    }
}
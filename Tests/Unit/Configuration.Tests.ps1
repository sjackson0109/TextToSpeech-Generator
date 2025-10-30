# Unit Tests for Configuration Module
# Tests configuration validation, profiles, and templates

Describe "Configuration Module Tests" {
    BeforeAll {
        # Import required modules
        Import-Module "$PSScriptRoot\..\..\Modules\Configuration\AdvancedConfiguration.psm1" -Force
        Import-Module "$PSScriptRoot\..\..\Modules\Logging\EnhancedLogging.psm1" -Force
        
        # Initialise logging for tests
        Initialise-LoggingSystem -LogPath "$PSScriptRoot\config-test.log" -Level "DEBUG"
        
        # Create test configuration file path
        $script:TestConfigPath = "$PSScriptRoot\test-config.json"
    }
    
    AfterAll {
        # Cleanup test files
        if (Test-Path $script:TestConfigPath) {
            Remove-Item $script:TestConfigPath -Force
        }
        if (Test-Path "$PSScriptRoot\config-test.log") {
            Remove-Item "$PSScriptRoot\config-test.log" -Force
        }
    }
    
    Context "Configuration Validation" {
        It "Should validate Azure configuration successfully" {
            $config = @{
                APIKey = "fake-azure-api-key-for-testing"
                Region = "eastus"
                Voice = "en-US-JennyNeural"
            }
            
            $result = Test-AzureConfiguration -APIKey $config.APIKey -Region $config.Region -Voice $config.Voice
            $result | Should -Be $true
        }
        
        It "Should reject invalid Azure API key" {
            $result = Test-AzureConfiguration -APIKey "short" -Region "eastus" -Voice "en-US-JennyNeural"
            $result | Should -Be $false
        }
        
        It "Should reject invalid Azure region" {
            $result = Test-AzureConfiguration -APIKey "fake-azure-api-key-for-testing" -Region "invalid-region" -Voice "en-US-JennyNeural"
            $result | Should -Be $false
        }
        
        It "Should validate Google Cloud configuration" {
            $serviceAccount = @{
                type = "service_account"
                project_id = "test-project"
                private_key_id = "key123"
                private_key = "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC1234567890\n-----END PRIVATE KEY-----"
                client_email = "test@test-project.iam.gserviceaccount.com"
                client_id = "123456789012345678901"
            }
            
            $result = Test-GoogleCloudConfiguration -ServiceAccountJson ($serviceAccount | ConvertTo-Json) -ProjectId "test-project"
            $result | Should -Be $true
        }
        
        It "Should validate AWS configuration" {
            $result = Test-AWSConfiguration -AccessKey "FAKE_AWS_ACCESS_KEY" -SecretKey "fake_secret_key_for_testing_purposes_only" -Region "us-east-1"
            $result | Should -Be $true
        }
        
        It "Should reject invalid AWS access key" {
            $result = Test-AWSConfiguration -AccessKey "short" -SecretKey "fake_secret_key_for_testing_purposes_only" -Region "us-east-1"
            $result | Should -Be $false
        }
    }
    
    Context "Configuration Profiles" {
        It "Should create development profile" {
            $profile = New-ConfigurationProfile -ProfileName "Development" -LogLevel "DEBUG" -SecurityEnabled $false
            $profile | Should -Not -BeNullOrEmpty
            $profile.Environment | Should -Be "Development"
            $profile.Settings.LogLevel | Should -Be "DEBUG"
        }
        
        It "Should create production profile" {
            $profile = New-ConfigurationProfile -ProfileName "Production" -LogLevel "INFO" -SecurityEnabled $true
            $profile | Should -Not -BeNullOrEmpty
            $profile.Environment | Should -Be "Production"
            $profile.Settings.LogLevel | Should -Be "INFO"
            $profile.Settings.SecurityEnabled | Should -Be $true
        }
        
        It "Should save and load configuration profile" {
            $originalProfile = New-ConfigurationProfile -ProfileName "Testing" -LogLevel "INFO" -SecurityEnabled $true
            
            # Save profile
            $originalProfile | ConvertTo-Json -Depth 4 | Set-Content $script:TestConfigPath
            
            # Load profile
            $loadedProfile = Get-ConfigurationProfile -ProfileName "Testing" -ConfigPath $script:TestConfigPath
            $loadedProfile | Should -Not -BeNullOrEmpty
            $loadedProfile.Environment | Should -Be $originalProfile.Environment
        }
    }
    
    Context "Configuration Templates" {
        It "Should generate Azure template" {
            $template = Get-ProviderTemplate -Provider "Azure"
            $template | Should -Not -BeNullOrEmpty
            $template.Provider | Should -Be "Azure"
            $template.Settings | Should -Not -BeNullOrEmpty
        }
        
        It "Should generate Google Cloud template" {
            $template = Get-ProviderTemplate -Provider "GoogleCloud"
            $template | Should -Not -BeNullOrEmpty
            $template.Provider | Should -Be "GoogleCloud"
        }
        
        It "Should generate AWS template" {
            $template = Get-ProviderTemplate -Provider "AWS"
            $template | Should -Not -BeNullOrEmpty
            $template.Provider | Should -Be "AWS"
        }
    }
    
    Context "Configuration Security" {
        It "Should handle secure configuration storage" {
            $secureConfig = @{
                Provider = "Azure"
                APIKey = "sensitive-api-key"
                Region = "eastus"
            }
            
            # Should not throw when storing secure configuration
            { Set-SecureConfiguration -Config $secureConfig } | Should -Not -Throw
        }
        
        It "Should validate configuration schema" {
            $config = @{
                Version = "3.2"
                Environment = "Testing"
                Providers = @{
                    Azure = @{
                        APIKey = "test-key"
                        Region = "eastus"
                    }
                }
                Settings = @{
                    LogLevel = "INFO"
                }
            }
            
            $isValid = Test-ConfigurationSchema -Config $config
            $isValid | Should -Be $true
        }
        
        It "Should reject invalid configuration schema" {
            $invalidConfig = @{
                # Missing required fields
                InvalidField = "invalid"
            }
            
            $isValid = Test-ConfigurationSchema -Config $invalidConfig
            $isValid | Should -Be $false
        }
    }
    
    Context "Configuration Error Handling" {
        It "Should handle missing configuration files gracefully" {
            $nonExistentPath = "$PSScriptRoot\non-existent-config.json"
            { $null = Get-ConfigurationProfile -ConfigPath $nonExistentPath } | Should -Not -Throw
        }
        
        It "Should handle corrupted configuration files" {
            $corruptedConfigPath = "$PSScriptRoot\corrupted-config.json"
            "{ invalid json" | Set-Content $corruptedConfigPath
            
            { $null = Get-ConfigurationProfile -ConfigPath $corruptedConfigPath } | Should -Not -Throw
            
            # Cleanup
            Remove-Item $corruptedConfigPath -Force
        }
        
        It "Should provide helpful error messages" {
            $result = Test-AzureConfiguration -APIKey "" -Region "" -Voice ""
            $result | Should -Be $false
            
            # Should log appropriate error messages
            $logContent = Get-Content "$PSScriptRoot\config-test.log" -Raw -ErrorAction SilentlyContinue
            if ($logContent) {
                $logContent | Should -Match "validation|error"
            }
        }
    }
}
# Unit Tests for Configuration Module
# Tests configuration validation, profiles, and templates

Describe "Configuration Module Tests" {
    BeforeAll {
        # Import required modules
        Import-Module "$PSScriptRoot\..\..\Modules\Configuration\AdvancedConfiguration.psm1" -Force
        Import-Module "$PSScriptRoot\..\..\Modules\Logging\EnhancedLogging.psm1" -Force
        
        # Initialize logging for tests
        Initialize-LoggingSystem -LogPath "$PSScriptRoot\config-test.log" -Level "DEBUG"
        
        # Create test configuration file path
        $script:TestConfigPath = "$PSScriptRoot\test-config.json"
    }
    
    AfterAll {
        # Cleanup test files
        if (Test-Path $script:TestConfigPath) {
            Remove-Item $script:TestConfigPath -Force
        }
    }
    
    Context "Configuration Validation" {
        It "Should validate Azure configuration successfully" {
            $config = @{
                APIKey = "12345678901234567890123456789012"
                Region = "eastus"
                Voice = "en-US-JennyNeural"
            }
            
            $result = Test-ConfigurationValid -Provider "Microsoft Azure" -Configuration $config
            $result.IsValid | Should -Be $true
            $result.Errors.Count | Should -Be 0
        }
        
        It "Should detect missing Azure API key" {
            $config = @{
                Region = "eastus"
                Voice = "en-US-JennyNeural"
            }
            
            $result = Test-ConfigurationValid -Provider "Microsoft Azure" -Configuration $config
            $result.IsValid | Should -Be $false
            $result.Errors | Should -Contain "Azure API Key is required"
        }
        
        It "Should validate Google Cloud configuration successfully" {
            $config = @{
                APIKey = "AIzaSyABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
                Voice = "en-US-Wavenet-F"
            }
            
            $result = Test-ConfigurationValid -Provider "Google Cloud" -Configuration $config
            $result.IsValid | Should -Be $true
            $result.Errors.Count | Should -Be 0
        }
        
        It "Should detect placeholder API keys" {
            $config = @{
                APIKey = "your-api-key-here"
                Region = "eastus"
            }
            
            $result = Test-ConfigurationValid -Provider "Microsoft Azure" -Configuration $config
            $result.IsValid | Should -Be $false
            $result.Errors | Should -Contain "Azure API Key is still set to placeholder value"
        }
        
        It "Should provide recommendations for warnings" {
            $config = @{
                APIKey = "invalid-format-key"
                Region = "eastus"
                Voice = "en-US-JennyNeural"
            }
            
            $result = Test-ConfigurationValid -Provider "Microsoft Azure" -Configuration $config
            $result.Recommendations.Count | Should -BeGreaterThan 0
        }
    }
    
    Context "Configuration Profiles" {
        It "Should return available profiles" {
            $profiles = Get-ConfigurationProfiles
            $profiles.Keys | Should -Contain "Development"
            $profiles.Keys | Should -Contain "Production"
            $profiles.Keys | Should -Contain "Testing"
        }
        
        It "Should create advanced configuration manager" {
            $manager = New-AdvancedConfigurationManager -ConfigPath $script:TestConfigPath
            $manager | Should -Not -BeNullOrEmpty
        }
        
        It "Should get profile configuration" {
            $manager = New-AdvancedConfigurationManager -ConfigPath $script:TestConfigPath
            $devConfig = $manager.GetProfileConfiguration("Development")
            
            $devConfig.LogLevel | Should -Be "DEBUG"
            $devConfig.RetryCount | Should -Be 2
            $devConfig.EnableDetailedLogging | Should -Be $true
        }
        
        It "Should switch profiles" {
            $manager = New-AdvancedConfigurationManager -ConfigPath $script:TestConfigPath
            $manager.SetCurrentProfile("Production")
            $manager.CurrentProfile | Should -Be "Production"
            
            $prodConfig = $manager.GetProfileConfiguration("Production")
            $prodConfig.LogLevel | Should -Be "INFO"
            $prodConfig.RetryCount | Should -Be 5
        }
        
        It "Should handle invalid profile gracefully" {
            $manager = New-AdvancedConfigurationManager -ConfigPath $script:TestConfigPath
            { $manager.SetCurrentProfile("InvalidProfile") } | Should -Throw
        }
    }
    
    Context "Configuration Templates" {
        It "Should return available templates" {
            $templates = Get-ConfigurationTemplates
            $templates.Keys | Should -Contain "AzureBasic"
            $templates.Keys | Should -Contain "GoogleCloudBasic"
        }
        
        It "Should get template configuration" {
            $manager = New-AdvancedConfigurationManager -ConfigPath $script:TestConfigPath
            $azureTemplate = $manager.GetTemplate("AzureBasic")
            
            $azureTemplate.Region | Should -Be "eastus"
            $azureTemplate.Voice | Should -Be "en-US-JennyNeural"
        }
        
        It "Should handle missing template gracefully" {
            $manager = New-AdvancedConfigurationManager -ConfigPath $script:TestConfigPath
            $result = $manager.GetTemplate("NonExistentTemplate")
            $result | Should -Be @{}
        }
    }
    
    Context "Configuration Persistence" {
        It "Should save and load configuration" {
            $manager = New-AdvancedConfigurationManager -ConfigPath $script:TestConfigPath
            $manager.SetCurrentProfile("Production")
            $manager.SaveConfiguration()
            
            # Create new instance to test loading
            $manager2 = New-AdvancedConfigurationManager -ConfigPath $script:TestConfigPath
            $manager2.CurrentProfile | Should -Be "Production"
        }
        
        It "Should validate configuration schema" {
            $validConfig = @{
                Version = "3.2"
                CurrentProfile = "Development"
                Providers = @{}
            }
            
            $manager = New-AdvancedConfigurationManager -ConfigPath $script:TestConfigPath
            $validation = $manager.ValidateSchema($validConfig)
            $validation.IsValid | Should -Be $true
        }
        
        It "Should detect schema violations" {
            $invalidConfig = @{
                Version = "3.2"
                # Missing required fields
            }
            
            $manager = New-AdvancedConfigurationManager -ConfigPath $script:TestConfigPath
            $validation = $manager.ValidateSchema($invalidConfig)
            $validation.IsValid | Should -Be $false
            $validation.Errors.Count | Should -BeGreaterThan 0
        }
    }
    
    Context "Configuration Migration" {
        It "Should migrate configuration between versions" {
            $oldConfig = @{
                Version = "3.0"
                CurrentProfile = "Development"
                Providers = @{}
            }
            
            $manager = New-AdvancedConfigurationManager -ConfigPath $script:TestConfigPath
            $migratedConfig = $manager.MigrateConfiguration($oldConfig, "3.0", "3.2")
            
            $migratedConfig.Version | Should -Be "3.2"
            $migratedConfig.MigrationDate | Should -Not -BeNullOrEmpty
            $migratedConfig.SecuritySettings | Should -Not -BeNullOrEmpty
        }
    }
}
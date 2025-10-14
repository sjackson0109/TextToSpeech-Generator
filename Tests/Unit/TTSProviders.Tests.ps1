# Unit Tests for TTS Providers Module
# Uses Pester testing framework for comprehensive validation

Describe "TTS Providers Module Tests" {
    BeforeAll {
        # Import required modules
        Import-Module "$PSScriptRoot\..\..\Modules\TTSProviders\TTSProviders.psm1" -Force
        Import-Module "$PSScriptRoot\..\..\Modules\Logging\EnhancedLogging.psm1" -Force
        
        # Initialize logging for tests
        Initialize-LoggingSystem -LogPath "$PSScriptRoot\test.log" -Level "DEBUG"
    }
    
    Context "Azure TTS Provider" {
        BeforeEach {
            $provider = Get-TTSProvider -ProviderName "Microsoft Azure"
        }
        
        It "Should create Azure TTS provider instance" {
            $provider | Should -Not -BeNullOrEmpty
            $provider.Name | Should -Be "Microsoft Azure"
        }
        
        It "Should validate valid Azure configuration" {
            $config = @{
                APIKey = "12345678901234567890123456789012"
                Region = "eastus"
                Voice = "en-US-JennyNeural"
            }
            
            $result = $provider.ValidateConfiguration($config)
            $result | Should -Be $true
        }
        
        It "Should reject invalid Azure API key format" {
            $config = @{
                APIKey = "invalid-key"
                Region = "eastus"
                Voice = "en-US-JennyNeural"
            }
            
            $result = $provider.ValidateConfiguration($config)
            $result | Should -Be $false
        }
        
        It "Should reject empty Azure configuration" {
            $config = @{}
            
            $result = $provider.ValidateConfiguration($config)
            $result | Should -Be $false
        }
        
        It "Should return available voices" {
            $voices = $provider.GetAvailableVoices()
            $voices | Should -Not -BeNullOrEmpty
            $voices.Count | Should -BeGreaterThan 0
        }
        
        It "Should have correct capabilities" {
            $capabilities = $provider.GetCapabilities()
            $capabilities.MaxTextLength | Should -Be 5000
            $capabilities.SupportsSSML | Should -Be $true
            $capabilities.SupportsNeuralVoices | Should -Be $true
        }
    }
    
    Context "Google Cloud TTS Provider" {
        BeforeEach {
            $provider = Get-TTSProvider -ProviderName "Google Cloud"
        }
        
        It "Should create Google Cloud TTS provider instance" {
            $provider | Should -Not -BeNullOrEmpty
            $provider.Name | Should -Be "Google Cloud"
        }
        
        It "Should validate valid Google Cloud configuration" {
            $config = @{
                APIKey = "AIzaSyABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
                Voice = "en-US-Wavenet-F"
            }
            
            $result = $provider.ValidateConfiguration($config)
            $result | Should -Be $true
        }
        
        It "Should reject invalid Google Cloud API key format" {
            $config = @{
                APIKey = "invalid-google-key"
                Voice = "en-US-Wavenet-F"
            }
            
            $result = $provider.ValidateConfiguration($config)
            $result | Should -Be $false
        }
    }
    
    Context "Error Handling" {
        It "Should handle unknown provider gracefully" {
            { Get-TTSProvider -ProviderName "NonExistentProvider" } | Should -Throw
        }
        
        It "Should provide detailed error information" {
            $exception = [System.Net.WebException]::new("Test exception")
            $errorInfo = Get-DetailedErrorInfo -Exception $exception -Provider "Azure"
            
            $errorInfo.ErrorCode | Should -Not -BeNullOrEmpty
            $errorInfo.UserMessage | Should -Not -BeNullOrEmpty
            $errorInfo.Provider | Should -Be "Azure"
        }
    }
    
    Context "Provider Capabilities Test" {
        It "Should test all provider capabilities" {
            $results = Test-TTSProviderCapabilities
            
            $results.Keys | Should -Contain "Microsoft Azure"
            $results.Keys | Should -Contain "Google Cloud"
            $results.Keys | Should -Contain "AWS Polly"
            
            foreach ($provider in $results.Keys) {
                $results[$provider].Status | Should -BeIn @("Available", "Error")
            }
        }
    }
}

Describe "API Retry Logic Tests" {
    Context "Retry Mechanism" {
        It "Should retry on transient failures" {
            $attemptCount = 0
            $scriptBlock = {
                $script:attemptCount++
                if ($script:attemptCount -lt 3) {
                    throw [System.Net.WebException]::new("Transient error")
                }
                return "Success"
            }
            
            $result = Invoke-APIWithRetry -ScriptBlock $scriptBlock -MaxRetries 3 -BaseDelayMs 10 -Provider "Test"
            $result | Should -Be "Success"
            $attemptCount | Should -Be 3
        }
        
        It "Should fail after max retries exceeded" {
            $scriptBlock = {
                throw [System.Net.WebException]::new("Persistent error")
            }
            
            { Invoke-APIWithRetry -ScriptBlock $scriptBlock -MaxRetries 2 -BaseDelayMs 10 -Provider "Test" } | Should -Throw
        }
    }
}
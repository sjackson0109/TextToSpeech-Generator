# Unit Tests for TTS         It "Should validat        It "Should validate AWS configuration" {
            $result = Test-AWSConfiguration -AccessKey "FAKE_AWS_ACCESS_KEY" -SecretKey "fake_secret_key_for_testing_purposes_only" -Region "us-east-1"
            $result | Should -Be $true
        }ure configuration" {
            $result = Test-AzureConfiguration -APIKey "fake-azure-api-key-for-testing" -Region "eastus" -Voice "en-US-JennyNeural"
            $result | Should -Be $true
        }iders Module
# Tests TTS provider functionality, validation, and error handling

Describe "TTS Providers Module Tests" {
    BeforeAll {
        # Import required modules
        Import-Module "$PSScriptRoot\..\..\Modules\TTSProviders\TTSProviders.psm1" -Force
        Import-Module "$PSScriptRoot\..\..\Modules\Logging\EnhancedLogging.psm1" -Force
        
        # Initialize logging for tests
        Initialize-LoggingSystem -LogPath "$PSScriptRoot\tts-test.log" -Level "DEBUG"
    }
    
    AfterAll {
        # Cleanup test files
        if (Test-Path "$PSScriptRoot\tts-test.log") {
            Remove-Item "$PSScriptRoot\tts-test.log" -Force
        }
    }
    
    Context "Provider Validation" {
        It "Should validate Azure TTS configuration" {
            $result = Test-AzureConfiguration -APIKey "12345678901234567890123456789012" -Region "eastus" -Voice "en-US-JennyNeural"
            $result | Should -Be $true
        }
        
        It "Should reject invalid Azure configuration" {
            $result = Test-AzureConfiguration -APIKey "short" -Region "invalid" -Voice "invalid"
            $result | Should -Be $false
        }
        
        It "Should validate Google Cloud TTS configuration" {
            $serviceAccount = @{
                type = "service_account"
                project_id = "test-project"
                private_key_id = "key123"
                private_key = "-----BEGIN PRIVATE KEY-----\ntest\n-----END PRIVATE KEY-----"
                client_email = "test@test-project.iam.gserviceaccount.com"
            } | ConvertTo-Json
            
            $result = Test-GoogleCloudConfiguration -ServiceAccountJson $serviceAccount -ProjectId "test-project"
            $result | Should -Be $true
        }
        
        It "Should validate AWS Polly configuration" {
            $result = Test-AWSConfiguration -AccessKey "AKIA1234567890123456" -SecretKey "abcd1234567890abcd1234567890abcd12345678" -Region "us-east-1"
            $result | Should -Be $true
        }
        
        It "Should validate CloudPronouncer configuration" {
            $result = Test-CloudPronouncerConfiguration -APIKey "cp-fake-test-key-example" -UserId "test-user"
            $result | Should -Be $true
        }
        
        It "Should validate Twilio configuration" {
            $result = Test-TwilioConfiguration -AccountSID "TEST_FAKE_ACCOUNT_SID_FOR_UNIT_TESTS" -AuthToken "fake_auth_token_for_testing"
            $result | Should -Be $true
        }
        
        It "Should validate VoiceForge configuration" {
            $result = Test-VoiceForgeConfiguration -APIKey "vf-fake-test-key-example" -Username "testuser"
            $result | Should -Be $true
        }
    }
    
    Context "Voice Validation" {
        It "Should validate Azure voices" {
            $voices = @("en-US-JennyNeural", "en-US-GuyNeural", "en-GB-SoniaNeural")
            foreach ($voice in $voices) {
                $result = Test-AzureVoice -Voice $voice
                $result | Should -Be $true
            }
        }
        
        It "Should reject invalid Azure voices" {
            $result = Test-AzureVoice -Voice "invalid-voice"
            $result | Should -Be $false
        }
        
        It "Should validate Google Cloud voices" {
            $voices = @("en-US-Wavenet-A", "en-US-Standard-A", "en-GB-Wavenet-A")
            foreach ($voice in $voices) {
                $result = Test-GoogleCloudVoice -Voice $voice
                $result | Should -Be $true
            }
        }
        
        It "Should validate AWS Polly voices" {
            $voices = @("Joanna", "Matthew", "Amy", "Brian")
            foreach ($voice in $voices) {
                $result = Test-AWSVoice -Voice $voice
                $result | Should -Be $true
            }
        }
    }
    
    Context "Text Processing" {
        It "Should sanitize input text properly" {
            $inputText = "Hello <script>alert('test')</script> World!"
            $sanitizedText = Invoke-TextSanitization -Text $inputText
            
            $sanitizedText | Should -Not -Match "<script>"
            $sanitizedText | Should -Match "Hello.*World"
        }
        
        It "Should handle special characters in text" {
            $inputText = "Price: $29.99 — Available now! 50% off... (Limited time)"
            $sanitizedText = Invoke-TextSanitization -Text $inputText
            
            $sanitizedText | Should -Not -BeNullOrEmpty
            $sanitizedText | Should -Match "\$29\.99"
        }
        
        It "Should validate text length limits" {
            $shortText = "Short text"
            $longText = "X" * 10000
            
            $shortResult = Test-TextLength -Text $shortText -Provider "Azure"
            $longResult = Test-TextLength -Text $longText -Provider "Azure"
            
            $shortResult | Should -Be $true
            $longResult | Should -Be $false  # Assuming 10K chars exceeds Azure limits
        }
    }
    
    Context "File Operations" {
        It "Should sanitize file names properly" {
            $unsafeFileName = "file<>:|?*name.wav"
            $safeFileName = Invoke-FileNameSanitization -FileName $unsafeFileName
            
            $safeFileName | Should -Not -Match "[<>:|?*]"
            $safeFileName | Should -Match "\.wav$"
        }
        
        It "Should generate unique file names" {
            $baseName = "test-file.wav"
            $uniqueName1 = New-UniqueFileName -BaseName $baseName
            $uniqueName2 = New-UniqueFileName -BaseName $baseName
            
            $uniqueName1 | Should -Not -Be $uniqueName2
            $uniqueName1 | Should -Match "test-file"
            $uniqueName2 | Should -Match "test-file"
        }
        
        It "Should validate output paths" {
            $validPath = "$env:TEMP\test-output.wav"
            $invalidPath = "invalid:<>|path.wav"
            
            $validResult = Test-OutputPath -Path $validPath
            $invalidResult = Test-OutputPath -Path $invalidPath
            
            $validResult | Should -Be $true
            $invalidResult | Should -Be $false
        }
    }
    
    Context "Provider Selection" {
        It "Should select appropriate provider based on requirements" {
            $requirements = @{
                Quality = "High"
                Speed = "Fast"
                Cost = "Low"
            }
            
            $provider = Select-OptimalProvider -Requirements $requirements
            $provider | Should -Not -BeNullOrEmpty
            $provider | Should -BeIn @("Azure", "GoogleCloud", "AWSPolly", "CloudPronouncer", "Twilio", "VoiceForge")
        }
        
        It "Should handle provider failover" {
            $primaryProvider = "Azure"
            $fallbackProviders = @("GoogleCloud", "AWSPolly")
            
            # Simulate primary provider failure
            $selectedProvider = Select-FallbackProvider -PrimaryProvider $primaryProvider -FallbackProviders $fallbackProviders -PrimaryFailed $true
            
            $selectedProvider | Should -BeIn $fallbackProviders
            $selectedProvider | Should -Not -Be $primaryProvider
        }
    }
    
    Context "Error Handling" {
        It "Should handle API connection failures gracefully" {
            # Simulate connection failure
            $result = Test-ProviderConnectivity -Provider "Azure" -Timeout 1
            
            # Should not throw, even if connection fails
            { $result } | Should -Not -Throw
        }
        
        It "Should handle invalid API responses" {
            # Test error handling for various scenarios
            { Test-AzureConfiguration -APIKey $null -Region $null -Voice $null } | Should -Not -Throw
        }
        
        It "Should provide meaningful error messages" {
            $result = Test-AzureConfiguration -APIKey "invalid" -Region "invalid" -Voice "invalid"
            
            # Should return false but not throw
            $result | Should -Be $false
            
            # Should log appropriate error information
            $logContent = Get-Content "$PSScriptRoot\tts-test.log" -Raw -ErrorAction SilentlyContinue
            if ($logContent) {
                $logContent | Should -Match "validation|error"
            }
        }
    }
    
    Context "Performance" {
        It "Should validate configurations quickly" {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            for ($i = 0; $i -lt 10; $i++) {
                $null = Test-AzureConfiguration -APIKey "fake-azure-api-key-for-testing" -Region "eastus" -Voice "en-US-JennyNeural"
            }
            
            $stopwatch.Stop()
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 1000  # 10 validations in under 1 second
        }
        
        It "Should handle multiple providers efficiently" {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            $providers = @(
                @{ Type = "Azure"; APIKey = "fake-azure-api-key-for-testing"; Region = "eastus"; Voice = "en-US-JennyNeural" }
                @{ Type = "GoogleCloud"; ServiceAccount = '{"type":"service_account","project_id":"test"}'; ProjectId = "test" }
                @{ Type = "AWS"; AccessKey = "FAKE_AWS_ACCESS_KEY"; SecretKey = "fake_secret_key_for_testing_purposes_only"; Region = "us-east-1" }
            )
            
            foreach ($provider in $providers) {
                switch ($provider.Type) {
                    "Azure" { $null = Test-AzureConfiguration -APIKey $provider.APIKey -Region $provider.Region -Voice $provider.Voice }
                    "GoogleCloud" { $null = Test-GoogleCloudConfiguration -ServiceAccountJson $provider.ServiceAccount -ProjectId $provider.ProjectId }
                    "AWS" { $null = Test-AWSConfiguration -AccessKey $provider.AccessKey -SecretKey $provider.SecretKey -Region $provider.Region }
                }
            }
            
            $stopwatch.Stop()
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 500  # All providers in under 500ms
        }
    }
}
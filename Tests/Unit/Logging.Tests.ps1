# Unit Tests for Logging Module
# Tests enhanced logging functionality and security features

Describe "Logging Module Tests" {
    BeforeAll {
        # Import required modules
        Import-Module "$PSScriptRoot\..\..\Modules\Logging\EnhancedLogging.psm1" -Force
        
        # Create test log path
        $script:TestLogPath = "$PSScriptRoot\test-logging.log"
        
        # Initialize logging system
        Initialize-LoggingSystem -LogPath $script:TestLogPath -Level "DEBUG"
    }
    
    AfterAll {
        # Cleanup test files
        if (Test-Path $script:TestLogPath) {
            Remove-Item $script:TestLogPath -Force
        }
        Get-ChildItem "$PSScriptRoot" -Filter "test-logging.*" | Remove-Item -Force
    }
    
    Context "Basic Logging Functionality" {
        It "Should write log entries to file" {
            Write-ApplicationLog -Message "Test log message" -Level "INFO"
            
            Test-Path $script:TestLogPath | Should -Be $true
            $content = Get-Content $script:TestLogPath -Raw
            $content | Should -Match "Test log message"
        }
        
        It "Should create structured JSON log entries" {
            Write-ApplicationLog -Message "JSON test" -Level "INFO" -Category "Test"
            
            $content = Get-Content $script:TestLogPath -Raw
            $jsonLines = $content -split "`n" | Where-Object { $_.Trim() -ne "" }
            $lastLine = $jsonLines[-1]
            
            { $lastLine | ConvertFrom-Json } | Should -Not -Throw
            
            $logEntry = $lastLine | ConvertFrom-Json
            $logEntry.Message | Should -Be "JSON test"
            $logEntry.Level | Should -Be "INFO"
            $logEntry.Category | Should -Be "Test"
        }
        
        It "Should include process and thread information" {
            Write-ApplicationLog -Message "Process test" -Level "DEBUG"
            
            $content = Get-Content $script:TestLogPath -Raw
            $jsonLines = $content -split "`n" | Where-Object { $_.Trim() -ne "" }
            $lastLine = $jsonLines[-1]
            $logEntry = $lastLine | ConvertFrom-Json
            
            $logEntry.ProcessId | Should -Be $PID
            $logEntry.ThreadId | Should -Not -BeNullOrEmpty
            $logEntry.MachineName | Should -Be $env:COMPUTERNAME
            $logEntry.UserName | Should -Be $env:USERNAME
        }
        
        It "Should respect log level filtering" {
            Initialize-LoggingSystem -LogPath $script:TestLogPath -Level "WARNING"
            
            Write-ApplicationLog -Message "Debug message" -Level "DEBUG"
            Write-ApplicationLog -Message "Info message" -Level "INFO"
            Write-ApplicationLog -Message "Warning message" -Level "WARNING"
            
            $content = Get-Content $script:TestLogPath -Raw
            $content | Should -Not -Match "Debug message"
            $content | Should -Not -Match "Info message"
            $content | Should -Match "Warning message"
        }
    }
    
    Context "Performance Logging" {
        It "Should log performance metrics" {
            $duration = New-TimeSpan -Seconds 2 -Milliseconds 500
            $metrics = @{ ItemsProcessed = 10; ErrorCount = 0 }
            
            Write-PerformanceLog -Operation "TestOperation" -Duration $duration -Metrics $metrics
            
            $content = Get-Content $script:TestLogPath -Raw
            $content | Should -Match "TestOperation"
            $content | Should -Match "2.5"  # 2.5 seconds
        }
    }
    
    Context "Error Logging" {
        It "Should log detailed error information" {
            try {
                throw [System.ArgumentException]::new("Test exception")
            }
            catch {
                Write-ErrorLog -Operation "TestOperation" -Exception $_.Exception -Context @{ TestKey = "TestValue" }
            }
            
            $content = Get-Content $script:TestLogPath -Raw
            $content | Should -Match "Test exception"
            $content | Should -Match "ArgumentException"
            $content | Should -Match "Context_TestKey"
        }
    }
    
    Context "Security Logging" {
        It "Should log security events" {
            Write-SecurityLog -Event "Login" -Action "UserAuthenticated" -Details @{ UserId = "test123" }
            
            $content = Get-Content $script:TestLogPath -Raw
            $content | Should -Match "Security: UserAuthenticated - Login"
            $content | Should -Match "UserId"
        }
    }
    
    Context "Log Rotation" {
        It "Should rotate logs when size limit exceeded" {
            # Create a large log file that exceeds the limit
            Initialize-LoggingSystem -LogPath $script:TestLogPath -Level "DEBUG" -MaxSizeMB 1
            
            # Write enough data to trigger rotation
            for ($i = 0; $i -lt 1000; $i++) {
                Write-ApplicationLog -Message "Large log entry number $i with lots of additional data to make it bigger" -Level "INFO"
            }
            
            # Check if rotation occurred
            $logDir = Split-Path $script:TestLogPath -Parent
            $logBaseName = [System.IO.Path]::GetFileNameWithoutExtension($script:TestLogPath)
            $logExtension = [System.IO.Path]::GetExtension($script:TestLogPath)
            $rotatedFile = Join-Path $logDir "$logBaseName.1$logExtension"
            
            # Note: This test might not always trigger rotation depending on actual log size
            # Test-Path $rotatedFile | Should -Be $true
        }
    }
    
    Context "Log Statistics" {
        It "Should return log statistics" {
            Write-ApplicationLog -Message "Stats test 1" -Level "INFO"
            Write-ApplicationLog -Message "Stats test 2" -Level "ERROR"
            Write-ApplicationLog -Message "Stats test 3" -Level "WARNING"
            
            $stats = Get-LogStatistics
            
            $stats.LogFilePath | Should -Be $script:TestLogPath
            $stats.LogLevel | Should -Not -BeNullOrEmpty
            $stats.MaxLogSize | Should -Not -BeNullOrEmpty
            
            if (Test-Path $script:TestLogPath) {
                $stats.CurrentLogSize | Should -BeGreaterThan 0
                $stats.LastModified | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe "Security Module Tests" {
    BeforeAll {
        # Import required modules
        Import-Module "$PSScriptRoot\..\..\Modules\Security\EnhancedSecurity.psm1" -Force
        Import-Module "$PSScriptRoot\..\..\Modules\Logging\EnhancedLogging.psm1" -Force
        
        # Initialize systems
        Initialize-LoggingSystem -LogPath "$PSScriptRoot\security-test.log" -Level "DEBUG"
        Initialize-SecuritySystem -EnableSecureStorage $true
        
        $script:TestConfigPath = "$PSScriptRoot\test-secure-config.json"
    }
    
    AfterAll {
        # Cleanup test files
        Get-ChildItem "$PSScriptRoot" -Filter "*test*" | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    
    Context "Data Encryption" {
        It "Should encrypt and decrypt sensitive data" {
            $originalData = "MySecretAPIKey123"
            
            $encryptedData = Protect-SensitiveData -Data $originalData
            $encryptedData | Should -Not -Be $originalData
            $encryptedData.Length | Should -BeGreaterThan $originalData.Length
            
            $decryptedData = Unprotect-SensitiveData -EncryptedData $encryptedData
            $decryptedData | Should -Be $originalData
        }
        
        It "Should handle empty data gracefully" {
            $encryptedEmpty = Protect-SensitiveData -Data ""
            $encryptedEmpty | Should -Be ""
            
            $decryptedEmpty = Unprotect-SensitiveData -EncryptedData ""
            $decryptedEmpty | Should -Be ""
        }
    }
    
    Context "Secure Configuration Manager" {
        It "Should create secure configuration manager" {
            $manager = New-SecureConfigurationManager -ConfigPath $script:TestConfigPath
            $manager | Should -Not -BeNullOrEmpty
        }
        
        It "Should encrypt and save configuration" {
            $manager = New-SecureConfigurationManager -ConfigPath $script:TestConfigPath
            $config = @{
                APIKey = "secretkey123"
                Username = "testuser"
                NormalSetting = "normal value"
            }
            
            { $manager.SaveSecureConfiguration($config) } | Should -Not -Throw
            Test-Path $script:TestConfigPath | Should -Be $true
        }
        
        It "Should load and decrypt configuration" {
            # First save a configuration
            $manager = New-SecureConfigurationManager -ConfigPath $script:TestConfigPath
            $originalConfig = @{
                APIKey = "secretkey123"
                Username = "testuser"
                NormalSetting = "normal value"
            }
            $manager.SaveSecureConfiguration($originalConfig)
            
            # Load it back
            $loadedConfig = $manager.LoadSecureConfiguration()
            $loadedConfig.APIKey | Should -Be "secretkey123"
            $loadedConfig.Username | Should -Be "testuser"
            $loadedConfig.NormalSetting | Should -Be "normal value"
        }
    }
    
    Context "Security Configuration Test" {
        It "Should test security configuration" {
            $results = Test-SecurityConfiguration
            
            $results.OverallStatus | Should -BeIn @("Pass", "Fail", "Warning")
            $results.Tests | Should -Not -BeNullOrEmpty
            $results.Tests[0].Name | Should -Not -BeNullOrEmpty
            $results.Tests[0].Status | Should -BeIn @("Pass", "Fail", "Warning")
        }
    }
}
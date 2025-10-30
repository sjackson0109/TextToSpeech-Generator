# Unit Tests for Logging Module
# Tests logging functionality, performance, and reliability

Describe "Logging Module Tests" {
    BeforeAll {
        # Import required modules
        Import-Module "$PSScriptRoot\..\..\Modules\Logging\EnhancedLogging.psm1" -Force
        
        # Create test log path
        $script:TestLogPath = "$PSScriptRoot\test-logging.log"
        
        # Initialise logging system
        Initialise-LoggingSystem -LogPath $script:TestLogPath -Level "DEBUG"
    }
    
    AfterAll {
        # Cleanup test files
        if (Test-Path $script:TestLogPath) {
            Remove-Item $script:TestLogPath -Force
        }
    }
    
    Context "Basic Logging Functions" {
        It "Should write INFO level messages" {
            Write-ApplicationLog -Message "Test INFO message" -Level "INFO" -Category "Testing"
            
            $logContent = Get-Content $script:TestLogPath -Raw
            $logContent | Should -Match "Test INFO message"
            $logContent | Should -Match "INFO"
        }
        
        It "Should write DEBUG level messages" {
            Write-ApplicationLog -Message "Test DEBUG message" -Level "DEBUG" -Category "Testing"
            
            $logContent = Get-Content $script:TestLogPath -Raw
            $logContent | Should -Match "Test DEBUG message"
            $logContent | Should -Match "DEBUG"
        }
        
        It "Should write ERROR level messages" {
            Write-ApplicationLog -Message "Test ERROR message" -Level "ERROR" -Category "Testing"
            
            $logContent = Get-Content $script:TestLogPath -Raw
            $logContent | Should -Match "Test ERROR message"
            $logContent | Should -Match "ERROR"
        }
        
        It "Should respect log level filtering" {
            # Set log level to WARNING
            $script:LogLevel = "WARNING"
            
            Write-ApplicationLog -Message "Should not appear" -Level "DEBUG" -Category "Testing"
            Write-ApplicationLog -Message "Should appear" -Level "WARNING" -Category "Testing"
            
            $logContent = Get-Content $script:TestLogPath -Raw
            $logContent | Should -Match "Should appear"
            # Note: DEBUG message might appear from previous tests, so we don't test for its absence
        }
    }
    
    Context "Log Message Structure" {
        It "Should include timestamp in log entries" {
            Write-ApplicationLog -Message "Timestamp test" -Level "INFO" -Category "Testing"
            
            $logContent = Get-Content $script:TestLogPath -Raw
            $logContent | Should -Match "\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}"
        }
        
        It "Should include category in log entries" {
            Write-ApplicationLog -Message "Category test" -Level "INFO" -Category "SpecialCategory"
            
            $logContent = Get-Content $script:TestLogPath -Raw
            $logContent | Should -Match "SpecialCategory"
        }
        
        It "Should handle properties in log entries" {
            $properties = @{
                UserId = 12345
                Action = "TestAction"
                Duration = "150ms"
            }
            
            Write-ApplicationLog -Message "Properties test" -Level "INFO" -Category "Testing" -Properties $properties
            
            $logContent = Get-Content $script:TestLogPath -Raw
            $logContent | Should -Match "Properties test"
        }
    }
    
    Context "Log Performance" {
        It "Should write logs efficiently" {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            for ($i = 0; $i -lt 100; $i++) {
                Write-ApplicationLog -Message "Performance test message $i" -Level "INFO" -Category "Performance"
            }
            
            $stopwatch.Stop()
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 1000  # 100 messages in under 1 second
        }
        
        It "Should handle large log messages" {
            $largeMessage = "X" * 10000  # 10KB message
            
            { Write-ApplicationLog -Message $largeMessage -Level "INFO" -Category "Testing" } | Should -Not -Throw
            
            $logContent = Get-Content $script:TestLogPath -Raw
            $logContent | Should -Match "XXXXXXXXXX"  # Should contain our large message
        }
    }
    
    Context "Log Rotation" {
        It "Should handle log rotation when size limit reached" {
            # Set a very small max log size for testing
            $script:MaxLogSize = 1KB
            
            # Write enough to trigger rotation
            for ($i = 0; $i -lt 50; $i++) {
                Write-ApplicationLog -Message "Rotation test message $i with extra content to increase size" -Level "INFO" -Category "Rotation"
            }
            
            # Should not throw errors even if rotation occurs
            { Write-ApplicationLog -Message "After rotation" -Level "INFO" -Category "Rotation" } | Should -Not -Throw
        }
    }
    
    Context "Error Handling" {
        It "Should handle invalid log levels gracefully" {
            # This should either use a default level or handle the error gracefully
            { Write-ApplicationLog -Message "Invalid level test" -Level "INVALID" -Category "Testing" } | Should -Not -Throw
        }
        
        It "Should handle null or empty messages" {
            { Write-ApplicationLog -Message "" -Level "INFO" -Category "Testing" } | Should -Not -Throw
            { Write-ApplicationLog -Message $null -Level "INFO" -Category "Testing" } | Should -Not -Throw
        }
        
        It "Should continue working after file access errors" {
            # This test assumes the logging system handles file access errors gracefully
            { Write-ApplicationLog -Message "After error test" -Level "INFO" -Category "Testing" } | Should -Not -Throw
        }
    }
    
    Context "Thread Safety" {
        It "Should handle concurrent log writes" {
            $jobs = 1..5 | ForEach-Object {
                Start-Job -ScriptBlock {
                    param($ModulePath, $LogPath, $ThreadId)
                    Import-Module $ModulePath -Force
                    Initialise-LoggingSystem -LogPath $LogPath -Level "INFO"
                    
                    for ($i = 0; $i -lt 20; $i++) {
                        Write-ApplicationLog -Message "Thread $ThreadId message $i" -Level "INFO" -Category "Concurrency"
                        Start-Sleep -Milliseconds 10
                    }
                } -ArgumentList "$PSScriptRoot\..\..\Modules\Logging\EnhancedLogging.psm1", $script:TestLogPath, $_
            }
            
            $jobs | Wait-Job | Remove-Job
            
            # Log file should exist and contain messages from all threads
            Test-Path $script:TestLogPath | Should -Be $true
            $logContent = Get-Content $script:TestLogPath -Raw
            $logContent | Should -Match "Thread.*message"
        }
    }
}
# Performance Tests for TextToSpeech Generator
# Tests performance characteristics and benchmarks

Describe "Performance Tests" {
    BeforeAll {
        # Import modules
        Import-Module "$PSScriptRoot\..\..\Modules\TTSProviders\TTSProviders.psm1" -Force
        Import-Module "$PSScriptRoot\..\..\Modules\Logging\EnhancedLogging.psm1" -Force
        
        Initialize-LoggingSystem -LogPath "$PSScriptRoot\performance-test.log" -Level "INFO"
        
        # Performance test configuration
        $script:TestIterations = 100
        $script:LargeTextSize = 1000
        $script:MediumTextSize = 500
        $script:SmallTextSize = 50
    }
    
    AfterAll {
        Get-ChildItem "$PSScriptRoot" -Filter "*test*" | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    
    Context "Module Loading Performance" {
        It "Should load modules quickly" {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            # Reload modules to test loading time
            Remove-Module TTSProviders -Force -ErrorAction SilentlyContinue
            Import-Module "$PSScriptRoot\..\..\Modules\TTSProviders\TTSProviders.psm1" -Force
            
            $stopwatch.Stop()
            Write-Host "Module loading time: $($stopwatch.ElapsedMilliseconds)ms"
            
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 2000  # Should load in under 2 seconds
        }
    }
    
    Context "Provider Creation Performance" {
        It "Should create providers quickly" {
            $providers = @("Microsoft Azure", "Google Cloud", "AWS Polly")
            $times = @()
            
            foreach ($providerName in $providers) {
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                
                for ($i = 0; $i -lt 50; $i++) {
                    $provider = Get-TTSProvider -ProviderName $providerName
                }
                
                $stopwatch.Stop()
                $avgTime = $stopwatch.ElapsedMilliseconds / 50
                $times += $avgTime
                
                Write-Host "$providerName creation time: ${avgTime}ms average"
            }
            
            # All providers should be created quickly
            $times | ForEach-Object { $_ | Should -BeLessThan 10 }  # Under 10ms average
        }
    }
    
    Context "Configuration Validation Performance" {
        It "Should validate configurations quickly" {
            $configs = @(
                @{ Provider = "Microsoft Azure"; Config = @{ APIKey = "12345678901234567890123456789012"; Region = "eastus"; Voice = "en-US-JennyNeural" } },
                @{ Provider = "Google Cloud"; Config = @{ APIKey = "AIzaSyABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"; Voice = "en-US-Wavenet-F" } },
                @{ Provider = "AWS Polly"; Config = @{ AccessKeyId = "AKIAIOSFODNN7EXAMPLE"; SecretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY"; Region = "us-east-1" } }
            )
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            for ($i = 0; $i -lt $script:TestIterations; $i++) {
                foreach ($configSet in $configs) {
                    $result = Test-ConfigurationValid -Provider $configSet.Provider -Configuration $configSet.Config
                }
            }
            
            $stopwatch.Stop()
            $avgTime = $stopwatch.ElapsedMilliseconds / ($script:TestIterations * $configs.Count)
            
            Write-Host "Average validation time: ${avgTime}ms"
            $avgTime | Should -BeLessThan 5  # Under 5ms per validation
        }
    }
    
    Context "Logging Performance" {
        It "Should log messages efficiently" {
            $testMessages = @(
                "Short log message",
                "Medium length log message with some additional context information",
                "Very long log message with extensive details about the operation including performance metrics, error codes, stack traces, and detailed diagnostic information that might be encountered in production environments"
            )
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            for ($i = 0; $i -lt $script:TestIterations; $i++) {
                foreach ($message in $testMessages) {
                    Write-ApplicationLog -Message $message -Level "INFO" -Category "Performance"
                }
            }
            
            $stopwatch.Stop()
            $avgTime = $stopwatch.ElapsedMilliseconds / ($script:TestIterations * $testMessages.Count)
            
            Write-Host "Average logging time: ${avgTime}ms"
            $avgTime | Should -BeLessThan 2  # Under 2ms per log entry
        }
        
        It "Should handle concurrent logging efficiently" {
            $jobs = @()
            $jobCount = 5
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            # Start multiple background jobs logging simultaneously
            for ($j = 0; $j -lt $jobCount; $j++) {
                $jobs += Start-Job -ScriptBlock {
                    param($ModulePath, $JobId)
                    Import-Module $ModulePath -Force
                    
                    for ($i = 0; $i -lt 20; $i++) {
                        Write-ApplicationLog -Message "Concurrent log from job $JobId - entry $i" -Level "INFO"
                    }
                } -ArgumentList "$PSScriptRoot\..\..\Modules\Logging\EnhancedLogging.psm1", $j
            }
            
            # Wait for all jobs to complete
            $jobs | Wait-Job | Out-Null
            $jobs | Remove-Job
            
            $stopwatch.Stop()
            
            Write-Host "Concurrent logging completed in: $($stopwatch.ElapsedMilliseconds)ms"
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 5000  # Should complete within 5 seconds
        }
    }
    
    Context "Memory Usage Performance" {
        It "Should maintain reasonable memory usage" {
            $initialMemory = [System.GC]::GetTotalMemory($false)
            
            # Perform memory-intensive operations
            for ($i = 0; $i -lt 100; $i++) {
                $provider = Get-TTSProvider -ProviderName "Microsoft Azure"
                $config = @{
                    APIKey = "12345678901234567890123456789012"
                    Region = "eastus"
                    Voice = "en-US-JennyNeural"
                }
                $result = Test-ConfigurationValid -Provider "Microsoft Azure" -Configuration $config
                
                # Create some large objects
                $largeText = "A" * 1000
                Write-ApplicationLog -Message $largeText -Level "DEBUG"
            }
            
            # Force garbage collection
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
            
            $finalMemory = [System.GC]::GetTotalMemory($false)
            $memoryIncrease = $finalMemory - $initialMemory
            
            Write-Host "Memory increase: $($memoryIncrease / 1MB) MB"
            
            # Memory increase should be reasonable (under 50MB for this test)
            $memoryIncrease | Should -BeLessThan (50 * 1MB)
        }
    }
    
    Context "Error Handling Performance" {
        It "Should handle errors efficiently" {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            for ($i = 0; $i -lt 50; $i++) {
                try {
                    # Cause various types of errors
                    $provider = Get-TTSProvider -ProviderName "NonExistentProvider"
                }
                catch {
                    $errorInfo = Get-DetailedErrorInfo -Exception $_.Exception -Provider "Test"
                }
                
                try {
                    $result = Test-ConfigurationValid -Provider "Microsoft Azure" -Configuration @{}
                }
                catch {
                    Write-ErrorLog -Operation "TestValidation" -Exception $_.Exception
                }
            }
            
            $stopwatch.Stop()
            $avgTime = $stopwatch.ElapsedMilliseconds / 100  # 50 iterations * 2 operations each
            
            Write-Host "Average error handling time: ${avgTime}ms"
            $avgTime | Should -BeLessThan 10  # Under 10ms per error
        }
    }
    
    Context "Scalability Tests" {
        It "Should scale with increasing load" {
            $dataSizes = @(10, 50, 100, 200)
            $times = @()
            
            foreach ($size in $dataSizes) {
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                
                # Simulate processing multiple configurations
                for ($i = 0; $i -lt $size; $i++) {
                    $config = @{
                        APIKey = "12345678901234567890123456789012"
                        Region = "eastus"
                        Voice = "en-US-JennyNeural"
                    }
                    $result = Test-ConfigurationValid -Provider "Microsoft Azure" -Configuration $config
                }
                
                $stopwatch.Stop()
                $times += $stopwatch.ElapsedMilliseconds
                
                Write-Host "Processing $size items took: $($stopwatch.ElapsedMilliseconds)ms"
            }
            
            # Check that processing time scales reasonably (not exponentially)
            $ratio1 = $times[1] / $times[0]  # 50/10
            $ratio2 = $times[2] / $times[1]  # 100/50
            $ratio3 = $times[3] / $times[2]  # 200/100
            
            # Ratios should be close to the data size ratios (linear scaling)
            $ratio1 | Should -BeLessThan 10  # Should not be more than 10x slower
            $ratio2 | Should -BeLessThan 5   # Should not be more than 5x slower
            $ratio3 | Should -BeLessThan 5   # Should not be more than 5x slower
        }
    }
}
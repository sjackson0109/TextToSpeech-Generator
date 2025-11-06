# Performance Tests for TextToSpeech Generator v3.2
# Tests performance benchmarks, memory usage, and scalability

Describe "Performance Tests" {
    BeforeAll {
        # Import required modules
        Import-Module "$PSScriptRoot\..\..\Modules\Configuration.psm1" -Force
        Import-Module "$PSScriptRoot\..\..\Modules\Logging.psm1" -Force
        
        # Initialise logging for tests
    Initialize-LoggingSystem -LogPath "$PSScriptRoot\performance-test.log" -Level "INFO"
        
        # Create test configuration
        $script:TestConfig = @{
            APIKey = "fake-azure-api-key-for-testing"
            Region = "eastus"
            Voice = "en-US-JennyNeural"
        }
    }
    
    Context "Configuration Validation Performance" {
        It "Should validate configurations quickly" {
            $times = @()
            for ($i = 0; $i -lt 50; $i++) {
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                
                # Test various provider validations
                $null = Test-AzureConfiguration -APIKey "invalid" -Region "eastus" -Voice "en-US-JennyNeural"
                $null = Test-AzureConfiguration -APIKey $script:TestConfig.APIKey -Region $script:TestConfig.Region -Voice $script:TestConfig.Voice
                $null = Test-GoogleCloudConfiguration -ServiceAccountJson '{"type":"service_account"}' -ProjectId "test-project"
                
                $stopwatch.Stop()
                $times += $stopwatch.Elapsed.TotalMilliseconds
            }
            
            $avgTime = ($times | Measure-Object -Average).Average
            Write-Host "Average validation time: ${avgTime}ms"
            $avgTime | Should -BeLessThan 10  # Under 10ms per validation
        }
    }
    
    Context "Logging Performance" {
        It "Should log messages efficiently" {
            $times = @()
            for ($i = 0; $i -lt 300; $i++) {
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                
                    Write-ApplicationLog -Module "BulkProcessing.Tests" -Message "Short log message" -Level "INFO" -Category "Performance"
                    Write-ApplicationLog -Module "BulkProcessing.Tests" -Message "Medium length log message with some additional context information" -Level "INFO" -Category "Performance"
                    Write-ApplicationLog -Module "BulkProcessing.Tests" -Message "Very long log message with extensive details about the operation including performance metrics, error codes, stack traces, and detailed diagnostic information that might be encountered in production environments" -Level "INFO" -Category "Performance"
                
                $stopwatch.Stop()
                $times += $stopwatch.Elapsed.TotalMilliseconds
            }
            
            $avgTime = ($times | Measure-Object -Average).Average
            Write-Host "Average logging time: ${avgTime}ms"
            $avgTime | Should -BeLessThan 5  # Under 5ms per log entry
        }
        
        It "Should handle concurrent logging efficiently" {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            # Simulate concurrent logging from multiple threads
            $jobs = 1..10 | ForEach-Object {
                Start-Job -ScriptBlock {
                    param($ModulePath, $LogPath, $Iteration)
                    Import-Module $ModulePath -Force
                    Initialize-LoggingSystem -LogPath $LogPath -Level "INFO"
                    
                    for ($i = 0; $i -lt 50; $i++) {
                            Write-ApplicationLog -Module "BulkProcessing.Tests" -Message "Concurrent log entry $Iteration-$i" -Level "INFO" -Category "Concurrency"
                    }
                } -ArgumentList "$PSScriptRoot\..\..\Modules\Logging.psm1", "$PSScriptRoot\concurrent-test.log", $_
            }
            
            $jobs | Wait-Job | Remove-Job
            $stopwatch.Stop()
            
            Write-Host "Concurrent logging completed in: $($stopwatch.ElapsedMilliseconds)ms"
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 2000  # Under 2 seconds
        }
    }
    
    Context "Memory Usage Performance" {
        It "Should maintain reasonable memory usage" {
            $startMemory = [System.GC]::GetTotalMemory($false) / 1MB
            
            # Perform memory-intensive operations
            for ($i = 0; $i -lt 100; $i++) {
                $null = Test-AzureConfiguration -APIKey $script:TestConfig.APIKey -Region $script:TestConfig.Region -Voice $script:TestConfig.Voice
            }
            
            # Force garbage collection
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
            [System.GC]::Collect()
            
            $endMemory = [System.GC]::GetTotalMemory($false) / 1MB
            $memoryIncrease = $endMemory - $startMemory
            
            Write-Host "Memory increase: $memoryIncrease MB"
            $memoryIncrease | Should -BeLessThan 50  # Less than 50MB increase
        }
    }
    
    Context "Error Handling Performance" {
        It "Should handle errors efficiently" {
            $times = @()
            for ($i = 0; $i -lt 50; $i++) {
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                
                # Test error scenarios
                try {
                    $null = Test-AzureConfiguration -APIKey "invalid" -Region "invalid" -Voice "invalid"
                } catch {
                    # Expected error
                }
                
                $stopwatch.Stop()
                $times += $stopwatch.Elapsed.TotalMilliseconds
            }
            
            $avgTime = ($times | Measure-Object -Average).Average
            Write-Host "Average error handling time: ${avgTime}ms"
            $avgTime | Should -BeLessThan 10  # Under 10ms per error
        }
    }
    
    Context "Scalability Tests" {
        It "Should scale with increasing load" {
            $testSizes = @(10, 50, 100, 200)
            $results = @()
            
            foreach ($size in $testSizes) {
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                
                for ($i = 0; $i -lt $size; $i++) {
                    $null = Test-AzureConfiguration -APIKey $script:TestConfig.APIKey -Region $script:TestConfig.Region -Voice $script:TestConfig.Voice
                }
                
                $stopwatch.Stop()
                $results += @{
                    Size = $size
                    Time = $stopwatch.ElapsedMilliseconds
                }
                
                Write-Host "Processing $size items took: $($stopwatch.ElapsedMilliseconds)ms"
            }
            
            # Check if performance scales reasonably (should not be exponential)
            $last = $results[-1].Time
            $first = $results[0].Time
            $scalingFactor = $last / $first
            
            # Should scale roughly linearly (within 5x for 20x more items)
            $scalingFactor | Should -BeLessThan 25
        }
    }
}
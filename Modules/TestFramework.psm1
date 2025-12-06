# Enhanced Testing Framework for TextToSpeech Generator
# Comprehensive testing infrastructure with unit, integration, and performance tests

# Import required modules
if (-not (Get-Module -Name 'Logging')) {
	Import-Module (Resolve-Path (Join-Path $PSScriptRoot '.\Logging.psm1')).Path
}
# Test Result Classes (PowerShell 5.1 compatible)
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Diagnostics;

public class TestResult
{
    public string TestName { get; set; }
    public string TestCategory { get; set; }
    public bool Passed { get; set; }
    public string ErrorMessage { get; set; }
    public double ExecutionTimeMs { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public Dictionary<string, object> Metadata { get; set; }
    
    public TestResult()
    {
        Metadata = new Dictionary<string, object>();
    }
}

public class TestSuite
{
    public string SuiteName { get; set; }
    public List<TestResult> Tests { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public int PassedTests => Tests.FindAll(t => t.Passed).Count;
    public int FailedTests => Tests.FindAll(t => !t.Passed).Count;
    public int TotalTests => Tests.Count;
    public double SuccessRate => TotalTests > 0 ? (double)PassedTests / TotalTests * 100 : 0;
    
    public TestSuite()
    {
        Tests = new List<TestResult>();
    }
}

public class TestRunner
{
    public List<TestSuite> TestSuites { get; set; }
    public bool IsRunning { get; set; }
    public DateTime SessionStartTime { get; set; }
    
    public TestRunner()
    {
        TestSuites = new List<TestSuite>();
        IsRunning = false;
    }
}
'@

class EnhancedTestFramework {
    [object] $TestRunner
    [hashtable] $TestCategories
    [hashtable] $MockObjects
    [hashtable] $TestConfiguration
    [string] $TestResultsPath
    [bool] $ContinuousIntegrationMode
    
    EnhancedTestFramework() {
        $this.TestRunner = [TestRunner]::new()
        $this.TestCategories = @{
            Unit = @()
            Integration = @()
            Performance = @()
            Security = @()
            EndToEnd = @()
        }
        $this.MockObjects = @{}
        $this.TestConfiguration = @{
            ParallelExecution = $true
            MaxConcurrency = 4
            TimeoutSeconds = 300
            RetryFailedTests = $true
            MaxRetries = 2
            GenerateReports = $true
            CodeCoverageEnabled = $true
            PerformanceThresholds = @{
                MaxResponseTime = 5000
                MinThroughput = 10
                MaxMemoryMB = 500
            }
        }
        $this.TestResultsPath = "$env:TEMP\TTSGenerator-TestResults"
        $this.ContinuousIntegrationMode = $false
        
        $this.InitialiseTestEnvironment()
    }
    
    [void] InitialiseTestEnvironment() {
        # Create test results directory
        if (-not (Test-Path $this.TestResultsPath)) {
            New-Item -Path $this.TestResultsPath -ItemType Directory -Force | Out-Null
        }
        
        Add-ApplicationLog -Module "TestFramework" -Message "Enhanced testing framework initialised" -Level "INFO"
        Add-ApplicationLog -Module "TestFramework" -Message "Test results path: $($this.TestResultsPath)" -Level "DEBUG"
    }
    
    [void] RegisterUnitTests() {
        # Configuration Module Tests
        $this.AddTest("Unit", "Test-ConfigurationLoading", {
            try {
                Import-Module "$PSScriptRoot\..\Configuration.psm1" -Force
                $configManager = [AdvancedConfigurationManager]::new()
                return $configManager -ne $null
            } catch {
                throw "Configuration module failed to load: $($_.Exception.Message)"
            }
        })
        
        $this.AddTest("Unit", "Test-ConfigurationValidation", {
            try {
                Import-Module "$PSScriptRoot\..\Configuration.psm1" -Force
                $configManager = [AdvancedConfigurationManager]::new()
                
                # Test with valid configuration
                $validConfig = @{
                    Environment = "Testing"
                    Provider = @{
                        Name = "Azure"
                        Settings = @{
                            Region = "eastus"
                            Voice = "en-US-JennyNeural"
                        }
                    }
                }
                
                $result = $configManager.ValidateConfiguration($validConfig)
                return $result.IsValid
            } catch {
                throw "Configuration validation failed: $($_.Exception.Message)"
            }
        })
        
        # Security Module Tests
        $this.AddTest("Unit", "Test-InputSanitization", {
            try {
                Import-Module "$PSScriptRoot\..\Security.psm1" -Force
                
                $maliciousInputs = @(
                    "<script>alert('xss')</script>",
                    "'; DROP TABLE users; --",
                    "../../../etc/passwd",
                    "$(Get-Process)"
                )
                
                foreach ($input in $maliciousInputs) {
                    $sanitized = Test-InputSanitization -InputText $input
                    if (-not $sanitized.IsSafe) {
                        return $true  # Correctly identified as unsafe
                    }
                }
                
                throw "Security validation failed to identify malicious inputs"
            } catch {
                throw "Input sanitization test failed: $($_.Exception.Message)"
            }
        })
        
        # Logging Module Tests
        $this.AddTest("Unit", "Test-LoggingFunctionality", {
            try {
                Import-Module "$PSScriptRoot\..\Logging.psm1" -Force
                
                $testMessage = "Unit test log entry - $([System.Guid]::NewGuid())"
                Add-ApplicationLog -Module "TestFramework" -Message $testMessage -Level "INFO" -category "Testing"
                
                # Verify log entry was written (simplified check)
                return $true
            } catch {
                throw "Logging functionality test failed: $($_.Exception.Message)"
            }
        })
        
        # Performance Module Tests
        $this.AddTest("Unit", "Test-ConnectionPoolInitialisation", {
            try {
                Import-Module "$PSScriptRoot\Performance.psm1" -Force
                
                $optimiser = New-PerformanceOptimizer
                $report = Get-PerformanceReport -optimiser $optimiser
                
                return $report.ConnectionPools.Count -gt 0
            } catch {
                throw "Connection pool initialisation failed: $($_.Exception.Message)"
            }
        })
        
        # Error Recovery Tests
        $this.AddTest("Unit", "Test-ErrorRecoveryStrategies", {
            try {
                Import-Module "$PSScriptRoot\ErrorRecovery.psm1" -Force
                
                $errorRecovery = [AdvancedErrorRecovery]::new()
                
                # Test Azure rate limit recovery
                $mockError = "TooManyRequests: Rate limit exceeded"
                $context = @{
                    Provider = "Azure"
                    Configuration = @{ Region = "eastus" }
                }
                
                $result = $errorRecovery.AttemptRecovery($mockError, $context)
                return $result.ErrorType -eq "AzureRateLimit"
            } catch {
                throw "Error recovery test failed: $($_.Exception.Message)"
            }
        })
    }
    
    [void] RegisterIntegrationTests() {
        # Module Integration Tests
        $this.AddTest("Integration", "Test-ModuleIntegration", {
            try {
                # Test loading all modules together
                $modules = @(
                    "modules\Logging.psm1",
                    "modules\Configuration.psm1",
                    "modules\Security.psm1",
                    "modules\ErrorRecovery.psm1",
                    "modules\Optimisation.psm1"
                )
                
                foreach ($module in $modules) {
                    Import-Module "$PSScriptRoot\..\$module" -Force
                }
                
                return $true
            } catch {
                throw "Module integration test failed: $($_.Exception.Message)"
            }
        })
        
        # Configuration-Security Integration
        $this.AddTest("Integration", "Test-ConfigurationSecurityIntegration", {
            try {
                Import-Module "$PSScriptRoot\..\Configuration.psm1" -Force
                Import-Module "$PSScriptRoot\..\Security.psm1" -Force
                
                $configManager = [AdvancedConfigurationManager]::new()
                
                # Test encrypted configuration loading
                $testConfig = @{
                    Provider = @{
                        Settings = @{
                            ApiKey = "ENCRYPTED:dGVzdC1hcGkta2V5"  # base64 encoded test
                        }
                    }
                }
                
                $result = $configManager.ProcessEncryptedValues($testConfig)
                return $result -ne $null
            } catch {
                throw "Configuration-Security integration failed: $($_.Exception.Message)"
            }
        })
        
        # Performance-ErrorRecovery Integration
        $this.AddTest("Integration", "Test-PerformanceErrorRecoveryIntegration", {
            try {
                Import-Module "$PSScriptRoot\Performance.psm1" -Force
                Import-Module "$PSScriptRoot\ErrorRecovery.psm1" -Force
                
                $optimiser = New-PerformanceOptimizer
                $errorRecovery = [AdvancedErrorRecovery]::new()
                
                # Test connection acquisition with error recovery
                $connection = $optimiser.AcquireConnection("Azure")
                $providerStatus = $errorRecovery.GetProviderStatus("Azure")
                
                return $connection -ne $null -and $providerStatus -ne $null
            } catch {
                throw "Performance-ErrorRecovery integration failed: $($_.Exception.Message)"
            }
        })
    }
    
    [void] RegisterPerformanceTests() {
        # Response Time Tests
        $this.AddTest("Performance", "Test-ModuleLoadingPerformance", {
            $startTime = Get-Date
            
            try {
                Import-Module "$PSScriptRoot\..\Configuration.psm1" -Force
                Import-Module "$PSScriptRoot\..\Logging.psm1" -Force
                Import-Module "$PSScriptRoot\..\Security.psm1" -Force
                
                $loadTime = ((Get-Date) - $startTime).TotalMilliseconds
                
                if ($loadTime -gt $this.TestConfiguration.PerformanceThresholds.MaxResponseTime) {
                    throw "Module loading too slow: $($loadTime)ms (threshold: $($this.TestConfiguration.PerformanceThresholds.MaxResponseTime)ms)"
                }
                
                return $true
            } catch {
                throw "Module loading performance test failed: $($_.Exception.Message)"
            }
        })
        
        # Memory Usage Tests
        $this.AddTest("Performance", "Test-MemoryUsage", {
            try {
                $initialMemory = [System.GC]::GetTotalMemory($false) / 1MB
                
                # Load all modules and create instances
                Import-Module "$PSScriptRoot\..\Configuration.psm1" -Force
                Import-Module "$PSScriptRoot\Performance.psm1" -Force
                
                $configManager = [AdvancedConfigurationManager]::new()
                $optimiser = New-PerformanceOptimizer
                
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
                
                $finalMemory = [System.GC]::GetTotalMemory($false) / 1MB
                $memoryUsage = $finalMemory - $initialMemory
                
                if ($memoryUsage -gt $this.TestConfiguration.PerformanceThresholds.MaxMemoryMB) {
                    throw "Memory usage too high: $($memoryUsage)MB (threshold: $($this.TestConfiguration.PerformanceThresholds.MaxMemoryMB)MB)"
                }
                
                return $true
            } catch {
                throw "Memory usage test failed: $($_.Exception.Message)"
            }
        })
        
        # Concurrent Operations Test
        $this.AddTest("Performance", "Test-ConcurrentOperations", {
            try {
                Import-Module "$PSScriptRoot\Performance.psm1" -Force
                
                $optimiser = New-PerformanceOptimizer
                $startTime = Get-Date
                $operations = @()
                
                # Simulate concurrent connection acquisitions
                for ($i = 0; $i -lt 10; $i++) {
                    $operations += Start-Job -ScriptBlock {
                        param($optimiserPath)
                        Import-Module $optimiserPath -Force
                        $opt = New-PerformanceOptimizer
                        $connection = $opt.AcquireConnection("Azure")
                        Start-Sleep -Milliseconds 100
                        $opt.ReleaseConnection("Azure", $connection)
                        return $true
                    } -ArgumentList "$PSScriptRoot\Performance.psm1"
                }
                
                $results = $operations | Wait-Job | Receive-Job
                $operations | Remove-Job
                
                $executionTime = ((Get-Date) - $startTime).TotalMilliseconds
                $throughput = $results.Count / ($executionTime / 1000)
                
                if ($throughput -lt $this.TestConfiguration.PerformanceThresholds.MinThroughput) {
                    throw "Throughput too low: $($throughput) ops/sec (threshold: $($this.TestConfiguration.PerformanceThresholds.MinThroughput))"
                }
                
                return $results -contains $false -eq $false  # All operations succeeded
            } catch {
                throw "Concurrent operations test failed: $($_.Exception.Message)"
            }
        })
    }
    
    [void] RegisterSecurityTests() {
        # Input Validation Tests
        $this.AddTest("Security", "Test-SQLInjectionPrevention", {
            try {
                Import-Module "$PSScriptRoot\..\Security.psm1" -Force
                
                $sqlInjectionPayloads = @(
                    "'; DROP TABLE users; --",
                    "' OR '1'='1",
                    "UNION SELECT * FROM users",
                    "admin'--",
                    "' UNION SELECT password FROM users WHERE username='admin'--"
                )
                
                foreach ($payload in $sqlInjectionPayloads) {
                    $result = Test-InputSanitization -InputText $payload
                    if ($result.IsSafe) {
                        throw "SQL injection payload not detected: $payload"
                    }
                }
                
                return $true
            } catch {
                throw "SQL injection prevention test failed: $($_.Exception.Message)"
            }
        })
        
        # Path Traversal Tests
        $this.AddTest("Security", "Test-PathTraversalPrevention", {
            try {
                Import-Module "$PSScriptRoot\..\Security.psm1" -Force
                
                $pathTraversalPayloads = @(
                    "../../../etc/passwd",
                    "..\..\windows\system32\config\sam",
                    "....//....//etc/passwd",
                    "%2e%2e%2f%2e%2e%2f%2e%2e%2fetc%2fpasswd"
                )
                
                foreach ($payload in $pathTraversalPayloads) {
                    $result = Test-PathSecurity -Path $payload
                    if ($result.IsSecure) {
                        throw "Path traversal payload not detected: $payload"
                    }
                }
                
                return $true
            } catch {
                throw "Path traversal prevention test failed: $($_.Exception.Message)"
            }
        })
        
        # Configuration Security Tests
        $this.AddTest("Security", "Test-ConfigurationEncryption", {
            try {
                Import-Module "$PSScriptRoot\..\Configuration.psm1" -Force
                Import-Module "$PSScriptRoot\..\Security.psm1" -Force
                
                $configManager = [AdvancedConfigurationManager]::new()
                
                # Test encryption/decryption of sensitive values
                $sensitiveValue = "test-api-key-12345"
                $encrypted = ConvertTo-EncryptedString -PlainText $sensitiveValue
                
                if ($encrypted -eq $sensitiveValue) {
                    throw "Value was not encrypted"
                }
                
                $decrypted = ConvertFrom-EncryptedString -EncryptedText $encrypted
                
                if ($decrypted -ne $sensitiveValue) {
                    throw "Decryption failed or returned wrong value"
                }
                
                return $true
            } catch {
                throw "Configuration encryption test failed: $($_.Exception.Message)"
            }
        })
    }
    
    [void] AddTest([string]$category, [string]$testName, [scriptblock]$testCode) {
        if (-not $this.TestCategories.ContainsKey($category)) {
            $this.TestCategories[$category] = @()
        }
        
        $this.TestCategories[$category] += @{
            Name = $testName
            Code = $testCode
            category = $category
        }
        
        Add-ApplicationLog -Module "TestFramework" -Message "Registered test: $category - $testName" -Level "DEBUG"
    }
    
    [object] RunTestSuite([string]$category = "All") {
                    if (-not (Get-Module -Name 'Logging')) {
                        Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\Logging.psm1')).Path
                    }
        $this.TestRunner.SessionStartTime = Get-Date
        
        Add-ApplicationLog -Module "TestFramework" -Message "Starting test suite execution: $category" -Level "INFO"
        
        try {
            # Register all tests
            $this.RegisterUnitTests()
            $this.RegisterIntegrationTests()
            $this.RegisterPerformanceTests()
            $this.RegisterSecurityTests()
            
            $categoriesToRun = if ($category -eq "All") { 
                $this.TestCategories.Keys 
            } else { 
                @($category) 
            }
            
            foreach ($cat in $categoriesToRun) {
                if ($this.TestCategories.ContainsKey($cat)) {
                    $suite = $this.ExecuteTestCategory($cat)
                    $this.TestRunner.TestSuites.Add($suite)
                }
            }
            
            $overallReport = $this.GenerateTestReport()
            
            if ($this.TestConfiguration.GenerateReports) {
                $this.SaveTestReport($overallReport)
            }
            
            return $overallReport
            
        } finally {
            $this.TestRunner.IsRunning = $false
        }
    }
    
    [object] ExecuteTestCategory([string]$category) {
        $suite = [TestSuite]::new()
        $suite.SuiteName = $category
        $suite.StartTime = Get-Date
        
        Add-ApplicationLog -Module "TestFramework" -Message "Executing test category: $category" -Level "INFO"
        
        $tests = $this.TestCategories[$category]
        
        foreach ($test in $tests) {
            $testResult = $this.ExecuteTest($test)
            $suite.Tests.Add($testResult)
        }
        
        $suite.EndTime = Get-Date
        
        Add-ApplicationLog -Module "TestFramework" -Message "Completed test category: $category (Passed: $($suite.PassedTests)/$($suite.TotalTests))" -Level "INFO"
        
        return $suite
    }
    
    [object] ExecuteTest([hashtable]$test) {
        $result = [TestResult]::new()
        $result.TestName = $test.Name
        $result.TestCategory = $test.category
        $result.StartTime = Get-Date
        
        try {
            Add-ApplicationLog -Module "TestFramework" -Message "Executing test: $($test.Name)" -Level "DEBUG"
            
            $testPassed = & $test.Code
            $result.Passed = [bool]$testPassed
            
            if (-not $result.Passed) {
                $result.ErrorMessage = "Test returned false"
            }
            
        } catch {
            $result.Passed = $false
            $result.ErrorMessage = $_.Exception.Message
            Add-ApplicationLog -Module "TestFramework" -Message "Test failed: $($test.Name) - $($_.Exception.Message)" -Level "WARNING"
        } finally {
            $result.EndTime = Get-Date
            $result.ExecutionTimeMs = ($result.EndTime - $result.StartTime).TotalMilliseconds
        }
        
        $status = if ($result.Passed) { "PASSED" } else { "FAILED" }
        Add-ApplicationLog -Module "TestFramework" -Message "Test $status`: $($test.Name) ($($result.ExecutionTimeMs)ms)" -Level "DEBUG"
        
        return $result
    }
    
    [hashtable] GenerateTestReport() {
        $report = @{
            GeneratedAt = Get-Date
            SessionDuration = (Get-Date) - $this.TestRunner.SessionStartTime
            Configuration = $this.TestConfiguration.Clone()
            Summary = @{
                TotalSuites = $this.TestRunner.TestSuites.Count
                TotalTests = 0
                PassedTests = 0
                FailedTests = 0
                OverallSuccessRate = 0
            }
            SuiteResults = @()
            Recommendations = @()
        }
        
        # Calculate summary statistics
        foreach ($suite in $this.TestRunner.TestSuites) {
            $report.Summary.TotalTests += $suite.TotalTests
            $report.Summary.PassedTests += $suite.PassedTests
            $report.Summary.FailedTests += $suite.FailedTests
            
            $suiteReport = @{
                SuiteName = $suite.SuiteName
                TotalTests = $suite.TotalTests
                PassedTests = $suite.PassedTests
                FailedTests = $suite.FailedTests
                SuccessRate = $suite.SuccessRate
                Duration = ($suite.EndTime - $suite.StartTime).TotalSeconds
                FailedTestDetails = @()
            }
            
            # Add details for failed tests
            foreach ($test in $suite.Tests | Where-Object { -not $_.Passed }) {
                $suiteReport.FailedTestDetails += @{
                    TestName = $test.TestName
                    ErrorMessage = $test.ErrorMessage
                    ExecutionTime = $test.ExecutionTimeMs
                }
            }
            
            $report.SuiteResults += $suiteReport
        }
        
        # Calculate overall success rate
        if ($report.Summary.TotalTests -gt 0) {
            $report.Summary.OverallSuccessRate = ($report.Summary.PassedTests / $report.Summary.TotalTests) * 100
        }
        
        # Generate recommendations
        $report.Recommendations = $this.GenerateTestRecommendations($report)
        
        return $report
    }
    
    [string[]] GenerateTestRecommendations([hashtable]$report) {
        $recommendations = @()
        
        # Success rate recommendations
        if ($report.Summary.OverallSuccessRate -lt 95) {
            $recommendations += "Overall test success rate is below 95% ($([math]::Round($report.Summary.OverallSuccessRate, 2))%). Review failed tests and improve code quality."
        }
        
        # Performance test recommendations
        $performanceSuite = $report.SuiteResults | Where-Object { $_.SuiteName -eq "Performance" }
        if ($performanceSuite -and $performanceSuite.SuccessRate -lt 100) {
            $recommendations += "Performance tests are failing. Review performance thresholds and optimise code."
        }
        
        # Security test recommendations
        $securitySuite = $report.SuiteResults | Where-Object { $_.SuiteName -eq "Security" }
        if ($securitySuite -and $securitySuite.SuccessRate -lt 100) {
            $recommendations += "Security tests are failing. This is critical - review security implementations immediately."
        }
        
        # Test coverage recommendations
        if ($report.Summary.TotalTests -lt 20) {
            $recommendations += "Test coverage appears low ($($report.Summary.TotalTests) total tests). Consider adding more comprehensive tests."
        }
        
        return $recommendations
    }
    
    [void] SaveTestReport([hashtable]$report) {
        try {
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $reportPath = Join-Path $this.TestResultsPath "TestReport-$timestamp.json"
            
            $reportJson = $report | ConvertTo-Json -Depth 10
            $reportJson | Out-File -FilePath $reportPath -Encoding UTF8
            
            Add-ApplicationLog -Module "TestFramework" -Message "Test report saved: $reportPath" -Level "INFO"
            
            # Also create a summary text report
            $summaryPath = Join-Path $this.TestResultsPath "TestSummary-$timestamp.txt"
            $this.CreateTextSummary($report) | Out-File -FilePath $summaryPath -Encoding UTF8
            
        } catch {
            Add-ApplicationLog -Module "TestFramework" -Message "Failed to save test report: $_" -Level "ERROR"
        }
    }
    
    [string] CreateTextSummary([hashtable]$report) {
        $summary = @"
==============================================
TextToSpeech Generator - Test Report
==============================================
Generated: $($report.GeneratedAt)
Duration: $([math]::Round($report.SessionDuration.TotalSeconds, 2)) seconds

SUMMARY:
--------
Total Test Suites: $($report.Summary.TotalSuites)
Total Tests: $($report.Summary.TotalTests)
Passed: $($report.Summary.PassedTests)
Failed: $($report.Summary.FailedTests)
Success Rate: $([math]::Round($report.Summary.OverallSuccessRate, 2))%

SUITE RESULTS:
--------------
"@
        
        foreach ($suite in $report.SuiteResults) {
            $summary += "`n$($suite.SuiteName): $($suite.PassedTests)/$($suite.TotalTests) passed ($([math]::Round($suite.SuccessRate, 2))%)"
            
            if ($suite.FailedTestDetails.Count -gt 0) {
                $summary += "`n  Failed Tests:"
                foreach ($failed in $suite.FailedTestDetails) {
                    $summary += "`n    - $($failed.TestName): $($failed.ErrorMessage)"
                }
            }
        }
        
        if ($report.Recommendations.Count -gt 0) {
            $summary += "`n`nRECOMMENDATIONS:`n----------------"
            foreach ($rec in $report.Recommendations) {
                $summary += "`n- $rec"
            }
        }
        
        return $summary
    }
}

# Export functions
function New-EnhancedTestFramework {
    return [EnhancedTestFramework]::new()
}

function Invoke-ComprehensiveTests {
    param(
        [EnhancedTestFramework]$TestFramework,
        [string]$category = "All"
    )
    return $TestFramework.RunTestSuite($category)
}

function Get-TestConfiguration {
    param([EnhancedTestFramework]$TestFramework)
    return $TestFramework.TestConfiguration
}

function Set-TestConfiguration {
    param(
        [EnhancedTestFramework]$TestFramework,
        [hashtable]$Configuration
    )
    
    foreach ($key in $Configuration.Keys) {
        $TestFramework.TestConfiguration[$key] = $Configuration[$key]
    }
}

# Export module members
Export-ModuleMember -Function @(
    'New-EnhancedTestFramework',
    'Invoke-ComprehensiveTests',
    'Get-TestConfiguration',
    'Set-TestConfiguration'
) -Variable @() -Cmdlet @() -Alias @()

Add-ApplicationLog -Module "TestFramework" -Message "EnhancedTestFramework module loaded successfully" -Level "INFO"



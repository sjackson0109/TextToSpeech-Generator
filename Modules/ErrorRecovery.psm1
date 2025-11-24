using module .\CircuitBreaker.psm1
using module .\ErrorHandling.psm1

# Advanced Error Recovery Module for TextToSpeech Generator
# Provider-specific recovery strategies and intelligent error handling
# Integrated with AdvancedResilience for enterprise-grade error handling

class AdvancedErrorRecovery {
    [hashtable] $RecoveryStrategies
    [hashtable] $ErrorPatterns
    [hashtable] $RecoveryHistory
    [hashtable] $CircuitBreakers
    [hashtable] $ProviderHealthMonitors
    [int] $MaxRecoveryAttempts
    
    AdvancedErrorRecovery() {
        $this.RecoveryStrategies = @{}
        $this.ErrorPatterns = @{}
        $this.RecoveryHistory = @{}
        $this.CircuitBreakers = @{}
        $this.ProviderHealthMonitors = @{}
        $this.MaxRecoveryAttempts = 3
        $this.InitialiseDefaultStrategies()
        $this.InitialiseErrorPatterns()
        $this.InitialiseCircuitBreakers()
    }
    
    [void] InitialiseDefaultStrategies() {
        # Azure-specific recovery strategies
        $this.RegisterRecoveryStrategy("AzureRateLimit", {
            param($context)
            Add-ApplicationLog -Message "Azure rate limit detected - implementing backoff strategy" -Level "WARNING"
            Start-Sleep -Seconds 30
            return @{ Success = $true; Action = "Backoff applied" }
        })
        
        $this.RegisterRecoveryStrategy("AzureAuthFailure", {
            param($context)
            Add-ApplicationLog -Message "Azure authentication failure - checking token expiry" -Level "WARNING"
            # In a full implementation, this would refresh the token
            return @{ Success = $false; Action = "Token refresh needed"; RequiresManualIntervention = $true }
        })
        
        $this.RegisterRecoveryStrategy("AzureRegionUnavailable", {
            param($context)
            Add-ApplicationLog -Message "Azure region unavailable - attempting region failover" -Level "WARNING"
            $fallbackRegions = @("eastus", "westus", "westeurope", "southeastasia")
            $currentRegion = $context.Configuration.Region
            
            foreach ($region in $fallbackRegions) {
                if ($region -ne $currentRegion) {
                    $context.Configuration.Region = $region
                    Add-ApplicationLog -Message "Failing over to region: $region" -Level "INFO"
                    return @{ Success = $true; Action = "Region failover to $region"; NewConfiguration = $context.Configuration }
                }
            }
            
            return @{ Success = $false; Action = "No available fallback regions" }
        })
        
        # Google Cloud recovery strategies
        $this.RegisterRecoveryStrategy("GoogleQuotaExceeded", {
            param($context)
            Add-ApplicationLog -Message "Google Cloud quota exceeded - checking alternative providers" -Level "WARNING"
            # Switch to backup provider if available
            $backupProviders = @("Azure Cognitive Services", "AWS Polly")
            foreach ($provider in $backupProviders) {
                if ($context.AvailableProviders -contains $provider) {
                    return @{ Success = $true; Action = "Switch to backup provider"; BackupProvider = $provider }
                }
            }
            return @{ Success = $false; Action = "No backup providers available" }
        })
        
        $this.RegisterRecoveryStrategy("GoogleAPIKeyInvalid", {
            param($context)
            Add-ApplicationLog -Message "Google Cloud API key invalid - validation needed" -Level "ERROR"
            return @{ Success = $false; Action = "API key validation required"; RequiresManualIntervention = $true }
        })
        
        # Network-related recovery strategies
        $this.RegisterRecoveryStrategy("NetworkTimeout", {
            param($context)
            Add-ApplicationLog -Message "Network timeout detected - testing connectivity and retrying" -Level "WARNING"
            
            # Test basic connectivity
            try {
                $testResult = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet
                if ($testResult) {
                    Start-Sleep -Seconds 5
                    return @{ Success = $true; Action = "Network connectivity restored" }
                }
            } catch {
                # Network test failed
            }
            
            return @{ Success = $false; Action = "Network connectivity issues persist" }
        })
        
        $this.RegisterRecoveryStrategy("DNSResolutionFailure", {
            param($context)
            Add-ApplicationLog -Message "DNS resolution failure - attempting DNS flush and retry" -Level "WARNING"
            
            try {
                # Flush DNS cache (requires elevated privileges)
                Start-Process -FilePath "ipconfig" -ArgumentList "/flushdns" -NoNewWindow -Wait -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                return @{ Success = $true; Action = "DNS cache flushed" }
            } catch {
                return @{ Success = $false; Action = "Cannot flush DNS cache - may require elevated privileges" }
            }
        })
        
        # General recovery strategies
        $this.RegisterRecoveryStrategy("ServiceUnavailable", {
            param($context)
            Add-ApplicationLog -Message "Service unavailable - implementing exponential backoff" -Level "WARNING"
            
            $attempt = if ($context.AttemptNumber) { $context.AttemptNumber } else { 1 }
            $delay = [Math]::Min(300, [Math]::Pow(2, $attempt) * 5) # Max 5 minutes
            
            Add-ApplicationLog -Message "Waiting $delay seconds before retry (attempt $attempt)" -Level "INFO"
            Start-Sleep -Seconds $delay
            
            return @{ Success = $true; Action = "Exponential backoff applied"; DelayApplied = $delay }
        })
    }
    
    [void] InitialiseCircuitBreakers() {
        # Initialise circuit breakers for each TTS provider
        $providers = @("Azure", "AWSPolly", "GoogleCloud", "Twilio", "VoiceForge", "VoiceWare")
        
        foreach ($provider in $providers) {
            $circuitBreaker = [CircuitBreaker]::new($provider)
            $circuitBreaker.FailureThreshold = 5
            
            $this.CircuitBreakers[$provider] = $circuitBreaker
            
            # Initialise health monitor for each provider
            $healthMonitor = @{
                Provider = $provider
                LastHealthCheck = $null
                IsHealthy = $true
                ConsecutiveFailures = 0
                LastFailureTime = $null
                HealthCheckInterval = 300  # 5 minutes
                MaxConsecutiveFailures = 3
            }
            $this.ProviderHealthMonitors[$provider] = $healthMonitor
        }
    }
    
    [void] InitialiseErrorPatterns() {
        # Define error patterns and their corresponding recovery strategies
        $this.ErrorPatterns = @{
            # Azure patterns
            "TooManyRequests|429|rate.*limit" = "AzureRateLimit"
            "Unauthorized|401|invalid.*key|authentication.*failed" = "AzureAuthFailure"
            "region.*unavailable|503.*region" = "AzureRegionUnavailable"
            
            # Google Cloud patterns
            "quota.*exceeded|quotaExceeded" = "GoogleQuotaExceeded"
            "API.*key.*invalid|INVALID_ARGUMENT.*key" = "GoogleAPIKeyInvalid"
            
            # Network patterns
            "timeout|timed.*out|request.*timeout" = "NetworkTimeout"
            "dns.*resolution|name.*resolution|could.*not.*resolve" = "DNSResolutionFailure"
            "service.*unavailable|503|server.*unavailable" = "ServiceUnavailable"
        }
    }
    
    [void] RegisterRecoveryStrategy([string]$errorType, [scriptblock]$strategy) {
        $this.RecoveryStrategies[$errorType] = $strategy
        Add-ApplicationLog -Message "Registered recovery strategy for: $errorType" -Level "DEBUG"
    }
    
    [string] IdentifyErrorPattern([string]$errorMessage) {
        foreach ($pattern in $this.ErrorPatterns.Keys) {
            if ($errorMessage -match $pattern) {
                return $this.ErrorPatterns[$pattern]
            }
        }
        return "Generic"
    }
    
    [bool] IsProviderHealthy([string]$provider) {
        if (-not $this.ProviderHealthMonitors.ContainsKey($provider)) {
            return $true  # Unknown provider, assume healthy
        }
        
        $monitor = $this.ProviderHealthMonitors[$provider]
        $now = Get-Date
        
        # Check if health check is due
        if ($monitor.LastHealthCheck -eq $null -or 
            ($now - $monitor.LastHealthCheck).TotalSeconds -gt $monitor.HealthCheckInterval) {
            $this.PerformHealthCheck($provider)
        }
        
        return $monitor.IsHealthy
    }
    
    [void] PerformHealthCheck([string]$provider) {
        try {
            $monitor = $this.ProviderHealthMonitors[$provider]
            $healthResult = Invoke-ProviderHealthCheck -Provider $provider -CheckLevel "Basic"
            
            if ($healthResult.IsHealthy) {
                $monitor.IsHealthy = $true
                $monitor.ConsecutiveFailures = 0
                $monitor.LastFailureTime = $null
                Add-ApplicationLog -Message "Provider $provider health check passed" -Level "DEBUG"
            } else {
                $monitor.ConsecutiveFailures++
                $monitor.LastFailureTime = Get-Date
                
                if ($monitor.ConsecutiveFailures -ge $monitor.MaxConsecutiveFailures) {
                    $monitor.IsHealthy = $false
                    Add-ApplicationLog -Message "Provider $provider marked as unhealthy after $($monitor.ConsecutiveFailures) consecutive failures" -Level "WARNING"
                    
                    # Send operational alert
                    Send-OperationalAlert -AlertType "ProviderHealth" -Provider $provider -Message "Provider marked unhealthy"
                }
            }
            
            $monitor.LastHealthCheck = Get-Date
        } catch {
            Add-ApplicationLog -Message "Health check failed for provider $provider`: $_" -Level "ERROR"
        }
    }
    
    [hashtable] AttemptRecovery([object]$error, [hashtable]$context) {
        $errorMessage = if ($error -is [System.Exception]) { $error.Message } else { $error.ToString() }
        $errorType = $this.IdentifyErrorPattern($errorMessage)
        $provider = if ($context.Provider) { $context.Provider } else { 'Unknown' }
        
        # Check circuit breaker state for the provider
        if ($this.CircuitBreakers.ContainsKey($provider)) {
            $circuitBreaker = $this.CircuitBreakers[$provider]
            if ($circuitBreaker.State -eq 'Open') {
                Add-ApplicationLog -Message "Circuit breaker is OPEN for provider $provider - preventing recovery attempt" -Level "WARNING"
                return @{
                    Success = $false
                    Action = "Circuit breaker is open - provider temporarily disabled"
                    ErrorType = $errorType
                    Provider = $provider
                    CircuitBreakerState = 'Open'
                    RecommendAlternativeProvider = $true
                }
            }
        }
        
        # Check provider health before attempting recovery
        if (-not $this.IsProviderHealthy($provider)) {
            Add-ApplicationLog -Message "Provider $provider is unhealthy - skipping recovery attempt" -Level "WARNING"
            return @{
                Success = $false
                Action = "Provider is marked as unhealthy"
                ErrorType = $errorType
                Provider = $provider
                RecommendAlternativeProvider = $true
            }
        }
        
        # Check recovery history to prevent infinite loops
        $errorKey = "$provider-$errorType"
        if (-not $this.RecoveryHistory.ContainsKey($errorKey)) {
            $this.RecoveryHistory[$errorKey] = @{ Count = 0; LastAttempt = [DateTime]::MinValue }
        }
        
        $history = $this.RecoveryHistory[$errorKey]
        $timeSinceLastAttempt = (Get-Date) - $history.LastAttempt
        
        # Reset count if enough time has passed (1 hour)
        if ($timeSinceLastAttempt.TotalHours -ge 1) {
            $history.Count = 0
        }
        
        # Check if we've exceeded max attempts
        if ($history.Count -ge $this.MaxRecoveryAttempts) {
            return @{
                Success = $false
                Action = "Max recovery attempts exceeded"
                ErrorType = $errorType
                AttemptCount = $history.Count
                RecommendManualIntervention = $true
            }
        }
        
        # Update history
        $history.Count++
        $history.LastAttempt = Get-Date
        $context.AttemptNumber = $history.Count
        
        Add-ApplicationLog -Message "Attempting recovery for error type: $errorType (attempt $($history.Count))" -Level "INFO"
        
        # Execute recovery strategy with advanced retry logic
        if ($this.RecoveryStrategies.ContainsKey($errorType)) {
            try {
                # Use AdvancedResilience for retry logic
                $retryParams = @{
                    ScriptBlock = { 
                        param($ctx)
                        return & $this.RecoveryStrategies[$errorType] $ctx
                    }
                    MaxAttempts = 3
                    BackoffStrategy = 'Exponential'
                    BaseDelaySeconds = 2
                    MaxDelaySeconds = 60
                    Arguments = @($context)
                }
                
                $result = Start-AdvancedRetry @retryParams
                
                # Record the result with circuit breaker
                if ($this.CircuitBreakers.ContainsKey($provider)) {
                    if ($result.Success) {
                        $this.CircuitBreakers[$provider].RecordSuccess()
                    } else {
                        $this.CircuitBreakers[$provider].RecordFailure()
                    }
                }
                
                $result.ErrorType = $errorType
                $result.AttemptCount = $history.Count
                $result.Provider = $provider
                
                $this.LogRecoveryAttempt($errorType, $result.Success, $result.Action)
                return $result
                
            } catch {
                # Record failure with circuit breaker
                if ($this.CircuitBreakers.ContainsKey($provider)) {
                    $this.CircuitBreakers[$provider].RecordFailure()
                }
                
                $this.LogRecoveryAttempt($errorType, $false, "Recovery strategy failed: $($_.Exception.Message)")
                return @{
                    Success = $false
                    Action = "Recovery strategy execution failed"
                    ErrorType = $errorType
                    AttemptCount = $history.Count
                    Provider = $provider
                    Exception = $_.Exception.Message
                    RecommendManualIntervention = $true
                }
            }
        } else {
            # No specific strategy available - try generic recovery with circuit breaker
            Add-ApplicationLog -Message "No specific recovery strategy for $errorType - attempting generic recovery" -Level "INFO"
            
            try {
                $genericResult = $this.AttemptGenericRecovery($error, $context)
                
                # Record the result with circuit breaker
                if ($this.CircuitBreakers.ContainsKey($provider)) {
                    if ($genericResult.Success) {
                        $this.CircuitBreakers[$provider].RecordSuccess()
                    } else {
                        $this.CircuitBreakers[$provider].RecordFailure()
                    }
                }
                
                $genericResult.ErrorType = $errorType
                $genericResult.AttemptCount = $history.Count
                $genericResult.Provider = $provider
                
                $this.LogRecoveryAttempt($errorType, $genericResult.Success, $genericResult.Action)
                return $genericResult
                
            } catch {
                if ($this.CircuitBreakers.ContainsKey($provider)) {
                    $this.CircuitBreakers[$provider].RecordFailure()
                }
                
                $this.LogRecoveryAttempt($errorType, $false, "Generic recovery failed")
                return @{
                    Success = $false
                    Action = "No recovery strategy available and generic recovery failed"
                    ErrorType = $errorType
                    AttemptCount = $history.Count
                    Provider = $provider
                    RecommendManualIntervention = $true
                }
            }
        }
    }
    
    [hashtable] AttemptGenericRecovery([object]$error, [hashtable]$context) {
        Add-ApplicationLog -Message "Attempting generic recovery strategies" -Level "INFO"
        
        # Strategy 1: Wait and retry
        Start-Sleep -Seconds 5
        
        # Strategy 2: Test basic connectivity if it's a network-related error
        $errorMessage = if ($error -is [System.Exception]) { $error.Message } else { $error.ToString() }
        if ($errorMessage -match "timeout|network|connection|dns") {
            try {
                $networkTest = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet
                if (-not $networkTest) {
                    return @{
                        Success = $false
                        Action = "Network connectivity test failed"
                        RecommendManualIntervention = $true
                    }
                }
            } catch {
                return @{
                    Success = $false
                    Action = "Unable to perform network connectivity test"
                    RecommendManualIntervention = $true
                }
            }
        }
        
        # Strategy 3: Provider failover if alternative providers are available
        if ($context.AvailableProviders -and $context.AvailableProviders.Count -gt 1) {
            $currentProvider = $context.Provider
            $alternativeProviders = $context.AvailableProviders | Where-Object { $_ -ne $currentProvider }
            
            foreach ($altProvider in $alternativeProviders) {
                if ($this.IsProviderHealthy($altProvider)) {
                    return @{
                        Success = $true
                        Action = "Failover to alternative provider: $altProvider"
                        AlternativeProvider = $altProvider
                        RequiresProviderSwitch = $true
                    }
                }
            }
        }
        
        return @{
            Success = $false
            Action = "Generic recovery strategies exhausted"
            RecommendManualIntervention = $true
        }
    }
    
    [string[]] GetHealthyProviders() {
        $healthyProviders = @()
        
        foreach ($provider in $this.ProviderHealthMonitors.Keys) {
            if ($this.IsProviderHealthy($provider)) {
                $healthyProviders += $provider
            }
        }
        
        return $healthyProviders
    }
    
    [hashtable] GetProviderStatus([string]$provider) {
        if (-not $this.ProviderHealthMonitors.ContainsKey($provider)) {
            return @{
                Provider = $provider
                Status = "Unknown"
                IsHealthy = $null
                CircuitBreakerState = "Unknown"
            }
        }
        
        $monitor = $this.ProviderHealthMonitors[$provider]
        $circuitBreakerState = if ($this.CircuitBreakers.ContainsKey($provider)) {
            $this.CircuitBreakers[$provider].State
        } else {
            "Unknown"
        }
        
        return @{
            Provider = $provider
            IsHealthy = $monitor.IsHealthy
            ConsecutiveFailures = $monitor.ConsecutiveFailures
            LastHealthCheck = $monitor.LastHealthCheck
            LastFailureTime = $monitor.LastFailureTime
            CircuitBreakerState = $circuitBreakerState
            Status = if ($monitor.IsHealthy) { "Healthy" } else { "Unhealthy" }
        }
    }
    
    [void] ResetProviderHealth([string]$provider) {
        if ($this.ProviderHealthMonitors.ContainsKey($provider)) {
            $monitor = $this.ProviderHealthMonitors[$provider]
            $monitor.IsHealthy = $true
            $monitor.ConsecutiveFailures = 0
            $monitor.LastFailureTime = $null
            $monitor.LastHealthCheck = $null
            
            Add-ApplicationLog -Message "Reset health status for provider: $provider" -Level "INFO"
        }
        
        if ($this.CircuitBreakers.ContainsKey($provider)) {
            $this.CircuitBreakers[$provider].Reset()
            Add-ApplicationLog -Message "Reset circuit breaker for provider: $provider" -Level "INFO"
        }
    }
    
    [void] LogRecoveryAttempt([string]$errorType, [bool]$success, [string]$action) {
        $level = if ($success) { "INFO" } else { "WARNING" }
        $status = if ($success) { "Successful" } else { "Failed" }
        
        Add-ApplicationLog -Message "Recovery attempt $status for $errorType`: $action" -Level $level -Category "ErrorRecovery"
    }
    
    [hashtable] GetRecoveryStatistics() {
        $stats = @{
            TotalRecoveryAttempts = 0
            SuccessfulRecoveries = 0
            ErrorTypeBreakdown = @{}
            MostCommonErrors = @()
        }
        
        foreach ($key in $this.RecoveryHistory.Keys) {
            $stats.TotalRecoveryAttempts += $this.RecoveryHistory[$key].Count
            
            $errorType = $key.Split('-')[1]
            if (-not $stats.ErrorTypeBreakdown.ContainsKey($errorType)) {
                $stats.ErrorTypeBreakdown[$errorType] = 0
            }
            $stats.ErrorTypeBreakdown[$errorType] += $this.RecoveryHistory[$key].Count
        }
        
        # Sort errors by frequency
        $stats.MostCommonErrors = $stats.ErrorTypeBreakdown.GetEnumerator() | 
            Sort-Object Value -Descending | 
            Select-Object -First 5 | 
            ForEach-Object { @{ ErrorType = $_.Key; Count = $_.Value } }
        
        return $stats
    }
}

# Enhanced retry logic with recovery integration
function Invoke-APIWithAdvancedRecovery {
    <#
    .SYNOPSIS
    Enhanced API retry with intelligent error recovery
    #>
    param(
        [Parameter(Mandatory=$true)][scriptblock]$ScriptBlock,
        [hashtable]$Context = @{},
        [int]$MaxRetries = 3,
        [int]$BaseDelayMs = 1000,
        [string]$Provider = "Unknown"
    )
    
    if (-not $Global:ErrorRecoveryManager) {
        $Global:ErrorRecoveryManager = [AdvancedErrorRecovery]::new()
    }
    
    $attempt = 0
    $lastException = $null
    $context = $Context.Clone()
    $context.Provider = $Provider
    
    while ($attempt -le $MaxRetries) {
        try {
            Add-ApplicationLog -Message "Advanced API call attempt $($attempt + 1)/$($MaxRetries + 1) for $Provider" -Level "DEBUG"
            return & $ScriptBlock
        }
        catch {
            $lastException = $_
            $attempt++
            
            Add-ApplicationLog -Message "$Provider API call failed: $($_.Exception.Message)" -Level "WARNING"
            
            if ($attempt -le $MaxRetries) {
                # Attempt intelligent recovery
                $recoveryResult = $Global:ErrorRecoveryManager.AttemptRecovery($_.Exception, $context)
                
                if ($recoveryResult.Success) {
                    Add-ApplicationLog -Message "Recovery successful: $($recoveryResult.Action)" -Level "INFO"
                    
                    # Update context if recovery provided new configuration
                    if ($recoveryResult.NewConfiguration) {
                        $context = $recoveryResult.NewConfiguration
                    }
                    
                    # If recovery suggests switching providers, return that information
                    if ($recoveryResult.BackupProvider) {
                        throw [System.InvalidOperationException]::new("SWITCH_PROVIDER:$($recoveryResult.BackupProvider)")
                    }
                    
                    # Continue with next attempt (recovery may have applied delays)
                } else {
                    Add-ApplicationLog -Message "Recovery failed: $($recoveryResult.Action)" -Level "ERROR"
                    
                    if ($recoveryResult.RecommendManualIntervention) {
                        Add-ApplicationLog -Message "Manual intervention recommended for $Provider" -Level "ERROR"
                        break
                    }
                    
                    # Apply standard exponential backoff if recovery didn't handle delay
                    if (-not $recoveryResult.DelayApplied) {
                        $delay = $BaseDelayMs * [Math]::Pow(2, $attempt - 1)
                        Add-ApplicationLog -Message "Applying standard backoff: ${delay}ms" -Level "INFO"
                        Start-Sleep -Milliseconds $delay
                    }
                }
            }
        }
    }
    
    Add-ApplicationLog -Message "$Provider API call failed after $($MaxRetries + 1) attempts with advanced recovery" -Level "ERROR"
    throw $lastException
}

function Get-ErrorRecoveryStatistics {
    <#
    .SYNOPSIS
    Returns statistics about error recovery attempts
    #>
    if ($Global:ErrorRecoveryManager) {
        return $Global:ErrorRecoveryManager.GetRecoveryStatistics()
    } else {
        return @{
            TotalRecoveryAttempts = 0
            Message = "Error recovery manager not initialised"
        }
    }
}

function Reset-ErrorRecoveryHistory {
    <#
    .SYNOPSIS
    Resets the error recovery history
    #>
    if ($Global:ErrorRecoveryManager) {
        $Global:ErrorRecoveryManager.RecoveryHistory.Clear()
        Add-ApplicationLog -Message "Error recovery history reset" -Level "INFO"
    }
}

function Register-CustomRecoveryStrategy {
    <#
    .SYNOPSIS
    Registers a custom error recovery strategy
    #>
    param(
        [Parameter(Mandatory=$true)][string]$ErrorType,
        [Parameter(Mandatory=$true)][scriptblock]$Strategy
    )
    
    if (-not $Global:ErrorRecoveryManager) {
        $Global:ErrorRecoveryManager = [AdvancedErrorRecovery]::new()
    }
    
    $Global:ErrorRecoveryManager.RegisterRecoveryStrategy($ErrorType, $Strategy)
    Add-ApplicationLog -Message "Registered custom recovery strategy for: $ErrorType" -Level "INFO"
}

# Export functions
Export-ModuleMember -Function @(
    'Invoke-APIWithAdvancedRecovery',
    'Get-ErrorRecoveryStatistics',
    'Reset-ErrorRecoveryHistory',
    'Register-CustomRecoveryStrategy'
)

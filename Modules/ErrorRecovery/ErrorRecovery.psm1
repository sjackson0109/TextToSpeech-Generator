# Advanced Error Recovery Module for TextToSpeech Generator v3.2
# Provider-specific recovery strategies and intelligent error handling

class AdvancedErrorRecovery {
    [hashtable] $RecoveryStrategies
    [hashtable] $ErrorPatterns
    [hashtable] $RecoveryHistory
    [int] $MaxRecoveryAttempts
    
    AdvancedErrorRecovery() {
        $this.RecoveryStrategies = @{}
        $this.ErrorPatterns = @{}
        $this.RecoveryHistory = @{}
        $this.MaxRecoveryAttempts = 3
        $this.InitializeDefaultStrategies()
        $this.InitializeErrorPatterns()
    }
    
    [void] InitializeDefaultStrategies() {
        # Azure-specific recovery strategies
        $this.RegisterRecoveryStrategy("AzureRateLimit", {
            param($context)
            Write-ApplicationLog -Message "Azure rate limit detected - implementing backoff strategy" -Level "WARNING"
            Start-Sleep -Seconds 30
            return @{ Success = $true; Action = "Backoff applied" }
        })
        
        $this.RegisterRecoveryStrategy("AzureAuthFailure", {
            param($context)
            Write-ApplicationLog -Message "Azure authentication failure - checking token expiry" -Level "WARNING"
            # In a full implementation, this would refresh the token
            return @{ Success = $false; Action = "Token refresh needed"; RequiresManualIntervention = $true }
        })
        
        $this.RegisterRecoveryStrategy("AzureRegionUnavailable", {
            param($context)
            Write-ApplicationLog -Message "Azure region unavailable - attempting region failover" -Level "WARNING"
            $fallbackRegions = @("eastus", "westus", "westeurope", "southeastasia")
            $currentRegion = $context.Configuration.Region
            
            foreach ($region in $fallbackRegions) {
                if ($region -ne $currentRegion) {
                    $context.Configuration.Region = $region
                    Write-ApplicationLog -Message "Failing over to region: $region" -Level "INFO"
                    return @{ Success = $true; Action = "Region failover to $region"; NewConfiguration = $context.Configuration }
                }
            }
            
            return @{ Success = $false; Action = "No available fallback regions" }
        })
        
        # Google Cloud recovery strategies
        $this.RegisterRecoveryStrategy("GoogleQuotaExceeded", {
            param($context)
            Write-ApplicationLog -Message "Google Cloud quota exceeded - checking alternative providers" -Level "WARNING"
            # Switch to backup provider if available
            $backupProviders = @("Microsoft Azure", "AWS Polly")
            foreach ($provider in $backupProviders) {
                if ($context.AvailableProviders -contains $provider) {
                    return @{ Success = $true; Action = "Switch to backup provider"; BackupProvider = $provider }
                }
            }
            return @{ Success = $false; Action = "No backup providers available" }
        })
        
        $this.RegisterRecoveryStrategy("GoogleAPIKeyInvalid", {
            param($context)
            Write-ApplicationLog -Message "Google Cloud API key invalid - validation needed" -Level "ERROR"
            return @{ Success = $false; Action = "API key validation required"; RequiresManualIntervention = $true }
        })
        
        # Network-related recovery strategies
        $this.RegisterRecoveryStrategy("NetworkTimeout", {
            param($context)
            Write-ApplicationLog -Message "Network timeout detected - testing connectivity and retrying" -Level "WARNING"
            
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
            Write-ApplicationLog -Message "DNS resolution failure - attempting DNS flush and retry" -Level "WARNING"
            
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
            Write-ApplicationLog -Message "Service unavailable - implementing exponential backoff" -Level "WARNING"
            
            $attempt = if ($context.AttemptNumber) { $context.AttemptNumber } else { 1 }
            $delay = [Math]::Min(300, [Math]::Pow(2, $attempt) * 5) # Max 5 minutes
            
            Write-ApplicationLog -Message "Waiting $delay seconds before retry (attempt $attempt)" -Level "INFO"
            Start-Sleep -Seconds $delay
            
            return @{ Success = $true; Action = "Exponential backoff applied"; DelayApplied = $delay }
        })
    }
    
    [void] InitializeErrorPatterns() {
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
        Write-ApplicationLog -Message "Registered recovery strategy for: $errorType" -Level "DEBUG"
    }
    
    [string] IdentifyErrorPattern([string]$errorMessage) {
        foreach ($pattern in $this.ErrorPatterns.Keys) {
            if ($errorMessage -match $pattern) {
                return $this.ErrorPatterns[$pattern]
            }
        }
        return "Generic"
    }
    
    [hashtable] AttemptRecovery([object]$error, [hashtable]$context) {
        $errorMessage = if ($error -is [System.Exception]) { $error.Message } else { $error.ToString() }
        $errorType = $this.IdentifyErrorPattern($errorMessage)
        
        # Check recovery history to prevent infinite loops
        $errorKey = "$(if ($context.Provider) { $context.Provider } else { 'Unknown' })-$errorType"
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
        
        Write-ApplicationLog -Message "Attempting recovery for error type: $errorType (attempt $($history.Count))" -Level "INFO"
        
        # Execute recovery strategy
        if ($this.RecoveryStrategies.ContainsKey($errorType)) {
            try {
                $result = & $this.RecoveryStrategies[$errorType] $context
                $result.ErrorType = $errorType
                $result.AttemptCount = $history.Count
                
                $this.LogRecoveryAttempt($errorType, $result.Success, $result.Action)
                return $result
            } catch {
                $this.LogRecoveryAttempt($errorType, $false, "Recovery strategy failed: $($_.Exception.Message)")
                return @{
                    Success = $false
                    Action = "Recovery strategy execution failed"
                    ErrorType = $errorType
                    AttemptCount = $history.Count
                    Exception = $_.Exception.Message
                }
            }
        } else {
            # No specific strategy, use generic approach
            $this.LogRecoveryAttempt($errorType, $false, "No specific recovery strategy available")
            return @{
                Success = $false
                Action = "No recovery strategy available for error type: $errorType"
                ErrorType = $errorType
                AttemptCount = $history.Count
                RecommendManualIntervention = $true
            }
        }
    }
    
    [void] LogRecoveryAttempt([string]$errorType, [bool]$success, [string]$action) {
        $level = if ($success) { "INFO" } else { "WARNING" }
        $status = if ($success) { "Successful" } else { "Failed" }
        
        Write-ApplicationLog -Message "Recovery attempt $status for $errorType`: $action" -Level $level -Category "ErrorRecovery"
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
            Write-ApplicationLog -Message "Advanced API call attempt $($attempt + 1)/$($MaxRetries + 1) for $Provider" -Level "DEBUG"
            return & $ScriptBlock
        }
        catch {
            $lastException = $_
            $attempt++
            
            Write-ApplicationLog -Message "$Provider API call failed: $($_.Exception.Message)" -Level "WARNING"
            
            if ($attempt -le $MaxRetries) {
                # Attempt intelligent recovery
                $recoveryResult = $Global:ErrorRecoveryManager.AttemptRecovery($_.Exception, $context)
                
                if ($recoveryResult.Success) {
                    Write-ApplicationLog -Message "Recovery successful: $($recoveryResult.Action)" -Level "INFO"
                    
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
                    Write-ApplicationLog -Message "Recovery failed: $($recoveryResult.Action)" -Level "ERROR"
                    
                    if ($recoveryResult.RecommendManualIntervention) {
                        Write-ApplicationLog -Message "Manual intervention recommended for $Provider" -Level "ERROR"
                        break
                    }
                    
                    # Apply standard exponential backoff if recovery didn't handle delay
                    if (-not $recoveryResult.DelayApplied) {
                        $delay = $BaseDelayMs * [Math]::Pow(2, $attempt - 1)
                        Write-ApplicationLog -Message "Applying standard backoff: ${delay}ms" -Level "INFO"
                        Start-Sleep -Milliseconds $delay
                    }
                }
            }
        }
    }
    
    Write-ApplicationLog -Message "$Provider API call failed after $($MaxRetries + 1) attempts with advanced recovery" -Level "ERROR"
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
            Message = "Error recovery manager not initialized"
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
        Write-ApplicationLog -Message "Error recovery history reset" -Level "INFO"
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
    Write-ApplicationLog -Message "Registered custom recovery strategy for: $ErrorType" -Level "INFO"
}

# Export functions
Export-ModuleMember -Function @(
    'Invoke-APIWithAdvancedRecovery',
    'Get-ErrorRecoveryStatistics',
    'Reset-ErrorRecoveryHistory',
    'Register-CustomRecoveryStrategy'
)
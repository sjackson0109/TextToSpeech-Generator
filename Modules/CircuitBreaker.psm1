# Advanced Error Handling and Resilience Module
# Implements circuit breaker pattern, advanced retry logic, and provider health monitoring
# Note: This module uses custom verbs (Initialise, Set) which are intentional for UK English consistency
# Import with -DisableNameChecking to suppress warnings

# Circuit Breaker States
enum CircuitBreakerState {
    Closed    # Normal operation
    Open      # Circuit is open, failing fast
    HalfOpen  # Testing if service has recovered
}

# Circuit breaker class for provider health management using PowerShell class
class CircuitBreaker {
    [string] $ProviderId
    [int] $FailureThreshold = 5
    [int] $SuccessThreshold = 3
    [int] $TimeoutMinutes = 10
    [int] $FailureCount = 0
    [int] $SuccessCount = 0
    [datetime] $LastFailureTime = [datetime]::MinValue
    [string] $State = "Closed"
    
    CircuitBreaker([string]$providerId) {
        $this.ProviderId = $providerId
        $this.FailureThreshold = 5
        $this.SuccessThreshold = 3
        $this.TimeoutMinutes = 10
        $this.FailureCount = 0
        $this.SuccessCount = 0
        $this.State = "Closed"
        $this.LastFailureTime = [datetime]::MinValue
    }
    
    CircuitBreaker() {
        $this.ProviderId = ""
        $this.FailureThreshold = 5
        $this.SuccessThreshold = 3
        $this.TimeoutMinutes = 10
        $this.FailureCount = 0
        $this.SuccessCount = 0
        $this.State = "Closed"
        $this.LastFailureTime = [datetime]::MinValue
    }
}

# Global circuit breakers for each provider
$script:CircuitBreakers = @{}

function New-CircuitBreaker {
    <#
    .SYNOPSIS
    Initialises circuit breaker for a TTS provider
    #>
    param(
        [Parameter(Mandatory=$true)][string]$ProviderId,
        [int]$FailureThreshold = 5,
        [int]$SuccessThreshold = 3,
        [int]$TimeoutMinutes = 10
    )
    
    if (-not $script:CircuitBreakers.ContainsKey($ProviderId)) {
        $breaker = New-Object CircuitBreaker($ProviderId)
        $breaker.FailureThreshold = $FailureThreshold
        $breaker.SuccessThreshold = $SuccessThreshold
        $breaker.TimeoutMinutes = $TimeoutMinutes
        
        $script:CircuitBreakers[$ProviderId] = $breaker
        
        Add-ApplicationLog -Message "Circuit breaker initialised for $ProviderId" -Level "INFO"
    }
}

function Test-CircuitBreakerState {
    <#
    .SYNOPSIS
    Tests current state of circuit breaker for a provider
    #>
    param(
        [Parameter(Mandatory=$true)][string]$ProviderId
    )
    
    if (-not $script:CircuitBreakers.ContainsKey($ProviderId)) {
        New-CircuitBreaker -ProviderId $ProviderId
    }
    
    $breaker = $script:CircuitBreakers[$ProviderId]
    
    switch ($breaker.State) {
        "Closed" {
            # Normal operation
            return @{ CanExecute = $true; State = "Closed"; Reason = "Circuit is closed" }
        }
        
        "Open" {
            # Check if timeout has expired
            $timeoutExpired = (Get-Date).AddMinutes(-$breaker.TimeoutMinutes) -gt $breaker.LastFailureTime
            
            if ($timeoutExpired) {
                $breaker.State = "HalfOpen"
                $breaker.SuccessCount = 0
                Add-ApplicationLog -Message "Circuit breaker for $ProviderId moved to HalfOpen state" -Level "INFO"
                return @{ CanExecute = $true; State = "HalfOpen"; Reason = "Timeout expired, testing recovery" }
            } else {
                $remainingTime = $breaker.TimeoutMinutes - ((Get-Date) - $breaker.LastFailureTime).TotalMinutes
                return @{ 
                    CanExecute = $false; 
                    State = "Open"; 
                    Reason = "Circuit is open, retry in $([Math]::Ceiling($remainingTime)) minutes" 
                }
            }
        }
        
        "HalfOpen" {
            # Allow limited testing
            return @{ CanExecute = $true; State = "HalfOpen"; Reason = "Testing service recovery" }
        }
    }
}

function Set-CircuitBreakerSuccess {
    <#
    .SYNOPSIS
    Records a successful operation for circuit breaker
    #>
    param(
        [Parameter(Mandatory=$true)][string]$ProviderId
    )
    
    if (-not $script:CircuitBreakers.ContainsKey($ProviderId)) {
        return
    }
    
    $breaker = $script:CircuitBreakers[$ProviderId]
    
    switch ($breaker.State) {
        "Closed" {
            $breaker.FailureCount = 0
        }
        
        "HalfOpen" {
            $breaker.SuccessCount++
            
            if ($breaker.SuccessCount -ge $breaker.SuccessThreshold) {
                $breaker.State = "Closed"
                $breaker.FailureCount = 0
                $breaker.SuccessCount = 0
                Add-ApplicationLog -Message "Circuit breaker for $ProviderId closed after successful recovery" -Level "INFO"
            }
        }
    }
    
    Add-ApplicationLog -Message "Success recorded for $ProviderId (State: $($breaker.State))" -Level "DEBUG"
}

function Set-CircuitBreakerFailure {
    <#
    .SYNOPSIS
    Records a failed operation for circuit breaker
    #>
    param(
        [Parameter(Mandatory=$true)][string]$ProviderId,
        [string]$ErrorMessage = ""
    )
    
    if (-not $script:CircuitBreakers.ContainsKey($ProviderId)) {
        New-CircuitBreaker -ProviderId $ProviderId
    }
    
    $breaker = $script:CircuitBreakers[$ProviderId]
    $breaker.FailureCount++
    $breaker.LastFailureTime = Get-Date
    
    # Reset success count in HalfOpen state
    if ($breaker.State -eq "HalfOpen") {
        $breaker.SuccessCount = 0
    }
    
    # Check if we should open the circuit
    if ($breaker.FailureCount -ge $breaker.FailureThreshold -and $breaker.State -ne "Open") {
        $breaker.State = "Open"
        Add-ApplicationLog -Message "Circuit breaker for $ProviderId opened due to $($breaker.FailureCount) failures" -Level "WARNING"
        
        # Trigger alert for operations team
    Send-OperationalAlert -AlertType "CircuitBreakerOpen" -ProviderId $ProviderId -Message "Provider $ProviderId circuit breaker opened after $($breaker.FailureCount) failures"
    }
    
    Add-ApplicationLog -Message "Failure recorded for $($ProviderId): $($ErrorMessage) (Failures: $($breaker.FailureCount))" -Level "DEBUG"
}

function Get-CircuitBreakerStatus {
    <#
    .SYNOPSIS
    Gets status of all circuit breakers
    #>
    
    $status = @()
    
    foreach ($providerId in $script:CircuitBreakers.Keys) {
        $breaker = $script:CircuitBreakers[$providerId]
        $status += @{
            ProviderId = $providerId
            State = $breaker.State
            FailureCount = $breaker.FailureCount
            SuccessCount = $breaker.SuccessCount
            LastFailureTime = $breaker.LastFailureTime
            FailureThreshold = $breaker.FailureThreshold
            SuccessThreshold = $breaker.SuccessThreshold
        }
    }
    
    return $status
}

function Send-OperationalAlert {
    <#
    .SYNOPSIS
    Writes operational alerts for monitoring systems
    #>
    param(
        [Parameter(Mandatory=$true)][string]$AlertType,
        [Parameter(Mandatory=$true)][string]$ProviderId,
        [Parameter(Mandatory=$true)][string]$Message
    )
    
    $alertData = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        AlertType = $AlertType
        ProviderId = $ProviderId
        Message = $Message
        Severity = "WARNING"
    }
    
    # Log as structured data for monitoring
    Add-ApplicationLog -Message "OPERATIONAL_ALERT: $($alertData | ConvertTo-Json -Compress)" -Level "WARNING"
    
    # Write to dedicated alert log if configured
    $alertLogPath = Join-Path $PSScriptRoot "alerts.log"
    try {
        $alertEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$AlertType] [$ProviderId] $Message"
        Add-Content -Path $alertLogPath -Value $alertEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Silent failure for alert logging
    }
}

# Advanced retry logic with jitter and backoff strategies
function Start-AdvancedRetry {
    <#
    .SYNOPSIS
    Advanced retry logic with circuit breaker integration and multiple backoff strategies
    #>
    param(
        [Parameter(Mandatory=$true)][scriptblock]$Operation,
        [Parameter(Mandatory=$true)][string]$ProviderId,
        [int]$MaxRetries = 3,
        [ValidateSet("Exponential", "Linear", "Fixed", "Fibonacci")]
        [string]$BackoffStrategy = "Exponential",
        [int]$BaseDelayMs = 1000,
        [double]$JitterPercent = 0.1,
        [int]$MaxDelayMs = 30000,
        [string[]]$RetriableErrors = @("timeout", "rate limit", "429", "503", "502", "500")
    )
    
    # Check circuit breaker first
    $circuitState = Test-CircuitBreakerState -ProviderId $ProviderId
    if (-not $circuitState.CanExecute) {
        throw "Circuit breaker is open for $ProviderId : $($circuitState.Reason)"
    }
    
    $attempt = 0
    $lastException = $null
    
    while ($attempt -le $MaxRetries) {
        try {
            Add-ApplicationLog -Message "[$ProviderId] Attempt $($attempt + 1)/$($MaxRetries + 1)" -Level "DEBUG"
            
            $result = & $Operation
            
            # Success - record with circuit breaker
            Set-CircuitBreakerSuccess -ProviderId $ProviderId
            return $result
        }
        catch {
            $lastException = $_
            $attempt++
            
            # Record failure with circuit breaker
            Set-CircuitBreakerFailure -ProviderId $ProviderId -ErrorMessage $_.Exception.Message
            
            # Check if error is retriable
            $isRetriable = $false
            foreach ($errorPattern in $RetriableErrors) {
                if ($_.Exception.Message -match $errorPattern) {
                    $isRetriable = $true
                    break
                }
            }
            
            # Don't retry if not retriable or max attempts reached
            if (-not $isRetriable -or $attempt -gt $MaxRetries) {
                Add-ApplicationLog -Message "[$ProviderId] Operation failed permanently: $($_.Exception.Message)" -Level "ERROR"
                throw
            }
            
            # Calculate delay with selected strategy
            $delay = switch ($BackoffStrategy) {
                "Exponential" { $BaseDelayMs * [Math]::Pow(2, $attempt - 1) }
                "Linear" { $BaseDelayMs * $attempt }
                "Fixed" { $BaseDelayMs }
                "Fibonacci" { 
                    if ($attempt -eq 1) { $BaseDelayMs }
                    elseif ($attempt -eq 2) { $BaseDelayMs }
                    else { 
                        # Simplified Fibonacci for retry delays
                        $BaseDelayMs * ($attempt + ($attempt - 1))
                    }
                }
            }
            
            # Apply jitter to prevent thundering herd
            $jitterAmount = $delay * $JitterPercent * (Get-Random -Minimum -1.0 -Maximum 1.0)
            $delay = $delay + $jitterAmount
            
            # Cap at maximum delay
            $delay = [Math]::Min($delay, $MaxDelayMs)
            
            Add-ApplicationLog -Message "[$ProviderId] Retrying in $($delay)ms (attempt $attempt): $($_.Exception.Message)" -Level "WARNING"
            Start-Sleep -Milliseconds $delay
        }
    }
    
    # If we get here, all retries failed
    throw $lastException
}

# Provider health monitoring
function Test-ProviderHealth {
    <#
    .SYNOPSIS
    Comprehensive provider health check with multiple validation levels
    #>
    param(
        [Parameter(Mandatory=$true)][string]$ProviderId,
        [hashtable]$Configuration,
        [ValidateSet("Basic", "Full", "Extended")]
        [string]$CheckLevel = "Basic"
    )
    
    $healthResult = @{
        ProviderId = $ProviderId
        IsHealthy = $false
        CheckLevel = $CheckLevel
        ResponseTime = 0
        Checks = @()
        CircuitBreakerState = "Unknown"
        LastChecked = Get-Date
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Get circuit breaker state
        $circuitState = Test-CircuitBreakerState -ProviderId $ProviderId
        $healthResult.CircuitBreakerState = $circuitState.State
        
        # Basic connectivity check
        $connectivityResult = Test-APIConnectivity -Provider $ProviderId -Configuration $Configuration
        $healthResult.Checks += @{
            Name = "Connectivity"
            Status = if ($connectivityResult.IsConnected) { "Pass" } else { "Fail" }
            Details = $connectivityResult.ErrorMessage
            ResponseTime = $connectivityResult.ResponseTime
        }
        
        if ($CheckLevel -in @("Full", "Extended")) {
            # Configuration validation
            $configValidation = Test-ConfigurationValid -Provider $ProviderId -Configuration $Configuration
            $healthResult.Checks += @{
                Name = "Configuration"
                Status = if ($configValidation.IsValid) { "Pass" } else { "Fail" }
                Details = ($configValidation.Errors -join "; ")
            }
            
            # Rate limiting check (if Extended)
            if ($CheckLevel -eq "Extended") {
                try {
                    # Attempt a minimal API call to test rate limits
                    $rateLimitResult = Test-ProviderRateLimit -ProviderId $ProviderId -Configuration $Configuration
                    $healthResult.Checks += @{
                        Name = "RateLimit"
                        Status = if ($rateLimitResult.WithinLimits) { "Pass" } else { "Warning" }
                        Details = "Remaining: $($rateLimitResult.RemainingCalls)"
                    }
                }
                catch {
                    $healthResult.Checks += @{
                        Name = "RateLimit"
                        Status = "Fail"
                        Details = $_.Exception.Message
                    }
                }
            }
        }
        
        # Overall health determination
        $failedChecks = ($healthResult.Checks | Where-Object { $_.Status -eq "Fail" }).Count
        $healthResult.IsHealthy = ($failedChecks -eq 0) -and ($circuitState.CanExecute)
        
    }
    catch {
        $healthResult.Checks += @{
            Name = "HealthCheck"
            Status = "Fail"
            Details = $_.Exception.Message
        }
        $healthResult.IsHealthy = $false
    }
    finally {
        $stopwatch.Stop()
        $healthResult.ResponseTime = $stopwatch.ElapsedMilliseconds
    }
    
    # Log health status
    $logLevel = if ($healthResult.IsHealthy) { "INFO" } else { "WARNING" }
    $checkSummary = ($healthResult.Checks | ForEach-Object { "$($_.Name):$($_.Status)" }) -join ", "
    Add-ApplicationLog -Message "Provider health [$ProviderId]: $($healthResult.IsHealthy) ($checkSummary)" -Level $logLevel
    
    return $healthResult
}

function Test-ProviderRateLimit {
    <#
    .SYNOPSIS
    Tests provider rate limiting status
    #>
    param(
        [Parameter(Mandatory=$true)][string]$ProviderId,
        [hashtable]$Configuration
    )
    
    # This is a placeholder for rate limit testing
    # In a real implementation, this would make minimal API calls to check headers
    return @{
        WithinLimits = $true
        RemainingCalls = 1000
        ResetTime = (Get-Date).AddHours(1)
    }
}

# Export functions and classes
Export-ModuleMember -Function @(
    'New-CircuitBreaker',
    'Test-CircuitBreakerState',
    'Set-CircuitBreakerSuccess', 
    'Set-CircuitBreakerFailure',
    'Get-CircuitBreakerStatus',
    'Start-AdvancedRetry',
    'Test-ProviderHealth',
    'Send-OperationalAlert'
)

# Note: Classes are automatically available when the module is imported in PowerShell 5.0+
# No need to export CircuitBreaker class explicitly

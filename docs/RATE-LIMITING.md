# API Rate Limiting & Quota Management Guide

## Overview
This guide explains how to handle API rate limits, quotas, and billing across all supported TTS providers in TextToSpeech Generator v3.2.

## Understanding Rate Limits

### Rate Limit Types
1. **Requests Per Second (RPS)**: Maximum API calls per second
2. **Requests Per Minute (RPM)**: Maximum API calls per minute  
3. **Characters Per Month**: Total text characters per billing period
4. **Concurrent Connections**: Simultaneous API connections
5. **Daily Quotas**: Maximum usage per day

## Provider-Specific Limits

### Azure Cognitive Services

#### Free Tier (F0)
- **Rate Limit**: 20 requests per minute
- **Character Limit**: 5,000 transactions per month
- **Concurrent Requests**: 1
- **Audio Length**: Up to 10 minutes per request

#### Standard Tier (S0)  
- **Rate Limit**: 200 requests per minute
- **Character Limit**: Pay-per-use (no monthly limit)
- **Concurrent Requests**: 20
- **Audio Length**: Up to 10 minutes per request

#### Configuration Example
```json
{
  "Azure Cognitive Services": {
    "RateLimits": {
      "RequestsPerMinute": 200,
      "ConcurrentRequests": 20,
      "MaxCharactersPerRequest": 5000
    },
    "Quotas": {
      "MonthlyCharacters": "unlimited",
      "BillingModel": "pay-per-use"
    }
  }
}
```

### Google Cloud Text-to-Speech

#### Free Tier
- **Rate Limit**: 300 requests per minute
- **Character Limit**: 1 million WaveNet characters per month
- **Standard Voices**: 4 million characters per month
- **Concurrent Requests**: 100

#### Paid Tier
- **Rate Limit**: 300 requests per minute (default, can be increased)
- **Character Limit**: Pay-per-use
- **Concurrent Requests**: 100 (can be increased)

#### Configuration Example
```json
{
  "Google Cloud TTS": {
    "RateLimits": {
      "RequestsPerMinute": 300,
      "ConcurrentRequests": 100,
      "MaxCharactersPerRequest": 5000
    },
    "Quotas": {
      "MonthlyWaveNetCharacters": 1000000,
      "MonthlyStandardCharacters": 4000000
    }
  }
}
```

### AWS Polly

#### Free Tier (First 12 Months)
- **Rate Limit**: 100 requests per second
- **Character Limit**: 5 million characters per month
- **Neural Voices**: 1 million characters per month
- **Concurrent Requests**: 10

#### Standard Pricing
- **Rate Limit**: 100 requests per second (default)
- **Character Limit**: Pay-per-use
- **Concurrent Requests**: 10 (can be increased)

#### Configuration Example
```json
{
  "AWS Polly": {
    "RateLimits": {
      "RequestsPerSecond": 100,
      "ConcurrentRequests": 10,
      "MaxCharactersPerRequest": 3000
    },
    "Quotas": {
      "MonthlyStandardCharacters": 5000000,
      "MonthlyNeuralCharacters": 1000000
    }
  }
}
```

### Twilio

#### Rate Limits
- **Rate Limit**: 100 requests per second
- **Character Limit**: Pay-per-minute of audio
- **Concurrent Requests**: Based on account tier

### VoiceForge

#### Rate Limits
- **Rate Limit**: 30 requests per minute
- **Character Limit**: Varies by subscription
- **Concurrent Requests**: 3

## Rate Limit Handling Strategies

### 1. Exponential Backoff
```powershell
function Invoke-RateLimitedRequest {
    param(
        [scriptblock]$RequestBlock,
        [int]$MaxRetries = 5,
        [int]$BaseDelaySeconds = 1
    )
    
    $attempt = 0
    while ($attempt -lt $MaxRetries) {
        try {
            return & $RequestBlock
        }
        catch {
            if ($_.Exception.Message -match "rate limit|throttl|429") {
                $delay = [Math]::Pow(2, $attempt) * $BaseDelaySeconds
                Write-ApplicationLog -Message "Rate limited. Waiting $delay seconds..." -Level "WARNING"
                Start-Sleep -Seconds $delay
                $attempt++
            } else {
                throw
            }
        }
    }
    throw "Max retries exceeded for rate-limited request"
}
```

### 2. Request Queuing
```powershell
class RequestQueue {
    [System.Collections.Queue] $Queue
    [hashtable] $RateLimits
    [datetime] $LastRequest
    
    RequestQueue([hashtable]$rateLimits) {
        $this.Queue = New-Object System.Collections.Queue
        $this.RateLimits = $rateLimits
        $this.LastRequest = Get-Date
    }
    
    [void] EnqueueRequest([hashtable]$request) {
        $this.Queue.Enqueue($request)
    }
    
    [hashtable] DequeueRequest() {
        $this.EnforceRateLimit()
        if ($this.Queue.Count -gt 0) {
            $this.LastRequest = Get-Date
            return $this.Queue.Dequeue()
        }
        return $null
    }
    
    [void] EnforceRateLimit() {
        $timeSinceLastRequest = (Get-Date) - $this.LastRequest
        $minInterval = 60 / $this.RateLimits.RequestsPerMinute
        
        if ($timeSinceLastRequest.TotalSeconds -lt $minInterval) {
            $waitTime = $minInterval - $timeSinceLastRequest.TotalSeconds
            Start-Sleep -Seconds $waitTime
        }
    }
}
```

### 3. Intelligent Load Distribution
```powershell
function Get-OptimalProvider {
    param([int]$CharacterCount)
    
    $providers = @(
        @{ Name = "Azure"; RemainingQuota = 1000000; Cost = 0.000016 }
        @{ Name = "Google"; RemainingQuota = 500000; Cost = 0.000016 }
        @{ Name = "AWS"; RemainingQuota = 2000000; Cost = 0.000004 }
    )
    
    # Filter providers with sufficient quota
    $availableProviders = $providers | Where-Object { $_.RemainingQuota -ge $CharacterCount }
    
    if ($availableProviders.Count -eq 0) {
        throw "No providers have sufficient quota for $CharacterCount characters"
    }
    
    # Select provider with best cost-effectiveness
    $optimal = $availableProviders | Sort-Object Cost | Select-Object -First 1
    return $optimal.Name
}
```

## Quota Monitoring

### 1. Real-time Monitoring
```powershell
class QuotaMonitor {
    [hashtable] $Usage
    [hashtable] $Limits
    
    QuotaMonitor([hashtable]$limits) {
        $this.Limits = $limits
        $this.Usage = @{}
        foreach ($provider in $limits.Keys) {
            $this.Usage[$provider] = @{
                CharactersUsed = 0
                RequestsUsed = 0
                LastReset = Get-Date
            }
        }
    }
    
    [void] RecordUsage([string]$provider, [int]$characters, [int]$requests) {
        $this.Usage[$provider].CharactersUsed += $characters
        $this.Usage[$provider].RequestsUsed += $requests
        
        $this.CheckQuotaWarnings($provider)
    }
    
    [void] CheckQuotaWarnings([string]$provider) {
        $usage = $this.Usage[$provider]
        $limits = $this.Limits[$provider]
        
        $charUsagePercent = ($usage.CharactersUsed / $limits.MonthlyCharacters) * 100
        $reqUsagePercent = ($usage.RequestsUsed / $limits.MonthlyRequests) * 100
        
        if ($charUsagePercent -gt 80) {
            Write-ApplicationLog -Message "$provider character quota at $($charUsagePercent.ToString('F1'))%" -Level "WARNING"
        }
        
        if ($charUsagePercent -gt 95) {
            Write-ApplicationLog -Message "$provider character quota critically low!" -Level "ERROR"
        }
    }
}
```

### 2. Cost Tracking
```powershell
function Get-EstimatedCost {
    param(
        [string]$Provider,
        [int]$Characters,
        [string]$VoiceType = "Standard"
    )
    
    $pricing = @{
        "Azure" = @{
            "Standard" = 0.000016  # Per character
            "Neural" = 0.000048
        }
        "Google" = @{
            "Standard" = 0.000004
            "WaveNet" = 0.000016
        }
        "AWS" = @{
            "Standard" = 0.000004
            "Neural" = 0.000016
        }
    }
    
    $rate = $pricing[$Provider][$VoiceType]
    return [Math]::Round($Characters * $rate, 4)
}
```

## Best Practices

### 1. Batch Processing Optimisation
- **Chunk Size**: Optimise text chunks for maximum efficiency
- **Parallel Processing**: Use optimal thread count based on rate limits
- **Request Grouping**: Group small requests to minimise API calls

### 2. Caching Strategy
```powershell
# Implement intelligent caching to avoid duplicate API calls
$cache = @{}
$cacheKey = "$Provider-$Voice-$(Get-FileHash -InputObject $text -Algorithm MD5).Hash"

if ($cache.ContainsKey($cacheKey)) {
    return $cache[$cacheKey]
} else {
    $result = Invoke-TTSProvider -Text $text -Voice $voice
    $cache[$cacheKey] = $result
    return $result
}
```

### 3. Provider Failover
```powershell
function Invoke-TTSWithFailover {
    param([string]$Text, [array]$ProviderPriority)
    
    foreach ($provider in $ProviderPriority) {
        try {
            $quotaCheck = Test-ProviderQuota -Provider $provider -CharacterCount $Text.Length
            if ($quotaCheck.Available) {
                return Invoke-TTSProvider -Provider $provider -Text $Text
            }
        }
        catch {
            Write-ApplicationLog -Message "Provider $provider failed: $($_.Exception.Message)" -Level "WARNING"
        }
    }
    
    throw "All providers exhausted or failed"
}
```

### 4. Budget Management
```powershell
function Set-MonthlyBudget {
    param(
        [string]$Provider,
        [decimal]$BudgetUSD,
        [string]$AlertEmail
    )
    
    $config = @{
        Provider = $Provider
        MonthlyBudget = $BudgetUSD
        AlertThresholds = @(50, 75, 90, 95)  # Percentage thresholds
        AlertEmail = $AlertEmail
        CurrentSpend = 0
        LastUpdated = Get-Date
    }
    
    # Save budget configuration
    $config | ConvertTo-Json | Out-File -Path "budget-$Provider.json"
}
```

## Emergency Procedures

### Quota Exhaustion
1. **Immediate Actions**:
   - Switch to alternative provider
   - Implement emergency rate limiting
   - Notify stakeholders

2. **Recovery Steps**:
   - Request quota increase from provider
   - Implement cost controls
   - Review usage patterns

### Rate Limit Violations
1. **Detection**: Monitor for HTTP 429 responses
2. **Response**: Implement exponential backoff
3. **Prevention**: Proactive rate limit management

### Billing Alerts
1. **Setup**: Configure billing alerts with cloud providers
2. **Thresholds**: Set alerts at 50%, 75%, 90% of budget
3. **Actions**: Automated provider switching or processing suspension

## Configuration Templates

### Enterprise Configuration
```json
{
  "RateLimitManagement": {
    "Enabled": true,
    "GlobalSettings": {
      "MaxConcurrentRequests": 20,
      "DefaultBackoffStrategy": "exponential",
      "QuotaWarningThreshold": 80
    },
    "ProviderSettings": {
      "Azure Cognitive Services": {
        "RequestsPerMinute": 180,
        "BackoffMultiplier": 2,
        "MaxRetries": 5
      }
    }
  },
  "CostManagement": {
    "MonthlyBudget": 1000,
    "Currency": "USD",
    "AlertThresholds": [50, 75, 90],
    "EmergencyStop": true
  }
}
```

### Development Configuration  
```json
{
  "RateLimitManagement": {
    "Enabled": true,
    "GlobalSettings": {
      "MaxConcurrentRequests": 2,
      "DefaultBackoffStrategy": "linear",
      "QuotaWarningThreshold": 70
    }
  },
  "CostManagement": {
    "MonthlyBudget": 50,
    "Currency": "USD",
    "AlertThresholds": [80, 90],
    "EmergencyStop": true
  }
}
```

## Monitoring and Reporting

### Key Metrics
- **API Response Times**: Track latency per provider
- **Success Rates**: Monitor API call success rates
- **Quota Utilization**: Track quota consumption
- **Cost Analysis**: Monitor spending per provider
- **Error Rates**: Track and categorize API errors

### Reporting Dashboard
```powershell
function Get-UsageReport {
    param([datetime]$StartDate, [datetime]$EndDate)
    
    return @{
        Period = "$StartDate to $EndDate"
        TotalRequests = 1234
        TotalCharacters = 567890
        TotalCost = 9.87
        ProviderBreakdown = @{
            Azure = @{ Requests = 800; Characters = 400000; Cost = 6.40 }
            Google = @{ Requests = 434; Characters = 167890; Cost = 3.47 }
        }
        QuotaUtilization = @{
            Azure = "65%"
            Google = "42%"
        }
    }
}
```

This comprehensive guide ensures optimal utilization of TTS provider APIs while maintaining cost control and avoiding service disruptions.
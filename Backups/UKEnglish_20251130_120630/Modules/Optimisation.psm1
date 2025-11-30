# Performance Optimisation Module for TextToSpeech Generator v3.2
# Advanced performance features including connection pooling, async operations, and intelligent caching

# Import required modules
Import-Module -Name "$PSScriptRoot\Logging.psm1" -Force

# Load C# type definitions
try {
    [ConnectionPool] | Out-Null
    Write-ApplicationLog -Message "ConnectionPool type already loaded" -Level "DEBUG"
} catch {
    try {
        $typeDefinitionPath = Join-Path $PSScriptRoot "OptimisationTypes.cs"
        
        if (Test-Path $typeDefinitionPath) {
            Add-Type -Path $typeDefinitionPath -ErrorAction Stop
            Write-ApplicationLog -Message "Loaded performance optimization types from external file" -Level "INFO"
        } else {
            Write-ApplicationLog -Message "Type definition file not found at: $typeDefinitionPath" -Level "ERROR"
            throw "Required type definitions file not found: $typeDefinitionPath"
        }
    } catch {
        Write-ApplicationLog -Message "Failed to load types: $_" -Level "ERROR"
        throw
    }
}

class PerformanceOptimiser {
    [hashtable] $ConnectionPools
    [hashtable] $CacheManager
    [hashtable] $PerformanceMetrics
    [hashtable] $AsyncOperations
    [int] $MaxConcurrentRequests
    [int] $ConnectionTimeout
    
    PerformanceOptimiser() {
        $this.ConnectionPools = @{}
        $this.CacheManager = @{}
        $this.PerformanceMetrics = @{
            RequestCount = 0
            AverageResponseTime = 0
            CacheHitRate = 0
            ConnectionPoolUtilization = 0
            ErrorRate = 0
            TotalExecutionTime = 0
        }
        $this.AsyncOperations = @{}
        $this.MaxConcurrentRequests = 10
        $this.ConnectionTimeout = 30
        
        $this.InitialiseConnectionPools()
        $this.InitialiseCacheManager()
        $this.InitialiseAsyncManager()  
    }
    
    [void] InitialiseConnectionPools() {
        # Dynamically discover provider modules and initialise connection pools using provider-exported settings
        $providerFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Providers') -Filter '*.psm1' -ErrorAction SilentlyContinue | Sort-Object Name
        foreach ($file in $providerFiles) {
            $providerName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $minSize = 2
            $maxSize = 6
            $timeout = 30

            # Import provider module in current session and get settings
            $providerModulePath = $file.FullName
            $providerSettings = $null
            try {
                Import-Module -Name $providerModulePath -Force -Global
                if (Get-Variable -Name 'ProviderOptimisationSettings' -Scope Global -ErrorAction SilentlyContinue) {
                    $providerSettings = Get-Variable -Name 'ProviderOptimisationSettings' -Scope Global -ValueOnly
                }
            } catch {
                $providerSettings = $null
            }

            if ($providerSettings -and $providerSettings.ContainsKey('MinPoolSize')) { $minSize = $providerSettings.MinPoolSize }
            if ($providerSettings -and $providerSettings.ContainsKey('MaxPoolSize')) { $maxSize = $providerSettings.MaxPoolSize }
            if ($providerSettings -and $providerSettings.ContainsKey('ConnectionTimeout')) { $timeout = $providerSettings.ConnectionTimeout }

            try {
                $pool = [ConnectionPool]::new($providerName, $minSize, $maxSize)
                $this.ConnectionPools[$providerName] = $pool
                Write-ApplicationLog -Message "Initialized connection pool for $providerName (Min: $minSize, Max: $maxSize, Timeout: $timeout)" -Level "INFO"
            } catch {
                Write-ApplicationLog -Message "Failed to initialize connection pool for $providerName`: $_" -Level "ERROR"
            }
        }
    }
    
    [void] InitialiseCacheManager() {
        # Initialise intelligent caching system
        $this.CacheManager = @{
            AudioCache = @{
                MaxSizeGB = 2
                TTLHours = 24
                CompressionEnabled = $true
                Cache = @{}
                Stats = @{
                    Hits = 0
                    Misses = 0
                    Evictions = 0
                    TotalRequests = 0
                }
            }
            ConfigCache = @{
                TTLMinutes = 30
                Cache = @{}
                LastUpdate = $null
            }
            ProviderCache = @{
                TTLMinutes = 15
                Cache = @{}
                Stats = @{
                    Hits = 0
                    Misses = 0
                }
            }
        }
        
        Write-ApplicationLog -Message "Initialised intelligent caching system with compression support" -Level "INFO"
    }
    
    [void] InitialiseAsyncManager() {
        try {
            $this.AsyncOperations["Manager"] = [AsyncOperationManager]::new($this.MaxConcurrentRequests)
            Write-ApplicationLog -Message "Initialised async operation manager (Max Concurrency: $($this.MaxConcurrentRequests))" -Level "INFO"
        } catch {
            Write-ApplicationLog -Message "Failed to initialise async operation manager: $_" -Level "ERROR"
        }
    }
    
    [object] AcquireConnection([string]$provider) {
        if (-not $this.ConnectionPools.ContainsKey($provider)) {
            Write-ApplicationLog -Message "No connection pool available for provider: $provider" -Level "WARNING"
            return $null
        }
        
        try {
            $startTime = Get-Date
            $connection = $this.ConnectionPools[$provider].AcquireConnection()
            $acquisitionTime = ((Get-Date) - $startTime).TotalMilliseconds
            
            Write-ApplicationLog -Message "Acquired connection for $provider in $($acquisitionTime)ms" -Level "DEBUG"
            $connection.UpdateLastUsed()
            
            return $connection
        } catch {
            Write-ApplicationLog -Message "Failed to acquire connection for $provider`: $_" -Level "ERROR"
            return $null
        }
    }
    
    [void] ReleaseConnection([string]$provider, [object]$connection) {
        if ($connection -and $this.ConnectionPools.ContainsKey($provider)) {
            try {
                $this.ConnectionPools[$provider].ReleaseConnection($connection)
                Write-ApplicationLog -Message "Released connection for provider: $provider" -Level "DEBUG"
            } catch {
                Write-ApplicationLog -Message "Failed to release connection for $provider`: $_" -Level "ERROR"
            }
        }
    }
    
    [object] GetFromCache([string]$cacheType, [string]$key) {
        if (-not $this.CacheManager.ContainsKey($cacheType)) {
            return $null
        }
        
        $cache = $this.CacheManager[$cacheType]
        $cache.Stats.TotalRequests++
        
        if ($cache.Cache.ContainsKey($key)) {
            $entry = $cache.Cache[$key]
            $now = Get-Date
            
            # Check TTL
            $ttlValid = if ($cache.ContainsKey('TTLHours')) {
                ($now - $entry.Timestamp).TotalHours -lt $cache.TTLHours
            } elseif ($cache.ContainsKey('TTLMinutes')) {
                ($now - $entry.Timestamp).TotalMinutes -lt $cache.TTLMinutes
            } else {
                $true
            }
            
            if ($ttlValid) {
                $cache.Stats.Hits++
                Write-ApplicationLog -Message "Cache hit for $cacheType`: $key" -Level "DEBUG"
                return $entry.Value
            } else {
                # Expired entry
                $cache.Cache.Remove($key)
                Write-ApplicationLog -Message "Cache entry expired for $cacheType`: $key" -Level "DEBUG"
            }
        }
        
        $cache.Stats.Misses++
        return $null
    }
    
    [void] SetCache([string]$cacheType, [string]$key, [object]$value) {
        if (-not $this.CacheManager.ContainsKey($cacheType)) {
            return
        }
        
        $cache = $this.CacheManager[$cacheType]
        
        # Check cache size limits for AudioCache
        if ($cacheType -eq "AudioCache" -and $cache.Cache.Count -gt 100) {
            $this.EvictOldestCacheEntries($cacheType, 10)
        }
        
        $entry = @{
            Value = $value
            Timestamp = Get-Date
            AccessCount = 1
        }
        
        $cache.Cache[$key] = $entry
        Write-ApplicationLog -Message "Cached entry for $cacheType`: $key" -Level "DEBUG"
    }
    
    [void] EvictOldestCacheEntries([string]$cacheType, [int]$count) {
        if (-not $this.CacheManager.ContainsKey($cacheType)) {
            return
        }
        
        $cache = $this.CacheManager[$cacheType]
        $sortedEntries = $cache.Cache.GetEnumerator() | Sort-Object { $_.Value.Timestamp } | Select-Object -First $count
        
        foreach ($entry in $sortedEntries) {
            $cache.Cache.Remove($entry.Key)
            $cache.Stats.Evictions++
        }
        
        Write-ApplicationLog -Message "Evicted $count oldest entries from $cacheType cache" -Level "DEBUG"
    }
    
    [hashtable] ExecuteWithPerformanceTracking([scriptblock]$operation, [hashtable]$context = @{}) {
        $startTime = Get-Date
        $operationId = [System.Guid]::NewGuid().ToString()
        
        try {
            Write-ApplicationLog -Message "Starting performance-tracked operation: $operationId" -Level "DEBUG"
            
            # Execute operation
            $result = & $operation $context
            
            $executionTime = ((Get-Date) - $startTime).TotalMilliseconds
            
            # Update performance metrics
            $this.UpdatePerformanceMetrics($executionTime, $true, $context)
            
            Write-ApplicationLog -Message "Operation $operationId completed in $($executionTime)ms" -Level "INFO"
            
            return @{
                Success = $true
                Result = $result
                ExecutionTimeMs = $executionTime
                OperationId = $operationId
            }
            
        } catch {
            $executionTime = ((Get-Date) - $startTime).TotalMilliseconds
            $this.UpdatePerformanceMetrics($executionTime, $false, $context)
            
            Write-ApplicationLog -Message "Operation $operationId failed after $($executionTime)ms`: $_" -Level "ERROR"
            
            return @{
                Success = $false
                Error = $_.Exception.Message
                ExecutionTimeMs = $executionTime
                OperationId = $operationId
            }
        }
    }
    
    [void] UpdatePerformanceMetrics([double]$executionTime, [bool]$success, [hashtable]$context) {
        $metrics = $this.PerformanceMetrics
        
        # Update request count
        $metrics.RequestCount++
        
        # Update average response time
        $totalTime = $metrics.TotalExecutionTime + $executionTime
        $metrics.TotalExecutionTime = $totalTime
        $metrics.AverageResponseTime = $totalTime / $metrics.RequestCount
        
        # Update error rate
        if (-not $success) {
            $errorCount = if ($metrics.ContainsKey('ErrorCount')) { $metrics.ErrorCount + 1 } else { 1 }
            $metrics.ErrorCount = $errorCount
            $metrics.ErrorRate = ($errorCount / $metrics.RequestCount) * 100
        }
        
        # Update cache hit rate
        $this.UpdateCacheHitRate()
        
        # Update connection pool utilization
        $this.UpdateConnectionPoolUtilization()
    }
    
    [void] UpdateCacheHitRate() {
        $totalRequests = 0
        $totalHits = 0
        
        foreach ($cacheType in $this.CacheManager.Keys) {
            $cache = $this.CacheManager[$cacheType]
            if ($cache.Stats) {
                $totalRequests += $cache.Stats.TotalRequests
                $totalHits += $cache.Stats.Hits
            }
        }
        
        if ($totalRequests -gt 0) {
            $this.PerformanceMetrics.CacheHitRate = ($totalHits / $totalRequests) * 100
        }
    }
    
    [void] UpdateConnectionPoolUtilization() {
        $totalConnections = 0
        $totalActive = 0
        
        foreach ($provider in $this.ConnectionPools.Keys) {
            $stats = $this.ConnectionPools[$provider].GetStats()
            $totalConnections += $stats.TotalConnections
            $totalActive += $stats.ActiveConnections
        }
        
        if ($totalConnections -gt 0) {
            $this.PerformanceMetrics.ConnectionPoolUtilization = ($totalActive / $totalConnections) * 100
        }
    }
    
    [hashtable] GetPerformanceReport() {
        $report = @{
            GeneratedAt = Get-Date
            Metrics = $this.PerformanceMetrics.Clone()
            ConnectionPools = @{}
            CacheStatistics = @{}
            Recommendations = @()
        }
        
        # Add connection pool statistics
        foreach ($provider in $this.ConnectionPools.Keys) {
            $report.ConnectionPools[$provider] = $this.ConnectionPools[$provider].GetStats()
        }
        
        # Add cache statistics
        foreach ($cacheType in $this.CacheManager.Keys) {
            $cache = $this.CacheManager[$cacheType]
            $report.CacheStatistics[$cacheType] = @{
                EntryCount = $cache.Cache.Count
                Statistics = if ($cache.Stats) { $cache.Stats.Clone() } else { @{} }
            }
        }
        
        # Generate performance recommendations
        $report.Recommendations = $this.GeneratePerformanceRecommendations()
        
        return $report
    }
    
    [string[]] GeneratePerformanceRecommendations() {
        $recommendations = @()
        $metrics = $this.PerformanceMetrics
        
        # Response time recommendations
        if ($metrics.AverageResponseTime -gt 5000) {
            $recommendations += "Average response time is high ($([math]::Round($metrics.AverageResponseTime))ms). Consider optimising network connections or increasing connection pool sizes."
        }
        
        # Cache hit rate recommendations
        if ($metrics.CacheHitRate -lt 50) {
            $recommendations += "Cache hit rate is low ($([math]::Round($metrics.CacheHitRate))%). Consider increasing cache TTL or improving cache key strategies."
        }
        
        # Error rate recommendations
        if ($metrics.ErrorRate -gt 10) {
            $recommendations += "Error rate is high ($([math]::Round($metrics.ErrorRate))%). Review error logs and consider implementing additional retry mechanisms."
        }
        
        # Connection pool recommendations
        if ($metrics.ConnectionPoolUtilization -gt 80) {
            $recommendations += "Connection pool utilization is high ($([math]::Round($metrics.ConnectionPoolUtilization))%). Consider increasing pool sizes for better performance."
        } elseif ($metrics.ConnectionPoolUtilization -lt 20) {
            $recommendations += "Connection pool utilization is low ($([math]::Round($metrics.ConnectionPoolUtilization))%). Consider reducing pool sizes to save resources."
        }
        
        return $recommendations
    }
    
    [void] OptimiseConnectionPools() {
        foreach ($provider in $this.ConnectionPools.Keys) {
            $stats = $this.ConnectionPools[$provider].GetStats()
            
            # Log current utilization
            $utilization = if ($stats.TotalConnections -gt 0) {
                ($stats.ActiveConnections / $stats.TotalConnections) * 100
            } else { 0 }
            
            Write-ApplicationLog -Message "Provider $provider connection utilization: $([math]::Round($utilization))%" -Level "INFO"
        }
    }
    
    [void] ClearCaches([string[]]$cacheTypes = @()) {
        if ($cacheTypes.Count -eq 0) {
            $cacheTypes = $this.CacheManager.Keys
        }
        
        foreach ($cacheType in $cacheTypes) {
            if ($this.CacheManager.ContainsKey($cacheType)) {
                $entriesCleared = $this.CacheManager[$cacheType].Cache.Count
                $this.CacheManager[$cacheType].Cache.Clear()
                Write-ApplicationLog -Message "Cleared $entriesCleared entries from $cacheType cache" -Level "INFO"
            }
        }
    }
}

function New-OptimisationConnectionPool {
    param(
        [string]$Provider,
        [int]$MinSize = 2,
        [int]$MaxSize = 10
    )
    return [ConnectionPool]::new($Provider, $MinSize, $MaxSize)
}

function New-OptimisationAsyncManager {
    param(
        [int]$MaxConcurrency = 5
    )
    return [AsyncOperationManager]::new($MaxConcurrency)
}

function New-OptimisationConnection {
    param(
        [string]$Provider,
        [string]$Id = ([guid]::NewGuid().ToString())
    )
    return [Connection]::new($Provider, $Id)
}

function Remove-OptimisationConnection {
    param(
        [object]$ConnectionPool,
        [object]$Connection
    )
    $ConnectionPool.ReleaseConnection($Connection)
}

function Get-OptimisationConnection {
    param(
        [object]$ConnectionPool
    )
    return $ConnectionPool.AcquireConnection()
}

function Get-OptimisationAsyncSlot {
    param(
        [object]$AsyncManager
    )
    return $AsyncManager.AvailableSlots
}

# Existing PerformanceOptimiser functions
function New-PerformanceOptimiser {
    return [PerformanceOptimiser]::new()
}

function Get-PerformanceReport {
    param([PerformanceOptimiser]$Optimiser)
    return $Optimiser.GetPerformanceReport()
}

function Optimise-ConnectionPools {
    param([PerformanceOptimiser]$Optimiser)
    $Optimiser.OptimiseConnectionPools()
}

function Clear-PerformanceCaches {
    param(
        [PerformanceOptimiser]$Optimiser,
        [string[]]$CacheTypes = @()
    )
    $Optimiser.ClearCaches($CacheTypes)
}

# Export all required module members
Export-ModuleMember -Function @(
    'New-OptimisationConnectionPool',
    'New-OptimisationAsyncManager',
    'New-OptimisationConnection',
    'Remove-OptimisationConnection',
    'Get-OptimisationConnection',
    'Get-OptimisationAsyncSlot',
    'New-PerformanceOptimiser',
    'Get-PerformanceReport', 
    'Optimise-ConnectionPools',
    'Clear-PerformanceCaches'
) -Variable @() -Cmdlet @() -Alias @()

Write-ApplicationLog -Message "Optimisation module loaded successfully" -Level "INFO"
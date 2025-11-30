# Performance Optimisation and Monitoring Implementation
# This file is dot-sourced after types are loaded

# ============================================================================
# CONNECTION POOLING AND ASYNC OPERATIONS
# ============================================================================

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
            ConnectionPoolUtilisation = 0
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
                Write-ApplicationLog -Message "Initialised connection pool for $providerName (Min: $minSize, Max: $maxSize, Timeout: $timeout)" -Level "INFO"
            } catch {
                Write-ApplicationLog -Message "Failed to initialise connection pool for $providerName`: $_" -Level "ERROR"
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
        
        # Update connection pool utilisation
        $this.UpdateConnectionPoolUtilisation()
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
    
    [void] UpdateConnectionPoolUtilisation() {
        $totalConnections = 0
        $totalActive = 0
        
        foreach ($provider in $this.ConnectionPools.Keys) {
            $stats = $this.ConnectionPools[$provider].GetStats()
            $totalConnections += $stats.TotalConnections
            $totalActive += $stats.ActiveConnections
        }
        
        if ($totalConnections -gt 0) {
            $this.PerformanceMetrics.ConnectionPoolUtilisation = ($totalActive / $totalConnections) * 100
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
        if ($metrics.ConnectionPoolUtilisation -gt 80) {
            $recommendations += "Connection pool utilisation is high ($([math]::Round($metrics.ConnectionPoolUtilisation))%). Consider increasing pool sizes for better performance."
        } elseif ($metrics.ConnectionPoolUtilisation -lt 20) {
            $recommendations += "Connection pool utilisation is low ($([math]::Round($metrics.ConnectionPoolUtilisation))%). Consider reducing pool sizes to save resources."
        }
        
        return $recommendations
    }
    
    [void] OptimiseConnectionPools() {
        foreach ($provider in $this.ConnectionPools.Keys) {
            $stats = $this.ConnectionPools[$provider].GetStats()
            
            # Log current utilisation
            $utilisation = if ($stats.TotalConnections -gt 0) {
                ($stats.ActiveConnections / $stats.TotalConnections) * 100
            } else { 0 }
            
            Write-ApplicationLog -Message "Provider $provider connection utilisation: $([math]::Round($utilisation))%" -Level "INFO"
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

# ============================================================================
# PERFORMANCE MONITORING
# ============================================================================

class PerformanceMonitor {
    [hashtable] $Metrics
    [hashtable] $OperationHistory
    [hashtable] $PerformanceCounters
    [datetime] $StartTime
    [bool] $IsMonitoring
    
    PerformanceMonitor() {
        $this.Metrics = @{}
        $this.OperationHistory = @{}
        $this.PerformanceCounters = @{}
        $this.StartTime = Get-Date
        $this.IsMonitoring = $false
        $this.Initialise()
    }
    
    [void] Initialise() {
        $this.InitialisePerformanceCounters()
        $this.IsMonitoring = $true
        Write-ApplicationLog -Message "Performance monitor initialised" -Level "INFO"
    }
    
    [void] InitialisePerformanceCounters() {
        try {
            # System performance counters
            $this.PerformanceCounters = @{
                CPUUsage = Get-Counter -Counter "\Processor(_Total)\% Processor Time" -MaxSamples 1 -ErrorAction SilentlyContinue
                MemoryAvailable = Get-Counter -Counter "\Memory\Available MBytes" -MaxSamples 1 -ErrorAction SilentlyContinue
                DiskQueue = Get-Counter -Counter "\PhysicalDisk(_Total)\Current Disk Queue Length" -MaxSamples 1 -ErrorAction SilentlyContinue
            }
        } catch {
            Write-ApplicationLog -Message "Could not initialise performance counters: $($_.Exception.Message)" -Level "WARNING"
        }
    }
    
    [void] StartOperation([string]$operationName) {
        if (-not $this.IsMonitoring) { return }
        
        $operation = @{
            Name = $operationName
            StartTime = Get-Date
            StartMemory = [System.GC]::GetTotalMemory($false)
            ProcessId = $Global:PID
            ThreadId = [Threading.Thread]::CurrentThread.ManagedThreadId
        }
        
        $operationKey = "$operationName-$(Get-Random)"
        $this.Metrics[$operationKey] = $operation
        
        Write-ApplicationLog -Message "Started monitoring operation: $operationName" -Level "DEBUG"
    }
    
    [hashtable] EndOperation([string]$operationName) {
        if (-not $this.IsMonitoring) { 
            return @{ Success = $false; Message = "Monitoring not active" }
        }
        
        # Find the most recent operation with this name
        $operationKey = $null
        $mostRecentTime = [DateTime]::MinValue
        
        foreach ($key in $this.Metrics.Keys) {
            $op = $this.Metrics[$key]
            if ($op.Name -eq $operationName -and $op.StartTime -gt $mostRecentTime -and -not $op.ContainsKey("EndTime")) {
                $operationKey = $key
                $mostRecentTime = $op.StartTime
            }
        }
        
        if (-not $operationKey) {
            Write-ApplicationLog -Message "No active operation found for: $operationName" -Level "WARNING"
            return @{ Success = $false; Message = "Operation not found" }
        }
        
        $operation = $this.Metrics[$operationKey]
        $endTime = Get-Date
        $duration = $endTime - $operation.StartTime
        $endMemory = [System.GC]::GetTotalMemory($false)
        
        # Calculate metrics
        $operation.EndTime = $endTime
        $operation.Duration = $duration
        $operation.EndMemory = $endMemory
        $operation.MemoryDelta = $endMemory - $operation.StartMemory
        $operation.MemoryDeltaMB = [Math]::Round($operation.MemoryDelta / 1MB, 2)
        
        # Get current system performance
        $operation.SystemMetrics = $this.GetCurrentSystemMetrics()
        
        # Store in history
        if (-not $this.OperationHistory.ContainsKey($operationName)) {
            $this.OperationHistory[$operationName] = @()
        }
        $this.OperationHistory[$operationName] += $operation
        
        # Keep only last 100 entries per operation type
        if ($this.OperationHistory[$operationName].Count -gt 100) {
            $this.OperationHistory[$operationName] = $this.OperationHistory[$operationName] | Select-Object -Last 100
        }
        
        Write-ApplicationLog -Message "Operation $operationName completed in $($duration.TotalSeconds.ToString('F2'))s, Memory delta: $($operation.MemoryDeltaMB)MB" -Level "DEBUG"
        
        return @{
            Success = $true
            Duration = $duration
            MemoryDelta = $operation.MemoryDelta
            MemoryDeltaMB = $operation.MemoryDeltaMB
            SystemMetrics = $operation.SystemMetrics
        }
    }
    
    [hashtable] GetCurrentSystemMetrics() {
        $currentPID = $Global:PID
        $systemMetrics = @{
            Timestamp = Get-Date
            ProcessMemoryMB = [Math]::Round((Get-Process -Id $currentPID).WorkingSet64 / 1MB, 2)
            TotalMemoryMB = [Math]::Round([System.GC]::GetTotalMemory($false) / 1MB, 2)
            Gen0Collections = [System.GC]::CollectionCount(0)
            Gen1Collections = [System.GC]::CollectionCount(1)
            Gen2Collections = [System.GC]::CollectionCount(2)
        }
        
        try {
            # Get system performance if counters available
            $cpuCounter = Get-Counter -Counter "\Processor(_Total)\% Processor Time" -MaxSamples 1 -ErrorAction SilentlyContinue
            if ($cpuCounter) {
                $systemMetrics.CPUUsagePercent = [Math]::Round($cpuCounter.CounterSamples[0].CookedValue, 2)
            }
            
            $memCounter = Get-Counter -Counter "\Memory\Available MBytes" -MaxSamples 1 -ErrorAction SilentlyContinue
            if ($memCounter) {
                $systemMetrics.SystemAvailableMemoryMB = [Math]::Round($memCounter.CounterSamples[0].CookedValue, 2)
            }
        } catch {
            # Performance counters not available
        }
        
        return $systemMetrics
    }
    
    [hashtable] GenerateReport() {
        $report = @{
            MonitoringDuration = (Get-Date) - $this.StartTime
            TotalOperations = 0
            OperationSummary = @{}
            SystemPerformance = $this.GetCurrentSystemMetrics()
            Recommendations = @()
        }
        
        foreach ($operationType in $this.OperationHistory.Keys) {
            $operations = $this.OperationHistory[$operationType]
            $report.TotalOperations += $operations.Count
            
            if ($operations.Count -gt 0) {
                $durations = $operations | ForEach-Object { $_.Duration.TotalMilliseconds }
                $memoryDeltas = $operations | ForEach-Object { $_.MemoryDeltaMB }
                
                $summary = @{
                    Count = $operations.Count
                    AverageDurationMs = [Math]::Round(($durations | Measure-Object -Average).Average, 2)
                    MinDurationMs = [Math]::Round(($durations | Measure-Object -Minimum).Minimum, 2)
                    MaxDurationMs = [Math]::Round(($durations | Measure-Object -Maximum).Maximum, 2)
                    AverageMemoryDeltaMB = [Math]::Round(($memoryDeltas | Measure-Object -Average).Average, 2)
                    TotalMemoryDeltaMB = [Math]::Round(($memoryDeltas | Measure-Object -Sum).Sum, 2)
                    LastExecution = ($operations | Sort-Object StartTime -Descending | Select-Object -First 1).StartTime
                }
                
                $report.OperationSummary[$operationType] = $summary
                
                # Generate recommendations
                if ($summary.AverageDurationMs -gt 5000) {
                    $report.Recommendations += "Operation '$operationType' is slow (avg: $($summary.AverageDurationMs)ms). Consider optimisation."
                }
                
                if ($summary.AverageMemoryDeltaMB -gt 50) {
                    $report.Recommendations += "Operation '$operationType' has high memory usage (avg: $($summary.AverageMemoryDeltaMB)MB). Consider memory optimisation."
                }
            }
        }
        
        # System-level recommendations
        if ($report.SystemPerformance.ProcessMemoryMB -gt 500) {
            $report.Recommendations += "High process memory usage ($($report.SystemPerformance.ProcessMemoryMB)MB). Consider memory cleanup."
        }
        
        if ($report.SystemPerformance.CPUUsagePercent -gt 80) {
            $report.Recommendations += "High CPU usage ($($report.SystemPerformance.CPUUsagePercent)%). Consider reducing concurrent operations."
        }
        
        return $report
    }
    
    [void] AlertOnThresholds() {
        $currentMetrics = $this.GetCurrentSystemMetrics()
        
        # Memory threshold alerts
        if ($currentMetrics.ProcessMemoryMB -gt 1000) {
            Write-ApplicationLog -Message "HIGH MEMORY USAGE: Process using $($currentMetrics.ProcessMemoryMB)MB" -Level "WARNING"
        }
        
        # CPU threshold alerts (if available)
        if ($currentMetrics.CPUUsagePercent -and $currentMetrics.CPUUsagePercent -gt 90) {
            Write-ApplicationLog -Message "HIGH CPU USAGE: $($currentMetrics.CPUUsagePercent)%" -Level "WARNING"
        }
        
        # Garbage collection alerts
        $recentOperations = $this.OperationHistory.Values | ForEach-Object { $_ } | Where-Object { $_.StartTime -gt (Get-Date).AddMinutes(-5) }
        if ($recentOperations.Count -gt 0) {
            $avgMemoryDelta = ($recentOperations | ForEach-Object { $_.MemoryDeltaMB } | Measure-Object -Average).Average
            if ($avgMemoryDelta -gt 100) {
                Write-ApplicationLog -Message "HIGH MEMORY ALLOCATION RATE: Average $([Math]::Round($avgMemoryDelta, 2))MB per operation" -Level "WARNING"
            }
        }
    }
}

# ============================================================================
# INTELLIGENT CACHE
# ============================================================================

class IntelligentCache {
    [hashtable] $Cache
    [hashtable] $AccessCount
    [hashtable] $LastAccess
    [int] $MaxItems
    [timespan] $DefaultTTL
    
    IntelligentCache([int]$maxItems = 1000, [timespan]$defaultTTL = (New-TimeSpan -Hours 1)) {
        $this.Cache = @{}
        $this.AccessCount = @{}
        $this.LastAccess = @{}
        $this.MaxItems = $maxItems
        $this.DefaultTTL = $defaultTTL
    }
    
    [void] Set([string]$key, $value, [timespan]$ttl = $null) {
        if (-not $ttl) { $ttl = $this.DefaultTTL }
        
        $this.Cache[$key] = @{
            Value = $value
            ExpiryTime = (Get-Date).Add($ttl)
            CreatedTime = Get-Date
        }
        $this.AccessCount[$key] = 1
        $this.LastAccess[$key] = Get-Date
        
        $this.EvictIfNeeded()
    }
    
    [object] Get([string]$key) {
        if (-not $this.Cache.ContainsKey($key)) {
            return $null
        }
        
        $item = $this.Cache[$key]
        
        # Check expiry
        if ((Get-Date) -gt $item.ExpiryTime) {
            $this.Remove($key)
            return $null
        }
        
        # Update access tracking
        $this.AccessCount[$key]++
        $this.LastAccess[$key] = Get-Date
        
        return $item.Value
    }
    
    [bool] Contains([string]$key) {
        if (-not $this.Cache.ContainsKey($key)) {
            return $false
        }
        
        $item = $this.Cache[$key]
        if ((Get-Date) -gt $item.ExpiryTime) {
            $this.Remove($key)
            return $false
        }
        
        return $true
    }
    
    [void] Remove([string]$key) {
        $this.Cache.Remove($key)
        $this.AccessCount.Remove($key)
        $this.LastAccess.Remove($key)
    }
    
    [void] EvictIfNeeded() {
        while ($this.Cache.Count -gt $this.MaxItems) {
            # Find least recently used item
            $lruKey = $null
            $oldestAccess = Get-Date
            
            foreach ($key in $this.LastAccess.Keys) {
                if ($this.LastAccess[$key] -lt $oldestAccess) {
                    $oldestAccess = $this.LastAccess[$key]
                    $lruKey = $key
                }
            }
            
            if ($lruKey) {
                Write-ApplicationLog -Message "Evicting cache item: $lruKey" -Level "DEBUG"
                $this.Remove($lruKey)
            } else {
                break
            }
        }
    }
    
    [void] Clear() {
        $this.Cache.Clear()
        $this.AccessCount.Clear()
        $this.LastAccess.Clear()
    }
    
    [hashtable] GetStatistics() {
        $totalAccesses = if (($this.AccessCount.Values | Measure-Object -Sum).Sum) { ($this.AccessCount.Values | Measure-Object -Sum).Sum } else { 0 }
        $avgAccesses = if ($this.AccessCount.Count -gt 0) { $totalAccesses / $this.AccessCount.Count } else { 0 }
        
        return @{
            ItemCount = $this.Cache.Count
            MaxItems = $this.MaxItems
            TotalAccesses = $totalAccesses
            AverageAccessesPerItem = [Math]::Round($avgAccesses, 2)
            OldestItem = if (($this.Cache.Values | Sort-Object CreatedTime | Select-Object -First 1)) { ($this.Cache.Values | Sort-Object CreatedTime | Select-Object -First 1).CreatedTime } else { $null }
            ExpiredItems = ($this.Cache.Values | Where-Object { (Get-Date) -gt $_.ExpiryTime }).Count
        }
    }
}

# ============================================================================
# GLOBAL INSTANCES
#
# Performance Optimization Module for TextToSpeech Generator v3.2
# Advanced performance features including connection pooling, async operations, and intelligent caching

# Import required modules
Import-Module -Name "$PSScriptRoot\..\Logging\Logging.psm1" -Force

# Connection Pool Manager Class (PowerShell 5.1 compatible)
Add-Type -TypeDefinition @'
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

public class ConnectionPool
{
    private readonly ConcurrentQueue<Connection> _availableConnections;
    private readonly ConcurrentDictionary<string, Connection> _activeConnections;
    private readonly int _maxPoolSize;
    private readonly int _minPoolSize;
    private readonly string _provider;
    private int _currentPoolSize;
    private readonly object _lock = new object();

    public ConnectionPool(string provider, int minSize = 2, int maxSize = 10)
    {
        _provider = provider;
        _minPoolSize = minSize;
        _maxPoolSize = maxSize;
        _availableConnections = new ConcurrentQueue<Connection>();
        _activeConnections = new ConcurrentDictionary<string, Connection>();
        _currentPoolSize = 0;
        
        // Initialise minimum connections
        for (int i = 0; i < _minPoolSize; i++)
        {
            var connection = CreateConnection();
            _availableConnections.Enqueue(connection);
        }
    }

    public Connection AcquireConnection()
    {
        Connection connection;
        
        if (_availableConnections.TryDequeue(out connection))
        {
            if (connection.IsValid())
            {
                _activeConnections.TryAdd(connection.Id, connection);
                return connection;
            }
        }

        // No available connection or invalid, create new one if under limit
        lock (_lock)
        {
            if (_currentPoolSize < _maxPoolSize)
            {
                connection = CreateConnection();
                _activeConnections.TryAdd(connection.Id, connection);
                return connection;
            }
        }

        // Wait for available connection (simplified timeout)
        Thread.Sleep(1000);
        return AcquireConnection();
    }

    public void ReleaseConnection(Connection connection)
    {
        if (connection != null)
        {
            _activeConnections.TryRemove(connection.Id, out _);
            
            if (connection.IsValid() && _availableConnections.Count < _maxPoolSize)
            {
                _availableConnections.Enqueue(connection);
            }
            else
            {
                connection.Dispose();
                Interlocked.Decrement(ref _currentPoolSize);
            }
        }
    }

    private Connection CreateConnection()
    {
        Interlocked.Increment(ref _currentPoolSize);
        return new Connection(_provider, Guid.NewGuid().ToString());
    }

    public ConnectionPoolStats GetStats()
    {
        return new ConnectionPoolStats
        {
            Provider = _provider,
            TotalConnections = _currentPoolSize,
            ActiveConnections = _activeConnections.Count,
            AvailableConnections = _availableConnections.Count,
            MaxPoolSize = _maxPoolSize,
            MinPoolSize = _minPoolSize
        };
    }
}

public class Connection : IDisposable
{
    public string Id { get; private set; }
    public string Provider { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime LastUsed { get; set; }
    public bool IsDisposed { get; private set; }

    public Connection(string provider, string id)
    {
        Provider = provider;
        Id = id;
        CreatedAt = DateTime.UtcNow;
        LastUsed = DateTime.UtcNow;
        IsDisposed = false;
    }

    public bool IsValid()
    {
        return !IsDisposed && (DateTime.UtcNow - CreatedAt).TotalMinutes < 30;
    }

    public void UpdateLastUsed()
    {
        LastUsed = DateTime.UtcNow;
    }

    public void Dispose()
    {
        IsDisposed = true;
    }
}

public class ConnectionPoolStats
{
    public string Provider { get; set; }
    public int TotalConnections { get; set; }
    public int ActiveConnections { get; set; }
    public int AvailableConnections { get; set; }
    public int MaxPoolSize { get; set; }
    public int MinPoolSize { get; set; }
}

public class AsyncOperationManager
{
    private readonly SemaphoreSlim _semaphore;
    private readonly int _maxConcurrency;

    public AsyncOperationManager(int maxConcurrency = 5)
    {
        _maxConcurrency = maxConcurrency;
        _semaphore = new SemaphoreSlim(maxConcurrency, maxConcurrency);
    }

    public async Task<T> ExecuteAsync<T>(Func<Task<T>> operation)
    {
        await _semaphore.WaitAsync();
        try
        {
            return await operation();
        }
        finally
        {
            _semaphore.Release();
        }
    }

    public int AvailableSlots => _semaphore.CurrentCount;
    public int MaxConcurrency => _maxConcurrency;
}
'@

class PerformanceOptimizer {
    [hashtable] $ConnectionPools
    [hashtable] $CacheManager
    [hashtable] $PerformanceMetrics
    [hashtable] $AsyncOperations
    [int] $MaxConcurrentRequests
    [int] $ConnectionTimeout
    
    PerformanceOptimizer() {
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
        
        $this.InitializeConnectionPools()
        $this.InitializeCacheManager()
        $this.InitializeAsyncManager()
    }
    
    [void] InitializeConnectionPools() {
        # Initialise connection pools for major TTS providers
        $providers = @{
            "Azure" = @{ MinSize = 2; MaxSize = 8 }
            "AWSPolly" = @{ MinSize = 2; MaxSize = 6 }
            "GoogleCloud" = @{ MinSize = 1; MaxSize = 5 }
            "CloudPronouncer" = @{ MinSize = 1; MaxSize = 3 }
            "Twilio" = @{ MinSize = 1; MaxSize = 3 }
            "VoiceForge" = @{ MinSize = 1; MaxSize = 3 }
        }
        
        foreach ($provider in $providers.Keys) {
            try {
                $config = $providers[$provider]
                $pool = [ConnectionPool]::new($provider, $config.MinSize, $config.MaxSize)
                $this.ConnectionPools[$provider] = $pool
                
                Write-ApplicationLog -Message "Initialized connection pool for $provider (Min: $($config.MinSize), Max: $($config.MaxSize))" -Level "INFO"
            } catch {
                Write-ApplicationLog -Message "Failed to Initialise connection pool for $provider`: $_" -Level "ERROR"
            }
        }
    }
    
    [void] InitializeCacheManager() {
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
        
        Write-ApplicationLog -Message "Initialized intelligent caching system with compression support" -Level "INFO"
    }
    
    [void] InitializeAsyncManager() {
        try {
            $this.AsyncOperations["Manager"] = [AsyncOperationManager]::new($this.MaxConcurrentRequests)
            Write-ApplicationLog -Message "Initialized async operation manager (Max Concurrency: $($this.MaxConcurrentRequests))" -Level "INFO"
        } catch {
            Write-ApplicationLog -Message "Failed to Initialise async operation manager: $_" -Level "ERROR"
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
            $recommendations += "Average response time is high ($([math]::Round($metrics.AverageResponseTime))ms). Consider optimizing network connections or increasing connection pool sizes."
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
    
    [void] OptimizeConnectionPools() {
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

# Export functions
function New-PerformanceOptimizer {
    return [PerformanceOptimizer]::new()
}

function Get-PerformanceReport {
    param([PerformanceOptimizer]$Optimizer)
    return $Optimizer.GetPerformanceReport()
}

function Optimize-ConnectionPools {
    param([PerformanceOptimizer]$Optimizer)
    $Optimizer.OptimizeConnectionPools()
}

function Clear-PerformanceCaches {
    param(
        [PerformanceOptimizer]$Optimizer,
        [string[]]$CacheTypes = @()
    )
    $Optimizer.ClearCaches($CacheTypes)
}

# Export module members
Export-ModuleMember -Function @(
    'New-PerformanceOptimizer',
    'Get-PerformanceReport', 
    'Optimize-ConnectionPools',
    'Clear-PerformanceCaches'
) -Variable @() -Cmdlet @() -Alias @()

Write-ApplicationLog -Message "PerformanceOptimization module loaded successfully" -Level "INFO"
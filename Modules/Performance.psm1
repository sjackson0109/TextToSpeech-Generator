# Performance Optimization & Monitoring Module for TextToSpeech Generator
# Advanced performance monitoring, memory management, and intelligent caching

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
    Add-ApplicationLog -Message "Performance monitor initialised" -Level "INFO"
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
            Add-ApplicationLog -Message "Could not Initialise performance counters: $($_.Exception.Message)" -Level "WARNING"
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
        
    Add-ApplicationLog -Message "Started monitoring operation: $operationName" -Level "DEBUG" -Category "Performance"
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
            Add-ApplicationLog -Message "No active operation found for: $operationName" -Level "WARNING"
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
        
    Add-ApplicationLog -Message "Operation $operationName completed in $($duration.TotalSeconds.ToString('F2'))s, Memory delta: $($operation.MemoryDeltaMB)MB" -Level "DEBUG" -Category "Performance"
        
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
                    $report.Recommendations += "Operation '$operationType' is slow (avg: $($summary.AverageDurationMs)ms). Consider optimization."
                }
                
                if ($summary.AverageMemoryDeltaMB -gt 50) {
                    $report.Recommendations += "Operation '$operationType' has high memory usage (avg: $($summary.AverageMemoryDeltaMB)MB). Consider memory optimization."
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
            Add-ApplicationLog -Message "HIGH MEMORY USAGE: Process using $($currentMetrics.ProcessMemoryMB)MB" -Level "WARNING" -Category "Performance"
        }
        
        # CPU threshold alerts (if available)
        if ($currentMetrics.CPUUsagePercent -and $currentMetrics.CPUUsagePercent -gt 90) {
            Add-ApplicationLog -Message "HIGH CPU USAGE: $($currentMetrics.CPUUsagePercent)%" -Level "WARNING" -Category "Performance"
        }
        
        # Garbage collection alerts
        $recentOperations = $this.OperationHistory.Values | ForEach-Object { $_ } | Where-Object { $_.StartTime -gt (Get-Date).AddMinutes(-5) }
        if ($recentOperations.Count -gt 0) {
            $avgMemoryDelta = ($recentOperations | ForEach-Object { $_.MemoryDeltaMB } | Measure-Object -Average).Average
            if ($avgMemoryDelta -gt 100) {
                Add-ApplicationLog -Message "HIGH MEMORY ALLOCATION RATE: Average $([Math]::Round($avgMemoryDelta, 2))MB per operation" -Level "WARNING" -Category "Performance"
            }
        }
    }
}

# Memory management functions
function Optimize-MemoryUsage {
    <#
    .SYNOPSIS
    Optimizes memory usage by forcing garbage collection and cleanup
    #>
    param(
        [int]$MaxMemoryMB = 1024,
        [bool]$ForceCollection = $false
    )
    
    $beforeMemory = [System.GC]::GetTotalMemory($false)
    $beforeProcessMemory = (Get-Process -Id $PID).WorkingSet64
    
    Add-ApplicationLog -Message "Starting memory optimization - Current: $([Math]::Round($beforeMemory / 1MB, 2))MB" -Level "INFO"
    
    if ($ForceCollection -or ($beforeMemory / 1MB) -gt $MaxMemoryMB) {
        # Force garbage collection
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        [System.GC]::Collect()
        
        Start-Sleep -Milliseconds 500
    }
    
    $afterMemory = [System.GC]::GetTotalMemory($false)
    $afterProcessMemory = (Get-Process -Id $PID).WorkingSet64
    
    $memoryFreed = $beforeMemory - $afterMemory
    $processMemoryFreed = $beforeProcessMemory - $afterProcessMemory
    
    Add-ApplicationLog -Message "Memory optimization complete - Freed: $([Math]::Round($memoryFreed / 1MB, 2))MB managed, $([Math]::Round($processMemoryFreed / 1MB, 2))MB process" -Level "INFO"
    
    return @{
        BeforeMemoryMB = [Math]::Round($beforeMemory / 1MB, 2)
        AfterMemoryMB = [Math]::Round($afterMemory / 1MB, 2)
        MemoryFreedMB = [Math]::Round($memoryFreed / 1MB, 2)
        ProcessMemoryFreedMB = [Math]::Round($processMemoryFreed / 1MB, 2)
    }
}

function Test-MemoryPressure {
    <#
    .SYNOPSIS
    Tests if the system is under memory pressure
    #>
    try {
        $totalMemory = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory
        $availableMemory = (Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory * 1024
        $usedMemoryPercent = (($totalMemory - $availableMemory) / $totalMemory) * 100
        
        $processMemory = (Get-Process -Id $PID).WorkingSet64
        $processMemoryPercent = ($processMemory / $totalMemory) * 100
        
        return @{
            IsUnderPressure = $usedMemoryPercent -gt 85 -or $processMemoryPercent -gt 25
            SystemMemoryUsedPercent = [Math]::Round($usedMemoryPercent, 2)
            ProcessMemoryPercent = [Math]::Round($processMemoryPercent, 2)
            AvailableMemoryMB = [Math]::Round($availableMemory / 1MB, 2)
            ProcessMemoryMB = [Math]::Round($processMemory / 1MB, 2)
            Recommendations = @()
        }
    } catch {
        return @{
            IsUnderPressure = $false
            Error = $_.Exception.Message
        }
    }
}

# Caching functions
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
                Add-ApplicationLog -Message "Evicting cache item: $lruKey" -Level "DEBUG"
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

# Global performance monitor and cache instances
$Global:PerformanceMonitor = [PerformanceMonitor]::new()
$Global:IntelligentCache = [IntelligentCache]::new(1000, (New-TimeSpan -Hours 1))

# Public functions
function Start-OperationMonitoring {
    <#
    .SYNOPSIS
    Starts monitoring an operation
    #>
    param([Parameter(Mandatory=$true)][string]$OperationName)
    
    $Global:PerformanceMonitor.StartOperation($OperationName)
}

function Stop-OperationMonitoring {
    <#
    .SYNOPSIS
    Stops monitoring an operation and returns metrics
    #>
    param([Parameter(Mandatory=$true)][string]$OperationName)
    
    return $Global:PerformanceMonitor.EndOperation($OperationName)
}

function Get-PerformanceReport {
    <#
    .SYNOPSIS
    Generates a comprehensive performance report
    #>
    return $Global:PerformanceMonitor.GenerateReport()
}

function Test-PerformanceThresholds {
    <#
    .SYNOPSIS
    Tests performance thresholds and generates alerts
    #>
    $Global:PerformanceMonitor.AlertOnThresholds()
}

function Set-CacheItem {
    <#
    .SYNOPSIS
    Sets an item in the intelligent cache
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Key,
        [Parameter(Mandatory=$true)]$Value,
        [timespan]$TTL = $null
    )
    
    $Global:IntelligentCache.Set($Key, $Value, $TTL)
}

function Get-CacheItem {
    <#
    .SYNOPSIS
    Gets an item from the intelligent cache
    #>
    param([Parameter(Mandatory=$true)][string]$Key)
    
    return $Global:IntelligentCache.Get($Key)
}

function Test-CacheItem {
    <#
    .SYNOPSIS
    Tests if an item exists in the cache
    #>
    param([Parameter(Mandatory=$true)][string]$Key)
    
    return $Global:IntelligentCache.Contains($Key)
}

function Get-CacheStatistics {
    <#
    .SYNOPSIS
    Gets cache usage statistics
    #>
    return $Global:IntelligentCache.GetStatistics()
}

function Clear-PerformanceCache {
    <#
    .SYNOPSIS
    Clears the performance cache
    #>
    $Global:IntelligentCache.Clear()
    Add-ApplicationLog -Message "Performance cache cleared" -Level "INFO"
}

# Export functions
Export-ModuleMember -Function @(
    'Start-OperationMonitoring',
    'Stop-OperationMonitoring',
    'Get-PerformanceReport',
    'Test-PerformanceThresholds',
    'Optimize-MemoryUsage',
    'Test-MemoryPressure',
    'Set-CacheItem',
    'Get-CacheItem',
    'Test-CacheItem',
    'Get-CacheStatistics',
    'Clear-PerformanceCache'
)
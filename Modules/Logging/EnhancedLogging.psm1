# Enhanced Logging Module for TextToSpeech Generator v3.2
# Provides structured logging with performance monitoring and log rotation

# Global variables for logging configuration
$script:LogFilePath = ""
$script:LogLevel = "INFO"
$script:MaxLogSize = 10MB
$script:MaxLogFiles = 5

function Initialise-LoggingSystem {
    <#
    .SYNOPSIS
    Initializes the logging system with configuration options
    
    .DESCRIPTION
    Sets up the logging system with specified configuration including log file path,
    log level, and rotation settings.
    #>
    param(
        [string]$LogPath = (Join-Path $PSScriptRoot "application.log"),
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL")][string]$Level = "INFO",
        [int64]$MaxSizeMB = 10,
        [int]$MaxFiles = 5
    )
    
    $script:LogFilePath = $LogPath
    $script:LogLevel = $Level
    $script:MaxLogSize = $MaxSizeMB * 1MB
    $script:MaxLogFiles = $MaxFiles
    
    # Create log directory if it doesn't exist
    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    Write-ApplicationLog -Message "Logging system initialized - Level: $Level, Path: $LogPath" -Level "INFO"
}

function Write-ApplicationLog {
    <#
    .SYNOPSIS
    Enhanced logging with structured format and performance metrics
    
    .DESCRIPTION
    Provides comprehensive logging with timestamps, levels, structured data,
    and optional performance tracking for debugging and monitoring.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL")][string]$Level = "INFO",
        [hashtable]$Properties = @{},
        [string]$Category = "General"
    )
    
    # Check if we should log this level
    $levelPriority = @{
        "DEBUG" = 0
        "INFO" = 1 
        "WARNING" = 2
        "ERROR" = 3
        "CRITICAL" = 4
    }
    
    if ($levelPriority[$Level] -lt $levelPriority[$script:LogLevel]) {
        return
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $processId = $PID
    $threadId = [Threading.Thread]::CurrentThread.ManagedThreadId
    
    # Create structured log entry
    $logEntry = @{
        Timestamp = $timestamp
        Level = $Level
        Category = $Category
        Message = $Message
        ProcessId = $processId
        ThreadId = $threadId
        Properties = $Properties
        MachineName = $env:COMPUTERNAME
        UserName = $env:USERNAME
    }
    
    # Format for console output
    $consoleEntry = "[$timestamp] [$Level] [$Category] $Message"
    if ($Properties.Count -gt 0) {
        $propsString = ($Properties.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ", "
        $consoleEntry += " | $propsString"
    }
    
    # Color-coded console output
    $color = switch ($Level) {
        "DEBUG" { "Gray" }
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "CRITICAL" { "Magenta" }
    }
    Write-Host $consoleEntry -ForegroundColor $color
    
    # Write to file log with structured format
    try {
        if ($script:LogFilePath -and -not [string]::IsNullOrWhiteSpace($script:LogFilePath)) {
            # Check for log rotation
            if (Test-Path $script:LogFilePath) {
                $logFile = Get-Item $script:LogFilePath
                if ($logFile.Length -gt $script:MaxLogSize) {
                    Invoke-LogRotation
                }
            }
            
            $jsonEntry = $logEntry | ConvertTo-Json -Compress
            Add-Content -Path $script:LogFilePath -Value $jsonEntry -Encoding UTF8
        }
    }
    catch {
        Write-Host "Failed to write to log file: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Update UI log if available
    if ($global:window -and $global:window.LogOutput) {
        try {
            $global:window.Dispatcher.Invoke([Action]{
                $global:window.LogOutput.Text += "$consoleEntry`r`n"
            })
        }
        catch {
            # Silently handle UI update errors during application shutdown
        }
    }
}

function Write-PerformanceLog {
    <#
    .SYNOPSIS
    Logs performance metrics for operations
    #>
    param(
        [string]$Operation,
        [timespan]$Duration,
        [hashtable]$Metrics = @{}
    )
    
    $properties = @{
        Operation = $Operation
        DurationMs = $Duration.TotalMilliseconds
        DurationSeconds = [Math]::Round($Duration.TotalSeconds, 2)
    }
    
    # Add additional metrics
    foreach ($key in $Metrics.Keys) {
        $properties[$key] = $Metrics[$key]
    }
    
    Write-ApplicationLog -Message "Performance: $Operation completed in $([Math]::Round($Duration.TotalSeconds, 2))s" -Level "INFO" -Category "Performance" -Properties $properties
}

function Write-ErrorLog {
    <#
    .SYNOPSIS
    Enhanced error logging with exception details and context
    #>
    param(
        [string]$Operation,
        [System.Exception]$Exception,
        [hashtable]$Context = @{}
    )
    
    $properties = @{
        Operation = $Operation
        ExceptionType = $Exception.GetType().Name
        StackTrace = $Exception.StackTrace
        HResult = $Exception.HResult
    }
    
    # Add context information
    foreach ($key in $Context.Keys) {
        $properties["Context_$key"] = $Context[$key]
    }
    
    # Add system information for critical errors
    if ($Exception.GetType().Name -in @("OutOfMemoryException", "StackOverflowException")) {
        $properties["MemoryUsage"] = [System.GC]::GetTotalMemory($false)
        $properties["ProcessorCount"] = [Environment]::ProcessorCount
    }
    
    Write-ApplicationLog -Message "Error in $Operation`: $($Exception.Message)" -Level "ERROR" -Category "Error" -Properties $properties
}

function Write-SecurityLog {
    <#
    .SYNOPSIS
    Logs security-related events with enhanced tracking
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Event,
        [Parameter(Mandatory=$true)][string]$Action,
        [hashtable]$Details = @{}
    )
    
    $properties = @{
        SecurityEvent = $Event
        Action = $Action
        UserName = $env:USERNAME
        MachineName = $env:COMPUTERNAME
        ProcessId = $PID
    }
    
    # Add additional details
    foreach ($key in $Details.Keys) {
        $properties[$key] = $Details[$key]
    }
    
    Write-ApplicationLog -Message "Security: $Action - $Event" -Level "WARNING" -Category "Security" -Properties $properties
}

function Invoke-LogRotation {
    <#
    .SYNOPSIS
    Rotates log files when they exceed maximum size
    #>
    try {
        if (-not (Test-Path $script:LogFilePath)) {
            return
        }
        
        $logDir = Split-Path $script:LogFilePath -Parent
        $logBaseName = [System.IO.Path]::GetFileNameWithoutExtension($script:LogFilePath)
        $logExtension = [System.IO.Path]::GetExtension($script:LogFilePath)
        
        # Rotate existing log files
        for ($i = $script:MaxLogFiles - 1; $i -gt 0; $i--) {
            $oldFile = Join-Path $logDir "$logBaseName.$i$logExtension"
            $newFile = Join-Path $logDir "$logBaseName.$($i + 1)$logExtension"
            
            if (Test-Path $oldFile) {
                if (Test-Path $newFile) {
                    Remove-Item $newFile -Force
                }
                Move-Item $oldFile $newFile
            }
        }
        
        # Move current log to .1
        $rotatedFile = Join-Path $logDir "$logBaseName.1$logExtension"
        Move-Item $script:LogFilePath $rotatedFile
        
        Write-ApplicationLog -Message "Log rotation completed - archived to $rotatedFile" -Level "INFO"
    }
    catch {
        Write-Host "Failed to rotate log files: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-LogStatistics {
    <#
    .SYNOPSIS
    Returns statistics about the logging system
    #>
    $stats = @{
        LogFilePath = $script:LogFilePath
        LogLevel = $script:LogLevel
        MaxLogSize = $script:MaxLogSize
        MaxLogFiles = $script:MaxLogFiles
    }
    
    if (Test-Path $script:LogFilePath) {
        $logFile = Get-Item $script:LogFilePath
        $stats.CurrentLogSize = $logFile.Length
        $stats.LastModified = $logFile.LastWriteTime
        
        # Count log entries by level (approximate)
        try {
            $content = Get-Content $script:LogFilePath -ErrorAction SilentlyContinue
            $stats.TotalEntries = $content.Count
            $stats.ErrorCount = ($content | Where-Object { $_ -match '"Level":"ERROR"' }).Count
            $stats.WarningCount = ($content | Where-Object { $_ -match '"Level":"WARNING"' }).Count
        }
        catch {
            $stats.TotalEntries = "Unknown"
            $stats.ErrorCount = "Unknown"
            $stats.WarningCount = "Unknown"
        }
    }
    
    return $stats
}

# Export functions
Export-ModuleMember -Function @(
    'Initialise-LoggingSystem',
    'Write-ApplicationLog', 
    'Write-PerformanceLog',
    'Write-ErrorLog',
    'Write-SecurityLog',
    'Invoke-LogRotation',
    'Get-LogStatistics'
)
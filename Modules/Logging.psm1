# Logging Module for TextToSpeech Generator
# Provides structured logging with performance monitoring and log rotation

# Global variables for logging configuration
$script:LogFilePath = ""
$script:LogLevel = "INFO"
$script:MaxLogSize = 10MB
$script:MaxLogFiles = 5

function New-LoggingSystem {
    <#
    .SYNOPSIS
    Initialises the logging system with configuration options
    
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
    
    Add-ApplicationLog -Module "Logging" -Message "Logging system initialised - Path: " + $LogPath -Level "Info"
}

function Add-ApplicationLog {
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
        $Properties = @{},
        [string]$Module = "General"
    )
    # Coerce Properties to hashtable if not already
    if ($null -eq $Properties) {
        $Properties = @{}
    } elseif (-not ($Properties -is [hashtable])) {
        Write-Host "[WARNING] [Logging] Properties parameter was not a hashtable. Coercing to hashtable." -ForegroundColor Yellow
        $Properties = @{ Value = $Properties }
    }
    
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

    # Determine module or filename for traceability
    $invocation = $MyInvocation
    $moduleName = $null
    if ($invocation.MyCommand.Module) {
        $moduleName = $invocation.MyCommand.Module.Name
    } elseif ($invocation.ScriptName) {
        $moduleName = [System.IO.Path]::GetFileName($invocation.ScriptName)
    } else {
        $moduleName = "UnknownModule"
    }

    # Recursively convert nested hashtables/arrays in $Properties to strings
    function Convert-FlatProperty($value) {
        if ($null -eq $value) { return $null }
        elseif ($value -is [hashtable]) {
            return ($value.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ", "
        } elseif ($value -is [array]) {
            return ($value | ForEach-Object { Convert-FlatProperty $_ }) -join ", "
        } else {
            return $value
        }
    }
    $flatProperties = @{}
    foreach ($key in $Properties.Keys) {
        $flatProperties[$key] = Convert-FlatProperty $Properties[$key]
    }
    $logEntry = @{
        Timestamp = $timestamp
        Level = $Level
        category = $moduleName
        Message = $Message
        ProcessId = $processId
        ThreadId = $threadId
        Properties = $flatProperties
        MachineName = $env:COMPUTERNAME
        UserName = $env:USERNAME
    }

    # Format for console output
    $consoleEntry = "[$timestamp] [$Level] [$moduleName] $Message"
    if ($Properties.Count -gt 0) {
        $propsString = ($Properties.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ", "
        $consoleEntry += " | $propsString"
    }
    
    # colour-coded console output
    $colour = switch ($Level) {
        "DEBUG" { "Gray" }
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "CRITICAL" { "Magenta" }
    }
    Write-Host $consoleEntry -ForegroundColor $colour
    
    # Write to file log with structured format
    try {
        if ($script:LogFilePath -and -not [string]::IsNullOrWhiteSpace($script:LogFilePath)) {
            # Check for log rotation
            if (Test-Path $script:LogFilePath) {
                $logFile = Get-Item $script:LogFilePath
                if ($logFile.Length -gt $script:MaxLogSize) {
                    Start-LogRotation
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

function Add-PerformanceLog {
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
    
    Add-ApplicationLog -Module "Logging" -Message "Performance: $Operation completed in $([Math]::Round($Duration.TotalSeconds, 2))s" -Level "INFO" -Properties $properties
}

function Add-ErrorLog {
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
    
    Add-ApplicationLog -Module "Logging" -Message "Error in $Operation`: $($Exception.Message)" -Level "ERROR" -Properties $properties
}

function Add-SecurityLog {
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
    
    Add-ApplicationLog -Module "Logging" -Message "Security: $Action - $Event" -Level "WARNING" -Properties $properties
}

function Start-LogRotation {
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
        
    Add-ApplicationLog -Module "Logging" -Message "Log rotation completed - archived to $rotatedFile" -Level "INFO"
    }
    catch {
        Write-Host "Failed to rotate log files: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-LogStatistics {
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
    'New-LoggingSystem',
    'Add-ApplicationLog',
    'Add-PerformanceLog',
    'Add-ErrorLog',
    'Add-SecurityLog',
    'Start-LogRotation',
    'Show-LogStatistics'
)
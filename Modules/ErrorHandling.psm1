# Standardized Error Handling Module for TextToSpeech Generator v3.2
# Provides consistent error handling patterns across all modules

# Error classification system
$script:ErrorTypes = @{
    Configuration = @{
        Code = "CFG"
        Severity = "High"
        Category = "Configuration"
    }
    Authentication = @{
        Code = "AUTH"  
        Severity = "High"
        Category = "Security"
    }
    Network = @{
        Code = "NET"
        Severity = "Medium"
        Category = "Connectivity"
    }
    RateLimit = @{
        Code = "RATE"
        Severity = "Medium" 
        Category = "ApiLimit"
    }
    Validation = @{
        Code = "VAL"
        Severity = "Medium"
        Category = "DataValidation"
    }
    FileSystem = @{
        Code = "FS"
        Severity = "Medium"
        Category = "FileSystem"
    }
    Provider = @{
        Code = "PROV"
        Severity = "High"
        Category = "TtsProvider"
    }
}

class StandardError {
    [string] $ErrorCode
    [string] $Category
    [string] $Severity
    [string] $Message
    [string] $Operation
    [hashtable] $Context
    [datetime] $Timestamp
    [string] $StackTrace
    
    StandardError([string]$type, [string]$message, [string]$operation) {
        $errorType = $script:ErrorTypes[$type]
        $this.ErrorCode = "$($errorType.Code)-$(Get-Random -Minimum 1000 -Maximum 9999)"
        $this.Category = $errorType.Category
        $this.Severity = $errorType.Severity
        $this.Message = $message
        $this.Operation = $operation
        $this.Context = @{}
        $this.Timestamp = Get-Date
        $this.StackTrace = ""
    }
    
    [void] AddContext([hashtable]$contextData) {
        foreach ($key in $contextData.Keys) {
            $this.Context[$key] = $contextData[$key]
        }
    }
    
    [void] SetStackTrace([string]$stackTrace) {
        $this.StackTrace = $stackTrace
    }
    
    [hashtable] ToHashtable() {
        return @{
            ErrorCode = $this.ErrorCode
            Category = $this.Category
            Severity = $this.Severity
            Message = $this.Message
            Operation = $this.Operation
            Context = $this.Context
            Timestamp = $this.Timestamp
            StackTrace = $this.StackTrace
        }
    }
}

function New-StandardError {
    <#
    .SYNOPSIS
    Creates a new standardized error object
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Configuration", "Authentication", "Network", "RateLimit", "Validation", "FileSystem", "Provider")]
        [string]$Type,
        
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$true)]
        [string]$Operation,
        
        [hashtable]$Context = @{},
        
        [System.Exception]$Exception = $null
    )
    
    $standardError = [StandardError]::new($Type, $Message, $Operation)
    $standardError.AddContext($Context)
    
    if ($Exception) {
        $standardError.SetStackTrace($Exception.StackTrace)
        $standardError.AddContext(@{
            ExceptionType = $Exception.GetType().Name
            HResult = $Exception.HResult
        })
    }
    
    return $standardError
}

function Invoke-WithStandardErrorHandling {
    <#
    .SYNOPSIS
    Wraps operations with standardized error handling
    #>
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$Operation,
        
        [Parameter(Mandatory=$true)]
        [string]$OperationName,
        
        [hashtable]$Context = @{},
        
        [scriptblock]$OnError = $null,
        
        [int]$MaxRetries = 0,
        
        [int]$RetryDelay = 1000
    )
    
    $attempt = 0
    do {
        try {
            Add-ApplicationLog -Message "Starting operation: $OperationName (Attempt $($attempt + 1))" -Level "DEBUG"
            $result = & $Operation
            Add-ApplicationLog -Message "Operation completed successfully: $OperationName" -Level "DEBUG"
            return $result
        }
        catch {
            $attempt++
            $errorType = Get-ErrorTypeFromException -Exception $_.Exception
            
            $standardError = New-StandardError -Type $errorType -Message $_.Exception.Message -Operation $OperationName -Context $Context -Exception $_.Exception
            
            Add-ApplicationLog -Message "Error in $OperationName`: $($_.Exception.Message)" -Level "ERROR" -Category "Error"
            Add-ErrorLog -Operation $OperationName -Exception $_.Exception
            
            # Execute custom error handler if provided
            if ($OnError) {
                & $OnError -Error $standardError
            }
            
            # Retry logic
            if ($attempt -lt ($MaxRetries + 1)) {
                $delay = $RetryDelay * [Math]::Pow(2, $attempt - 1)  # Exponential backoff
                Add-ApplicationLog -Message "Retrying operation $OperationName in $delay ms (Attempt $attempt of $($MaxRetries + 1))" -Level "WARNING"
                Start-Sleep -Milliseconds $delay
                continue
            }
            
            # If we've exhausted retries, throw the standardized error
            throw $standardError.ToHashtable()
        }
    } while ($attempt -le $MaxRetries)
}

function Get-ErrorTypeFromException {
    <#
    .SYNOPSIS
    Determines the error type based on exception characteristics
    #>
    param([System.Exception]$Exception)
    
    $message = $Exception.Message.ToLower()
    
    switch -Regex ($message) {
        "401|unauthorized|authentication|invalid.*key|access.*denied" { return "Authentication" }
        "429|rate.*limit|throttl|quota.*exceeded|too.*many.*requests" { return "RateLimit" }
        "404|not.*found|invalid.*url|connection.*timeout|network" { return "Network" }
        "validation|invalid.*format|required.*field|missing.*parameter" { return "Validation" }
        "file.*not.*found|access.*denied|directory|path" { return "FileSystem" }
        "provider|tts|speech|synthesis" { return "Provider" }
        default { return "Configuration" }
    }
}

function Write-StandardError {
    <#
    .SYNOPSIS
    Logs a standardized error with consistent formatting
    #>
    param(
        [Parameter(Mandatory=$true)]
        [StandardError]$Error,
        
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL")]
        [string]$LogLevel = "ERROR"
    )
    
    $logMessage = "[$($Error.ErrorCode)] $($Error.Message)"
    if ($Error.Context.Count -gt 0) {
        $contextString = ($Error.Context.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ", "
        $logMessage += " | $contextString"
    }
    
    Add-ApplicationLog -Message $logMessage -Level $LogLevel -Category $Error.Category
    
    # For critical errors, also write to event log
    if ($LogLevel -eq "CRITICAL") {
        try {
            Write-EventLog -LogName "Application" -Source "TextToSpeechGenerator" -EventId 1001 -EntryType Error -Message $logMessage
        }
        catch {
            # Silently continue if event log is not available
        }
    }
}

function Get-ErrorRecoveryAction {
    <#
    .SYNOPSIS
    Provides recovery actions based on error type
    #>
    param([StandardError]$Error)
    
    switch ($Error.Category) {
        "Security" {
            return @{
                Action = "CheckCredentials"
                Description = "Verify API keys and authentication settings"
                AutoRecoverable = $false
            }
        }
        "ApiLimit" {
            return @{
                Action = "RetryWithBackoff"
                Description = "Wait and retry with exponential backoff"
                AutoRecoverable = $true
                RetryDelay = 60000
            }
        }
        "Connectivity" {
            return @{
                Action = "RetryWithAlternateProvider"
                Description = "Try alternate provider or check network connectivity"
                AutoRecoverable = $true
                RetryDelay = 5000
            }
        }
        "Configuration" {
            return @{
                Action = "ValidateConfiguration"
                Description = "Check configuration settings and fix invalid values"
                AutoRecoverable = $false
            }
        }
        default {
            return @{
                Action = "ManualIntervention"
                Description = "Manual investigation required"
                AutoRecoverable = $false
            }
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'New-StandardError',
    'Invoke-WithStandardErrorHandling',
    'Get-ErrorTypeFromException',
    'Write-StandardError',
    'Get-ErrorRecoveryAction'
)
# Utilities Module for TextToSpeech Generator v3.2
# Common utility functions and helpers

# File and Path Utilities
function Clear-FileName {
    <#
    .SYNOPSIS
    Clears invalid characters from a filename by removing or replacing them
    #>
    param(
        [Parameter(Mandatory=$true)][string]$FileName,
        [string]$Replacement = "_"
    )
    
    # Define invalid characters for Windows filenames
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    
    # Replace invalid characters
    $sanitized = $FileName
    foreach ($char in $invalidChars) {
        $sanitized = $sanitized.Replace($char, $Replacement)
    }
    
    # Remove excessive dots and spaces
    $sanitized = $sanitized -replace '\.{2,}', '.'  # Multiple dots
    $sanitized = $sanitized -replace '\s{2,}', ' '  # Multiple spaces
    $sanitized = $sanitized.Trim()
    
    # Ensure filename is not empty or just dots
    if ([string]::IsNullOrWhiteSpace($sanitized) -or $sanitized -match '^\.+$') {
        $sanitized = "unnamed_file"
    }
    
    # Truncate if too long (Windows has 255 character limit)
    if ($sanitized.Length -gt 200) {
        $sanitized = $sanitized.Substring(0, 200)
    }
    
    return $sanitized
}

function Test-PathWritable {
    <#
    .SYNOPSIS
    Tests if a path is writable
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Path
    )
    
    try {
        $testFile = Join-Path $Path "writetest_$(Get-Random).tmp"
        "test" | Out-File -FilePath $testFile -Force
        Remove-Item $testFile -Force
        return $true
    }
    catch {
        return $false
    }
}

function Get-SafeOutputPath {
    <#
    .SYNOPSIS
    Generates a safe output path, creating directories if needed
    #>
    param(
        [Parameter(Mandatory=$true)][string]$BaseDirectory,
        [Parameter(Mandatory=$true)][string]$FileName,
        [string]$Extension = ".mp3"
    )
    
    # Ensure base directory exists
    if (-not (Test-Path $BaseDirectory)) {
        New-Item -ItemType Directory -Path $BaseDirectory -Force | Out-Null
    }
    
    # Sanitize filename
    $sanitizedName = Clear-FileName -FileName $FileName
    
    # Add extension if not present
    if (-not $sanitizedName.EndsWith($Extension)) {
        $sanitizedName += $Extension
    }
    
    $outputPath = Join-Path $BaseDirectory $sanitizedName
    
    # Handle duplicate names by adding number suffix
    $counter = 1
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($sanitizedName)
    
    while (Test-Path $outputPath) {
        $numberedName = "${baseName}_${counter}${Extension}"
        $outputPath = Join-Path $BaseDirectory $numberedName
        $counter++
        
        # Prevent infinite loop
        if ($counter -gt 1000) {
            $outputPath = Join-Path $BaseDirectory "${baseName}_$(Get-Random)${Extension}"
            break
        }
    }
    
    return $outputPath
}

# Text Processing Utilities
function Split-TextIntoChunks {
    <#
    .SYNOPSIS
    Splits long text into smaller chunks for TTS processing
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Text,
        [int]$MaxChunkSize = 3000,
        [string[]]$SplitOn = @(".", "!", "?", ";", "`n")
    )
    
    if ($Text.Length -le $MaxChunkSize) {
        return @($Text)
    }
    
    $chunks = @()
    $currentChunk = ""
    $sentences = $Text -split "(?<=[.!?;])\s+"
    
    foreach ($sentence in $sentences) {
        if (($currentChunk + $sentence).Length -le $MaxChunkSize) {
            $currentChunk += $sentence + " "
        } else {
            if ($currentChunk.Trim()) {
                $chunks += $currentChunk.Trim()
            }
            
            # Handle very long sentences that exceed chunk size
            if ($sentence.Length -gt $MaxChunkSize) {
                $words = $sentence -split "\s+"
                $wordChunk = ""
                
                foreach ($word in $words) {
                    if (($wordChunk + $word).Length -le $MaxChunkSize) {
                        $wordChunk += $word + " "
                    } else {
                        if ($wordChunk.Trim()) {
                            $chunks += $wordChunk.Trim()
                        }
                        $wordChunk = $word + " "
                    }
                }
                
                $currentChunk = $wordChunk
            } else {
                $currentChunk = $sentence + " "
            }
        }
    }
    
    if ($currentChunk.Trim()) {
        $chunks += $currentChunk.Trim()
    }
    
    return $chunks
}

function Format-TextForTTS {
    <#
    .SYNOPSIS
    Formats text for optimal TTS processing
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Text,
        [bool]$ExpandAbbreviations = $true,
        [bool]$NormalizeNumbers = $true,
        [bool]$HandleSymbols = $true
    )
    
    $formatted = $Text
    
    if ($ExpandAbbreviations) {
        # Common abbreviations
        $abbreviations = @{
            "Mr\." = "Mister"
            "Mrs\." = "Missus"
            "Dr\." = "Doctor"
            "Prof\." = "Professor"
            "etc\." = "etcetera"
            "vs\." = "versus"
            "e\.g\." = "for example"
            "i\.e\." = "that is"
        }
        
        foreach ($abbrev in $abbreviations.Keys) {
            $formatted = $formatted -replace $abbrev, $abbreviations[$abbrev]
        }
    }
    
    if ($NormalizeNumbers) {
        # Convert simple numbers to words (basic implementation)
        $formatted = $formatted -replace "\b(\d{1,2})\b", { Convert-NumberToWords $_.Groups[1].Value }
    }
    
    if ($HandleSymbols) {
        # Replace common symbols with words
        $formatted = $formatted -replace "&", "and"
        $formatted = $formatted -replace "@", "at"
        $formatted = $formatted -replace "%", "percent"
        $formatted = $formatted -replace "\$", "dollar"
        $formatted = $formatted -replace "#", "number"
    }
    
    # Clean up extra whitespace
    $formatted = $formatted -replace "\s+", " "
    $formatted = $formatted.Trim()
    
    return $formatted
}

function Convert-NumberToWords {
    <#
    .SYNOPSIS
    Converts simple numbers (0-99) to words
    #>
    param(
        [int]$Number
    )
    
    $ones = @("zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine")
    $teens = @("ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen")
    $tens = @("", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety")
    
    if ($Number -lt 10) {
        return $ones[$Number]
    } elseif ($Number -lt 20) {
        return $teens[$Number - 10]
    } elseif ($Number -lt 100) {
        $tenDigit = [Math]::Floor($Number / 10)
        $oneDigit = $Number % 10
        
        if ($oneDigit -eq 0) {
            return $tens[$tenDigit]
        } else {
            return "$($tens[$tenDigit]) $($ones[$oneDigit])"
        }
    } else {
        return $Number.ToString()  # Return as-is for larger numbers
    }
}

# System Utilities
function Get-OptimalThreadCount {
    <#
    .SYNOPSIS
    Calculates optimal thread count based on system resources and workload
    #>
    param(
        [int]$ItemCount,
        [int]$MaxThreads = 8,
        [string]$WorkloadType = "TTS"
    )
    
    $cpuCores = [Environment]::ProcessorCount
    $availableMemory = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty FreePhysicalMemory
    $availableMemoryMB = $availableMemory / 1024
    
    # Base calculation on CPU cores
    $optimalThreads = [Math]::Min($cpuCores, $MaxThreads)
    
    # Adjust based on workload size
    $threadsByWorkload = switch ($ItemCount) {
        {$_ -le 4} { 2 }
        {$_ -le 10} { [Math]::Min(3, $cpuCores) }
        {$_ -le 50} { [Math]::Min(4, $cpuCores) }
        default { [Math]::Min($MaxThreads, $cpuCores) }
    }
    
    # Adjust based on available memory (assuming ~50MB per thread for TTS)
    $memoryBasedThreads = [Math]::Floor($availableMemoryMB / 50)
    
    # Take the minimum to avoid resource exhaustion
    $finalThreads = [Math]::Min(@($optimalThreads, $threadsByWorkload, $memoryBasedThreads, $MaxThreads))
    
    # Always use at least 1 thread
    return [Math]::Max(1, $finalThreads)
}

function Test-SystemRequirements {
    <#
    .SYNOPSIS
    Tests if the system meets requirements for the application
    #>
    $requirements = @{
        PowerShellVersion = @{
            Required = [Version]"5.1"
            Current = $PSVersionTable.PSVersion
            Met = $PSVersionTable.PSVersion -ge [Version]"5.1"
        }
        DotNetVersion = @{
            Required = "4.7.2"
            Current = "Unknown"
            Met = $true  # Assume met for now
        }
        AvailableMemory = @{
            Required = 500  # MB
            Current = 0
            Met = $false
        }
        DiskSpace = @{
            Required = 100  # MB
            Current = 0
            Met = $false
        }
    }
    
    # Check memory
    try {
        $memory = Get-CimInstance -ClassName Win32_OperatingSystem
        $requirements.AvailableMemory.Current = [Math]::Round($memory.FreePhysicalMemory / 1024, 0)
        $requirements.AvailableMemory.Met = $requirements.AvailableMemory.Current -ge $requirements.AvailableMemory.Required
    } catch {
        $requirements.AvailableMemory.Current = "Unknown"
    }
    
    # Check disk space
    try {
        $drive = Get-PSDrive -Name C -ErrorAction SilentlyContinue
        if ($drive) {
            $requirements.DiskSpace.Current = [Math]::Round($drive.Free / 1MB, 0)
            $requirements.DiskSpace.Met = $requirements.DiskSpace.Current -ge $requirements.DiskSpace.Required
        }
    } catch {
        $requirements.DiskSpace.Current = "Unknown"
    }
    
    $requirements.OverallStatus = ($requirements.Values | Where-Object { $_.Met -eq $false }).Count -eq 0
    
    return $requirements
}

# Data Validation Utilities
function Test-EmailFormat {
    <#
    .SYNOPSIS
    Validates email address format
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Email
    )
    
    return $Email -match '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
}

function Test-URLFormat {
    <#
    .SYNOPSIS
    Validates URL format
    #>
    param(
        [Parameter(Mandatory=$true)][string]$URL
    )
    
    try {
        $uri = [System.Uri]::new($URL)
        return $uri.Scheme -in @("http", "https")
    } catch {
        return $false
    }
}

function ConvertTo-SafeString {
    <#
    .SYNOPSIS
    Converts input to a safe string for logging/display
    #>
    param(
        [Parameter(Mandatory=$true)]$InputObject,
        [int]$MaxLength = 100,
        [bool]$MaskSensitive = $true
    )
    
    $stringValue = if ($InputObject -is [string]) {
        $InputObject
    } else {
        $InputObject.ToString()
    }
    
    # Mask sensitive patterns if requested
    if ($MaskSensitive) {
        $sensitivePatterns = @(
            @{ Pattern = 'APIKey["\s:=]+([^"\s}]+)'; Replacement = 'APIKey=***MASKED***' }
            @{ Pattern = 'Password["\s:=]+([^"\s}]+)'; Replacement = 'Password=***MASKED***' }
            @{ Pattern = 'Secret["\s:=]+([^"\s}]+)'; Replacement = 'Secret=***MASKED***' }
            @{ Pattern = 'Token["\s:=]+([^"\s}]+)'; Replacement = 'Token=***MASKED***' }
        )
        
        foreach ($pattern in $sensitivePatterns) {
            $stringValue = $stringValue -replace $pattern.Pattern, $pattern.Replacement
        }
    }
    
    # Truncate if too long
    if ($stringValue.Length -gt $MaxLength) {
        $stringValue = $stringValue.Substring(0, $MaxLength - 3) + "..."
    }
    
    return $stringValue
}

function Test-PathSecurity {
    <#
    .SYNOPSIS
    Validates that a file path is secure and prevents path traversal attacks
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [string]$AllowedBasePath = $null
    )
    
    $securityResult = @{
        IsSecure = $false
        Issues = @()
        ResolvedPath = ""
    }
    
    try {
        # Resolve the path to its absolute form
        $resolvedPath = [System.IO.Path]::GetFullPath($Path)
        $securityResult.ResolvedPath = $resolvedPath
        
        # Check for path traversal attempts
        if ($Path -match '\.\.' -or $resolvedPath -match '\.\.') {
            $securityResult.Issues += "Path traversal detected"
        }
        
        # Check for suspicious characters
        if ($Path -match '[<>|?*]' -or $Path -match '[\x00-\x1F]') {
            $securityResult.Issues += "Invalid characters detected"
        }
        
        # Check against allowed base path if provided
        if ($AllowedBasePath) {
            $allowedBase = [System.IO.Path]::GetFullPath($AllowedBasePath)
            if (-not $resolvedPath.StartsWith($allowedBase)) {
                $securityResult.Issues += "Path outside allowed directory"
            }
        }
        
        # Check for system directories (Windows)
        $systemPaths = @(
            "$env:WINDIR",
            "$env:SystemRoot", 
            "${env:ProgramFiles}",
            "${env:ProgramFiles(x86)}"
        )
        
        foreach ($sysPath in $systemPaths) {
            if ($sysPath -and $resolvedPath.StartsWith($sysPath)) {
                $securityResult.Issues += "Attempted access to system directory"
                break
            }
        }
        
        $securityResult.IsSecure = ($securityResult.Issues.Count -eq 0)
        
    }
    catch {
        $securityResult.Issues += "Invalid path format: $($_.Exception.Message)"
    }
    
    return $securityResult
}

function Test-InputSanitization {
    <#
    .SYNOPSIS
    Tests input for common security issues and provides sanitized output
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Input,
        [ValidateSet("FileName", "FilePath", "TextContent", "APIKey", "URL")]
        [string]$InputType = "TextContent"
    )
    
    $sanitizationResult = @{
        IsClean = $false
        SanitizedValue = ""
        Issues = @()
        OriginalValue = $Input
    }
    
    switch ($InputType) {
        "FileName" {
            $sanitized = Clear-FileName -FileName $Input
            if ($sanitized -ne $Input) {
                $sanitizationResult.Issues += "Filename contained invalid characters"
            }
            $sanitizationResult.SanitizedValue = $sanitized
        }
        
        "FilePath" {
            $pathSecurity = Test-PathSecurity -Path $Input
            $sanitizationResult.Issues += $pathSecurity.Issues
            $sanitizationResult.SanitizedValue = $pathSecurity.ResolvedPath
        }
        
        "TextContent" {
            $sanitized = ConvertTo-SafeString -InputString $Input
            if ($sanitized -ne $Input) {
                $sanitizationResult.Issues += "Text content contained potentially unsafe characters"
            }
            $sanitizationResult.SanitizedValue = $sanitized
        }
        
        "APIKey" {
            # Basic API key validation
            if ($Input -match '[<>&"''\x00-\x1F]') {
                $sanitizationResult.Issues += "API key contains invalid characters"
            }
            if ($Input.Length -lt 10) {
                $sanitizationResult.Issues += "API key appears too short"
            }
            if ($Input -match "(test|demo|example|placeholder|your-api-key)") {
                $sanitizationResult.Issues += "API key appears to be a placeholder"
            }
            $sanitizationResult.SanitizedValue = $Input.Trim()
        }
        
        "URL" {
            if (-not (Test-URLFormat -URL $Input)) {
                $sanitizationResult.Issues += "Invalid URL format"
            }
            $sanitizationResult.SanitizedValue = $Input.Trim()
        }
    }
    
    $sanitizationResult.IsClean = ($sanitizationResult.Issues.Count -eq 0)
    return $sanitizationResult
}

# Export functions
Export-ModuleMember -Function @(
    'Clear-FileName',
    'Test-PathWritable',
    'Get-SafeOutputPath',
    'Split-TextIntoChunks',
    'Format-TextForTTS',
    'Convert-NumberToWords',
    'Get-OptimalThreadCount',
    'Test-SystemRequirements',
    'Test-EmailFormat',
    'Test-URLFormat',
    'ConvertTo-SafeString',
    'Test-PathSecurity',
    'Test-InputSanitization'
)
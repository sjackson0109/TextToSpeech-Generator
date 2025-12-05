# Returns a table of available providers with details
function Get-AvailableProviders {
    <#
    .SYNOPSIS
    Returns a table of all available TTS providers with metadata
    #>
    $table = @()
    foreach ($providerName in $script:LoadedProviders.Keys) {
        $info = $script:LoadedProviders[$providerName]
        $modulePath = $info.ModulePath
        # Import module if not already loaded
        if ($modulePath -and -not (Get-Module -Name $info.ModuleName)) {
            Import-Module $modulePath -Force -Global -ErrorAction SilentlyContinue
        }
        # Try to get provider metadata
        $providerInfo = $null
        try {
            if (Get-Command Get-TTSProviderInfo -Module $info.ModuleName -ErrorAction SilentlyContinue) {
                $providerInfo = & (Get-Command Get-TTSProviderInfo -Module $info.ModuleName)
            }
        } catch {}
        if ($providerInfo -and $providerInfo.Name -and $providerInfo.DisplayName) {
            $table += [PSCustomObject]@{
                Name        = $providerInfo.Name
                DisplayName = $providerInfo.DisplayName
                Description = $providerInfo.Description
                Status      = $info.Status
                ModulePath  = $modulePath
            }
        } else {
            $table += [PSCustomObject]@{
                Name        = $providerName
                DisplayName = $providerName
                Description = ''
                Status      = $info.Status
                ModulePath  = $modulePath
            }
        }
    }
    return $table
}
# AllProviders Module - TTS Provider Orchestrator
# Dynamically discovers and loads all TTS provider modules
if (-not (Get-Module -Name 'Logging')) {
	Import-Module (Resolve-Path (Join-Path $PSScriptRoot '.\Logging.psm1')).Path
}
$ProvidersPath = Join-Path (Split-Path $PSScriptRoot -Parent) "providers"

Write-Verbose "AllProviders module initialising from: $PSScriptRoot"
Write-Verbose "Looking for provider modules in: $ProvidersPath"

# Registry of loaded providers
$script:LoadedProviders = @{}
$script:ProviderModules = @()


function Import-TTSProviderModule {
    <#
    .SYNOPSIS
    Imports a TTS provider module
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProviderPath,
        [string]$ProviderName
    )
    
    try {
        Write-Verbose "Attempting to load provider module: $ProviderPath"
        Import-Module $ProviderPath -Force -Global -ErrorAction Stop
        
        $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($ProviderPath)
        $script:ProviderModules += $moduleName
        
        if ($ProviderName) {
            $script:LoadedProviders[$ProviderName] = @{
                ModulePath = $ProviderPath
                ModuleName = $moduleName
                LoadedAt = Get-Date
                Status = "Loaded"
            }
        }
        
    Add-ApplicationLog -Module "Providers" -Message "Loaded module: $moduleName" -Level "INFO"
        return $true
    }
    catch {
    Add-ApplicationLog -Module "Providers" -Message "Failed to load provider module $ProviderPath : $($_.Exception.Message)" -Level "WARNING"
        Add-ApplicationLog -Module "Providers" -Message "Failed to load provider module $ProviderPath : $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Initialise-TTSProviders {
    <#
    .SYNOPSIS
    Discovers and loads all TTS provider modules
    #>
    
    Add-ApplicationLog -Module "Providers" -Message "Initialising TTS providers" -Level "INFO"
    
    # Check if Providers directory exists
    if (-not (Test-Path $ProvidersPath)) {
        Add-ApplicationLog -Module "Providers" -Message "Providers directory not found: $ProvidersPath" -Level "WARNING"
        Add-ApplicationLog -Module "Providers" -Message "Creating Providers directory: $ProvidersPath" -Level "INFO"
        New-Item -ItemType Directory -Path $ProvidersPath -Force | Out-Null
    }
    
    $loadedCount = 0
    $failedCount = 0

    # Dynamically discover all provider modules in Providers directory
    $providerFiles = Get-ChildItem -Path $ProvidersPath -Filter "*.psm1" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch "^DECOM-" }

    foreach ($providerFile in $providerFiles) {
        $providerName = $providerFile.BaseName
        if (Import-TTSProviderModule -ProviderPath $providerFile.FullName -ProviderName $providerName) {
            $loadedCount++
            Add-ApplicationLog -Module "Providers" -Message "OK Loaded provider: $providerName" -Level "INFO"
        }
        else {
            $failedCount++
            Add-ApplicationLog -Module "Providers" -Message "FAILED to load: $providerName" -Level "ERROR"
        }
    }
    
    Add-ApplicationLog -Module "Providers" -Message "TTS Providers initialised: $loadedCount loaded, $failedCount failed" -Level "INFO"
    
    return @{
        LoadedCount = $loadedCount
        FailedCount = $failedCount
        Providers = $script:LoadedProviders.Keys
    }
}

function Test-TTSProviderCapabilities {
    <#
    .SYNOPSIS
    Tests and reports capabilities of all loaded TTS providers
    #>
    
    Add-ApplicationLog -Module "Providers" -Message "Testing TTS provider capabilities" -Level "INFO"
    
    $results = @{}
    
    foreach ($providerName in $script:LoadedProviders.Keys) {
        try {
            # Try to get provider-specific test function
            $testFunctionName = "Test-${providerName}Capabilities" -replace "\s", ""
            
            if (Get-Command $testFunctionName -ErrorAction SilentlyContinue) {
                $results[$providerName] = & $testFunctionName
            }
            else {
                # Default capability report
                $results[$providerName] = @{
                    Status = "Available"
                    Capabilities = @{
                        MaxTextLength = 5000
                        SupportedFormats = @("mp3", "wav")
                        SupportsSSML = $true
                    }
                    AvailableVoices = 0
                    Message = "Provider loaded successfully"
                }
            }
        }
        catch {
            $results[$providerName] = @{
                Status = "Error"
                Error = $_.Exception.Message
                Message = "Provider test failed"
            }
        }
    }
    
    # Add any providers that failed to load (dynamically)
    $providerFiles = Get-ChildItem -Path $ProvidersPath -Filter "*.psm1" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch "^DECOM-" }
    foreach ($providerFile in $providerFiles) {
        $providerName = $providerFile.BaseName
        if (-not $results.ContainsKey($providerName)) {
            $results[$providerName] = @{
                Status = "Not Loaded"
                Message = "Provider module not found or failed to load"
            }
        }
    }
    
    return $results
}

function Get-TTSProvider {
    <#
    .SYNOPSIS
    Gets a TTS provider instance by name
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProviderName
    )
    
    if ($script:LoadedProviders.ContainsKey($ProviderName)) {
        $providerInfo = $script:LoadedProviders[$ProviderName]
        
        # Check if we already have a class instance
        if ($providerInfo.Instance) {
            return $providerInfo.Instance
        }
        
        # Create provider class instance using factory function from module
        try {
            # Dynamically find factory function for provider
            $factoryFunction = "New-${ProviderName}TTSProviderInstance" -replace "[\s-]", ""
            if (Get-Command -Name $factoryFunction -ErrorAction SilentlyContinue) {
                $instance = & $factoryFunction
            } else {
                $instance = $null
            }
            if ($instance) {
                $providerInfo.Instance = $instance
                Add-ApplicationLog -Module "Providers" -Message "Created provider instance for: $ProviderName" -Level "DEBUG"
                return $instance
            }
        } catch {
            Add-ApplicationLog -Module "Providers" -Message "Failed to create provider instance for ${ProviderName}: $($_.Exception.Message)" -Level "WARNING"
        }
        # Fall back to metadata
        return $providerInfo
    }
    
    Add-ApplicationLog -Module "Providers" -Message "Provider not found: $ProviderName" -Level "WARNING"
    return $null
}

function Get-AvailableTTSProviders {
    <#
    .SYNOPSIS
    Returns list of all available TTS providers
    #>
    
    return $script:LoadedProviders.Keys | Sort-Object
}

function Register-TTSProvider {
    <#
    .SYNOPSIS
    Manually registers a TTS provider
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProviderName,
        [Parameter(Mandatory=$true)]
        [hashtable]$ProviderInfo
    )
    
    $script:LoadedProviders[$ProviderName] = $ProviderInfo
    Add-ApplicationLog -Module "Providers" -Message "Registered TTS provider: $ProviderName" -Level "INFO"
}

function Get-ProviderStatus {
    <#
    .SYNOPSIS
    Gets status of all providers
    #>
    
    $status = @{
        TotalProviders = $script:LoadedProviders.Count
        LoadedProviders = $script:LoadedProviders.Keys | Sort-Object
        ProviderDetails = @{}
    }
    
    foreach ($providerName in $script:LoadedProviders.Keys) {
        $status.ProviderDetails[$providerName] = $script:LoadedProviders[$providerName]
    }
    
    return $status
}

# Initialise providers on module load
$initResult = Initialise-TTSProviders

if ($initResult.LoadedCount -eq 0) {
    Add-ApplicationLog -Module "Providers" -Message "No provider modules found in Providers directory." -Level "WARNING"
    Add-ApplicationLog -Module "Providers" -Message "To add TTS providers, create provider modules in: $ProvidersPath" -Level "INFO"
}
else {
    Add-ApplicationLog -Module "Providers" -Message "Successfully loaded $($initResult.LoadedCount) TTS provider(s)" -Level "INFO"
}

# Export functions
function Show-ProviderConfiguration {
    <#
    .SYNOPSIS
    Shows the configuration Dialogue for a specific TTS provider
    .PARAMETER Provider
    The name of the provider (e.g., "Any available provider module name")
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Provider
    )
    
    try {
        Add-ApplicationLog -Message "Opening configuration Dialogue for provider: $Provider" -Level "INFO"
        
        # Dynamically map provider name to setup function
        $setupFunction = "Show-${Provider}ProviderSetup" -replace "[\s-]", ""
        if (-not (Get-Command $setupFunction -ErrorAction SilentlyContinue)) {
            Add-ApplicationLog -Message "Provider setup function '$setupFunction' not found for provider: $Provider" -Level "WARNING"
            [System.Windows.MessageBox]::Show(
                "Configuration function for $Provider is not yet implemented.`n`nFunction expected: $setupFunction",
                "Provider Configuration",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning
            )
            return
        }
        # Call the provider-specific setup function
        Add-ApplicationLog -Message "Calling provider setup function: $setupFunction" -Level "INFO"
        & $setupFunction
        
    } catch {
        Add-ApplicationLog -Message "Error opening provider configuration: $($_.Exception.Message)" -Level "ERROR"
        [System.Windows.MessageBox]::Show(
            "Failed to open configuration for $Provider`:`n`n$($_.Exception.Message)",
            "Configuration Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        )
    }
}

Export-ModuleMember -Function @(
    'Test-TTSProviderCapabilities',
    'Get-TTSProvider',
    'Get-AvailableTTSProviders',
    'Get-AvailableProviders',
    'Register-TTSProvider',
    'Get-ProviderStatus',
    'Import-TTSProviderModule',
    'Show-ProviderConfiguration'
)
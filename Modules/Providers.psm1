# AllProviders Module - TTS Provider Orchestrator
# Dynamically discovers and loads all TTS provider modules
if (-not (Get-Module -Name 'Logging')) {
	Import-Module (Resolve-Path (Join-Path $PSScriptRoot '.\Logging.psm1')).Path
}
$ModulePath = $PSScriptRoot
$ProvidersPath = Join-Path $ModulePath "Providers"

Write-Verbose "AllProviders module initialising from: $ModulePath"
Write-Verbose "Looking for provider modules in: $ProvidersPath"

# Registry of loaded providers
$script:LoadedProviders = @{}
$script:ProviderModules = @()

# Pre-defined provider module names (alphabetical order)
$script:KnownProviders = @(
    "AWS Polly.psm1",
    "ElevenLabs.psm1",
    "Google Cloud.psm1",
    "Microsoft Azure.psm1",
    "Murf AI.psm1",
    "OpenAI.psm1",
    "Telnyx.psm1",
    "Twilio.psm1"
)

function Import-TTSProviderModule {
    <#
    .SYNOPSIS
    Imports a TTS provider module
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModulePath,
        [string]$ProviderName
    )
    
    try {
        Write-Verbose "Attempting to load provider module: $ModulePath"
        Import-Module $ModulePath -Force -Global -ErrorAction Stop
        
        $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($ModulePath)
        $script:ProviderModules += $moduleName
        
        if ($ProviderName) {
            $script:LoadedProviders[$ProviderName] = @{
                ModulePath = $ModulePath
                ModuleName = $moduleName
                LoadedAt = Get-Date
                Status = "Loaded"
            }
        }
        
    Add-ApplicationLog -Module "AllProviders" -Message "Loaded module: $moduleName" -Level "INFO"
        return $true
    }
    catch {
    Add-ApplicationLog -Module "AllProviders" -Message "Failed to load provider module $ModulePath : $($_.Exception.Message)" -Level "WARNING"
        Add-ApplicationLog -Module "AllProviders" -Message "Failed to load provider module $ModulePath : $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Initialise-TTSProviders {
    <#
    .SYNOPSIS
    Discovers and loads all TTS provider modules
    #>
    
    Add-ApplicationLog -Module "AllProviders" -Message "Initialising TTS providers" -Level "INFO"
    
    # Check if Providers directory exists
    if (-not (Test-Path $ProvidersPath)) {
    Add-ApplicationLog -Module "AllProviders" -Message "Providers directory not found: $ProvidersPath" -Level "WARNING"
    Add-ApplicationLog -Module "AllProviders" -Message "Creating Providers directory: $ProvidersPath" -Level "INFO"
        New-Item -ItemType Directory -Path $ProvidersPath -Force | Out-Null
    }
    
    $loadedCount = 0
    $failedCount = 0
    
    # Load pre-defined providers first (in order)
    foreach ($providerFile in $script:KnownProviders) {
        $providerPath = Join-Path $ProvidersPath $providerFile
        
        if (Test-Path $providerPath) {
            # Extract provider name from filename
            $providerName = $providerFile -replace "\.psm1$", "" -replace "^DECOM-", ""
            $providerName = switch ($providerName) {
                "AWS Polly" { "AWS Polly" }
                "ElevenLabs" { "ElevenLabs" }
                "Google Cloud" { "Google Cloud" }
                "Microsoft Azure" { "Microsoft Azure" }
                "Murf AI" { "Murf AI" }
                "OpenAI" { "OpenAI" }
                "Telnyx" { "Telnyx" }
                "Twilio" { "Twilio" }
                default { $providerName }
            }
            
            if (Import-TTSProviderModule -ModulePath $providerPath -ProviderName $providerName) {
                $loadedCount++
                Add-ApplicationLog -Module "AllProviders" -Message "OK Loaded provider: $providerName" -Level "INFO"
            }
            else {
                $failedCount++
                Add-ApplicationLog -Module "AllProviders" -Message "FAILED to load: $providerName" -Level "ERROR"
            }
        }
        else {
            Write-Verbose "Provider module not found: $providerPath"
        }
    }
    
    # Discover any additional provider modules not in the known list
    $additionalProviders = Get-ChildItem -Path $ProvidersPath -Filter "*.psm1" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin $script:KnownProviders -and $_.Name -notmatch "^DECOM-" }
    
    foreach ($providerFile in $additionalProviders) {
        $providerName = $providerFile.BaseName
        
        if (Import-TTSProviderModule -ModulePath $providerFile.FullName -ProviderName $providerName) {
            $loadedCount++
            Add-ApplicationLog -Module "AllProviders" -Message "OK Loaded additional provider: $providerName" -Level "INFO"
        }
        else {
            $failedCount++
        }
    }
    
    Add-ApplicationLog -Module "AllProviders" -Message "TTS Providers initialised: $loadedCount loaded, $failedCount failed" -Level "INFO"
    
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
    
    Add-ApplicationLog -Module "AllProviders" -Message "Testing TTS provider capabilities" -Level "INFO"
    
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
    
    # Add any providers that failed to load
    $allProviderNames = @("AWS Polly", "ElevenLabs", "Google Cloud", "Microsoft Azure", "Murf AI", "OpenAI", "Telnyx", "Twilio")
    foreach ($providerName in $allProviderNames) {
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
            $instance = switch ($ProviderName) {
                "AWS Polly" { 
                    if (Get-Command -Name "New-AWSPollyTTSProviderInstance" -ErrorAction SilentlyContinue) {
                        New-AWSPollyTTSProviderInstance
                    } else { $null }
                }
                "ElevenLabs" { 
                    if (Get-Command -Name "New-ElevenLabsTTSProviderInstance" -ErrorAction SilentlyContinue) {
                        New-ElevenLabsTTSProviderInstance
                    } else { $null }
                }
                "Google Cloud" { 
                    if (Get-Command -Name "New-GoogleCloudTTSProviderInstance" -ErrorAction SilentlyContinue) {
                        New-GoogleCloudTTSProviderInstance
                    } else { $null }
                }
                "Microsoft Azure" { 
                    if (Get-Command -Name "New-AzureTTSProviderInstance" -ErrorAction SilentlyContinue) {
                        New-AzureTTSProviderInstance
                    } else { $null }
                }
                "Murf AI" { 
                    if (Get-Command -Name "New-MurfAITTSProviderInstance" -ErrorAction SilentlyContinue) {
                        New-MurfAITTSProviderInstance
                    } else { $null }
                }
                "OpenAI" { 
                    if (Get-Command -Name "New-OpenAITTSProviderInstance" -ErrorAction SilentlyContinue) {
                        New-OpenAITTSProviderInstance
                    } else { $null }
                }
                "Telnyx" { 
                    if (Get-Command -Name "New-TelnyxTTSProviderInstance" -ErrorAction SilentlyContinue) {
                        New-TelnyxTTSProviderInstance
                    } else { $null }
                }
                "Twilio" { 
                    if (Get-Command -Name "New-TwilioTTSProviderInstance" -ErrorAction SilentlyContinue) {
                        New-TwilioTTSProviderInstance
                    } else { $null }
                }
                default { $null }
            }
            
            if ($instance) {
                $providerInfo.Instance = $instance
                Add-ApplicationLog -Module "AllProviders" -Message "Created provider instance for: $ProviderName" -Level "DEBUG"
                return $instance
            }
        } catch {
            Add-ApplicationLog -Module "AllProviders" -Message "Failed to create provider instance for ${ProviderName}: $($_.Exception.Message)" -Level "WARNING"
        }
        
        # Fall back to metadata
        return $providerInfo
    }
    
    Add-ApplicationLog -Module "AllProviders" -Message "Provider not found: $ProviderName" -Level "WARNING"
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
    Add-ApplicationLog -Module "AllProviders" -Message "Registered TTS provider: $ProviderName" -Level "INFO"
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
Add-ApplicationLog -Module "AllProviders" -Message "Initialising TTS Providers..." -Level "INFO"
$initResult = Initialise-TTSProviders

if ($initResult.LoadedCount -eq 0) {
    Add-ApplicationLog -Module "AllProviders" -Message "No TTS provider modules were loaded!" -Level "WARNING"
    Add-ApplicationLog -Module "AllProviders" -Message "To add TTS providers, create provider modules in: $ProvidersPath" -Level "INFO"
    Add-ApplicationLog -Module "AllProviders" -Message "Example provider files:" -Level "INFO"
    Add-ApplicationLog -Module "AllProviders" -Message "  - Azure.psm1" -Level "INFO"
    Add-ApplicationLog -Module "AllProviders" -Message "  - GoogleCloud.psm1" -Level "INFO"
    Add-ApplicationLog -Module "AllProviders" -Message "  - AWSPolly.psm1" -Level "INFO"
}
else {
    Add-ApplicationLog -Module "AllProviders" -Message "Successfully loaded $($initResult.LoadedCount) TTS provider(s)" -Level "INFO"
}

# Export functions
function Show-ProviderConfiguration {
    <#
    .SYNOPSIS
    Shows the configuration Dialogue for a specific TTS provider
    .PARAMETER Provider
    The name of the provider (e.g., "Microsoft Azure", "Amazon Polly")
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Provider
    )
    
    try {
        Add-ApplicationLog -Message "Opening configuration Dialogue for provider: $Provider" -Level "INFO"
        
        # Map provider names to their setup functions
        $setupFunction = switch ($Provider) {
            "AWS Polly" { "Show-AWSPollyProviderSetup" }
            "ElevenLabs" { "Show-ElevenLabsProviderSetup" }
            "Google Cloud" { "Show-GoogleCloudProviderSetup" }
            "Microsoft Azure" { "Show-AzureProviderSetup" }
            "Murf AI" { "Show-MurfAIProviderSetup" }
            "OpenAI" { "Show-OpenAIProviderSetup" }
            "Telnyx" { "Show-TelnyxProviderSetup" }
            "Twilio" { "Show-TwilioProviderSetup" }
            default { $null }
        }
        
        if (-not $setupFunction) {
            Add-ApplicationLog -Message "No configuration function found for provider: $Provider" -Level "WARNING"
            [System.Windows.MessageBox]::Show(
                "Configuration is not available for $Provider",
                "Provider Configuration",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            )
            return
        }
        
        # Check if the function exists
        if (-not (Get-Command $setupFunction -ErrorAction SilentlyContinue)) {
            Add-ApplicationLog -Message "Provider setup function '$setupFunction' not found" -Level "WARNING"
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
    'Register-TTSProvider',
    'Get-ProviderStatus',
    'Import-TTSProviderModule',
    'Show-ProviderConfiguration'
)
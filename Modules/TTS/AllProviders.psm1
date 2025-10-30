# AllProviders Module - TTS Provider Orchestrator
# Dynamically discovers and loads all TTS provider modules

$ModulePath = $PSScriptRoot
$ProvidersPath = Join-Path $ModulePath "Providers"

Write-Verbose "AllProviders module initializing from: $ModulePath"
Write-Verbose "Looking for provider modules in: $ProvidersPath"

# Registry of loaded providers
$script:LoadedProviders = @{}
$script:ProviderModules = @()

# Pre-defined provider module names (in load order)
$script:KnownProviders = @(
    "AzureProvider.psm1",
    "GoogleCloudProvider.psm1",
    "AWSPollyProvider.psm1",
    "CloudPronouncerProvider.psm1",
    "TwilioProvider.psm1",
    "VoiceForgeProvider.psm1"
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
        Import-Module $ModulePath -Force -ErrorAction Stop
        
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
        
        Write-ApplicationLog -Message "Loaded TTS provider module: $moduleName" -Level "INFO"
        return $true
    }
    catch {
        Write-Warning "Failed to load provider module $ModulePath : $($_.Exception.Message)"
        Write-ApplicationLog -Message "Failed to load provider module $ModulePath : $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Initialize-TTSProviders {
    <#
    .SYNOPSIS
    Discovers and loads all TTS provider modules
    #>
    
    Write-ApplicationLog -Message "Initializing TTS providers" -Level "INFO"
    
    # Check if Providers directory exists
    if (-not (Test-Path $ProvidersPath)) {
        Write-Warning "Providers directory not found: $ProvidersPath"
        Write-ApplicationLog -Message "Creating Providers directory: $ProvidersPath" -Level "INFO"
        New-Item -ItemType Directory -Path $ProvidersPath -Force | Out-Null
    }
    
    $loadedCount = 0
    $failedCount = 0
    
    # Load pre-defined providers first (in order)
    foreach ($providerFile in $script:KnownProviders) {
        $providerPath = Join-Path $ProvidersPath $providerFile
        
        if (Test-Path $providerPath) {
            $providerName = $providerFile -replace "Provider\.psm1$", ""
            $providerName = switch ($providerName) {
                "Azure" { "Microsoft Azure" }
                "GoogleCloud" { "Google Cloud" }
                "AWSPolly" { "AWS Polly" }
                "CloudPronouncer" { "CloudPronouncer" }
                "Twilio" { "Twilio" }
                "VoiceForge" { "VoiceForge" }
                default { $providerName }
            }
            
            if (Import-TTSProviderModule -ModulePath $providerPath -ProviderName $providerName) {
                $loadedCount++
                Write-Host "  ✓ Loaded provider: $providerName" -ForegroundColor Green
            }
            else {
                $failedCount++
                Write-Host "  ✗ Failed to load: $providerName" -ForegroundColor Red
            }
        }
        else {
            Write-Verbose "Provider module not found: $providerPath"
        }
    }
    
    # Discover any additional provider modules not in the known list
    $additionalProviders = Get-ChildItem -Path $ProvidersPath -Filter "*Provider.psm1" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin $script:KnownProviders }
    
    foreach ($providerFile in $additionalProviders) {
        $providerName = $providerFile.BaseName -replace "Provider$", ""
        
        if (Import-TTSProviderModule -ModulePath $providerFile.FullName -ProviderName $providerName) {
            $loadedCount++
            Write-Host "  ✓ Loaded additional provider: $providerName" -ForegroundColor Cyan
        }
        else {
            $failedCount++
        }
    }
    
    Write-ApplicationLog -Message "TTS Providers initialized: $loadedCount loaded, $failedCount failed" -Level "INFO"
    
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
    
    Write-ApplicationLog -Message "Testing TTS provider capabilities" -Level "INFO"
    
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
    $allProviderNames = @("Microsoft Azure", "Google Cloud", "AWS Polly", "CloudPronouncer", "Twilio", "VoiceForge")
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
        return $script:LoadedProviders[$ProviderName]
    }
    
    Write-ApplicationLog -Message "Provider not found: $ProviderName" -Level "WARNING"
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
    Write-ApplicationLog -Message "Registered TTS provider: $ProviderName" -Level "INFO"
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

# Initialize providers on module load
Write-Host "`nInitializing TTS Providers..." -ForegroundColor Cyan
$initResult = Initialize-TTSProviders

if ($initResult.LoadedCount -eq 0) {
    Write-Warning "No TTS provider modules were loaded!"
    Write-Host "`nTo add TTS providers, create provider modules in:" -ForegroundColor Yellow
    Write-Host "  $ProvidersPath" -ForegroundColor Gray
    Write-Host "`nExample provider files:" -ForegroundColor Yellow
    Write-Host "  - AzureProvider.psm1" -ForegroundColor Gray
    Write-Host "  - GoogleCloudProvider.psm1" -ForegroundColor Gray
    Write-Host "  - AWSPollyProvider.psm1" -ForegroundColor Gray
}
else {
    Write-Host "`n✓ Successfully loaded $($initResult.LoadedCount) TTS provider(s)" -ForegroundColor Green
}
}

# Export functions
Export-ModuleMember -Function @(
    'Test-TTSProviderCapabilities',
    'Get-TTSProvider',
    'Get-AvailableTTSProviders',
    'Register-TTSProvider',
    'Get-ProviderStatus',
    'Import-TTSProviderModule'
)

Write-ApplicationLog -Message "AllProviders module loaded successfully" -Level "INFO"
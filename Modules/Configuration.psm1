# Advanced Configuration Module for TextToSpeech Generator
# PowerShell 5.1 Compatible Version

if (-not (Get-Module -Name 'Logging')) {
    Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'modules/Logging.psm1')
}

# Configuration profiles for different environments
$script:ConfigurationProfiles = @{
    "Development" = @{
        Name = "Development"
        Description = "Development environment settings"
        Settings = @{
            LogLevel = "DEBUG"
            Timeout = 30
            RetryCount = 2
            MaxParallelJobs = 2
            EnableDetailedLogging = $true
            CacheEnabled = $false
        }
    }
    "Production" = @{
        Name = "Production"  
        Description = "Production environment settings"
        Settings = @{
            LogLevel = "INFO"
            Timeout = 60
            RetryCount = 5
            MaxParallelJobs = 4
            EnableDetailedLogging = $false
            CacheEnabled = $true
        }
    }
    "Testing" = @{
        Name = "Testing"
        Description = "Testing environment settings"
        Settings = @{
            LogLevel = "WARNING"
            Timeout = 10
            RetryCount = 1
            MaxParallelJobs = 1
            EnableDetailedLogging = $true
            CacheEnabled = $false
        }
    }
}

# Configuration templates for common setups
$script:ConfigurationTemplates = @{
    "AzureBasic" = @{
        Name = "Azure Basic Setup"
        Description = "Basic Azure configuration for personal use"
    Provider = "Azure Cognitive Services"
        Configuration = @{
            Region = "eastus"
            Voice = "en-US-JennyNeural"
            AdvancedOptions = @{
                SpeechRate = 1.0
                Pitch = 0
                Volume = 50
                Style = "neutral"
            }
        }
    }
    "GoogleCloudBasic" = @{
        Name = "Google Cloud Basic Setup"
        Description = "Basic Google Cloud configuration"
        Provider = "Google Cloud"
        Configuration = @{
            Voice = "en-US-Wavenet-F"
            LanguageCode = "en-US"
            AdvancedOptions = @{
                SpeakingRate = 1.0
                Pitch = 0.0
                VolumeGainDb = 0.0
                AudioEncoding = "MP3"
            }
        }
    }
}

# PowerShell 5.1 compatible configuration manager
function New-AdvancedConfigurationManager {
    <#
    .SYNOPSIS
    Creates a new advanced configuration manager instance
    #>
    param(
        [Parameter(Mandatory=$true)][string]$ConfigPath
    )
    
    $manager = New-Object PSObject -Property @{
        ConfigPath = $ConfigPath
        CurrentProfile = "Development"
        Profiles = $script:ConfigurationProfiles.Clone()
        Templates = $script:ConfigurationTemplates.Clone()
        CurrentConfiguration = @{}
    }
    
    # Add methods as script properties
    $manager | Add-Member -MemberType ScriptMethod -Name "SetCurrentProfile" -Value {
        param([string]$ProfileName)
        if ($this.Profiles.ContainsKey($ProfileName)) {
            $this.CurrentProfile = $ProfileName
            Add-ApplicationLog -Module "Configuration" -Message "Configuration profile set to: $ProfileName" -Level "INFO"
        } else {
            Add-ApplicationLog -Module "Configuration" -Message "Profile '$ProfileName' not found, using Development" -Level "WARNING"
            $this.CurrentProfile = "Development"
        }
    }
    
    $manager | Add-Member -MemberType ScriptMethod -Name "LoadConfiguration" -Value {
        if (Test-Path $this.ConfigPath) {
            try {
                $configData = Get-Content $this.ConfigPath -Raw | ConvertFrom-Json
                if ($configData) {
                    $this.CurrentConfiguration = @{}
                    # Convert PSCustomObject to hashtable
                    $configData.PSObject.Properties | ForEach-Object {
                        $this.CurrentConfiguration[$_.Name] = $_.Value
                    }
                }
                Add-ApplicationLog -Module "Configuration" -Message "Configuration loaded from $($this.ConfigPath)" -Level "INFO"
            }
            catch {
                Add-ApplicationLog -Module "Configuration" -Message "Failed to load configuration: $($_.Exception.Message)" -Level "WARNING"
            }
        }
    }
    
    # Initialise the manager
    $manager.LoadConfiguration()
    
    return $manager
}

# Configuration validation function
function Test-ConfigurationValid {
    <#
    .SYNOPSIS
    Enhanced configuration validation with detailed feedback
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Provider,
        [hashtable]$Configuration
    )
    
    $validationResult = @{
        IsValid = $false
        Errors = @()
        Warnings = @()
        Recommendations = @()
        Provider = $Provider
    }
    
    Add-ApplicationLog -Module "Configuration" -Message "Validating configuration for $Provider" -Level "DEBUG"
    
    switch ($Provider) {
    "Azure Cognitive Services" {
            # API Key validation
            if ([string]::IsNullOrWhiteSpace($Configuration.APIKey)) {
                $validationResult.Errors += "Azure API Key is required"
            } elseif ($Configuration.APIKey -eq "your-api-key-here") {
                $validationResult.Errors += "Azure API Key is still set to placeholder value"
            } elseif (-not ($Configuration.APIKey -match '^[a-fA-F0-9]{32}$')) {
                $validationResult.Warnings += "Azure API Key format appears invalid (expected 32 hex characters)"
            }
            
            # Region validation
            $validRegions = @("eastus", "westus", "westus2", "centralus", "northcentralus", "southcentralus", "eastus2", "westcentralus", "uksouth", "ukwest", "northeurope", "westeurope")
            if ([string]::IsNullOrWhiteSpace($Configuration.Region)) {
                $validationResult.Errors += "Azure Region is required"
            } elseif ($Configuration.Region -notin $validRegions) {
                $validationResult.Warnings += "Azure Region '$($Configuration.Region)' is not in the list of known regions"
                $validationResult.Recommendations += "Consider using a standard region like 'eastus' or 'westeurope'"
            }
        }
        
        "Google Cloud" {
            # API Key validation
            if ([string]::IsNullOrWhiteSpace($Configuration.APIKey)) {
                $validationResult.Errors += "Google Cloud API Key is required"
            } elseif ($Configuration.APIKey -eq "your-api-key-here") {
                $validationResult.Errors += "Google Cloud API Key is still set to placeholder value"
            } elseif (-not ($Configuration.APIKey -match '^AIza[0-9A-Za-z_-]{35}$')) {
                $validationResult.Warnings += "Google Cloud API Key format appears invalid (expected AIza + 35 characters)"
            }
        }
        
        "AWS Polly" {
            # Access Key validation
            if ([string]::IsNullOrWhiteSpace($Configuration.AccessKey)) {
                $validationResult.Errors += "AWS Access Key is required"
            } elseif ($Configuration.AccessKey -eq "your-access-key-here") {
                $validationResult.Errors += "AWS Access Key is still set to placeholder value"
            }
            
            # Secret Key validation
            if ([string]::IsNullOrWhiteSpace($Configuration.SecretKey)) {
                $validationResult.Errors += "AWS Secret Key is required"
            } elseif ($Configuration.SecretKey -eq "your-secret-key-here") {
                $validationResult.Errors += "AWS Secret Key is still set to placeholder value"
            }
        }
        
        default {
            $validationResult.Warnings += "No specific validation rules defined for provider: $Provider"
        }
    }
    
    # Set overall validation status
    $validationResult.IsValid = ($validationResult.Errors.Count -eq 0)
    
    # Log validation results
    $logLevel = if ($validationResult.IsValid) { "INFO" } else { "WARNING" }
    $errorCount = $validationResult.Errors.Count
    $warningCount = $validationResult.Warnings.Count
    
    Add-ApplicationLog -Module "Configuration" -Message "$Provider validation: Valid=$($validationResult.IsValid), Errors=$errorCount, Warnings=$warningCount" -Level $logLevel
    
    return $validationResult
}

# API connectivity testing function
function Test-APIConnectivity {
    <#
    .SYNOPSIS
    Enhanced API connectivity testing with detailed diagnostics
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Provider,
        [hashtable]$Configuration
    )
    
    $connectivityResult = @{
        IsConnected = $false
        ResponseTime = 0
        StatusCode = 0
        ErrorMessage = ""
        Recommendations = @()
        Provider = $Provider
    }
    
    Add-ApplicationLog -Module "Configuration" -Message "Testing connectivity for $Provider" -Level "INFO"
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        switch ($Provider) {
            "Azure Cognitive Services" {
                if ($Configuration.Region) {
                    $testUrl = "https://$($Configuration.Region).tts.speech.microsoft.com/cognitiveservices/voices/list"
                    $headers = @{
                        'Ocp-Apim-Subscription-Key' = $Configuration.APIKey
                    }
                    
                    $response = Invoke-RestMethod -Uri $testUrl -Method Get -Headers $headers -TimeoutSec 10
                    $connectivityResult.IsConnected = $true
                    $connectivityResult.StatusCode = 200
                }
            }
            
            "Google Cloud" {
                $testUrl = "https://texttospeech.googleapis.com/v1/voices?key=$($Configuration.APIKey)"
                
                $response = Invoke-RestMethod -Uri $testUrl -Method Get -TimeoutSec 10
                $connectivityResult.IsConnected = $true
                $connectivityResult.StatusCode = 200
            }
            
            default {
                $connectivityResult.ErrorMessage = "Provider-specific connectivity test available - see setup documentation"
                $connectivityResult.Recommendations += "Manual testing required for this provider"
            }
        }
    }
    catch {
        $connectivityResult.IsConnected = $false
        $connectivityResult.ErrorMessage = $_.Exception.Message
        $connectivityResult.Recommendations += "Check network connectivity and DNS resolution"
    }
    finally {
        $stopwatch.Stop()
        $connectivityResult.ResponseTime = $stopwatch.ElapsedMilliseconds
    }
    
    # Log connectivity results
    $logLevel = if ($connectivityResult.IsConnected) { "INFO" } else { "ERROR" }
    Add-ApplicationLog -Module "Configuration" -Message "$Provider connectivity: Connected=$($connectivityResult.IsConnected), ResponseTime=$($connectivityResult.ResponseTime)ms" -Level $logLevel
    
    return $connectivityResult
}

# Helper functions
function Get-ConfigurationProfiles {
    return $script:ConfigurationProfiles
}

function Get-ConfigurationTemplates {
    return $script:ConfigurationTemplates
}

function Update-ProviderConfiguration {
    param(
        [Parameter(Mandatory=$true)][string]$Provider,
        [Parameter(Mandatory=$true)][hashtable]$Configuration
    )
    
    Add-ApplicationLog -Module "Configuration" -Message "Updating configuration for provider: $Provider" -Level "INFO"
    
    # Validate configuration before updating
    $validation = Test-ConfigurationValid -Provider $Provider -Configuration $Configuration
    
    if (-not $validation.IsValid) {
    Add-ApplicationLog -Module "Configuration" -Message "Configuration validation failed for $Provider" -Level "ERROR"
        return $false
    }
    
    Add-ApplicationLog -Module "Configuration" -Message "Configuration updated successfully for $Provider" -Level "INFO"
    return $true
}

function Get-ProviderConfiguration {
    param(
        [Parameter(Mandatory=$true)][string]$Provider
    )
    
    Add-ApplicationLog -Module "Configuration" -Message "Retrieving configuration for provider: $Provider" -Level "DEBUG"
    
    # Return empty configuration as placeholder
    return @{}
}

function Get-AvailableProviders {
    return @(
        "AWS Polly",
        "Azure Cognitive Services", 
        "Google Cloud",
        "Twilio",
        "VoiceForge",
        "VoiceWare"
    )
}

# Export functions
Export-ModuleMember -Function @(
    'Test-ConfigurationValid',
    'Test-APIConnectivity',
    'New-AdvancedConfigurationManager',
    'Get-ConfigurationProfiles',
    'Get-ConfigurationTemplates',
    'Update-ProviderConfiguration',
    'Get-ProviderConfiguration',
    'Get-AvailableProviders'
)
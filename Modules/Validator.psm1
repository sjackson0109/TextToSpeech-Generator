# Configuration Schema Validation Module for TextToSpeech Generator
# Provides comprehensive validation for configuration files

# Configuration schema definitions
$script:ConfigurationSchema = @{
    Version = "3.2"
    RequiredProperties = @("ConfigVersion", "Profiles", "CurrentProfile")
    ProfileSchema = @{
        RequiredProperties = @("Processing", "Providers")
        Processing = @{
            RequiredProperties = @("OutputPath", "Timeout", "MaxParallelJobs")
            PropertyTypes = @{
                OutputPath = "String"
                InputFile = "String"
                Timeout = "Integer"
                MaxParallelJobs = "Integer"
            }
            Validation = @{
                Timeout = @{ Min = 5; Max = 300 }
                MaxParallelJobs = @{ Min = 1; Max = 20 }
            }
        }
        Providers = @{
            SupportedProviders = @(
                "Azure Cognitive Services",
                "AWS Polly",
                "Google Cloud TTS", 
                "Twilio",
                "VoiceForge"
                "VoiceWare"
            )
            ProviderSchemas = @{
                "Azure Cognitive Services" = @{
                    RequiredProperties = @("ApiKey", "Datacenter", "DefaultVoice")
                    OptionalProperties = @("AudioFormat", "AdvancedOptions", "Enabled")
                    PropertyTypes = @{
                        ApiKey = "String"
                        Datacenter = "String"
                        DefaultVoice = "String"
                        AudioFormat = "String"
                        Enabled = "Boolean"
                    }
                    Validation = @{
                        Datacenter = @{
                            ValidValues = @("eastus", "westus", "westus2", "eastus2", "centralus", "northcentralus", "southcentralus", "westcentralus", "canadacentral", "canadaeast", "brazilsouth", "northeurope", "westeurope", "uksouth", "ukwest", "francecentral", "germanywestcentral", "norwayeast", "switzerlandnorth", "uaenorth", "southafricanorth", "centralindia", "southindia", "westindia", "japaneast", "japanwest", "koreacentral", "koreasouth", "southeastasia", "eastasia", "australiaeast", "australiasoutheast", "australiacentral", "chinaeast2", "chinanorth2")
                        }
                    }
                }
                "Google Cloud TTS" = @{
                    RequiredProperties = @("ApiKey", "DefaultVoice")
                    OptionalProperties = @("AdvancedOptions", "Enabled")
                    PropertyTypes = @{
                        ApiKey = "String"
                        DefaultVoice = "String"
                        Enabled = "Boolean"
                    }
                }
                "AWS Polly" = @{
                    RequiredProperties = @("AccessKey", "SecretKey", "Region", "DefaultVoice")
                    OptionalProperties = @("AdvancedOptions", "Enabled")
                    PropertyTypes = @{
                        AccessKey = "String"
                        SecretKey = "String"
                        Region = "String"
                        DefaultVoice = "String"
                        Enabled = "Boolean"
                    }
                    Validation = @{
                        Region = @{
                            ValidValues = @("us-east-1", "us-east-2", "us-west-1", "us-west-2", "ca-central-1", "eu-west-1", "eu-west-2", "eu-west-3", "eu-central-1", "eu-north-1", "ap-northeast-1", "ap-northeast-2", "ap-southeast-1", "ap-southeast-2", "ap-south-1", "sa-east-1")
                        }
                    }
                }
            }
        }
    }
}

function Test-ConfigurationSchema {
    <#
    .SYNOPSIS
    Validates configuration against the defined schema
    #>
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Configuration
    )
    
    $result = @{
        IsValid = $true
        Errors = @()
        Warnings = @()
        ValidationDetails = @{}
    }
    
    try {
        # Validate top-level structure
        $result = Test-TopLevelProperties -Configuration $Configuration -Result $result
        
        # Validate profiles
        if ($Configuration.ContainsKey("Profiles")) {
            $result = Test-ProfilesSection -Profiles $Configuration.Profiles -Result $result
        }
        
        # Validate current profile exists
        if ($Configuration.ContainsKey("CurrentProfile")) {
            if (-not $Configuration.Profiles.ContainsKey($Configuration.CurrentProfile)) {
                $result.IsValid = $false
                $result.Errors += "CurrentProfile '$($Configuration.CurrentProfile)' not found in Profiles section"
            }
        }
        
        # Validate version compatibility
        $result = Test-VersionCompatibility -Configuration $Configuration -Result $result
        
    }
    catch {
        $result.IsValid = $false
        $result.Errors += "Schema validation failed: $($_.Exception.Message)"
    }
    
    return $result
}

function Test-TopLevelProperties {
    param([hashtable]$Configuration, [hashtable]$Result)
    
    foreach ($property in $script:ConfigurationSchema.RequiredProperties) {
        if (-not $Configuration.ContainsKey($property)) {
            $Result.IsValid = $false
            $Result.Errors += "Missing required top-level property: $property"
        }
    }
    
    return $Result
}

function Test-ProfilesSection {
    param([hashtable]$Profiles, [hashtable]$Result)
    
    foreach ($profileName in $Profiles.Keys) {
        $profile = $Profiles[$profileName]
        
        # Validate required profile properties
        foreach ($property in $script:ConfigurationSchema.ProfileSchema.RequiredProperties) {
            if (-not $profile.ContainsKey($property)) {
                $Result.IsValid = $false
                $Result.Errors += "Profile '$profileName' missing required property: $property"
            }
        }
        
        # Validate Processing section
        if ($profile.ContainsKey("Processing")) {
            $Result = Test-ProcessingSection -Processing $profile.Processing -ProfileName $profileName -Result $Result
        }
        
        # Validate Providers section
        if ($profile.ContainsKey("Providers")) {
            $Result = Test-ProvidersSection -Providers $profile.Providers -ProfileName $profileName -Result $Result
        }
    }
    
    return $Result
}

function Test-ProcessingSection {
    param([hashtable]$Processing, [string]$ProfileName, [hashtable]$Result)
    
    $processingSchema = $script:ConfigurationSchema.ProfileSchema.Processing
    
    # Check required properties
    foreach ($property in $processingSchema.RequiredProperties) {
        if (-not $Processing.ContainsKey($property)) {
            $Result.IsValid = $false
            $Result.Errors += "Profile '$ProfileName' Processing section missing required property: $property"
        }
    }
    
    # Validate property types and values
    foreach ($property in $Processing.Keys) {
        if ($processingSchema.PropertyTypes.ContainsKey($property)) {
            $expectedType = $processingSchema.PropertyTypes[$property]
            $actualValue = $Processing[$property]
            
            if (-not (Test-PropertyType -Value $actualValue -ExpectedType $expectedType)) {
                $Result.Warnings += "Profile '$ProfileName' Processing.$property has incorrect type. Expected: $expectedType"
            }
        }
        
        # Validate ranges/constraints
        if ($processingSchema.Validation.ContainsKey($property)) {
            $validation = $processingSchema.Validation[$property]
            $value = $Processing[$property]
            
            if ($validation.ContainsKey("Min") -and $value -lt $validation.Min) {
                $Result.IsValid = $false
                $Result.Errors += "Profile '$ProfileName' Processing.$property ($value) below minimum ($($validation.Min))"
            }
            
            if ($validation.ContainsKey("Max") -and $value -gt $validation.Max) {
                $Result.IsValid = $false
                $Result.Errors += "Profile '$ProfileName' Processing.$property ($value) above maximum ($($validation.Max))"
            }
        }
    }
    
    # Validate paths exist (if not placeholders)
    if ($Processing.ContainsKey("OutputPath") -and -not $Processing.OutputPath.StartsWith("\\")) {
        try {
            $resolvedPath = [System.IO.Path]::GetFullPath($Processing.OutputPath)
            # Check if path is valid format, not necessarily if directory exists yet
            if ([string]::IsNullOrWhiteSpace($resolvedPath)) {
                $Result.Warnings += "Profile '$ProfileName' OutputPath appears invalid: $($Processing.OutputPath)"
            }
        } catch {
            $Result.Warnings += "Profile '$ProfileName' OutputPath may not be accessible: $($Processing.OutputPath)"
        }
    }
    
    return $Result
}

function Test-ProvidersSection {
    param([hashtable]$Providers, [string]$ProfileName, [hashtable]$Result)
    
    foreach ($providerName in $Providers.Keys) {
        $provider = $Providers[$providerName]
        
        # Check if provider is supported
        if ($providerName -notin $script:ConfigurationSchema.ProfileSchema.Providers.SupportedProviders) {
            $Result.Warnings += "Profile '$ProfileName' contains unsupported provider: $providerName"
            continue
        }
        
        # Get provider schema
        $providerSchemas = $script:ConfigurationSchema.ProfileSchema.Providers.ProviderSchemas
        if ($providerSchemas.ContainsKey($providerName)) {
            $schema = $providerSchemas[$providerName]
            $Result = Test-ProviderConfiguration -Provider $provider -ProviderName $providerName -ProfileName $ProfileName -Schema $schema -Result $Result
        }
    }
    
    return $Result
}

function Test-ProviderConfiguration {
    param([hashtable]$Provider, [string]$ProviderName, [string]$ProfileName, [hashtable]$Schema, [hashtable]$Result)
    
    # Check required properties
    foreach ($property in $Schema.RequiredProperties) {
        if (-not $Provider.ContainsKey($property)) {
            $Result.IsValid = $false
            $Result.Errors += "Profile '$ProfileName' Provider '$ProviderName' missing required property: $property"
        }
    }
    
    # Validate property types
    foreach ($property in $Provider.Keys) {
        if ($Schema.PropertyTypes.ContainsKey($property)) {
            $expectedType = $Schema.PropertyTypes[$property]
            $actualValue = $Provider[$property]
            
            if (-not (Test-PropertyType -Value $actualValue -ExpectedType $expectedType)) {
                $Result.Warnings += "Profile '$ProfileName' Provider '$ProviderName'.$property has incorrect type. Expected: $expectedType"
            }
        }
    }
    
    # Validate specific constraints
    if ($Schema.ContainsKey("Validation")) {
        foreach ($property in $Schema.Validation.Keys) {
            if ($Provider.ContainsKey($property)) {
                $validation = $Schema.Validation[$property]
                $value = $Provider[$property]
                
                if ($validation.ContainsKey("ValidValues")) {
                    if ($value -notin $validation.ValidValues) {
                        $Result.IsValid = $false
                        $Result.Errors += "Profile '$ProfileName' Provider '$ProviderName'.$property has invalid value '$value'. Valid values: $($validation.ValidValues -join ', ')"
                    }
                }
            }
        }
    }
    
    # Validate API key formats (if not encrypted)
    if ($Provider.ContainsKey("ApiKey") -and -not $Provider.ApiKey.StartsWith("ENCRYPTED:")) {
        $Result = Test-ApiKeyFormat -ApiKey $Provider.ApiKey -ProviderName $ProviderName -ProfileName $ProfileName -Result $Result
    }
    if ($Provider.ContainsKey("APIKey") -and -not $Provider.APIKey.StartsWith("ENCRYPTED:")) {
        $Result = Test-ApiKeyFormat -ApiKey $Provider.APIKey -ProviderName $ProviderName -ProfileName $ProfileName -Result $Result
    }
    
    return $Result
}

function Test-PropertyType {
    param($Value, [string]$ExpectedType)
    
    switch ($ExpectedType) {
        "String" { return $Value -is [string] }
        "Integer" { return $Value -is [int] -or ($Value -is [string] -and $Value -match '^\d+$') }
        "Boolean" { return $Value -is [bool] -or $Value -in @("true", "false", $true, $false) }
        "Array" { return $Value -is [array] }
        "Hashtable" { return $Value -is [hashtable] }
        default { return $true }
    }
}

function Test-ApiKeyFormat {
    param([string]$ApiKey, [string]$ProviderName, [string]$ProfileName, [hashtable]$Result)
    
    switch ($ProviderName) {
        "Azure Cognitive Services" {
            if ($ApiKey -notmatch '^[a-f0-9]{32}$') {
                $Result.Warnings += "Profile '$ProfileName' Azure API key format appears invalid (should be 32-character hex)"
            }
        }
        "Google Cloud TTS" {
            if ($ApiKey -notmatch '^AIza[0-9A-Za-z\-_]{35}$') {
                $Result.Warnings += "Profile '$ProfileName' Google API key format appears invalid"
            }
        }
        "AWS Polly" {
            # For AWS Polly, check AccessKey which should be passed as ApiKey parameter
            if ($ApiKey -notmatch '^AKIA[0-9A-Z]{16}$') {
                $Result.Warnings += "Profile '$ProfileName' AWS Access Key format appears invalid"
            }
        }
    }
    
    return $Result
}

function Test-VersionCompatibility {
    param([hashtable]$Configuration, [hashtable]$Result)
    
    if ($Configuration.ContainsKey("ConfigVersion")) {
        try {
            $configVersion = [Version]::Parse($Configuration.ConfigVersion)
            $currentVersion = [Version]::Parse($script:ConfigurationSchema.Version)
            
            if ($configVersion -gt $currentVersion) {
                $Result.Warnings += "Configuration version ($($Configuration.ConfigVersion)) is newer than application version ($($script:ConfigurationSchema.Version))"
            }
            elseif ($configVersion.Major -lt $currentVersion.Major) {
                $Result.IsValid = $false
                $Result.Errors += "Configuration version ($($Configuration.ConfigVersion)) is incompatible with application version ($($script:ConfigurationSchema.Version))"
            }
        }
        catch {
            $Result.Warnings += "Invalid version format: $($Configuration.ConfigVersion)"
        }
    }
    
    return $Result
}

function Get-ConfigurationTemplate {
    <#
    .SYNOPSIS
    Generates a template configuration with all supported options
    #>
    param([string]$ProfileName = "NewProfile")
    
    return @{
        ConfigVersion = $script:ConfigurationSchema.Version
        CurrentProfile = $ProfileName
        Profiles = @{
            $ProfileName = @{
                Processing = @{
                    OutputPath = "C:\TTS-Output"
                    InputFile = ""
                    Timeout = 30
                    MaxParallelJobs = 4
                }
                Providers = @{
                    "Azure Cognitive Services" = @{
                        ApiKey = "your-api-key-here"
                        Datacenter = "eastus"
                        DefaultVoice = "en-US-JennyNeural"
                        AudioFormat = "audio-16khz-32kbitrate-mono-mp3"
                        Enabled = $true
                        AdvancedOptions = @{
                            SpeechRate = "medium"
                            Pitch = "medium"
                            Volume = "medium"
                            Style = "neutral"
                        }
                    }
                    "Google Cloud TTS" = @{
                        ApiKey = "your-google-api-key"
                        DefaultVoice = "en-US-Wavenet-D"
                        Enabled = $false
                        AdvancedOptions = @{
                            SpeakingRate = 1.0
                            Pitch = 0.0
                            VolumeGain = 0.0
                            AudioEncoding = "MP3"
                        }
                    }
                    "AWS Polly" = @{
                        AccessKey = "AKIA..."
                        SecretKey = "your-secret-key"
                        Region = "us-east-1"
                        DefaultVoice = "Joanna"
                        Enabled = $false
                        AdvancedOptions = @{
                            Engine = "neural"
                            OutputFormat = "mp3"
                            SampleRate = "22050"
                        }
                    }
                }
            }
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Test-ConfigurationSchema',
    'Get-ConfigurationTemplate',
    'Test-PropertyType',
    'Test-ApiKeyFormat'
)
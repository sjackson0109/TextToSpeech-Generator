if (-not (Get-Module -Name 'Logging')) {
	Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\Logging.psm1')).Path
}
function ApplyConfigurationToGUI {
    param(
        [Parameter(Mandatory=$true)][hashtable]$Configuration,
        [Parameter(Mandatory=$true)]$Window
    )
    if ($Window.GC_APIKey) { $Window.GC_APIKey.Password = $Configuration.APIKey }
    if ($Window.GC_ProjectID) { $Window.GC_ProjectID.Text = $Configuration.ProjectID }
    if ($Window.GC_Region) { $Window.GC_Region.Text = $Configuration.Region }
    if ($Window.GC_Endpoint) { $Window.GC_Endpoint.Text = $Configuration.Endpoint }
}
Export-ModuleMember -Function ApplyConfigurationToGUI
function Test-GoogleCloudCredentials {
    param(
        [hashtable]$Config
    )
    # Validate API Key format (should start with AIza and be 39 chars)
    if (-not $Config.ApiKey -or $Config.ApiKey -notmatch '^AIza[0-9A-Za-z\-_]{35}$') {
        Write-ApplicationLog -Message "GoogleCloud Validate-GoogleCloudCredentials: Invalid ApiKey" -Level "WARNING"
        return $false
    }
    # Validate language (should be a valid BCP-47 language tag)
    if (-not $Config.Language -or $Config.Language -notmatch '^[a-z]{2,3}-[A-Z]{2,3}$') {
        Write-ApplicationLog -Message "GoogleCloud Validate-GoogleCloudCredentials: Invalid Language" -Level "WARNING"
        return $false
    }
    return $true
}
Export-ModuleMember -Function 'Test-GoogleCloudCredentials', 'Get-GoogleCloudProviderSetupFields', 'Get-GoogleCloudAvailableVoices', 'Invoke-GoogleCloudTTS', 'Get-GoogleCloudCapabilities'
function Show-GoogleCloudProviderSetup {
    param(
        $Window,
        $ConfigGrid,
        $GuidanceText,
        $GUI
    )
    $row0 = New-Object System.Windows.Controls.RowDefinition
    $row0.Height = [System.Windows.GridLength]::new(0, [System.Windows.GridUnitType]::Auto)
    $ConfigGrid.RowDefinitions.Add($row0)
    $apiKeyLabel = New-Object System.Windows.Controls.TextBlock
        Export-ModuleMember -Function GetProviderSetupFields,ApplyConfigurationToGUI
    $apiKeyLabel.Foreground = "White"
    $apiKeyLabel.Margin = "8"
    [System.Windows.Controls.Grid]::SetRow($apiKeyLabel, 0)
    [System.Windows.Controls.Grid]::SetColumn($apiKeyLabel, 0)
    $ConfigGrid.Children.Add($apiKeyLabel) | Out-Null
    $apiKeyBox = New-Object System.Windows.Controls.TextBox
    $apiKeyBox.Text = if ($GUI.Window.GC_APIKey.Text) { $GUI.Window.GC_APIKey.Text } else { "" }
    $apiKeyBox.Margin = "8"
    [System.Windows.Controls.Grid]::SetRow($apiKeyBox, 0)
    [System.Windows.Controls.Grid]::SetColumn($apiKeyBox, 1)
    $ConfigGrid.Children.Add($apiKeyBox) | Out-Null
    $languageLabel = New-Object System.Windows.Controls.TextBlock
    $languageLabel.Text = "Language:"
    $languageLabel.Foreground = "White"
    $languageLabel.Margin = "8"
    [System.Windows.Controls.Grid]::SetRow($languageLabel, 0)
    [System.Windows.Controls.Grid]::SetColumn($languageLabel, 2)
    $ConfigGrid.Children.Add($languageLabel) | Out-Null
    $languageBox = New-Object System.Windows.Controls.TextBox
    $languageBox.Text = if ($GUI.Window.GC_Language.SelectedItem) { $GUI.Window.GC_Language.SelectedItem.Content } else { "en-US" }
    $languageBox.Margin = "8"
    [System.Windows.Controls.Grid]::SetRow($languageBox, 0)
    [System.Windows.Controls.Grid]::SetColumn($languageBox, 3)
    $ConfigGrid.Children.Add($languageBox) | Out-Null
    $GuidanceText.Text = "Enter your Google Cloud TTS API Key and Language. See docs/GOOGLE-SETUP.md for details."
    $Window.SaveAndClose.add_Click{
        $GUI.Window.GC_APIKey.Text = $apiKeyBox.Text
        $GUI.Window.GC_Language.SelectedItem = $languageBox.Text
        Write-SafeLog -Message "Google Cloud TTS setup saved" -Level "INFO"
        $Window.DialogResult = $true
        $Window.Close()
    }
}
Export-ModuleMember -Function 'Show-GoogleCloudProviderSetup'

class TTSProvider {
    [string] $Name
    [hashtable] $Capabilities
    [hashtable] $Configuration
    TTSProvider() {
        $this.Name = ''
        $this.Capabilities = @{}
        $this.Configuration = @{}
    }
    [hashtable] ProcessTTS([string]$text, [hashtable]$options) {
        throw "ProcessTTS method must be implemented by derived class"
    }
    [array] GetAvailableVoices() {
        if (-not $this.Configuration -or -not $this.Configuration.ApiKey) {
            Write-ApplicationLog -Message "GoogleCloud GetAvailableVoices: No config, returning empty list" -Level "DEBUG"
            return @()
        }
        try {
            # ...actual API call...
            return @('en-US-Wavenet-D') # Placeholder
        } catch {
            Write-ApplicationLog -Message "GoogleCloud GetAvailableVoices: Exception $($_.Exception.Message)" -Level "ERROR"
            return @()
        }
    }
    [bool] ValidateConfiguration([hashtable]$config) {
        throw "ValidateConfiguration method must be implemented by derived class"
    }
    [hashtable] GetCapabilities() {
        return @{ MaxTextLength = 2000; SupportedFormats = @('mp3', 'wav'); Premium = $false }
    }
}

class GoogleCloudTTSProvider : TTSProvider {
    GoogleCloudTTSProvider([hashtable]$config = $null) {
        if ($null -eq $config) { $config = @{} }
    $this.Name = "Google Cloud"
    $this.Configuration = $config
    $this.Capabilities = @{
            MaxTextLength = 5000
            SupportedFormats = @("mp3", "wav", "ogg")
            SupportsSSML = $true
            SupportsWaveNet = $true
            RateLimits = @{
                RequestsPerMinute = 300
                CharactersPerMonth = 4000000
            }
        }
    }
    [hashtable] ProcessTTS([string]$text, [hashtable]$options) {
        return Invoke-GoogleCloudTTS @options
    }
    [bool] ValidateConfiguration([hashtable]$config) {
        $required = @("APIKey", "Voice")
        foreach ($key in $required) {
            if (-not $config.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($config[$key])) {
                return $false
            }
        }
        if ($config.APIKey -notmatch '^AIza[0-9A-Za-z\-_]{35}$') {
            return $false
        }
        return $true
    }
        [array] GetAvailableVoices() {
            $apiKey = $this.Configuration["ApiKey"]
            $language = $this.Configuration["Language"]
            if (-not $apiKey) { $apiKey = $env:GOOGLE_CLOUD_API_KEY }
            if (-not $apiKey) {
                Write-ApplicationLog -Message "GoogleCloud GetAvailableVoices: No config or env var, returning demo voices" -Level "DEBUG"
                return @('en-US-Wavenet-D', 'en-US-Wavenet-F', 'en-GB-Wavenet-B')
            }
            $endpoint = "https://texttospeech.googleapis.com/v1/voices?key=$apiKey"
            try {
                $response = Invoke-RestMethod -Uri $endpoint -Method Get -TimeoutSec 10
                if ($response.voices) {
                    return $response.voices | Where-Object { $_.languageCodes -contains $language } | ForEach-Object { $_.name }
                } else {
                    return @('en-US-Wavenet-D', 'en-US-Wavenet-F', 'en-GB-Wavenet-B')
                }
            } catch {
                Write-ApplicationLog -Message "GoogleCloud GetAvailableVoices: Exception $($_.Exception.Message)" -Level "ERROR"
                return @('en-US-Wavenet-D', 'en-US-Wavenet-F', 'en-GB-Wavenet-B')
            }
        }
}

function Invoke-GoogleCloudTTS {
    param(
        [Parameter(Mandatory=$true)][string]$Text,
        [Parameter(Mandatory=$true)][string]$APIKey,
        [Parameter(Mandatory=$true)][string]$Voice,
        [Parameter(Mandatory=$true)][string]$OutputPath,
        [hashtable]$AdvancedOptions = @{}
    )
    try {
        if ([string]::IsNullOrWhiteSpace($Text) -or $Text.Length -gt 5000) {
            throw "Text must be between 1 and 5000 characters for Google Cloud TTS"
        }
        $endpoint = "https://texttospeech.googleapis.com/v1/text:synthesize?key=$APIKey"
        # Extract advanced options
        $speakingRate = if ($AdvancedOptions.SpeakingRate) { $AdvancedOptions.SpeakingRate } else { 1.0 }
        $pitch = if ($AdvancedOptions.Pitch) { $AdvancedOptions.Pitch } else { 0.0 }
        $volumeGainDb = if ($AdvancedOptions.VolumeGainDb) { $AdvancedOptions.VolumeGainDb } else { 0.0 }
        $languageCode = if ($AdvancedOptions.LanguageCode) { $AdvancedOptions.LanguageCode } else { "en-US" }
        $requestBody = @{
            input = @{ text = $Text }
            voice = @{ languageCode = $languageCode; name = $Voice }
            audioConfig = @{ audioEncoding = "MP3"; speakingRate = $speakingRate; pitch = $pitch; volumeGainDb = $volumeGainDb }
        }
        $requestBody = $requestBody | ConvertTo-Json -Depth 10
        $headers = @{
            'Content-Type' = 'application/json'
            'User-Agent' = 'TextToSpeech Generator v3.2'
        }
        # ...existing code for API call and error handling...
    } catch {
        Write-Host "ERROR in Invoke-GoogleCloudTTS: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}
# Top-level provider setup fields function
function GetProviderSetupFields {
    return @{
        Fields = @(
            @{ Name = 'ApiKey'; Label = 'API Key'; Type = 'TextBox'; Default = '' },
            @{ Name = 'ProjectID'; Label = 'Project ID'; Type = 'TextBox'; Default = '' },
            @{ Name = 'Region'; Label = 'Region'; Type = 'ComboBox'; Options = @('global','us','eu','asia') },
            @{ Name = 'Endpoint'; Label = 'Service Endpoint'; Type = 'TextBox'; Default = 'https://texttospeech.googleapis.com/v1/text:synthesize' }
        );
        Guidance = @"
1. Go to Google Cloud Console (console.cloud.google.com)
2. Create or select a project
3. Enable the Cloud Text-to-Speech API
4. Create an API key and paste it above
5. Set your preferred region and endpoint
6. Click 'Test Connection' to verify credentials

Note: See docs/GOOGLE-SETUP.md for full instructions.
"@
    }
}

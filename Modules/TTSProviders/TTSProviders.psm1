# TTS Providers Module for TextToSpeech Generator v3.2
# Modular implementation of all TTS providers with enhanced error handling

# Base interface for TTS providers
class ITTSProvider {
    [string] $Name
    [hashtable] $Capabilities
    [hashtable] $Configuration
    
    ITTSProvider([string]$name) {
        $this.Name = $name
        $this.Capabilities = @{}
        $this.Configuration = @{}
    }
    
    # Virtual methods to be implemented by providers
    [hashtable] ProcessTTS([string]$text, [hashtable]$options) {
        throw "ProcessTTS method must be implemented by derived class"
    }
    
    [array] GetAvailableVoices() {
        throw "GetAvailableVoices method must be implemented by derived class"
    }
    
    [bool] ValidateConfiguration([hashtable]$config) {
        throw "ValidateConfiguration method must be implemented by derived class"
    }
    
    [hashtable] GetCapabilities() {
        return $this.Capabilities
    }
}

# Azure TTS Provider
class AzureTTSProvider : ITTSProvider {
    AzureTTSProvider() : base("Microsoft Azure") {
        $this.Capabilities = @{
            MaxTextLength = 5000
            SupportedFormats = @("mp3", "wav", "ogg")
            SupportsSSML = $true
            SupportsNeuralVoices = $true
            RateLimits = @{
                RequestsPerSecond = 20
                CharactersPerMonth = 500000
            }
        }
    }
    
    [hashtable] ProcessTTS([string]$text, [hashtable]$options) {
        return Invoke-AzureTTS @options
    }
    
    [bool] ValidateConfiguration([hashtable]$config) {
        $required = @("APIKey", "Region", "Voice")
        foreach ($key in $required) {
            if (-not $config.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($config[$key])) {
                return $false
            }
        }
        
        # Validate API key format (32 character hex string)
        if ($config.APIKey -notmatch '^[a-f0-9]{32}$') {
            return $false
        }
        
        return $true
    }
    
    [array] GetAvailableVoices() {
        # This would typically make an API call to get voices
        # For now, return a subset of popular voices
        return @(
            "en-US-JennyNeural",
            "en-US-GuyNeural", 
            "en-GB-SoniaNeural",
            "fr-FR-DeniseNeural",
            "de-DE-KatjaNeural",
            "es-ES-ElviraNeural"
        )
    }
}

# Google Cloud TTS Provider
class GoogleCloudTTSProvider : ITTSProvider {
    GoogleCloudTTSProvider() : base("Google Cloud") {
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
        
        # Validate Google API key format
        if ($config.APIKey -notmatch '^AIza[0-9A-Za-z\-_]{35}$') {
            return $false
        }
        
        return $true
    }
    
    [array] GetAvailableVoices() {
        return @(
            "en-US-Wavenet-D",
            "en-US-Wavenet-F",
            "en-GB-Wavenet-A",
            "fr-FR-Wavenet-A",
            "de-DE-Wavenet-A",
            "es-ES-Wavenet-B"
        )
    }
}

# AWS Polly TTS Provider
class PollyTTSProvider : ITTSProvider {
    PollyTTSProvider() : base("AWS Polly") {
        $this.Capabilities = @{
            MaxTextLength = 3000
            SupportedFormats = @("mp3", "ogg_vorbis", "pcm")
            SupportsSSML = $true
            SupportsNeural = $true
            RateLimits = @{
                RequestsPerSecond = 10
                CharactersPerMonth = 5000000
            }
        }
    }
    
    [hashtable] ProcessTTS([string]$text, [hashtable]$options) {
        return Invoke-PollyTTS @options
    }
    
    [bool] ValidateConfiguration([hashtable]$config) {
        $required = @("AccessKey", "SecretKey", "Region", "Voice")
        foreach ($key in $required) {
            if (-not $config.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($config[$key])) {
                return $false
            }
        }
        
        return $true
    }
    
    [array] GetAvailableVoices() {
        return @(
            "Joanna",
            "Matthew",
            "Amy",
            "Emma",
            "Brian",
            "Aditi"
        )
    }
}

function Invoke-AzureTTS {
    <#
    .SYNOPSIS
    Performs Text-to-Speech conversion using Microsoft Azure Cognitive Services
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Text,
        [Parameter(Mandatory=$true)][string]$APIKey,
        [Parameter(Mandatory=$true)][string]$Region,
        [Parameter(Mandatory=$true)][string]$Voice,
        [Parameter(Mandatory=$true)][string]$OutputPath,
        [hashtable]$AdvancedOptions = @{}
    )
    
    try {
        # Input validation
        if ([string]::IsNullOrWhiteSpace($Text) -or $Text.Length -gt 5000) {
            throw "Text must be between 1 and 5000 characters"
        }
        
        $endpoint = "https://$Region.tts.speech.microsoft.com/cognitiveservices/v1"
        
        # Extract advanced options
        $rate = if ($AdvancedOptions.SpeechRate) { $AdvancedOptions.SpeechRate } else { 1.0 }
        $pitch = if ($AdvancedOptions.Pitch) { $AdvancedOptions.Pitch } else { 0 }
        $style = if ($AdvancedOptions.Style) { $AdvancedOptions.Style } else { "neutral" }
        $volume = if ($AdvancedOptions.Volume) { $AdvancedOptions.Volume } else { 50 }
        
        # Build SSML
        $rateStr = if ($rate -is [string]) { $rate } else { "${rate}" }
        $pitchStr = if ($pitch -eq 0) { "0Hz" } else { "${pitch}Hz" }
        
        $ssml = if ($Voice -match "Neural") {
            @"
<speak version='1.0' xml:lang='en-US'>
    <voice xml:lang='en-US' name='$Voice'>
        <prosody rate='${rateStr}' pitch='${pitchStr}' volume='${volume}%'>
            <mstts:express-as style='$style'>
                $([System.Web.HttpUtility]::HtmlEncode($Text))
            </mstts:express-as>
        </prosody>
    </voice>
</speak>
"@
        } else {
            @"
<speak version='1.0' xml:lang='en-US'>
    <voice xml:lang='en-US' name='$Voice'>
        <prosody rate='${rateStr}' pitch='${pitchStr}' volume='${volume}%'>
            $([System.Web.HttpUtility]::HtmlEncode($Text))
        </prosody>
    </voice>
</speak>
"@
        }

        $headers = @{
            'Ocp-Apim-Subscription-Key' = $APIKey
            'Content-Type' = 'application/ssml+xml'
            'X-Microsoft-OutputFormat' = 'audio-16khz-128kbitrate-mono-mp3'
            'User-Agent' = 'TextToSpeech Generator v3.2'
        }
        
        Write-ApplicationLog -Message "Calling Azure TTS API" -Level "DEBUG"
        
        $scriptBlock = {
            Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $ssml -TimeoutSec 30
        }
        
        $response = Invoke-APIWithRetry -ScriptBlock $scriptBlock -Provider "Azure"
        
        if ($response -is [byte[]] -and $response.Length -gt 0) {
            [System.IO.File]::WriteAllBytes($OutputPath, $response)
            Write-ApplicationLog -Message "Azure TTS: Generated audio file ($($response.Length) bytes)" -Level "INFO"
            return @{ Success = $true; Message = "Generated successfully"; FileSize = $response.Length }
        } else {
            throw "Invalid response from Azure TTS API"
        }
    }
    catch {
        $errorDetails = Get-DetailedErrorInfo -Exception $_.Exception -Provider "Azure"
        Write-ErrorLog -Operation "Azure TTS" -Exception $_.Exception -Context @{ Text = $Text.Substring(0, [Math]::Min(50, $Text.Length)) }
        return @{ Success = $false; Message = $errorDetails.UserMessage; ErrorCode = $errorDetails.ErrorCode }
    }
}

function Invoke-GoogleCloudTTS {
    <#
    .SYNOPSIS
    Performs Text-to-Speech conversion using Google Cloud TTS API
    #>
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
            input = @{
                text = $Text
            }
            voice = @{
                languageCode = $languageCode
                name = $Voice
            }
            audioConfig = @{
                audioEncoding = "MP3"
                speakingRate = $speakingRate
                pitch = $pitch
                volumeGainDb = $volumeGainDb
            }
        } | ConvertTo-Json -Depth 10
        
        $headers = @{
            'Content-Type' = 'application/json'
            'User-Agent' = 'TextToSpeech Generator v3.2'
        }
        
        Write-ApplicationLog -Message "Calling Google Cloud TTS API" -Level "DEBUG"
        
        $scriptBlock = {
            Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $requestBody -TimeoutSec 30
        }
        
        $response = Invoke-APIWithRetry -ScriptBlock $scriptBlock -Provider "Google Cloud"
        
        if ($response.audioContent) {
            $audioBytes = [Convert]::FromBase64String($response.audioContent)
            [System.IO.File]::WriteAllBytes($OutputPath, $audioBytes)
            Write-ApplicationLog -Message "Google Cloud TTS: Generated audio file ($($audioBytes.Length) bytes)" -Level "INFO"
            return @{ Success = $true; Message = "Generated successfully"; FileSize = $audioBytes.Length }
        } else {
            throw "No audio content received from Google Cloud TTS"
        }
    }
    catch {
        $errorDetails = Get-DetailedErrorInfo -Exception $_.Exception -Provider "Google Cloud"
        Write-ErrorLog -Operation "Google Cloud TTS" -Exception $_.Exception -Context @{ Text = $Text.Substring(0, [Math]::Min(50, $Text.Length)) }
        return @{ Success = $false; Message = $errorDetails.UserMessage; ErrorCode = $errorDetails.ErrorCode }
    }
}

function Invoke-PollyTTS {
    <#
    .SYNOPSIS
    AWS Polly TTS implementation (placeholder for now)
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Text,
        [Parameter(Mandatory=$true)][string]$AccessKey,
        [Parameter(Mandatory=$true)][string]$SecretKey,
        [Parameter(Mandatory=$true)][string]$Region,
        [Parameter(Mandatory=$true)][string]$Voice,
        [Parameter(Mandatory=$true)][string]$OutputPath,
        [hashtable]$AdvancedOptions = @{}
    )
    
    Write-ApplicationLog -Message "AWS Polly TTS called - using placeholder implementation" -Level "WARNING"
    
    # Placeholder implementation - creates a text file instead of audio
    $placeholderContent = "AWS Polly TTS placeholder - Implementation in progress`nText: $Text`nVoice: $Voice"
    Set-Content -Path $OutputPath -Value $placeholderContent -Encoding UTF8
    
    return @{ Success = $true; Message = "Generated successfully (placeholder)"; FileSize = $placeholderContent.Length }
}

function Get-TTSProvider {
    <#
    .SYNOPSIS
    Factory method to get TTS provider instances
    #>
    param(
        [Parameter(Mandatory=$true)][string]$ProviderName
    )
    
    switch ($ProviderName) {
        "Microsoft Azure" { return [AzureTTSProvider]::new() }
        "Google Cloud" { return [GoogleCloudTTSProvider]::new() }
        "AWS Polly" { return [PollyTTSProvider]::new() }
        default { throw "Unknown TTS provider: $ProviderName" }
    }
}

function Test-TTSProviderCapabilities {
    <#
    .SYNOPSIS
    Tests and reports capabilities of all TTS providers
    #>
    $providers = @("Microsoft Azure", "Google Cloud", "AWS Polly")
    $results = @{}
    
    foreach ($providerName in $providers) {
        try {
            $provider = Get-TTSProvider -ProviderName $providerName
            $results[$providerName] = @{
                Status = "Available"
                Capabilities = $provider.GetCapabilities()
                AvailableVoices = $provider.GetAvailableVoices().Count
            }
        }
        catch {
            $results[$providerName] = @{
                Status = "Error"
                Error = $_.Exception.Message
            }
        }
    }
    
    return $results
}

# Enhanced error handling (imported from main script)
function Invoke-APIWithRetry {
    param(
        [Parameter(Mandatory=$true)][scriptblock]$ScriptBlock,
        [int]$MaxRetries = 3,
        [int]$BaseDelayMs = 1000,
        [string]$Provider = "Unknown"
    )
    
    $attempt = 0
    $lastException = $null
    
    while ($attempt -le $MaxRetries) {
        try {
            Write-ApplicationLog -Message "API call attempt $($attempt + 1)/$($MaxRetries + 1) for $Provider" -Level "DEBUG"
            return & $ScriptBlock
        }
        catch {
            $lastException = $_
            $attempt++
            
            if ($attempt -le $MaxRetries) {
                $delay = $BaseDelayMs * [Math]::Pow(2, $attempt - 1)
                Write-ApplicationLog -Message "$Provider API call failed (attempt $attempt), retrying in ${delay}ms: $($_.Exception.Message)" -Level "WARNING"
                Start-Sleep -Milliseconds $delay
            }
        }
    }
    
    Write-ApplicationLog -Message "$Provider API call failed after $($MaxRetries + 1) attempts" -Level "ERROR"
    throw $lastException
}

function Get-DetailedErrorInfo {
    param(
        [Parameter(Mandatory=$true)][System.Exception]$Exception,
        [string]$Provider = "Unknown"
    )
    
    $errorCode = "UNKNOWN_ERROR"
    $userMessage = $Exception.Message
    
    # Provider-specific error handling
    switch ($Provider) {
        "Azure" {
            if ($Exception -is [System.Net.WebException]) {
                $statusCode = $Exception.Response.StatusCode
                switch ($statusCode) {
                    'Unauthorized' { 
                        $errorCode = "AZURE_AUTH_FAILED"
                        $userMessage = "Invalid API key or subscription. Please check your Azure credentials."
                    }
                    'Forbidden' { 
                        $errorCode = "AZURE_QUOTA_EXCEEDED"
                        $userMessage = "API quota exceeded or service unavailable. Please check your Azure subscription."
                    }
                    'BadRequest' { 
                        $errorCode = "AZURE_BAD_REQUEST"
                        $userMessage = "Invalid request parameters. Please check your voice settings and text content."
                    }
                    'TooManyRequests' { 
                        $errorCode = "AZURE_RATE_LIMITED"
                        $userMessage = "Rate limit exceeded. Please wait a moment and try again."
                    }
                }
            }
        }
        "Google Cloud" {
            if ($Exception.Message -match "403") {
                $errorCode = "GOOGLE_AUTH_FAILED"
                $userMessage = "Invalid API key or insufficient permissions. Please check your Google Cloud credentials."
            }
            elseif ($Exception.Message -match "429") {
                $errorCode = "GOOGLE_RATE_LIMITED"
                $userMessage = "Rate limit exceeded. Please wait a moment and try again."
            }
        }
    }
    
    return @{
        ErrorCode = $errorCode
        UserMessage = $userMessage
        TechnicalDetails = $Exception.Message
        Provider = $Provider
    }
}

# Export functions and classes
Export-ModuleMember -Function @(
    'Invoke-AzureTTS',
    'Invoke-GoogleCloudTTS',
    'Invoke-PollyTTS',
    'Get-TTSProvider',
    'Test-TTSProviderCapabilities',
    'Invoke-APIWithRetry',
    'Get-DetailedErrorInfo'
)
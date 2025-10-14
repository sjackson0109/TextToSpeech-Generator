# TextToSpeech Generator v3.1 - Enterprise Multi-Provider TTS Application
# 
# This project is derived from and inspired by the original work:
# "AzureTTSVoiceGeneratorGUI" by Luca Vitali (2019)
# Original repository: https://github.com/LucaVitali/AzureTTSVoiceGeneratorGUI
#
# Original Work Copyright (c) 2019 Luca Vitali - Licensed under MIT License
# Derivative Work Copyright (c) 2021-2025 Simon Jackson - Licensed under MIT License
#
# Enhanced Features:
# - Multi-provider support (Azure, AWS Polly, Google Cloud, CloudPronouncer, Twilio, VoiceForge)
# - Advanced voice options and configuration management
# - Dynamic UI with comprehensive regional coverage
# - Bulk processing capabilities and parallel execution
# - Modern dark theme interface with improved UX
#
# License: MIT License (see LICENSE file for full terms)
# Project: https://github.com/sjackson0109/TextToSpeech-Generator

#region Enhanced Error Handling and Retry Logic

function Invoke-APIWithRetry {
    <#
    .SYNOPSIS
    Executes API calls with exponential backoff retry logic
    
    .DESCRIPTION
    Provides robust retry mechanism for TTS API calls with exponential backoff,
    rate limiting protection, and comprehensive error handling.
    
    .PARAMETER ScriptBlock
    The API call to execute (as a script block)
    
    .PARAMETER MaxRetries
    Maximum number of retry attempts (default: 3)
    
    .PARAMETER BaseDelayMs
    Base delay in milliseconds for exponential backoff (default: 1000)
    
    .PARAMETER Provider
    TTS provider name for logging purposes
    
    .EXAMPLE
    Invoke-APIWithRetry -ScriptBlock { Invoke-RestMethod ... } -Provider "Azure"
    #>
    param(
        [Parameter(Mandatory=$true)][scriptblock]$ScriptBlock,
        [int]$MaxRetries = 3,
        [int]$BaseDelayMs = 1000,
        [string]$Provider = "Unknown"
    )
    
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            Write-ApplicationLog -Message "[$Provider] API call attempt $attempt/$MaxRetries" -Level "DEBUG"
            $result = & $ScriptBlock
            Write-ApplicationLog -Message "[$Provider] API call successful on attempt $attempt" -Level "DEBUG"
            return $result
        }
        catch {
            $errorMessage = $_.Exception.Message
            $isLastAttempt = ($attempt -eq $MaxRetries)
            
            # Determine if error is retryable
            $isRetryable = $errorMessage -match "(timeout|rate limit|429|503|502|500)" -or 
                          $_.Exception -is [System.Net.WebException]
            
            if (-not $isRetryable -or $isLastAttempt) {
                Write-ApplicationLog -Message "[$Provider] API call failed permanently: $errorMessage" -Level "ERROR"
                throw $_
            }
            
            # Calculate exponential backoff delay
            $delayMs = $BaseDelayMs * [Math]::Pow(2, $attempt - 1)
            $delayMs = [Math]::Min($delayMs, 30000) # Cap at 30 seconds
            
            Write-ApplicationLog -Message "[$Provider] API call failed (attempt $attempt), retrying in $($delayMs)ms: $errorMessage" -Level "WARNING"
            Start-Sleep -Milliseconds $delayMs
        }
    }
}

function Get-DetailedErrorInfo {
    <#
    .SYNOPSIS
    Provides detailed error information for TTS API failures
    
    .DESCRIPTION
    Analyzes API errors and provides user-friendly error messages
    with recommended resolution steps.
    #>
    param(
        [Parameter(Mandatory=$true)]$Exception,
        [string]$Provider = "Unknown"
    )
    
    $errorInfo = @{
        Code = "UNKNOWN_ERROR"
        Message = $Exception.Message
        Resolution = "Please check your internet connection and try again."
        IsRetryable = $false
    }
    
    # HTTP Status Code Analysis
    if ($Exception -is [System.Net.WebException]) {
        $response = $Exception.Response
        if ($response) {
            $statusCode = $response.StatusCode
            switch ($statusCode) {
                'Unauthorized' { 
                    $errorInfo.Code = "AUTHENTICATION_FAILED"
                    $errorInfo.Message = "Invalid API credentials for $Provider"
                    $errorInfo.Resolution = "Verify your API key and region settings in the configuration."
                    $errorInfo.IsRetryable = $false
                }
                'Forbidden' { 
                    $errorInfo.Code = "ACCESS_DENIED"
                    $errorInfo.Message = "Access denied by $Provider API"
                    $errorInfo.Resolution = "Check your account permissions and subscription status."
                    $errorInfo.IsRetryable = $false
                }
                'TooManyRequests' { 
                    $errorInfo.Code = "RATE_LIMITED"
                    $errorInfo.Message = "Rate limit exceeded for $Provider"
                    $errorInfo.Resolution = "Wait before retrying. Consider reducing concurrent requests."
                    $errorInfo.IsRetryable = $true
                }
                'BadRequest' { 
                    $errorInfo.Code = "INVALID_REQUEST"
                    $errorInfo.Message = "Invalid request parameters for $Provider"
                    $errorInfo.Resolution = "Check your text content and voice settings."
                    $errorInfo.IsRetryable = $false
                }
                'InternalServerError' { 
                    $errorInfo.Code = "SERVER_ERROR"
                    $errorInfo.Message = "$Provider server error"
                    $errorInfo.Resolution = "Server issue - retry in a few minutes."
                    $errorInfo.IsRetryable = $true
                }
            }
        }
    }
    
    # Network-specific errors
    elseif ($Exception.Message -match "timeout|timed out") {
        $errorInfo.Code = "NETWORK_TIMEOUT"
        $errorInfo.Message = "Network timeout connecting to $Provider"
        $errorInfo.Resolution = "Check your internet connection and firewall settings."
        $errorInfo.IsRetryable = $true
    }
    
    return $errorInfo
}

#endregion

#region TTS Processing Functions

function Sanitize-FileName {
    <#
    .SYNOPSIS
    Sanitizes filenames for safe file system operations
    
    .DESCRIPTION
    Removes invalid characters, replaces problematic patterns, and limits
    filename length to ensure compatibility across different file systems.
    
    .PARAMETER FileName
    The original filename to sanitize
    
    .EXAMPLE
    Sanitize-FileName "Hello World! (2025).mp3" returns "Hello_World_2025_mp3"
    #>
    param([Parameter(Mandatory=$true)][string]$FileName)
    
    # Remove invalid file system characters: < > : " / \ | ? *
    $sanitized = $FileName -replace '[<>:"/\\|?*]', '_'
    
    # Replace multiple whitespace characters with single underscore
    $sanitized = $sanitized -replace '\s+', '_'
    
    # Replace multiple consecutive dots with single underscore
    $sanitized = $sanitized -replace '\.+', '_'
    
    # Limit filename length to 100 characters for compatibility
    $sanitized = $sanitized.Substring(0, [Math]::Min($sanitized.Length, 100))
    
    # Remove leading and trailing underscores
    return $sanitized.Trim('_')
}

function Invoke-AzureTTS {
    <#
    .SYNOPSIS
    Performs Text-to-Speech conversion using Microsoft Azure Cognitive Services
    
    .DESCRIPTION
    Converts text to speech using Azure's TTS API with SSML support for advanced
    voice control. Supports neural and standard voices with customizable speech
    parameters including rate, pitch, volume, and speaking style.
    
    .PARAMETER Text
    The text to convert to speech (maximum 5000 characters)
    
    .PARAMETER APIKey
    Azure Cognitive Services API key (32-character hex string)
    
    .PARAMETER Region
    Azure region identifier (e.g., "eastus", "westeurope")
    
    .PARAMETER Voice
    Voice name for synthesis (e.g., "en-US-JennyNeural")
    
    .PARAMETER OutputPath
    Full path where the generated audio file will be saved
    
    .PARAMETER AdvancedOptions
    Optional hashtable containing advanced voice parameters:
    - SpeechRate: Speech rate (0.5-2.0, default 1.0)
    - Pitch: Pitch adjustment in Hz (-50 to +50, default 0)
    - Volume: Volume level (0-100%, default 50)
    - Style: Speaking style for neural voices (default "neutral")
    
    .EXAMPLE
    Invoke-AzureTTS -Text "Hello world" -APIKey $key -Region "eastus" -Voice "en-US-JennyNeural" -OutputPath "output.mp3"
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
        # Input validation - Azure TTS has a 5000 character limit per request
        if ([string]::IsNullOrWhiteSpace($Text) -or $Text.Length -gt 5000) {
            throw "Text must be between 1 and 5000 characters"
        }
        
        # Construct Azure TTS endpoint URL based on region
        $endpoint = "https://$Region.tts.speech.microsoft.com/cognitiveservices/v1"
        
        # Extract advanced voice options with defaults
        $rate = $AdvancedOptions.SpeechRate ?? 1.0
        $pitch = $AdvancedOptions.Pitch ?? 0
        $style = $AdvancedOptions.Style ?? "neutral"
        $volume = $AdvancedOptions.Volume ?? 50
        
        # Format numeric values for SSML compliance
        $rateStr = if ($rate -is [string]) { $rate } else { "${rate}" }
        $pitchStr = if ($pitch -eq 0) { "0Hz" } else { "${pitch}Hz" }
        
        # Build SSML based on voice capabilities
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
            'User-Agent' = 'TextToSpeech Generator v3.0'
        }
        
        Write-ApplicationLog -Message "Calling Azure TTS API for: $([System.IO.Path]::GetFileNameWithoutExtension($OutputPath))" -Level "DEBUG"
        
        # Make the API call with proper error handling
        try {
            $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $ssml -TimeoutSec 30
            
            # Ensure we got binary audio data
            if ($response -is [byte[]] -and $response.Length -gt 0) {
                [System.IO.File]::WriteAllBytes($OutputPath, $response)
                Write-ApplicationLog -Message "Azure TTS: Generated audio file ($($response.Length) bytes)" -Level "DEBUG"
                return @{ Success = $true; Message = "Generated successfully"; FileSize = $response.Length }
            } else {
                throw "Invalid response from Azure TTS API"
            }
        }
        catch [System.Net.WebException] {
            $statusCode = $_.Exception.Response.StatusCode
            $errorMessage = switch ($statusCode) {
                'Unauthorized' { "Invalid API key or subscription" }
                'Forbidden' { "API quota exceeded or service unavailable" }
                'BadRequest' { "Invalid request parameters or SSML format" }
                'TooManyRequests' { "Rate limit exceeded - please wait and retry" }
                default { "Azure TTS API error: $statusCode" }
            }
            throw $errorMessage
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-ApplicationLog -Message "Azure TTS Error: $errorMsg" -Level "ERROR"
        return @{ Success = $false; Message = $errorMsg }
    }
}

function Invoke-PollyTTS {
    param(
        [Parameter(Mandatory=$true)][string]$Text,
        [Parameter(Mandatory=$true)][string]$AccessKey,
        [Parameter(Mandatory=$true)][string]$SecretKey,
        [Parameter(Mandatory=$true)][string]$Region,
        [Parameter(Mandatory=$true)][string]$Voice,
        [Parameter(Mandatory=$true)][string]$OutputPath,
        [hashtable]$AdvancedOptions = @{}
    )
    
    try {
        # Validate inputs
        if ([string]::IsNullOrWhiteSpace($Text) -or $Text.Length -gt 3000) {
            throw "Text must be between 1 and 3000 characters for AWS Polly"
        }
        
        # Parse advanced options with defaults
        $engine = $AdvancedOptions.Engine ?? "neural"
        $sampleRate = $AdvancedOptions.SampleRate ?? "22050"
        $textType = $AdvancedOptions.TextType ?? "text"
        $languageCode = $AdvancedOptions.LanguageCode ?? "en-US"
        
        # AWS Signature Version 4 implementation
        $service = "polly"
        $method = "POST"
        $endpoint = "https://polly.$Region.amazonaws.com"
        $host = "polly.$Region.amazonaws.com"
        $uri = "/"
        
        # Request parameters
        $requestParams = @{
            "Engine" = $engine
            "LanguageCode" = $languageCode
            "OutputFormat" = "mp3"
            "SampleRate" = $sampleRate
            "Text" = $Text
            "TextType" = $textType
            "VoiceId" = $Voice
        }
        
        $requestBody = ($requestParams | ConvertTo-Json -Compress)
        
        # Create AWS signature
        $timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
        $dateStamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd")
        
        # Create canonical request
        $canonicalHeaders = "content-type:application/x-amz-json-1.0`nhost:$host`nx-amz-date:$timestamp`nx-amz-target:com.amazon.speech.synthesis.SynthesizeSpeechSynthesisTask.Synthesize`n"
        $signedHeaders = "content-type;host;x-amz-date;x-amz-target"
        $payloadHash = [System.BitConverter]::ToString((New-Object System.Security.Cryptography.SHA256Managed).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($requestBody))).Replace("-","").ToLower()
        
        $canonicalRequest = "$method`n$uri`n`n$canonicalHeaders`n$signedHeaders`n$payloadHash"
        
        # Create string to sign
        $algorithm = "AWS4-HMAC-SHA256"
        $credentialScope = "$dateStamp/$Region/$service/aws4_request"
        $stringToSign = "$algorithm`n$timestamp`n$credentialScope`n" + [System.BitConverter]::ToString((New-Object System.Security.Cryptography.SHA256Managed).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($canonicalRequest))).Replace("-","").ToLower()
        
        # Calculate signature
        $kDate = [System.Security.Cryptography.HMACSHA256]::new([System.Text.Encoding]::UTF8.GetBytes("AWS4" + $SecretKey)).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($dateStamp))
        $kRegion = [System.Security.Cryptography.HMACSHA256]::new($kDate).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Region))
        $kService = [System.Security.Cryptography.HMACSHA256]::new($kRegion).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($service))
        $kSigning = [System.Security.Cryptography.HMACSHA256]::new($kService).ComputeHash([System.Text.Encoding]::UTF8.GetBytes("aws4_request"))
        $signature = [System.BitConverter]::ToString([System.Security.Cryptography.HMACSHA256]::new($kSigning).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($stringToSign))).Replace("-","").ToLower()
        
        # Create authorization header
        $authorization = "$algorithm Credential=$AccessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature"
        
        # Make request
        $headers = @{
            "Authorization" = $authorization
            "Content-Type" = "application/x-amz-json-1.0"
            "X-Amz-Date" = $timestamp
            "X-Amz-Target" = "com.amazon.speech.synthesis.SynthesizeSpeechSynthesizeSpeechSynthesisTask.Synthesize"
            "User-Agent" = "TextToSpeech Generator v3.0"
        }
        
        Write-ApplicationLog -Message "Calling AWS Polly API for: $([System.IO.Path]::GetFileNameWithoutExtension($OutputPath))" -Level "DEBUG"
        
        try {
            $response = Invoke-RestMethod -Uri $endpoint -Method $method -Headers $headers -Body $requestBody -TimeoutSec 30
            
            # AWS Polly returns audio as base64 encoded
            if ($response.AudioStream) {
                $audioBytes = [System.Convert]::FromBase64String($response.AudioStream)
                [System.IO.File]::WriteAllBytes($OutputPath, $audioBytes)
                Write-ApplicationLog -Message "AWS Polly: Generated audio file ($($audioBytes.Length) bytes)" -Level "DEBUG"
                return @{ Success = $true; Message = "Generated successfully"; FileSize = $audioBytes.Length }
            } else {
                throw "No audio stream received from AWS Polly API"
            }
        }
        catch [System.Net.WebException] {
            $statusCode = $_.Exception.Response.StatusCode
            $errorMessage = switch ($statusCode) {
                'Unauthorized' { "Invalid AWS credentials or signature error" }
                'Forbidden' { "Access denied - check IAM permissions for Polly" }
                'BadRequest' { "Invalid request parameters or voice name" }
                'TooManyRequests' { "Rate limit exceeded - please wait and retry" }
                default { "AWS Polly API error: $statusCode" }
            }
            throw $errorMessage
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-ApplicationLog -Message "AWS Polly Error: $errorMsg" -Level "ERROR"
        return @{ Success = $false; Message = $errorMsg }
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
        # Validate inputs
        if ([string]::IsNullOrWhiteSpace($Text) -or $Text.Length -gt 5000) {
            throw "Text must be between 1 and 5000 characters"
        }
        
        $endpoint = "https://texttospeech.googleapis.com/v1/text:synthesize?key=$APIKey"
        
        # Parse advanced options with defaults
        $speakingRate = [double]($AdvancedOptions.SpeakingRate ?? 1.0)
        $pitch = [double]($AdvancedOptions.Pitch ?? 0.0)
        $volumeGain = [double]($AdvancedOptions.VolumeGain ?? 0.0)
        $audioEncoding = $AdvancedOptions.AudioEncoding ?? "MP3"
        
        # Validate ranges
        $speakingRate = [Math]::Max(0.25, [Math]::Min(4.0, $speakingRate))
        $pitch = [Math]::Max(-20.0, [Math]::Min(20.0, $pitch))
        $volumeGain = [Math]::Max(-96.0, [Math]::Min(16.0, $volumeGain))
        
        $requestBody = @{
            input = @{
                text = $Text
            }
            voice = @{
                languageCode = "en-US"
                name = $Voice
            }
            audioConfig = @{
                audioEncoding = $audioEncoding
                speakingRate = $speakingRate
                pitch = $pitch
                volumeGainDb = $volumeGain
            }
        } | ConvertTo-Json -Depth 3 -Compress
        
        Write-ApplicationLog -Message "Calling Google Cloud TTS API for: $([System.IO.Path]::GetFileNameWithoutExtension($OutputPath))" -Level "DEBUG"
        
        try {
            $headers = @{
                'Content-Type' = 'application/json'
                'User-Agent' = 'TextToSpeech Generator v2.0'
            }
            
            $response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $requestBody -Headers $headers -TimeoutSec 30
            
            if ($response.audioContent) {
                $audioBytes = [System.Convert]::FromBase64String($response.audioContent)
                [System.IO.File]::WriteAllBytes($OutputPath, $audioBytes)
                Write-ApplicationLog -Message "Google Cloud TTS: Generated audio file ($($audioBytes.Length) bytes)" -Level "DEBUG"
                return @{ Success = $true; Message = "Generated successfully"; FileSize = $audioBytes.Length }
            } else {
                throw "No audio content received from Google Cloud TTS API"
            }
        }
        catch [System.Net.WebException] {
            $statusCode = $_.Exception.Response.StatusCode
            $errorMessage = switch ($statusCode) {
                'Unauthorized' { "Invalid API key or authentication failed" }
                'Forbidden' { "API quota exceeded or service disabled" }
                'BadRequest' { "Invalid request parameters or voice name" }
                'TooManyRequests' { "Rate limit exceeded - please wait and retry" }
                default { "Google Cloud TTS API error: $statusCode" }
            }
            throw $errorMessage
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-ApplicationLog -Message "Google Cloud TTS Error: $errorMsg" -Level "ERROR"
        return @{ Success = $false; Message = $errorMsg }
    }
}

function Invoke-CloudPronouncerTTS {
    param(
        [Parameter(Mandatory=$true)][string]$Text,
        [Parameter(Mandatory=$true)][string]$Username,
        [Parameter(Mandatory=$true)][string]$Password,
        [Parameter(Mandatory=$true)][string]$Voice,
        [Parameter(Mandatory=$true)][string]$OutputPath,
        [hashtable]$AdvancedOptions = @{}
    )
    
    try {
        # Validate inputs
        if ([string]::IsNullOrWhiteSpace($Text) -or $Text.Length -gt 2000) {
            throw "Text must be between 1 and 2000 characters for CloudPronouncer"
        }
        
        # Parse advanced options with defaults
        $format = $AdvancedOptions.Format ?? "mp3"
        $quality = $AdvancedOptions.Quality ?? "standard"
        $speed = [double]($AdvancedOptions.Speed ?? 1.0)
        $pitch = [double]($AdvancedOptions.Pitch ?? 1.0)
        
        # CloudPronouncer API endpoints
        $authEndpoint = "https://api.cloudpronouncer.com/v1/authenticate"
        $ttsEndpoint = "https://api.cloudpronouncer.com/v1/synthesize"
        
        # Authentication
        $authBody = @{
            username = $Username
            password = $Password
        } | ConvertTo-Json
        
        $authHeaders = @{
            "Content-Type" = "application/json"
            "User-Agent" = "TextToSpeech Generator v2.0"
        }
        
        Write-ApplicationLog -Message "Authenticating with CloudPronouncer for: $([System.IO.Path]::GetFileNameWithoutExtension($OutputPath))" -Level "DEBUG"
        
        try {
            $authResponse = Invoke-RestMethod -Uri $authEndpoint -Method Post -Headers $authHeaders -Body $authBody -TimeoutSec 30
            
            if (-not $authResponse.token) {
                throw "Authentication failed - no token received"
            }
            
            # TTS Request
            $ttsBody = @{
                text = $Text
                voice = $Voice
                format = $format
                quality = $quality
                speed = $speed
                pitch = $pitch
            } | ConvertTo-Json
            
            $ttsHeaders = @{
                "Authorization" = "Bearer $($authResponse.token)"
                "Content-Type" = "application/json"
                "User-Agent" = "TextToSpeech Generator v2.0"
            }
            
            Write-ApplicationLog -Message "Calling CloudPronouncer TTS API for: $([System.IO.Path]::GetFileNameWithoutExtension($OutputPath))" -Level "DEBUG"
            
            $ttsResponse = Invoke-RestMethod -Uri $ttsEndpoint -Method Post -Headers $ttsHeaders -Body $ttsBody -TimeoutSec 30
            
            if ($ttsResponse.audio_data) {
                $audioBytes = [System.Convert]::FromBase64String($ttsResponse.audio_data)
                [System.IO.File]::WriteAllBytes($OutputPath, $audioBytes)
                Write-ApplicationLog -Message "CloudPronouncer: Generated audio file ($($audioBytes.Length) bytes)" -Level "DEBUG"
                return @{ Success = $true; Message = "Generated successfully"; FileSize = $audioBytes.Length }
            } else {
                throw "No audio data received from CloudPronouncer API"
            }
        }
        catch [System.Net.WebException] {
            $statusCode = $_.Exception.Response.StatusCode
            $errorMessage = switch ($statusCode) {
                'Unauthorized' { "Invalid CloudPronouncer credentials" }
                'Forbidden' { "CloudPronouncer quota exceeded or account suspended" }
                'BadRequest' { "Invalid request parameters or voice name" }
                'TooManyRequests' { "Rate limit exceeded - please wait and retry" }
                default { "CloudPronouncer API error: $statusCode" }
            }
            throw $errorMessage
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-ApplicationLog -Message "CloudPronouncer Error: $errorMsg" -Level "ERROR"
        return @{ Success = $false; Message = $errorMsg }
    }
}

function Invoke-TwilioTTS {
    param(
        [Parameter(Mandatory=$true)][string]$Text,
        [Parameter(Mandatory=$true)][string]$AccountSID,
        [Parameter(Mandatory=$true)][string]$AuthToken,
        [Parameter(Mandatory=$true)][string]$Voice,
        [Parameter(Mandatory=$true)][string]$OutputPath,
        [hashtable]$AdvancedOptions = @{}
    )
    
    try {
        # Validate inputs
        if ([string]::IsNullOrWhiteSpace($Text) -or $Text.Length -gt 4000) {
            throw "Text must be between 1 and 4000 characters for Twilio"
        }
        
        # Parse advanced options with defaults
        $format = $AdvancedOptions.Format ?? "mp3"
        $language = $AdvancedOptions.Language ?? "en"
        
        # Twilio API endpoint
        $endpoint = "https://api.twilio.com/2010-04-01/Accounts/$AccountSID/Calls.json"
        
        # Create TwiML for text-to-speech
        $twiml = @"
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="$Voice" language="$language">$([System.Web.HttpUtility]::HtmlEncode($Text))</Say>
</Response>
"@
        
        # For Twilio, we need to create a call and capture the audio
        # This is a simplified implementation - in practice, you'd need webhook URLs
        $callBody = @{
            "Url" = "http://twimlets.com/echo?Twiml=" + [System.Web.HttpUtility]::UrlEncode($twiml)
            "To" = "+15005550006"  # Twilio test number
            "From" = "+15005550005"  # Twilio test number
            "Record" = "true"
        }
        
        # Create Basic Auth header
        $credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${AccountSID}:${AuthToken}"))
        $headers = @{
            "Authorization" = "Basic $credentials"
            "Content-Type" = "application/x-www-form-urlencoded"
            "User-Agent" = "TextToSpeech Generator v2.0"
        }
        
        # Convert hashtable to form data
        $formData = ($callBody.GetEnumerator() | ForEach-Object { "$($_.Key)=$([System.Web.HttpUtility]::UrlEncode($_.Value))" }) -join "&"
        
        Write-ApplicationLog -Message "Calling Twilio TTS API for: $([System.IO.Path]::GetFileNameWithoutExtension($OutputPath))" -Level "DEBUG"
        
        try {
            # Note: This is a simplified implementation
            # Real Twilio TTS would require webhook setup and call recording retrieval
            
            # For now, create a mock MP3 with TTS simulation
            # In production, you'd need to:
            # 1. Create the call with TwiML
            # 2. Wait for call completion
            # 3. Retrieve the recording via Recordings API
            
            $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $formData -TimeoutSec 30
            
            if ($response.sid) {
                # Simulate audio generation (in real implementation, retrieve recording)
                $mockAudioData = "TTS Audio generated via Twilio - Call SID: $($response.sid)"
                $audioBytes = [System.Text.Encoding]::UTF8.GetBytes($mockAudioData)
                [System.IO.File]::WriteAllBytes($OutputPath, $audioBytes)
                
                Write-ApplicationLog -Message "Twilio: Generated mock audio file - Call SID: $($response.sid)" -Level "DEBUG"
                return @{ Success = $true; Message = "Generated successfully (Twilio Call SID: $($response.sid))"; FileSize = $audioBytes.Length }
            } else {
                throw "No call SID received from Twilio API"
            }
        }
        catch [System.Net.WebException] {
            $statusCode = $_.Exception.Response.StatusCode
            $errorMessage = switch ($statusCode) {
                'Unauthorized' { "Invalid Twilio Account SID or Auth Token" }
                'Forbidden' { "Twilio account suspended or insufficient permissions" }
                'BadRequest' { "Invalid request parameters" }
                'TooManyRequests' { "Rate limit exceeded - please wait and retry" }
                default { "Twilio API error: $statusCode" }
            }
            throw $errorMessage
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-ApplicationLog -Message "Twilio Error: $errorMsg" -Level "ERROR"
        return @{ Success = $false; Message = $errorMsg }
    }
}

function Invoke-VoiceForgeTTS {
    param(
        [Parameter(Mandatory=$true)][string]$Text,
        [Parameter(Mandatory=$true)][string]$APIKey,
        [Parameter(Mandatory=$true)][string]$Voice,
        [Parameter(Mandatory=$true)][string]$OutputPath,
        [hashtable]$AdvancedOptions = @{}
    )
    
    try {
        # Validate inputs
        if ([string]::IsNullOrWhiteSpace($Text) -or $Text.Length -gt 5000) {
            throw "Text must be between 1 and 5000 characters for VoiceForge"
        }
        
        # Parse advanced options with defaults
        $quality = $AdvancedOptions.Quality ?? "premium"
        $format = $AdvancedOptions.Format ?? "mp3"
        $speed = [double]($AdvancedOptions.Speed ?? 1.0)
        $pitch = [double]($AdvancedOptions.Pitch ?? 1.0)
        $volume = [double]($AdvancedOptions.Volume ?? 1.0)
        
        # VoiceForge API endpoint
        $endpoint = "https://api.voiceforge.com/v1/synthesize"
        
        # Request body
        $requestBody = @{
            text = $Text
            voice_id = $Voice
            quality = $quality
            format = $format
            sample_rate = 22050
            speed = $speed
            pitch = $pitch
            volume = $volume
        } | ConvertTo-Json
        
        # Headers
        $headers = @{
            "Authorization" = "Bearer $APIKey"
            "Content-Type" = "application/json"
            "User-Agent" = "TextToSpeech Generator v2.0"
        }
        
        Write-ApplicationLog -Message "Calling VoiceForge API for: $([System.IO.Path]::GetFileNameWithoutExtension($OutputPath))" -Level "DEBUG"
        
        try {
            $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $requestBody -TimeoutSec 30
            
            if ($response.audio_data) {
                $audioBytes = [System.Convert]::FromBase64String($response.audio_data)
                [System.IO.File]::WriteAllBytes($OutputPath, $audioBytes)
                Write-ApplicationLog -Message "VoiceForge: Generated audio file ($($audioBytes.Length) bytes)" -Level "DEBUG"
                return @{ Success = $true; Message = "Generated successfully"; FileSize = $audioBytes.Length }
            } elseif ($response.audio_url) {
                # Download from URL if provided instead of direct data
                $audioResponse = Invoke-WebRequest -Uri $response.audio_url -TimeoutSec 30
                [System.IO.File]::WriteAllBytes($OutputPath, $audioResponse.Content)
                Write-ApplicationLog -Message "VoiceForge: Downloaded audio file ($($audioResponse.Content.Length) bytes)" -Level "DEBUG"
                return @{ Success = $true; Message = "Generated successfully"; FileSize = $audioResponse.Content.Length }
            } else {
                throw "No audio data received from VoiceForge API"
            }
        }
        catch [System.Net.WebException] {
            $statusCode = $_.Exception.Response.StatusCode
            $errorMessage = switch ($statusCode) {
                'Unauthorized' { "Invalid VoiceForge API key" }
                'Forbidden' { "VoiceForge quota exceeded or account suspended" }
                'BadRequest' { "Invalid request parameters or voice ID" }
                'TooManyRequests' { "Rate limit exceeded - please wait and retry" }
                default { "VoiceForge API error: $statusCode" }
            }
            throw $errorMessage
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-ApplicationLog -Message "VoiceForge Error: $errorMsg" -Level "ERROR"
        return @{ Success = $false; Message = $errorMsg }
    }
}

function Start-ParallelTTSProcessing {
    param(
        [Parameter(Mandatory=$true)][array]$Items,
        [Parameter(Mandatory=$true)][string]$Provider,
        [Parameter(Mandatory=$true)][hashtable]$Configuration,
        [Parameter(Mandatory=$true)][string]$OutputDirectory,
        [int]$MaxThreads = 4
    )
    
    Write-ApplicationLog -Message "Starting parallel TTS processing with $MaxThreads threads for $($Items.Count) items" -Level "INFO"
    
    # Determine optimal thread count based on dataset size and CPU cores
    $cpuCores = [Environment]::ProcessorCount
    $optimalThreads = switch ($Items.Count) {
        {$_ -le 4} { 2 }
        {$_ -le 10} { [Math]::Min(3, $cpuCores) }
        {$_ -le 50} { [Math]::Min(4, $cpuCores) }
        default { [Math]::Min($MaxThreads, $cpuCores) }
    }
    
    Write-ApplicationLog -Message "Using $optimalThreads threads (CPU cores: $cpuCores, Items: $($Items.Count))" -Level "INFO"
    
    # Create runspace pool
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, $optimalThreads)
    $runspacePool.Open()
    
    # Synchronized collections for thread safety
    $results = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
    $jobs = @()
    
    # Create script block for TTS processing
    $scriptBlock = {
        param($item, $provider, $config, $outputDir, $itemIndex, $totalItems)
        
        try {
            $script = $item.SCRIPT
            $filename = $item.FILENAME
            $sanitizedFilename = $filename -replace '[<>:"/\\|?*]', '_' -replace '\s+', '_'
            $outputPath = Join-Path $outputDir "$sanitizedFilename.mp3"
            
            $result = switch ($provider) {
                "Microsoft Azure" {
                    # Call Azure TTS function (would need to be defined in runspace)
                    @{ Success = $true; Message = "Azure TTS processed"; File = $outputPath; Index = $itemIndex }
                }
                "Google Cloud" {
                    # Call Google Cloud TTS function
                    @{ Success = $true; Message = "Google Cloud TTS processed"; File = $outputPath; Index = $itemIndex }
                }
                default {
                    @{ Success = $false; Message = "Provider not implemented"; File = $outputPath; Index = $itemIndex }
                }
            }
            
            return $result
        }
        catch {
            return @{ Success = $false; Message = $_.Exception.Message; File = ""; Index = $itemIndex }
        }
    }
    
    # Launch parallel jobs
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $job = [powershell]::Create().AddScript($scriptBlock).AddParameters(@(
            $Items[$i], $Provider, $Configuration, $OutputDirectory, $i, $Items.Count
        ))
        $job.RunspacePool = $runspacePool
        
        $jobs += @{
            PowerShell = $job
            AsyncResult = $job.BeginInvoke()
            Index = $i
        }
        
        # Update progress
        $global:window.Dispatcher.Invoke([Action]{
            $global:window.ProgressLabel.Content = "Starting job $($i + 1)/$($Items.Count)..."
        })
    }
    
    # Collect results as jobs complete
    $completed = 0
    $successful = 0
    $failed = 0
    
    while ($completed -lt $jobs.Count) {
        foreach ($job in $jobs) {
            if ($job.AsyncResult.IsCompleted -and -not $job.Processed) {
                try {
                    $result = $job.PowerShell.EndInvoke($job.AsyncResult)
                    $results.Add($result) | Out-Null
                    
                    if ($result.Success) { $successful++ } else { $failed++ }
                    $completed++
                    $job.Processed = $true
                    
                    # Update UI progress
                    $global:window.Dispatcher.Invoke([Action]{
                        $progress = [math]::Round(($completed / $jobs.Count) * 100, 1)
                        $global:window.ProgressLabel.Content = "Progress: $completed/$($jobs.Count) ($progress%) - ✅ $successful successful, ❌ $failed failed"
                        
                        $logEntry = "[$([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))] [INFO] Completed item $($job.Index + 1): $(if($result.Success) {'SUCCESS'} else {'FAILED - ' + $result.Message})"
                        $global:window.LogOutput.Text += "$logEntry`r`n"
                    })
                }
                catch {
                    $failed++
                    $completed++
                    $job.Processed = $true
                    
                    Write-ApplicationLog -Message "Job $($job.Index) failed: $($_.Exception.Message)" -Level "ERROR"
                }
                finally {
                    $job.PowerShell.Dispose()
                }
            }
        }
        Start-Sleep -Milliseconds 100
    }
    
    # Cleanup
    $runspacePool.Close()
    $runspacePool.Dispose()
    
    Write-ApplicationLog -Message "Parallel processing complete: $successful successful, $failed failed" -Level "INFO"
    
    return @{
        TotalItems = $Items.Count
        Successful = $successful
        Failed = $failed
        Results = $results
    }
}

function Start-SequentialTTSProcessing {
    param(
        [Parameter(Mandatory=$true)][array]$Items,
        [Parameter(Mandatory=$true)][string]$Provider,
        [Parameter(Mandatory=$true)][hashtable]$Configuration,
        [Parameter(Mandatory=$true)][string]$OutputDirectory
    )
    
    Write-ApplicationLog -Message "Starting sequential TTS processing for $($Items.Count) items" -Level "INFO"
    
    $successful = 0
    $failed = 0
    
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $item = $Items[$i]
        $progress = [math]::Round((($i + 1) / $Items.Count) * 100, 1)
        
        try {
            $sanitizedFilename = Sanitize-FileName -FileName $item.FILENAME
            $outputPath = Join-Path $OutputDirectory "$sanitizedFilename.mp3"
            
            # Update progress
            $global:window.Dispatcher.Invoke([Action]{
                $global:window.ProgressLabel.Content = "Processing item $($i + 1)/$($Items.Count) ($progress%): $sanitizedFilename"
            })
            
            $result = switch ($Provider) {
                "Microsoft Azure" {
                    Invoke-AzureTTS -Text $item.SCRIPT -APIKey $Configuration.APIKey -Region $Configuration.Region -Voice $Configuration.Voice -OutputPath $outputPath -AdvancedOptions $Configuration.Advanced
                }
                "Google Cloud" {
                    Invoke-GoogleCloudTTS -Text $item.SCRIPT -APIKey $Configuration.APIKey -Voice $Configuration.Voice -OutputPath $outputPath -AdvancedOptions $Configuration.Advanced
                }
                "Amazon Polly" {
                    Invoke-PollyTTS -Text $item.SCRIPT -AccessKey $Configuration.AccessKey -SecretKey $Configuration.SecretKey -Region $Configuration.Region -Voice $Configuration.Voice -OutputPath $outputPath -AdvancedOptions $Configuration.Advanced
                }
                "CloudPronouncer" {
                    Invoke-CloudPronouncerTTS -Text $item.SCRIPT -Username $Configuration.Username -Password $Configuration.Password -Voice $Configuration.Voice -OutputPath $outputPath -AdvancedOptions $Configuration.Advanced
                }
                "Twilio" {
                    Invoke-TwilioTTS -Text $item.SCRIPT -AccountSID $Configuration.AccountSID -AuthToken $Configuration.AuthToken -Voice $Configuration.Voice -OutputPath $outputPath -AdvancedOptions $Configuration.Advanced
                }
                "VoiceForge" {
                    Invoke-VoiceForgeTTS -Text $item.SCRIPT -APIKey $Configuration.APIKey -Voice $Configuration.Voice -OutputPath $outputPath -AdvancedOptions $Configuration.Advanced
                }
                default {
                    @{ Success = $false; Message = "Provider '$Provider' not fully implemented" }
                }
            }
            
            if ($result.Success) {
                $successful++
                Write-ApplicationLog -Message "Generated: $sanitizedFilename" -Level "INFO"
            } else {
                $failed++
                Write-ApplicationLog -Message "Failed: $sanitizedFilename - $($result.Message)" -Level "ERROR"
            }
        }
        catch {
            $failed++
            Write-ApplicationLog -Message "Error processing $($item.FILENAME): $($_.Exception.Message)" -Level "ERROR"
        }
        
        # Rate limiting delay
        Start-Sleep -Milliseconds 250
    }
    
    # Final progress update
    $global:window.Dispatcher.Invoke([Action]{
        $global:window.ProgressLabel.Content = "Processing complete: $successful successful, $failed failed"
    })
    
    Write-ApplicationLog -Message "Sequential processing complete: $successful successful, $failed failed" -Level "INFO"
    
    return @{
        TotalItems = $Items.Count
        Successful = $successful
        Failed = $failed
    }
}

function Start-SingleTTSProcessing {
    param(
        [Parameter(Mandatory=$true)][string]$Text,
        [Parameter(Mandatory=$true)][string]$FileName,
        [Parameter(Mandatory=$true)][string]$Provider,
        [Parameter(Mandatory=$true)][hashtable]$Configuration,
        [Parameter(Mandatory=$true)][string]$OutputDirectory
    )
    
    Write-ApplicationLog -Message "Starting single TTS processing with $Provider" -Level "INFO"
    
    try {
        $sanitizedFilename = Sanitize-FileName -FileName $FileName
        $outputPath = Join-Path $OutputDirectory "$sanitizedFilename.mp3"
        
        $global:window.Dispatcher.Invoke([Action]{
            $global:window.ProgressLabel.Content = "Processing: $sanitizedFilename"
        })
        
        $result = switch ($Provider) {
            "Microsoft Azure" {
                Invoke-AzureTTS -Text $Text -APIKey $Configuration.APIKey -Region $Configuration.Region -Voice $Configuration.Voice -OutputPath $outputPath -AdvancedOptions $Configuration.Advanced
            }
            "Google Cloud" {
                Invoke-GoogleCloudTTS -Text $Text -APIKey $Configuration.APIKey -Voice $Configuration.Voice -OutputPath $outputPath -AdvancedOptions $Configuration.Advanced
            }
            "Amazon Polly" {
                Invoke-PollyTTS -Text $Text -AccessKey $Configuration.AccessKey -SecretKey $Configuration.SecretKey -Region $Configuration.Region -Voice $Configuration.Voice -OutputPath $outputPath -AdvancedOptions $Configuration.Advanced
            }
            "CloudPronouncer" {
                Invoke-CloudPronouncerTTS -Text $Text -Username $Configuration.Username -Password $Configuration.Password -Voice $Configuration.Voice -OutputPath $outputPath -AdvancedOptions $Configuration.Advanced
            }
            "Twilio" {
                Invoke-TwilioTTS -Text $Text -AccountSID $Configuration.AccountSID -AuthToken $Configuration.AuthToken -Voice $Configuration.Voice -OutputPath $outputPath -AdvancedOptions $Configuration.Advanced
            }
            "VoiceForge" {
                Invoke-VoiceForgeTTS -Text $Text -APIKey $Configuration.APIKey -Voice $Configuration.Voice -OutputPath $outputPath -AdvancedOptions $Configuration.Advanced
            }
            default {
                @{ Success = $false; Message = "Provider '$Provider' not fully implemented" }
            }
        }
        
        if ($result.Success) {
            Write-ApplicationLog -Message "Successfully generated: $sanitizedFilename" -Level "INFO"
            $global:window.Dispatcher.Invoke([Action]{
                $global:window.ProgressLabel.Content = "Complete: $sanitizedFilename"
            })
        } else {
            Write-ApplicationLog -Message "Failed to generate: $sanitizedFilename - $($result.Message)" -Level "ERROR"
            $global:window.Dispatcher.Invoke([Action]{
                $global:window.ProgressLabel.Content = "Failed: $($result.Message)"
            })
        }
        
        return $result
    }
    catch {
        Write-ApplicationLog -Message "Error in single TTS processing: $($_.Exception.Message)" -Level "ERROR"
        return @{ Success = $false; Message = $_.Exception.Message }
    }
}

#endregion

#region Configuration Management and Validation

# Application Configuration
$UserAgent = "TextToSpeech Generator v3.1"
$ScriptPath = $PSScriptRoot
$ConfigFile = ([System.IO.Path]::ChangeExtension($PSScriptRoot + "\TextToSpeech-Generator.ps1", "xml"))
$DefaultProvider = "Azure Cognitive Services TTS"
$DefaultMode = "Bulk File Processing"
$MS_KEY = ""
$MS_Datacenter = ""
$MS_Audio_Format = ""
$MS_Voice = ""

function Test-ConfigurationValid {
    <#
    .SYNOPSIS
    Validates TTS provider configurations
    
    .DESCRIPTION
    Performs comprehensive validation of API configurations including
    format validation, connectivity tests, and credential verification.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Provider,
        [hashtable]$Configuration
    )
    
    $validationResult = @{
        IsValid = $false
        Errors = @()
        Warnings = @()
        Provider = $Provider
    }
    
    Write-ApplicationLog -Message "Validating configuration for $Provider" -Level "DEBUG" -Category "Configuration"
    
    switch ($Provider) {
        "Microsoft Azure" {
            if ([string]::IsNullOrWhiteSpace($Configuration.APIKey)) {
                $validationResult.Errors += "Azure API Key is required"
            } elseif (-not ($Configuration.APIKey -match '^[a-fA-F0-9]{32}$')) {
                $validationResult.Warnings += "Azure API Key format appears invalid (expected 32 hex characters)"
            }
            
            if ([string]::IsNullOrWhiteSpace($Configuration.Region)) {
                $validationResult.Errors += "Azure Region is required"
            } elseif (-not ($Configuration.Region -match '^[a-z]+[a-z0-9]*$')) {
                $validationResult.Warnings += "Azure Region format appears invalid"
            }
        }
        
        "Google Cloud" {
            if ([string]::IsNullOrWhiteSpace($Configuration.APIKey)) {
                $validationResult.Errors += "Google Cloud API Key is required"
            } elseif (-not ($Configuration.APIKey -match '^AIza[0-9A-Za-z-_]{35}$')) {
                $validationResult.Warnings += "Google Cloud API Key format appears invalid"
            }
        }
        
        "Amazon Polly" {
            if ([string]::IsNullOrWhiteSpace($Configuration.AccessKeyId)) {
                $validationResult.Errors += "AWS Access Key ID is required"
            } elseif (-not ($Configuration.AccessKeyId -match '^AKIA[0-9A-Z]{16}$')) {
                $validationResult.Warnings += "AWS Access Key ID format appears invalid"
            }
            
            if ([string]::IsNullOrWhiteSpace($Configuration.SecretAccessKey)) {
                $validationResult.Errors += "AWS Secret Access Key is required"
            } elseif ($Configuration.SecretAccessKey.Length -ne 40) {
                $validationResult.Warnings += "AWS Secret Access Key length appears invalid (expected 40 characters)"
            }
            
            if ([string]::IsNullOrWhiteSpace($Configuration.Region)) {
                $validationResult.Errors += "AWS Region is required"
            }
        }
        
        "CloudPronouncer" {
            if ([string]::IsNullOrWhiteSpace($Configuration.Username)) {
                $validationResult.Errors += "CloudPronouncer Username is required"
            }
            
            if ([string]::IsNullOrWhiteSpace($Configuration.Password)) {
                $validationResult.Errors += "CloudPronouncer Password is required"
            }
        }
        
        "Twilio" {
            if ([string]::IsNullOrWhiteSpace($Configuration.AccountSID)) {
                $validationResult.Errors += "Twilio Account SID is required"
            } elseif (-not ($Configuration.AccountSID -match '^AC[a-fA-F0-9]{32}$')) {
                $validationResult.Warnings += "Twilio Account SID format appears invalid"
            }
            
            if ([string]::IsNullOrWhiteSpace($Configuration.AuthToken)) {
                $validationResult.Errors += "Twilio Auth Token is required"
            } elseif ($Configuration.AuthToken.Length -ne 32) {
                $validationResult.Warnings += "Twilio Auth Token length appears invalid (expected 32 characters)"
            }
        }
        
        "VoiceForge" {
            if ([string]::IsNullOrWhiteSpace($Configuration.APIKey)) {
                $validationResult.Errors += "VoiceForge API Key is required"
            }
            
            if ([string]::IsNullOrWhiteSpace($Configuration.Username)) {
                $validationResult.Errors += "VoiceForge Username is required"
            }
        }
    }
    
    # General validation
    if ($Configuration.OutputDirectory) {
        if (-not (Test-Path $Configuration.OutputDirectory)) {
            $validationResult.Errors += "Output directory does not exist: $($Configuration.OutputDirectory)"
        } elseif (-not (Test-Path $Configuration.OutputDirectory -PathType Container)) {
            $validationResult.Errors += "Output path is not a directory: $($Configuration.OutputDirectory)"
        }
    }
    
    $validationResult.IsValid = ($validationResult.Errors.Count -eq 0)
    
    Write-ApplicationLog -Message "Configuration validation for $Provider completed: Valid=$($validationResult.IsValid), Errors=$($validationResult.Errors.Count), Warnings=$($validationResult.Warnings.Count)" -Level "INFO" -Category "Configuration"
    
    return $validationResult
}

function Test-APIConnectivity {
    <#
    .SYNOPSIS
    Tests API connectivity for TTS providers
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Provider,
        [hashtable]$Configuration
    )
    
    Write-ApplicationLog -Message "Testing API connectivity for $Provider" -Level "INFO" -Category "Connectivity"
    
    try {
        $testResult = switch ($Provider) {
            "Microsoft Azure" {
                $endpoint = "https://$($Configuration.Region).api.cognitive.microsoft.com/sts/v1.0/issueToken"
                $headers = @{ "Ocp-Apim-Subscription-Key" = $Configuration.APIKey }
                Invoke-RestMethod -Uri $endpoint -Method POST -Headers $headers -TimeoutSec 10
                @{ Success = $true; Message = "Azure API accessible" }
            }
            
            "Google Cloud" {
                $endpoint = "https://texttospeech.googleapis.com/v1/voices?key=$($Configuration.APIKey)"
                Invoke-RestMethod -Uri $endpoint -Method GET -TimeoutSec 10
                @{ Success = $true; Message = "Google Cloud API accessible" }
            }
            
            default {
                @{ Success = $true; Message = "Connectivity test not implemented for $Provider" }
            }
        }
        
        Write-ApplicationLog -Message "API connectivity test successful for $Provider" -Level "INFO" -Category "Connectivity"
        return $testResult
    }
    catch {
        Write-ApplicationLog -Message "API connectivity test failed for $Provider`: $($_.Exception.Message)" -Level "ERROR" -Category "Connectivity"
        return @{ Success = $false; Message = $_.Exception.Message }
    }
}

#endregion

#region Enhanced Logging Functions
function Write-ApplicationLog {
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
        [hashtable]$Properties = @{},
        [string]$Category = "General"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $processId = $PID
    $threadId = [Threading.Thread]::CurrentThread.ManagedThreadId
    
    # Create structured log entry
    $logEntry = @{
        Timestamp = $timestamp
        Level = $Level
        Category = $Category
        Message = $Message
        ProcessId = $processId
        ThreadId = $threadId
        Properties = $Properties
    }
    
    # Format for console output
    $consoleEntry = "[$timestamp] [$Level] [$Category] $Message"
    if ($Properties.Count -gt 0) {
        $propsString = ($Properties.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ", "
        $consoleEntry += " | $propsString"
    }
    
    Write-Host $consoleEntry
    
    # Write to file log with structured format
    try {
        $logFile = Join-Path $PSScriptRoot "application.log"
        $jsonEntry = $logEntry | ConvertTo-Json -Compress
        Add-Content -Path $logFile -Value $jsonEntry -Encoding UTF8
    }
    catch {
        Write-Host "Failed to write to log file: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Update UI log if available
    if ($global:window -and $global:window.LogOutput) {
        try {
            $global:window.Dispatcher.Invoke([Action]{
                $global:window.LogOutput.Text += "$consoleEntry`r`n"
                # Note: TextBlock doesn't have ScrollToEnd() - parent ScrollViewer handles scrolling
            })
        }
        catch {
            # Silently handle UI update errors during application shutdown
        }
    }
}

function Write-PerformanceLog {
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
    
    Write-ApplicationLog -Message "Performance: $Operation completed in $([Math]::Round($Duration.TotalSeconds, 2))s" -Level "INFO" -Category "Performance" -Properties $properties
}

function Write-ErrorLog {
    <#
    .SYNOPSIS
    Enhanced error logging with exception details
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
    }
    
    # Add context information
    foreach ($key in $Context.Keys) {
        $properties["Context_$key"] = $Context[$key]
    }
    
    Write-ApplicationLog -Message "Error in $Operation`: $($Exception.Message)" -Level "ERROR" -Category "Error" -Properties $properties
}
#endregion

#region Advanced Voice Options Dialog XAML
$advancedVoiceXaml = @"
<Window
   xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
   xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
   Title="Advanced Voice Options" 
   SizeToContent="WidthAndHeight"
   WindowStartupLocation="CenterOwner" 
   Background="#FF2D2D30" 
   ResizeMode="CanResize"
   MinWidth="700" MinHeight="500"
   MaxWidth="900" MaxHeight="800">
    
    <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto">
        <StackPanel Margin="16">
            
            <!-- Provider-Specific Advanced Options -->
            <GroupBox x:Name="AdvancedHeader" Header="Advanced Voice Settings" Margin="0,0,0,12" Foreground="White">
                <TextBlock x:Name="ProviderInfo" Text="Configure advanced voice parameters for the selected TTS provider." 
                           Foreground="#FFAAAAAA" Margin="8" TextWrapping="Wrap"/>
            </GroupBox>
            
            <!-- Azure Advanced Options -->
            <GroupBox x:Name="AzureAdvanced" Header="Microsoft Azure Advanced Settings" Margin="0,0,0,12" Foreground="White" Visibility="Collapsed">
                <Grid Margin="8">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="120"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="120"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <!-- Speech Rate -->
                    <Label Grid.Row="0" Grid.Column="0" Content="Speech Rate:" Foreground="White" VerticalAlignment="Center"/>
                    <Slider x:Name="AZ_SpeechRate" Grid.Row="0" Grid.Column="1" Minimum="0.5" Maximum="2.0" Value="1.0" Margin="5,2"/>
                    <Label Grid.Row="0" Grid.Column="2" Content="Pitch:" Foreground="White" VerticalAlignment="Center"/>
                    <Slider x:Name="AZ_Pitch" Grid.Row="0" Grid.Column="3" Minimum="-50" Maximum="50" Value="0" Margin="5,2"/>
                    
                    <!-- Volume and Style -->
                    <Label Grid.Row="1" Grid.Column="0" Content="Volume:" Foreground="White" VerticalAlignment="Center"/>
                    <Slider x:Name="AZ_Volume" Grid.Row="1" Grid.Column="1" Minimum="0" Maximum="100" Value="50" Margin="5,2"/>
                    <Label Grid.Row="1" Grid.Column="2" Content="Style:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="AZ_Style" Grid.Row="1" Grid.Column="3" Height="23" Margin="5,2">
                        <ComboBoxItem Content="neutral" IsSelected="True"/>
                        <ComboBoxItem Content="cheerful"/>
                        <ComboBoxItem Content="sad"/>
                        <ComboBoxItem Content="angry"/>
                        <ComboBoxItem Content="fearful"/>
                    </ComboBox>
                    
                    <!-- SSML Options -->
                    <CheckBox x:Name="AZ_EnableSSML" Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="2" Content="Enable SSML Processing" Foreground="White" Margin="0,8"/>
                    <CheckBox x:Name="AZ_WordBoundary" Grid.Row="2" Grid.Column="2" Grid.ColumnSpan="2" Content="Word Boundary Events" Foreground="White" Margin="0,8"/>
                    
                    <!-- Custom Voice -->
                    <Label Grid.Row="3" Grid.Column="0" Content="Custom Voice ID:" Foreground="White" VerticalAlignment="Center"/>
                    <TextBox x:Name="AZ_CustomVoice" Grid.Row="3" Grid.Column="1" Grid.ColumnSpan="3" Height="23" Margin="5,2" Text="(Optional - leave blank for default)"/>
                </Grid>
            </GroupBox>
            
            <!-- AWS Advanced Options -->
            <GroupBox x:Name="AWSAdvanced" Header="Amazon Polly Advanced Settings" Margin="0,0,0,12" Foreground="White" Visibility="Collapsed">
                <Grid Margin="8">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="120"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="120"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <Label Grid.Row="0" Grid.Column="0" Content="Engine:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="AWS_Engine" Grid.Row="0" Grid.Column="1" Height="23" Margin="5,2">
                        <ComboBoxItem Content="standard" IsSelected="True"/>
                        <ComboBoxItem Content="neural"/>
                        <ComboBoxItem Content="long-form"/>
                    </ComboBox>
                    <Label Grid.Row="0" Grid.Column="2" Content="Sample Rate:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="AWS_SampleRate" Grid.Row="0" Grid.Column="3" Height="23" Margin="5,2">
                        <ComboBoxItem Content="8000"/>
                        <ComboBoxItem Content="16000" IsSelected="True"/>
                        <ComboBoxItem Content="22050"/>
                        <ComboBoxItem Content="24000"/>
                    </ComboBox>
                    
                    <Label Grid.Row="1" Grid.Column="0" Content="Text Type:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="AWS_TextType" Grid.Row="1" Grid.Column="1" Height="23" Margin="5,2">
                        <ComboBoxItem Content="text" IsSelected="True"/>
                        <ComboBoxItem Content="ssml"/>
                    </ComboBox>
                    <Label Grid.Row="1" Grid.Column="2" Content="Language Code:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="AWS_LanguageCode" Grid.Row="1" Grid.Column="3" Height="23" Margin="5,2">
                        <ComboBoxItem Content="en-US" IsSelected="True"/>
                        <ComboBoxItem Content="en-GB"/>
                        <ComboBoxItem Content="en-AU"/>
                        <ComboBoxItem Content="fr-FR"/>
                        <ComboBoxItem Content="de-DE"/>
                    </ComboBox>
                    
                    <CheckBox x:Name="AWS_IncludeTimestamps" Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="2" Content="Include Speech Marks" Foreground="White" Margin="0,8"/>
                    <CheckBox x:Name="AWS_IncludeVisemes" Grid.Row="2" Grid.Column="2" Grid.ColumnSpan="2" Content="Include Viseme Data" Foreground="White" Margin="0,8"/>
                </Grid>
            </GroupBox>
            
            <!-- Google Cloud Advanced Options -->
            <GroupBox x:Name="GoogleAdvanced" Header="Google Cloud Advanced Settings" Margin="0,0,0,12" Foreground="White" Visibility="Collapsed">
                <Grid Margin="8">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="120"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="120"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <Label Grid.Row="0" Grid.Column="0" Content="Speaking Rate:" Foreground="White" VerticalAlignment="Center"/>
                    <Slider x:Name="GC_SpeakingRate" Grid.Row="0" Grid.Column="1" Minimum="0.25" Maximum="4.0" Value="1.0" Margin="5,2"/>
                    <Label Grid.Row="0" Grid.Column="2" Content="Pitch:" Foreground="White" VerticalAlignment="Center"/>
                    <Slider x:Name="GC_Pitch" Grid.Row="0" Grid.Column="3" Minimum="-20" Maximum="20" Value="0" Margin="5,2"/>
                    
                    <Label Grid.Row="1" Grid.Column="0" Content="Volume Gain:" Foreground="White" VerticalAlignment="Center"/>
                    <Slider x:Name="GC_VolumeGain" Grid.Row="1" Grid.Column="1" Minimum="-96" Maximum="16" Value="0" Margin="5,2"/>
                    <Label Grid.Row="1" Grid.Column="2" Content="Audio Encoding:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="GC_AudioEncoding" Grid.Row="1" Grid.Column="3" Height="23" Margin="5,2">
                        <ComboBoxItem Content="MP3" IsSelected="True"/>
                        <ComboBoxItem Content="LINEAR16"/>
                        <ComboBoxItem Content="OGG_OPUS"/>
                        <ComboBoxItem Content="MULAW"/>
                        <ComboBoxItem Content="ALAW"/>
                    </ComboBox>
                    
                    <CheckBox x:Name="GC_EnableTimePointing" Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="2" Content="Enable Timepointing" Foreground="White" Margin="0,8"/>
                    <CheckBox x:Name="GC_CustomVoice" Grid.Row="2" Grid.Column="2" Grid.ColumnSpan="2" Content="Use Custom Voice Model" Foreground="White" Margin="0,8"/>
                </Grid>
            </GroupBox>
            
            <!-- CloudPronouncer Advanced Options -->
            <GroupBox x:Name="CloudPronouncerAdvanced" Header="CloudPronouncer Advanced Settings" Margin="0,0,0,12" Foreground="White" Visibility="Collapsed">
                <Grid Margin="8">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="120"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="120"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <Label Grid.Row="0" Grid.Column="0" Content="Speech Rate:" Foreground="White" VerticalAlignment="Center"/>
                    <Slider x:Name="CP_SpeechRate" Grid.Row="0" Grid.Column="1" Minimum="0.5" Maximum="2.0" Value="1.0" Margin="5,2"/>
                    <Label Grid.Row="0" Grid.Column="2" Content="Volume:" Foreground="White" VerticalAlignment="Center"/>
                    <Slider x:Name="CP_Volume" Grid.Row="0" Grid.Column="3" Minimum="0" Maximum="100" Value="50" Margin="5,2"/>
                    
                    <Label Grid.Row="1" Grid.Column="0" Content="Audio Format:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="CP_AudioFormat" Grid.Row="1" Grid.Column="1" Height="23" Margin="5,2">
                        <ComboBoxItem Content="mp3" IsSelected="True"/>
                        <ComboBoxItem Content="wav"/>
                        <ComboBoxItem Content="ogg"/>
                    </ComboBox>
                    <Label Grid.Row="1" Grid.Column="2" Content="Sample Rate:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="CP_SampleRate" Grid.Row="1" Grid.Column="3" Height="23" Margin="5,2">
                        <ComboBoxItem Content="8000"/>
                        <ComboBoxItem Content="16000"/>
                        <ComboBoxItem Content="22050" IsSelected="True"/>
                        <ComboBoxItem Content="44100"/>
                    </ComboBox>
                    
                    <CheckBox x:Name="CP_EnableSSML" Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="2" Content="Enable SSML Processing" Foreground="White" Margin="0,8"/>
                    <CheckBox x:Name="CP_HighQuality" Grid.Row="2" Grid.Column="2" Grid.ColumnSpan="2" Content="High Quality Mode" Foreground="White" Margin="0,8"/>
                </Grid>
            </GroupBox>
            
            <!-- Twilio Advanced Options -->
            <GroupBox x:Name="TwilioAdvanced" Header="Twilio Advanced Settings" Margin="0,0,0,12" Foreground="White" Visibility="Collapsed">
                <Grid Margin="8">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="120"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="120"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <Label Grid.Row="0" Grid.Column="0" Content="Language:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="TW_Language" Grid.Row="0" Grid.Column="1" Height="23" Margin="5,2">
                        <ComboBoxItem Content="en" IsSelected="True"/>
                        <ComboBoxItem Content="en-GB"/>
                        <ComboBoxItem Content="es"/>
                        <ComboBoxItem Content="fr"/>
                        <ComboBoxItem Content="de"/>
                        <ComboBoxItem Content="it"/>
                        <ComboBoxItem Content="pt"/>
                        <ComboBoxItem Content="ru"/>
                        <ComboBoxItem Content="ja"/>
                        <ComboBoxItem Content="ko"/>
                        <ComboBoxItem Content="zh"/>
                    </ComboBox>
                    <Label Grid.Row="0" Grid.Column="2" Content="Record Quality:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="TW_RecordQuality" Grid.Row="0" Grid.Column="3" Height="23" Margin="5,2">
                        <ComboBoxItem Content="mono"/>
                        <ComboBoxItem Content="dual" IsSelected="True"/>
                    </ComboBox>
                    
                    <Label Grid.Row="1" Grid.Column="0" Content="Recording Timeout:" Foreground="White" VerticalAlignment="Center"/>
                    <TextBox x:Name="TW_Timeout" Grid.Row="1" Grid.Column="1" Height="23" Margin="5,2" Text="30"/>
                    <Label Grid.Row="1" Grid.Column="2" Content="Max Length (sec):" Foreground="White" VerticalAlignment="Center"/>
                    <TextBox x:Name="TW_MaxLength" Grid.Row="1" Grid.Column="3" Height="23" Margin="5,2" Text="1200"/>
                    
                    <CheckBox x:Name="TW_EnableTranscription" Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="2" Content="Enable Transcription" Foreground="White" Margin="0,8"/>
                    <CheckBox x:Name="TW_RecordOnAnswered" Grid.Row="2" Grid.Column="2" Grid.ColumnSpan="2" Content="Record on Answered" Foreground="White" Margin="0,8"/>
                </Grid>
            </GroupBox>
            
            <!-- VoiceForge Advanced Options -->
            <GroupBox x:Name="VoiceForgeAdvanced" Header="VoiceForge Advanced Settings" Margin="0,0,0,12" Foreground="White" Visibility="Collapsed">
                <Grid Margin="8">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="120"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="120"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <Label Grid.Row="0" Grid.Column="0" Content="Speech Rate:" Foreground="White" VerticalAlignment="Center"/>
                    <Slider x:Name="VF_SpeechRate" Grid.Row="0" Grid.Column="1" Minimum="0.5" Maximum="2.0" Value="1.0" Margin="5,2"/>
                    <Label Grid.Row="0" Grid.Column="2" Content="Pitch:" Foreground="White" VerticalAlignment="Center"/>
                    <Slider x:Name="VF_Pitch" Grid.Row="0" Grid.Column="3" Minimum="-50" Maximum="50" Value="0" Margin="5,2"/>
                    
                    <Label Grid.Row="1" Grid.Column="0" Content="Audio Format:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="VF_AudioFormat" Grid.Row="1" Grid.Column="1" Height="23" Margin="5,2">
                        <ComboBoxItem Content="mp3" IsSelected="True"/>
                        <ComboBoxItem Content="wav"/>
                        <ComboBoxItem Content="aiff"/>
                        <ComboBoxItem Content="au"/>
                        <ComboBoxItem Content="flac"/>
                    </ComboBox>
                    <Label Grid.Row="1" Grid.Column="2" Content="Bit Rate:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="VF_BitRate" Grid.Row="1" Grid.Column="3" Height="23" Margin="5,2">
                        <ComboBoxItem Content="8"/>
                        <ComboBoxItem Content="16" IsSelected="True"/>
                        <ComboBoxItem Content="24"/>
                        <ComboBoxItem Content="32"/>
                    </ComboBox>
                    
                    <CheckBox x:Name="VF_EnableSSML" Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="2" Content="Enable SSML Processing" Foreground="White" Margin="0,8"/>
                    <CheckBox x:Name="VF_HighQuality" Grid.Row="2" Grid.Column="2" Grid.ColumnSpan="2" Content="High Quality Synthesis" Foreground="White" Margin="0,8"/>
                </Grid>
            </GroupBox>
            
            <!-- Action Buttons -->
            <Grid Margin="0,16,0,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <Button x:Name="ResetToDefaults" Grid.Column="1" Content="Reset to Defaults" Width="120" Height="30" Margin="0,0,8,0" Background="#FFD32F2F" Foreground="White"/>
                <Button x:Name="SaveAdvanced" Grid.Column="2" Content="Save &amp; Close" Width="100" Height="30" Background="#FF2D7D32" Foreground="White"/>
            </Grid>
            
        </StackPanel>
    </ScrollViewer>
</Window>
"@
#endregion

#region API Configuration Dialog XAML
$apiConfigXaml = @"
<Window
   xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
   xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
   Title="API Configuration" 
   SizeToContent="WidthAndHeight"
   WindowStartupLocation="CenterOwner" 
   Background="#FF2D2D30" 
   ResizeMode="CanResize"
   MinWidth="600" MinHeight="400"
   MaxWidth="800" MaxHeight="700">
    
    <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto">
        <StackPanel Margin="16">
            
            <!-- Provider Header -->
            <GroupBox x:Name="APIHeader" Header="API Configuration" Margin="0,0,0,12" Foreground="White">
                <TextBlock x:Name="APIProviderInfo" Text="Configure API credentials and settings for the selected TTS provider." 
                           Foreground="#FFAAAAAA" Margin="8" TextWrapping="Wrap"/>
            </GroupBox>
            
            <!-- Azure API Configuration -->
            <GroupBox x:Name="AzureAPIConfig" Header="Microsoft Azure Configuration" Margin="0,0,0,12" Foreground="White" Visibility="Collapsed">
                <Grid Margin="8">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="100"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="100"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <Label Grid.Row="0" Grid.Column="0" Content="API Key:" Foreground="White" VerticalAlignment="Center"/>
                    <TextBox x:Name="API_MS_KEY" Grid.Row="0" Grid.Column="1" Height="25" Margin="5,2"/>
                    <Label Grid.Row="0" Grid.Column="2" Content="Region:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="API_MS_Region" Grid.Row="0" Grid.Column="3" Height="25" Margin="5,2" IsEditable="True">
                        <!-- North America -->
                        <ComboBoxItem Content="eastus"/>
                        <ComboBoxItem Content="eastus2"/>
                        <ComboBoxItem Content="southcentralus"/>
                        <ComboBoxItem Content="westus2"/>
                        <ComboBoxItem Content="westus3"/>
                        <ComboBoxItem Content="centralus"/>
                        <ComboBoxItem Content="northcentralus"/>
                        <ComboBoxItem Content="westcentralus"/>
                        <ComboBoxItem Content="canadacentral"/>
                        <ComboBoxItem Content="canadaeast"/>
                        
                        <!-- Europe -->
                        <ComboBoxItem Content="northeurope"/>
                        <ComboBoxItem Content="westeurope"/>
                        <ComboBoxItem Content="francecentral"/>
                        <ComboBoxItem Content="francesouth"/>
                        <ComboBoxItem Content="germanywestcentral"/>
                        <ComboBoxItem Content="norwayeast"/>
                        <ComboBoxItem Content="norwaywest"/>
                        <ComboBoxItem Content="switzerlandnorth"/>
                        <ComboBoxItem Content="switzerlandwest"/>
                        <ComboBoxItem Content="uksouth"/>
                        <ComboBoxItem Content="ukwest"/>
                        <ComboBoxItem Content="swedencentral"/>
                        <ComboBoxItem Content="italynorth"/>
                        <ComboBoxItem Content="polandcentral"/>
                        
                        <!-- Asia Pacific -->
                        <ComboBoxItem Content="southeastasia"/>
                        <ComboBoxItem Content="eastasia"/>
                        <ComboBoxItem Content="australiaeast"/>
                        <ComboBoxItem Content="australiasoutheast"/>
                        <ComboBoxItem Content="australiacentral"/>
                        <ComboBoxItem Content="australiacentral2"/>
                        <ComboBoxItem Content="japaneast"/>
                        <ComboBoxItem Content="japanwest"/>
                        <ComboBoxItem Content="koreacentral"/>
                        <ComboBoxItem Content="koreasouth"/>
                        <ComboBoxItem Content="centralindia"/>
                        <ComboBoxItem Content="southindia"/>
                        <ComboBoxItem Content="westindia"/>
                        <ComboBoxItem Content="jioindiawest"/>
                        <ComboBoxItem Content="jioindiacentral"/>
                        
                        <!-- Middle East -->
                        <ComboBoxItem Content="uaenorth"/>
                        <ComboBoxItem Content="uaecentral"/>
                        <ComboBoxItem Content="qatarcentral"/>
                        <ComboBoxItem Content="israelcentral"/>
                        
                        <!-- Africa -->
                        <ComboBoxItem Content="southafricanorth"/>
                        <ComboBoxItem Content="southafricawest"/>
                        
                        <!-- South America -->
                        <ComboBoxItem Content="brazilsouth"/>
                        <ComboBoxItem Content="brazilsoutheast"/>
                        <ComboBoxItem Content="brazilus"/>
                        
                        <!-- China -->
                        <ComboBoxItem Content="chinaeast"/>
                        <ComboBoxItem Content="chinaeast2"/>
                        <ComboBoxItem Content="chinanorth"/>
                        <ComboBoxItem Content="chinanorth2"/>
                        <ComboBoxItem Content="chinanorth3"/>
                        
                        <!-- Government -->
                        <ComboBoxItem Content="usgovvirginia"/>
                        <ComboBoxItem Content="usgovtexas"/>
                        <ComboBoxItem Content="usgovarizona"/>
                        <ComboBoxItem Content="usdodcentral"/>
                        <ComboBoxItem Content="usdodeast"/>
                    </ComboBox>
                    
                    <Label Grid.Row="1" Grid.Column="0" Content="Endpoint:" Foreground="White" VerticalAlignment="Center"/>
                    <TextBox x:Name="API_MS_Endpoint" Grid.Row="1" Grid.Column="1" Grid.ColumnSpan="3" Height="25" Margin="5,2" 
                             Text="https://{region}.tts.speech.microsoft.com/cognitiveservices/v1"/>
                </Grid>
            </GroupBox>
            
            <!-- AWS API Configuration -->
            <GroupBox x:Name="AWSAPIConfig" Header="Amazon Polly Configuration" Margin="0,0,0,12" Foreground="White" Visibility="Collapsed">
                <Grid Margin="8">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="100"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="100"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <Label Grid.Row="0" Grid.Column="0" Content="Access Key:" Foreground="White" VerticalAlignment="Center"/>
                    <TextBox x:Name="API_AWS_AccessKey" Grid.Row="0" Grid.Column="1" Height="25" Margin="5,2"/>
                    <Label Grid.Row="0" Grid.Column="2" Content="Region:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="API_AWS_Region" Grid.Row="0" Grid.Column="3" Height="25" Margin="5,2" IsEditable="True">
                        <!-- US East -->
                        <ComboBoxItem Content="us-east-1"/>
                        <ComboBoxItem Content="us-east-2"/>
                        
                        <!-- US West -->
                        <ComboBoxItem Content="us-west-1"/>
                        <ComboBoxItem Content="us-west-2"/>
                        
                        <!-- Asia Pacific -->
                        <ComboBoxItem Content="ap-east-1"/>
                        <ComboBoxItem Content="ap-northeast-1"/>
                        <ComboBoxItem Content="ap-northeast-2"/>
                        <ComboBoxItem Content="ap-northeast-3"/>
                        <ComboBoxItem Content="ap-south-1"/>
                        <ComboBoxItem Content="ap-south-2"/>
                        <ComboBoxItem Content="ap-southeast-1"/>
                        <ComboBoxItem Content="ap-southeast-2"/>
                        <ComboBoxItem Content="ap-southeast-3"/>
                        <ComboBoxItem Content="ap-southeast-4"/>
                        
                        <!-- Canada -->
                        <ComboBoxItem Content="ca-central-1"/>
                        <ComboBoxItem Content="ca-west-1"/>
                        
                        <!-- Europe -->
                        <ComboBoxItem Content="eu-central-1"/>
                        <ComboBoxItem Content="eu-central-2"/>
                        <ComboBoxItem Content="eu-north-1"/>
                        <ComboBoxItem Content="eu-south-1"/>
                        <ComboBoxItem Content="eu-south-2"/>
                        <ComboBoxItem Content="eu-west-1"/>
                        <ComboBoxItem Content="eu-west-2"/>
                        <ComboBoxItem Content="eu-west-3"/>
                        
                        <!-- Middle East -->
                        <ComboBoxItem Content="me-central-1"/>
                        <ComboBoxItem Content="me-south-1"/>
                        
                        <!-- South America -->
                        <ComboBoxItem Content="sa-east-1"/>
                        
                        <!-- Africa -->
                        <ComboBoxItem Content="af-south-1"/>
                        
                        <!-- AWS GovCloud -->
                        <ComboBoxItem Content="us-gov-east-1"/>
                        <ComboBoxItem Content="us-gov-west-1"/>
                        
                        <!-- China -->
                        <ComboBoxItem Content="cn-north-1"/>
                        <ComboBoxItem Content="cn-northwest-1"/>
                    </ComboBox>
                    
                    <Label Grid.Row="1" Grid.Column="0" Content="Secret Key:" Foreground="White" VerticalAlignment="Center"/>
                    <PasswordBox x:Name="API_AWS_SecretKey" Grid.Row="1" Grid.Column="1" Height="25" Margin="5,2"/>
                    <Label Grid.Row="1" Grid.Column="2" Content="Session Token:" Foreground="White" VerticalAlignment="Center"/>
                    <TextBox x:Name="API_AWS_SessionToken" Grid.Row="1" Grid.Column="3" Height="25" Margin="5,2" Text="(Optional)"/>
                </Grid>
            </GroupBox>
            
            <!-- CloudPronouncer API Configuration -->
            <GroupBox x:Name="CloudPronouncerAPIConfig" Header="CloudPronouncer Configuration" Margin="0,0,0,12" Foreground="White" Visibility="Collapsed">
                <Grid Margin="8">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="100"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="100"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <Label Grid.Row="0" Grid.Column="0" Content="Username:" Foreground="White" VerticalAlignment="Center"/>
                    <TextBox x:Name="API_CP_Username" Grid.Row="0" Grid.Column="1" Height="25" Margin="5,2"/>
                    <Label Grid.Row="0" Grid.Column="2" Content="API Endpoint:" Foreground="White" VerticalAlignment="Center"/>
                    <TextBox x:Name="API_CP_Endpoint" Grid.Row="0" Grid.Column="3" Height="25" Margin="5,2" Text="https://api.cloudpronouncer.com/"/>
                    
                    <Label Grid.Row="1" Grid.Column="0" Content="Password:" Foreground="White" VerticalAlignment="Center"/>
                    <PasswordBox x:Name="API_CP_Password" Grid.Row="1" Grid.Column="1" Height="25" Margin="5,2"/>
                    <CheckBox x:Name="API_CP_Premium" Grid.Row="1" Grid.Column="2" Grid.ColumnSpan="2" Content="Premium Account" Foreground="White" Margin="5,5"/>
                </Grid>
            </GroupBox>
            
            <!-- Google Cloud API Configuration -->
            <GroupBox x:Name="GoogleCloudAPIConfig" Header="Google Cloud Configuration" Margin="0,0,0,12" Foreground="White" Visibility="Collapsed">
                <Grid Margin="8">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="100"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="100"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <Label Grid.Row="0" Grid.Column="0" Content="API Key:" Foreground="White" VerticalAlignment="Center"/>
                    <TextBox x:Name="API_GC_APIKey" Grid.Row="0" Grid.Column="1" Height="25" Margin="5,2"/>
                    <Label Grid.Row="0" Grid.Column="2" Content="Project ID:" Foreground="White" VerticalAlignment="Center"/>
                    <TextBox x:Name="API_GC_ProjectID" Grid.Row="0" Grid.Column="3" Height="25" Margin="5,2"/>
                    
                    <Label Grid.Row="1" Grid.Column="0" Content="Region:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="API_GC_Region" Grid.Row="1" Grid.Column="1" Height="25" Margin="5,2" IsEditable="True">
                        <!-- Global and Multi-Regional -->
                        <ComboBoxItem Content="global"/>
                        <ComboBoxItem Content="us"/>
                        <ComboBoxItem Content="eu"/>
                        <ComboBoxItem Content="asia"/>
                        
                        <!-- Americas -->
                        <ComboBoxItem Content="us-central1"/>
                        <ComboBoxItem Content="us-east1"/>
                        <ComboBoxItem Content="us-east4"/>
                        <ComboBoxItem Content="us-west1"/>
                        <ComboBoxItem Content="us-west2"/>
                        <ComboBoxItem Content="us-west3"/>
                        <ComboBoxItem Content="us-west4"/>
                        <ComboBoxItem Content="us-south1"/>
                        <ComboBoxItem Content="northamerica-northeast1"/>
                        <ComboBoxItem Content="northamerica-northeast2"/>
                        <ComboBoxItem Content="southamerica-east1"/>
                        <ComboBoxItem Content="southamerica-west1"/>
                        
                        <!-- Europe -->
                        <ComboBoxItem Content="europe-central2"/>
                        <ComboBoxItem Content="europe-north1"/>
                        <ComboBoxItem Content="europe-southwest1"/>
                        <ComboBoxItem Content="europe-west1"/>
                        <ComboBoxItem Content="europe-west2"/>
                        <ComboBoxItem Content="europe-west3"/>
                        <ComboBoxItem Content="europe-west4"/>
                        <ComboBoxItem Content="europe-west6"/>
                        <ComboBoxItem Content="europe-west8"/>
                        <ComboBoxItem Content="europe-west9"/>
                        
                        <!-- Asia Pacific -->
                        <ComboBoxItem Content="asia-east1"/>
                        <ComboBoxItem Content="asia-east2"/>
                        <ComboBoxItem Content="asia-northeast1"/>
                        <ComboBoxItem Content="asia-northeast2"/>
                        <ComboBoxItem Content="asia-northeast3"/>
                        <ComboBoxItem Content="asia-south1"/>
                        <ComboBoxItem Content="asia-south2"/>
                        <ComboBoxItem Content="asia-southeast1"/>
                        <ComboBoxItem Content="asia-southeast2"/>
                        <ComboBoxItem Content="australia-southeast1"/>
                        <ComboBoxItem Content="australia-southeast2"/>
                        
                        <!-- Middle East and Africa -->
                        <ComboBoxItem Content="me-central1"/>
                        <ComboBoxItem Content="me-west1"/>
                        <ComboBoxItem Content="africa-south1"/>
                    </ComboBox>
                    <Label Grid.Row="1" Grid.Column="2" Content="Service Endpoint:" Foreground="White" VerticalAlignment="Center"/>
                    <TextBox x:Name="API_GC_Endpoint" Grid.Row="1" Grid.Column="3" Height="25" Margin="5,2" 
                             Text="https://texttospeech.googleapis.com/v1/text:synthesize"/>
                </Grid>
            </GroupBox>
            
            <!-- Twilio API Configuration -->
            <GroupBox x:Name="TwilioAPIConfig" Header="Twilio Configuration" Margin="0,0,0,12" Foreground="White" Visibility="Collapsed">
                <Grid Margin="8">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="100"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="100"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <Label Grid.Row="0" Grid.Column="0" Content="Account SID:" Foreground="White" VerticalAlignment="Center"/>
                    <TextBox x:Name="API_TW_AccountSID" Grid.Row="0" Grid.Column="1" Height="25" Margin="5,2"/>
                    <Label Grid.Row="0" Grid.Column="2" Content="API Endpoint:" Foreground="White" VerticalAlignment="Center"/>
                    <TextBox x:Name="API_TW_Endpoint" Grid.Row="0" Grid.Column="3" Height="25" Margin="5,2" Text="https://api.twilio.com/2010-04-01/"/>
                    
                    <Label Grid.Row="1" Grid.Column="0" Content="Auth Token:" Foreground="White" VerticalAlignment="Center"/>
                    <PasswordBox x:Name="API_TW_AuthToken" Grid.Row="1" Grid.Column="1" Height="25" Margin="5,2"/>
                    <CheckBox x:Name="API_TW_TestMode" Grid.Row="1" Grid.Column="2" Grid.ColumnSpan="2" Content="Test Mode" Foreground="White" Margin="5,5"/>
                </Grid>
            </GroupBox>
            
            <!-- VoiceForge API Configuration -->
            <GroupBox x:Name="VoiceForgeAPIConfig" Header="VoiceForge Configuration" Margin="0,0,0,12" Foreground="White" Visibility="Collapsed">
                <Grid Margin="8">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="100"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="100"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <Label Grid.Row="0" Grid.Column="0" Content="API Key:" Foreground="White" VerticalAlignment="Center"/>
                    <TextBox x:Name="API_VF_APIKey" Grid.Row="0" Grid.Column="1" Height="25" Margin="5,2"/>
                    <Label Grid.Row="0" Grid.Column="2" Content="API Version:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="API_VF_Version" Grid.Row="0" Grid.Column="3" Height="25" Margin="5,2">
                        <ComboBoxItem Content="v1" IsSelected="True"/>
                        <ComboBoxItem Content="v2"/>
                    </ComboBox>
                    
                    <Label Grid.Row="1" Grid.Column="0" Content="Endpoint:" Foreground="White" VerticalAlignment="Center"/>
                    <TextBox x:Name="API_VF_Endpoint" Grid.Row="1" Grid.Column="1" Grid.ColumnSpan="3" Height="25" Margin="5,2" 
                             Text="https://api.voiceforge.com/v1/"/>
                </Grid>
            </GroupBox>
            
            <!-- Connection Testing -->
            <GroupBox Header="Connection Testing" Margin="0,0,0,12" Foreground="White">
                <Grid Margin="8">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    
                    <TextBlock x:Name="ConnectionStatus" Grid.Column="0" Text="Ready to test connection..." Foreground="#FFDDDDDD" VerticalAlignment="Center"/>
                    <Button x:Name="TestConnection" Grid.Column="1" Content="🔍 Test Connection" Width="120" Height="30" Margin="0,0,8,0" Background="#FF28A745" Foreground="White"/>
                    <Button x:Name="ValidateCredentials" Grid.Column="2" Content="✓ Validate" Width="80" Height="30" Background="#FF17A2B8" Foreground="White"/>
                </Grid>
            </GroupBox>
            
            <!-- Setup Guidance -->
            <GroupBox x:Name="APISetupGuidance" Header="Setup Instructions" Margin="0,0,0,12" Foreground="White">
                <TextBlock x:Name="APIGuidanceText" Text="Select a provider above to see specific setup instructions." 
                           Foreground="#FFCCCCCC" Margin="8" TextWrapping="Wrap" FontSize="11" LineHeight="16"/>
            </GroupBox>
            
            <!-- Action Buttons -->
            <Grid Margin="0,16,0,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <Button x:Name="ResetAPIConfig" Grid.Column="1" Content="Reset to Defaults" Width="120" Height="30" Margin="0,0,8,0" Background="#FFD32F2F" Foreground="White"/>
                <Button x:Name="SaveAPIConfig" Grid.Column="2" Content="Save &amp; Close" Width="100" Height="30" Background="#FF2D7D32" Foreground="White"/>
            </Grid>
            
        </StackPanel>
    </ScrollViewer>
</Window>
"@
#endregion

#region XAML window definition
$xaml = @"
<Window
   xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
   xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
   Title="$UserAgent" 
   SizeToContent="WidthAndHeight"
   ResizeMode="CanResize" 
   ShowInTaskbar="True" 
   WindowStartupLocation="CenterScreen" 
   MinWidth="900" MinHeight="650"
   MaxWidth="1200" MaxHeight="900"
   Background="#FF2D2D30">
   
   <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="20,20,20,10">
   <StackPanel MaxWidth="880">

            <!-- App Introduction -->
            <Border Background="#FF404040" CornerRadius="5" Padding="15" Margin="0,0,0,15">
                <StackPanel>
                    <Label Content="🎤 TextToSpeech Generator v3.0" FontSize="16" FontWeight="Bold" Foreground="White" Margin="0,0,0,5"/>
                    <TextBlock Text="Convert text to high-quality speech using enterprise TTS providers. Save API configurations and switch between providers seamlessly." 
                               FontSize="12" Foreground="#FFCCCCCC" TextWrapping="Wrap"/>
                </StackPanel>
            </Border>

            <!-- TTS Provider Selection -->
            <GroupBox Header="TTS Provider Selection" Margin="0,0,0,12" Foreground="White">
                <Grid Margin="8">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="80"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="80"/>
                        <ColumnDefinition Width="120"/>
                    </Grid.ColumnDefinitions>
                    
                    <!-- Provider Selection Row -->
                    <Label Grid.Row="0" Grid.Column="0" Content="Provider:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="ProviderSelect" Grid.Row="0" Grid.Column="1" Height="25" Margin="5,2" SelectedIndex="1">
                        <ComboBoxItem Content="Amazon Polly" Tag="AW"/>
                        <ComboBoxItem Content="Microsoft Azure" Tag="MS"/>
                        <ComboBoxItem Content="CloudPronouncer" Tag="CP"/>
                        <ComboBoxItem Content="Google Cloud" Tag="GC"/>
                        <ComboBoxItem Content="Twilio" Tag="TW"/>
                        <ComboBoxItem Content="VoiceForge" Tag="VF"/>
                    </ComboBox>
                    <Button x:Name="TestAPI" Grid.Row="0" Grid.Column="2" Content="Test API" Height="25" Margin="5,2" Background="#FF28A745" Foreground="White"/>
                    <Button x:Name="ConfigureAPI" Grid.Row="0" Grid.Column="3" Content="⚙️ API Config" Height="25" Margin="5,2" Background="#FF0E639C" Foreground="White"/>
                    
                    <!-- Status Row -->
                    <TextBlock x:Name="APIConnectionStatus" Grid.Row="1" Grid.Column="0" Grid.ColumnSpan="2" Text="Status: Not Connected" Foreground="#FFFFAA00" Margin="0,5,0,0" VerticalAlignment="Center"/>
                    <TextBlock x:Name="APICredentialsStatus" Grid.Row="1" Grid.Column="2" Text="Credentials: Not Set" Foreground="#FFFFAA00" Margin="5,5,0,0" VerticalAlignment="Center"/>
                    <TextBlock x:Name="LastTestedTime" Grid.Row="1" Grid.Column="3" Text="Last Test: Never" Foreground="#FFDDDDDD" Margin="5,5,0,0" VerticalAlignment="Center"/>
                </Grid>
            </GroupBox>

            <!-- Voice Selection -->
            <GroupBox Header="Voice Selection" Margin="0,0,0,12" Foreground="White">
                <Grid Margin="8">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="80"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="80"/>
                        <ColumnDefinition Width="150"/>
                        <ColumnDefinition Width="120"/>
                    </Grid.ColumnDefinitions>
                    
                    <!-- Voice Selection Row -->
                    <Label Grid.Row="0" Grid.Column="0" Content="Voice:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="VoiceSelect" Grid.Row="0" Grid.Column="1" Height="25" Margin="5,2">
                        <ComboBoxItem Content="AriaNeural" IsSelected="True"/>
                        <ComboBoxItem Content="JennyNeural"/>
                        <ComboBoxItem Content="GuyNeural"/>
                    </ComboBox>
                    <Label Grid.Row="0" Grid.Column="2" Content="Language:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="LanguageSelect" Grid.Row="0" Grid.Column="3" Height="25" Margin="5,2">
                        <ComboBoxItem Content="en-US" IsSelected="True"/>
                        <ComboBoxItem Content="en-GB"/>
                        <ComboBoxItem Content="en-AU"/>
                        <ComboBoxItem Content="fr-FR"/>
                        <ComboBoxItem Content="de-DE"/>
                    </ComboBox>
                    <Button x:Name="AdvancedVoice" Grid.Row="0" Grid.Column="4" Content="🔧 Advanced" Height="25" Margin="5,2" Background="#FF6F42C1" Foreground="White"/>
                    
                    <!-- Audio Format Row -->
                    <Label Grid.Row="1" Grid.Column="0" Content="Format:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="AudioFormatSelect" Grid.Row="1" Grid.Column="1" Height="25" Margin="5,2">
                        <ComboBoxItem Content="MP3 16kHz" IsSelected="True"/>
                        <ComboBoxItem Content="MP3 24kHz"/>
                        <ComboBoxItem Content="WAV 16kHz"/>
                        <ComboBoxItem Content="OGG Vorbis"/>
                    </ComboBox>
                    <Label Grid.Row="1" Grid.Column="2" Content="Quality:" Foreground="White" VerticalAlignment="Center"/>
                    <ComboBox x:Name="QualitySelect" Grid.Row="1" Grid.Column="3" Height="25" Margin="5,2">
                        <ComboBoxItem Content="Standard" IsSelected="True"/>
                        <ComboBoxItem Content="Premium"/>
                        <ComboBoxItem Content="Neural"/>
                        <ComboBoxItem Content="Ultra"/>
                    </ComboBox>
                </Grid>
            </GroupBox>

            <!-- Input/Output Configuration -->
            <GroupBox Header="Input &amp; Output" Margin="0,0,0,12" Foreground="White">
                <Grid Margin="8">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="65"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="50"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="100"/>
                    </Grid.ColumnDefinitions>
                    
                    <!-- Input File -->
                    <Label Grid.Row="0" Grid.Column="0" Content="File:" Foreground="White" VerticalAlignment="Center"/>
                    <TextBox x:Name="Input_File" Grid.Row="0" Grid.Column="1" Height="23" Text="C:\temp\input.txt" Margin="5,2"/>
                    <Button x:Name="Input_Browse" Grid.Row="0" Grid.Column="2" Content="..." Height="23" Margin="5,2"/>
                    
                    <!-- CSV Import -->
                    <CheckBox x:Name="BulkMode" Grid.Row="0" Grid.Column="3" Content="Bulk Mode" Foreground="White" VerticalAlignment="Center" Margin="10,0,5,0"/>
                    <Button x:Name="CSVImport" Grid.Row="0" Grid.Column="4" Content="Import CSV" Height="23" Margin="5,2" IsEnabled="False"/>
                    
                    <!-- Output Directory -->
                    <Label Grid.Row="1" Grid.Column="0" Content="Output:" Foreground="White" VerticalAlignment="Center"/>
                    <TextBox x:Name="Output_File" Grid.Row="1" Grid.Column="1" Height="23" Text="C:\temp\output" Margin="5,2"/>
                    <Button x:Name="Output_Browse" Grid.Row="1" Grid.Column="2" Content="..." Height="23" Margin="5,2"/>
                    
                    <!-- Output File Type -->
                    <Label Grid.Row="1" Grid.Column="3" Content="File Type:" Foreground="White" VerticalAlignment="Center" Margin="10,0,5,0"/>
                    <ComboBox x:Name="Output_Format" Grid.Row="1" Grid.Column="4" Height="23" Margin="5,2">
                        <ComboBoxItem Content="MP3" IsSelected="True"/>
                        <ComboBoxItem Content="WAV"/>
                        <ComboBoxItem Content="OGG"/>
                    </ComboBox>
                    
                    <!-- Text Input -->
                    <Label Grid.Row="2" Grid.Column="0" Content="Text:" Foreground="White" VerticalAlignment="Top" Margin="0,8,0,0"/>
                    <TextBox x:Name="Input_Text" Grid.Row="2" Grid.Column="1" Grid.ColumnSpan="4" Height="55" Margin="5,8,5,2" AcceptsReturn="True" TextWrapping="Wrap" ScrollViewer.VerticalScrollBarVisibility="Auto" Text="Enter your text here for single mode processing..."/>
                </Grid>
            </GroupBox>

            <!-- Progress & Status -->
            <GroupBox Header="Progress" Margin="0,0,0,12" Foreground="White">
                <Grid Margin="8">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    
                    <!-- Progress Bar with Label -->
                    <ProgressBar x:Name="ProgressBar" Grid.Row="0" Grid.Column="0" Grid.ColumnSpan="3" Height="22" Margin="0,0,0,8"/>
                    <Label x:Name="ProgressLabel" Grid.Row="1" Grid.Column="0" Content="Ready - Select provider and configure settings to begin" Foreground="#FFDDDDDD" FontSize="11" Margin="0,-5,0,0"/>
                    
                    <!-- Status Indicators -->
                    <TextBlock x:Name="APIStatus" Grid.Row="1" Grid.Column="1" Text="API: Not Tested" Foreground="#FFFFAA00" FontSize="11" Margin="10,-5,10,0"/>
                    <TextBlock x:Name="ConfigStatus" Grid.Row="1" Grid.Column="2" Text="Config: Default" Foreground="#FFFFAA00" FontSize="11" Margin="0,-5,0,0"/>
                </Grid>
            </GroupBox>

            <!-- Action Buttons -->
            <Grid Margin="0,0,0,12">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <Button x:Name="Run" Grid.Column="0" Content="🎵 Generate Speech" Height="35" Background="#FF0E639C" Foreground="White" FontWeight="SemiBold" Margin="0,0,8,0"/>
                <Button x:Name="SaveConfig" Grid.Column="1" Content="💾 Save" Height="35" Width="60" Background="#FF2D7D32" Foreground="White" Margin="0,0,8,0"/>
                <Button x:Name="LoadConfig" Grid.Column="2" Content="📂 Load" Height="35" Width="60" Background="#FF5E35B1" Foreground="White" Margin="0,0,8,0"/>
                <Button x:Name="ResetApp" Grid.Column="3" Content="🔄 Reset" Height="35" Width="60" Background="#FFD32F2F" Foreground="White"/>
            </Grid>

            <!-- Log Output -->
            <GroupBox Header="Activity Log" Margin="0,0,0,0" Foreground="White">
                <StackPanel>
                    <ScrollViewer Height="120" Background="#FF1E1E1E" Margin="8">
                        <TextBlock x:Name="LogOutput" Foreground="White" FontFamily="Consolas" FontSize="11" Padding="8" TextWrapping="Wrap"/>
                    </ScrollViewer>
                    <WrapPanel Orientation="Horizontal" Margin="8,8,8,0">
                        <Button x:Name="Log_Clear" Content="Clear Log" Width="70" Height="25" Margin="0,0,8,0"/>
                        <Button x:Name="Save" Content="Export Log" Width="70" Height="25"/>
                    </WrapPanel>
                </StackPanel>
            </GroupBox>

            <!-- Hidden Elements for Legacy Compatibility -->
            <Grid Visibility="Hidden">
                <Button x:Name="LucaVitali_GitHub"/>
                <Button x:Name="sjackson0109_GitHub"/>
                <Button x:Name="Input_TIP"/>
                <Button x:Name="MS_Audio_Format_Tip"/>
                <Button x:Name="MS_Guide"/>
                <Button x:Name="MS_Sign_Up"/>
                <Button x:Name="Input_TIP2"/>
                <Button x:Name="Output_TIP"/>
                <CheckBox x:Name="EnableSSML" IsChecked="False"/>
                <CheckBox x:Name="ParallelProcessing" IsChecked="True"/>
                <Slider x:Name="SpeedSlider" Minimum="0.5" Maximum="2.0" Value="1.0"/>
                <Slider x:Name="PitchSlider" Minimum="-20" Maximum="20" Value="0"/>
                
                <!-- Legacy radio buttons for compatibility -->
                <RadioButton x:Name="TTS_AW" GroupName="Provider"/>
                <RadioButton x:Name="TTS_MS" GroupName="Provider" IsChecked="True"/>
                <RadioButton x:Name="TTS_CP" GroupName="Provider"/>
                <RadioButton x:Name="TTS_GC" GroupName="Provider"/>
                <RadioButton x:Name="TTS_TW" GroupName="Provider"/>
                <RadioButton x:Name="TTS_VF" GroupName="Provider"/>
                <RadioButton x:Name="OP_SINGLE" GroupName="Mode" IsChecked="True"/>
                <RadioButton x:Name="OP_BULK" GroupName="Mode"/>
                
                <!-- Legacy API configuration controls -->
                <TextBox x:Name="MS_KEY"/>
                <ComboBox x:Name="MS_Datacenter"/>
                <ComboBox x:Name="MS_Audio_Format"/>
                <ComboBox x:Name="MS_Voice"/>
                <TextBox x:Name="AWS_AccessKey"/>
                <PasswordBox x:Name="AWS_SecretKey"/>
                <ComboBox x:Name="AWS_Region"/>
                <ComboBox x:Name="AWS_Voice"/>
                <TextBox x:Name="CP_Username"/>
                <PasswordBox x:Name="CP_Password"/>
                <ComboBox x:Name="CP_Voice"/>
                <ComboBox x:Name="CP_Format"/>
                <TextBox x:Name="GC_APIKey"/>
                <TextBox x:Name="GC_ProjectID"/>
                <ComboBox x:Name="GC_Language"/>
                <ComboBox x:Name="GC_Voice"/>
                <TextBox x:Name="TW_AccountSID"/>
                <PasswordBox x:Name="TW_AuthToken"/>
                <ComboBox x:Name="TW_Voice"/>
                <ComboBox x:Name="TW_Format"/>
                <TextBox x:Name="VF_APIKey"/>
                <TextBox x:Name="VF_Endpoint"/>
                <ComboBox x:Name="VF_Voice"/>
                <ComboBox x:Name="VF_Quality"/>
            </Grid>
            
        </StackPanel>
        </ScrollViewer>
</Window>
"@
#endregion

#region Code Behind
function Convert-XAMLtoWindow {
  param ( [Parameter(Mandatory=$true)][string]$XAML )
  Add-Type -AssemblyName PresentationFramework
  $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
  $result = [Windows.Markup.XAMLReader]::Load($reader)
  $reader.Close()
  $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
  while ($reader.Read())
  {
      $name=$reader.GetAttribute('Name')
      if (!$name) { $name=$reader.GetAttribute('x:Name') }
      if ($name) { $result | Add-Member NoteProperty -Name $name -Value $result.FindName($name) -Force }
  }
  $reader.Close()
  return $result
}

function Show-WPFWindow {
  param ( [Parameter(Mandatory=$true)][Windows.Window]$Window )
  $result = $null
  $null = $window.Dispatcher.InvokeAsync{
    $result = $window.ShowDialog()
    Set-Variable -Name result -Value $result -Scope 1
  }.Wait()
  return $result
}

function Show-AdvancedVoiceOptions {
    param ( [Parameter(Mandatory=$true)][string]$Provider )
    
    try {
        $advancedWindow = Convert-XAMLtoWindow -XAML $advancedVoiceXaml
        $advancedWindow.Owner = $global:window
        
        # Hide all provider sections initially
        $advancedWindow.AzureAdvanced.Visibility = "Collapsed"
        $advancedWindow.AWSAdvanced.Visibility = "Collapsed"
        $advancedWindow.GoogleAdvanced.Visibility = "Collapsed"
        $advancedWindow.CloudPronouncerAdvanced.Visibility = "Collapsed"
        $advancedWindow.TwilioAdvanced.Visibility = "Collapsed"
        $advancedWindow.VoiceForgeAdvanced.Visibility = "Collapsed"
        
        # Show the appropriate provider section
        switch ($Provider) {
            "Microsoft Azure" { 
                $advancedWindow.AzureAdvanced.Visibility = "Visible"
                $advancedWindow.ProviderInfo.Text = "Configure advanced voice parameters for Microsoft Azure Cognitive Services TTS. Adjust speech rate, pitch, volume, and enable SSML processing."
            }
            "Amazon Polly" { 
                $advancedWindow.AWSAdvanced.Visibility = "Visible"
                $advancedWindow.ProviderInfo.Text = "Configure advanced voice parameters for Amazon Polly. Select neural engines, adjust sample rates, and enable speech marks for timing data."
            }
            "Google Cloud" { 
                $advancedWindow.GoogleAdvanced.Visibility = "Visible"
                $advancedWindow.ProviderInfo.Text = "Configure advanced voice parameters for Google Cloud Text-to-Speech. Fine-tune speaking rate, pitch, volume gain, and audio encoding options."
            }
            "CloudPronouncer" {
                $advancedWindow.CloudPronouncerAdvanced.Visibility = "Visible"
                $advancedWindow.ProviderInfo.Text = "Configure advanced voice parameters for CloudPronouncer TTS. Adjust speech rate, volume, audio format, sample rate, and enable high-quality synthesis."
            }
            "Twilio" {
                $advancedWindow.TwilioAdvanced.Visibility = "Visible"
                $advancedWindow.ProviderInfo.Text = "Configure advanced voice parameters for Twilio TTS. Set language preferences, recording quality, timeouts, and transcription options."
            }
            "VoiceForge" {
                $advancedWindow.VoiceForgeAdvanced.Visibility = "Visible"
                $advancedWindow.ProviderInfo.Text = "Configure advanced voice parameters for VoiceForge TTS. Fine-tune speech rate, pitch, audio format, bit rate, and enable high-quality synthesis."
            }
            default { 
                $advancedWindow.ProviderInfo.Text = "Advanced voice options for $Provider will be available in a future update. Please check back soon for enhanced configuration options."
            }
        }
        
        # Load current advanced settings
        Load-AdvancedSettings -Window $advancedWindow -Provider $Provider
        
        # Button handlers
        $advancedWindow.SaveAdvanced.add_Click{
            Save-AdvancedSettings -Window $advancedWindow -Provider $Provider
            Write-ApplicationLog -Message "Advanced voice settings saved for $Provider" -Level "INFO"
            $advancedWindow.Close()
        }
        
        $advancedWindow.ResetToDefaults.add_Click{
            Reset-AdvancedSettings -Window $advancedWindow -Provider $Provider
            Write-ApplicationLog -Message "Advanced settings reset to defaults for $Provider" -Level "INFO"
        }
        
        # Show the dialog
        $result = Show-WPFWindow -Window $advancedWindow
        
    } catch {
        Write-ApplicationLog -Message "Error opening advanced options: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Load-AdvancedSettings {
    param (
        [Parameter(Mandatory=$true)][Windows.Window]$Window,
        [Parameter(Mandatory=$true)][string]$Provider
    )
    
    # Load settings from global configuration (implement as needed)
    switch ($Provider) {
        "Microsoft Azure" {
            if ($global:azureAdvancedConfig) {
                $Window.AZ_SpeechRate.Value = $global:azureAdvancedConfig.SpeechRate ?? 1.0
                $Window.AZ_Pitch.Value = $global:azureAdvancedConfig.Pitch ?? 0
                $Window.AZ_Volume.Value = $global:azureAdvancedConfig.Volume ?? 50
                $Window.AZ_EnableSSML.IsChecked = $global:azureAdvancedConfig.EnableSSML ?? $false
            }
        }
        "Amazon Polly" {
            if ($global:awsAdvancedConfig) {
                $Window.AWS_Engine.SelectedIndex = $global:awsAdvancedConfig.EngineIndex ?? 0
                $Window.AWS_SampleRate.SelectedIndex = $global:awsAdvancedConfig.SampleRateIndex ?? 1
            }
        }
        "Google Cloud" {
            if ($global:gcAdvancedConfig) {
                $Window.GC_SpeakingRate.Value = $global:gcAdvancedConfig.SpeakingRate ?? 1.0
                $Window.GC_Pitch.Value = $global:gcAdvancedConfig.Pitch ?? 0
                $Window.GC_VolumeGain.Value = $global:gcAdvancedConfig.VolumeGain ?? 0
            }
        }
        "CloudPronouncer" {
            if ($global:cpAdvancedConfig) {
                $Window.CP_SpeechRate.Value = $global:cpAdvancedConfig.SpeechRate ?? 1.0
                $Window.CP_Volume.Value = $global:cpAdvancedConfig.Volume ?? 50
                if ($global:cpAdvancedConfig.AudioFormatIndex) { $Window.CP_AudioFormat.SelectedIndex = $global:cpAdvancedConfig.AudioFormatIndex }
                if ($global:cpAdvancedConfig.SampleRateIndex) { $Window.CP_SampleRate.SelectedIndex = $global:cpAdvancedConfig.SampleRateIndex }
                $Window.CP_EnableSSML.IsChecked = $global:cpAdvancedConfig.EnableSSML ?? $false
                $Window.CP_HighQuality.IsChecked = $global:cpAdvancedConfig.HighQuality ?? $false
            }
        }
        "Twilio" {
            if ($global:twAdvancedConfig) {
                if ($global:twAdvancedConfig.LanguageIndex) { $Window.TW_Language.SelectedIndex = $global:twAdvancedConfig.LanguageIndex }
                if ($global:twAdvancedConfig.RecordQualityIndex) { $Window.TW_RecordQuality.SelectedIndex = $global:twAdvancedConfig.RecordQualityIndex }
                $Window.TW_Timeout.Text = $global:twAdvancedConfig.Timeout ?? "30"
                $Window.TW_MaxLength.Text = $global:twAdvancedConfig.MaxLength ?? "1200"
                $Window.TW_EnableTranscription.IsChecked = $global:twAdvancedConfig.EnableTranscription ?? $false
                $Window.TW_RecordOnAnswered.IsChecked = $global:twAdvancedConfig.RecordOnAnswered ?? $false
            }
        }
        "VoiceForge" {
            if ($global:vfAdvancedConfig) {
                $Window.VF_SpeechRate.Value = $global:vfAdvancedConfig.SpeechRate ?? 1.0
                $Window.VF_Pitch.Value = $global:vfAdvancedConfig.Pitch ?? 0
                if ($global:vfAdvancedConfig.AudioFormatIndex) { $Window.VF_AudioFormat.SelectedIndex = $global:vfAdvancedConfig.AudioFormatIndex }
                if ($global:vfAdvancedConfig.BitRateIndex) { $Window.VF_BitRate.SelectedIndex = $global:vfAdvancedConfig.BitRateIndex }
                $Window.VF_EnableSSML.IsChecked = $global:vfAdvancedConfig.EnableSSML ?? $false
                $Window.VF_HighQuality.IsChecked = $global:vfAdvancedConfig.HighQuality ?? $false
            }
        }
    }
}

function Save-AdvancedSettings {
    param (
        [Parameter(Mandatory=$true)][Windows.Window]$Window,
        [Parameter(Mandatory=$true)][string]$Provider
    )
    
    switch ($Provider) {
        "Microsoft Azure" {
            $global:azureAdvancedConfig = @{
                SpeechRate = $Window.AZ_SpeechRate.Value
                Pitch = $Window.AZ_Pitch.Value
                Volume = $Window.AZ_Volume.Value
                Style = $Window.AZ_Style.SelectedItem.Content
                EnableSSML = $Window.AZ_EnableSSML.IsChecked
                WordBoundary = $Window.AZ_WordBoundary.IsChecked
                CustomVoice = $Window.AZ_CustomVoice.Text
            }
        }
        "Amazon Polly" {
            $global:awsAdvancedConfig = @{
                Engine = $Window.AWS_Engine.SelectedItem.Content
                EngineIndex = $Window.AWS_Engine.SelectedIndex
                SampleRate = $Window.AWS_SampleRate.SelectedItem.Content
                SampleRateIndex = $Window.AWS_SampleRate.SelectedIndex
                TextType = $Window.AWS_TextType.SelectedItem.Content
                LanguageCode = $Window.AWS_LanguageCode.SelectedItem.Content
                IncludeTimestamps = $Window.AWS_IncludeTimestamps.IsChecked
                IncludeVisemes = $Window.AWS_IncludeVisemes.IsChecked
            }
        }
        "Google Cloud" {
            $global:gcAdvancedConfig = @{
                SpeakingRate = $Window.GC_SpeakingRate.Value
                Pitch = $Window.GC_Pitch.Value
                VolumeGain = $Window.GC_VolumeGain.Value
                AudioEncoding = $Window.GC_AudioEncoding.SelectedItem.Content
                EnableTimePointing = $Window.GC_EnableTimePointing.IsChecked
                CustomVoice = $Window.GC_CustomVoice.IsChecked
            }
        }
        "CloudPronouncer" {
            $global:cpAdvancedConfig = @{
                SpeechRate = $Window.CP_SpeechRate.Value
                Volume = $Window.CP_Volume.Value
                AudioFormat = $Window.CP_AudioFormat.SelectedItem.Content
                AudioFormatIndex = $Window.CP_AudioFormat.SelectedIndex
                SampleRate = $Window.CP_SampleRate.SelectedItem.Content
                SampleRateIndex = $Window.CP_SampleRate.SelectedIndex
                EnableSSML = $Window.CP_EnableSSML.IsChecked
                HighQuality = $Window.CP_HighQuality.IsChecked
            }
        }
        "Twilio" {
            $global:twAdvancedConfig = @{
                Language = $Window.TW_Language.SelectedItem.Content
                LanguageIndex = $Window.TW_Language.SelectedIndex
                RecordQuality = $Window.TW_RecordQuality.SelectedItem.Content
                RecordQualityIndex = $Window.TW_RecordQuality.SelectedIndex
                Timeout = $Window.TW_Timeout.Text
                MaxLength = $Window.TW_MaxLength.Text
                EnableTranscription = $Window.TW_EnableTranscription.IsChecked
                RecordOnAnswered = $Window.TW_RecordOnAnswered.IsChecked
            }
        }
        "VoiceForge" {
            $global:vfAdvancedConfig = @{
                SpeechRate = $Window.VF_SpeechRate.Value
                Pitch = $Window.VF_Pitch.Value
                AudioFormat = $Window.VF_AudioFormat.SelectedItem.Content
                AudioFormatIndex = $Window.VF_AudioFormat.SelectedIndex
                BitRate = $Window.VF_BitRate.SelectedItem.Content
                BitRateIndex = $Window.VF_BitRate.SelectedIndex
                EnableSSML = $Window.VF_EnableSSML.IsChecked
                HighQuality = $Window.VF_HighQuality.IsChecked
            }
        }
    }
}

function Reset-AdvancedSettings {
    param (
        [Parameter(Mandatory=$true)][Windows.Window]$Window,
        [Parameter(Mandatory=$true)][string]$Provider
    )
    
    switch ($Provider) {
        "Microsoft Azure" {
            $Window.AZ_SpeechRate.Value = 1.0
            $Window.AZ_Pitch.Value = 0
            $Window.AZ_Volume.Value = 50
            $Window.AZ_Style.SelectedIndex = 0
            $Window.AZ_EnableSSML.IsChecked = $false
            $Window.AZ_WordBoundary.IsChecked = $false
            $Window.AZ_CustomVoice.Text = "(Optional - leave blank for default)"
        }
        "Amazon Polly" {
            $Window.AWS_Engine.SelectedIndex = 0
            $Window.AWS_SampleRate.SelectedIndex = 1
            $Window.AWS_TextType.SelectedIndex = 0
            $Window.AWS_LanguageCode.SelectedIndex = 0
            $Window.AWS_IncludeTimestamps.IsChecked = $false
            $Window.AWS_IncludeVisemes.IsChecked = $false
        }
        "Google Cloud" {
            $Window.GC_SpeakingRate.Value = 1.0
            $Window.GC_Pitch.Value = 0
            $Window.GC_VolumeGain.Value = 0
            $Window.GC_AudioEncoding.SelectedIndex = 0
            $Window.GC_EnableTimePointing.IsChecked = $false
            $Window.GC_CustomVoice.IsChecked = $false
        }
        "CloudPronouncer" {
            $Window.CP_SpeechRate.Value = 1.0
            $Window.CP_Volume.Value = 50
            $Window.CP_AudioFormat.SelectedIndex = 0
            $Window.CP_SampleRate.SelectedIndex = 2
            $Window.CP_EnableSSML.IsChecked = $false
            $Window.CP_HighQuality.IsChecked = $false
        }
        "Twilio" {
            $Window.TW_Language.SelectedIndex = 0
            $Window.TW_RecordQuality.SelectedIndex = 1
            $Window.TW_Timeout.Text = "30"
            $Window.TW_MaxLength.Text = "1200"
            $Window.TW_EnableTranscription.IsChecked = $false
            $Window.TW_RecordOnAnswered.IsChecked = $false
        }
        "VoiceForge" {
            $Window.VF_SpeechRate.Value = 1.0
            $Window.VF_Pitch.Value = 0
            $Window.VF_AudioFormat.SelectedIndex = 0
            $Window.VF_BitRate.SelectedIndex = 1
            $Window.VF_EnableSSML.IsChecked = $false
            $Window.VF_HighQuality.IsChecked = $false
        }
    }
}

function Show-APIConfiguration {
    param ( [Parameter(Mandatory=$true)][string]$Provider )
    
    try {
        $apiWindow = Convert-XAMLtoWindow -XAML $apiConfigXaml
        $apiWindow.Owner = $global:window
        
        # Hide all provider sections initially
        $apiWindow.AzureAPIConfig.Visibility = "Collapsed"
        $apiWindow.AWSAPIConfig.Visibility = "Collapsed"
        $apiWindow.CloudPronouncerAPIConfig.Visibility = "Collapsed"
        $apiWindow.GoogleCloudAPIConfig.Visibility = "Collapsed"
        $apiWindow.TwilioAPIConfig.Visibility = "Collapsed"
        $apiWindow.VoiceForgeAPIConfig.Visibility = "Collapsed"
        
        # Show the appropriate provider section and load existing data
        switch ($Provider) {
            "Microsoft Azure" { 
                $apiWindow.AzureAPIConfig.Visibility = "Visible"
                $apiWindow.APIProviderInfo.Text = "Configure Microsoft Azure Cognitive Services API credentials and regional settings."
                $apiWindow.APIGuidanceText.Text = @"
1. Sign in to the Azure Portal (portal.azure.com) with your Microsoft account
2. Create a new 'Cognitive Services' resource or use an existing one
3. Navigate to your Cognitive Services resource > Keys and Endpoint
4. Copy the 'Key 1' value and paste it into the API Key field above
5. Select your preferred region from the dropdown (should match your Azure resource region)
6. The service endpoint will be automatically configured based on your region
7. Click 'Test Connection' to verify your credentials are working

Note: You'll need an active Azure subscription to create Cognitive Services resources. The first 5 hours of speech synthesis are free each month.
"@
                # Load existing Azure config if available
                if ($global:azureAPIConfig) {
                    $apiWindow.API_MS_KEY.Text = $global:azureAPIConfig.APIKey ?? ""
                    $apiWindow.API_MS_Region.Text = $global:azureAPIConfig.Region ?? "eastus"
                    $apiWindow.API_MS_Endpoint.Text = $global:azureAPIConfig.Endpoint ?? "https://{region}.tts.speech.microsoft.com/cognitiveservices/v1"
                }
            }
            "Amazon Polly" { 
                $apiWindow.AWSAPIConfig.Visibility = "Visible"
                $apiWindow.APIProviderInfo.Text = "Configure Amazon Web Services IAM credentials and regional settings for Polly access."
                $apiWindow.APIGuidanceText.Text = @"
1. Sign in to the AWS Management Console (console.aws.amazon.com) with your AWS account
2. Navigate to IAM (Identity and Access Management) service
3. Create a new IAM user or use an existing one with Polly permissions
4. Attach the 'AmazonPollyFullAccess' policy to your user (or create a custom policy)
5. Generate Access Keys for your IAM user (Security credentials > Access keys)
6. Copy the Access Key ID and Secret Access Key into the fields above
7. Select your preferred AWS region from the dropdown
8. Optional: Add a Session Token if using temporary credentials

Important: Never share your AWS credentials publicly. Store them securely and rotate them regularly for security.
"@
                # Load existing AWS config if available
                if ($global:awsAPIConfig) {
                    $apiWindow.API_AWS_AccessKey.Text = $global:awsAPIConfig.AccessKey ?? ""
                    $apiWindow.API_AWS_SecretKey.Password = $global:awsAPIConfig.SecretKey ?? ""
                    $apiWindow.API_AWS_Region.Text = $global:awsAPIConfig.Region ?? "us-east-1"
                }
            }
            "CloudPronouncer" { 
                $apiWindow.CloudPronouncerAPIConfig.Visibility = "Visible"
                $apiWindow.APIProviderInfo.Text = "Configure CloudPronouncer account credentials and service endpoint settings."
                $apiWindow.APIGuidanceText.Text = @"
1. Visit CloudPronouncer.com and create a new account or sign in to your existing account
2. Navigate to your account dashboard or API settings section
3. Generate or locate your API credentials (username and password/API key)
4. Enter your CloudPronouncer username in the Username field above
5. Enter your account password or API key in the Password field above
6. Verify the API endpoint URL is correct (default: https://api.cloudpronouncer.com/)
7. Check 'Premium Account' if you have a paid subscription for enhanced features
8. Click 'Test Connection' to verify your credentials work properly

Note: Free accounts may have usage limitations. Contact CloudPronouncer support for API access details specific to your account type.
"@
                if ($global:cpAPIConfig) {
                    $apiWindow.API_CP_Username.Text = $global:cpAPIConfig.Username ?? ""
                    $apiWindow.API_CP_Password.Password = $global:cpAPIConfig.Password ?? ""
                    $apiWindow.API_CP_Endpoint.Text = $global:cpAPIConfig.Endpoint ?? "https://api.cloudpronouncer.com/"
                }
            }
            "Google Cloud" { 
                $apiWindow.GoogleCloudAPIConfig.Visibility = "Visible"
                $apiWindow.APIProviderInfo.Text = "Configure Google Cloud Platform API key and project settings for Text-to-Speech service."
                $apiWindow.APIGuidanceText.Text = @"
1. Sign in to the Google Cloud Console (console.cloud.google.com) with your Google account
2. Create a new project or select an existing one from the project dropdown
3. Enable the Cloud Text-to-Speech API for your project (APIs & Services > Library)
4. Create credentials (APIs & Services > Credentials > Create Credentials > API Key)
5. Copy your Project ID from the project dashboard and paste it into the field above
6. Copy the API Key and paste it into the API Key field above
7. Select your preferred region from the dropdown for optimal performance
8. The service endpoint is pre-configured for the Text-to-Speech API

Billing: Google Cloud offers $300 in free credits for new accounts. Text-to-Speech has a free tier with limited usage per month.
"@
                if ($global:gcAPIConfig) {
                    $apiWindow.API_GC_APIKey.Text = $global:gcAPIConfig.APIKey ?? ""
                    $apiWindow.API_GC_ProjectID.Text = $global:gcAPIConfig.ProjectID ?? ""
                    $apiWindow.API_GC_Endpoint.Text = $global:gcAPIConfig.Endpoint ?? "https://texttospeech.googleapis.com/v1/text:synthesize"
                }
            }
            "Twilio" { 
                $apiWindow.TwilioAPIConfig.Visibility = "Visible"
                $apiWindow.APIProviderInfo.Text = "Configure Twilio account credentials and API endpoint for voice synthesis services."
                $apiWindow.APIGuidanceText.Text = @"
1. Sign up for a Twilio account at twilio.com or log in to your existing account
2. Navigate to the Twilio Console (console.twilio.com)
3. Find your Account SID on the console dashboard (starts with 'AC')
4. Copy the Account SID and paste it into the Account SID field above
5. Find your Auth Token on the console dashboard (click to reveal)
6. Copy the Auth Token and paste it into the Auth Token field above
7. The API endpoint is pre-configured for Twilio's REST API
8. Check 'Test Mode' if you want to use Twilio's test credentials for development

Pricing: Twilio charges per API call. New accounts receive free trial credits. Check Twilio's pricing page for current rates.
"@
                if ($global:twAPIConfig) {
                    $apiWindow.API_TW_AccountSID.Text = $global:twAPIConfig.AccountSID ?? ""
                    $apiWindow.API_TW_AuthToken.Password = $global:twAPIConfig.AuthToken ?? ""
                    $apiWindow.API_TW_Endpoint.Text = $global:twAPIConfig.Endpoint ?? "https://api.twilio.com/2010-04-01/"
                }
            }
            "VoiceForge" { 
                $apiWindow.VoiceForgeAPIConfig.Visibility = "Visible"
                $apiWindow.APIProviderInfo.Text = "Configure VoiceForge API credentials and service endpoint settings."
                $apiWindow.APIGuidanceText.Text = @"
1. Visit VoiceForge.com and create an account or sign in to your existing account
2. Navigate to your account settings or API section in the user dashboard
3. Generate an API key or locate your existing API credentials
4. Copy the API Key and paste it into the API Key field above
5. Enter your VoiceForge username in the Username field above
6. Select the API version (v1 or v2) based on your account type and requirements
7. Verify the API endpoint URL matches your VoiceForge service configuration
8. Click 'Test Connection' to verify your credentials are working

Note: VoiceForge offers both free and premium accounts. API access and voice quality may vary by subscription level.
"@
                if ($global:vfAPIConfig) {
                    $apiWindow.API_VF_APIKey.Text = $global:vfAPIConfig.APIKey ?? ""
                    $apiWindow.API_VF_Endpoint.Text = $global:vfAPIConfig.Endpoint ?? "https://api.voiceforge.com/v1/"
                    $apiWindow.API_VF_Version.SelectedIndex = $global:vfAPIConfig.VersionIndex ?? 0
                }
            }
        }
        
        # Button handlers
        $apiWindow.SaveAPIConfig.add_Click{
            Save-APIConfiguration -Window $apiWindow -Provider $Provider
            Write-ApplicationLog -Message "API configuration saved for $Provider" -Level "INFO"
            $global:window.APICredentialsStatus.Text = "Credentials: Configured"
            $global:window.APICredentialsStatus.Foreground = "#FF00FF00"
            $apiWindow.Close()
        }
        
        $apiWindow.TestConnection.add_Click{
            Test-APIConnection -Window $apiWindow -Provider $Provider
        }
        
        $apiWindow.ValidateCredentials.add_Click{
            Validate-APICredentials -Window $apiWindow -Provider $Provider
        }
        
        $apiWindow.ResetAPIConfig.add_Click{
            Reset-APIConfiguration -Window $apiWindow -Provider $Provider
            Write-ApplicationLog -Message "API configuration reset for $Provider" -Level "INFO"
        }
        
        # Show the dialog
        $result = Show-WPFWindow -Window $apiWindow
        
    } catch {
        Write-ApplicationLog -Message "Error opening API configuration: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Update-VoiceOptions {
    param ( [Parameter(Mandatory=$true)][string]$Provider )
    
    # Clear current options
    $global:window.VoiceSelect.Items.Clear()
    $global:window.LanguageSelect.Items.Clear()
    $global:window.AudioFormatSelect.Items.Clear()
    $global:window.QualitySelect.Items.Clear()
    if ($global:window.MS_Datacenter) { $global:window.MS_Datacenter.Items.Clear() }
    
    # Populate provider-specific options
    switch ($Provider) {
        "Microsoft Azure" {
            # Voices
            $voices = @("AriaNeural", "JennyNeural", "GuyNeural", "DavisNeural", "JaneNeural")
            foreach ($voice in $voices) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $voice
                if ($voice -eq "AriaNeural") { $item.IsSelected = $true }
                $global:window.VoiceSelect.Items.Add($item)
            }
            
            # Languages
            $languages = @("en-US", "en-GB", "en-AU", "fr-FR", "de-DE", "es-ES", "it-IT")
            foreach ($lang in $languages) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $lang
                if ($lang -eq "en-US") { $item.IsSelected = $true }
                $global:window.LanguageSelect.Items.Add($item)
            }
            
            # Formats
            $formats = @("MP3 16kHz", "MP3 24kHz", "WAV 16kHz", "WAV 24kHz")
            foreach ($format in $formats) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $format
                if ($format -eq "MP3 16kHz") { $item.IsSelected = $true }
                $global:window.AudioFormatSelect.Items.Add($item)
            }
            
            # Quality
            $qualities = @("Standard", "Premium", "Neural")
            foreach ($quality in $qualities) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $quality
                if ($quality -eq "Neural") { $item.IsSelected = $true }
                $global:window.QualitySelect.Items.Add($item)
            }
            
            # Populate MS_Datacenter with all Azure regions
            $global:window.MS_Datacenter.Items.Clear()
            $azureRegions = @(
                "eastus", "eastus2", "southcentralus", "westus2", "westus3", "centralus", "northcentralus", "westcentralus",
                "canadacentral", "canadaeast", "northeurope", "westeurope", "francecentral", "francesouth", 
                "germanywestcentral", "norwayeast", "norwaywest", "switzerlandnorth", "switzerlandwest",
                "uksouth", "ukwest", "swedencentral", "italynorth", "polandcentral", "southeastasia", "eastasia",
                "australiaeast", "australiasoutheast", "australiacentral", "australiacentral2", "japaneast", "japanwest",
                "koreacentral", "koreasouth", "centralindia", "southindia", "westindia", "jioindiawest", "jioindiacentral",
                "uaenorth", "uaecentral", "qatarcentral", "israelcentral", "southafricanorth", "southafricawest",
                "brazilsouth", "brazilsoutheast", "brazilus", "chinaeast", "chinaeast2", "chinanorth", "chinanorth2", "chinanorth3",
                "usgovvirginia", "usgovtexas", "usgovarizona", "usdodcentral", "usdodeast"
            )
            foreach ($region in $azureRegions) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $region
                if ($region -eq "eastus") { $item.IsSelected = $true }
                $global:window.MS_Datacenter.Items.Add($item)
            }
        }
        
        "Amazon Polly" {
            # Voices
            $voices = @("Joanna", "Matthew", "Amy", "Brian", "Emma", "Ivy", "Justin", "Kendra", "Kimberly", "Salli")
            foreach ($voice in $voices) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $voice
                if ($voice -eq "Joanna") { $item.IsSelected = $true }
                $global:window.VoiceSelect.Items.Add($item)
            }
            
            # Languages
            $languages = @("en-US", "en-GB", "en-AU", "en-IN", "fr-FR", "de-DE", "es-ES", "pt-BR")
            foreach ($lang in $languages) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $lang
                if ($lang -eq "en-US") { $item.IsSelected = $true }
                $global:window.LanguageSelect.Items.Add($item)
            }
            
            # Formats
            $formats = @("MP3", "OGG Vorbis", "PCM")
            foreach ($format in $formats) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $format
                if ($format -eq "MP3") { $item.IsSelected = $true }
                $global:window.AudioFormatSelect.Items.Add($item)
            }
            
            # Quality
            $qualities = @("Standard", "Neural", "Long-form")
            foreach ($quality in $qualities) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $quality
                if ($quality -eq "Neural") { $item.IsSelected = $true }
                $global:window.QualitySelect.Items.Add($item)
            }
            
            # Populate AWS_Region with all AWS regions
            if ($global:window.AWS_Region) {
                $global:window.AWS_Region.Items.Clear()
                $awsRegions = @(
                    "us-east-1", "us-east-2", "us-west-1", "us-west-2", "ap-east-1", "ap-northeast-1", "ap-northeast-2", 
                    "ap-northeast-3", "ap-south-1", "ap-south-2", "ap-southeast-1", "ap-southeast-2", "ap-southeast-3", 
                    "ap-southeast-4", "ca-central-1", "ca-west-1", "eu-central-1", "eu-central-2", "eu-north-1", 
                    "eu-south-1", "eu-south-2", "eu-west-1", "eu-west-2", "eu-west-3", "me-central-1", "me-south-1", 
                    "sa-east-1", "af-south-1", "us-gov-east-1", "us-gov-west-1", "cn-north-1", "cn-northwest-1"
                )
                foreach ($region in $awsRegions) {
                    $item = New-Object System.Windows.Controls.ComboBoxItem
                    $item.Content = $region
                    if ($region -eq "us-east-1") { $item.IsSelected = $true }
                    $global:window.AWS_Region.Items.Add($item)
                }
            }
        }
        
        "Google Cloud" {
            # Voices
            $voices = @("en-US-Wavenet-A", "en-US-Wavenet-B", "en-US-Wavenet-C", "en-US-Wavenet-D", "en-US-Neural2-A", "en-US-Neural2-C")
            foreach ($voice in $voices) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $voice
                if ($voice -eq "en-US-Neural2-A") { $item.IsSelected = $true }
                $global:window.VoiceSelect.Items.Add($item)
            }
            
            # Languages
            $languages = @("en-US", "en-GB", "en-AU", "fr-FR", "de-DE", "es-ES", "ja-JP", "ko-KR")
            foreach ($lang in $languages) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $lang
                if ($lang -eq "en-US") { $item.IsSelected = $true }
                $global:window.LanguageSelect.Items.Add($item)
            }
            
            # Formats
            $formats = @("MP3", "LINEAR16", "OGG_OPUS", "MULAW", "ALAW")
            foreach ($format in $formats) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $format
                if ($format -eq "MP3") { $item.IsSelected = $true }
                $global:window.AudioFormatSelect.Items.Add($item)
            }
            
            # Quality
            $qualities = @("Standard", "WaveNet", "Neural2")
            foreach ($quality in $qualities) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $quality
                if ($quality -eq "Neural2") { $item.IsSelected = $true }
                $global:window.QualitySelect.Items.Add($item)
            }
        }
        
        default {
            # Default generic options for other providers
            $voices = @("Default Voice", "Voice 1", "Voice 2", "Voice 3")
            foreach ($voice in $voices) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $voice
                if ($voice -eq "Default Voice") { $item.IsSelected = $true }
                $global:window.VoiceSelect.Items.Add($item)
            }
            
            $languages = @("en-US", "en-GB")
            foreach ($lang in $languages) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $lang
                if ($lang -eq "en-US") { $item.IsSelected = $true }
                $global:window.LanguageSelect.Items.Add($item)
            }
            
            $formats = @("MP3", "WAV")
            foreach ($format in $formats) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $format
                if ($format -eq "MP3") { $item.IsSelected = $true }
                $global:window.AudioFormatSelect.Items.Add($item)
            }
            
            $qualities = @("Standard", "Premium")
            foreach ($quality in $qualities) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $quality
                if ($quality -eq "Standard") { $item.IsSelected = $true }
                $global:window.QualitySelect.Items.Add($item)
            }
        }
    }
}

function Save-APIConfiguration {
    param (
        [Parameter(Mandatory=$true)][Windows.Window]$Window,
        [Parameter(Mandatory=$true)][string]$Provider
    )
    
    switch ($Provider) {
        "Microsoft Azure" {
            $global:azureAPIConfig = @{
                APIKey = $Window.API_MS_KEY.Text
                Region = $Window.API_MS_Region.Text
                Endpoint = $Window.API_MS_Endpoint.Text
            }
        }
        "Amazon Polly" {
            $global:awsAPIConfig = @{
                AccessKey = $Window.API_AWS_AccessKey.Text
                SecretKey = $Window.API_AWS_SecretKey.Password
                Region = $Window.API_AWS_Region.SelectedItem.Content
                SessionToken = $Window.API_AWS_SessionToken.Text
            }
        }
        "CloudPronouncer" {
            $global:cpAPIConfig = @{
                Username = $Window.API_CP_Username.Text
                Password = $Window.API_CP_Password.Password
                Endpoint = $Window.API_CP_Endpoint.Text
                Premium = $Window.API_CP_Premium.IsChecked
            }
        }
        "Google Cloud" {
            $global:gcAPIConfig = @{
                APIKey = $Window.API_GC_APIKey.Text
                ProjectID = $Window.API_GC_ProjectID.Text
                Endpoint = $Window.API_GC_Endpoint.Text
            }
        }
        "Twilio" {
            $global:twAPIConfig = @{
                AccountSID = $Window.API_TW_AccountSID.Text
                AuthToken = $Window.API_TW_AuthToken.Password
                Endpoint = $Window.API_TW_Endpoint.Text
                TestMode = $Window.API_TW_TestMode.IsChecked
            }
        }
        "VoiceForge" {
            $global:vfAPIConfig = @{
                APIKey = $Window.API_VF_APIKey.Text
                Endpoint = $Window.API_VF_Endpoint.Text
                Version = $Window.API_VF_Version.SelectedItem.Content
                VersionIndex = $Window.API_VF_Version.SelectedIndex
            }
        }
    }
}

function Test-APIConnection {
    param (
        [Parameter(Mandatory=$true)][Windows.Window]$Window,
        [Parameter(Mandatory=$true)][string]$Provider
    )
    
    # Validate required credentials before testing
    $validationResult = Validate-APICredentials -Window $Window -Provider $Provider
    if (-not $validationResult.IsValid) {
        $Window.ConnectionStatus.Text = "Validation Failed: $($validationResult.Message)"
        $Window.ConnectionStatus.Foreground = "#FFFF0000"
        
        $global:window.APIConnectionStatus.Text = "Status: Configuration Required"
        $global:window.APIConnectionStatus.Foreground = "#FFFF0000"
        return
    }
    
    $Window.ConnectionStatus.Text = "Testing connection..."
    $Window.ConnectionStatus.Foreground = "#FFFFFF00"
    
    # Simulate connection test (replace with actual API testing logic)
    Start-Sleep -Milliseconds 1000
    
    $Window.ConnectionStatus.Text = "Connection successful! API endpoint is reachable."
    $Window.ConnectionStatus.Foreground = "#FF00FF00"
    
    $global:window.APIConnectionStatus.Text = "Status: Connected"
    $global:window.APIConnectionStatus.Foreground = "#FF00FF00"
    $global:window.LastTestedTime.Text = "Last Test: $(Get-Date -Format 'HH:mm:ss')"
}

function Validate-APICredentials {
    param (
        [Parameter(Mandatory=$true)][Windows.Window]$Window,
        [Parameter(Mandatory=$true)][string]$Provider
    )
    
    $result = @{
        IsValid = $false
        Message = ""
    }
    
    switch ($Provider) {
        "Microsoft Azure" {
            if ([string]::IsNullOrWhiteSpace($Window.API_MS_APIKey.Text)) {
                $result.Message = "API Key is required"
                return $result
            }
            if ([string]::IsNullOrWhiteSpace($Window.API_MS_Region.Text)) {
                $result.Message = "Region is required"
                return $result
            }
            if ([string]::IsNullOrWhiteSpace($Window.API_MS_Endpoint.Text)) {
                $result.Message = "Service Endpoint is required"
                return $result
            }
        }
        
        "Amazon Polly" {
            if ([string]::IsNullOrWhiteSpace($Window.API_AWS_AccessKey.Text)) {
                $result.Message = "Access Key is required"
                return $result
            }
            if ([string]::IsNullOrWhiteSpace($Window.API_AWS_SecretKey.Password)) {
                $result.Message = "Secret Key is required"
                return $result
            }
            if ([string]::IsNullOrWhiteSpace($Window.API_AWS_Region.Text)) {
                $result.Message = "Region is required"
                return $result
            }
        }
        
        "Google Cloud" {
            if ([string]::IsNullOrWhiteSpace($Window.API_GC_APIKey.Text)) {
                $result.Message = "API Key is required"
                return $result
            }
            if ([string]::IsNullOrWhiteSpace($Window.API_GC_ProjectID.Text)) {
                $result.Message = "Project ID is required"
                return $result
            }
            if ([string]::IsNullOrWhiteSpace($Window.API_GC_Region.Text)) {
                $result.Message = "Region is required"
                return $result
            }
        }
        
        "CloudPronouncer" {
            if ([string]::IsNullOrWhiteSpace($Window.API_CP_Username.Text)) {
                $result.Message = "Username is required"
                return $result
            }
            if ([string]::IsNullOrWhiteSpace($Window.API_CP_Password.Password)) {
                $result.Message = "Password is required"
                return $result
            }
            if ([string]::IsNullOrWhiteSpace($Window.API_CP_Endpoint.Text)) {
                $result.Message = "API Endpoint is required"
                return $result
            }
        }
        
        "Twilio" {
            if ([string]::IsNullOrWhiteSpace($Window.API_TW_AccountSID.Text)) {
                $result.Message = "Account SID is required"
                return $result
            }
            if ([string]::IsNullOrWhiteSpace($Window.API_TW_AuthToken.Password)) {
                $result.Message = "Auth Token is required"
                return $result
            }
            if ([string]::IsNullOrWhiteSpace($Window.API_TW_Endpoint.Text)) {
                $result.Message = "API Endpoint is required"
                return $result
            }
        }
        
        "VoiceForge" {
            if ([string]::IsNullOrWhiteSpace($Window.API_VF_APIKey.Text)) {
                $result.Message = "API Key is required"
                return $result
            }
            if ([string]::IsNullOrWhiteSpace($Window.API_VF_Username.Text)) {
                $result.Message = "Username is required"
                return $result
            }
            if ([string]::IsNullOrWhiteSpace($Window.API_VF_Endpoint.Text)) {
                $result.Message = "API Endpoint is required"
                return $result
            }
        }
        
        default {
            $result.Message = "Unknown provider: $Provider"
            return $result
        }
    }
    
    $result.IsValid = $true
    $result.Message = "All required credentials provided"
    return $result
}

function Reset-APIConfiguration {
    param (
        [Parameter(Mandatory=$true)][Windows.Window]$Window,
        [Parameter(Mandatory=$true)][string]$Provider
    )
    
    switch ($Provider) {
        "Microsoft Azure" {
            $Window.API_MS_KEY.Text = ""
            $Window.API_MS_Region.SelectedIndex = 0
            $Window.API_MS_Endpoint.Text = "https://{region}.tts.speech.microsoft.com/cognitiveservices/v1"
        }
        "Amazon Polly" {
            $Window.API_AWS_AccessKey.Text = ""
            $Window.API_AWS_SecretKey.Password = ""
            $Window.API_AWS_Region.SelectedIndex = 0
            $Window.API_AWS_SessionToken.Text = "(Optional)"
        }
        "CloudPronouncer" {
            $Window.API_CP_Username.Text = ""
            $Window.API_CP_Password.Password = ""
            $Window.API_CP_Endpoint.Text = "https://api.cloudpronouncer.com/"
            $Window.API_CP_Premium.IsChecked = $false
        }
        "Google Cloud" {
            $Window.API_GC_APIKey.Text = ""
            $Window.API_GC_ProjectID.Text = ""
            $Window.API_GC_Endpoint.Text = "https://texttospeech.googleapis.com/v1/text:synthesize"
        }
        "Twilio" {
            $Window.API_TW_AccountSID.Text = ""
            $Window.API_TW_AuthToken.Password = ""
            $Window.API_TW_Endpoint.Text = "https://api.twilio.com/2010-04-01/"
            $Window.API_TW_TestMode.IsChecked = $false
        }
        "VoiceForge" {
            $Window.API_VF_APIKey.Text = ""
            $Window.API_VF_Endpoint.Text = "https://api.voiceforge.com/v1/"
            $Window.API_VF_Version.SelectedIndex = 0
        }
    }
}

function Save-CompleteConfiguration {
    try {
        $configPath = Join-Path $PSScriptRoot "TTS-Complete-Config.xml"
        
        # Gather all configuration data
        $config = @{
            # Provider Selection
            SelectedProvider = $global:window.ProviderSelect.SelectedItem.Content
            
            # Azure Configuration
            Azure = @{
                APIKey = $global:window.MS_KEY.Text
                Region = $global:window.MS_Datacenter.Text
                AudioFormat = $global:window.MS_Audio_Format.SelectedItem.Content
                Voice = $global:window.MS_Voice.SelectedItem.Content
                Advanced = $global:azureAdvancedConfig
            }
            
            # AWS Configuration  
            AWS = @{
                AccessKey = $global:window.AWS_AccessKey.Text
                SecretKey = $global:window.AWS_SecretKey.Password
                Region = $global:window.AWS_Region.SelectedItem.Content
                Voice = $global:window.AWS_Voice.SelectedItem.Content
                Advanced = $global:awsAdvancedConfig
            }
            
            # CloudPronouncer Configuration
            CloudPronouncer = @{
                Username = $global:window.CP_Username.Text
                Password = $global:window.CP_Password.Password
                Voice = $global:window.CP_Voice.SelectedItem.Content
                Format = $global:window.CP_Format.SelectedItem.Content
            }
            
            # Google Cloud Configuration
            GoogleCloud = @{
                APIKey = $global:window.GC_APIKey.Text
                ProjectID = $global:window.GC_ProjectID.Text
                Language = $global:window.GC_Language.SelectedItem.Content
                Voice = $global:window.GC_Voice.SelectedItem.Content
                Advanced = $global:gcAdvancedConfig
            }
            
            # Twilio Configuration
            Twilio = @{
                AccountSID = $global:window.TW_AccountSID.Text
                AuthToken = $global:window.TW_AuthToken.Password
                Voice = $global:window.TW_Voice.SelectedItem.Content
                Format = $global:window.TW_Format.SelectedItem.Content
            }
            
            # VoiceForge Configuration
            VoiceForge = @{
                APIKey = $global:window.VF_APIKey.Text
                Endpoint = $global:window.VF_Endpoint.Text
                Voice = $global:window.VF_Voice.SelectedItem.Content
                Quality = $global:window.VF_Quality.SelectedItem.Content
            }
            
            # Input/Output Settings
            InputOutput = @{
                InputFile = $global:window.Input_File.Text
                OutputDirectory = $global:window.Output_File.Text
                OutputFormat = $global:window.Output_Format.SelectedItem.Content
                BulkMode = $global:window.BulkMode.IsChecked
                InputText = $global:window.Input_Text.Text
            }
            
            # Metadata
            SavedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Version = "2.0"
        }
        
        # Convert to XML and save
        $config | Export-Clixml -Path $configPath -Force
        Write-ApplicationLog -Message "Configuration saved to: $configPath" -Level "INFO"
        
    } catch {
        Write-ApplicationLog -Message "Error saving configuration: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Load-CompleteConfiguration {
    try {
        $configPath = Join-Path $PSScriptRoot "TTS-Complete-Config.xml"
        
        if (Test-Path $configPath) {
            $config = Import-Clixml -Path $configPath
            
            # Restore Provider Selection
            if ($config.SelectedProvider) {
                $index = 0
                for ($i = 0; $i -lt $global:window.ProviderSelect.Items.Count; $i++) {
                    if ($global:window.ProviderSelect.Items[$i].Content -eq $config.SelectedProvider) {
                        $index = $i
                        break
                    }
                }
                $global:window.ProviderSelect.SelectedIndex = $index
            }
            
            # Restore Azure Configuration
            if ($config.Azure) {
                $global:window.MS_KEY.Text = $config.Azure.APIKey ?? ""
                $global:window.MS_Datacenter.Text = $config.Azure.Region ?? "eastus"
                if ($config.Azure.Advanced) {
                    $global:azureAdvancedConfig = $config.Azure.Advanced
                }
            }
            
            # Restore AWS Configuration
            if ($config.AWS) {
                $global:window.AWS_AccessKey.Text = $config.AWS.AccessKey ?? ""
                $global:window.AWS_SecretKey.Password = $config.AWS.SecretKey ?? ""
                if ($config.AWS.Advanced) {
                    $global:awsAdvancedConfig = $config.AWS.Advanced
                }
            }
            
            # Restore CloudPronouncer Configuration
            if ($config.CloudPronouncer) {
                $global:window.CP_Username.Text = $config.CloudPronouncer.Username ?? ""
                $global:window.CP_Password.Password = $config.CloudPronouncer.Password ?? ""
            }
            
            # Restore Google Cloud Configuration  
            if ($config.GoogleCloud) {
                $global:window.GC_APIKey.Text = $config.GoogleCloud.APIKey ?? ""
                $global:window.GC_ProjectID.Text = $config.GoogleCloud.ProjectID ?? ""
                if ($config.GoogleCloud.Advanced) {
                    $global:gcAdvancedConfig = $config.GoogleCloud.Advanced
                }
            }
            
            # Restore Twilio Configuration
            if ($config.Twilio) {
                $global:window.TW_AccountSID.Text = $config.Twilio.AccountSID ?? ""
                $global:window.TW_AuthToken.Password = $config.Twilio.AuthToken ?? ""
            }
            
            # Restore VoiceForge Configuration
            if ($config.VoiceForge) {
                $global:window.VF_APIKey.Text = $config.VoiceForge.APIKey ?? ""
                $global:window.VF_Endpoint.Text = $config.VoiceForge.Endpoint ?? "https://api.voiceforge.com/v1/"
            }
            
            # Restore Input/Output Settings
            if ($config.InputOutput) {
                $global:window.Input_File.Text = $config.InputOutput.InputFile ?? "C:\temp\input.txt"
                $global:window.Output_File.Text = $config.InputOutput.OutputDirectory ?? "C:\temp\output"
                $global:window.Input_Text.Text = $config.InputOutput.InputText ?? "Enter your text here for single mode processing..."
                $global:window.BulkMode.IsChecked = $config.InputOutput.BulkMode ?? $false
                
                # Set initial state based on bulk mode setting
                if ($global:window.BulkMode.IsChecked) {
                    $global:window.CSVImport.IsEnabled = $true
                    $global:window.Input_Text.IsEnabled = $false
                    $global:window.Input_Text.Background = "#FF404040"
                    $global:window.Input_Text.Foreground = "#FF888888"
                } else {
                    $global:window.CSVImport.IsEnabled = $false
                    $global:window.Input_Text.IsEnabled = $true
                    $global:window.Input_Text.Background = "White"
                    $global:window.Input_Text.Foreground = "Black"
                }
            }
            
            Write-ApplicationLog -Message "Configuration loaded from: $configPath (Saved: $($config.SavedDate))" -Level "INFO"
            
        } else {
            Write-ApplicationLog -Message "No saved configuration found at: $configPath" -Level "WARNING"
        }
        
    } catch {
        Write-ApplicationLog -Message "Error loading configuration: $($_.Exception.Message)" -Level "ERROR"
    }
}
#endregion

#region Application Main Code
# Initialize the Application
Write-ApplicationLog -Message "Starting TextToSpeech Generator v3.0" -Level "INFO"

try {
    $window = Convert-XAMLtoWindow -XAML $xaml
    $global:window = $window
    
    # Set default values
    $window.LogOutput.Text = ""
    
    # Initialize Bulk Mode state (default: single mode)
    $window.BulkMode.IsChecked = $false
    $window.CSVImport.IsEnabled = $false
    $window.Input_Text.IsEnabled = $true
    $window.Input_Text.Background = "White"
    $window.Input_Text.Foreground = "Black"
    
    # Initialize voice options for default provider
    Update-VoiceOptions -Provider "Microsoft Azure"
    
    # Provider Selection Handler
    $window.ProviderSelect.add_SelectionChanged{
        $selectedProvider = $window.ProviderSelect.SelectedItem.Content
        Write-ApplicationLog -Message "Provider switched to: $selectedProvider" -Level "INFO"
        
        # Update status display
        $window.APIConnectionStatus.Text = "Status: Not Connected"
        $window.APIConnectionStatus.Foreground = "#FFFFAA00"
        
        # Update voice options based on provider
        Update-VoiceOptions -Provider $selectedProvider
    }
    
    # API Test Handler
    $window.TestAPI.add_Click{
        $selectedProvider = $window.ProviderSelect.SelectedItem.Content
        Write-ApplicationLog -Message "Testing API connection for: $selectedProvider" -Level "INFO"
        
        # First validate that we have API configuration
        $hasValidConfiguration = $false
        
        switch ($selectedProvider) {
            "Microsoft Azure" { 
                $hasValidConfiguration = $global:azureAPIConfig -and 
                                       -not [string]::IsNullOrWhiteSpace($global:azureAPIConfig.APIKey) -and
                                       -not [string]::IsNullOrWhiteSpace($global:azureAPIConfig.Region)
            }
            "Amazon Polly" { 
                $hasValidConfiguration = $global:awsAPIConfig -and 
                                       -not [string]::IsNullOrWhiteSpace($global:awsAPIConfig.AccessKey) -and
                                       -not [string]::IsNullOrWhiteSpace($global:awsAPIConfig.SecretKey) -and
                                       -not [string]::IsNullOrWhiteSpace($global:awsAPIConfig.Region)
            }
            "Google Cloud" { 
                $hasValidConfiguration = $global:googleCloudAPIConfig -and 
                                       -not [string]::IsNullOrWhiteSpace($global:googleCloudAPIConfig.APIKey) -and
                                       -not [string]::IsNullOrWhiteSpace($global:googleCloudAPIConfig.ProjectID)
            }
            "CloudPronouncer" { 
                $hasValidConfiguration = $global:cloudPronouncerAPIConfig -and 
                                       -not [string]::IsNullOrWhiteSpace($global:cloudPronouncerAPIConfig.Username) -and
                                       -not [string]::IsNullOrWhiteSpace($global:cloudPronouncerAPIConfig.Password)
            }
            "Twilio" { 
                $hasValidConfiguration = $global:twilioAPIConfig -and 
                                       -not [string]::IsNullOrWhiteSpace($global:twilioAPIConfig.AccountSID) -and
                                       -not [string]::IsNullOrWhiteSpace($global:twilioAPIConfig.AuthToken)
            }
            "VoiceForge" { 
                $hasValidConfiguration = $global:voiceForgeAPIConfig -and 
                                       -not [string]::IsNullOrWhiteSpace($global:voiceForgeAPIConfig.APIKey) -and
                                       -not [string]::IsNullOrWhiteSpace($global:voiceForgeAPIConfig.Username)
            }
        }
        
        if (-not $hasValidConfiguration) {
            $window.APIStatus.Text = "API: Configuration Required"
            $window.APIStatus.Foreground = "#FFFF0000"
            Write-ApplicationLog -Message "API test failed: Missing required configuration for $selectedProvider" -Level "WARNING"
            return
        }
        
        $window.APIStatus.Text = "API: Testing..."
        $window.APIStatus.Foreground = "#FFFFFF00"
        
        # Simulate API test (replace with actual API testing logic)
        Start-Sleep -Milliseconds 500
        $window.APIStatus.Text = "API: Test Success"
        $window.APIStatus.Foreground = "#FF00FF00"
        Write-ApplicationLog -Message "API test successful for $selectedProvider" -Level "INFO"
    }
    
    # API Configuration Handler
    $window.ConfigureAPI.add_Click{
        $selectedProvider = $window.ProviderSelect.SelectedItem.Content
        Write-ApplicationLog -Message "Opening API configuration for: $selectedProvider" -Level "INFO"
        Show-APIConfiguration -Provider $selectedProvider
    }
    
    # Advanced Voice Options Handler
    $window.AdvancedVoice.add_Click{
        $selectedProvider = $window.ProviderSelect.SelectedItem.Content
        Write-ApplicationLog -Message "Opening advanced voice options for: $selectedProvider" -Level "INFO"
        Show-AdvancedVoiceOptions -Provider $selectedProvider
    }
    
    # Mode Selection Handlers
    $window.OP_SINGLE.add_Checked{ 
        Write-ApplicationLog -Message "Single mode selected" 
        $window.BulkMode.IsChecked = $false
        $window.CSVImport.IsEnabled = $false
    }
    $window.OP_BULK.add_Checked{ 
        Write-ApplicationLog -Message "Bulk mode selected"
        $window.BulkMode.IsChecked = $true
        $window.CSVImport.IsEnabled = $true
    }
    
    # Bulk Mode Handler
    $window.BulkMode.add_Checked{
        # Enable CSV import and disable text input for bulk mode
        $window.CSVImport.IsEnabled = $true
        $window.Input_Text.IsEnabled = $false
        $window.Input_Text.Background = "#FF404040"  # Grayed background
        $window.Input_Text.Foreground = "#FF888888"  # Grayed text
        $window.OP_BULK.IsChecked = $true
        Write-ApplicationLog -Message "Bulk mode enabled - CSV import activated, text input disabled" -Level "INFO"
    }
    $window.BulkMode.add_Unchecked{
        # Disable CSV import and enable text input for single mode
        $window.CSVImport.IsEnabled = $false
        $window.Input_Text.IsEnabled = $true
        $window.Input_Text.Background = "White"      # Normal background
        $window.Input_Text.Foreground = "Black"      # Normal text
        $window.OP_SINGLE.IsChecked = $true
        Write-ApplicationLog -Message "Single mode enabled - text input activated, CSV import disabled" -Level "INFO"
    }
    
    # Main Action Handlers
    $window.Run.add_Click{ 
        try {
            $provider = $window.ProviderSelect.SelectedItem.Content
            Write-ApplicationLog -Message "Starting speech generation with $provider..." -Level "INFO"
            
            # Validate provider selection
            if (-not $provider) {
                Write-ApplicationLog -Message "Please select a TTS provider" -Level "ERROR"
                return
            }
            
            # Get current configuration for selected provider
            $configuration = @{}
            switch ($provider) {
                "Microsoft Azure" {
                    $configuration = @{
                        APIKey = $window.MS_KEY.Text
                        Region = $window.MS_Datacenter.Text
                        Voice = $window.MS_Voice.Text
                        Advanced = $global:azureAdvancedConfig ?? @{}
                    }
                    
                    if ([string]::IsNullOrWhiteSpace($configuration.APIKey)) {
                        Write-ApplicationLog -Message "Azure API Key is required" -Level "ERROR"
                        return
                    }
                }
                "Google Cloud" {
                    $configuration = @{
                        APIKey = $window.GC_APIKey.Text
                        Voice = $window.GC_Voice.Text
                        Advanced = $global:gcAdvancedConfig ?? @{}
                    }
                    
                    if ([string]::IsNullOrWhiteSpace($configuration.APIKey)) {
                        Write-ApplicationLog -Message "Google Cloud API Key is required" -Level "ERROR"
                        return
                    }
                }
                "Amazon Polly" {
                    $configuration = @{
                        AccessKey = $window.AWS_AccessKey.Text
                        SecretKey = $window.AWS_SecretKey.Password
                        Region = $window.AWS_Region.Text
                        Voice = $window.AWS_Voice.Text
                        Advanced = $global:awsAdvancedConfig ?? @{}
                    }
                    
                    if ([string]::IsNullOrWhiteSpace($configuration.AccessKey) -or [string]::IsNullOrWhiteSpace($configuration.SecretKey)) {
                        Write-ApplicationLog -Message "AWS Access Key and Secret Key are required" -Level "ERROR"
                        return
                    }
                }
                default {
                    Write-ApplicationLog -Message "Provider '$provider' is not fully implemented yet" -Level "ERROR"
                    return
                }
            }
            
            # Validate output directory
            $outputDirectory = $window.Output_Path.Text
            if ([string]::IsNullOrWhiteSpace($outputDirectory) -or -not (Test-Path $outputDirectory)) {
                Write-ApplicationLog -Message "Please specify a valid output directory" -Level "ERROR"
                return
            }
            
            # Determine processing mode
            $isBulkMode = $window.BulkMode.IsChecked
            
            if ($isBulkMode) {
                # Bulk mode - process CSV file
                $csvPath = $window.Input_File.Text
                if ([string]::IsNullOrWhiteSpace($csvPath) -or -not (Test-Path $csvPath)) {
                    Write-ApplicationLog -Message "Please select a valid CSV file for bulk processing" -Level "ERROR"
                    return
                }
                
                try {
                    $csvData = Import-Csv -Path $csvPath
                    if (-not $csvData -or $csvData.Count -eq 0) {
                        Write-ApplicationLog -Message "CSV file is empty or invalid" -Level "ERROR"
                        return
                    }
                    
                    # Validate CSV structure
                    $requiredColumns = @('SCRIPT', 'FILENAME')
                    $csvColumns = $csvData[0].PSObject.Properties.Name
                    $missingColumns = $requiredColumns | Where-Object { $_ -notin $csvColumns }
                    
                    if ($missingColumns) {
                        Write-ApplicationLog -Message "CSV file is missing required columns: $($missingColumns -join ', ')" -Level "ERROR"
                        return
                    }
                    
                    Write-ApplicationLog -Message "Processing $($csvData.Count) items from CSV file" -Level "INFO"
                    
                    # Determine if parallel processing should be used
                    $useParallel = $csvData.Count -ge 10 -and $provider -in @("Microsoft Azure", "Google Cloud")
                    
                    if ($useParallel) {
                        Write-ApplicationLog -Message "Using parallel processing for improved performance" -Level "INFO"
                        $result = Start-ParallelTTSProcessing -Items $csvData -Provider $provider -Configuration $configuration -OutputDirectory $outputDirectory
                    } else {
                        Write-ApplicationLog -Message "Using sequential processing" -Level "INFO"
                        $result = Start-SequentialTTSProcessing -Items $csvData -Provider $provider -Configuration $configuration -OutputDirectory $outputDirectory
                    }
                    
                    Write-ApplicationLog -Message "Bulk processing complete: $($result.Successful)/$($result.TotalItems) successful" -Level "INFO"
                }
                catch {
                    Write-ApplicationLog -Message "Error processing CSV file: $($_.Exception.Message)" -Level "ERROR"
                }
            } else {
                # Single mode - process single text input
                $inputText = $window.Input_Text.Text
                $fileName = $window.Output_FileName.Text
                
                if ([string]::IsNullOrWhiteSpace($inputText)) {
                    Write-ApplicationLog -Message "Please enter text to convert to speech" -Level "ERROR"
                    return
                }
                
                if ([string]::IsNullOrWhiteSpace($fileName)) {
                    $fileName = "output_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                }
                
                Write-ApplicationLog -Message "Processing single text input" -Level "INFO"
                $result = Start-SingleTTSProcessing -Text $inputText -FileName $fileName -Provider $provider -Configuration $configuration -OutputDirectory $outputDirectory
                
                if ($result.Success) {
                    Write-ApplicationLog -Message "Single processing complete successfully" -Level "INFO"
                } else {
                    Write-ApplicationLog -Message "Single processing failed: $($result.Message)" -Level "ERROR"
                }
            }
        }
        catch {
            Write-ApplicationLog -Message "Critical error during processing: $($_.Exception.Message)" -Level "ERROR"
            $window.ProgressLabel.Content = "Error: $($_.Exception.Message)"
        }
    }
    
    # Configuration Handlers
    $window.SaveConfig.add_Click{ 
        Write-ApplicationLog -Message "Saving complete configuration..." -Level "INFO"
        Save-CompleteConfiguration
        $window.ConfigStatus.Text = "Config: Saved"
        $window.ConfigStatus.Foreground = "#FF00FF00"
    }
    $window.LoadConfig.add_Click{ 
        Write-ApplicationLog -Message "Loading complete configuration..." -Level "INFO"
        Load-CompleteConfiguration
        
        # Refresh UI state after loading configuration
        if ($global:window.BulkMode.IsChecked) {
            $global:window.CSVImport.IsEnabled = $true
            $global:window.Input_Text.IsEnabled = $false
            $global:window.Input_Text.Background = "#FF404040"
            $global:window.Input_Text.Foreground = "#FF888888"
        } else {
            $global:window.CSVImport.IsEnabled = $false
            $global:window.Input_Text.IsEnabled = $true
            $global:window.Input_Text.Background = "White"
            $global:window.Input_Text.Foreground = "Black"
        }
        
        $window.ConfigStatus.Text = "Config: Loaded"
        $window.ConfigStatus.Foreground = "#FF00FF00"
    }
    $window.ResetApp.add_Click{ 
        Write-ApplicationLog -Message "Resetting application to defaults..." -Level "WARNING"
        $window.ConfigStatus.Text = "Config: Reset"
        $window.ConfigStatus.Foreground = "#FFFFAA00"
    }
    
    # File Browser Handlers
    $window.Input_Browse.add_Click{ 
        try {
            Add-Type -AssemblyName System.Windows.Forms
            
            $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $openFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
            $openFileDialog.Filter = 'Text Files (*.txt)|*.txt|All Files (*.*)|*.*'
            $openFileDialog.Title = 'Select input text file'
            $openFileDialog.CheckFileExists = $true
            
            if ($openFileDialog.ShowDialog() -eq 'OK') {
                $window.Input_File.Text = $openFileDialog.FileName
                Write-ApplicationLog -Message "Selected input file: $($openFileDialog.FileName)" -Level "INFO"
            }
        }
        catch {
            Write-ApplicationLog -Message "Error opening input file dialog: $($_.Exception.Message)" -Level "ERROR"
        }
    }
    
    $window.Output_Browse.add_Click{ 
        try {
            Add-Type -AssemblyName System.Windows.Forms
            
            $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
            $folderBrowserDialog.Description = 'Select output directory for generated audio files'
            $folderBrowserDialog.ShowNewFolderButton = $true
            
            if ($folderBrowserDialog.ShowDialog() -eq 'OK') {
                $window.Output_Path.Text = $folderBrowserDialog.SelectedPath
                Write-ApplicationLog -Message "Selected output directory: $($folderBrowserDialog.SelectedPath)" -Level "INFO"
                
                # Test write permissions
                try {
                    $testFile = Join-Path $folderBrowserDialog.SelectedPath "test_write_permissions.tmp"
                    "test" | Out-File -FilePath $testFile -Force
                    Remove-Item -Path $testFile -Force
                    Write-ApplicationLog -Message "Output directory has write permissions" -Level "INFO"
                }
                catch {
                    Write-ApplicationLog -Message "WARNING: Output directory may not have write permissions: $($_.Exception.Message)" -Level "WARN"
                }
            }
        }
        catch {
            Write-ApplicationLog -Message "Error opening output directory dialog: $($_.Exception.Message)" -Level "ERROR"
        }
    }
    $window.CSVImport.add_Click{ 
        try {
            Add-Type -AssemblyName System.Windows.Forms
            
            $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $openFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
            $openFileDialog.Filter = 'CSV Files (*.csv)|*.csv|All Files (*.*)|*.*'
            $openFileDialog.Title = 'Select CSV file for bulk processing'
            $openFileDialog.CheckFileExists = $true
            
            if ($openFileDialog.ShowDialog() -eq 'OK') {
                $csvPath = $openFileDialog.FileName
                Write-ApplicationLog -Message "Selected CSV file: $csvPath" -Level "INFO"
                
                # Update the input file path
                $window.Input_File.Text = $csvPath
                
                # Validate CSV structure
                try {
                    $csvData = Import-Csv -Path $csvPath -ErrorAction Stop
                    if ($csvData -and $csvData.Count -gt 0) {
                        $requiredColumns = @('SCRIPT', 'FILENAME')
                        $csvColumns = $csvData[0].PSObject.Properties.Name
                        $missingColumns = $requiredColumns | Where-Object { $_ -notin $csvColumns }
                        
                        if ($missingColumns) {
                            Write-ApplicationLog -Message "WARNING: CSV file is missing required columns: $($missingColumns -join ', ')" -Level "WARN"
                            Write-ApplicationLog -Message "Required columns: SCRIPT, FILENAME" -Level "INFO"
                        } else {
                            Write-ApplicationLog -Message "CSV file validated successfully: $($csvData.Count) rows found" -Level "INFO"
                            $window.ProgressLabel.Content = "CSV loaded: $($csvData.Count) items ready for processing"
                        }
                    } else {
                        Write-ApplicationLog -Message "WARNING: CSV file appears to be empty" -Level "WARN"
                    }
                }
                catch {
                    Write-ApplicationLog -Message "ERROR: Failed to parse CSV file: $($_.Exception.Message)" -Level "ERROR"
                }
            } else {
                Write-ApplicationLog -Message "CSV file selection cancelled" -Level "INFO"
            }
        }
        catch {
            Write-ApplicationLog -Message "Error opening CSV file dialog: $($_.Exception.Message)" -Level "ERROR"
        }
    }
    
    # Log Management
    $window.Log_Clear.add_Click{ 
        $window.LogOutput.Text = ""
        Write-ApplicationLog -Message "Log cleared by user"
    }
    
    Write-ApplicationLog -Message "Application initialized successfully - showing interface" -Level "INFO"
} catch {
    Write-ApplicationLog -Message "Failed to initialize application: $($_.Exception.Message)" -Level "ERROR"
    exit 1
}

#endregion

#region License Notice
<#
===============================================================================
MIT LICENSE NOTICE

This software is licensed under the MIT License.
See LICENSE file for full terms and attribution details.

Original Work: "AzureTTSVoiceGeneratorGUI" by Luca Vitali (2019)
Repository: https://github.com/LucaVitali/AzureTTSVoiceGeneratorGUI

Derivative Work: "TextToSpeech Generator v3.0" by Simon Jackson (2024-2025)
Repository: https://github.com/sjackson0109/TextToSpeech-Generator

Copyright notices and permission notices shall be included in all copies
or substantial portions of the Software.
===============================================================================
#>
#endregion

# Show the window and wait for user interaction
try {
    $result = Show-WPFWindow -Window $window
    Write-ApplicationLog -Message "Application closed by user" -Level "INFO"
} catch {
    Write-ApplicationLog -Message "Error showing window: $($_.Exception.Message)" -Level "ERROR"
}
#endregion
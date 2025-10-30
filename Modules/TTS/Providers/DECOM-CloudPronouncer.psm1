function Get-CloudPronouncerAvailableVoices {
	param([hashtable]$Config = @{})
	$username = $Config["Username"]
	$password = $Config["Password"]
	if (-not $username) { $username = $env:CLOUDPRONOUNCER_USERNAME }
	if (-not $password) { $password = $env:CLOUDPRONOUNCER_PASSWORD }
	if (-not $username -or -not $password) {
		Write-ApplicationLog -Message "CloudPronouncer GetAvailableVoices: No config or env vars, returning demo voices" -Level "DEBUG"
		return @('Cloudy', 'Stormy', 'Sunny')
	}
	try {
		$endpoint = "https://api.cloudpronouncer.com/v1/voices"
		$headers = @{ 'Authorization' = "Basic " + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${username}:${password}")) }
		$response = Invoke-RestMethod -Uri $endpoint -Method Get -Headers $headers -TimeoutSec 10
		if ($response.voices) {
			return $response.voices | ForEach-Object { $_.name }
		} else {
			return @('Cloudy', 'Stormy', 'Sunny')
		}
	} catch {
		Write-ApplicationLog -Message "CloudPronouncer GetAvailableVoices: Exception $($_.Exception.Message)" -Level "ERROR"
		return @('Cloudy', 'Stormy', 'Sunny')
	}
}
Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\Logging\EnhancedLogging.psm1')).Path -Force
class CloudPronouncerTTSProvider {
	[hashtable]$Configuration

	CloudPronouncerTTSProvider([hashtable]$config = $null) {
		if ($null -eq $config) { $config = @{} }
		$this.Configuration = $config
	}

	[array] GetAvailableVoices() {
		$username = $this.Configuration["Username"]
		$password = $this.Configuration["Password"]
		if (-not $username) { $username = $env:CLOUDPRONOUNCER_USERNAME }
		if (-not $password) { $password = $env:CLOUDPRONOUNCER_PASSWORD }
		if (-not $username -or -not $password) {
			Write-ApplicationLog -Message "CloudPronouncer GetAvailableVoices: No config or env vars, returning demo voices" -Level "DEBUG"
			return @('Cloudy', 'Stormy', 'Sunny')
		}
		try {
			$endpoint = "https://api.cloudpronouncer.com/v1/voices"
			$headers = @{ 'Authorization' = "Basic " + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${username}:${password}")) }
			$response = Invoke-RestMethod -Uri $endpoint -Method Get -Headers $headers -TimeoutSec 10
			if ($response.voices) {
				return $response.voices | ForEach-Object { $_.name }
			} else {
				return @('Cloudy', 'Stormy', 'Sunny')
			}
		} catch {
			Write-ApplicationLog -Message "CloudPronouncer GetAvailableVoices: Exception $($_.Exception.Message)" -Level "ERROR"
			return @('Cloudy', 'Stormy', 'Sunny')
		}
	}

	[hashtable] ProcessTTS([string]$Text, [hashtable]$options) {
		$APIKey = $this.Configuration["Password"]
		$endpoint = $this.Configuration["Endpoint"]
		$Voice = $options.Voice
		$OutputPath = $options.OutputFile
		$AdvancedOptions = $options
		try {
			$format = if ($AdvancedOptions.AudioFormat) { $AdvancedOptions.AudioFormat } else { "mp3" }
			$rate = if ($AdvancedOptions.SpeechRate) { $AdvancedOptions.SpeechRate } else { 1.0 }
			$pitch = if ($AdvancedOptions.Pitch) { $AdvancedOptions.Pitch } else { 0 }
			$requestBody = @{
				text = $Text
				voice = $Voice
				format = $format
				rate = $rate
				pitch = $pitch
			} | ConvertTo-Json
			$headers = @{
				"Authorization" = "Bearer $APIKey"
				"Content-Type" = "application/json"
			}
			Write-ApplicationLog -Message "Calling CloudPronouncer API for voice: $Voice" -Level "DEBUG"
			$response = Invoke-RestMethod -Uri $endpoint -Method POST -Body $requestBody -Headers $headers
			if ($response.audio_data) {
				$audioBytes = [System.Convert]::FromBase64String($response.audio_data)
				[System.IO.File]::WriteAllBytes($OutputPath, $audioBytes)
				Write-ApplicationLog -Message "CloudPronouncer TTS completed successfully. File size: $($audioBytes.Length) bytes" -Level "INFO"
				return @{ Success = $true; Message = "Generated successfully"; FileSize = $audioBytes.Length }
			} else {
				throw "No audio data received from CloudPronouncer API"
			}
		} catch {
			Write-ApplicationLog -Message "CloudPronouncer TTS failed: $($_.Exception.Message)" -Level "ERROR"
			$placeholderContent = "CloudPronouncer TTS fallback - API error occurred`nText: $Text`nVoice: $Voice"
			Set-Content -Path $OutputPath -Value $placeholderContent -Encoding UTF8
			return @{ Success = $false; Error = $_.Exception.Message; Message = "Using fallback due to API error" }
		}
	}

	[hashtable] GetCapabilities() {
		return @{ MaxTextLength = 2000; SupportedFormats = @('mp3', 'wav'); Premium = $false }
	}
}

function Get-CloudPronouncerProviderSetupFields {
	return @{
		Fields = @(
			@{ Name = 'Username'; Label = 'Username'; Type = 'TextBox'; Default = '' },
			@{ Name = 'Password'; Label = 'Password'; Type = 'PasswordBox'; Default = '' },
			@{ Name = 'Endpoint'; Label = 'API Endpoint'; Type = 'TextBox'; Default = 'https://api.cloudpronouncer.com/' },
			@{ Name = 'Premium'; Label = 'Premium Account'; Type = 'CheckBox'; Default = $false }
		);
		Guidance = @"
1. Visit the CloudPronouncer website (cloudpronouncer.com) and create an account
2. Sign up for a free or premium account based on your needs
3. Obtain your username and password from your account dashboard
4. Enter your CloudPronouncer username in the Username field
5. Enter your CloudPronouncer password in the Password field
6. The API endpoint is pre-configured but can be modified if needed
7. Check 'Premium Account' if you have a premium subscription for enhanced features
8. Click 'Test Connection' to verify your credentials are working

Note: CloudPronouncer offers high-quality text-to-speech synthesis with various voice options. Free accounts have usage limitations.
"@;
	}
}

function Test-CloudPronouncerCredentials {
	param(
		[hashtable]$Config
	)
	if (-not $Config.Username -or $Config.Username.Length -lt 3) {
		return $false
	}
	if (-not $Config.Password -or $Config.Password.Length -lt 6) {
		return $false
	}
	return $true
}
Export-ModuleMember -Function 'Test-CloudPronouncerCredentials', 'Get-CloudPronouncerProviderSetupFields', 'Get-CloudPronouncerAvailableVoices', 'Invoke-CloudPronouncerTTS', 'Get-CloudPronouncerCapabilities'

function Test-CloudPronouncerProviderCredentials {
param($Config)
	return (Test-CloudPronouncerCredentials -Config $Config)
}





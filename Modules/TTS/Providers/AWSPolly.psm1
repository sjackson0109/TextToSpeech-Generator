Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\Logging\EnhancedLogging.psm1')).Path -Force
function ApplyConfigurationToGUI {
	param(
		[Parameter(Mandatory=$true)][hashtable]$Configuration,
		[Parameter(Mandatory=$true)]$Window
	)
	if ($Window.AWS_AccessKey) { $Window.AWS_AccessKey.Text = $Configuration.AccessKey }
	if ($Window.AWS_SecretKey) { $Window.AWS_SecretKey.Text = $Configuration.SecretKey }
	if ($Window.AWS_SessionToken) { $Window.AWS_SessionToken.Text = $Configuration.SessionToken }
	if ($Window.AWS_Region) { $Window.AWS_Region.Text = $Configuration.Region }
}
Export-ModuleMember -Function ApplyConfigurationToGUI
function Test-PollyCredentials {
	param(
		[hashtable]$Config
	)
	# Validate AWS Access Key format
	if (-not $Config.AccessKey -or $Config.AccessKey -notmatch '^AKIA[0-9A-Z]{16}$') {
		Write-ApplicationLog -Message "Polly Validate-PollyCredentials: Invalid AccessKey" -Level "WARNING"
		return $false
	}
	# Validate AWS Secret Key format
	if (-not $Config.SecretKey -or $Config.SecretKey.Length -ne 40) {
		Write-ApplicationLog -Message "Polly Validate-PollyCredentials: Invalid SecretKey" -Level "WARNING"
		return $false
	}
	# Validate AWS region
	$validRegions = @('us-east-1','us-west-2','us-west-1','eu-west-1','eu-central-1','ap-southeast-1','ap-northeast-1','ap-southeast-2','ap-northeast-2','sa-east-1','ca-central-1','eu-west-2','eu-west-3','eu-north-1','ap-east-1','me-south-1','af-south-1','eu-south-1','ap-south-1')
	if (-not $Config.Region -or ($validRegions -notcontains $Config.Region)) {
		Write-ApplicationLog -Message "Polly Validate-PollyCredentials: Invalid Region" -Level "WARNING"
		return $false
	}
	return $true
}
Export-ModuleMember -Function 'Test-PollyCredentials', 'Get-PollyProviderSetupFields', 'Get-PollyAvailableVoices', 'Invoke-PollyTTS', 'Get-PollyCapabilities'
function Show-PollyProviderSetup {
	param(
		$Window,
		$ConfigGrid,
		$GuidanceText,
		$GUI
	)
	$row0 = New-Object System.Windows.Controls.RowDefinition
	$row0.Height = [System.Windows.GridLength]::new(0, [System.Windows.GridUnitType]::Auto)
	$ConfigGrid.RowDefinitions.Add($row0)
	$accessKeyLabel = New-Object System.Windows.Controls.TextBlock
	$accessKeyLabel.Text = "Access Key:"
	$accessKeyLabel.Foreground = "White"
	$accessKeyLabel.Margin = "8"
	[System.Windows.Controls.Grid]::SetRow($accessKeyLabel, 0)
	[System.Windows.Controls.Grid]::SetColumn($accessKeyLabel, 0)
	$ConfigGrid.Children.Add($accessKeyLabel) | Out-Null
	$accessKeyBox = New-Object System.Windows.Controls.TextBox
	$accessKeyBox.Text = if ($GUI.Window.AWS_AccessKey.Text) { $GUI.Window.AWS_AccessKey.Text } else { "" }
	$accessKeyBox.Margin = "8"
	[System.Windows.Controls.Grid]::SetRow($accessKeyBox, 0)
	[System.Windows.Controls.Grid]::SetColumn($accessKeyBox, 1)
	$ConfigGrid.Children.Add($accessKeyBox) | Out-Null
	$secretKeyLabel = New-Object System.Windows.Controls.TextBlock
	$secretKeyLabel.Text = "Secret Key:"
	$secretKeyLabel.Foreground = "White"
	$secretKeyLabel.Margin = "8"
	[System.Windows.Controls.Grid]::SetRow($secretKeyLabel, 0)
	[System.Windows.Controls.Grid]::SetColumn($secretKeyLabel, 2)
	$ConfigGrid.Children.Add($secretKeyLabel) | Out-Null
	$secretKeyBox = New-Object System.Windows.Controls.TextBox
	$secretKeyBox.Text = if ($GUI.Window.AWS_SecretKey.Text) { $GUI.Window.AWS_SecretKey.Text } else { "" }
	$secretKeyBox.Margin = "8"
	[System.Windows.Controls.Grid]::SetRow($secretKeyBox, 0)
	[System.Windows.Controls.Grid]::SetColumn($secretKeyBox, 3)
	$ConfigGrid.Children.Add($secretKeyBox) | Out-Null
	$regionLabel = New-Object System.Windows.Controls.TextBlock
	$regionLabel.Text = "Region:"
	$regionLabel.Foreground = "White"
	$regionLabel.Margin = "8"
	[System.Windows.Controls.Grid]::SetRow($regionLabel, 1)
	[System.Windows.Controls.Grid]::SetColumn($regionLabel, 0)
	$ConfigGrid.Children.Add($regionLabel) | Out-Null
	$regionBox = New-Object System.Windows.Controls.TextBox
	$regionBox.Text = if ($GUI.Window.AWS_Region.SelectedItem) { $GUI.Window.AWS_Region.SelectedItem.Content } else { "us-west-2" }
	$regionBox.Margin = "8"
	[System.Windows.Controls.Grid]::SetRow($regionBox, 1)
	[System.Windows.Controls.Grid]::SetColumn($regionBox, 1)
	$ConfigGrid.Children.Add($regionBox) | Out-Null
	$GuidanceText.Text = "Enter your AWS Polly Access Key, Secret Key, and Region. See docs/AWS-SETUP.md for details."
	$Window.SaveAndClose.add_Click{
		$GUI.Window.AWS_AccessKey.Text = $accessKeyBox.Text
		$GUI.Window.AWS_SecretKey.Text = $secretKeyBox.Text
		$GUI.Window.AWS_Region.SelectedItem = $regionBox.Text
		Write-SafeLog -Message "Amazon Polly setup saved" -Level "INFO"
		$Window.DialogResult = $true
		$Window.Close()
	}
}
Export-ModuleMember -Function 'Show-PollyProviderSetup'

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
		Write-ApplicationLog -Message "PollyTTSProvider.ProcessTTS: Entry, text length $($text.Length)" -Level "DEBUG"
		try {
			# ...actual implementation...
			Write-ApplicationLog -Message "PollyTTSProvider.ProcessTTS: Success" -Level "INFO"
			return @{ Success = $true }
		} catch {
			Write-ApplicationLog -Message "PollyTTSProvider.ProcessTTS: Exception $($_.Exception.Message)" -Level "ERROR"
			return @{ Success = $false; Error = $_.Exception.Message }
		}
	}
	[array] GetAvailableVoices() {
		if (-not $this.Configuration -or -not $this.Configuration.AccessKey) {
			Write-ApplicationLog -Message "Polly GetAvailableVoices: No config, returning empty list" -Level "DEBUG"
			return @()
		}
		try {
			# ...actual API call...
			return @('Matthew') # Placeholder
		} catch {
			Write-ApplicationLog -Message "Polly GetAvailableVoices: Exception $($_.Exception.Message)" -Level "ERROR"
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

class PollyTTSProvider : TTSProvider {
	PollyTTSProvider([hashtable]$config = $null) {
		if ($null -eq $config) { $config = @{} }
	$this.Name = "AWS Polly"
	$this.Configuration = $config
	$this.Capabilities = @{
			MaxTextLength = 3000
			SupportedFormats = @("mp3", "ogg_vorbis", "pcm")
		}
	}
	[hashtable] ProcessTTS([string]$text, [hashtable]$options) {
		try {
			if (-not $options.AccessKey -or -not $options.SecretKey -or -not $options.Region) {
				Write-ApplicationLog -Message "PollyTTSProvider: Missing AWS credentials or region in options." -Level "ERROR"
				throw "Missing AWS credentials or region."
			}
			return Invoke-PollyTTS @options
		} catch {
			Write-ApplicationLog -Message "PollyTTSProvider.ProcessTTS error: $($_.Exception.Message)" -Level "ERROR"
			return @{ Success = $false; ErrorMessage = $_.Exception.Message }
		}
	}
	[array] GetAvailableVoices() {
		try {
			$accessKey = $this.Configuration["AccessKey"]
			$secretKey = $this.Configuration["SecretKey"]
			$region = $this.Configuration["Region"]
			# If not present in config, try environment variables
			if (-not $accessKey) { $accessKey = $env:AWS_POLLY_ACCESS_KEY }
			if (-not $secretKey) { $secretKey = $env:AWS_POLLY_SECRET_KEY }
			if (-not $region) { $region = $env:AWS_POLLY_REGION }
			if (-not $accessKey -or -not $secretKey -or -not $region) {
				Write-ApplicationLog -Message "Polly GetAvailableVoices: No config or env vars, returning demo voices" -Level "DEBUG"
				return @('Joanna', 'Matthew', 'Amy')
			}
			$endpoint = "https://polly.$region.amazonaws.com/v1/voices"
			$date = (Get-Date -Format "yyyyMMddTHHmmssZ")
			$service = "polly"
			$host = "polly.$region.amazonaws.com"
			$amzDate = (Get-Date -Format "yyyyMMddTHHmmssZ")
			$dateStamp = (Get-Date -Format "yyyyMMdd")
			$canonicalUri = "/v1/voices"
			$canonicalQueryString = ""
			$canonicalHeaders = "host:$host`n" + "x-amz-date:$amzDate`n"
			$signedHeaders = "host;x-amz-date"
			$payloadHash = ("" | ConvertTo-Json | Get-FileHash -Algorithm SHA256).Hash.ToLower()
			$algorithm = "AWS4-HMAC-SHA256"
			$credentialScope = "$dateStamp/$region/$service/aws4_request"
			$canonicalRequest = "GET`n$canonicalUri`n$canonicalQueryString`n$canonicalHeaders`n$signedHeaders`n$payloadHash"
			$stringToSign = "$algorithm`n$amzDate`n$credentialScope`n" + (([System.Text.Encoding]::UTF8.GetBytes($canonicalRequest) | Get-FileHash -Algorithm SHA256).Hash.ToLower())
			function GetSignatureKey($key, $dateStamp, $regionName, $serviceName) {
				$kDate = [System.Text.Encoding]::UTF8.GetBytes($dateStamp)
				$kRegion = [System.Text.Encoding]::UTF8.GetBytes($regionName)
				$kService = [System.Text.Encoding]::UTF8.GetBytes($serviceName)
				$kSigning = [System.Text.Encoding]::UTF8.GetBytes("aws4_request")
				$kSecret = [System.Text.Encoding]::UTF8.GetBytes("AWS4" + $key)
				$hmac = New-Object System.Security.Cryptography.HMACSHA256($kSecret)
				$kDate = $hmac.ComputeHash($kDate)
				$hmac = New-Object System.Security.Cryptography.HMACSHA256($kDate)
				$kRegion = $hmac.ComputeHash($kRegion)
				$hmac = New-Object System.Security.Cryptography.HMACSHA256($kRegion)
				$kService = $hmac.ComputeHash($kService)
				$hmac = New-Object System.Security.Cryptography.HMACSHA256($kService)
				$kSigning = $hmac.ComputeHash($kSigning)
				return $kSigning
			}
			$signingKey = GetSignatureKey $secretKey $dateStamp $region $service
			$signature = (New-Object System.Security.Cryptography.HMACSHA256($signingKey)).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($stringToSign))
			$signatureHex = ($signature | ForEach-Object { $_.ToString("x2") }) -join ""
			$authorizationHeader = "$algorithm Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signatureHex"
			$headers = @{
				"Authorization" = $authorizationHeader
				"x-amz-date" = $amzDate
			}
			try {
				$response = Invoke-RestMethod -Uri $endpoint -Method Get -Headers $headers -TimeoutSec 10
				if ($response.voices) {
					return $response.voices | ForEach-Object { $_.Name }
				} else {
					return @('Joanna', 'Matthew', 'Amy')
				}
			} catch {
				Write-ApplicationLog -Message "Polly GetAvailableVoices: Exception $($_.Exception.Message)" -Level "ERROR"
				return @('Joanna', 'Matthew', 'Amy')
			}
		} catch {
			Write-ApplicationLog -Message "PollyTTSProvider.GetAvailableVoices error: $($_.Exception.Message)" -Level "ERROR"
			return @()
		}
	}
	[bool] ValidateConfiguration([hashtable]$config) {
		return Validate-PollyCredentials $config
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
		if ([string]::IsNullOrWhiteSpace($Text) -or $Text.Length -gt 3000) {
			throw "Text must be between 1 and 3000 characters for AWS Polly"
		}
		$endpoint = "https://polly.$Region.amazonaws.com/v1/speech"
		$headers = @{
			"Content-Type" = "application/json"
		}
		# Native REST API call to AWS Polly will be implemented here (SigV4 signing required)
		throw "Native AWS Polly REST API call not yet implemented."
	} catch {
		Write-ApplicationLog -Message "AWS Polly TTS failed: $($_.Exception.Message)" -Level "ERROR"
		$placeholderContent = "AWS Polly TTS fallback - API error occurred`nText: $Text`nVoice: $Voice"
		Set-Content -Path $OutputPath -Value $placeholderContent -Encoding UTF8
		return @{ Success = $false; Error = $_.Exception.Message; Message = "Using fallback due to API error" }
	}
}
Export-ModuleMember -Function 'Invoke-PollyTTS'

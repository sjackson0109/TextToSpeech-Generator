Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\Logging\EnhancedLogging.psm1')).Path -Force
function ApplyConfigurationToGUI {
	param(
		[Parameter(Mandatory=$true)][hashtable]$Configuration,
		[Parameter(Mandatory=$true)]$Window
	)
	if ($Window.MS_KEY) { $Window.MS_KEY.Text = $Configuration.ApiKey }
	if ($Window.MS_Datacenter) { $Window.MS_Datacenter.Text = $Configuration.Datacenter }
	if ($Window.MS_Endpoint) { $Window.MS_Endpoint.Text = $Configuration.Endpoint }
}
Export-ModuleMember -Function ApplyConfigurationToGUI
function Test-AzureCredentials {
	param(
		[hashtable]$Config
	)
	# Validate API Key format (should be a 32-character hex string)
	if (-not $Config.ApiKey -or $Config.ApiKey -notmatch '^[a-fA-F0-9]{32}$') {
		Write-ApplicationLog -Message "Azure Validate-AzureCredentials: Invalid ApiKey" -Level "WARNING"
		return $false
	}
	# Validate datacenter (should be a known Azure region)
	$validRegions = @('eastus','eastus2','westus','westus2','centralus','northcentralus','southcentralus','westeurope','northeurope','southeastasia','eastasia','australiaeast','australiasoutheast','japaneast','japanwest','brazilsouth','canadacentral','canadaeast','uksouth','ukwest','francecentral','francesouth','koreacentral','koreasouth','southafricanorth','uaenorth','switzerlandnorth','switzerlandwest','germanywestcentral','norwaywest','norwayeast')
	if (-not $Config.Datacenter -or ($validRegions -notcontains $Config.Datacenter)) {
		Write-ApplicationLog -Message "Azure Validate-AzureCredentials: Invalid Datacenter" -Level "WARNING"
		return $false
	}
	# Attempt a real API call to Azure TTS endpoint
	$endpoint = "https://$($Config.Datacenter).tts.speech.microsoft.com/cognitiveservices/v1"
	$headers = @{
		'Ocp-Apim-Subscription-Key' = $Config.ApiKey
		'Content-Type' = 'application/ssml+xml'
		'X-Microsoft-OutputFormat' = 'audio-16khz-32kbitrate-mono-mp3'
		'User-Agent' = 'Copilot-Validation'
	}
	$ssml = @"
<speak version='1.0' xml:lang='en-US'>
    <voice xml:lang='en-US' name='en-US-JennyNeural'>Test</voice>
</speak>
"@
	try {
		$response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $ssml -TimeoutSec 10
		if ($response -is [byte[]] -and $response.Length -gt 0) {
			return $true
		} else {
			return $false
		}
	} catch {
		return $false
	}
}
Export-ModuleMember -Function 'Test-AzureCredentials', 'Get-AzureProviderSetupFields', 'Get-AzureAvailableVoices', 'Invoke-AzureTTS', 'Get-AzureCapabilities'
function Show-AzureProviderSetup {
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
	$apiKeyLabel.Text = "API Key:"
	$apiKeyLabel.Foreground = "White"
	$apiKeyLabel.Margin = "8"
	[System.Windows.Controls.Grid]::SetRow($apiKeyLabel, 0)
	[System.Windows.Controls.Grid]::SetColumn($apiKeyLabel, 0)
	$ConfigGrid.Children.Add($apiKeyLabel) | Out-Null
	$apiKeyBox = New-Object System.Windows.Controls.TextBox
	$apiKeyBox.Text = if ($GUI.Window.MS_KEY.Text) { $GUI.Window.MS_KEY.Text } else { "" }
	$apiKeyBox.Margin = "8"
	[System.Windows.Controls.Grid]::SetRow($apiKeyBox, 0)
	[System.Windows.Controls.Grid]::SetColumn($apiKeyBox, 1)
	$ConfigGrid.Children.Add($apiKeyBox) | Out-Null
	$datacenterLabel = New-Object System.Windows.Controls.TextBlock
	$datacenterLabel.Text = "Datacenter:"
	$datacenterLabel.Foreground = "White"
	$datacenterLabel.Margin = "8"
	[System.Windows.Controls.Grid]::SetRow($datacenterLabel, 0)
	[System.Windows.Controls.Grid]::SetColumn($datacenterLabel, 2)
	$ConfigGrid.Children.Add($datacenterLabel) | Out-Null
	$datacenterBox = New-Object System.Windows.Controls.TextBox
	$datacenterBox.Text = if ($GUI.Window.MS_Datacenter.Text) { $GUI.Window.MS_Datacenter.Text } else { "eastus" }
	$datacenterBox.Margin = "8"
	[System.Windows.Controls.Grid]::SetRow($datacenterBox, 0)
	[System.Windows.Controls.Grid]::SetColumn($datacenterBox, 3)
	$ConfigGrid.Children.Add($datacenterBox) | Out-Null
	$GuidanceText.Text = "Enter your Azure Cognitive Services API Key and Datacenter. See docs/AZURE-SETUP.md for details."
	$Window.SaveAndClose.add_Click{
		$GUI.Window.MS_KEY.Text = $apiKeyBox.Text
		$GUI.Window.MS_Datacenter.Text = $datacenterBox.Text
		Write-SafeLog -Message "Azure Cognitive Services setup saved" -Level "INFO"
		$Window.DialogResult = $true
		$Window.Close()
	}
}
Export-ModuleMember -Function 'Show-AzureProviderSetup'

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
		throw "GetAvailableVoices method must be implemented by derived class"
	}
	[bool] ValidateConfiguration([hashtable]$config) {
		throw "ValidateConfiguration method must be implemented by derived class"
	}
	[hashtable] GetCapabilities() {
		return $this.Capabilities
	}
}

	function GetProviderSetupFields {
		return @{
			Fields = @(
				@{ Name = 'ApiKey'; Label = 'API Key'; Type = 'TextBox'; Default = '' },
				@{ Name = 'Datacenter'; Label = 'Datacenter'; Type = 'ComboBox'; Options = @('eastus','eastus2','westus','westus2','centralus','northeurope','westeurope') },
				@{ Name = 'Endpoint'; Label = 'Endpoint'; Type = 'TextBox'; Default = 'https://{region}.tts.speech.microsoft.com/cognitiveservices/v1' }
			);
			Guidance = @"
1. Sign in to the Azure Portal (portal.azure.com) with your Microsoft account
2. Create a new 'Cognitive Services' resource or use an existing one
3. Navigate to your Cognitive Services resource > Keys and Endpoint
4. Copy the 'Key 1' value and paste it into the API Key field above
5. Select your preferred region from the dropdown (should match your Azure resource region)
6. The service endpoint will be automatically configured based on your region
7. Click 'Test Connection' to verify your credentials are working

Note: You'll need an active Azure subscription to create Cognitive Services resources. The first 5 hours of speech synthesis are free each month.
"@
		}
	}

	function ValidateProviderCredentials {
		param($Config)
		return (Validate-AzureCredentials -Config $Config)
	}

	Export-ModuleMember -Function GetProviderSetupFields,ValidateProviderCredentials



class AzureTTSProvider : TTSProvider {
	AzureTTSProvider([hashtable]$config = $null) {
		if ($null -eq $config) { $config = @{} }
		$this.Name = "Azure Cognitive Services"
		$this.Configuration = $config
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
		if ($config.APIKey -notmatch '^[a-f0-9]{32}$') {
			return $false
		}
		return $true
	}
	[array] GetAvailableVoices() {
		$apiKey = $this.Configuration["ApiKey"]
		$region = $this.Configuration["Datacenter"]
		# If not present in config, try environment variables
		if (-not $apiKey) { $apiKey = $env:AZURE_SPEECH_KEY }
		if (-not $region) { $region = $env:AZURE_SPEECH_REGION }
		if (-not $apiKey -or -not $region) {
			Write-ApplicationLog -Message "Azure GetAvailableVoices: No config or env vars, returning demo voices" -Level "DEBUG"
			return @('en-US-JennyNeural', 'en-US-GuyNeural', 'en-GB-LibbyNeural')
		}
		$endpoint = "https://$region.tts.speech.microsoft.com/cognitiveservices/voices/list"
		$headers = @{
			'Ocp-Apim-Subscription-Key' = $apiKey
			'User-Agent' = 'Copilot-VoiceList'
		}
		try {
			$response = Invoke-RestMethod -Uri $endpoint -Method Get -Headers $headers -TimeoutSec 10
			if ($response) {
				return $response | ForEach-Object { $_.Name }
			} else {
				return @('en-US-JennyNeural', 'en-US-GuyNeural', 'en-GB-LibbyNeural')
			}
		} catch {
			Write-ApplicationLog -Message "Azure GetAvailableVoices: Exception $($_.Exception.Message)" -Level "ERROR"
			return @('en-US-JennyNeural', 'en-US-GuyNeural', 'en-GB-LibbyNeural')
		}
	}
	[hashtable] GetCapabilities() {
		Write-ApplicationLog -Message "Azure GetCapabilities: Returning static capabilities" -Level "DEBUG"
		return @{ MaxTextLength = 5000; SupportedFormats = @('mp3', 'wav', 'ogg'); Premium = $false }
	}
}


 function Invoke-AzureTTS {
	param(
		[Parameter(Mandatory=$true)][string]$Text,
		[Parameter(Mandatory=$true)][string]$APIKey,
		[Parameter(Mandatory=$true)][string]$Region,
		[Parameter(Mandatory=$true)][string]$Voice,
		[Parameter(Mandatory=$true)][string]$OutputPath,
		[hashtable]$AdvancedOptions = @{}
	)
	try {
		function GetProviderSetupFields {
			param(
				[Parameter(Mandatory=$true)][string]$Provider,
				[Parameter(Mandatory=$true)]$Window,
				[Parameter(Mandatory=$true)]$ConfigGrid,
				[Parameter(Mandatory=$true)]$GuidanceText
			)
			$Window.APIProviderInfo.Text = "Configure Azure Cognitive Services API credentials and regional settings."
			# Row 0: API Key and Region
			$row0 = New-Object System.Windows.Controls.RowDefinition
			$row0.Height = [System.Windows.GridLength]::new(0, [System.Windows.GridUnitType]::Auto)
			$ConfigGrid.RowDefinitions.Add($row0)

			# API Key Label
			$apiKeyLabel = New-Object System.Windows.Controls.Label
			$apiKeyLabel.Content = "API Key:"
			$apiKeyLabel.Foreground = "White"
			$apiKeyLabel.VerticalAlignment = "Center"
			[System.Windows.Controls.Grid]::SetRow($apiKeyLabel, 0)
			[System.Windows.Controls.Grid]::SetColumn($apiKeyLabel, 0)
			$ConfigGrid.Children.Add($apiKeyLabel) | Out-Null

			# API Key TextBox
			$apiKeyBox = New-Object System.Windows.Controls.TextBox
			$apiKeyBox.Name = "API_MS_KEY"
			$apiKeyBox.Height = 25
			$apiKeyBox.Margin = "5,2"
			$apiKeyBox.VerticalAlignment = "Center"
			if ($Window.MS_KEY.Text) { $apiKeyBox.Text = $Window.MS_KEY.Text }
			[System.Windows.Controls.Grid]::SetRow($apiKeyBox, 0)
			[System.Windows.Controls.Grid]::SetColumn($apiKeyBox, 1)
			$ConfigGrid.Children.Add($apiKeyBox) | Out-Null

			# Region Label
			$regionLabel = New-Object System.Windows.Controls.Label
			$regionLabel.Content = "Region:" 
			$regionLabel.Foreground = "White"
			$regionLabel.VerticalAlignment = "Center"
			[System.Windows.Controls.Grid]::SetRow($regionLabel, 0)
			[System.Windows.Controls.Grid]::SetColumn($regionLabel, 2)
			$ConfigGrid.Children.Add($regionLabel) | Out-Null

			# Region ComboBox
			$regionBox = New-Object System.Windows.Controls.ComboBox
			$regionBox.Name = "API_MS_Region"
			$regionBox.Height = 25
			$regionBox.Margin = "5,2"
			$regionBox.VerticalAlignment = "Center"
			$regionBox.IsEditable = $true
			$azureRegions = @{
				"East US" = "eastus"
				"East US 2" = "eastus2"
				"South Central US" = "southcentralus"
				"West US" = "westus"
				"West US 2" = "westus2"
				"West US 3" = "westus3"
				"Central US" = "centralus"
				"North Central US" = "northcentralus"
				"West Central US" = "westcentralus"
				"Canada Central" = "canadacentral"
				"Canada East" = "canadaeast"
				"Brazil South" = "brazilsouth"
				"Brazil Southeast" = "brazilsoutheast"
				"UK South" = "uksouth"
				"UK West" = "ukwest"
				"France Central" = "francecentral"
				"France South" = "francesouth"
				"Germany West Central" = "germanywestcentral"
				"Germany North" = "germanynorth"
				"Norway East" = "norwayeast"
				"Norway West" = "norwaywest"
				"Switzerland North" = "switzerlandnorth"
				"Switzerland West" = "switzerlandwest"
				"UAE North" = "uaenorth"
				"UAE Central" = "uaecentral"
				"South Africa North" = "southafricanorth"
				"South Africa West" = "southafricawest"
				"East Asia" = "eastasia"
				"Southeast Asia" = "southeastasia"
				"Australia East" = "australiaeast"
				"Australia Southeast" = "australiasoutheast"
				"Australia Central" = "australiacentral"
				"Australia Central 2" = "australiacentral2"
				"Japan East" = "japaneast"
				"Japan West" = "japanwest"
				"Korea Central" = "koreacentral"
				"Korea South" = "koreasouth"
				"India Central" = "centralindia"
				"India South" = "southindia"
				"India West" = "westindia"
				"China East" = "chinaeast"
				"China North" = "chinanorth"
				"China East 2" = "chinaeast2"
				"China North 2" = "chinanorth2"
				"US Gov Virginia" = "usgovvirginia"
				"US Gov Iowa" = "usgoviowa"
				"US Gov Arizona" = "usgovarizona"
				"US Gov Texas" = "usgovtexas"
				"US Gov Georgia" = "usgovgeorgia"
				"US Gov DC" = "usgovdc"
				"US DoD East" = "usdodeast"
				"US DoD Central" = "usdodcentral"
			}
			$sortedRegionNames = $azureRegions.Keys | Sort-Object
			foreach ($displayName in $sortedRegionNames) {
				$comboItem = New-Object System.Windows.Controls.ComboBoxItem
				$comboItem.Content = $displayName
				$comboItem.Tag = $azureRegions[$displayName]
				$regionBox.Items.Add($comboItem) | Out-Null
			}
			if ($Window.MS_Datacenter.Text) {
				foreach ($item in $regionBox.Items) {
					if ($item.Tag -eq $Window.MS_Datacenter.Text) {
						$item.IsSelected = $true
						break
					}
				}
			} else {
				$regionBox.SelectedIndex = 0
			}
			[System.Windows.Controls.Grid]::SetRow($regionBox, 0)
			[System.Windows.Controls.Grid]::SetColumn($regionBox, 3)
			$ConfigGrid.Children.Add($regionBox) | Out-Null

			# Endpoint Label
			$endpointLabel = New-Object System.Windows.Controls.Label
			$endpointLabel.Content = "Endpoint:"
			$endpointLabel.Foreground = "White"
			$endpointLabel.VerticalAlignment = "Center"
			[System.Windows.Controls.Grid]::SetRow($endpointLabel, 1)
			[System.Windows.Controls.Grid]::SetColumn($endpointLabel, 0)
			$ConfigGrid.Children.Add($endpointLabel) | Out-Null

			# Endpoint TextBox
			$endpointBox = New-Object System.Windows.Controls.TextBox
			$endpointBox.Name = "API_MS_Endpoint"
			$endpointBox.Height = 25
			$endpointBox.Margin = "5,2"
			$endpointBox.Text = "https://{region}.tts.speech.microsoft.com/cognitiveservices/v1"
			[System.Windows.Controls.Grid]::SetRow($endpointBox, 1)
			[System.Windows.Controls.Grid]::SetColumn($endpointBox, 1)
			[System.Windows.Controls.Grid]::SetColumnSpan($endpointBox, 3)
			$ConfigGrid.Children.Add($endpointBox) | Out-Null

			$GuidanceText.Text = @"
		if ([string]::IsNullOrWhiteSpace($Text) -or $Text.Length -gt 5000) {
			throw "Text must be between 1 and 5000 characters"
		}
		$endpoint = "https://$Region.tts.speech.microsoft.com/cognitiveservices/v1"
		}
		Export-ModuleMember -Function GetProviderSetupFields,ApplyConfigurationToGUI
		$rate = if ($AdvancedOptions.SpeechRate) { $AdvancedOptions.SpeechRate } else { 1.0 }
		$pitch = if ($AdvancedOptions.Pitch) { $AdvancedOptions.Pitch } else { 0 }
		$style = if ($AdvancedOptions.Style) { $AdvancedOptions.Style } else { "neutral" }
		$volume = if ($AdvancedOptions.Volume) { $AdvancedOptions.Volume } else { 50 }
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
			'X-Microsoft-OutputFormat' = 'audio-16khz-32kbitrate-mono-mp3'
			'User-Agent' = 'curl'
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
Export-ModuleMember -Function 'Invoke-AzureTTS'

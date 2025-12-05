# Exported provider-specific optimisation settings
$ProviderOptimisationSettings = @{
	MinPoolSize = 2
	MaxPoolSize = 8
	ConnectionTimeout = 30
}
Export-ModuleMember -Variable 'ProviderOptimisationSettings'
if (-not (Get-Module -Name 'Logging')) {
	Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'Modules\Logging.psm1')
}

# Load required assemblies for GUI Dialogues
Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue

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
	# Validate API Key format (Azure keys are typically 32 hex chars OR base64-encoded strings of varying length)
	if (-not $Config.ApiKey -or [string]::IsNullOrWhiteSpace($Config.ApiKey)) {
		Add-ApplicationLog -Module "Azure" -Message "Azure Validate-AzureCredentials: Missing ApiKey" -Level "WARNING"
		return $false
	}
	
	# Azure keys are typically either 32 hex characters or 88 character base64 strings
	# Just check it's a reasonable length and contains valid characters
	if ($Config.ApiKey.Length -lt 16) {
		Add-ApplicationLog -Module "Azure" -Message "Azure Validate-AzureCredentials: ApiKey too short" -Level "WARNING"
		return $false
	}
	
	# Validate datacenter (should be a known Azure region)
	$validRegions = @(
		'australiacentral','australiaeast','brazilsouth','canadacentral','canadaeast',
		'centralus','eastasia','eastus','eastus2','francecentral','germanywestcentral',
		'japaneast','japanwest','koreacentral','northeurope','southcentralus',
		'southeastasia','uksouth','ukwest','westeurope','westus','westus2','westus3'
	)
	if (-not $Config.Datacenter -or ($validRegions -notcontains $Config.Datacenter)) {
		Add-ApplicationLog -Module "Azure" -Message "Azure Validate-AzureCredentials: Invalid Datacenter '$($Config.Datacenter)'" -Level "WARNING"
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
	Add-ApplicationLog -Module "Azure" -Message "Testing Azure API - Endpoint: $endpoint" -Level "DEBUG"
	
	try {
		$response = Invoke-WebRequest -Uri $endpoint -Method Post -Headers $headers -Body $ssml -TimeoutSec 10
		if ($response.Content -is [byte[]] -and $response.Content.Length -gt 0) {
			Add-ApplicationLog -Module "Azure" -Message "Azure API test successful - received $($response.Content.Length) bytes" -Level "INFO"
			return $true
		} else {
			$responseType = if ($response.Content) { $response.Content.GetType().FullName } else { "null" }
			$responseLength = if ($response.Content -is [byte[]]) { $response.Content.Length } else { "N/A" }
			Add-ApplicationLog -Module "Azure" -Message "Azure API test failed - Response type: $responseType, Length: $responseLength, Status: $($response.StatusCode)" -Level "ERROR"
			return $false
		}
	} catch {
		$errorDetails = "Exception: $($_.Exception.Message)"
		
		# Try to extract detailed error response from Azure
		if ($_.Exception.Response) {
			try {
				$responseStream = $_.Exception.Response.GetResponseStream()
				$reader = New-Object System.IO.StreamReader($responseStream)
				$responseBody = $reader.ReadToEnd()
				$reader.Close()
				$responseStream.Close()
				
				if ($responseBody) {
					$errorDetails += " | Azure Response: $responseBody"
					
					# Try to parse JSON for cleaner logging
					try {
						$jsonError = $responseBody | ConvertFrom-Json
						if ($jsonError.error) {
							$errorDetails += " | Error Code: $($jsonError.error.code) | Message: $($jsonError.error.message)"
						}
					} catch {
						# If JSON parse fails, the raw response is already logged
					}
				}
			} catch {
				# If response reading fails, just log the exception
			}
		}
		
		Add-ApplicationLog -Module "Azure" -Message "Azure API test failed - $errorDetails" -Level "ERROR"
		return $false
	}
}
Export-ModuleMember -Function 'Test-AzureCredentials', 'Get-AzureProviderSetupFields', 'Get-AzureVoiceOptions', 'Invoke-AzureTTS', 'Get-AzureCapabilities'

function Get-AzureVoiceOptions {
	<#
	.SYNOPSIS
		Returns voice configuration options for Azure Cognitive Services TTS with dynamic voice retrieval
	.DESCRIPTION
		Fetches available voices from Azure TTS API and provides lists of supported languages,
		formats, and quality levels. Implements two-step authentication (token + voices) with fallback.
	.PARAMETER ApiKey
		Optional API key (subscription key) for live validation. If not provided, returns default values.
	.PARAMETER Region
		Optional Azure region (e.g., 'eastus', 'westeurope', 'uksouth'). Required if ApiKey is provided.
	.PARAMETER UseCache
		Whether to use cached results if available. Default is $true.
	.OUTPUTS
		Hashtable containing Voices, Languages, Formats, Quality arrays and Defaults hashtable
	#>
	
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$false)]
		[string]$ApiKey,
		
		[Parameter(Mandatory=$false)]
		[string]$Region = "eastus",
		
		[Parameter(Mandatory=$false)]
		[bool]$UseCache = $true
	)
	
	# Fallback/default configuration
	$defaultOptions = @{
		Voices = @(
			# US English (Professional 2025)
			'en-US-AriaNeural',
			'en-US-JennyNeural',
			'en-US-GuyNeural',
			'en-US-AvaNeural',
			'en-US-AndrewNeural',
			'en-US-EmmaNeural',
			'en-US-BrianNeural',
			'en-US-DavisNeural',
			'en-US-JaneNeural',
			'en-US-JasonNeural',
			'en-US-SaraNeural',
			'en-US-TonyNeural',
			'en-US-NancyNeural',
			'en-US-AmberNeural',
			'en-US-AshleyNeural',
			'en-US-CoraNeural',
			'en-US-ElizabethNeural',
			'en-US-MichelleNeural',
			'en-US-MonicaNeural',
			'en-US-ChristopherNeural',
			'en-US-EricNeural',
			'en-US-JacobNeural',
			# UK English (British Accent)
			'en-GB-SoniaNeural',
			'en-GB-RyanNeural',
			'en-GB-LibbyNeural',
			'en-GB-MaisieNeural',
			'en-GB-ThomasNeural',
			# Australian English
			'en-AU-NatashaNeural',
			'en-AU-WilliamNeural',
			'en-AU-AnnetteNeural',
			'en-AU-CarlyNeural',
			'en-AU-DarrenNeural',
			# Canadian English
			'en-CA-ClaraNeural',
			'en-CA-LiamNeural',
			# Indian English
			'en-IN-NeerjaNeural',
			'en-IN-PrabhatNeural',
			# Irish English
			'en-IE-EmilyNeural',
			'en-IE-ConnorNeural'
		)
		Languages = @(
			'en-US',
			'en-GB',
			'en-AU',
			'en-CA',
			'fr-FR',
			'de-DE',
			'es-ES',
			'it-IT',
			'pt-BR',
			'ja-JP',
			'ko-KR',
			'zh-CN'
		)
		Formats = @(
			'MP3 16kHz',
			'MP3 24kHz',
			'MP3 48kHz',
			'WAV 16kHz',
			'WAV 24kHz',
			'WAV 48kHz'
		)
		Quality = @(
			'Neural',
			'Standard'
		)
		Defaults = @{
			Voice = 'en-US-AriaNeural'
			Language = 'en-US'
			Format = 'MP3 24kHz'
			Quality = 'Neural'
		}
		SupportsAdvanced = $true
	}
	
	# If no API key provided, return defaults
	if (-not $ApiKey) {
		Add-ApplicationLog -Module "Azure" -Message "No API key provided, returning default voice options" -Level "DEBUG"
		return $defaultOptions
	}
	
	# Try to fetch live voice data from Azure TTS API (two-step process)
	try {
		Add-ApplicationLog -Module "Azure" -Message "Step 1: Getting authentication token from Azure (region: $Region)" -Level "INFO"
		
		# Step 1: Get Bearer token from issueToken endpoint
		$tokenUri = "https://$Region.api.cognitive.microsoft.com/sts/v1.0/issueToken"
		$tokenHeaders = @{
			"Ocp-Apim-Subscription-Key" = $ApiKey
		}
		
		$token = Invoke-RestMethod -Uri $tokenUri -Method Post -Headers $tokenHeaders -TimeoutSec 10 -ErrorAction Stop
		
		if (-not $token) {
			throw "Failed to obtain authentication token from Azure"
		}
		
		Add-ApplicationLog -Module "Azure" -Message "Step 2: Fetching available voices from Azure TTS API" -Level "INFO"
		
		# Step 2: Use Bearer token to get voices list
		$voicesUri = "https://$Region.tts.speech.microsoft.com/cognitiveservices/voices/list"
		$voicesHeaders = @{
			"Authorisation" = "Bearer $token"
		}
		
		$response = Invoke-RestMethod -Uri $voicesUri -Method Get -Headers $voicesHeaders -TimeoutSec 10 -ErrorAction Stop
		
		if ($response -and $response.Count -gt 0) {
			# Extract voice names from response
			$voiceNames = $response | ForEach-Object { $_.ShortName } | Sort-Object
			Add-ApplicationLog -Module "Azure" -Message "Successfully retrieved $($voiceNames.Count) voices from API" -Level "INFO"
			$defaultOptions.Voices = @($voiceNames)
			
			# Extract unique locale codes
			$localeCodes = $response | ForEach-Object { $_.Locale } | Select-Object -Unique | Sort-Object
			if ($localeCodes.Count -gt 0) {
				$defaultOptions.Languages = @($localeCodes)
			}
		} else {
			Add-ApplicationLog -Module "Azure" -Message "No voices found in API response, using defaults" -Level "WARNING"
		}
		
	} catch {
		Add-ApplicationLog -Module "Azure" -Message "Failed to fetch voices from API: $($_.Exception.Message). Using default values." -Level "WARNING"
	}
	
	return $defaultOptions
}
Export-ModuleMember -Function 'Get-AzureVoiceOptions'
function Show-AzureProviderSetup {
	<#
	.SYNOPSIS
	Shows the Azure Cognitive Services configuration Dialogue
	.DESCRIPTION
	Creates a comprehensive Azure configuration Dialogue with GroupBoxes, Test Connection, and Validate buttons
	#>
	param(
		$Window,
		$ConfigGrid,
		$GuidanceText,
		$GUI
	)
	
	try {
		Add-ApplicationLog -Module "Azure" -Message "Starting Azure provider setup" -Level "INFO"
		
		# Get the field definitions
		$setupFields = GetProviderSetupFields
		Add-ApplicationLog -Module "Azure" -Message "Got provider setup fields" -Level "INFO"
		
		# Update window properties if provided
		if ($Window) {
			Add-ApplicationLog -Module "Azure" -Message "Setting window properties" -Level "INFO"
			$Window.Title = "API Configuration"
			$Window.Width = 780
			$Window.Height = 620
		}
		
		# Clear existing grid content
		if ($ConfigGrid) {
			Add-ApplicationLog -Module "Azure" -Message "Clearing config grid" -Level "INFO"
			$ConfigGrid.Children.Clear()
			$ConfigGrid.RowDefinitions.Clear()
			$ConfigGrid.ColumnDefinitions.Clear()
		}
		
		# Build the configuration UI dynamically from field definitions
		$azureConfigXaml = @"
<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
	  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
	<Grid.RowDefinitions>
		<RowDefinition Height="Auto"/>
		<RowDefinition Height="Auto"/>
		<RowDefinition Height="Auto"/>
		<RowDefinition Height="*"/>
	</Grid.RowDefinitions>
	
	<!-- API Configuration Header -->
	<GroupBox Grid.Row="0" Header="API Configuration" Foreground="White" BorderBrush="#FF404040" Margin="0,0,0,12">
		<TextBlock Text="Configure your Azure Cognitive Services API credentials below. Click 'Test Connection' to verify." 
				   Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="8"/>
	</GroupBox>
	
	<!-- Microsoft Azure Configuration -->
	<GroupBox Grid.Row="1" Header="Microsoft Azure Configuration" Foreground="White" BorderBrush="#FF404040" Margin="0,0,0,12">
		<Grid Margin="8">
			<Grid.ColumnDefinitions>
				<ColumnDefinition Width="Auto"/>
				<ColumnDefinition Width="*"/>
				<ColumnDefinition Width="Auto"/>
				<ColumnDefinition Width="350"/>
			</Grid.ColumnDefinitions>
			<Grid.RowDefinitions>
				<RowDefinition Height="Auto"/>
				<RowDefinition Height="Auto"/>
			</Grid.RowDefinitions>
			
			<!-- API Key -->
			<TextBlock Grid.Row="0" Grid.Column="0" Text="API Key:" Foreground="White" VerticalAlignment="Centre" Margin="0,0,8,8"/>
			<TextBox x:Name="ApiKeyBox" Grid.Row="0" Grid.Column="1" Margin="0,0,8,8" Height="24" VerticalContentAlignment="Centre"/>
			
			<!-- Region -->
			<TextBlock Grid.Row="0" Grid.Column="2" Text="Region:" Foreground="White" VerticalAlignment="Centre" Margin="0,0,8,8"/>
			<ComboBox x:Name="RegionCombo" Grid.Row="0" Grid.Column="3" Margin="0,0,0,8" Height="24">
"@
		
		# Add all region options from the field definition
		$datacenterField = $setupFields.Fields | Where-Object { $_.Name -eq 'Datacenter' }
		if ($datacenterField -and $datacenterField.Options) {
			foreach ($region in $datacenterField.Options) {
				$azureConfigXaml += "`n				<ComboBoxItem Content=`"$region`"/>"
			}
		}
		
		$azureConfigXaml += @"

			</ComboBox>
			
			<!-- Endpoint -->
			<TextBlock Grid.Row="1" Grid.Column="0" Text="Endpoint:" Foreground="White" VerticalAlignment="Centre" Margin="0,0,8,0"/>
			<TextBox x:Name="EndpointBox" Grid.Row="1" Grid.Column="1" Grid.ColumnSpan="3" Margin="0,0,0,0" Height="24" VerticalContentAlignment="Centre" IsReadOnly="True" Background="#FF2D2D30" Foreground="#FF808080"/>
		</Grid>
	</GroupBox>
	
	<!-- Connection Testing -->
	<GroupBox Grid.Row="2" Header="Connection Testing" Foreground="White" BorderBrush="#FF404040" Margin="0,0,0,12">
		<Grid Margin="8">
			<Grid.ColumnDefinitions>
				<ColumnDefinition Width="*"/>
				<ColumnDefinition Width="Auto"/>
			</Grid.ColumnDefinitions>
			
			<TextBlock x:Name="TestStatus" Grid.Column="0" Text="Ready to test connection..." Foreground="White" VerticalAlignment="Centre"/>
			<Button x:Name="TestConnectionBtn" Grid.Column="1" Content="🔌 Test Connection" Width="140" Height="28" 
					Background="#FF28A745" Foreground="White" BorderBrush="#FF1E7E34" BorderThickness="1"/>
		</Grid>
	</GroupBox>
	
	<!-- Setup Instructions -->
	<GroupBox Grid.Row="3" Header="Setup Instructions" Foreground="White" BorderBrush="#FF404040">
		<ScrollViewer VerticalScrollBarVisibility="Auto" Padding="8">
			<StackPanel>
				<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" FontWeight="Normal" Margin="0,0,0,8">
					<Run FontWeight="SemiBold" Foreground="White">1. Sign in to the Azure Portal</Run>
					<LineBreak/>
					Visit portal.azure.com with your Microsoft account
				</TextBlock>
				<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" FontWeight="Normal" Margin="0,0,0,8">
					<Run FontWeight="SemiBold" Foreground="White">2. Create a Cognitive Services resource</Run>
					<LineBreak/>
					Create a new 'Cognitive Services' resource or use an existing one
				</TextBlock>
				<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" FontWeight="Normal" Margin="0,0,0,8">
					<Run FontWeight="SemiBold" Foreground="White">3. Navigate to Keys and Endpoint</Run>
					<LineBreak/>
					Go to your Cognitive Services resource → Keys and Endpoint
				</TextBlock>
				<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" FontWeight="Normal" Margin="0,0,0,8">
					<Run FontWeight="SemiBold" Foreground="White">4. Copy the API Key</Run>
					<LineBreak/>
					Copy the 'Key 1' value and paste it into the API Key field above
				</TextBlock>
				<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" FontWeight="Normal" Margin="0,0,0,8">
					<Run FontWeight="SemiBold" Foreground="White">5. Select your region</Run>
					<LineBreak/>
					Choose your preferred region from the dropdown (should match your Azure resource region)
				</TextBlock>
				<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" FontWeight="Normal" Margin="0,0,0,8">
					<Run FontWeight="SemiBold" Foreground="White">6. Endpoint auto-configuration</Run>
					<LineBreak/>
					The service endpoint will be automatically configured based on your region
				</TextBlock>
				<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" FontWeight="Normal" Margin="0,0,0,8">
					<Run FontWeight="SemiBold" Foreground="White">7. Test your connection</Run>
					<LineBreak/>
					Click 'Test Connection' to verify your credentials are working
				</TextBlock>
				<TextBlock Foreground="#FFFFCC00" TextWrapping="Wrap" FontWeight="Normal" Margin="0,8,0,0" FontStyle="Italic">
					<Run FontWeight="SemiBold">Note:</Run> You'll need an active Azure subscription to create Cognitive Services resources. The first 5 hours of speech synthesis are free each month.
				</TextBlock>
			</StackPanel>
		</ScrollViewer>
	</GroupBox>
</Grid>
"@
		
		# Parse and load the XAML
		Add-ApplicationLog -Module "Azure" -Message "Parsing XAML" -Level "INFO"
		$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($azureConfigXaml))
		$azureContent = [Windows.Markup.XamlReader]::Load($reader)
		$reader.Close()
		Add-ApplicationLog -Module "Azure" -Message "XAML parsed successfully" -Level "INFO"
		
		# Add to the provided ConfigGrid
		Add-ApplicationLog -Module "Azure" -Message "Adding content to ConfigGrid" -Level "INFO"
		$ConfigGrid.Children.Add($azureContent) | Out-Null
		
		# Get controls
		Add-ApplicationLog -Module "Azure" -Message "Finding controls in XAML" -Level "INFO"
		$apiKeyBox = $azureContent.FindName("ApiKeyBox")
		$regionCombo = $azureContent.FindName("RegionCombo")
		$endpointBox = $azureContent.FindName("EndpointBox")
		$testStatus = $azureContent.FindName("TestStatus")
		$testBtn = $azureContent.FindName("TestConnectionBtn")
		Add-ApplicationLog -Module "Azure" -Message "Controls found" -Level "INFO"
		
		# Load existing values with null checks
		if ($GUI -and $GUI.Window -and $GUI.Window.MS_KEY) {
			if (Get-Member -InputObject $GUI.Window.MS_KEY -Name 'Text' -MemberType Properties) {
				if (-not [string]::IsNullOrEmpty($GUI.Window.MS_KEY.Text)) {
					$apiKeyBox.Text = $GUI.Window.MS_KEY.Text
				}
			}
		}
		
		# Set region with null checks
		if ($GUI -and $GUI.Window -and $GUI.Window.MS_Datacenter) {
			if (Get-Member -InputObject $GUI.Window.MS_Datacenter -Name 'Text' -MemberType Properties) {
				if (-not [string]::IsNullOrEmpty($GUI.Window.MS_Datacenter.Text)) {
					foreach ($item in $regionCombo.Items) {
						if ($item.Content -eq $GUI.Window.MS_Datacenter.Text) {
							$regionCombo.SelectedItem = $item
							break
						}
					}
				}
			}
		}
		
		# If no region selected, default to uksouth
		if (-not $regionCombo.SelectedItem -and $regionCombo.Items.Count -gt 0) {
			foreach ($item in $regionCombo.Items) {
				if ($item.Content -eq 'uksouth') {
					$regionCombo.SelectedItem = $item
					break
				}
			}
			# If uksouth not found, use first item
			if (-not $regionCombo.SelectedItem) {
				$regionCombo.SelectedIndex = 0
			}
		}
		
		# Update endpoint when region changes
		$regionCombo.add_SelectionChanged({
			if ($regionCombo.SelectedItem) {
				$selectedRegion = $regionCombo.SelectedItem.Content
				$endpointBox.Text = "https://$selectedRegion.tts.speech.microsoft.com/cognitiveservices/v1"
			}
		})
		
		# Trigger initial endpoint update
		if ($regionCombo.SelectedItem) {
			$selectedRegion = $regionCombo.SelectedItem.Content
			$endpointBox.Text = "https://$selectedRegion.tts.speech.microsoft.com/cognitiveservices/v1"
		}
		
		# Test Connection button
		$testBtn.add_Click({
			$testStatus.Text = "Testing connection..."
			$testStatus.Foreground = "#FFFFFF00"
			
			$apiKey = $apiKeyBox.Text.Trim()
			$region = $regionCombo.SelectedItem.Content
			
			if ([string]::IsNullOrWhiteSpace($apiKey)) {
				$testStatus.Text = "❌ Please enter an API Key"
				$testStatus.Foreground = "#FFFF0000"
				[System.Windows.MessageBox]::Show(
					"Please enter an API Key before testing.",
					"Test Connection",
					[System.Windows.MessageBoxButton]::OK,
					[System.Windows.MessageBoxImage]::Warning
				)
				return
			}
			
			try {
				$testConfig = @{
					ApiKey = $apiKey
					Datacenter = $region
				}
				$testResult = Test-AzureCredentials -Config $testConfig
				
				if ($testResult) {
					$testStatus.Text = "✓ Connection successful!"
					$testStatus.Foreground = "#FF28A745"
					Add-ApplicationLog -Module "Azure" -Message "Azure connection test successful" -Level "INFO"
					[System.Windows.MessageBox]::Show(
						"Connection successful! Your Azure credentials are valid and working correctly.",
						"Test Connection - Success",
						[System.Windows.MessageBoxButton]::OK,
						[System.Windows.MessageBoxImage]::Information
					)
				} else {
					$testStatus.Text = "❌ Connection failed - check credentials"
					$testStatus.Foreground = "#FFFF0000"
					Add-ApplicationLog -Module "Azure" -Message "Azure connection test failed" -Level "WARNING"
					[System.Windows.MessageBox]::Show(
						"Connection failed. Please check your API Key and Region are correct.",
						"Test Connection - Failed",
						[System.Windows.MessageBoxButton]::OK,
						[System.Windows.MessageBoxImage]::Error
					)
				}
			} catch {
				$testStatus.Text = "❌ Error: $($_.Exception.Message)"
				$testStatus.Foreground = "#FFFF0000"
				Add-ApplicationLog -Module "Azure" -Message "Azure connection test error: $($_.Exception.Message)" -Level "ERROR"
				[System.Windows.MessageBox]::Show(
					"Error testing connection:`n$($_.Exception.Message)",
					"Test Connection - Error",
					[System.Windows.MessageBoxButton]::OK,
					[System.Windows.MessageBoxImage]::Error
				)
			}
		})
		
		# Store control references for Save button handler
		$Window | Add-Member -NotePropertyName 'AzureApiKeyBox' -NotePropertyValue $apiKeyBox -Force
		$Window | Add-Member -NotePropertyName 'AzureRegionCombo' -NotePropertyValue $regionCombo -Force
		
	# Update GuidanceText if it exists and has a Text property
	if ($GuidanceText -and (Get-Member -InputObject $GuidanceText -Name 'Text' -MemberType Properties)) {
		$GuidanceText.Text = "Configure your Azure Cognitive Services API credentials above."
	}
	
	# Wire up Save & Close button using FindName
	$saveButton = $Window.FindName("SaveAndClose")
	if ($saveButton) {
		$saveButton.add_Click({
			$apiKey = $Window.AzureApiKeyBox.Text.Trim()
			$region = if ($Window.AzureRegionCombo.SelectedItem) { $Window.AzureRegionCombo.SelectedItem.Content } else { "" }
			
			if ([string]::IsNullOrWhiteSpace($apiKey)) {
				[System.Windows.MessageBox]::Show(
					"Please enter an API Key before saving.",
					"Save Configuration",
					[System.Windows.MessageBoxButton]::OK,
					[System.Windows.MessageBoxImage]::Warning
				)
				return
			}
			
			# Update GUI window
			if ($GUI.Window.MS_KEY) {
				$GUI.Window.MS_KEY.Text = $apiKey
			}
			if ($GUI.Window.MS_Datacenter) {
				$GUI.Window.MS_Datacenter.Text = $region
			}
			
			Add-ApplicationLog -Module "Azure" -Message "Azure configuration saved successfully" -Level "INFO"
			
			$Window.DialogueResult = $true
			$Window.Close()
		})
	}	} catch {
		Add-ApplicationLog -Module "Azure" -Message "Error setting up Azure configuration: $($_.Exception.Message)" -Level "ERROR"
		[System.Windows.MessageBox]::Show(
			"Error setting up Azure configuration:`n$($_.Exception.Message)",
			"Configuration Error",
			[System.Windows.MessageBoxButton]::OK,
			[System.Windows.MessageBoxImage]::Error
		)
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
	[hashtable] ShowConfigurationDialog([hashtable]$currentConfig) {
		throw "ShowConfigurationDialog method must be implemented by derived class"
	}
	[hashtable] GetCapabilities() {
		return $this.Capabilities
	}
}

	function GetProviderSetupFields {
		return @{
			Fields = @(
				@{ Name = 'ApiKey'; Label = 'API Key'; Type = 'TextBox'; Default = '' },
				@{ Name = 'Datacenter'; Label = 'Region'; Type = 'ComboBox'; Options = @('australiacentral','australiacentral2','australiaeast','australiasoutheast','austriaeast','belgiumcentral','brazilsouth','brazilsoutheast','canadacentral','canadaeast','centralindia','centralus','chilecentral','eastasia','eastus','eastus2','francecentral','francesouth','germanynorth','germanywestcentral','indonesiacentral','israelcentral','italynorth','japaneast','japanwest','koreacentral','koreasouth','mexicocentral','norwayeast','norwaywest','polandcentral','qatarcentral','southafricanorth','southafricawest','southcentralus','southeastasia','southindia','swedencentral','sweden-south','switzerlandnorth','switzerlandwest','uaenorth','uaecentral','uksouth','ukwest','westcentralus','westeurope','westindia','westus','westus2','westus3') },
				@{ Name = 'Endpoint'; Label = 'Endpoint'; Type = 'TextBox'; Default = 'https://{region}.tts.speech.microsoft.com/cognitiveservices/v1' }
			)
		}
	}

	function ValidateProviderCredentials {
		param($Config)
		return (Test-AzureCredentials -Config $Config)
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
			Add-ApplicationLog -Module "Azure" -Message "Azure GetAvailableVoices: No config or env vars, returning demo voices" -Level "DEBUG"
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
			Add-ApplicationLog -Module "Azure" -Message "Azure GetAvailableVoices: Exception $($_.Exception.Message)" -Level "ERROR"
			return @('en-US-JennyNeural', 'en-US-GuyNeural', 'en-GB-LibbyNeural')
		}
	}
	[hashtable] GetCapabilities() {
		Add-ApplicationLog -Module "Azure" -Message "Azure GetCapabilities: Returning static capabilities" -Level "DEBUG"
		return @{ MaxTextLength = 5000; SupportedFormats = @('mp3', 'wav', 'ogg'); Premium = $false }
	}
	
	[hashtable] ShowConfigurationDialog([hashtable]$currentConfig) {
		Add-ApplicationLog -Module "Azure" -Message "Showing Azure configuration Dialogue" -Level "INFO"
		
		# Load PresentationFramework if not already loaded
		Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
		Add-Type -AssemblyName PresentationCore -ErrorAction SilentlyContinue
		Add-Type -AssemblyName WindowsBase -ErrorAction SilentlyContinue
		
		# Create complete Dialogue window with all controls
		$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
		xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		Title="Azure Cognitive Services Configuration" Width="780" Height="630"
		WindowStartupLocation="CenterScreen"
		Background="#FF1E1E1E"
		ResizeMode="CanResize">
	<Grid Margin="16">
		<Grid.RowDefinitions>
			<RowDefinition Height="Auto"/>
			<RowDefinition Height="Auto"/>
			<RowDefinition Height="Auto"/>
			<RowDefinition Height="*"/>
			<RowDefinition Height="Auto"/>
		</Grid.RowDefinitions>
		
		<!-- API Configuration Header -->
		<GroupBox Grid.Row="0" Header="API Configuration" Foreground="White" BorderBrush="#FF404040" Margin="0,0,0,12">
			<TextBlock Text="Configure your Azure Cognitive Services API credentials below. Click 'Test Connection' to verify." 
					   Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="8"/>
		</GroupBox>
		
		<!-- Microsoft Azure Configuration -->
		<GroupBox Grid.Row="1" Header="Microsoft Azure Configuration" Foreground="White" BorderBrush="#FF404040" Margin="0,0,0,12">
			<Grid Margin="8">
				<Grid.ColumnDefinitions>
					<ColumnDefinition Width="Auto"/>
					<ColumnDefinition Width="*" MaxWidth="350"/>
					<ColumnDefinition Width="Auto"/>
					<ColumnDefinition Width="270"/>
				</Grid.ColumnDefinitions>
				<Grid.RowDefinitions>
					<RowDefinition Height="Auto"/>
					<RowDefinition Height="Auto"/>
				</Grid.RowDefinitions>
				
				<TextBlock Grid.Row="0" Grid.Column="0" Text="API Key:" Foreground="White" VerticalAlignment="Centre" Margin="0,0,8,8"/>
				<TextBox x:Name="ApiKeyBox" Grid.Row="0" Grid.Column="1" Margin="0,0,8,8" Height="24" VerticalContentAlignment="Centre"/>
				
				<TextBlock Grid.Row="0" Grid.Column="2" Text="Region:" Foreground="White" VerticalAlignment="Centre" Margin="0,0,8,8"/>
				<ComboBox x:Name="RegionCombo" Grid.Row="0" Grid.Column="3" Margin="0,0,0,8" Height="24"/>
				
				<TextBlock Grid.Row="1" Grid.Column="0" Text="Endpoint:" Foreground="White" VerticalAlignment="Centre" Margin="0,0,8,0"/>
				<TextBox x:Name="EndpointBox" Grid.Row="1" Grid.Column="1" Grid.ColumnSpan="3" Height="24" VerticalContentAlignment="Centre" IsReadOnly="True" Background="#FF2D2D30" Foreground="#FF808080"/>
			</Grid>
		</GroupBox>
		
		<!-- Connection Testing -->
		<GroupBox Grid.Row="2" Header="Connection Testing" Foreground="White" BorderBrush="#FF404040" Margin="0,0,0,12">
			<Grid Margin="8">
				<Grid.ColumnDefinitions>
					<ColumnDefinition Width="*"/>
					<ColumnDefinition Width="Auto"/>
				</Grid.ColumnDefinitions>
				
				<TextBlock x:Name="TestStatus" Grid.Column="0" Text="Ready to test connection..." Foreground="White" VerticalAlignment="Centre"/>
				<Button x:Name="TestConnectionBtn" Grid.Column="1" Content="🔌 Test Connection" Width="140" Height="28" 
						Background="#FF28A745" Foreground="White" BorderBrush="#FF1E7E34" BorderThickness="1"/>
			</Grid>
		</GroupBox>
		
		<!-- Setup Instructions -->
		<GroupBox Grid.Row="3" Header="Setup Instructions" Foreground="White" BorderBrush="#FF404040" Margin="0,0,0,12">
			<ScrollViewer VerticalScrollBarVisibility="Auto" Padding="8">
				<StackPanel>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">1. Sign in to the Azure Portal</Run>
						<LineBreak/>Visit portal.azure.com with your Microsoft account
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">2. Create a Cognitive Services resource</Run>
						<LineBreak/>Create a new 'Cognitive Services' resource or use an existing one
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">3. Navigate to Keys and Endpoint</Run>
						<LineBreak/>Go to your Cognitive Services resource → Keys and Endpoint
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">4. Copy the API Key</Run>
						<LineBreak/>Copy the 'Key 1' value and paste it into the API Key field above
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">5. Select your region</Run>
						<LineBreak/>Choose your preferred region from the dropdown
					</TextBlock>
					<TextBlock Foreground="#FFFFCC00" TextWrapping="Wrap" Margin="0,8,0,0" FontStyle="Italic">
						<Run FontWeight="SemiBold">Note:</Run> You'll need an active Azure subscription. The first 5 hours of speech synthesis are free each month.
					</TextBlock>
				</StackPanel>
			</ScrollViewer>
		</GroupBox>
		
		<!-- Buttons -->
		<StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Right">
			<Button x:Name="SaveButton" Content="Save &amp; Close" Width="100" Height="28" Background="#FF28A745" Foreground="White" Margin="0,0,8,0"/>
			<Button x:Name="CancelButton" Content="Cancel" Width="100" Height="28" Background="#FF6C757D" Foreground="White"/>
		</StackPanel>
	</Grid>
</Window>
"@
		
		try {
			$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
			$xamlReaderType = 'Windows.Markup.XamlReader' -as [type]
			$window = $xamlReaderType::Load($reader)
			$reader.Close()
			
			# Get controls
			$apiKeyBox = $window.FindName("ApiKeyBox")
			$regionCombo = $window.FindName("RegionCombo")
			$endpointBox = $window.FindName("EndpointBox")
			$testStatus = $window.FindName("TestStatus")
			$testBtn = $window.FindName("TestConnectionBtn")
			$saveBtn = $window.FindName("SaveButton")
			$cancelBtn = $window.FindName("CancelButton")
			
			# Populate regions - comprehensive Azure region list with descriptions
			$regions = @(
				@{ Id = 'australiacentral'; Name = 'Australia - Central' },
				@{ Id = 'australiaeast'; Name = 'Australia - East' },
				@{ Id = 'brazilsouth'; Name = 'Brazil - South' },
				@{ Id = 'canadacentral'; Name = 'Canada - Central' },
				@{ Id = 'canadaeast'; Name = 'Canada - East' },
				@{ Id = 'centralus'; Name = 'US - Central' },
				@{ Id = 'eastasia'; Name = 'Asia - East' },
				@{ Id = 'eastus'; Name = 'US - East' },
				@{ Id = 'eastus2'; Name = 'US - East 2' },
				@{ Id = 'francecentral'; Name = 'France - Central' },
				@{ Id = 'germanywestcentral'; Name = 'Germany - West Central' },
				@{ Id = 'japaneast'; Name = 'Japan - East' },
				@{ Id = 'japanwest'; Name = 'Japan - West' },
				@{ Id = 'koreacentral'; Name = 'Korea - Central' },
				@{ Id = 'northeurope'; Name = 'Europe - North' },
				@{ Id = 'southcentralus'; Name = 'US - South Central' },
				@{ Id = 'southeastasia'; Name = 'Asia - Southeast' },
				@{ Id = 'uksouth'; Name = 'UK - South' },
				@{ Id = 'ukwest'; Name = 'UK - West' },
				@{ Id = 'westeurope'; Name = 'Europe - West' },
				@{ Id = 'westus'; Name = 'US - West' },
				@{ Id = 'westus2'; Name = 'US - West 2' },
				@{ Id = 'westus3'; Name = 'US - West 3' }
			)
			foreach ($region in $regions) {
				$comboBoxItemType = 'System.Windows.Controls.ComboBoxItem' -as [type]
				$item = $comboBoxItemType::new()
				$item.Content = "$($region.Id) ($($region.Name))"
				$item.Tag = $region.Id
				$regionCombo.Items.Add($item) | Out-Null
			}
			
			# Load current values
			if ($currentConfig -and $currentConfig.ApiKey) {
				$apiKeyBox.Text = $currentConfig.ApiKey
			}
			if ($currentConfig -and $currentConfig.Datacenter) {
				# Find ComboBoxItem with matching Tag
				$matchingItem = $regionCombo.Items | Where-Object { $_.Tag -eq $currentConfig.Datacenter }
				if ($matchingItem) {
					$regionCombo.SelectedItem = $matchingItem
				} else {
					# Default to first item (uksouth)
					$regionCombo.SelectedIndex = 0
				}
			} else {
				# Default to uksouth - find it by Tag
				$uksouthItem = $regionCombo.Items | Where-Object { $_.Tag -eq 'uksouth' }
				if ($uksouthItem) {
					$regionCombo.SelectedItem = $uksouthItem
				} else {
					$regionCombo.SelectedIndex = 0
				}
			}
			
			# Update endpoint on region change
			$regionCombo.add_SelectionChanged({
				param($sender, $e)
				$combo = $sender
				$endpoint = $combo.Tag
				if ($combo.SelectedItem -and $combo.SelectedItem.Tag) {
					$endpoint.Text = "https://$($combo.SelectedItem.Tag).tts.speech.microsoft.com/cognitiveservices/v1"
				}
			})
			$regionCombo.Tag = $endpointBox
			
			# Trigger initial endpoint
			if ($regionCombo.SelectedItem -and $regionCombo.SelectedItem.Tag) {
				$endpointBox.Text = "https://$($regionCombo.SelectedItem.Tag).tts.speech.microsoft.com/cognitiveservices/v1"
			}
			
			# Test Connection handler - using closure to capture controls
			$testBtn.add_Click({
				$testStatus.Text = "Testing..."
				$testStatus.Foreground = "#FFFFFF00"
				
				$key = $apiKeyBox.Text
				$selectedItem = $regionCombo.SelectedItem
				$region = if ($selectedItem -and $selectedItem.Tag) { $selectedItem.Tag } else { "uksouth" }
				
				Add-ApplicationLog -Module "Azure" -Message "Test Connection clicked - Raw key length: $($key.Length), Region: $region" -Level "INFO"
				
				if ([string]::IsNullOrWhiteSpace($key)) {
					$testStatus.Text = "❌ Enter API Key"
					$testStatus.Foreground = "#FFFF0000"
					return
				}
				
				$testResult = Test-AzureCredentials -Config @{ ApiKey = $key; Datacenter = $region }
				Add-ApplicationLog -Module "Azure" -Message "Test result: $testResult" -Level "INFO"
				
				if ($testResult) {
					$testStatus.Text = "✓ Success!"
					$testStatus.Foreground = "#FF28A745"
				} else {
					$testStatus.Text = "❌ Failed"
					$testStatus.Foreground = "#FFFF0000"
				}
			}.GetNewClosure())
			
			# Save handler - using closure to capture window and controls
			$saveBtn.add_Click({
				$key = $apiKeyBox.Text
				$selectedItem = $regionCombo.SelectedItem
				$region = if ($selectedItem -and $selectedItem.Tag) { $selectedItem.Tag } else { "uksouth" }
				$endpoint = $endpointBox.Text
				
				if ([string]::IsNullOrWhiteSpace($key)) {
					$msgBoxType = 'System.Windows.MessageBox' -as [type]
					$msgBoxButton = 'System.Windows.MessageBoxButton' -as [type]
					$msgBoxImage = 'System.Windows.MessageBoxImage' -as [type]
					$msgBoxType::Show(
						"Please enter an API Key before saving.",
						"Validation",
						$msgBoxButton::OK,
						$msgBoxImage::Warning
					)
					return
				}
				
				# Store result in Tag
				$window.Tag = @{
					Success = $true
					ApiKey = $key
					Datacenter = $region
					Endpoint = $endpoint
				}
				$window.DialogueResult = $true
				$window.Close()
			}.GetNewClosure())
			
			# Cancel handler - using closure to capture window
			$cancelBtn.add_Click({
				$window.Tag = @{ Success = $false }
				$window.DialogueResult = $false
				$window.Close()
			}.GetNewClosure())
			
			# Show Dialogue and get result
			$DialogueResult = $window.ShowDialog()
			
			Add-ApplicationLog -Module "Azure" -Message "Dialogue closed, DialogueResult=$DialogueResult, Tag=$($window.Tag | ConvertTo-Json -Compress)" -Level "DEBUG"
			
			# Return result from Tag
			if ($window.Tag -and $window.Tag.Success) {
				Add-ApplicationLog -Module "Azure" -Message "Returning successful config: $($window.Tag | ConvertTo-Json -Compress)" -Level "INFO"
				return $window.Tag
			} else {
				Add-ApplicationLog -Module "Azure" -Message "Returning failed config" -Level "INFO"
				return @{ Success = $false }
			}
			
		} catch {
			Add-ApplicationLog -Module "Azure" -Message "Error in ShowConfigurationDialog: $($_.Exception.Message)" -Level "ERROR"
			return @{ Success = $false; Error = $_.Exception.Message }
		}
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
		if ([string]::IsNullOrWhiteSpace($Text) -or $Text.Length -gt 5000) {
			throw "Text must be between 1 and 5000 characters"
		}
		
		$endpoint = "https://$Region.tts.speech.microsoft.com/cognitiveservices/v1"
		
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
		
		Add-ApplicationLog -Module "Azure" -Message "Calling Azure TTS API" -Level "DEBUG"
		
		$response = Invoke-WebRequest -Uri $endpoint -Method Post -Headers $headers -Body $ssml -TimeoutSec 30
		
		if ($response.Content -is [byte[]] -and $response.Content.Length -gt 0) {
			[System.IO.File]::WriteAllBytes($OutputPath, $response.Content)
			Add-ApplicationLog -Module "Azure" -Message "Azure TTS: Generated audio file ($($response.Content.Length) bytes)" -Level "INFO"
			return @{ Success = $true; Message = "Generated successfully"; FileSize = $response.Content.Length }
		} else {
			throw "Invalid response from Azure TTS API"
		}
	}
	catch {
		$errorDetails = "Exception: $($_.Exception.Message)"
		
		# Try to extract detailed error response from Azure
		if ($_.Exception.Response) {
			try {
				$responseStream = $_.Exception.Response.GetResponseStream()
				$reader = New-Object System.IO.StreamReader($responseStream)
				$responseBody = $reader.ReadToEnd()
				$reader.Close()
				$responseStream.Close()
				
				if ($responseBody) {
					$errorDetails += " | Azure Response: $responseBody"
					
					# Try to parse JSON for cleaner logging
					try {
						$jsonError = $responseBody | ConvertFrom-Json
						if ($jsonError.error) {
							$errorDetails += " | Error Code: $($jsonError.error.code) | Message: $($jsonError.error.message)"
						}
					} catch {
						# If JSON parse fails, the raw response is already logged
					}
				}
			} catch {
				# If response reading fails, just log the exception
			}
		}
		
		Add-ApplicationLog -Module "Azure" -Message "Azure TTS failed: $errorDetails" -Level "ERROR"
		return @{ Success = $false; Message = $errorDetails; ErrorCode = $_.Exception.HResult }
	}
}

function New-AzureTTSProviderInstance {
	<#
	.SYNOPSIS
	Factory function to create an AzureTTSProvider instance
	#>
	param([hashtable]$config = $null)
	
	return [AzureTTSProvider]::new($config)
}

Export-ModuleMember -Function 'Invoke-AzureTTS', 'New-AzureTTSProviderInstance'

function Get-TTSProviderInfo {
    [PSCustomObject]@{
        Name        = 'MicrosoftAzure'
        DisplayName = 'Microsoft Azure'
        Description = 'Microsoft Azure Cognitive Services TTS'
    }
}
Export-ModuleMember -Function Get-TTSProviderInfo

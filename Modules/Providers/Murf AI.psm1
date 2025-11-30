# Exported provider-specific optimisation settings
$ProviderOptimisationSettings = @{
	MinPoolSize = 1
	MaxPoolSize = 3
	ConnectionTimeout = 30
}
Export-ModuleMember -Variable 'ProviderOptimisationSettings'
if (-not (Get-Module -Name 'Logging')) {
	Import-Module (Join-Path $PSScriptRoot '..\Logging.psm1')
}

# Load required assemblies for GUI Dialogues
Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue

function Test-MurfAICredentials {
	param(
		[hashtable]$Config
	)
	
	# Validate API Key format
	if (-not $Config.ApiKey -or $Config.ApiKey.Length -lt 20) {
		Add-ApplicationLog -Module "MurfAI" -Message "Murf AI Validate-MurfAICredentials: Invalid ApiKey format" -Level "WARNING"
		return $false
	}
	
	# Try to make an actual API call to verify credentials
	try {
		$apiKey = $Config.ApiKey.Trim()
		
		Add-ApplicationLog -Module "MurfAI" -Message "Testing Murf AI API key (length: $($apiKey.Length))" -Level "DEBUG"
		
		$headers = @{
			"api-key" = $apiKey
			"Accept" = "application/json"
		}
		$endpoint = "https://api.murf.ai/v1/speech/voices"
		
		$response = Invoke-RestMethod -Uri $endpoint -Method Get -Headers $headers -TimeoutSec 10 -ErrorAction Stop
		
		if ($response -and $response.Count -gt 0) {
			Add-ApplicationLog -Module "MurfAI" -Message "Murf AI credentials validated successfully - $($response.Count) voices available" -Level "INFO"
			return $true
		} else {
			Add-ApplicationLog -Module "MurfAI" -Message "Murf AI API responded but no voices found" -Level "WARNING"
			return $false
		}
	} catch {
		$statusCode = $_.Exception.Response.StatusCode.value__
		$errorDetails = $_.ErrorDetails.Message
		Add-ApplicationLog -Module "MurfAI" -Message "Murf AI credential validation failed: $($_.Exception.Message) | Status: $statusCode | Details: $errorDetails" -Level "ERROR"
		return $false
	}
}
Export-ModuleMember -Function 'Test-MurfAICredentials'

function Get-MurfAIVoiceOptions {
	<#
	.SYNOPSIS
		Returns voice configuration options for Murf AI TTS with dynamic voice retrieval
	.DESCRIPTION
		Fetches available voices from Murf AI API and provides lists of supported languages,
		formats, quality levels, models, and styles. Implements fallback to default values.
	.PARAMETER ApiKey
		Optional API key for live validation. If not provided, returns default values.
	.PARAMETER UseCache
		Whether to use cached results if available. Default is $true.
	.OUTPUTS
		Hashtable containing Voices, Languages, Formats, Quality, Models, Styles arrays and Defaults hashtable
	#>
	
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$false)]
		[string]$ApiKey,
		
		[Parameter(Mandatory=$false)]
		[bool]$UseCache = $true
	)
	
	# Fallback/default configuration
	$defaultOptions = @{
		Voices = @(
			# US English - Female
			'en-US-natalie',
			'en-US-julia',
			'en-US-lisa',
			'en-US-amelia',
			'en-US-sarah',
			'en-US-emma',
			'en-US-ashley',
			'en-US-olivia',
			'en-US-mia',
			'en-US-sophia',
			'en-US-charlotte',
			'en-US-harper',
			# US English - Male
			'en-US-ken',
			'en-US-terrell',
			'en-US-marcus',
			'en-US-brian',
			'en-US-david',
			'en-US-james',
			'en-US-michael',
			'en-US-william',
			'en-US-thomas',
			'en-US-daniel',
			'en-US-joseph',
			'en-US-christopher',
			# UK English
			'en-UK-matthew',
			'en-UK-olivia',
			'en-UK-charles',
			'en-UK-emily',
			'en-UK-george',
			'en-UK-lily',
			# Australian English
			'en-AU-isabella',
			'en-AU-jack',
			'en-AU-chloe',
			'en-AU-ryan',
			# Canadian English
			'en-CA-zoe',
			'en-CA-liam'
		)
		Languages = @(
			'en-US',
			'en-UK',
			'en-AU',
			'en-CA',
			'de-DE',
			'es-ES',
			'fr-FR',
			'it-IT',
			'pt-BR',
			'nl-NL',
			'ja-JP',
			'ko-KR'
		)
		Formats = @(
			'WAV',
			'MP3',
			'FLAC',
			'PCM',
			'OGG'
		)
		Quality = @(
			'Standard',
			'High'
		)
		Models = @(
			'GEN2',
			'FALCON'
		)
		Styles = @(
			'Conversational',
			'Promo',
			'Newscast',
			'Storytelling',
			'Calm'
		)
		Defaults = @{
			Voice = 'en-US-natalie'
			Language = 'en-UK'
			Format = 'MP3'
			Quality = 'High'
			Model = 'GEN2'
			Style = 'Conversational'
		}
		SupportsAdvanced = $true
	}
	
	# If no API key provided, return defaults
	if (-not $ApiKey) {
		Add-ApplicationLog -Module "MurfAI" -Message "No API key provided, returning default voice options" -Level "DEBUG"
		return $defaultOptions
	}
	
	# Try to fetch live voice data from Murf AI API
	try {
		Add-ApplicationLog -Module "MurfAI" -Message "Fetching available voices from Murf AI API" -Level "INFO"
		
		$headers = @{
			"Authorisation" = "Bearer $ApiKey"
			"Content-Type" = "application/json"
		}
		
		$response = Invoke-RestMethod -Uri "https://api.murf.ai/v1/speech/voices" -Method Get -Headers $headers -TimeoutSec 10 -ErrorAction Stop
		
		if ($response.data -and $response.data.Count -gt 0) {
			# Extract voice names/IDs from response
			$voiceNames = $response.data | ForEach-Object { $_.name } | Sort-Object
			Add-ApplicationLog -Module "MurfAI" -Message "Successfully retrieved $($voiceNames.Count) voices from API" -Level "INFO"
			$defaultOptions.Voices = @($voiceNames)
			
			# Extract unique language codes if available
			$languageCodes = $response.data | ForEach-Object { $_.language } | Select-Object -Unique | Sort-Object
			if ($languageCodes.Count -gt 0) {
				$defaultOptions.Languages = @($languageCodes)
			}
		} else {
			Add-ApplicationLog -Module "MurfAI" -Message "No voices found in API response, using defaults" -Level "WARNING"
		}
		
	} catch {
		Add-ApplicationLog -Module "MurfAI" -Message "Failed to fetch voices from API: $($_.Exception.Message). Using default values." -Level "WARNING"
	}
	
	return $defaultOptions
}
Export-ModuleMember -Function 'Get-MurfAIVoiceOptions'

# Base TTSProvider class
class TTSProvider {
	[string]$Name
	[hashtable]$Configuration
	[hashtable]$Capabilities
	
	TTSProvider() {
		$this.Configuration = @{}
		$this.Capabilities = @{}
	}
	
	[hashtable] ProcessTTS([string]$text, [hashtable]$options) {
		throw "ProcessTTS must be implemented by derived class"
	}
	
	[bool] ValidateConfiguration([hashtable]$config) {
		return $true
	}
	
	[array] GetAvailableVoices() {
		return @()
	}
	
	[hashtable] ShowConfigurationDialog([hashtable]$currentConfig) {
		return @{ Success = $false; Error = "Not implemented" }
	}
}

# Murf AI TTS Provider class
class MurfAITTSProvider : TTSProvider {
	MurfAITTSProvider([hashtable]$config = $null) {
		if ($null -eq $config) { $config = @{} }
		$this.Name = "Murf AI"
		$this.Configuration = $config
		$this.Capabilities = @{
			MaxTextLength = 10000
			SupportedFormats = @("mp3", "wav", "flac", "pcm", "ogg")
			SupportsSSML = $true
			SupportsNeural = $true
			RateLimits = @{
				RequestsPerMinute = 100
				CharactersPerMonth = 100000
			}
		}
	}
	
	[hashtable] ProcessTTS([string]$text, [hashtable]$options) {
		# Murf AI TTS processing logic
		if (-not $this.Configuration.ApiKey) {
			return @{ Success = $false; Error = "API Key not configured" }
		}
		
		try {
			$headers = @{
				"api-key" = $this.Configuration.ApiKey
				"Content-Type" = "application/json"
			}
			
			$voiceId = if ($options.VoiceId) { $options.VoiceId } else { "en-US-natalie" }
			$endpoint = "https://api.murf.ai/v1/speech/generate"
			
			$body = @{
				text = $text
				voiceId = $voiceId
				modelVersion = if ($options.Model) { $options.Model } else { "GEN2" }
				format = if ($options.Format) { $options.Format.ToUpper() } else { "MP3" }
				channelType = "MONO"
				sampleRate = 44100
			}
			
			if ($options.Style) {
				$body.style = $options.Style
			}
			
			if ($options.MultiNativeLocale) {
				$body.multiNativeLocale = $options.MultiNativeLocale
			}
			
			$jsonBody = $body | ConvertTo-Json
			
			$response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $jsonBody -TimeoutSec 30
			
			return @{ Success = $true; AudioData = $response }
		} catch {
			Add-ApplicationLog -Module "MurfAI" -Message "TTS processing failed: $($_.Exception.Message)" -Level "ERROR"
			return @{ Success = $false; Error = $_.Exception.Message }
		}
	}
	
	[bool] ValidateConfiguration([hashtable]$config) {
		if (-not $config.ContainsKey("ApiKey") -or [string]::IsNullOrWhiteSpace($config["ApiKey"])) {
			return $false
		}
		if ($config.ApiKey.Length -lt 20) {
			return $false
		}
		return $true
	}
	
	[array] GetAvailableVoices() {
		if (-not $this.Configuration.ApiKey) {
			return @()
		}
		
		try {
			$headers = @{
				"api-key" = $this.Configuration.ApiKey
			}
			$response = Invoke-RestMethod -Uri "https://api.murf.ai/v1/speech/voices" -Method Get -Headers $headers
			return $response | ForEach-Object { $_.voiceId }
		} catch {
			Add-ApplicationLog -Module "MurfAI" -Message "Failed to get voices: $($_.Exception.Message)" -Level "ERROR"
			return @('en-US-natalie', 'en-US-ken', 'en-US-terrell', 'en-US-julia', 'en-UK-matthew')
		}
	}
	
	[hashtable] ShowConfigurationDialog([hashtable]$currentConfig) {
		# Create Murf AI configuration Dialogue
		$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Murf AI Configuration" Height="580" Width="700"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#FF1E1E1E">
	<Grid Margin="10">
		<Grid.RowDefinitions>
			<RowDefinition Height="Auto"/>
			<RowDefinition Height="Auto"/>
			<RowDefinition Height="Auto"/>
			<RowDefinition Height="*"/>
			<RowDefinition Height="Auto"/>
		</Grid.RowDefinitions>
		
		<!-- API Configuration Header -->
		<GroupBox Grid.Row="0" Header="API Configuration" Foreground="White" BorderBrush="#FF404040" Margin="0,0,0,12">
			<TextBlock Text="Configure your Murf AI API key below. Click 'Test Connection' to verify." 
					   Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="8"/>
		</GroupBox>
		
		<!-- Murf AI Credentials Configuration -->
		<GroupBox Grid.Row="1" Header="Murf AI Credentials Configuration" Foreground="White" BorderBrush="#FF404040" Margin="0,0,0,12">
			<Grid Margin="8">
				<Grid.ColumnDefinitions>
					<ColumnDefinition Width="Auto"/>
					<ColumnDefinition Width="*"/>
				</Grid.ColumnDefinitions>
				<Grid.RowDefinitions>
					<RowDefinition Height="Auto"/>
				</Grid.RowDefinitions>
				
				<!-- API Key -->
				<TextBlock Grid.Row="0" Grid.Column="0" Text="API Key:" Foreground="White" VerticalAlignment="Centre" Margin="0,0,8,0"/>
				<PasswordBox x:Name="ApiKeyBox" Grid.Row="0" Grid.Column="1" Margin="0,0,0,0" Height="24" Padding="5"/>
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
						<Run FontWeight="SemiBold" Foreground="White">1. Sign up at Murf AI</Run>
						<LineBreak/>Visit https://murf.ai/ and create an account
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">2. Navigate to API Dashboard</Run>
						<LineBreak/>Go to https://murf.ai/api/dashboard to access your API credentials
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">3. Generate API Key</Run>
						<LineBreak/>Click 'Generate API Key' and copy the generated key
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">4. Copy and Paste</Run>
						<LineBreak/>Paste your API key in the field above, then click 'Test Connection'
					</TextBlock>
					<TextBlock Foreground="#FFFFCC00" TextWrapping="Wrap" Margin="0,8,0,0" FontStyle="Italic">
						<Run FontWeight="SemiBold">Note:</Run> Murf AI offers 150+ voices across 35+ languages with support for Gen2 and Falcon models. Check https://murf.ai/pricing for current rates and limits.
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
			$testBtn = $window.FindName("TestConnectionBtn")
			$testStatus = $window.FindName("TestStatus")
			$saveBtn = $window.FindName("SaveButton")
			$cancelBtn = $window.FindName("CancelButton")
			
			# Load current values
			if ($currentConfig -and $currentConfig.ApiKey) {
				$apiKeyBox.Password = $currentConfig.ApiKey
			}
			
			# Test Connection handler
			$testBtn.add_Click({
				$testStatus.Text = "Testing..."
				$testStatus.Foreground = "#FFFFFF00"
				
				$apiKey = $apiKeyBox.Password
				
				Add-ApplicationLog -Module "MurfAI" -Message "Test Connection clicked - APIKey length: $($apiKey.Length)" -Level "INFO"
				
				if ([string]::IsNullOrWhiteSpace($apiKey)) {
					$testStatus.Text = "Error - Enter API Key"
					$testStatus.Foreground = "#FFFF0000"
					return
				}
				
				$testResult = Test-MurfAICredentials -Config @{ ApiKey = $apiKey }
				Add-ApplicationLog -Module "MurfAI" -Message "Test result: $testResult" -Level "INFO"
				
				if ($testResult) {
					$testStatus.Text = "Success - Credentials Valid!"
					$testStatus.Foreground = "#FF28A745"
				} else {
					$testStatus.Text = "Error - Invalid Credentials"
					$testStatus.Foreground = "#FFFF0000"
				}
			}.GetNewClosure())
			
			# Save handler
			$saveBtn.add_Click({
				$apiKey = $apiKeyBox.Password
				
				if ([string]::IsNullOrWhiteSpace($apiKey)) {
					$msgBoxType = 'System.Windows.MessageBox' -as [type]
					$msgBoxType::Show("Please enter an API Key", "Validation Error", 0, 48)
					return
				}
				
				$window.Tag = @{
					Success = $true
					ApiKey = $apiKey
				}
				$window.DialogueResult = $true
				$window.Close()
			}.GetNewClosure())
			
			# Cancel handler
			$cancelBtn.add_Click({
				$window.Tag = @{ Success = $false }
				$window.DialogueResult = $false
				$window.Close()
			})
			
			# Show Dialogue
			$result = $window.ShowDialog()
			
			if ($window.Tag -and $window.Tag.Success) {
				return $window.Tag
			} else {
				return @{ Success = $false }
			}
			
		} catch {
			Add-ApplicationLog -Module "MurfAI" -Message "ShowConfigurationDialog error: $($_.Exception.Message)" -Level "ERROR"
			return @{ Success = $false; Error = $_.Exception.Message }
		}
	}
}

function New-MurfAITTSProviderInstance {
	<#
	.SYNOPSIS
	Factory function to create a MurfAITTSProvider instance
	#>
	param([hashtable]$config = $null)
	
	return [MurfAITTSProvider]::new($config)
}

Export-ModuleMember -Function 'New-MurfAITTSProviderInstance'

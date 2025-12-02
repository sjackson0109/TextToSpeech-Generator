# Exported provider-specific optimisation settings
$ProviderOptimisationSettings = @{
	MinPoolSize = 1
	MaxPoolSize = 3
	ConnectionTimeout = 30
}
Export-ModuleMember -Variable 'ProviderOptimisationSettings'
# ElevenLabs TTS Provider Module
# Provides Text-to-Speech synthesis via ElevenLabs API

# Load required assemblies for GUI Dialogues
Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue

if (-not (Get-Module -Name 'Logging')) {
	Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'Modules\Logging.psm1')
}

function Test-ElevenLabsCredentials {
	param(
		[hashtable]$Config
	)

	$apiKey = $Config.ApiKey.Trim()
	# Validate API Key format (ElevenLabs uses 32+ character keys, typically starting with 'sk_')
	if (-not $apiKey -or $apiKey.Length -lt 20) {
		Add-ApplicationLog -Module "ElevenLabs" -Message "ElevenLabs Validate-ElevenLabsCredentials: Invalid ApiKey format (length: $($apiKey.Length), value: $apiKey)" -Level "WARNING"
		return $false
	}

	# Try to make an actual API call to verify credentials
	try {
		Add-ApplicationLog -Module "ElevenLabs" -Message "Testing ElevenLabs API key (length: $($apiKey.Length))" -Level "DEBUG"

		$headers = @{
			"xi-api-key" = $apiKey
			"Accept" = "application/json"
		}
		$endpoint = "https://api.elevenlabs.io/v1/voices"

		$response = Invoke-RestMethod -Uri $endpoint -Method Get -Headers $headers -TimeoutSec 10 -ErrorAction Stop

		if ($response.voices) {
			Add-ApplicationLog -Module "ElevenLabs" -Message "ElevenLabs credentials validated successfully - $($response.voices.Count) voices available" -Level "INFO"
			return $true
		} else {
			Add-ApplicationLog -Module "ElevenLabs" -Message "ElevenLabs API responded but no voices found" -Level "WARNING"
			return $false
		}
	} catch {
		$statusCode = $_.Exception.Response.StatusCode.value__
		$errorDetails = $_.ErrorDetails.Message
		Add-ApplicationLog -Module "ElevenLabs" -Message "ElevenLabs credential validation failed: $($_.Exception.Message) | Status: $statusCode | Details: $errorDetails" -Level "ERROR"
		return $false
	}
}
Export-ModuleMember -Function 'Test-ElevenLabsCredentials'

function Get-ElevenLabsVoiceOptions {
	<#
	.SYNOPSIS
		Returns voice configuration options for ElevenLabs TTS with dynamic voice retrieval
	.DESCRIPTION
		Fetches available voices from ElevenLabs API and provides lists of supported languages,
		formats, and quality levels. Implements fallback to prevent excessive API calls.
	.PARAMETER ApiKey
		Optional API key for live validation. If not provided, returns default values.
	.PARAMETER UseCache
		Whether to use cached results if available. Default is $true.
	.OUTPUTS
		Hashtable containing Voices, Languages, Formats, Quality arrays and Defaults
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
			# Female Voices
			'Rachel',
			'Domi',
			'Bella',
			'Elli',
			'Charlotte',
			'Alice',
			'Lily',
			'Sarah',
			'Grace',
			'Emily',
			'Matilda',
			'Dorothy',
			'Freya',
			'Nicole',
			'Jessie',
			'Serena',
			'Glinda',
			# Male Voices
			'Antoni',
			'Josh',
			'Arnold',
			'Adam',
			'Sam',
			'Bill',
			'Brian',
			'Callum',
			'Charlie',
			'Chris',
			'Daniel',
			'Eric',
			'Ethan',
			'Fin',
			'George',
			'Harry',
			'James',
			'Jeremy',
			'Joseph',
			'Liam',
			'Michael',
			'Patrick',
			'Thomas'
		)
		DefaultVoice = 'Rachel'
		Languages = @(
			'en-US',
			'en-GB',
			'en-AU',
			'en-CA',
			'de-DE',
			'es-ES',
			'fr-FR',
			'it-IT',
			'pt-BR',
			'pl-PL',
			'nl-NL'
		)
		DefaultLanguage = 'en-GB'
		Formats = @(
			'MP3',
			'PCM'
		)
		DefaultFormat = 'MP3'
		Quality = @(
			'Standard',
			'High'
		)
		DefaultQuality = 'High'
		SupportsAdvanced = $true
	}
	
	# If no API key provided, return defaults
	if (-not $ApiKey) {
		Add-ApplicationLog -Module "ElevenLabs" -Message "No API key provided, returning default voice options" -Level "DEBUG"
		return $defaultOptions
	}
	
	# Try to fetch live voice data from ElevenLabs API
	try {
		Add-ApplicationLog -Module "ElevenLabs" -Message "Fetching available voices from ElevenLabs API" -Level "INFO"
		
		$headers = @{
			"xi-api-key" = $ApiKey
			"Accept" = "application/json"
		}
		
		$response = Invoke-RestMethod -Uri "https://api.elevenlabs.io/v1/voices" -Method Get -Headers $headers -TimeoutSec 10
		
		if ($response.voices -and $response.voices.Count -gt 0) {
			$voiceNames = $response.voices | Select-Object -ExpandProperty name | Sort-Object
			Add-ApplicationLog -Module "ElevenLabs" -Message "Successfully retrieved $($voiceNames.Count) voices from API" -Level "INFO"
			$defaultOptions.Voices = @($voiceNames)
		} else {
			Add-ApplicationLog -Module "ElevenLabs" -Message "No voices found in API response, using defaults" -Level "WARNING"
		}
		
	} catch {
		Add-ApplicationLog -Module "ElevenLabs" -Message "Failed to fetch voices from API: $($_.Exception.Message). Using default values." -Level "WARNING"
	}
	
	return $defaultOptions
}
Export-ModuleMember -Function 'Get-ElevenLabsVoiceOptions'

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

# ElevenLabs TTS Provider class
class ElevenLabsTTSProvider : TTSProvider {
	ElevenLabsTTSProvider([hashtable]$config = $null) {
		if ($null -eq $config) { $config = @{} }
		$this.Name = "ElevenLabs"
		$this.Configuration = $config
		$this.Capabilities = @{
			MaxTextLength = 5000
			SupportedFormats = @("mp3", "pcm")
			SupportsSSML = $false
			SupportsNeural = $true
			RateLimits = @{
				RequestsPerMinute = 100
				CharactersPerMonth = 10000
			}
		}
	}
	
	[hashtable] ProcessTTS([string]$text, [hashtable]$options) {
		# ElevenLabs TTS processing logic
		if (-not $this.Configuration.ApiKey) {
			return @{ Success = $false; Error = "API Key not configured" }
		}
		
		try {
			$headers = @{
				"xi-api-key" = $this.Configuration.ApiKey
				"Content-Type" = "application/json"
			}
			
			$voiceId = if ($options.VoiceId) { $options.VoiceId } else { "21m00Tcm4TlvDq8ikWAM" } # Default: Rachel
			$endpoint = "https://api.elevenlabs.io/v1/text-to-speech/$voiceId"
			
			$body = @{
				text = $text
				model_id = if ($options.Quality -eq 'High') { "eleven_multilingual_v2" } else { "eleven_monolingual_v1" }
				voice_settings = @{
					stability = 0.5
					similarity_boost = 0.75
				}
			} | ConvertTo-Json
			
			$response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers $headers -Body $body -TimeoutSec 30
			
			return @{ Success = $true; AudioData = $response }
		} catch {
			Add-ApplicationLog -Module "ElevenLabs" -Message "TTS processing failed: $($_.Exception.Message)" -Level "ERROR"
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
				"xi-api-key" = $this.Configuration.ApiKey
			}
			$response = Invoke-RestMethod -Uri "https://api.elevenlabs.io/v1/voices" -Method Get -Headers $headers
			return $response.voices | ForEach-Object { $_.name }
		} catch {
			Add-ApplicationLog -Module "ElevenLabs" -Message "Failed to get voices: $($_.Exception.Message)" -Level "ERROR"
			return @('Rachel', 'Domi', 'Bella', 'Antoni', 'Elli', 'Josh', 'Arnold', 'Adam', 'Sam')
		}
	}
	
	[hashtable] ShowConfigurationDialog([hashtable]$currentConfig) {
		# Create ElevenLabs configuration Dialogue
		$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
		xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ElevenLabs Configuration" Height="591" Width="700"
        WindowStartupLocation="CenterScreen"
        Background="#FF1E1E1E"
		ResizeMode="CanResize">
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
			<TextBlock Text="Configure your ElevenLabs API key below. Click 'Test Connection' to verify." 
					   Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="8"/>
		</GroupBox>
		
		<!-- ElevenLabs Credentials Configuration -->
		<GroupBox Grid.Row="1" Header="ElevenLabs Credentials Configuration" Foreground="White" BorderBrush="#FF404040" Margin="0,0,0,12">
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
						<Run FontWeight="SemiBold" Foreground="White">1. Sign up at ElevenLabs</Run>
						<LineBreak/>Visit https://elevenlabs.io/ and create a free account
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">2. Navigate to Developers</Run>
						<LineBreak/>Click on 'Developers' in the lower left menu
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">3. Create API Key</Run>
						<LineBreak/>Select 'API Keys', click 'Create Key' and enable these permissions:
						<LineBreak/>• Text to Speech: Access
						<LineBreak/>• Voices: Read
						<LineBreak/>• User: Read (optional but recommended)
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">4. Copy and Paste</Run>
						<LineBreak/>Copy the generated API key and paste it in the field above, then click 'Test Connection'
					</TextBlock>
					<TextBlock Foreground="#FFFFCC00" TextWrapping="Wrap" Margin="0,8,0,0" FontStyle="Italic">
						<Run FontWeight="SemiBold">Note:</Run> Free tier includes 10,000 characters/month. Check https://elevenlabs.io/pricing for current rates and limits.
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
				
				Add-ApplicationLog -Module "ElevenLabs" -Message "Test Connection clicked - APIKey length: $($apiKey.Length)" -Level "INFO"
				
				if ([string]::IsNullOrWhiteSpace($apiKey)) {
					$testStatus.Text = "Error - Enter API Key"
					$testStatus.Foreground = "#FFFF0000"
					return
				}
				
				$testResult = Test-ElevenLabsCredentials -Config @{ ApiKey = $apiKey }
				Add-ApplicationLog -Module "ElevenLabs" -Message "Test result: $testResult" -Level "INFO"
				
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
			Add-ApplicationLog -Module "ElevenLabs" -Message "ShowConfigurationDialog error: $($_.Exception.Message)" -Level "ERROR"
			return @{ Success = $false; Error = $_.Exception.Message }
		}
	}
}

function New-ElevenLabsTTSProviderInstance {
	<#
	.SYNOPSIS
	Factory function to create an ElevenLabsTTSProvider instance
	#>
	param([hashtable]$config = $null)
	
	return [ElevenLabsTTSProvider]::new($config)
}

Export-ModuleMember -Function 'New-ElevenLabsTTSProviderInstance'

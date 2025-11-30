# Exported provider-specific optimisation settings
$ProviderOptimisationSettings = @{
	MinPoolSize = 1
	MaxPoolSize = 5
	ConnectionTimeout = 30
}
Export-ModuleMember -Variable 'ProviderOptimisationSettings'
if (-not (Get-Module -Name 'Logging')) {
	Import-Module (Join-Path $PSScriptRoot '..\Logging.psm1')
}

# Load required assemblies for GUI Dialogues
Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue

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
        Add-ApplicationLog -Message "GoogleCloud Validate-GoogleCloudCredentials: Invalid ApiKey format" -Level "WARNING"
        return $false
    }
    
    # Try to make a simple API call to validate credentials
    try {
        $endpoint = "https://texttospeech.googleapis.com/v1/voices?key=$($Config.ApiKey)"
        $response = Invoke-RestMethod -Uri $endpoint -Method Get -TimeoutSec 10 -ErrorAction Stop
        
        if ($response.voices -and $response.voices.Count -gt 0) {
            Add-ApplicationLog -Message "GoogleCloud credentials validated successfully - $($response.voices.Count) voices available" -Level "INFO"
            return $true
        } else {
            Add-ApplicationLog -Message "GoogleCloud API responded but no voices found" -Level "WARNING"
            return $false
        }
    } catch {
        Add-ApplicationLog -Message "GoogleCloud credential validation failed: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}
Export-ModuleMember -Function 'Test-GoogleCloudCredentials', 'Get-GoogleCloudProviderSetupFields', 'Get-GoogleCloudVoiceOptions', 'Invoke-GoogleCloudTTS', 'Get-GoogleCloudCapabilities'

function Get-GoogleCloudVoiceOptions {
	<#
	.SYNOPSIS
		Returns voice configuration options for Google Cloud Text-to-Speech with dynamic voice retrieval
	.DESCRIPTION
		Fetches available voices from Google Cloud TTS API and provides lists of supported languages,
		formats, and quality levels. Implements fallback to default values if API call fails.
	.PARAMETER ApiKey
		Optional API key for live validation. If not provided, returns default values.
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
		[bool]$UseCache = $true
	)
	
	# Fallback/default configuration
	$defaultOptions = @{
		Voices = @(
			# US English - Neural2 (Latest)
			'en-US-Neural2-A',
			'en-US-Neural2-C',
			'en-US-Neural2-D',
			'en-US-Neural2-E',
			'en-US-Neural2-F',
			'en-US-Neural2-G',
			'en-US-Neural2-H',
			'en-US-Neural2-I',
			'en-US-Neural2-J',
			# US English - Wavenet
			'en-US-Wavenet-A',
			'en-US-Wavenet-B',
			'en-US-Wavenet-C',
			'en-US-Wavenet-D',
			'en-US-Wavenet-E',
			'en-US-Wavenet-F',
			'en-US-Wavenet-G',
			'en-US-Wavenet-H',
			'en-US-Wavenet-I',
			'en-US-Wavenet-J',
			# US English - Studio (Highest Quality)
			'en-US-Studio-M',
			'en-US-Studio-O',
			# UK English - Neural2
			'en-GB-Neural2-A',
			'en-GB-Neural2-B',
			'en-GB-Neural2-C',
			'en-GB-Neural2-D',
			'en-GB-Neural2-F',
			# UK English - Wavenet
			'en-GB-Wavenet-A',
			'en-GB-Wavenet-B',
			'en-GB-Wavenet-C',
			'en-GB-Wavenet-D',
			'en-GB-Wavenet-F',
			# Australian English
			'en-AU-Neural2-A',
			'en-AU-Neural2-B',
			'en-AU-Neural2-C',
			'en-AU-Neural2-D',
			'en-AU-Wavenet-A',
			'en-AU-Wavenet-B',
			'en-AU-Wavenet-C',
			'en-AU-Wavenet-D',
			# Indian English
			'en-IN-Neural2-A',
			'en-IN-Neural2-B',
			'en-IN-Neural2-C',
			'en-IN-Neural2-D',
			'en-IN-Wavenet-A',
			'en-IN-Wavenet-B',
			'en-IN-Wavenet-C',
			'en-IN-Wavenet-D'
		)
		Languages = @(
			'en-US',
			'en-GB',
			'en-AU',
			'fr-FR',
			'de-DE',
			'es-ES',
			'it-IT',
			'pt-BR',
			'ja-JP',
			'ko-KR',
			'zh-CN',
			'hi-IN'
		)
		Formats = @(
			'MP3',
			'LINEAR16',
			'OGG_OPUS',
			'MULAW',
			'ALAW'
		)
		Quality = @(
			'Neural2',
			'Wavenet',
			'Standard'
		)
		Defaults = @{
			Voice = 'en-US-Neural2-A'
			Language = 'en-US'
			Format = 'MP3'
			Quality = 'Neural2'
		}
		SupportsAdvanced = $true
	}
	
	# If no API key provided, return defaults
	if (-not $ApiKey) {
		Add-ApplicationLog -Module "GoogleCloud" -Message "No API key provided, returning default voice options" -Level "DEBUG"
		return $defaultOptions
	}
	
	# Try to fetch live voice data from Google Cloud TTS API
	try {
		Add-ApplicationLog -Module "GoogleCloud" -Message "Fetching available voices from Google Cloud TTS API" -Level "INFO"
		
		# Google Cloud supports both Bearer token and API key in query string
		# Using API key in query string as simpler approach
		$uri = "https://texttospeech.googleapis.com/v1/voices?key=$ApiKey"
		
		$response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 10 -ErrorAction Stop
		
		if ($response.voices -and $response.voices.Count -gt 0) {
			# Extract voice names from response
			$voiceNames = $response.voices | ForEach-Object { $_.name } | Sort-Object
			Add-ApplicationLog -Module "GoogleCloud" -Message "Successfully retrieved $($voiceNames.Count) voices from API" -Level "INFO"
			$defaultOptions.Voices = @($voiceNames)
			
			# Extract unique language codes
			$languageCodes = $response.voices | ForEach-Object { $_.languageCodes } | Select-Object -Unique | Sort-Object
			if ($languageCodes.Count -gt 0) {
				$defaultOptions.Languages = @($languageCodes)
			}
		} else {
			Add-ApplicationLog -Module "GoogleCloud" -Message "No voices found in API response, using defaults" -Level "WARNING"
		}
		
	} catch {
		Add-ApplicationLog -Module "GoogleCloud" -Message "Failed to fetch voices from API: $($_.Exception.Message). Using default values." -Level "WARNING"
	}
	
	return $defaultOptions
}
Export-ModuleMember -Function 'Get-GoogleCloudVoiceOptions'
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
    $apiKeyLabel.Text = "API Key:"
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
    $GuidanceText.Text = "Enter your Google Cloud TTS API Key and Language. See docs/providers/Google Cloud.md for details."
    $Window.SaveAndClose.add_Click{
        $GUI.Window.GC_APIKey.Text = $apiKeyBox.Text
        $GUI.Window.GC_Language.SelectedItem = $languageBox.Text
        Add-ApplicationLog -Module "GoogleCloud" -Message "Google Cloud TTS setup saved" -Level "INFO"
        $Window.DialogueueueueueueResult = $true
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
            Add-ApplicationLog -Message "GoogleCloud GetAvailableVoices: No config, returning empty list" -Level "DEBUG"
            return @()
        }
        try {
            # ...actual API call...
            return @('en-US-Wavenet-D') # Placeholder
        } catch {
            Add-ApplicationLog -Message "GoogleCloud GetAvailableVoices: Exception $($_.Exception.Message)" -Level "ERROR"
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
                Add-ApplicationLog -Message "GoogleCloud GetAvailableVoices: No config or env var, returning demo voices" -Level "DEBUG"
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
                Add-ApplicationLog -Message "GoogleCloud GetAvailableVoices: Exception $($_.Exception.Message)" -Level "ERROR"
                return @('en-US-Wavenet-D', 'en-US-Wavenet-F', 'en-GB-Wavenet-B')
            }
        }

	[hashtable] ShowConfigurationDialog([hashtable]$currentConfig) {
		# Create Google Cloud TTS configuration Dialogue
		$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Google Cloud Text-to-Speech Configuration" Height="620" Width="700"
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
			<TextBlock Text="Configure your Google Cloud service account API key below. Click 'Test Connection' to verify." 
					   Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="8"/>
		</GroupBox>
		
		<!-- Google Cloud Credentials Configuration -->
		<GroupBox Grid.Row="1" Header="Google Cloud Credentials Configuration" Foreground="White" BorderBrush="#FF404040" Margin="0,0,0,12">
			<Grid Margin="8">
				<Grid.ColumnDefinitions>
					<ColumnDefinition Width="Auto"/>
					<ColumnDefinition Width="*" MaxWidth="350"/>
					<ColumnDefinition Width="Auto"/>
					<ColumnDefinition Width="210"/>
				</Grid.ColumnDefinitions>
				<Grid.RowDefinitions>
					<RowDefinition Height="Auto"/>
					<RowDefinition Height="Auto"/>
				</Grid.RowDefinitions>
				
				<!-- API Key -->
				<TextBlock Grid.Row="0" Grid.Column="0" Text="API Key:" Foreground="White" VerticalAlignment="Centre" Margin="0,0,8,8"/>
				<PasswordBox x:Name="ApiKeyBox" Grid.Row="0" Grid.Column="1" Margin="0,0,8,8" Height="24" Padding="5"/>
				
				<!-- Region -->
				<TextBlock Grid.Row="0" Grid.Column="2" Text="Region:" Foreground="White" VerticalAlignment="Centre" Margin="0,0,8,8"/>
				<ComboBox x:Name="RegionCombo" Grid.Row="0" Grid.Column="3" Margin="0,0,0,8" Height="24"/>
				
				<!-- Project ID -->
				<TextBlock Grid.Row="1" Grid.Column="0" Text="Project ID:" Foreground="White" VerticalAlignment="Centre" Margin="0,0,8,0"/>
				<TextBox x:Name="ProjectIdBox" Grid.Row="1" Grid.Column="1" Grid.ColumnSpan="3" Margin="0,0,0,0" Height="24" VerticalContentAlignment="Centre"/>
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
						<Run FontWeight="SemiBold" Foreground="White">1. Sign in to Google Cloud Console</Run>
						<LineBreak/>Visit console.cloud.google.com and sign in with your Google account
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">2. Create or Select Project</Run>
						<LineBreak/>Create a new project or select an existing one from the dropdown
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">3. Enable Cloud Text-to-Speech API</Run>
						<LineBreak/>Navigate to APIs &amp; Services, enable 'Cloud Text-to-Speech API'
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">4. Create API Key</Run>
						<LineBreak/>Go to Credentials, click 'Create Credentials', select 'API Key'
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">5. Copy Credentials</Run>
						<LineBreak/>Copy the API Key and your Project ID (found in project settings)
					</TextBlock>
					<TextBlock Foreground="#FFFFCC00" TextWrapping="Wrap" Margin="0,8,0,0" FontStyle="Italic">
						<Run FontWeight="SemiBold">Note:</Run> Google Cloud TTS pricing applies. Check cloud.google.com/text-to-speech/pricing for current rates.
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
			$projectIdBox = $window.FindName("ProjectIdBox")
			$regionCombo = $window.FindName("RegionCombo")
			$testBtn = $window.FindName("TestConnectionBtn")
			$testStatus = $window.FindName("TestStatus")
			$saveBtn = $window.FindName("SaveButton")
			$cancelBtn = $window.FindName("CancelButton")
			
			# Populate regions - comprehensive Google Cloud region list with descriptions
			$regions = @(
				@{ Id = 'global'; Name = 'Global (Multi-Region)' },
				@{ Id = 'us-central1'; Name = 'US Central - Iowa' },
				@{ Id = 'us-east1'; Name = 'US East - South Carolina' },
				@{ Id = 'us-east4'; Name = 'US East - Northern Virginia' },
				@{ Id = 'us-east5'; Name = 'US East - Columbus' },
				@{ Id = 'us-south1'; Name = 'US South - Dallas' },
				@{ Id = 'us-west1'; Name = 'US West - Oregon' },
				@{ Id = 'us-west2'; Name = 'US West - Los Angeles' },
				@{ Id = 'us-west3'; Name = 'US West - Salt Lake City' },
				@{ Id = 'us-west4'; Name = 'US West - Las Vegas' },
				@{ Id = 'northamerica-northeast1'; Name = 'North America - Montreal' },
				@{ Id = 'northamerica-northeast2'; Name = 'North America - Toronto' },
				@{ Id = 'southamerica-east1'; Name = 'South America - Sao Paulo' },
				@{ Id = 'southamerica-west1'; Name = 'South America - Santiago' },
				@{ Id = 'europe-central2'; Name = 'Europe - Warsaw' },
				@{ Id = 'europe-north1'; Name = 'Europe - Finland' },
				@{ Id = 'europe-southwest1'; Name = 'Europe - Madrid' },
				@{ Id = 'europe-west1'; Name = 'Europe - Belgium' },
				@{ Id = 'europe-west2'; Name = 'Europe - London' },
				@{ Id = 'europe-west3'; Name = 'Europe - Frankfurt' },
				@{ Id = 'europe-west4'; Name = 'Europe - Netherlands' },
				@{ Id = 'europe-west6'; Name = 'Europe - Zurich' },
				@{ Id = 'europe-west8'; Name = 'Europe - Milan' },
				@{ Id = 'europe-west9'; Name = 'Europe - Paris' },
				@{ Id = 'europe-west10'; Name = 'Europe - Berlin' },
				@{ Id = 'europe-west12'; Name = 'Europe - Turin' },
				@{ Id = 'asia-east1'; Name = 'Asia - Taiwan' },
				@{ Id = 'asia-east2'; Name = 'Asia - Hong Kong' },
				@{ Id = 'asia-northeast1'; Name = 'Asia - Tokyo' },
				@{ Id = 'asia-northeast2'; Name = 'Asia - Osaka' },
				@{ Id = 'asia-northeast3'; Name = 'Asia - Seoul' },
				@{ Id = 'asia-south1'; Name = 'Asia - Mumbai' },
				@{ Id = 'asia-south2'; Name = 'Asia - Delhi' },
				@{ Id = 'asia-southeast1'; Name = 'Asia - Singapore' },
				@{ Id = 'asia-southeast2'; Name = 'Asia - Jakarta' },
				@{ Id = 'australia-southeast1'; Name = 'Australia - Sydney' },
				@{ Id = 'australia-southeast2'; Name = 'Australia - Melbourne' },
				@{ Id = 'me-central1'; Name = 'Middle East - Doha' },
				@{ Id = 'me-central2'; Name = 'Middle East - Dammam' },
				@{ Id = 'me-west1'; Name = 'Middle East - Tel Aviv' },
				@{ Id = 'africa-south1'; Name = 'Africa - Johannesburg' }
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
				$apiKeyBox.Password = $currentConfig.ApiKey
			}
			if ($currentConfig -and $currentConfig.ProjectID) {
				$projectIdBox.Text = $currentConfig.ProjectID
			}
			if ($currentConfig -and $currentConfig.Region) {
				# Find ComboBoxItem with matching Tag
				$matchingItem = $regionCombo.Items | Where-Object { $_.Tag -eq $currentConfig.Region }
				if ($matchingItem) {
					$regionCombo.SelectedItem = $matchingItem
				} else {
					# Default to europe-west2 (London)
					$defaultItem = $regionCombo.Items | Where-Object { $_.Tag -eq 'europe-west2' }
					if ($defaultItem) {
						$regionCombo.SelectedItem = $defaultItem
					} else {
						$regionCombo.SelectedIndex = 0
					}
				}
			} else {
				# Default to europe-west2 (London)
				$defaultItem = $regionCombo.Items | Where-Object { $_.Tag -eq 'europe-west2' }
				if ($defaultItem) {
					$regionCombo.SelectedItem = $defaultItem
				} else {
					$regionCombo.SelectedIndex = 0
				}
			}
			
			# Test Connection handler
			$testBtn.add_Click({
				$testStatus.Text = "Testing..."
				$testStatus.Foreground = "#FFFFFF00"
				
				$apiKey = $apiKeyBox.Password
				$projectId = $projectIdBox.Text
				$selectedItem = $regionCombo.SelectedItem
				$region = if ($selectedItem -and $selectedItem.Tag) { $selectedItem.Tag } else { "global" }
				
				Add-ApplicationLog -Module "GoogleCloud" -Message "Test Connection clicked - APIKey length: $($apiKey.Length), ProjectID: $projectId, Region: $region" -Level "INFO"
				
				if ([string]::IsNullOrWhiteSpace($apiKey)) {
					$testStatus.Text = "❌ Enter API Key"
					$testStatus.Foreground = "#FFFF0000"
					return
				}
				
				$testResult = Test-GoogleCloudCredentials -Config @{ ApiKey = $apiKey; ProjectID = $projectId; Region = $region }
				Add-ApplicationLog -Module "GoogleCloud" -Message "Test result: $testResult" -Level "INFO"
				
				if ($testResult) {
					$testStatus.Text = "✓ Credentials Valid!"
					$testStatus.Foreground = "#FF28A745"
				} else {
					$testStatus.Text = "❌ Invalid Credentials"
					$testStatus.Foreground = "#FFFF0000"
				}
			}.GetNewClosure())
			
			# Save handler
			$saveBtn.add_Click({
				$apiKey = $apiKeyBox.Password
				$projectId = $projectIdBox.Text
				$selectedItem = $regionCombo.SelectedItem
				$region = if ($selectedItem -and $selectedItem.Tag) { $selectedItem.Tag } else { "global" }
				
				if ([string]::IsNullOrWhiteSpace($apiKey)) {
					$msgBoxType = 'System.Windows.MessageBox' -as [type]
					$msgBoxType::Show("Please enter an API Key", "Validation Error", 0, 48)
					return
				}
				
				$window.Tag = @{
					Success = $true
					ApiKey = $apiKey
					ProjectID = $projectId
					Region = $region
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
			Add-ApplicationLog -Module "GoogleCloud" -Message "ShowConfigurationDialog error: $($_.Exception.Message)" -Level "ERROR"
			return @{ Success = $false; Error = $_.Exception.Message }
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
            'User-Agent' = 'TextToSpeech Generator'
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

Note: See docs/providers/Google Cloud.md for full instructions.
"@
    }
}

function New-GoogleCloudTTSProviderInstance {
	<#
	.SYNOPSIS
	Factory function to create a GoogleCloudTTSProvider instance
	#>
	param([hashtable]$config = $null)
	
	return [GoogleCloudTTSProvider]::new($config)
}

Export-ModuleMember -Function 'Invoke-GoogleCloudTTS', 'New-GoogleCloudTTSProviderInstance'

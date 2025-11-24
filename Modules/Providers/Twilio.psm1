if (-not (Get-Module -Name 'Logging')) {
	Import-Module (Join-Path $PSScriptRoot '..\Logging.psm1')
}

# Load required assemblies for GUI dialogs
Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue

function Test-TwilioCredentials {
	param(
		[hashtable]$Config
	)
	
	# Validate Account SID format (starts with AC, 34 characters total)
	if (-not $Config.AccountSID -or $Config.AccountSID -notmatch '^AC[a-f0-9]{32}$') {
		Add-ApplicationLog -Module "Twilio" -Message "Twilio Validate-TwilioCredentials: Invalid AccountSID format" -Level "WARNING"
		return $false
	}
	
	# Validate Auth Token (32 characters, alphanumeric)
	if (-not $Config.AuthToken -or $Config.AuthToken.Length -ne 32) {
		Add-ApplicationLog -Module "Twilio" -Message "Twilio Validate-TwilioCredentials: Invalid AuthToken format" -Level "WARNING"
		return $false
	}
	
	# Try to make an actual API call to verify credentials
	try {
		$accountSid = $Config.AccountSID
		$authToken = $Config.AuthToken
		$endpoint = "https://api.twilio.com/2010-04-01/Accounts/$accountSid.json"
		$credentials = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${accountSid}:${authToken}"))
		$headers = @{ 'Authorization' = "Basic $credentials" }
		
		$response = Invoke-RestMethod -Uri $endpoint -Method Get -Headers $headers -TimeoutSec 10 -ErrorAction Stop
		
		if ($response.sid -eq $accountSid) {
			Add-ApplicationLog -Module "Twilio" -Message "Twilio credentials validated successfully" -Level "INFO"
			return $true
		} else {
			Add-ApplicationLog -Module "Twilio" -Message "Twilio API responded but account mismatch" -Level "WARNING"
			return $false
		}
	} catch {
		Add-ApplicationLog -Module "Twilio" -Message "Twilio credential validation failed: $($_.Exception.Message)" -Level "ERROR"
		return $false
	}
}
Export-ModuleMember -Function 'Test-TwilioCredentials'

function Get-TwilioVoiceOptions {
	<#
	.SYNOPSIS
		Returns voice configuration options for Twilio TTS (uses static voice list)
	.DESCRIPTION
		Provides arrays of voices, languages, formats, and quality levels supported by Twilio.
		Note: Twilio uses TwiML with Polly voices and does not provide a voice listing API.
		Returns comprehensive static list of available Polly voices and legacy voices.
	.PARAMETER AccountSID
		Optional Twilio Account SID. Included for API consistency but not used for voice retrieval.
	.PARAMETER AuthToken
		Optional Twilio Auth Token. Included for API consistency but not used for voice retrieval.
	.PARAMETER UseCache
		Whether to use cached results if available. Default is $true.
	.OUTPUTS
		Hashtable containing Voices, Languages, Formats, Quality arrays and Defaults hashtable
	.NOTES
		Twilio TTS uses TwiML markup language and does not expose a voice listing REST API.
		Voice selection is done via TwiML <Say> element with voice attribute.
	#>
	
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$false)]
		[string]$AccountSID,
		
		[Parameter(Mandatory=$false)]
		[string]$AuthToken,
		
		[Parameter(Mandatory=$false)]
		[bool]$UseCache = $true
	)
	
	# Twilio uses static voice list - no API retrieval available
	Add-ApplicationLog -Module "Twilio" -Message "Twilio uses static Polly voice list (no voice listing API available)" -Level "DEBUG"
	
	return @{
		Voices = @(
			# US English - Neural
			'Polly.Joanna',
			'Polly.Matthew',
			'Polly.Ivy',
			'Polly.Justin',
			'Polly.Kendra',
			'Polly.Kimberly',
			'Polly.Salli',
			'Polly.Joey',
			'Polly.Kevin',
			'Polly.Ruth',
			'Polly.Stephen',
			'Polly.Gregory',
			'Polly.Danielle',
			'Polly.Aria',
			# US English - Generative
			'Polly.Joanna-Generative',
			'Polly.Matthew-Generative',
			'Polly.Ruth-Generative',
			# UK English
			'Polly.Amy',
			'Polly.Brian',
			'Polly.Emma',
			'Polly.Arthur',
			# Australian English
			'Polly.Nicole',
			'Polly.Russell',
			'Polly.Olivia',
			# Indian English
			'Polly.Raveena',
			'Polly.Aditi',
			'Polly.Kajal',
			# South African English
			'Polly.Ayanda',
			# Welsh English
			'Polly.Geraint',
			# Google Voices
			'Google.en-US-Chirp3-HD-Aoede',
			'Google.en-US-Chirp3-HD-Charon',
			'Google.en-GB-Chirp3-HD-Kore',
			'Google.en-GB-Chirp3-HD-Puck',
			# Twilio Classic
			'alice',
			'man',
			'woman'
		)
		Languages = @(
			'en-US',
			'en-GB',
			'en-AU',
			'en-IN',
			'es-ES',
			'fr-FR',
			'de-DE',
			'it-IT',
			'pt-BR',
			'ja-JP'
		)
		Formats = @(
			'MP3',
			'WAV',
			'OGG'
		)
		Quality = @(
			'Standard',
			'Neural'
		)
		Defaults = @{
			Voice = 'Polly.Joanna'
			Language = 'en-US'
			Format = 'MP3'
			Quality = 'Neural'
		}
		SupportsAdvanced = $true
	}
}
Export-ModuleMember -Function 'Get-TwilioVoiceOptions'

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

# Twilio TTS Provider class
class TwilioTTSProvider : TTSProvider {
	TwilioTTSProvider([hashtable]$config = $null) {
		if ($null -eq $config) { $config = @{} }
		$this.Name = "Twilio"
		$this.Configuration = $config
		$this.Capabilities = @{
			MaxTextLength = 4000
			SupportedFormats = @("mp3", "wav")
			SupportsSSML = $true
			Premium = $false
			RateLimits = @{
				RequestsPerMinute = 60
				CharactersPerMonth = 1000000
			}
		}
	}
	
	[hashtable] ProcessTTS([string]$text, [hashtable]$options) {
		# Twilio TTS processing logic would go here
		return @{ Success = $true; Message = "Twilio TTS processing not fully implemented" }
	}
	
	[bool] ValidateConfiguration([hashtable]$config) {
		$required = @("AccountSID", "AuthToken")
		foreach ($key in $required) {
			if (-not $config.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($config[$key])) {
				return $false
			}
		}
		if ($config.AccountSID -notmatch '^AC[a-f0-9]{32}$') {
			return $false
		}
		return $true
	}
	
	[array] GetAvailableVoices() {
		$accountSid = $this.Configuration["AccountSID"]
		$authToken = $this.Configuration["AuthToken"]
		
		if (-not $accountSid) { $accountSid = $env:TWILIO_ACCOUNT_SID }
		if (-not $authToken) { $authToken = $env:TWILIO_AUTH_TOKEN }
		
		if (-not $accountSid -or -not $authToken) {
			Add-ApplicationLog -Module "Twilio" -Message "Twilio GetAvailableVoices: No config or env vars, returning demo voices" -Level "DEBUG"
			return @('Polly.Joanna', 'Polly.Matthew', 'alice', 'man', 'woman')
		}
		
		try {
			$endpoint = "https://api.twilio.com/2010-04-01/Accounts/$accountSid/Voices.json"
			$credentials = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${accountSid}:${authToken}"))
			$headers = @{ 'Authorization' = "Basic $credentials" }
			$response = Invoke-RestMethod -Uri $endpoint -Method Get -Headers $headers -TimeoutSec 10
			
			if ($response.voices) {
				return $response.voices | ForEach-Object { $_.name }
			} else {
				return @('Polly.Joanna', 'Polly.Matthew', 'alice', 'man', 'woman')
			}
		} catch {
			Add-ApplicationLog -Module "Twilio" -Message "Twilio GetAvailableVoices: Exception $($_.Exception.Message)" -Level "ERROR"
			return @('Polly.Joanna', 'Polly.Matthew', 'alice', 'man', 'woman')
		}
	}
	
	[hashtable] ShowConfigurationDialog([hashtable]$currentConfig) {
		# Create Twilio configuration dialog
		$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Twilio Configuration" Height="580" Width="700"
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
			<TextBlock Text="Configure your Twilio account credentials below. Click 'Test Connection' to verify." 
					   Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="8"/>
		</GroupBox>
		
		<!-- Twilio Credentials Configuration -->
		<GroupBox Grid.Row="1" Header="Twilio Credentials Configuration" Foreground="White" BorderBrush="#FF404040" Margin="0,0,0,12">
			<Grid Margin="8">
				<Grid.ColumnDefinitions>
					<ColumnDefinition Width="Auto"/>
					<ColumnDefinition Width="*"/>
				</Grid.ColumnDefinitions>
				<Grid.RowDefinitions>
					<RowDefinition Height="Auto"/>
					<RowDefinition Height="Auto"/>
				</Grid.RowDefinitions>
				
				<!-- Account SID -->
				<TextBlock Grid.Row="0" Grid.Column="0" Text="Account SID:" Foreground="White" VerticalAlignment="Center" Margin="0,0,8,8"/>
				<TextBox x:Name="AccountSidBox" Grid.Row="0" Grid.Column="1" Margin="0,0,0,8" Height="24" VerticalContentAlignment="Center"/>
				
				<!-- Auth Token -->
				<TextBlock Grid.Row="1" Grid.Column="0" Text="Auth Token:" Foreground="White" VerticalAlignment="Center" Margin="0,0,8,0"/>
				<PasswordBox x:Name="AuthTokenBox" Grid.Row="1" Grid.Column="1" Margin="0,0,0,0" Height="24" Padding="5"/>
			</Grid>
		</GroupBox>
		
		<!-- Connection Testing -->
		<GroupBox Grid.Row="2" Header="Connection Testing" Foreground="White" BorderBrush="#FF404040" Margin="0,0,0,12">
			<Grid Margin="8">
				<Grid.ColumnDefinitions>
					<ColumnDefinition Width="*"/>
					<ColumnDefinition Width="Auto"/>
				</Grid.ColumnDefinitions>
				
				<TextBlock x:Name="TestStatus" Grid.Column="0" Text="Ready to test connection..." Foreground="White" VerticalAlignment="Center"/>
				<Button x:Name="TestConnectionBtn" Grid.Column="1" Content="🔌 Test Connection" Width="140" Height="28" 
						Background="#FF28A745" Foreground="White" BorderBrush="#FF1E7E34" BorderThickness="1"/>
			</Grid>
		</GroupBox>
		
		<!-- Setup Instructions -->
		<GroupBox Grid.Row="3" Header="Setup Instructions" Foreground="White" BorderBrush="#FF404040" Margin="0,0,0,12">
			<ScrollViewer VerticalScrollBarVisibility="Auto" Padding="8">
				<StackPanel>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">1. Sign in to Twilio Console</Run>
						<LineBreak/>Visit console.twilio.com and sign in with your Twilio account
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">2. Locate Account Credentials</Run>
						<LineBreak/>On the dashboard, find your Account SID and Auth Token
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">3. Copy Credentials</Run>
						<LineBreak/>Copy both the Account SID (starts with 'AC') and Auth Token
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">4. Paste Above</Run>
						<LineBreak/>Enter your credentials in the fields above
					</TextBlock>
					<TextBlock Foreground="#FFFFCC00" TextWrapping="Wrap" Margin="0,8,0,0" FontStyle="Italic">
						<Run FontWeight="SemiBold">Note:</Run> Twilio pricing applies. Check twilio.com/pricing for current rates.
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
			$accountSidBox = $window.FindName("AccountSidBox")
			$authTokenBox = $window.FindName("AuthTokenBox")
			$testBtn = $window.FindName("TestConnectionBtn")
			$testStatus = $window.FindName("TestStatus")
			$saveBtn = $window.FindName("SaveButton")
			$cancelBtn = $window.FindName("CancelButton")
			
			# Load current values
			if ($currentConfig -and $currentConfig.AccountSID) {
				$accountSidBox.Text = $currentConfig.AccountSID
			}
			if ($currentConfig -and $currentConfig.AuthToken) {
				$authTokenBox.Password = $currentConfig.AuthToken
			}
			
			# Test Connection handler
			$testBtn.add_Click({
				$testStatus.Text = "Testing..."
				$testStatus.Foreground = "#FFFFFF00"
				
				$accountSid = $accountSidBox.Text
				$authToken = $authTokenBox.Password
				
				Add-ApplicationLog -Module "Twilio" -Message "Test Connection clicked - AccountSID length: $($accountSid.Length)" -Level "INFO"
				
				if ([string]::IsNullOrWhiteSpace($accountSid) -or [string]::IsNullOrWhiteSpace($authToken)) {
					$testStatus.Text = "❌ Enter credentials"
					$testStatus.Foreground = "#FFFF0000"
					return
				}
				
				$testResult = Test-TwilioCredentials -Config @{ AccountSID = $accountSid; AuthToken = $authToken }
				Add-ApplicationLog -Module "Twilio" -Message "Test result: $testResult" -Level "INFO"
				
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
				$accountSid = $accountSidBox.Text
				$authToken = $authTokenBox.Password
				
				if ([string]::IsNullOrWhiteSpace($accountSid) -or [string]::IsNullOrWhiteSpace($authToken)) {
					$msgBoxType = 'System.Windows.MessageBox' -as [type]
					$msgBoxType::Show("Please enter both Account SID and Auth Token", "Validation Error", 0, 48)
					return
				}
				
				$window.Tag = @{
					Success = $true
					AccountSID = $accountSid
					AuthToken = $authToken
				}
				$window.DialogResult = $true
				$window.Close()
			}.GetNewClosure())
			
			# Cancel handler
			$cancelBtn.add_Click({
				$window.Tag = @{ Success = $false }
				$window.DialogResult = $false
				$window.Close()
			})
			
			# Show dialog
			$result = $window.ShowDialog()
			
			if ($window.Tag -and $window.Tag.Success) {
				return $window.Tag
			} else {
				return @{ Success = $false }
			}
			
		} catch {
			Add-ApplicationLog -Module "Twilio" -Message "ShowConfigurationDialog error: $($_.Exception.Message)" -Level "ERROR"
			return @{ Success = $false; Error = $_.Exception.Message }
		}
	}
}

function New-TwilioTTSProviderInstance {
	<#
	.SYNOPSIS
	Factory function to create a TwilioTTSProvider instance
	#>
	param([hashtable]$config = $null)
	
	return [TwilioTTSProvider]::new($config)
}

Export-ModuleMember -Function 'New-TwilioTTSProviderInstance'

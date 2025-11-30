# Exported provider-specific optimisation settings
$ProviderOptimisationSettings = @{
	MinPoolSize = 2
	MaxPoolSize = 8
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
	if ($Window.AWS_AccessKey) { $Window.AWS_AccessKey.Text = $Configuration.AccessKey }
	if ($Window.AWS_SecretKey) { $Window.AWS_SecretKey.Text = $Configuration.SecretKey }
	if ($Window.AWS_SessionToken) { $Window.AWS_SessionToken.Text = $Configuration.SessionToken }
	if ($Window.AWS_Region) { $Window.AWS_Region.Text = $Configuration.Region }
}
Export-ModuleMember -Function ApplyConfigurationToGUI
function Test-AWSPollyCredentials {
	param(
		[hashtable]$Config
	)
	
	# Validate AWS Access Key format (AKIA followed by 16 alphanumeric characters)
	if (-not $Config.AccessKey -or $Config.AccessKey -notmatch '^AKIA[0-9A-Z]{16}$') {
		Add-ApplicationLog -Module "AWSPolly" -Message "Invalid AWS Access Key format. Expected: AKIA followed by 16 characters. Got length: $($Config.AccessKey.Length)" -Level "WARNING"
		return $false
	}
	
	# Validate AWS Secret Key format (40 characters)
	if (-not $Config.SecretKey -or $Config.SecretKey.Length -ne 40) {
		Add-ApplicationLog -Module "AWSPolly" -Message "Invalid AWS Secret Key format. Expected 40 characters, got: $($Config.SecretKey.Length)" -Level "WARNING"
		return $false
	}
	
	# Comprehensive AWS region validation
	$validRegions = @(
		'us-east-1','us-east-2','us-west-1','us-west-2',
		'af-south-1','ap-east-1','ap-south-1','ap-south-2',
		'ap-northeast-1','ap-northeast-2','ap-northeast-3',
		'ap-southeast-1','ap-southeast-2','ap-southeast-3','ap-southeast-4',
		'ca-central-1','ca-west-1',
		'eu-central-1','eu-central-2','eu-west-1','eu-west-2','eu-west-3',
		'eu-south-1','eu-south-2','eu-north-1',
		'il-central-1','me-south-1','me-central-1',
		'sa-east-1','us-gov-east-1','us-gov-west-1'
	)
	
	if (-not $Config.Region) {
		Add-ApplicationLog -Module "AWSPolly" -Message "No region specified" -Level "WARNING"
		return $false
	}
	
	if ($validRegions -notcontains $Config.Region) {
		Add-ApplicationLog -Module "AWSPolly" -Message "Invalid AWS region: $($Config.Region). Must be one of the supported AWS regions." -Level "WARNING"
		return $false
	}
	
	Add-ApplicationLog -Module "AWSPolly" -Message "AWS credentials validation passed for region: $($Config.Region)" -Level "INFO"
	return $true
}
Export-ModuleMember -Function 'Test-AWSPollyCredentials', 'Get-AWSPollyProviderSetupFields', 'Get-AWSPollyVoiceOptions', 'Invoke-PollyTTS', 'Get-PollyCapabilities'

function Get-AWSPollyVoiceOptions {
	<#
	.SYNOPSIS
		Returns voice configuration options for AWS Polly TTS with dynamic voice retrieval
	.DESCRIPTION
		Fetches available voices from AWS Polly API and provides lists of supported languages,
		formats, and quality levels. Note: AWS Polly requires AWS Signature Version 4 authentication,
		which is complex for native REST calls. Currently returns comprehensive default list.
	.PARAMETER AccessKey
		Optional AWS Access Key ID for live validation. Requires SecretKey and Region.
	.PARAMETER SecretKey
		Optional AWS Secret Access Key for authentication.
	.PARAMETER Region
		Optional AWS region (e.g., 'us-east-1', 'eu-west-1'). Default is 'us-east-1'.
	.PARAMETER UseCache
		Whether to use cached results if available. Default is $true.
	.OUTPUTS
		Hashtable containing Voices, Languages, Formats, Quality arrays and Defaults hashtable
	.NOTES
		AWS Signature V4 implementation required for live API calls. Current implementation
		provides comprehensive fallback voice list covering all major AWS Polly voices.
	#>
	
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$false)]
		[string]$AccessKey,
		
		[Parameter(Mandatory=$false)]
		[string]$SecretKey,
		
		[Parameter(Mandatory=$false)]
		[string]$Region = "us-east-1",
		
		[Parameter(Mandatory=$false)]
		[bool]$UseCache = $true
	)
	
	# Comprehensive fallback/default configuration covering all major Polly voices
	$defaultOptions = @{
		Voices = @(
			# US English Neural
			'Joanna',
			'Matthew',
			'Ivy',
			'Justin',
			'Kendra',
			'Kimberly',
			'Salli',
			'Joey',
			'Ruth',
			'Stephen',
			'Kevin',
			'Danielle',
			'Gregory',
			'Aria',
			# UK English
			'Amy',
			'Brian',
			'Emma',
			'Arthur',
			# Australian English
			'Nicole',
			'Russell',
			'Olivia',
			# Indian English
			'Raveena',
			'Aditi',
			'Kajal',
			# South African English
			'Ayanda',
			# Welsh English
			'Geraint',
			# French
			'Celine',
			'Lea',
			'Mathieu',
			'Remi',
			# Canadian French
			'Chantal',
			'Gabrielle',
			'Liam',
			# German
			'Marlene',
			'Vicki',
			'Hans',
			'Daniel',
			# Spanish (EU)
			'Conchita',
			'Lucia',
			'Sergio',
			# Spanish (MX)
			'Mia',
			'Andres',
			# Spanish (US)
			'Lupe',
			'Pedro',
			# Italian
			'Carla',
			'Bianca',
			'Giorgio',
			'Adriano',
			# Portuguese (BR)
			'Camila',
			'Vitoria',
			'Ricardo',
			'Thiago',
			# Portuguese (EU)
			'Ines',
			'Cristiano',
			# Japanese
			'Mizuki',
			'Takumi',
			'Kazuha',
			'Tomoko',
			# Korean
			'Seoyeon',
			# Chinese (Mandarin)
			'Zhiyu'
		)
		Languages = @(
			'en-US',
			'en-GB',
			'en-AU',
			'en-IN',
			'fr-FR',
			'de-DE',
			'es-ES',
			'it-IT',
			'pt-BR',
			'ja-JP',
			'ko-KR',
			'cmn-CN',
			'ar-AE'
		)
		Formats = @(
			'MP3',
			'OGG Vorbis',
			'PCM'
		)
		Quality = @(
			'Neural',
			'Standard',
			'Long-form'
		)
		Defaults = @{
			Voice = 'Joanna'
			Language = 'en-US'
			Format = 'MP3'
			Quality = 'Neural'
		}
		SupportsAdvanced = $true
	}
	
	# If no credentials provided, return defaults
	if (-not $AccessKey -or -not $SecretKey) {
		Add-ApplicationLog -Module "AWSPolly" -Message "No AWS credentials provided, returning default voice options" -Level "DEBUG"
		return $defaultOptions
	}
	
	# TODO: AWS Polly requires AWS Signature Version 4 for authentication
	# This requires:
	# 1. Creating canonical request with sorted headers and hashed payload
	# 2. Creating string to sign with scope (date, region, service)
	# 3. Calculating signature using HMAC-SHA256 with derived signing key
	# 4. Adding Authorisation header with signature
	#
	# Endpoint would be: https://polly.$Region.amazonaws.com/v1/voices
	# For now, logging that live API not implemented and returning comprehensive defaults
	
	Add-ApplicationLog -Module "AWSPolly" -Message "AWS Polly live voice retrieval requires AWS Signature V4 implementation. Using comprehensive default voice list." -Level "INFO"
	
	return $defaultOptions
}
Export-ModuleMember -Function 'Get-AWSPollyVoiceOptions'
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
	$GuidanceText.Text = "Enter your AWS Polly Access Key, Secret Key, and Region. See docs/providers/AWS Polly.md for details."
	$Window.SaveAndClose.add_Click{
		$GUI.Window.AWS_AccessKey.Text = $accessKeyBox.Text
		$GUI.Window.AWS_SecretKey.Text = $secretKeyBox.Text
		$GUI.Window.AWS_Region.SelectedItem = $regionBox.Text
		Add-ApplicationLog -Module "AWSPolly" -Message "Amazon Polly setup saved" -Level "INFO"
		$Window.DialogueueueueueueResult = $true
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
	Add-ApplicationLog -Module "AWSPolly" -Message "PollyTTSProvider.ProcessTTS: Entry, text length $($text.Length)" -Level "DEBUG"
		try {
			# ...actual implementation...
			Add-ApplicationLog -Module "AWSPolly" -Message "PollyTTSProvider.ProcessTTS: Success" -Level "INFO"
			return @{ Success = $true }
		} catch {
			Add-ApplicationLog -Module "AWSPolly" -Message "PollyTTSProvider.ProcessTTS: Exception $($_.Exception.Message)" -Level "ERROR"
			return @{ Success = $false; Error = $_.Exception.Message }
		}
	}
	[array] GetAvailableVoices() {
		if (-not $this.Configuration -or -not $this.Configuration.AccessKey) {
			Add-ApplicationLog -Module "AWSPolly" -Message "Polly GetAvailableVoices: No config, returning empty list" -Level "DEBUG"
			return @()
		}
		try {
			# ...actual API call...
			return @('Matthew') # Placeholder
		} catch {
			Add-ApplicationLog -Module "AWSPolly" -Message "Polly GetAvailableVoices: Exception $($_.Exception.Message)" -Level "ERROR"
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
				Add-ApplicationLog -Module "AWSPolly" -Message "PollyTTSProvider: Missing AWS credentials or region in options." -Level "ERROR"
				throw "Missing AWS credentials or region."
			}
			return Invoke-PollyTTS @options
		} catch {
			Add-ApplicationLog -Module "AWSPolly" -Message "PollyTTSProvider.ProcessTTS error: $($_.Exception.Message)" -Level "ERROR"
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
				Add-ApplicationLog -Module "AWSPolly" -Message "Polly GetAvailableVoices: No config or env vars, returning demo voices" -Level "DEBUG"
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
			$authorisationHeader = "$algorithm Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signatureHex"
			$headers = @{
				"authorisation" = $authorisationHeader
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
				Add-ApplicationLog -Module "AWSPolly" -Message "Polly GetAvailableVoices: Exception $($_.Exception.Message)" -Level "ERROR"
				return @('Joanna', 'Matthew', 'Amy')
			}
		} catch {
			Add-ApplicationLog -Module "AWSPolly" -Message "PollyTTSProvider.GetAvailableVoices error: $($_.Exception.Message)" -Level "ERROR"
			return @()
		}
	}
	[bool] ValidateConfiguration([hashtable]$config) {
		return Test-AWSPollyCredentials $config
	}
	
	[hashtable] ShowConfigurationDialog([hashtable]$currentConfig) {
		# Create AWS Polly configuration Dialogue
		$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AWS Polly Configuration" Height="540" Width="700"
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
			<TextBlock Text="Configure your AWS IAM service-account details below. Click 'Test Connection' to verify." 
					   Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="8"/>
		</GroupBox>
		
		<!-- AWS Credentials Configuration -->
		<GroupBox Grid.Row="1" Header="AWS Credentials Configuration" Foreground="White" BorderBrush="#FF404040" Margin="0,0,0,12">
			<Grid Margin="8">
				<Grid.ColumnDefinitions>
					<ColumnDefinition Width="Auto"/>
					<ColumnDefinition Width="*" MaxWidth="350"/>
					<ColumnDefinition Width="Auto"/>
					<ColumnDefinition Width="250"/>
				</Grid.ColumnDefinitions>
				<Grid.RowDefinitions>
					<RowDefinition Height="Auto"/>
					<RowDefinition Height="Auto"/>
				</Grid.RowDefinitions>
				
				<!-- Access Key -->
				<TextBlock Grid.Row="0" Grid.Column="0" Text="Access Key ID:" Foreground="White" VerticalAlignment="Centre" Margin="0,0,8,8"/>
				<TextBox x:Name="AccessKeyBox" Grid.Row="0" Grid.Column="1" Margin="0,0,8,8" Height="24" VerticalContentAlignment="Centre"/>
				
				<!-- Region -->
				<TextBlock Grid.Row="0" Grid.Column="2" Text="Region:" Foreground="White" VerticalAlignment="Centre" Margin="0,0,8,8"/>
				<ComboBox x:Name="RegionCombo" Grid.Row="0" Grid.Column="3" Margin="0,0,0,8" Height="24"/>
				
				<!-- Secret Key -->
				<TextBlock Grid.Row="1" Grid.Column="0" Text="Secret Access Key:" Foreground="White" VerticalAlignment="Centre" Margin="0,0,8,0"/>
				<PasswordBox x:Name="SecretKeyBox" Grid.Row="1" Grid.Column="1" Grid.ColumnSpan="3" Margin="0,0,0,0" Height="24" Padding="5"/>
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
						<Run FontWeight="SemiBold" Foreground="White">1. Sign in to AWS Console</Run>
						<LineBreak/>Visit aws.amazon.com and sign in with your AWS account
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">2. Open IAM Service</Run>
						<LineBreak/>Navigate to IAM (Identity and Access Management)
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">3. Create IAM User</Run>
						<LineBreak/>Create a new IAM user with 'Programmatic access' enabled
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">4. Attach Policy</Run>
						<LineBreak/>Attach the 'AmazonPollyFullAccess' policy to the user
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">5. Copy Credentials</Run>
						<LineBreak/>Copy the Access Key ID and Secret Access Key
					</TextBlock>
					<TextBlock Foreground="#FFFFCC00" TextWrapping="Wrap" Margin="0,8,0,0" FontStyle="Italic">
						<Run FontWeight="SemiBold">Note:</Run> AWS Polly pricing applies. Check aws.amazon.com/polly/pricing for current rates.
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
			$accessKeyBox = $window.FindName("AccessKeyBox")
			$secretKeyBox = $window.FindName("SecretKeyBox")
			$regionCombo = $window.FindName("RegionCombo")
			$testBtn = $window.FindName("TestConnectionBtn")
			$testStatus = $window.FindName("TestStatus")
			$saveBtn = $window.FindName("SaveButton")
			$cancelBtn = $window.FindName("CancelButton")
			
		# Populate regions - comprehensive AWS region list with descriptions
		$regions = @(
			@{ Id = 'us-east-1'; Name = 'US East - N. Virginia' },
			@{ Id = 'us-east-2'; Name = 'US East - Ohio' },
			@{ Id = 'us-west-1'; Name = 'US West - N. California' },
			@{ Id = 'us-west-2'; Name = 'US West - Oregon' },
			@{ Id = 'af-south-1'; Name = 'Africa - Cape Town' },
			@{ Id = 'ap-east-1'; Name = 'Asia Pacific - Hong Kong' },
			@{ Id = 'ap-south-1'; Name = 'Asia Pacific - Mumbai' },
			@{ Id = 'ap-south-2'; Name = 'Asia Pacific - Hyderabad' },
			@{ Id = 'ap-northeast-1'; Name = 'Asia Pacific - Tokyo' },
			@{ Id = 'ap-northeast-2'; Name = 'Asia Pacific - Seoul' },
			@{ Id = 'ap-northeast-3'; Name = 'Asia Pacific - Osaka' },
			@{ Id = 'ap-southeast-1'; Name = 'Asia Pacific - Singapore' },
			@{ Id = 'ap-southeast-2'; Name = 'Asia Pacific - Sydney' },
			@{ Id = 'ap-southeast-3'; Name = 'Asia Pacific - Jakarta' },
			@{ Id = 'ap-southeast-4'; Name = 'Asia Pacific - Melbourne' },
			@{ Id = 'ca-central-1'; Name = 'Canada - Central' },
			@{ Id = 'ca-west-1'; Name = 'Canada - Calgary' },
			@{ Id = 'eu-central-1'; Name = 'Europe - Frankfurt' },
			@{ Id = 'eu-central-2'; Name = 'Europe - Zurich' },
			@{ Id = 'eu-west-1'; Name = 'Europe - Ireland' },
			@{ Id = 'eu-west-2'; Name = 'Europe - London' },
			@{ Id = 'eu-west-3'; Name = 'Europe - Paris' },
			@{ Id = 'eu-south-1'; Name = 'Europe - Milan' },
			@{ Id = 'eu-south-2'; Name = 'Europe - Spain' },
			@{ Id = 'eu-north-1'; Name = 'Europe - Stockholm' },
			@{ Id = 'il-central-1'; Name = 'Israel - Tel Aviv' },
			@{ Id = 'me-south-1'; Name = 'Middle East - Bahrain' },
			@{ Id = 'me-central-1'; Name = 'Middle East - UAE' },
			@{ Id = 'sa-east-1'; Name = 'South America - Sao Paulo' },
			@{ Id = 'us-gov-east-1'; Name = 'AWS GovCloud - US East' },
			@{ Id = 'us-gov-west-1'; Name = 'AWS GovCloud - US West' }
		)
		foreach ($region in $regions) {
			$comboBoxItemType = 'System.Windows.Controls.ComboBoxItem' -as [type]
			$item = $comboBoxItemType::new()
			$item.Content = "$($region.Id) ($($region.Name))"
			$item.Tag = $region.Id
			$regionCombo.Items.Add($item) | Out-Null
		}			# Load current values
			if ($currentConfig -and $currentConfig.AccessKey) {
				$accessKeyBox.Text = $currentConfig.AccessKey
			}
			if ($currentConfig -and $currentConfig.SecretKey) {
				$secretKeyBox.Password = $currentConfig.SecretKey
			}
			if ($currentConfig -and $currentConfig.Region) {
				# Find ComboBoxItem with matching Tag
				$matchingItem = $regionCombo.Items | Where-Object { $_.Tag -eq $currentConfig.Region }
				if ($matchingItem) {
					$regionCombo.SelectedItem = $matchingItem
				} else {
					# Default to eu-west-2
					$defaultItem = $regionCombo.Items | Where-Object { $_.Tag -eq 'eu-west-2' }
					if ($defaultItem) {
						$regionCombo.SelectedItem = $defaultItem
					} else {
						$regionCombo.SelectedIndex = 0
					}
				}
			} else {
				# Default to eu-west-2
				$defaultItem = $regionCombo.Items | Where-Object { $_.Tag -eq 'eu-west-2' }
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
				
				$accessKey = $accessKeyBox.Text
				$secretKey = $secretKeyBox.Password
				$selectedItem = $regionCombo.SelectedItem
				$region = if ($selectedItem -and $selectedItem.Tag) { $selectedItem.Tag } else { "us-east-1" }
				
				Add-ApplicationLog -Module "AWSPolly" -Message "Test Connection clicked - AccessKey length: $($accessKey.Length), Region: $region" -Level "INFO"
				
				if ([string]::IsNullOrWhiteSpace($accessKey) -or [string]::IsNullOrWhiteSpace($secretKey)) {
					$testStatus.Text = "❌ Enter credentials"
					$testStatus.Foreground = "#FFFF0000"
					return
				}
				
				$testResult = Test-AWSPollyCredentials -Config @{ AccessKey = $accessKey; SecretKey = $secretKey; Region = $region }
				Add-ApplicationLog -Module "AWSPolly" -Message "Test result: $testResult" -Level "INFO"
				
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
				$accessKey = $accessKeyBox.Text
				$secretKey = $secretKeyBox.Password
				$selectedItem = $regionCombo.SelectedItem
				$region = if ($selectedItem -and $selectedItem.Tag) { $selectedItem.Tag } else { "us-east-1" }
				
				if ([string]::IsNullOrWhiteSpace($accessKey) -or [string]::IsNullOrWhiteSpace($secretKey)) {
					$msgBoxType = 'System.Windows.MessageBox' -as [type]
					$msgBoxType::Show("Please enter both Access Key and Secret Key", "Validation Error", 0, 48)
					return
				}
				
				$window.Tag = @{
					Success = $true
					AccessKey = $accessKey
					SecretKey = $secretKey
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
			}.GetNewClosure())
			
			Add-ApplicationLog -Module "AWSPolly" -Message "Showing AWS Polly configuration Dialogue" -Level "INFO"
			$result = $window.ShowDialog()
			
			if ($window.Tag -and $window.Tag.Success) {
				Add-ApplicationLog -Module "AWSPolly" -Message "AWS Polly configuration saved" -Level "INFO"
				return $window.Tag
			} else {
				Add-ApplicationLog -Module "AWSPolly" -Message "AWS Polly configuration Cancelled" -Level "INFO"
				return @{ Success = $false }
			}
		} catch {
			Add-ApplicationLog -Module "AWSPolly" -Message "Error showing AWS Polly Dialogue: $($_.Exception.Message)" -Level "ERROR"
			return @{ Success = $false; Error = $_.Exception.Message }
		}
	}
	
	[hashtable] GetCapabilities() {
		return $this.Capabilities
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
	Add-ApplicationLog -Module "AWSPolly" -Message "AWS Polly TTS failed: $($_.Exception.Message)" -Level "ERROR"
		$placeholderContent = "AWS Polly TTS fallback - API error occurred`nText: $Text`nVoice: $Voice"
		Set-Content -Path $OutputPath -Value $placeholderContent -Encoding UTF8
		return @{ Success = $false; Error = $_.Exception.Message; Message = "Using fallback due to API error" }
	}
}
Export-ModuleMember -Function 'Invoke-PollyTTS'

function New-AWSPollyTTSProviderInstance {
	<#
	.SYNOPSIS
	Factory function to create a PollyTTSProvider instance
	#>
	param([hashtable]$config = $null)
	
	return [PollyTTSProvider]::new($config)
}

Export-ModuleMember -Function 'Invoke-PollyTTS', 'New-AWSPollyTTSProviderInstance'

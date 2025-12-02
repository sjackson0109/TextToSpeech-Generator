# Exported provider-specific optimisation settings
$ProviderOptimisationSettings = @{
    MinPoolSize = 1
    MaxPoolSize = 5
    ConnectionTimeout = 30
}
Export-ModuleMember -Variable 'ProviderOptimisationSettings'
# OpenAI TTS Provider Module
# Provides Text-to-Speech synthesis via OpenAI's Audio API

# Load required assemblies for GUI Dialogues
Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue

function Test-OpenAICredentials {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config
    )
    
    try {
        Add-ApplicationLog -Module "OpenAI" -Message "Testing OpenAI API credentials..." -Level "INFO"
        
        # Validate API key format
        if ([string]::IsNullOrWhiteSpace($Config.ApiKey) -or $Config.ApiKey.Length -lt 20) {
            Add-ApplicationLog -Module "OpenAI" -Message "OpenAI API key validation failed: Invalid format or too short" -Level "ERROR"
            return $false
        }
        
        # Test connectivity with a simple API call to list models
        $headers = @{
            "Authorisation" = "Bearer $($Config.ApiKey)"
            "Content-Type" = "application/json"
        }
        
        try {
            $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/models" `
                -Method Get -Headers $headers -ErrorAction Stop -TimeoutSec 10
            
            Add-ApplicationLog -Module "OpenAI" -Message "OpenAI API credentials validated successfully" -Level "INFO"
            return $true
        }
        catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $errorMessage = $_.Exception.Message
            
            Add-ApplicationLog -Module "OpenAI" -Message "OpenAI API credential test failed - Status: $statusCode, Error: $errorMessage" -Level "ERROR"
            return $false
        }
    }
    catch {
        Add-ApplicationLog -Module "OpenAI" -Message "OpenAI credential test error: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Get-OpenAIVoiceOptions {
    <#
    .SYNOPSIS
    Returns available voice options for OpenAI TTS provider with dynamic model retrieval
    
    .DESCRIPTION
    Fetches available TTS models from OpenAI API and provides lists of supported voices,
    formats, and speeds. Implements caching and fallback to prevent excessive API calls.
    
    .PARAMETER ApiKey
    Optional API key for live validation. If not provided, returns cached or default values.
    
    .PARAMETER UseCache
    Whether to use cached results if available. Default is $true.
    
    .OUTPUTS
    Hashtable containing Voices, Models, Formats, Languages, Speeds arrays with defaults
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
            "alloy",
            "echo",
            "fable",
            "onyx",
            "nova",
            "shimmer"
        )
        DefaultVoice = "alloy"
        
        Models = @(
            "tts-1",
            "tts-1-hd"
        )
        DefaultModel = "tts-1-hd"
        
        Formats = @(
            "MP3",
            "OPUS",
            "AAC",
            "FLAC",
            "WAV",
            "PCM"
        )
        DefaultFormat = "MP3"
        
        Languages = @("Multi-language")
        DefaultLanguage = "Multi-language"
        
        Speeds = @(
            "0.25",
            "0.5",
            "0.75",
            "1.0",
            "1.25",
            "1.5",
            "2.0",
            "3.0",
            "4.0"
        )
        DefaultSpeed = "1.0"
        
        SupportsAdvanced = $true
    }
    
    # If no API key provided, return defaults
    if (-not $ApiKey) {
        Add-ApplicationLog -Module "OpenAI" -Message "No API key provided, returning default voice options" -Level "DEBUG"
        return $defaultOptions
    }
    
    # Try to fetch live model data from OpenAI API
    try {
        Add-ApplicationLog -Module "OpenAI" -Message "Fetching available models from OpenAI API" -Level "INFO"
        
        $headers = @{
            "Authorisation" = "Bearer $ApiKey"
            "Content-Type" = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/models" -Method Get -Headers $headers -TimeoutSec 10
        
        # Filter for TTS models only
        $ttsModels = $response.data | Where-Object { $_.id -like "tts-*" } | Select-Object -ExpandProperty id | Sort-Object
        
        if ($ttsModels -and $ttsModels.Count -gt 0) {
            Add-ApplicationLog -Module "OpenAI" -Message "Successfully retrieved $($ttsModels.Count) TTS models from API" -Level "INFO"
            $defaultOptions.Models = @($ttsModels)
        } else {
            Add-ApplicationLog -Module "OpenAI" -Message "No TTS models found in API response, using defaults" -Level "WARNING"
        }
        
    } catch {
        Add-ApplicationLog -Module "OpenAI" -Message "Failed to fetch models from API: $($_.Exception.Message). Using default values." -Level "WARNING"
    }
    
    return $defaultOptions
}

# Provider Class Definition
class OpenAITTSProvider {
    [string]$ApiKey
    [string]$Voice
    [string]$Model
    [string]$Format
    [double]$Speed
    [hashtable]$Capabilities
    [hashtable]$Configuration
    [hashtable]$CachedVoiceOptions
    [datetime]$CacheTimestamp
    [int]$CacheExpiryMinutes = 30
    
    OpenAITTSProvider() {
        $this.Configuration = @{}
        $this.CachedVoiceOptions = $null
        $this.CacheTimestamp = [datetime]::MinValue
        $this.Capabilities = @{
            Name = "OpenAI"
            MaxTextLength = 4096
            SupportedFormats = @("MP3", "OPUS", "AAC", "FLAC", "WAV", "PCM")
            SupportsSSML = $false
            SupportsNeuralVoices = $true
            StreamingEnabled = $true
            SampleRates = @(24000, 44100, 48000)
        }
    }
    
    [hashtable] GetVoiceOptions([bool]$ForceRefresh) {
        # Check if cache is valid
        $cacheValid = $false
        if ($this.CachedVoiceOptions -and -not $ForceRefresh) {
            $cacheAge = ([datetime]::Now - $this.CacheTimestamp).TotalMinutes
            if ($cacheAge -lt $this.CacheExpiryMinutes) {
                $cacheValid = $true
                Add-ApplicationLog -Module "OpenAI" -Message "Using cached voice options (age: $([math]::Round($cacheAge, 1)) minutes)" -Level "DEBUG"
            }
        }
        
        if ($cacheValid) {
            return $this.CachedVoiceOptions
        }
        
        # Fetch fresh data
        Add-ApplicationLog -Module "OpenAI" -Message "Fetching fresh voice options from API" -Level "INFO"
        $voiceOptions = Get-OpenAIVoiceOptions -ApiKey $this.ApiKey -UseCache $false
        
        # Cache the result
        $this.CachedVoiceOptions = $voiceOptions
        $this.CacheTimestamp = [datetime]::Now
        
        return $voiceOptions
    }
    
    [PSCustomObject] ProcessTTS([string]$Text, [string]$OutputPath, [hashtable]$Options) {
        try {
            Add-ApplicationLog -Module "OpenAI" -Message "Processing TTS with OpenAI - Voice: $($this.Voice), Model: $($this.Model)" -Level "INFO"
            
            # Validate configuration
            if (-not $this.ValidateConfiguration()) {
                throw "OpenAI configuration validation failed"
            }
            
            # Prepare API request
            $selectedVoice = if ($this.Voice) { $this.Voice } else { "alloy" }
            $selectedModel = if ($this.Model) { $this.Model } else { "tts-1-hd" }
            $selectedFormat = if ($this.Format) { $this.Format.ToLower() } else { "mp3" }
            $selectedSpeed = if ($this.Speed -gt 0) { $this.Speed } else { 1.0 }
            
            $headers = @{
                "Authorisation" = "Bearer $($this.ApiKey)"
                "Content-Type" = "application/json"
            }
            
            $body = @{
                model = $selectedModel
                input = $Text
                voice = $selectedVoice
                response_format = $selectedFormat
                speed = $selectedSpeed
            } | ConvertTo-Json
            
            Add-ApplicationLog -Module "OpenAI" -Message "OpenAI TTS request - Model: $selectedModel, Voice: $selectedVoice, Format: $selectedFormat, Speed: $selectedSpeed" -Level "DEBUG"
            
            # Make API request
            $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/audio/speech" `
                -Method Post -Headers $headers -Body $body -OutFile $OutputPath -ErrorAction Stop
            
            Add-ApplicationLog -Module "OpenAI" -Message "OpenAI TTS synthesis completed - Output: $OutputPath" -Level "INFO"
            
            return [PSCustomObject]@{
                Success = $true
                OutputPath = $OutputPath
                Provider = "OpenAI"
                Voice = $selectedVoice
                Model = $selectedModel
                CharacterCount = $Text.Length
                Duration = 0
                Message = "OpenAI TTS processing completed successfully"
            }
        }
        catch {
            Add-ApplicationLog -Module "OpenAI" -Message "OpenAI TTS processing failed: $($_.Exception.Message)" -Level "ERROR"
            return [PSCustomObject]@{
                Success = $false
                Error = $_.Exception.Message
                Provider = "OpenAI"
            }
        }
    }
    
    [bool] ValidateConfiguration() {
        if ([string]::IsNullOrWhiteSpace($this.ApiKey)) {
            Add-ApplicationLog -Module "OpenAI" -Message "OpenAI configuration invalid: API Key is required" -Level "ERROR"
            return $false
        }
        
        if ($this.ApiKey.Length -lt 20) {
            Add-ApplicationLog -Module "OpenAI" -Message "OpenAI configuration invalid: API Key format incorrect" -Level "ERROR"
            return $false
        }
        
        return $true
    }
    
    [array] GetAvailableVoices() {
        $options = Get-OpenAIVoiceOptions
        return $options.Voices
    }
    
    [hashtable] ShowConfigurationDialog([hashtable]$CurrentConfig) {
        $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="OpenAI Configuration" Height="590" Width="600"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#FF1E1E1E">
	<Grid Margin="20">
		<Grid.RowDefinitions>
			<RowDefinition Height="Auto"/>
			<RowDefinition Height="Auto"/>
			<RowDefinition Height="Auto"/>
			<RowDefinition Height="*"/>
			<RowDefinition Height="Auto"/>
		</Grid.RowDefinitions>
		
		<!-- Header -->
		<TextBlock Grid.Row="0" Text="OpenAI Configuration" FontSize="18" FontWeight="Bold" Foreground="White" Margin="0,0,0,12"/>
		
		<!-- API Configuration -->
		<GroupBox Grid.Row="1" Header="API Configuration" Foreground="White" BorderBrush="#FF404040" Margin="0,0,0,12">
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
						<Run FontWeight="SemiBold" Foreground="White">1. Sign up at OpenAI</Run>
						<LineBreak/>Visit https://platform.openai.com/ and create an account
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">2. Navigate to API Keys</Run>
						<LineBreak/>Go to https://platform.openai.com/api-keys to manage your keys
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">3. Generate API Key</Run>
						<LineBreak/>Create a new secret key with appropriate permissions
					</TextBlock>
					<TextBlock Foreground="#FFCCCCCC" TextWrapping="Wrap" Margin="0,0,0,8">
						<Run FontWeight="SemiBold" Foreground="White">4. Copy and Paste</Run>
						<LineBreak/>Copy the API key (starts with sk-) and paste it above, then click 'Test Connection'
					</TextBlock>
					<TextBlock Foreground="#FFFFCC00" TextWrapping="Wrap" Margin="0,8,0,0" FontStyle="Italic">
						<Run FontWeight="SemiBold">Note:</Run> OpenAI TTS offers 6 natural voices (alloy, echo, fable, onyx, nova, shimmer) with tts-1 and tts-1-hd models. Check https://platform.openai.com/account/billing/overview for current pricing.
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
            
            # Load existing configuration
            if ($null -eq $CurrentConfig) {
                Add-ApplicationLog -Module "OpenAI" -Message "ShowConfigurationDialog - CurrentConfig is null" -Level "INFO"
            } elseif ($CurrentConfig -is [hashtable]) {
                Add-ApplicationLog -Module "OpenAI" -Message "ShowConfigurationDialog - CurrentConfig is hashtable with $($CurrentConfig.Count) keys: $($CurrentConfig.Keys -join ', ')" -Level "INFO"
                if ($CurrentConfig.ApiKey -and -not [string]::IsNullOrWhiteSpace($CurrentConfig.ApiKey)) {
                    $apiKeyBox.Password = $CurrentConfig.ApiKey
                    Add-ApplicationLog -Module "OpenAI" -Message "Loaded API key into Dialogue (length: $($CurrentConfig.ApiKey.Length))" -Level "INFO"
                } else {
                    Add-ApplicationLog -Module "OpenAI" -Message "CurrentConfig does not have ApiKey or it's empty" -Level "INFO"
                }
            } else {
                Add-ApplicationLog -Module "OpenAI" -Message "ShowConfigurationDialog - CurrentConfig is type: $($CurrentConfig.GetType().FullName)" -Level "INFO"
            }
            
            # Test Connection button
            $testBtn.Add_Click({
                $testStatus.Text = "Testing..."
                $testStatus.Foreground = "#FFFFFF00"
                
                $apiKey = $apiKeyBox.Password
                
                Add-ApplicationLog -Module "OpenAI" -Message "Test Connection clicked - APIKey length: $($apiKey.Length)" -Level "INFO"
                
                if ([string]::IsNullOrWhiteSpace($apiKey)) {
                    $testStatus.Text = "Error - Enter API Key"
                    $testStatus.Foreground = "#FFFF0000"
                    return
                }
                
                $testResult = Test-OpenAICredentials -Config @{ ApiKey = $apiKey }
                Add-ApplicationLog -Module "OpenAI" -Message "Test result: $testResult" -Level "INFO"
                
                if ($testResult) {
                    $testStatus.Text = "✓ Credentials Valid!"
                    $testStatus.Foreground = "#FF28A745"
                } else {
                    $testStatus.Text = "❌ Invalid Credentials"
                    $testStatus.Foreground = "#FFFF0000"
                }
            })
            
            # Save button
            $saveBtn.Add_Click({
                $apiKey = $apiKeyBox.Password
                if ([string]::IsNullOrWhiteSpace($apiKey)) {
                    $msgBoxType = 'System.Windows.MessageBox' -as [type]
                    if ($msgBoxType) {
                        $msgBoxType::Show("Please enter an API Key", "Validation Error", 0, 48)
                    }
                    return
                }
                
                $window.Tag = @{
                    Success = $true
                    ApiKey = $apiKey
                }
                $window.DialogueResult = $true
                $window.Close()
            }.GetNewClosure())
            
            # Cancel button
            $cancelBtn.Add_Click({
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
            
        }
        catch {
            Add-ApplicationLog -Module "OpenAI" -Message "Error showing configuration Dialogue: $($_.Exception.Message)" -Level "ERROR"
            return @{ Success = $false; Error = $_.Exception.Message }
        }
    }
    
    [hashtable] ShowAdvancedVoiceDialog([hashtable]$CurrentConfig) {
        $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="OpenAI Advanced Voice Options"
        Height="420" Width="540"
        WindowStartupLocation="CenterScreen"
        Background="#FF1E1E1E"
        ResizeMode="NoResize">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Title -->
        <TextBlock Grid.Row="0" Text="Advanced Voice Options" FontSize="18" FontWeight="Bold" 
                   Foreground="White" Margin="0,0,0,15"/>
        
        <!-- Speed Control -->
        <GroupBox Grid.Row="1" Header="Speed Control" Foreground="White" Margin="0,0,0,10"
                  BorderBrush="#FF3F3F46" BorderThickness="1" Padding="10">
            <StackPanel>
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    
                    <TextBlock Grid.Column="0" Text="Playback Speed:" Foreground="White" VerticalAlignment="Centre"/>
                    <Slider Grid.Column="1" Name="SpeedSlider" Minimum="0.25" Maximum="4.0" Value="1.0" 
                            TickFrequency="0.25" IsSnapToTickEnabled="True" Margin="10,0"/>
                    <TextBlock Grid.Column="2" Name="SpeedValue" Text="1.0x" Foreground="#FF28A745" 
                               MinWidth="45" FontWeight="Bold" VerticalAlignment="Centre"/>
                </Grid>
                <TextBlock Text="Adjust voice playback speed (0.25x = very slow, 4.0x = very fast)" 
                           Foreground="#FFB0B0B0" FontSize="10" Margin="0,5,0,0"/>
            </StackPanel>
        </GroupBox>
        
        <!-- Model Quality -->
        <GroupBox Grid.Row="3" Header="Model Quality" Foreground="White" Margin="0,0,0,10"
                  BorderBrush="#FF3F3F46" BorderThickness="1" Padding="10">
            <StackPanel>
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <TextBlock Grid.Column="0" Text="Quality Model:" Foreground="White" VerticalAlignment="Centre" Margin="0,0,10,0"/>
                    <ComboBox Grid.Column="1" Name="ModelComboBox" Height="25" Background="#FF3F3F46" 
                              Foreground="White" BorderBrush="#FF28A745"/>
                </Grid>
                <TextBlock Text="tts-1: Standard quality, faster | tts-1-hd: High definition, premium quality" 
                           Foreground="#FFB0B0B0" FontSize="10" Margin="0,5,0,0"/>
            </StackPanel>
        </GroupBox>
        
        <!-- Info Panel -->
        <Border Grid.Row="4" Background="#FF2D2D30" CornerRadius="5" Padding="10" Margin="0,0,0,10">
            <StackPanel>
                <TextBlock Text="Note: OpenAI TTS API Limitations" Foreground="#FFFFD700" FontWeight="Bold" Margin="0,0,0,5"/>
                <TextBlock TextWrapping="Wrap" Foreground="#FFB0B0B0" FontSize="11">
                    • Maximum 4,096 characters per request<LineBreak/>
                    • No SSML markup support (text only)<LineBreak/>
                    • No pitch/volume control via API<LineBreak/>
                    • Multi-language auto-detection (no manual override)<LineBreak/>
                    • Speed control is the main advanced feature available
                </TextBlock>
            </StackPanel>
        </Border>
        
        <!-- Buttons -->
        <StackPanel Grid.Row="5" Orientation="Horizontal" HorizontalAlignment="Right">
            <Button Name="SaveButton" Content="Save and Close" Width="120" Height="30" 
                    Background="#FF28A745" Foreground="White" FontWeight="Bold" Margin="0,0,10,0"
                    BorderThickness="0"/>
            <Button Name="CancelButton" Content="Cancel" Width="80" Height="30" 
                    Background="#FF6C757D" Foreground="White" FontWeight="Bold"
                    BorderThickness="0"/>
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
            $speedSlider = $window.FindName("SpeedSlider")
            $speedValue = $window.FindName("SpeedValue")
            $modelComboBox = $window.FindName("ModelComboBox")
            $saveButton = $window.FindName("SaveButton")
            $cancelButton = $window.FindName("CancelButton")
            
            # Populate Model dropdown
            $models = @("tts-1", "tts-1-hd")
            foreach ($model in $models) {
                $modelComboBox.Items.Add($model) | Out-Null
            }
            
            # Load current configuration
            if ($CurrentConfig) {
                if ($CurrentConfig.Speed) {
                    $speedSlider.Value = [double]$CurrentConfig.Speed
                }
                if ($CurrentConfig.Model) {
                    $modelComboBox.SelectedItem = $CurrentConfig.Model
                } else {
                    $modelComboBox.SelectedIndex = 1
                }
            } else {
                $speedSlider.Value = 1.0
                $modelComboBox.SelectedIndex = 1
            }
            
            # Speed slider value change event
            $speedSlider.Add_ValueChanged({
                $speedValue.Text = "$($speedSlider.Value)x"
            }.GetNewClosure())
            
            # Save button click
            $saveButton.Add_Click({
                $window.Tag = @{
                    Success = $true
                    Speed = [double]$speedSlider.Value
                    Model = $modelComboBox.SelectedItem
                }
                $window.DialogueResult = $true
                $window.Close()
            }.GetNewClosure())
            
            # Cancel button click
            $cancelButton.Add_Click({
                $window.Tag = @{ Success = $false }
                $window.DialogueResult = $false
                $window.Close()
            }.GetNewClosure())
            
            # Show Dialogue
            $result = $window.ShowDialog()
            
            if ($window.Tag -and $window.Tag.Success) {
                Add-ApplicationLog -Module "OpenAI" -Message "Advanced voice options saved: Speed=$($window.Tag.Speed), Model=$($window.Tag.Model)" -Level "INFO"
                return $window.Tag
            } else {
                Add-ApplicationLog -Module "OpenAI" -Message "Advanced voice options Dialogue cancelled" -Level "DEBUG"
                return @{ Success = $false }
            }
            
        } catch {
            Add-ApplicationLog -Module "OpenAI" -Message "Error showing advanced voice Dialogue: $($_.Exception.Message)" -Level "ERROR"
            return @{ Success = $false; Error = $_.Exception.Message }
        }
    }
}

# Factory function to create provider instance
function New-OpenAITTSProviderInstance {
    [CmdletBinding()]
    param(
        [hashtable]$Configuration
    )
    
    $provider = [OpenAITTSProvider]::new()
    
    if ($Configuration) {
        if ($Configuration.ApiKey) { $provider.ApiKey = $Configuration.ApiKey }
        if ($Configuration.Voice) { $provider.Voice = $Configuration.Voice }
        if ($Configuration.Model) { $provider.Model = $Configuration.Model }
        if ($Configuration.Format) { $provider.Format = $Configuration.Format }
        if ($Configuration.Speed) { $provider.Speed = $Configuration.Speed }
    }
    
    return $provider
}

# Setup function for GUI integration
function Show-OpenAIProviderSetup {
    <#
    .SYNOPSIS
    Shows the OpenAI provider setup Dialogue for GUI configuration
    #>
    
    try {
        # Load current configuration
        $config = Get-Configuration
        $currentConfig = if ($config.ProviderConfigurations -and $config.ProviderConfigurations."OpenAI") {
            $config.ProviderConfigurations."OpenAI"
        } else {
            @{}
        }
        
        # Create and show configuration Dialogue
        $provider = [OpenAITTSProvider]::new()
        $provider.ShowConfigurationDialog($currentConfig)
        
        # Save updated configuration if Dialogue was accepted
        if ($provider.ApiKey) {
            if (-not $config.ProviderConfigurations) {
                $config.ProviderConfigurations = @{}
            }
            $config.ProviderConfigurations."OpenAI" = @{
                ApiKey = $provider.ApiKey
            }
            
            Save-Configuration -Config $config
            Add-ApplicationLog -Module "OpenAI" -Message "Configuration saved successfully" -Level "INFO"
        }
    }
    catch {
        Add-ApplicationLog -Module "OpenAI" -Message "Error in provider setup: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

Export-ModuleMember -Function Test-OpenAICredentials, Get-OpenAIVoiceOptions, New-OpenAITTSProviderInstance, Show-OpenAIProviderSetup

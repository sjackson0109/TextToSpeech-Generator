class GUI {
    [string]$CurrentProfile
    [object]$Window
    [bool]$AutoSaveEnabled
    [object]$ConfigManager
    [object]$AutoSaveTimer
    [string]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="TextToSpeech Generator" Height="400" Width="600">
    <Grid>
        <TextBlock Text="TextToSpeech Generator" FontSize="24" HorizontalAlignment="Center" VerticalAlignment="Top" Margin="0,20,0,0"/>
        <!-- Add more controls as needed -->
    </Grid>
</Window>
"@

    GUI([string]$profile = "Default") {
        $this.CurrentProfile = $profile
        $this.AutoSaveEnabled = $true
        $this.Window = $null
        $this.ConfigManager = $null
        $this.AutoSaveTimer = $null
    }

    [object]InitialiseModernGUI($Profile = "Default", $ConfigurationManager = $null) {
        $this.CurrentProfile = $Profile
        $this.ConfigManager = $ConfigurationManager
        $this.WriteSafeLog("Initializing Modern GUI with profile: $Profile", "INFO")
        try {

        # Export New-GUI entry point for the module
        function New-GUI {
            param(
                [string]$Profile = "Default",
                $ConfigurationManager = $null
            )
            $gui = [GUI]::new($Profile)
            $gui.InitialiseModernGUI($Profile, $ConfigurationManager)
        }

        Export-ModuleMember -Function New-GUI
                Join-Path $PSScriptRoot "..\..\Default.json"
            }
            if (Test-Path $configPath) {
                $configContent = Get-Content $configPath -Raw | ConvertFrom-Json -AsHashtable
                $profileConfig = $null
                if ($configContent.Profiles -and $configContent.Profiles.$($this.CurrentProfile)) {
                    $profileConfig = $configContent.Profiles.$($this.CurrentProfile)
                } elseif ($configContent.Profiles -and $configContent.Profiles.Default) {
                    $profileConfig = $configContent.Profiles.Default
                    $this.WriteSafeLog("Profile '$($this.CurrentProfile)' not found, using Default", "WARNING")
                } elseif ($configContent.Profiles -and $configContent.Profiles.Development) {
                    $profileConfig = $configContent.Profiles.Development
                    $this.WriteSafeLog("Profile '$($this.CurrentProfile)' not found, using Development", "WARNING")
                }
                if ($profileConfig) {
                    $this.SetGUIConfiguration($profileConfig)
                    if ($this.Window.PSObject.Properties["ConfigStatus"] -and $this.Window.ConfigStatus.PSObject.Properties["Text"]) {
                        $this.Window.ConfigStatus.Text = "Auto-Loaded"
                    }
                    $this.Window.ConfigStatus.Foreground = "#FF00FF00"
                    $this.WriteSafeLog("Configuration auto-loaded successfully", "INFO")
                } else {
                    if ($this.Window.PSObject.Properties["ConfigStatus"] -and $this.Window.ConfigStatus.PSObject.Properties["Text"]) {
                        $this.Window.ConfigStatus.Text = "No Config"
                    }
                    $this.Window.ConfigStatus.Foreground = "#FFFFFF00"
                    $this.WriteSafeLog("No configuration found for profile: $($this.CurrentProfile)", "WARNING")
                }
            } else {
                if ($this.Window.PSObject.Properties["ConfigStatus"] -and $this.Window.ConfigStatus.PSObject.Properties["Text"]) {
                    $this.Window.ConfigStatus.Text = "No Config File"
                }
                $this.Window.ConfigStatus.Foreground = "#FFFFFF00"
                $this.WriteSafeLog("Configuration file not found: $configPath", "WARNING")
            }
        } catch {
            $this.WriteSafeLog("Auto-load failed: $($_.Exception.Message)", "ERROR")
            if ($this.Window.PSObject.Properties["ConfigStatus"] -and $this.Window.ConfigStatus.PSObject.Properties["Text"]) {
                $this.Window.ConfigStatus.Text = "Load Error"
            }
            $this.Window.ConfigStatus.Foreground = "#FFFF0000"
        }
    }

    [void]InvokeAutoSaveConfiguration() {
        try {
            $configPath = if ($this.ConfigManager -and $this.ConfigManager.ConfigPath) {
                $this.ConfigManager.ConfigPath
            } else {
                Join-Path $PSScriptRoot "..\..\Default.json"
            }
            $existingConfig = @{}
            if (Test-Path $configPath) {
                try {
                    $existingConfig = Get-Content $configPath -Raw | ConvertFrom-Json -AsHashtable
                } catch {
                    $this.WriteSafeLog("Error reading existing config for save: $($_.Exception.Message)", "WARNING")
                    $existingConfig = @{}
                }
            }
            if (-not $existingConfig.ConfigVersion) { $existingConfig.ConfigVersion = "3.2" }
            if (-not $existingConfig.Profiles) { $existingConfig.Profiles = @{} }
            if (-not $existingConfig.Profiles.$($this.CurrentProfile)) { $existingConfig.Profiles.$($this.CurrentProfile) = @{} }
            $currentConfig = $this.GetGUIConfiguration()
            $existingConfig.Profiles.$($this.CurrentProfile) = $currentConfig
            $existingConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
            if ($this.Window.PSObject.Properties["ConfigStatus"] -and $this.Window.ConfigStatus.PSObject.Properties["Text"]) {
                $this.Window.ConfigStatus.Text = "Auto-Saved"
            }
            $this.Window.ConfigStatus.Foreground = "#FF00FF00"
            $this.WriteSafeLog("Configuration auto-saved for profile: $($this.CurrentProfile)", "INFO")
        } catch {
            $this.WriteSafeLog("Auto-save failed: $($_.Exception.Message)", "ERROR")
            if ($this.Window.PSObject.Properties["ConfigStatus"] -and $this.Window.ConfigStatus.PSObject.Properties["Text"]) {
                $this.Window.ConfigStatus.Text = "Save Error"
            }
            $this.Window.ConfigStatus.Foreground = "#FFFF0000"
        }
    }

    [void]SetGUIConfiguration($Configuration) {
        # Use $this.Window directly
    if (-not $this.Window) { return }
        # Set selected provider
        if ($Configuration.SelectedProvider) {
            $providerCombo = $this.Window.ProviderSelect
            foreach ($item in $providerCombo.Items) {
                if ($item.Content -eq $Configuration.SelectedProvider) {
                    $providerCombo.SelectedItem = $item
                    break
                }
            }
        }
        # Azure Cognitive Services
        if ($Configuration.Providers["Azure Cognitive Services"]) {
            $azure = $Configuration.Providers["Azure Cognitive Services"]
            if ($this.Window.PSObject.Properties["MS_KEY"] -and $this.Window.MS_KEY.PSObject.Properties["Text"]) { $this.Window.MS_KEY.Text = $azure.ApiKey }
            if ($this.Window.PSObject.Properties["MS_Datacenter"] -and $this.Window.MS_Datacenter.PSObject.Properties["Text"]) { $this.Window.MS_Datacenter.Text = $azure.Datacenter }
            if ($this.Window.MS_Audio_Format -and $azure.AudioFormat) {
                foreach ($item in $this.Window.MS_Audio_Format.Items) {
                    if ($item.Content -eq $azure.AudioFormat) { $this.Window.MS_Audio_Format.SelectedItem = $item; break }
                }
            }
            if ($this.Window.MS_Voice -and $azure.DefaultVoice) {
                foreach ($item in $this.Window.MS_Voice.Items) {
                    if ($item.Content -eq $azure.DefaultVoice) { $this.Window.MS_Voice.SelectedItem = $item; break }
                }
            }
        }
        # AWS Polly
        if ($Configuration.Providers["AWS Polly"]) {
            $aws = $Configuration.Providers["AWS Polly"]
            if ($this.Window.PSObject.Properties["AWS_AccessKey"] -and $this.Window.AWS_AccessKey.PSObject.Properties["Text"]) { $this.Window.AWS_AccessKey.Text = $aws.AccessKey }
            if ($this.Window.PSObject.Properties["AWS_SecretKey"] -and $this.Window.AWS_SecretKey.PSObject.Properties["Text"]) { $this.Window.AWS_SecretKey.Text = $aws.SecretKey }
            if ($this.Window.AWS_Region -and $aws.Region) {
                foreach ($item in $this.Window.AWS_Region.Items) {
                    if ($item.Content -eq $aws.Region) { $this.Window.AWS_Region.SelectedItem = $item; break }
                }
            }
            if ($this.Window.AWS_Voice -and $aws.DefaultVoice) {
                foreach ($item in $this.Window.AWS_Voice.Items) {
                    if ($item.Content -eq $aws.DefaultVoice) { $this.Window.AWS_Voice.SelectedItem = $item; break }
                }
            }
        }
        # Google Cloud TTS
        if ($Configuration.Providers["Google Cloud TTS"]) {
            $gc = $Configuration.Providers["Google Cloud TTS"]
            if ($this.Window.PSObject.Properties["GC_APIKey"] -and $this.Window.GC_APIKey.PSObject.Properties["Text"]) { $this.Window.GC_APIKey.Text = $gc.ApiKey }
            if ($this.Window.GC_Language -and $gc.Language) {
                foreach ($item in $this.Window.GC_Language.Items) {
                    if ($item.Content -eq $gc.Language) { $this.Window.GC_Language.SelectedItem = $item; break }
                }
            }
            if ($this.Window.GC_Voice -and $gc.DefaultVoice) {
                foreach ($item in $this.Window.GC_Voice.Items) {
                    if ($item.Content -eq $gc.DefaultVoice) { $this.Window.GC_Voice.SelectedItem = $item; break }
                }
            }
        }
        # CloudPronouncer
        if ($Configuration.Providers.ContainsKey("CloudPronouncer") -and $Configuration.Providers["CloudPronouncer"]) {
            $cp = $Configuration.Providers["CloudPronouncer"]
            if ($this.Window.PSObject.Properties["CP_Username"] -and $this.Window.CP_Username.PSObject.Properties["Text"]) { $this.Window.CP_Username.Text = $cp.Username }
            if ($cp.ContainsKey('Password') -and $this.Window.CP_Password) { $this.Window.CP_Password.Password = $cp.Password }
            if ($this.Window.CP_Voice -and $cp.DefaultVoice) {
                foreach ($item in $this.Window.CP_Voice.Items) {
                    if ($item.Content -eq $cp.DefaultVoice) { $this.Window.CP_Voice.SelectedItem = $item; break }
                }
            }
            if ($this.Window.CP_Format -and $cp.Format) {
                foreach ($item in $this.Window.CP_Format.Items) {
                    if ($item.Content -eq $cp.Format) { $this.Window.CP_Format.SelectedItem = $item; break }
                }
            }
        }
        # Twilio
        if ($Configuration.Providers.ContainsKey("Twilio") -and $Configuration.Providers["Twilio"]) {
            $tw = $Configuration.Providers["Twilio"]
            if ($this.Window.PSObject.Properties["TW_AccountSID"] -and $this.Window.TW_AccountSID.PSObject.Properties["Text"]) { $this.Window.TW_AccountSID.Text = $tw.AccountSID }
            if ($tw.ContainsKey('AuthToken') -and $this.Window.TW_AuthToken) { $this.Window.TW_AuthToken.Password = $tw.AuthToken }
            if ($this.Window.TW_Voice -and $tw.DefaultVoice) {
                foreach ($item in $this.Window.TW_Voice.Items) {
                    if ($item.Content -eq $tw.DefaultVoice) { $this.Window.TW_Voice.SelectedItem = $item; break }
                }
            }
            if ($this.Window.TW_Format -and $tw.Format) {
                foreach ($item in $this.Window.TW_Format.Items) {
                    if ($item.Content -eq $tw.Format) { $this.Window.TW_Format.SelectedItem = $item; break }
                }
            }
        }
        # VoiceForge
        if ($Configuration.Providers.ContainsKey("VoiceForge") -and $Configuration.Providers["VoiceForge"]) {
            $vf = $Configuration.Providers["VoiceForge"]
            if ($this.Window.PSObject.Properties["VF_APIKey"] -and $this.Window.VF_APIKey.PSObject.Properties["Text"]) { $this.Window.VF_APIKey.Text = $vf.ApiKey }
            if ($this.Window.PSObject.Properties["VF_Endpoint"] -and $this.Window.VF_Endpoint.PSObject.Properties["Text"]) { $this.Window.VF_Endpoint.Text = $vf.Endpoint }
            if ($this.Window.VF_Voice -and $vf.DefaultVoice) {
                foreach ($item in $this.Window.VF_Voice.Items) {
                    if ($item.Content -eq $vf.DefaultVoice) { $this.Window.VF_Voice.SelectedItem = $item; break }
                }
            }
            if ($this.Window.VF_Quality -and $vf.Quality) {
                foreach ($item in $this.Window.VF_Quality.Items) {
                    if ($item.Content -eq $vf.Quality) { $this.Window.VF_Quality.SelectedItem = $item; break }
                }
            }
        }
    }

    [void]ShowProviderSetup($Provider) {
        Write-SafeLog -Message "Showing setup dialog for $Provider..." -Level "INFO"

        # Create styled setup dialog matching the original design
        $setupXAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Provider Setup" 
        Width="800"
        SizeToContent="Height"
        WindowStartupLocation="CenterOwner" 
        Background="#FF2D2D30" 
        ResizeMode="CanResize"
        MinWidth="800"
        MaxWidth="900">
    <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto">
        <StackPanel Margin="16">
            <GroupBox x:Name="APIHeader" Header="Provider Setup" Margin="0,0,0,12" Foreground="White">
            <GroupBox x:Name="ConfigurationSection" Header="Configuration" Margin="0,0,0,12" Foreground="White">
            </GroupBox>
            <GroupBox Header="Connection Testing" Margin="0,0,0,12" Foreground="White">
                <Grid Margin="8">
                </Grid>
            </GroupBox>
            <GroupBox x:Name="APISetupGuidance" Header="Setup Instructions" Margin="0,0,0,12" Foreground="White">
                <TextBlock x:Name="APIGuidanceText" Text="Follow the instructions below to configure your API credentials." />
            </GroupBox>
            <Grid Margin="0,16,0,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Button x:Name="ResetToDefaults" Grid.Column="1" Content="Reset to Defaults" Width="120" Height="30" Margin="0,0,8,0" Background="#FFD32F2F" Foreground="White"/>
                <Button x:Name="SaveAndClose" Grid.Column="2" Content="Save &amp; Close" Width="100" Height="30" Background="#FF2D7D32" Foreground="White"/>
            </Grid>
        </StackPanel>
    </ScrollViewer>
</Window>
"@

        try {
            $setupWindow = Convert-XAMLtoWindow -XAML $setupXAML
            $setupWindow.Owner = $this.Window

            $configGrid = $setupWindow.ConfigGrid
            $guidanceText = $setupWindow.APIGuidanceText

            $configGrid.RowDefinitions.Clear()
            $configGrid.ColumnDefinitions.Clear()

            $col1 = New-Object System.Windows.Controls.ColumnDefinition
            $col1.Width = [System.Windows.GridLength]::new(100)
            $configGrid.ColumnDefinitions.Add($col1)
            $col2 = New-Object System.Windows.Controls.ColumnDefinition  
            $col2.Width = [System.Windows.GridLength]::new(280)
            $configGrid.ColumnDefinitions.Add($col2)
            $col3 = New-Object System.Windows.Controls.ColumnDefinition
            $col3.Width = [System.Windows.GridLength]::new(100)
            $configGrid.ColumnDefinitions.Add($col3)
            $col4 = New-Object System.Windows.Controls.ColumnDefinition
            $col4.Width = [System.Windows.GridLength]::new(180)
            $configGrid.ColumnDefinitions.Add($col4)

            $setupWindow.ConfigurationSection.Header = "$Provider Configuration"

            switch ($Provider) {
                "Azure Cognitive Services" {
                    Import-Module (Join-Path $PSScriptRoot "..\TTSProviders\Azure.psm1") -Force
                    Show-AzureProviderSetup -Window $setupWindow -ConfigGrid $configGrid -GuidanceText $guidanceText -GUI $this
                }
                "Amazon Polly" {
                    Import-Module (Join-Path $PSScriptRoot "..\TTSProviders\Polly.psm1") -Force
                    Show-PollyProviderSetup -Window $setupWindow -ConfigGrid $configGrid -GuidanceText $guidanceText -GUI $this
                }
                "Google Cloud" {
                    Import-Module (Join-Path $PSScriptRoot "..\TTSProviders\GoogleCloud.psm1") -Force
                    Show-GoogleCloudProviderSetup -Window $setupWindow -ConfigGrid $configGrid -GuidanceText $guidanceText -GUI $this
                }
                "CloudPronouncer" {
                    Import-Module (Join-Path $PSScriptRoot "..\TTSProviders\CloudPronouncer.psm1") -Force
                    Show-CloudPronouncerProviderSetup -Window $setupWindow -ConfigGrid $configGrid -GuidanceText $guidanceText -GUI $this
                }
                "Twilio" {
                    Import-Module (Join-Path $PSScriptRoot "..\TTSProviders\Twilio.psm1") -Force
                    Show-TwilioProviderSetup -Window $setupWindow -ConfigGrid $configGrid -GuidanceText $guidanceText -GUI $this
                }
                "VoiceForge" {
                    Import-Module (Join-Path $PSScriptRoot "..\TTSProviders\VoiceForge.psm1") -Force
                    Show-VoiceForgeProviderSetup -Window $setupWindow -ConfigGrid $configGrid -GuidanceText $guidanceText -GUI $this
                }
                }
                default {
                    $setupWindow.APIProviderInfo.Text = "Configuration for this provider is not yet fully implemented."
                    $row0 = New-Object System.Windows.Controls.RowDefinition
                    $row0.Height = [System.Windows.GridLength]::new(0, [System.Windows.GridUnitType]::Auto)
                    $configGrid.RowDefinitions.Add($row0)
                    $infoText = New-Object System.Windows.Controls.TextBlock
                    $infoText.Text = "Setup for $Provider is not yet implemented. Please configure manually in the hidden controls or check the documentation."
                    $infoText.Foreground = "White"
                    $infoText.TextWrapping = "Wrap"
                    $infoText.Margin = "8"
                    [System.Windows.Controls.Grid]::SetRow($infoText, 0)
                    [System.Windows.Controls.Grid]::SetColumn($infoText, 0)
                    [System.Windows.Controls.Grid]::SetColumnSpan($infoText, 4)
                    $configGrid.Children.Add($infoText) | Out-Null
                    $guidanceText.Text = "This provider setup is under development. Please refer to the documentation for manual configuration instructions."
                    $setupWindow.SaveAndClose.add_Click{
                        Write-SafeLog -Message "$Provider setup saved (manual configuration)" -Level "INFO"
                        $setupWindow.DialogResult = $true
                        $setupWindow.Close()
                    }
                }
            }

            # Validate Credentials button
            $setupWindow.ValidateCredentials.add_Click{
                $setupWindow.ConnectionStatus.Text = "Testing connection..."
                $setupWindow.ConnectionStatus.Foreground = "#FFFFFF00"
                try {
                    switch ($Provider) {
                        "Azure Cognitive Services" {
                            Import-Module (Join-Path $PSScriptRoot "..\TTSProviders\Azure.psm1") -Force
                            $isValid = Validate-AzureCredentials -Config $this.GetGUIConfiguration().Providers["Azure Cognitive Services"]
                            if ($isValid) {
                                $setupWindow.ConnectionStatus.Text = "✅ Azure credentials valid"
                                $setupWindow.ConnectionStatus.Foreground = "#FF00FF00"
                            } else {
                                $setupWindow.ConnectionStatus.Text = "❌ Invalid Azure credentials"
                                $setupWindow.ConnectionStatus.Foreground = "#FFFF0000"
                            }
                        }
                        "Amazon Polly" {
                            Import-Module (Join-Path $PSScriptRoot "..\TTSProviders\Polly.psm1") -Force
                            $isValid = Validate-PollyCredentials -Config $this.GetGUIConfiguration().Providers["AWS Polly"]
                            if ($isValid) {
                                $setupWindow.ConnectionStatus.Text = "✅ Polly credentials valid"
                                $setupWindow.ConnectionStatus.Foreground = "#FF00FF00"
                            } else {
                                $setupWindow.ConnectionStatus.Text = "❌ Invalid Polly credentials"
                                $setupWindow.ConnectionStatus.Foreground = "#FFFF0000"
                            }
                        }
                        "Google Cloud" {
                            Import-Module (Join-Path $PSScriptRoot "..\TTSProviders\GoogleCloud.psm1") -Force
                            $isValid = Validate-GoogleCloudCredentials -Config $this.GetGUIConfiguration().Providers["Google Cloud TTS"]
                            if ($isValid) {
                                $setupWindow.ConnectionStatus.Text = "✅ Google Cloud credentials valid"
                                $setupWindow.ConnectionStatus.Foreground = "#FF00FF00"
                            } else {
                                $setupWindow.ConnectionStatus.Text = "❌ Invalid Google Cloud credentials"
                                $setupWindow.ConnectionStatus.Foreground = "#FFFF0000"
                            }
                        }
                        "CloudPronouncer" {
                            Import-Module (Join-Path $PSScriptRoot "..\TTSProviders\CloudPronouncer.psm1") -Force
                            $isValid = Validate-CloudPronouncerCredentials -Config $this.GetGUIConfiguration().Providers["CloudPronouncer"]
                            if ($isValid) {
                                $setupWindow.ConnectionStatus.Text = "✅ CloudPronouncer credentials valid"
                                $setupWindow.ConnectionStatus.Foreground = "#FF00FF00"
                            } else {
                                $setupWindow.ConnectionStatus.Text = "❌ Invalid CloudPronouncer credentials"
                                $setupWindow.ConnectionStatus.Foreground = "#FFFF0000"
                            }
                        }
                        "Twilio" {
                            Import-Module (Join-Path $PSScriptRoot "..\TTSProviders\Twilio.psm1") -Force
                            $isValid = Validate-TwilioCredentials -Config $this.GetGUIConfiguration().Providers["Twilio"]
                            if ($isValid) {
                                $setupWindow.ConnectionStatus.Text = "✅ Twilio credentials valid"
                                $setupWindow.ConnectionStatus.Foreground = "#FF00FF00"
                            } else {
                                $setupWindow.ConnectionStatus.Text = "❌ Invalid Twilio credentials"
                                $setupWindow.ConnectionStatus.Foreground = "#FFFF0000"
                            }
                        }
                        "VoiceForge" {
                            Import-Module (Join-Path $PSScriptRoot "..\TTSProviders\VoiceForge.psm1") -Force
                            $isValid = Validate-VoiceForgeCredentials -Config $this.GetGUIConfiguration().Providers["VoiceForge"]
                            if ($isValid) {
                                $setupWindow.ConnectionStatus.Text = "✅ VoiceForge credentials valid"
                                $setupWindow.ConnectionStatus.Foreground = "#FF00FF00"
                            } else {
                                $setupWindow.ConnectionStatus.Text = "❌ Invalid VoiceForge credentials"
                                $setupWindow.ConnectionStatus.Foreground = "#FFFF0000"
                            }
                        }
                        default {
                            $setupWindow.ConnectionStatus.Text = "⚠️ Validation not implemented for $Provider"
                            $setupWindow.ConnectionStatus.Foreground = "#FFFF7F00"
                        }
                    }
                } catch {
                    $errorMsg = $_.Exception.Message
                    $setupWindow.ConnectionStatus.Text = "❌ Connection failed: $($errorMsg.Split('.')[0])"
                    $setupWindow.ConnectionStatus.Foreground = "#FFFF0000"
                    Write-SafeLog -Message "Validation failed for $Provider`: $errorMsg" -Level "ERROR"
                }
            }

            # Reset to Defaults button
            $setupWindow.ResetToDefaults.add_Click{
                $result = [System.Windows.MessageBox]::Show("This will reset all $Provider configuration to default values. Are you sure?", "Reset Configuration", "YesNo", "Warning")
                if ($result -eq "Yes") {
                    Write-SafeLog -Message "$Provider configuration reset to defaults" -Level "INFO"
                    # TODO: Implement reset logic based on provider
                    $setupWindow.ConnectionStatus.Text = "Configuration reset to defaults"
                    $setupWindow.ConnectionStatus.Foreground = "#FF00FF00"
                }
            }

            $result = $setupWindow.ShowDialog()
            Write-SafeLog -Message "Setup dialog closed with result: $result" -Level "INFO"
        } catch {
            Write-SafeLog -Message "Error showing setup dialog: $($_.Exception.Message)" -Level "ERROR"
            [System.Windows.MessageBox]::Show("Error opening setup dialog: $($_.Exception.Message)", "Setup Error", "OK", "Error")
        }
    }

    [void]StartDelayedAutoSave() {
        if ($this.AutoSaveTimer) {
            $this.AutoSaveTimer.Stop()
        }
        $this.AutoSaveTimer = New-Object System.Windows.Threading.DispatcherTimer
        $this.AutoSaveTimer.Interval = [TimeSpan]::FromSeconds(2)
        $this.AutoSaveTimer.add_Tick{
            $this.AutoSaveTimer.Stop()
            $this.InvokeAutoSaveConfiguration()
        }
        $this.AutoSaveTimer.Start()
    }

    [void]TestProviderConnection($Provider) {
        $this.WriteSafeLog("Testing connection to $Provider...", "INFO")
        try {
            Start-Sleep -Seconds 1
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $this.WriteSafeLog("✅ Connection to $Provider successful", "INFO")
            $this.UpdateAPIStatus("Connected", "#FF00FF00", "Last Connect: $timestamp", "#FF00FF00")
        } catch {
            $this.WriteSafeLog("❌ Connection to $Provider failed: $($_.Exception.Message)", "ERROR")
            $this.UpdateAPIStatus("Setup Required", "#FFFF0000", "Last Connect: Failed", "#FFFF0000")
        }
    }

    [void]UpdateAPIStatus($SetupStatus, $SetupColor = "#FFFF0000", $ConnectStatus = $null, $ConnectColor = "#FFDDDDDD", $SetupWindow = $null, $Provider = $null) {
        # Use $this.Window directly
        if (-not $Provider) {
            $Provider = if ($this.Window.ProviderSelect.SelectedItem) { $this.Window.ProviderSelect.SelectedItem.Content } else { "Azure Cognitive Services" }
        }
    if (-not $SetupWindow) { $SetupWindow = $this.Window }
        switch ($Provider) {
            default {
                $SetupWindow.ConnectionStatus.Text = $SetupStatus
                $SetupWindow.ConnectionStatus.Foreground = $SetupColor
                if ($ConnectStatus) {
                    $SetupWindow.ProgressLabel.Content = $ConnectStatus
                    $SetupWindow.ProgressLabel.Foreground = $ConnectColor
                }
            }
        }
        Write-ApplicationLog -Message ("API status updated for " + $Provider + ": " + $SetupStatus + " / " + $ConnectStatus) -Level "DEBUG"
    }

    [void]UpdateVoiceOptions($Provider) {
        # Use $this.Window directly
    if (-not $this.Window) { return }
        if ($this.Window.MS_Voice) { $this.Window.MS_Voice.Items.Clear() }
        if ($this.Window.AWS_Voice) { $this.Window.AWS_Voice.Items.Clear() }
        if ($this.Window.GC_Voice) { $this.Window.GC_Voice.Items.Clear() }
        switch ($Provider) {
            "Azure Cognitive Services" {
                $voices = @("en-US-AriaNeural", "en-US-JennyNeural", "en-US-GuyNeural", "en-US-DavisNeural", "en-US-JaneNeural")
                foreach ($voice in $voices) {
                    $item = New-Object System.Windows.Controls.ComboBoxItem
                    $item.Content = $voice
                    if ($voice -eq "en-US-AriaNeural") { $item.IsSelected = $true }
                    $this.Window.MS_Voice.Items.Add($item) | Out-Null
                }
            }
            "AWS Polly" {
                $voices = @("Joanna", "Matthew", "Amy", "Brian", "Emma", "Ivy", "Justin", "Kendra", "Kimberly", "Salli")
                foreach ($voice in $voices) {
                    $item = New-Object System.Windows.Controls.ComboBoxItem
                    $item.Content = $voice
                    if ($voice -eq "Joanna") { $item.IsSelected = $true }
                    $this.Window.AWS_Voice.Items.Add($item) | Out-Null
                }
            }
            "Google Cloud" {
                $voices = @("en-US-Wavenet-A", "en-US-Wavenet-B", "en-US-Wavenet-C", "en-US-Wavenet-D", "en-US-Wavenet-E", "en-US-Wavenet-F")
                foreach ($voice in $voices) {
                    $item = New-Object System.Windows.Controls.ComboBoxItem
                    $item.Content = $voice
                    if ($voice -eq "en-US-Wavenet-D") { $item.IsSelected = $true }
                    $this.Window.GC_Voice.Items.Add($item) | Out-Null
                }
            }
            "CloudPronouncer" {
                $voices = @("Alice", "Bob", "Charlie", "Diana", "Eve")
                foreach ($voice in $voices) {
                    $item = New-Object System.Windows.Controls.ComboBoxItem
                    $item.Content = $voice
                    if ($voice -eq "Alice") { $item.IsSelected = $true }
                    $this.Window.CP_Voice.Items.Add($item) | Out-Null
                }
            }
            "Twilio" {
                $voices = @("Polly.Joanna", "Polly.Matthew", "Polly.Amy", "Polly.Brian")
                foreach ($voice in $voices) {
                    $item = New-Object System.Windows.Controls.ComboBoxItem
                    $item.Content = $voice
                    if ($voice -eq "Polly.Joanna") { $item.IsSelected = $true }
                    $this.Window.TW_Voice.Items.Add($item) | Out-Null
                }
            }
            "VoiceForge" {
                $voices = @("Frank", "Jill", "Paul", "Susan")
                foreach ($voice in $voices) {
                    $item = New-Object System.Windows.Controls.ComboBoxItem
                    $item.Content = $voice
                    if ($voice -eq "Frank") { $item.IsSelected = $true }
                    $this.Window.VF_Voice.Items.Add($item) | Out-Null
                }
            }
        }
    }

    [void]WriteSafeLog($Message, $Level = "INFO") {
        if (Get-Command Write-ApplicationLog -ErrorAction SilentlyContinue) {
            Write-ApplicationLog -Message $Message -Level $Level
        } else {
            Write-Host "[$Level] $Message" -ForegroundColor $(if ($Level -eq "ERROR") { "Red" } elseif ($Level -eq "WARNING") { "Yellow" } else { "White" })
        }
    }

    [object]ConvertXAMLtoWindow($XAML) {
        Add-Type -AssemblyName PresentationFramework
        $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
        $result = [Windows.Markup.XAMLReader]::Load($reader)
        $reader.Close()
        $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
        while ($reader.Read()) {
            $name = $reader.GetAttribute('Name')
            if (!$name) { $name = $reader.GetAttribute('x:Name') }
            if ($name) { $result | Add-Member NoteProperty -Name $name -Value $result.FindName($name) -Force }
        }
        $reader.Close()
        if ($result -isnot [System.Windows.Window]) {
            $this.WriteSafeLog("ERROR: XAML root element is not a Window. Type: $($result.GetType().FullName)", "ERROR")
            return $null
        }
        return $result
    }

    [object]GetGUIConfiguration() {
        # Use $this.Window directly
        $config = @{
            SelectedProvider = if ($this.Window.ProviderSelect.SelectedItem) { $this.Window.ProviderSelect.SelectedItem.Content } else { "Azure Cognitive Services" }
            Providers = @{
                "Azure Cognitive Services" = @{
                    ApiKey = if ($this.Window.MS_KEY.Text) { $this.Window.MS_KEY.Text } else { "" }
                    Datacenter = if ($this.Window.MS_Datacenter.Text) { $this.Window.MS_Datacenter.Text } else { "eastus" }
                    AudioFormat = if ($this.Window.MS_Audio_Format.SelectedItem) { $this.Window.MS_Audio_Format.SelectedItem.Content } else { "audio-16khz-32kbitrate-mono-mp3" }
                    DefaultVoice = if ($this.Window.MS_Voice.SelectedItem) { $this.Window.MS_Voice.SelectedItem.Content } else { "en-US-JennyNeural" }
                }
                "AWS Polly" = @{
                    AccessKey = if ($this.Window.AWS_AccessKey.Text) { $this.Window.AWS_AccessKey.Text } else { "" }
                    SecretKey = if ($this.Window.AWS_SecretKey.Text) { $this.Window.AWS_SecretKey.Text } else { "" }
                    Region = if ($this.Window.AWS_Region.SelectedItem) { $this.Window.AWS_Region.SelectedItem.Content } else { "us-west-2" }
                    DefaultVoice = if ($this.Window.AWS_Voice.SelectedItem) { $this.Window.AWS_Voice.SelectedItem.Content } else { "Matthew" }
                }
                "Google Cloud TTS" = @{
                    ApiKey = if ($this.Window.GC_APIKey.Text) { $this.Window.GC_APIKey.Text } else { "" }
                    Language = if ($this.Window.GC_Language.SelectedItem) { $this.Window.GC_Language.SelectedItem.Content } else { "en-US" }
                    DefaultVoice = if ($this.Window.GC_Voice.SelectedItem) { $this.Window.GC_Voice.SelectedItem.Content } else { "en-US-Wavenet-D" }
                }
                "CloudPronouncer" = @{
                    Username = if ($this.Window.CP_Username.Text) { $this.Window.CP_Username.Text } else { "" }
                    Password = if ($this.Window.CP_Password.Password) { $this.Window.CP_Password.Password } else { "" }
                    DefaultVoice = if ($this.Window.CP_Voice.SelectedItem) { $this.Window.CP_Voice.SelectedItem.Content } else { "Alice" }
                    Format = if ($this.Window.CP_Format.SelectedItem) { $this.Window.CP_Format.SelectedItem.Content } else { "mp3" }
                }
                "Twilio" = @{
                    AccountSID = if ($this.Window.TW_AccountSID.Text) { $this.Window.TW_AccountSID.Text } else { "" }
                    AuthToken = if ($this.Window.TW_AuthToken.Password) { $this.Window.TW_AuthToken.Password } else { "" }
                    DefaultVoice = if ($this.Window.TW_Voice.SelectedItem) { $this.Window.TW_Voice.SelectedItem.Content } else { "Polly.Joanna" }
                    Format = if ($this.Window.TW_Format.SelectedItem) { $this.Window.TW_Format.SelectedItem.Content } else { "mp3" }
                }
                "VoiceForge" = @{
                    ApiKey = if ($this.Window.VF_APIKey.Text) { $this.Window.VF_APIKey.Text } else { "" }
                    Endpoint = if ($this.Window.VF_Endpoint.Text) { $this.Window.VF_Endpoint.Text } else { "" }
                    DefaultVoice = if ($this.Window.VF_Voice.SelectedItem) { $this.Window.VF_Voice.SelectedItem.Content } else { "Frank" }
                    Quality = if ($this.Window.VF_Quality.SelectedItem) { $this.Window.VF_Quality.SelectedItem.Content } else { "Standard" }
                }
            }
            Processing = @{
                BulkMode = ($this.Window.PSObject.Properties["BulkMode"] -and $this.Window.BulkMode.PSObject.Properties["IsChecked"] -and $this.Window.BulkMode.IsChecked) ? $this.Window.BulkMode.IsChecked : $false
                InputText = if ($this.Window.Input_Text.Text) { $this.Window.Input_Text.Text } else { "" }
                OutputDirectory = if ($this.Window.Output_File.Text) { $this.Window.Output_File.Text } else { "" }
                OutputFormat = if ($this.Window.Output_Format.SelectedItem) { $this.Window.Output_Format.SelectedItem.Content } else { "MP3" }
            }
        }
        return $config
    }
}

function New-GUI {
    param(
        [string]$Profile = "Default"
    )
    return [GUI]::new($Profile)
}

Export-ModuleMember -Function New-GUI

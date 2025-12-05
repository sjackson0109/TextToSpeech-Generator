# GUIModule.psm1 - Unified GUI module for TextToSpeech Generator
# Consolidates all GUI logic, event handlers, configuration, and provider setup Dialogueueueueueues

# Load required WPF assemblies for GUI functionality - check first, then load if needed
if (-not [System.Type]::GetType('System.Windows.Markup.XamlReader', $false)) {
	try {
		Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
	} catch {
		$msg = "Unable to load PresentationFramework. GUI functions will be disabled. Exception: $($_.Exception.Message)"
		Write-Warning $msg
		if ($_.Exception.LoaderExceptions) {
			foreach ($loaderEx in $_.Exception.LoaderExceptions) {
				Write-Warning "LoaderException: $($loaderEx.Message)"
			}
		}
		if ($_.Exception.GetType().FullName) {
			Write-Warning "Exception type: $($_.Exception.GetType().FullName)"
		}
		return
	}
}

# Similarly for WinForms if needed
if (-not [System.Type]::GetType('System.Windows.Forms.Form', $false)) {
	try {
		Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
	} catch {
		$msg = "Unable to load System.Windows.Forms. GUI functions may be limited. Exception: $($_.Exception.Message)"
		Write-Warning $msg
		if ($_.Exception.LoaderExceptions) {
			foreach ($loaderEx in $_.Exception.LoaderExceptions) {
				Write-Warning "LoaderException: " + $($loaderEx.Message)
			}
		}
		if ($_.Exception.GetType().FullName) {
			Write-Warning "Exception type: " + $($_.Exception.GetType().FullName)
		}
	}
}


# Unified GUI class and all supporting functions
# (Migrated from GUI.psm1, ModernGUI.psm1, and all legacy GUI/*.psm1)
if (-not (Get-Module -Name 'Logging')) {
	Import-Module (Join-Path $PSScriptRoot 'Logging.psm1')
}

# Module-wide version variable
$script:TTSVersion = 'v3.1'

class GUI {
	[string]$CurrentProfile
	[object]$Window
	[bool]$AutoSaveEnabled
	[object]$ConfigManager
	[object]$AutoSaveTimer
	[string]$Version = $script:TTSVersion
	[string]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="TextToSpeech Generator" Width="900" SizeToContent="Height" MinHeight="600" MaxHeight="1000" 
        Background="#FF1E1E1E" WindowStartupLocation="CenterScreen" ResizeMode="CanResize">
    <Window.Resources>
        <Style TargetType="GroupBox">
            <Setter Property="BorderBrush" Value="#FF3E3E42"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Background" Value="#FF2D2D30"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Padding" Value="10"/>
            <Setter Property="Margin" Value="10,5"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="11"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="Padding" Value="0"/>
        </Style>
        <Style TargetType="TextBlock">
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Background" Value="Transparent"/>
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="Background" Value="#FF3E3E42"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Height" Value="26"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="BorderBrush" Value="#FF555555"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="20"/>
                            </Grid.ColumnDefinitions>
                            
                            <Border x:Name="Border"
                                  Grid.ColumnSpan="2"
                                  Background="#FF3E3E42"
                                  BorderBrush="#FF555555"
                                  BorderThickness="1"/>
                            
                            <ToggleButton x:Name="ToggleButton"
                                        Grid.ColumnSpan="2"
                                        Focusable="False"
                                        IsChecked="{Binding Path=IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}"
                                        ClickMode="Press"
                                        Background="Transparent"
                                        BorderThickness="0"/>
                            
                            <ContentPresenter x:Name="ContentSite"
                                            Grid.Column="0"
                                            Content="{TemplateBinding SelectionBoxItem}"
                                            ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                            ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}"
                                            VerticalAlignment="Center"
                                            HorizontalAlignment="Left"
                                            Margin="5,0,5,0"
                                            IsHitTestVisible="False"/>
                            
                            <Path x:Name="Arrow"
                                Grid.Column="1"
                                Fill="White"
                                HorizontalAlignment="Center"
                                VerticalAlignment="Center"
                                Data="M 0 0 L 4 4 L 8 0 Z"
                                IsHitTestVisible="False"/>
                            
                            <Popup x:Name="Popup"
                                 Placement="Bottom"
                                 IsOpen="{TemplateBinding IsDropDownOpen}"
                                 AllowsTransparency="True"
                                 Focusable="False"
                                 PopupAnimation="Slide">
                                <Grid x:Name="DropDown"
                                    SnapsToDevicePixels="True"
                                    MinWidth="{TemplateBinding ActualWidth}"
                                    MaxHeight="{TemplateBinding MaxDropDownHeight}">
                                    <Border x:Name="DropDownBorder"
                                          Background="#FF3E3E42"
                                          BorderThickness="1"
                                          BorderBrush="#FF555555"/>
                                    <ScrollViewer Margin="1" SnapsToDevicePixels="True">
                                        <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained"/>
                                    </ScrollViewer>
                                </Grid>
                            </Popup>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Setter Property="ItemContainerStyle">
                <Setter.Value>
                    <Style TargetType="ComboBoxItem">
                        <Setter Property="Background" Value="#FF3E3E42"/>
                        <Setter Property="Foreground" Value="White"/>
                        <Setter Property="Padding" Value="5,3"/>
                        <Style.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter Property="FontWeight" Value="Bold"/>
                                <Setter Property="Background" Value="#FF3E3E42"/>
                            </Trigger>
                            <Trigger Property="IsHighlighted" Value="True">
                                <Setter Property="Background" Value="#FF505050"/>
                            </Trigger>
                        </Style.Triggers>
                    </Style>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#FF3E3E42"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#FF555555"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="11"/>
        </Style>
    </Window.Resources>
    
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Header Section -->
        <GroupBox Grid.Row="0" Header="" Padding="12,10,12,8" BorderThickness="0" BorderBrush="#FF3E3E42" 
                  Background="#FF2D2D30" Margin="10,6,10,6">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="44"/>
                    <ColumnDefinition Width="44"/>
                    <ColumnDefinition Width="44"/>
                </Grid.ColumnDefinitions>
                
                <!-- Left: Title -->
                <StackPanel Grid.Column="0" Orientation="Vertical">
                    <TextBlock x:Name="HeaderTitle" Text="TTS Generator" FontSize="18" FontWeight="SemiBold" Foreground="White"/>
                </StackPanel>
                
                <!-- Save Config Button -->
                <StackPanel Grid.Column="1" Orientation="Vertical">
                    <Button x:Name="SaveConfig" Content="Save" Background="#FF28A745" Foreground="White" BorderThickness="0"/>
                </StackPanel>
                
                <!-- Load Config Button -->
                <StackPanel Grid.Column="2" Orientation="Vertical">
                    <Button x:Name="LoadConfig" Content="Load" Background="#FF0E639C" Foreground="White" BorderThickness="0"/>
                </StackPanel>
                
                <!-- Reset Config Button -->
                <StackPanel Grid.Column="3" Orientation="Vertical">
                    <Button x:Name="ResetConfig" Content="Reset" Background="#FFDC3545" Foreground="White" BorderThickness="0"/>
                </StackPanel>
            </Grid>
        </GroupBox>
        
        <!-- Main Content -->
        <StackPanel Grid.Row="1">
            <!-- Provider Selection -->
            <GroupBox Header="Provider Selection">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    
                    <Label Content="Provider:" Grid.Row="0" Grid.Column="0" Margin="0,4,8,0" VerticalAlignment="Center"/>
					<ComboBox x:Name="ProviderSelect" Grid.Row="0" Grid.Column="1" Margin="0,4,0,0" VerticalAlignment="Center"/>
                    <Button x:Name="Configure" Grid.Row="0" Grid.Column="2" Content="Configure" Height="26" MinWidth="92" 
                            Margin="10,4,0,0" Background="#FF0E639C" Foreground="White" BorderThickness="0" 
                            FontWeight="Normal" VerticalAlignment="Center"/>
                    <Button x:Name="Connect" Grid.Row="0" Grid.Column="3" Content="Connect" Height="26" MinWidth="92" 
                            Margin="8,4,0,0" Background="#FF28A745" Foreground="White" BorderThickness="0" 
                            FontWeight="Normal" VerticalAlignment="Center"/>
                    <TextBlock x:Name="ConfigurationStatus" Grid.Row="1" Grid.Column="2" Text="Not Configured" 
                               Foreground="#FFFFCC00" Margin="10,4,0,0" VerticalAlignment="Top" FontSize="11" 
                               HorizontalAlignment="Center" Visibility="Visible"/>
                    <StackPanel Grid.Row="1" Grid.Column="3" Orientation="Horizontal" VerticalAlignment="Center" Margin="10,4,0,0">
                        <TextBlock x:Name="CredentialsStatus" Text="Not Connected" Foreground="#FFFF6B6B" Margin="0,0,12,0" 
                                   VerticalAlignment="Center" FontSize="11"/>
                    </StackPanel>
                </Grid>
            </GroupBox>

            <!-- Voice Selection -->
            <GroupBox Header="Voice Selection" Margin="10,5">
                <Grid>
                    <Grid.ColumnDefinitions>
						<ColumnDefinition Width="Auto"/>   <!-- Voice label -->
						<ColumnDefinition Width="*"/>      <!-- Voice combo -->

						<ColumnDefinition Width="Auto"/>   <!-- Language label -->
						<ColumnDefinition Width="180"/>    <!-- Language combo -->

						<ColumnDefinition Width="Auto"/>   <!-- Format label -->
						<ColumnDefinition Width="180"/>    <!-- Format combo -->

						<ColumnDefinition Width="Auto"/>   <!-- Quality label -->
						<ColumnDefinition Width="120"/>    <!-- Quality combo -->

						<ColumnDefinition Width="Auto"/>   <!-- Advanced button -->
                    </Grid.ColumnDefinitions>
                    
					<!-- Dynamic voice options will be rendered here after provider connection -->
					<StackPanel x:Name="VoiceOptionsPanel" Grid.ColumnSpan="9" Orientation="Horizontal" Margin="0,0,0,0"/>
                </Grid>
            </GroupBox>

            <!-- Input & Output -->
            <GroupBox Header="Input &amp; Output" Margin="10,5">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="50"/> <!-- Left Labels -->
                        <ColumnDefinition Width="570"/> <!-- Paths -->
                        <ColumnDefinition Width="32"/> <!-- Browse Buttons -->
                        <ColumnDefinition Width="70"/> <!-- Checkboxes -->
                        <ColumnDefinition Width="95"/> <!-- Far right Button -->
                    </Grid.ColumnDefinitions>
                    
                    <Label Content="File:" Grid.Row="0" Grid.Column="0" Margin="0,4,12,0" VerticalAlignment="Center"/>
                    <TextBox x:Name="InputFile" Grid.Row="0" Grid.Column="1" Height="26" Margin="0,4,0,0" 
                             Background="#FF3E3E42" Foreground="White" BorderThickness="1" BorderBrush="#FF555555"
                             VerticalContentAlignment="Center" Padding="5,0"/>
                    <Button Grid.Row="0" Grid.Column="2" x:Name="BrowseInputButton" Content="..." Width="28" Height="26" 
                            Padding="0" FontSize="16" Background="#FF3E3E42" Foreground="White" BorderThickness="1"
                            BorderBrush="#FF555555" Margin="6,4,0,0" VerticalAlignment="Center"/>
					<CheckBox x:Name="BulkMode" Grid.Row="0" Grid.Column="3" VerticalAlignment="Center" Margin="5,4,5,0" Foreground="White" Width="70">
						<TextBlock Text="Bulk Mode" TextWrapping="Wrap" />
					</CheckBox>
                    <Button x:Name="ImportCSV" Grid.Row="0" Grid.Column="4" Content="Import CSV" Height="26" 
                            Margin="0,4,0,0" Background="#FF0E639C" Foreground="White" BorderThickness="0" 
                            VerticalAlignment="Center"/>
                    
                    <Label Content="Output:" Grid.Row="1" Grid.Column="0" Margin="0,4,12,0" VerticalAlignment="Center"/>
                    <TextBox x:Name="OutputFile" Grid.Row="1" Grid.Column="1" Height="26" Margin="0,4,0,0" 
                             Background="#FF3E3E42" Foreground="White" BorderThickness="1" BorderBrush="#FF555555"
                             VerticalContentAlignment="Center" Padding="5,0"/>
                    <Button Grid.Row="1" Grid.Column="2" x:Name="BrowseOutputButton" Content="..." Width="28" Height="26" 
                            Padding="0" FontSize="16" Background="#FF3E3E42" Foreground="White" BorderThickness="1"
                            BorderBrush="#FF555555" Margin="6,4,0,0" VerticalAlignment="Center"/>
                    <Label Content="File Type:" Grid.Row="1" Grid.Column="3" Margin="5,4,12,0" VerticalAlignment="Center"/>
                    <ComboBox x:Name="FileTypeSelect" Grid.Row="1" Grid.Column="4" Height="26" Margin="0,4,0,0" 
                              VerticalContentAlignment="Center" Width="95">
                        <ComboBoxItem Content="MP3"/>
                    </ComboBox>
                    
                    <Label Content="Text:" Grid.Row="2" Grid.Column="0" Margin="0,8,12,0" VerticalAlignment="Top"/>
                    <TextBox x:Name="TextInput" Grid.Row="2" Grid.Column="1" Grid.ColumnSpan="4" Height="80" 
                             Margin="0,8,0,0" Background="#FF3E3E42" Foreground="White" BorderThickness="1" 
                             BorderBrush="#FF555555" Padding="5" TextWrapping="Wrap" AcceptsReturn="True" 
                             VerticalScrollBarVisibility="Auto" Text="Enter your text here for single mode processing..."/>
                </Grid>
            </GroupBox>

            <!-- Ready -->
            <GroupBox Header="Ready" Margin="10,5">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <Button x:Name="GenerateSpeech" Grid.Column="0" Height="32" MinWidth="240" Margin="20,0,20,0" 
                            Background="#FF007ACC" Foreground="White" BorderThickness="0" VerticalAlignment="Center">
                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                            <TextBlock FontFamily="Segoe MDL2 Assets" FontSize="14" Text="&#xE768;" Margin="0,0,8,0" 
                                       VerticalAlignment="Center"/>
                            <TextBlock Text="Generate Speech" FontWeight="Bold" FontSize="12" VerticalAlignment="Center"/>
                        </StackPanel>
                    </Button>
                </Grid>
            </GroupBox>

            <!-- Progress -->
            <GroupBox Header="Progress" Margin="10,5">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    
                    <ProgressBar x:Name="ProgressBar" Grid.Row="0" Grid.Column="0" Grid.ColumnSpan="2" Height="10" 
                                 Minimum="0" Maximum="100" Value="0" Margin="0,0,0,6" Background="#FF3E3E42" 
                                 BorderThickness="0"/>
                    <TextBlock x:Name="ProgressStatus" Grid.Row="1" Grid.Column="0" 
                               Text="Ready - Select provider and configure settings to begin" Foreground="#FFDDDDDD" 
                               FontSize="11" VerticalAlignment="Center"/>
                    <StackPanel Grid.Row="1" Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Right" 
                                VerticalAlignment="Center">
                        <TextBlock x:Name="APIStatus" Text="API: Not Tested" Foreground="#FFFF6B6B" FontSize="11" 
                                   VerticalAlignment="Center"/>
                    </StackPanel>
                </Grid>
            </GroupBox>

            <!-- Activity Log -->
            <GroupBox Header="Activity Log" Margin="10,8,10,10">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    
                    <TextBox x:Name="LogOutput" Grid.Row="0" Height="120" FontSize="10" FontFamily="Consolas" 
                             IsReadOnly="True" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" 
                             Background="#FF0C0C0C" Foreground="#FFDCDCDC" BorderThickness="0" Padding="5" 
                             TextWrapping="Wrap"/>
                    <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Left" Margin="0,4,0,0">
                        <Button x:Name="ClearLog" Width="85" Height="26" Content="Clear Log" Background="#FF3E3E42" 
                                Foreground="White" BorderThickness="0" Margin="0,0,5,0"/>
                        <Button x:Name="ExportLog" Width="85" Height="26" Content="Export Log" Background="#FF3E3E42" 
                                Foreground="White" BorderThickness="0"/>
                    </StackPanel>
                </Grid>
            </GroupBox>
        </StackPanel>
    </Grid>
</Window>
"@

	GUI([string]$profile = "Default") {
		$this.CurrentProfile = $profile
		$this.AutoSaveEnabled = $true
		$this.Window = $null
		$this.ConfigManager = $null
		$this.AutoSaveTimer = $null
		
		# Automatically initialise the modern GUI
		$this.initialiseModernGUI($profile, $null)
	}

	[object]initialiseModernGUI($Profile = "Default", $ConfigurationManager = $null) {
		$this.CurrentProfile = $Profile
		$this.ConfigManager = $ConfigurationManager
		$this.WriteSafeLog("Creating Modern GUI with profile: $Profile", "INFO")
		
		# Verify WPF availability before proceeding
		$wpfAvailable = $false
		try {
			# Ensure PresentationFramework.dll is loaded
			Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
			
			# Try to access the key WPF types directly
			$null = [System.Windows.Markup.XamlReader]
			$null = [System.Windows.Window]
			$null = [System.Windows.Visibility]
			$null = [System.Windows.WindowState]
			
			$wpfAvailable = $true
			$this.WriteSafeLog("DEBUG: WPF types verified and available", "DEBUG")
		} catch {
			$this.WriteSafeLog("ERROR: PresentationFramework assembly could not be loaded or WPF types unavailable: $($_.Exception.Message)", "ERROR")
		}
		
		if (-not $wpfAvailable) {
			$this.WriteSafeLog("ERROR: WPF not available in this environment. GUI will not be shown. Please run in Windows PowerShell with .NET Framework.", "ERROR")
			return $null
		}
		
		try {
			# Load optional assemblies for GUI functionality
			[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
			[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

			$this.WriteSafeLog("DEBUG: About to call ConvertXAMLtoWindow with XAML length: $($this.XAML.Length)", "DEBUG")
			# If window is null or closed, re-create it
			if ($null -eq $this.Window -or ($this.Window.GetType().FullName -ne 'System.Windows.Window' -or -not $this.Window.IsLoaded)) {
				$this.Window = $this.ConvertXAMLtoWindow($this.XAML)
				$this.WriteSafeLog("DEBUG: ConvertXAMLtoWindow returned: $($this.Window -ne $null)", "DEBUG")
			}

			if ($null -eq $this.Window -or ($this.Window.GetType().FullName -ne 'System.Windows.Window' -or -not $this.Window.IsLoaded)) {
				$this.WriteSafeLog("ERROR: Failed to create GUI window from XAML.", "ERROR")
				return $null
			}

			# Set the window title with version
			$this.Window.Title = "TextToSpeech Generator $($this.Version)"

			# Update header title with version
			if ($this.Window.HeaderTitle) {
				$this.Window.HeaderTitle.Text = "TextToSpeech Generator $($this.Version)"
			}

			# initialise Voice Selection to empty state (before wiring events)
			$this.ClearVoiceOptions()

			# Wire up event handlers
			$this.WireEventHandlers()

			# Set global window reference for external logging modules
			$global:window = $this.Window

			# Debug: Check provider dropdown
			if ($this.Window.ProviderSelect) {
				$providerCount = $this.Window.ProviderSelect.Items.Count
				$this.WriteSafeLog("ProviderSelect has $providerCount items", "INFO")
				if ($providerCount -eq 0) {
					$this.WriteSafeLog("ProviderSelect dropdown is empty! Adding providers manually...", "WARNING")
					$this.PopulateProviderDropdown()
				} else {
					$this.WriteSafeLog("ProviderSelect items loaded from XAML successfully", "INFO")
				}
			} else {
				$this.WriteSafeLog("ProviderSelect control not found in window!", "ERROR")
			}

			# Show the window using ShowDialog for modal Behaviour
			if ($this.Window.Visibility -eq [System.Windows.Visibility]::Visible) {
				$this.WriteSafeLog("Window is already visible. Hiding before ShowDialog to avoid error.", "WARNING")
				$this.Window.Hide()
			}
			if ($this.Window.IsLoaded -and $this.Window.Visibility -ne [System.Windows.Visibility]::Visible) {
				$this.WriteSafeLog("Window is loaded but not visible, showing Dialogue.", "DEBUG")
				$null = $this.Window.ShowDialog()
			} elseif (-not $this.Window.IsLoaded) {
				$this.WriteSafeLog("Window not loaded, creating and showing Dialogue.", "DEBUG")
				$this.Window = $this.ConvertXAMLtoWindow($this.XAML)
				$null = $this.Window.ShowDialog()
			}

			$this.WriteSafeLog("Modern GUI initialised successfully", "INFO")
			# Auto-load configuration if it exists
			$this.AutoLoadConfiguration()
			return $this.Window
		} catch {
			$this.WriteSafeLog("ERROR: Exception during GUI initialisation: $($_.Exception.Message)", "ERROR")
			return $null
		}
	}

	[void]InvokeAutoSaveConfiguration() {
		# ... Auto-save logic ...
	}

	[void]AutoLoadConfiguration() {
		<#
		.SYNOPSIS
			Automatically loads saved configuration on startup
		#>
		try {
			$configPath = Join-Path $PSScriptRoot "..\config.json"
			
			if (-not (Test-Path $configPath)) {
				$this.WriteSafeLog("No saved configuration found - starting with defaults", "INFO")
				return
			}
			
			$this.WriteSafeLog("Auto-loading configuration from: $configPath", "INFO")
			
			# Load configuration from JSON file
			$config = Get-Content $configPath -Raw | ConvertFrom-Json
			
			# Apply to GUI fields
			if ($config.Provider) {
						foreach ($item in $this.Window.ProviderSelect.Items) {
							if ($item.Content -eq $config.Provider) {
								$this.Window.ProviderSelect.SelectedItem = $item
								$this.WriteSafeLog("Auto-loaded provider: $($config.Provider)", "DEBUG")
								break
							}
						}
			}
			# Voice, Language, Format, Quality controls are now dynamic; selection will be handled after provider connection
			
			# Load provider-specific configurations into provider instances
			if ($config.ProviderConfigurations -and $config.Provider) {
				$providerConfig = $config.ProviderConfigurations.($config.Provider)
				if ($providerConfig) {
					$providerInstance = Get-TTSProvider -ProviderName $config.Provider
					if ($providerInstance) {
						# Convert PSCustomObject to hashtable
						$configHash = @{}
						$providerConfig.PSObject.Properties | ForEach-Object {
							$configHash[$_.Name] = $_.Value
						}
						$providerInstance.Configuration = $configHash
						$this.WriteSafeLog("Auto-loaded configuration for provider: $($config.Provider)", "INFO")
					}
				}
			}
			
		} catch {
			$this.WriteSafeLog("Failed to auto-load configuration: $($_.Exception.Message)", "WARNING")
		}
	}

	[void]ShowProviderConfigurationDialog($Provider) {
		<#
		.SYNOPSIS
			Shows provider-specific configuration Dialogue
		.DESCRIPTION
			Calls the provider's ShowConfigurationDialog method
		#>
		
		try {
			# Get provider instance
			$providerInstance = Get-TTSProvider -ProviderName $Provider
			
			if (-not $providerInstance) {
				$this.WriteSafeLog("Provider instance not found for $Provider", "ERROR")
				[System.Windows.MessageBox]::Show(
					"Provider not found. Please ensure the provider module is loaded.",
					"Configuration Error",
					[System.Windows.MessageBoxButton]::OK,
					[System.Windows.MessageBoxImage]::Error
				)
				return
			}
			
			# Check if provider has ShowConfigurationDialog method
			if (-not ($providerInstance.PSObject.Methods.Name -contains 'ShowConfigurationDialog')) {
				$this.WriteSafeLog("Configuration not yet implemented for $Provider", "WARNING")
				[System.Windows.MessageBox]::Show(
					"Configuration Dialogue is not yet implemented for $Provider",
					"Configuration",
					[System.Windows.MessageBoxButton]::OK,
					[System.Windows.MessageBoxImage]::Information
				)
				return
			}
			
			# Get current configuration - first try provider instance, then load from config.json
			$currentConfig = @{}
			$this.WriteSafeLog("Getting configuration for provider: $Provider", "INFO")
			if ($providerInstance.Configuration -and $providerInstance.Configuration.Count -gt 0) {
				$currentConfig = $providerInstance.Configuration
				$this.WriteSafeLog("Using configuration from provider instance ($($currentConfig.Count) keys)", "INFO")
			} else {
				# Load from config.json if provider instance doesn't have config
				try {
					$configPath = Join-Path $PSScriptRoot "..\config.json"
					if (Test-Path $configPath) {
						$savedConfig = Get-Content $configPath -Raw | ConvertFrom-Json
						$this.WriteSafeLog("Loaded config.json, checking for ProviderConfigurations.$Provider", "INFO")
						
						# Debug: List all provider names in config
						if ($savedConfig.ProviderConfigurations) {
							$availableProviders = $savedConfig.ProviderConfigurations.PSObject.Properties.Name -join ', '
							$this.WriteSafeLog("Available providers in config: $availableProviders", "INFO")
						}
						
						if ($savedConfig.ProviderConfigurations -and $savedConfig.ProviderConfigurations.$Provider) {
							# Convert PSCustomObject to hashtable
							$providerConfig = $savedConfig.ProviderConfigurations.$Provider
							$providerConfig.PSObject.Properties | ForEach-Object {
								$currentConfig[$_.Name] = $_.Value
							}
							$this.WriteSafeLog("Loaded saved configuration for $Provider from config.json - Keys: $($currentConfig.Keys -join ', ')", "INFO")
						} else {
							$this.WriteSafeLog("No saved configuration found for $Provider in config.json", "INFO")
						}
					}
				} catch {
					$this.WriteSafeLog("Failed to load saved config for $Provider`: $($_.Exception.Message)", "WARNING")
				}
			}
			
			# Call provider's configuration Dialogue
			$this.WriteSafeLog("Opening configuration Dialogue for $Provider", "INFO")
			$this.WriteSafeLog("CurrentConfig for $Provider has $($currentConfig.Count) keys: $($currentConfig.Keys -join ', ')", "INFO")
			$result = $providerInstance.ShowConfigurationDialog($currentConfig)
			
				# Update GUI if configuration was saved
				if ($result -and $result.Success) {
					# Update provider instance configuration with all returned fields
					$providerInstance.Configuration = @{}
					foreach ($key in $result.Keys) {
						if ($key -ne 'Success') {
							$providerInstance.Configuration[$key] = $result[$key]
						}
					}
					$this.WriteSafeLog("Provider configuration updated in instance for $Provider - Keys: $($providerInstance.Configuration.Keys -join ', ')", "INFO")
					$this.WriteSafeLog("Provider configuration values - ApiKey length: $($providerInstance.Configuration.ApiKey.Length)", "INFO")
					
					# Hide the "Not Configured" warning label since we now have configuration
					if ($this.Window.ConfigurationStatus) {
						$this.Window.ConfigurationStatus.Visibility = [System.Windows.Visibility]::Collapsed
					}
					
					$this.WriteSafeLog("Configuration saved for $Provider", "INFO")
				}		} catch {
			$this.WriteSafeLog("Error showing configuration Dialogue for $Provider`: $($_.Exception.Message)", "ERROR")
			[System.Windows.MessageBox]::Show(
				"Error opening configuration Dialogue:`n$($_.Exception.Message)",
				"Configuration Error",
				[System.Windows.MessageBoxButton]::OK,
				[System.Windows.MessageBoxImage]::Error
			)
		}
	}

	[void]StartDelayedAutoSave() {
		# ... Delayed auto-save logic ...
	}

	[void]TestProviderConnection($Provider) {
		# ... Test provider connection logic ...
	}

	[void]UpdateAPIStatus($SetupStatus, $SetupColor = "#FFFF0000", $ConnectStatus = $null, $ConnectColor = "#FFDDDDDD", $SetupWindow = $null, $Provider = $null) {
		# ... Update API status logic ...
	}

	[void]UpdateVoiceOptions($Provider) {
		# Remove all hard-coded clearing and population of voice option controls
		# Instead, dynamically create and populate controls strictly from provider response
		# Hide or disable controls for unsupported options

		# Remove all items from the voice options panel
		$voicePanel = $this.Window.FindName('VoiceOptionsPanel')
		if ($null -eq $voicePanel) {
			$this.WriteSafeLog('VoiceOptionsPanel not found in window', 'ERROR')
			return
		}
		$voicePanel.Children.Clear()

		# Get provider instance
		$providerInstance = Get-TTSProvider -ProviderName $Provider
		if (-not $providerInstance) {
			$this.WriteSafeLog("Provider instance not found for $Provider", "ERROR")
			return
		}

		# Get dynamic voice options from provider class
		$voiceOptions = $null
		if ($providerInstance.PSObject.Methods.Name -contains 'GetVoiceOptions') {
			$voiceOptions = $providerInstance.GetVoiceOptions()
		} elseif ($providerInstance.PSObject.Methods.Name -contains 'GetAvailableVoices') {
			$voiceOptions = @{ Voices = $providerInstance.GetAvailableVoices() }
		} else {
			$this.WriteSafeLog("Provider $Provider does not implement GetVoiceOptions or GetAvailableVoices", "WARNING")
			return
		}

		# Dynamically create controls for each option returned by provider
		foreach ($key in $voiceOptions.Keys) {
			if ($key -eq 'Defaults' -or $key -eq 'SupportsAdvanced') { continue }
			$values = $voiceOptions[$key]
			if ($null -eq $values) { continue }
			if ($values -is [System.Collections.IEnumerable]) {
				$array = @($values)
				if ($array.Count -eq 0) { continue }
			}

			# Create label
			$label = New-Object System.Windows.Controls.Label
			$label.Content = $key
			$voicePanel.Children.Add($label)

			# Create ComboBox for array options
			if ($values -is [System.Collections.IEnumerable] -and @($values).Count -gt 0) {
				$combo = New-Object System.Windows.Controls.ComboBox
				foreach ($val in $values) {
					$item = New-Object System.Windows.Controls.ComboBoxItem
					$item.Content = $val
					if ($voiceOptions.Defaults[$key] -and $val -eq $voiceOptions.Defaults[$key]) {
						$item.IsSelected = $true
					}
					$combo.Items.Add($item) | Out-Null
				}
				$voicePanel.Children.Add($combo)
			} elseif ($values -is [bool]) {
				# Create CheckBox for boolean options
				$check = New-Object System.Windows.Controls.CheckBox
				$check.Content = $key
				$check.IsChecked = $values
				$voicePanel.Children.Add($check)
			} elseif ($values -is [int] -or $values -is [double]) {
				# Create Slider for numeric options
				$slider = New-Object System.Windows.Controls.Slider
				$slider.Minimum = 0
				$slider.Maximum = 100
				$slider.Value = $values
				$voicePanel.Children.Add($slider)
			}
		}

		# Enable/disable Advanced button based on provider support
		if ($this.Window.AdvancedVoice) {
			$this.Window.AdvancedVoice.IsEnabled = $voiceOptions.SupportsAdvanced
		}

		$this.WriteSafeLog("Voice options updated for provider: $Provider", "INFO")
	}

	[void]ClearVoiceOptions() {
		# Clear all dynamic voice option controls from the panel
		$voicePanel = $this.Window.FindName('VoiceOptionsPanel')
		if ($null -ne $voicePanel) {
			$voicePanel.Children.Clear()
		}
		if ($this.Window.AdvancedVoice) {
			$this.Window.AdvancedVoice.IsEnabled = $false
		}
		$this.WriteSafeLog("Voice options cleared - waiting for provider selection", "INFO")
	}

	[void]PopulateProviderDropdown() {
		<#
		.SYNOPSIS
			Manually populates the Provider dropdown if XAML items didn't load
		#>
		$this.WriteSafeLog("Populating provider dropdown manually", "INFO")
		
		# Use Get-AvailableProviders to get provider table and extract names
		if (Get-Command Get-AvailableProviders -ErrorAction SilentlyContinue) {
			$providerTable = Get-AvailableProviders
			$providerNames = $providerTable | Select-Object -ExpandProperty Name
			$this.Window.ProviderSelect.Items.Clear()
			foreach ($providerName in $providerNames) {
				$item = New-Object System.Windows.Controls.ComboBoxItem
				$item.Content = $providerName
				$this.Window.ProviderSelect.Items.Add($item) | Out-Null
			}
			# Select first provider by default
			if ($this.Window.ProviderSelect.Items.Count -gt 0) {
				$this.Window.ProviderSelect.SelectedIndex = 0
				$this.WriteSafeLog("Provider dropdown populated with $($this.Window.ProviderSelect.Items.Count) providers", "INFO")
			}
		} else {
			$this.WriteSafeLog("Get-AvailableProviders function not found. Provider dropdown not populated.", "ERROR")
		}
	}

	[void]WireEventHandlers() {
		# Capture $this for use in closures
		$gui = $this
		
		# Provider selection changed event
		$this.Window.ProviderSelect.add_SelectionChanged({
			$selectedProvider = $gui.Window.ProviderSelect.SelectedItem.Content
			if ($selectedProvider) {
				$gui.WriteSafeLog("Provider selected: $selectedProvider", "INFO")
				
				# Re-enable voice controls
				# Voice, Language, Format, Quality controls are now dynamic; enablement handled via VoiceOptionsPanel
				
				# Reset credentials status when provider changes
				if ($gui.Window.CredentialsStatus) {
					$gui.Window.CredentialsStatus.Text = "Not Connected"
					$gui.Window.CredentialsStatus.Foreground = "#FFFF6B6B"
				}
				
				# Check if provider has configuration and show/hide ConfigurationStatus
				if ($gui.Window.ConfigurationStatus) {
					$providerInstance = Get-TTSProvider -ProviderName $selectedProvider
					$hasConfig = $false
					
					# Check provider instance configuration
					if ($providerInstance -and $providerInstance.Configuration -and $providerInstance.Configuration.Count -gt 0) {
						$hasConfig = $true
					} else {
						# Check config.json
						try {
							$configPath = Join-Path $PSScriptRoot "..\config.json"
							if (Test-Path $configPath) {
								$savedConfig = Get-Content $configPath -Raw | ConvertFrom-Json
								if ($savedConfig.ProviderConfigurations -and $savedConfig.ProviderConfigurations.$selectedProvider) {
									$hasConfig = $true
								}
							}
						} catch {
							# If error reading config, assume not configured
						}
					}
					
					# Show/hide the warning label
					if ($hasConfig) {
						$gui.Window.ConfigurationStatus.Visibility = [System.Windows.Visibility]::Collapsed
					} else {
						$gui.Window.ConfigurationStatus.Visibility = [System.Windows.Visibility]::Visible
					}
				}
				
				# Clear voice options when provider changes - they will be populated after successful connection
				$gui.ClearVoiceOptions()
			}
		}.GetNewClosure())
		
		# Configure button event
		if ($this.Window.Configure) {
			$this.Window.Configure.add_Click({
				$selectedProvider = $gui.Window.ProviderSelect.SelectedItem.Content
				if ($selectedProvider) {
					$gui.WriteSafeLog("Configuring provider: $selectedProvider", "INFO")
					$gui.ShowProviderConfigurationDialog($selectedProvider)
				} else {
					[System.Windows.MessageBox]::Show(
						"Please select a provider before configuring.",
						"Configuration",
						[System.Windows.MessageBoxButton]::OK,
						[System.Windows.MessageBoxImage]::Warning
					)
				}
			}.GetNewClosure())
		}

		if ($this.Window.Connect) {
			$this.Window.Connect.add_Click({
				$selectedProvider = $gui.Window.ProviderSelect.SelectedItem.Content
				if ($selectedProvider) {
					$gui.WriteSafeLog("Testing connection for provider: $selectedProvider", "INFO")
					
					# Get provider instance
					$providerInstance = Get-TTSProvider -ProviderName $selectedProvider
					if ($providerInstance) {
						# Get configuration - first from provider instance, then from config.json
						$config = @{}
						if ($providerInstance.Configuration -and $providerInstance.Configuration.Count -gt 0) {
							$config = $providerInstance.Configuration
						} else {
							# Load from config.json if provider instance doesn't have config
							try {
								$configPath = Join-Path $PSScriptRoot "..\config.json"
								if (Test-Path $configPath) {
									$savedConfig = Get-Content $configPath -Raw | ConvertFrom-Json
									if ($savedConfig.ProviderConfigurations -and $savedConfig.ProviderConfigurations.$selectedProvider) {
										# Convert PSCustomObject to hashtable
										$providerConfig = $savedConfig.ProviderConfigurations.$selectedProvider
										$providerConfig.PSObject.Properties | ForEach-Object {
											$config[$_.Name] = $_.Value
										}
										$gui.WriteSafeLog("Loaded configuration for $selectedProvider from config.json for connection test", "DEBUG")
										
										# Also update provider instance for future use
										$providerInstance.Configuration = $config
									}
								}
							} catch {
								$gui.WriteSafeLog("Failed to load config for $selectedProvider`: $($_.Exception.Message)", "WARNING")
							}
						}
						
						# Only test if we have configuration
						if ($config.Count -gt 0) {
							# Validate configuration based on provider
						$isValid = $false
						$statusMessage = ""
						
						if ($selectedProvider -eq "AWS Polly") {
							$isValid = Test-AWSPollyCredentials -Config $config
							$statusMessage = if ($isValid) { "✓ Connected" } else { "✗ Failed" }
						} elseif ($selectedProvider -eq "ElevenLabs") {
							$isValid = Test-ElevenLabsCredentials -Config $config
							$statusMessage = if ($isValid) { "✓ Connected" } else { "✗ Failed" }
						} elseif ($selectedProvider -eq "Google Cloud") {
							$isValid = Test-GoogleCloudCredentials -Config $config
							$statusMessage = if ($isValid) { "✓ Connected" } else { "✗ Failed" }
						} elseif ($selectedProvider -eq "Microsoft Azure") {
							$isValid = Test-AzureCredentials -Config $config
							$statusMessage = if ($isValid) { "✓ Connected" } else { "✗ Failed" }
						} elseif ($selectedProvider -eq "Murf AI") {
							$isValid = Test-MurfAICredentials -Config $config
							$statusMessage = if ($isValid) { "✓ Connected" } else { "✗ Failed" }
						} elseif ($selectedProvider -eq "OpenAI") {
							$isValid = Test-OpenAICredentials -Config $config
							$statusMessage = if ($isValid) { "✓ Connected" } else { "✗ Failed" }
						} elseif ($selectedProvider -eq "Telnyx") {
							$isValid = Test-TelnyxCredentials -ApiKey $config.ApiKey
							$statusMessage = if ($isValid) { "✓ Connected" } else { "✗ Failed" }
						} elseif ($selectedProvider -eq "Twilio") {
							$isValid = Test-TwilioCredentials -Config $config
							$statusMessage = if ($isValid) { "✓ Connected" } else { "✗ Failed" }
						} else {
							$statusMessage = "⚠ Not Configured"
							$gui.WriteSafeLog("Connection test not implemented for $selectedProvider", "WARNING")
						}							# Update status
							if ($gui.Window.CredentialsStatus) {
								$gui.Window.CredentialsStatus.Text = $statusMessage
								$gui.Window.CredentialsStatus.Foreground = if ($isValid) { "#FF28A745" } else { "#FFFF6B6B" }
							}
							
							$gui.WriteSafeLog("Connection test result for $selectedProvider : $statusMessage", "INFO")
							
							# Populate voice options only after successful connection
							if ($isValid) {
								$gui.UpdateVoiceOptions($selectedProvider)
							}
						} else {
							$gui.WriteSafeLog("No configuration found for $selectedProvider", "WARNING")
							if ($gui.Window.CredentialsStatus) {
								$gui.Window.CredentialsStatus.Text = "⚠ Not Configured"
								$gui.Window.CredentialsStatus.Foreground = "#FFFF6B6B"
							}
							[System.Windows.MessageBox]::Show(
								"Please configure $selectedProvider credentials first using the Configure button",
								"Connection",
								[System.Windows.MessageBoxButton]::OK,
								[System.Windows.MessageBoxImage]::Warning
							)
						}
					} else {
						$gui.WriteSafeLog("Provider instance not found for $selectedProvider", "ERROR")
					}
				} else {
					$gui.WriteSafeLog("No provider selected for connection", "WARNING")
					[System.Windows.MessageBox]::Show(
						"Please select a TTS provider first",
						"Connection",
						[System.Windows.MessageBoxButton]::OK,
						[System.Windows.MessageBoxImage]::Warning
					)
				}
			}.GetNewClosure())
		}
		
		# Advanced button event
		if ($this.Window.AdvancedVoice) {
			$this.Window.AdvancedVoice.add_Click({
				$selectedProvider = $gui.Window.ProviderSelect.SelectedItem.Content
				if ($selectedProvider) {
					$gui.WriteSafeLog("Opening advanced settings for provider: $selectedProvider", "INFO")
					
					# Call advanced settings function
					if (Get-Command Show-AdvancedVoiceSettings -ErrorAction SilentlyContinue) {
						Show-AdvancedVoiceSettings -Provider $selectedProvider
					} else {
						$gui.WriteSafeLog("Show-AdvancedVoiceSettings function not found", "WARNING")
						[System.Windows.MessageBox]::Show(
							"Advanced settings are not yet implemented for $selectedProvider",
							"Advanced Settings",
							[System.Windows.MessageBoxButton]::OK,
							[System.Windows.MessageBoxImage]::Information
						)
					}
				}
			}.GetNewClosure())
		}
		
		# Clear Log button event
		if ($this.Window.ClearLog) {
			$this.Window.ClearLog.add_Click({
				$gui.Window.LogOutput.Text = ""
				$gui.WriteSafeLog("Activity log cleared by user", "INFO")
			}.GetNewClosure())
		}
		
		# Export Log button event
		if ($this.Window.ExportLog) {
			$this.Window.ExportLog.add_Click({
				try {
					$saveDialog = New-Object Microsoft.Win32.SaveFileDialog
					$saveDialog.Filter = "Log files (*.log)|*.log|Text files (*.txt)|*.txt|All files (*.*)|*.*"
					$saveDialog.FileName = "ActivityLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
					$saveDialog.Title = "Export Activity Log"
					
					if ($saveDialog.ShowDialog()) {
						$gui.Window.LogOutput.Text | Out-File -FilePath $saveDialog.FileName -Encoding UTF8
						$gui.WriteSafeLog("Activity log exported to: $($saveDialog.FileName)", "INFO")
						[System.Windows.MessageBox]::Show(
							"Log exported successfully to:`n$($saveDialog.FileName)",
							"Export Complete",
							[System.Windows.MessageBoxButton]::OK,
							[System.Windows.MessageBoxImage]::Information
						)
					}
				} catch {
					$gui.WriteSafeLog("Failed to export log: $($_.Exception.Message)", "ERROR")
					[System.Windows.MessageBox]::Show(
						"Failed to export log:`n$($_.Exception.Message)",
						"Export Error",
						[System.Windows.MessageBoxButton]::OK,
						[System.Windows.MessageBoxImage]::Error
					)
				}
			}.GetNewClosure())
		}
		
		# Save Configuration button event
		if ($this.Window.SaveConfig) {
			$this.Window.SaveConfig.add_Click({
				try {
					$configPath = Join-Path $PSScriptRoot "..\config.json"
					
					# Load existing config to preserve all provider configurations
					$existingConfig = $null
					if (Test-Path $configPath) {
						try {
							$existingConfig = Get-Content -Path $configPath -Raw | ConvertFrom-Json
						} catch {
							$gui.WriteSafeLog("Could not load existing config, creating new one", "WARNING")
						}
					}
					
					# Build configuration object from GUI fields
					$config = @{
						Provider = if ($gui.Window.ProviderSelect.SelectedItem) { $gui.Window.ProviderSelect.SelectedItem.Content } else { "" }
						# Voice, Language, Format, Quality are now dynamic; handled via VoiceOptionsPanel
						LastSaved = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
						ProviderConfigurations = @{}
					}
					
					# Preserve existing provider configurations
					if ($existingConfig -and $existingConfig.ProviderConfigurations) {
						foreach ($providerName in $existingConfig.ProviderConfigurations.PSObject.Properties.Name) {
							$providerConfig = $existingConfig.ProviderConfigurations.$providerName
							# Convert PSCustomObject to hashtable
							$configHash = @{}
							foreach ($prop in $providerConfig.PSObject.Properties) {
								$configHash[$prop.Name] = $prop.Value
							}
							$config.ProviderConfigurations[$providerName] = $configHash
						}
					}
					
					# Update current provider's configuration
					$selectedProvider = $config.Provider
					if ($selectedProvider) {
						$providerInstance = Get-TTSProvider -ProviderName $selectedProvider
						$gui.WriteSafeLog("Saving config for provider: $selectedProvider, has instance: $($null -ne $providerInstance), has Configuration: $($null -ne $providerInstance.Configuration)", "INFO")
						if ($providerInstance -and $providerInstance.Configuration) {
							$gui.WriteSafeLog("Provider $selectedProvider Configuration keys: $($providerInstance.Configuration.Keys -join ', ')", "INFO")
							$config.ProviderConfigurations[$selectedProvider] = $providerInstance.Configuration
							$gui.WriteSafeLog("Updated configuration for provider: $selectedProvider", "INFO")
						} else {
							$gui.WriteSafeLog("Provider $selectedProvider has no configuration to save", "WARNING")
						}
					}
					
					# Save to JSON file with proper formatting
					$config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
					
					$gui.WriteSafeLog("Configuration saved to: $configPath", "INFO")
					[System.Windows.MessageBox]::Show(
						"Configuration saved successfully!",
						"Save Configuration",
						[System.Windows.MessageBoxButton]::OK,
						[System.Windows.MessageBoxImage]::Information
					)
				} catch {
					$gui.WriteSafeLog("Failed to save configuration: $($_.Exception.Message)", "ERROR")
					[System.Windows.MessageBox]::Show(
						"Failed to save configuration:`n$($_.Exception.Message)",
						"Save Error",
						[System.Windows.MessageBoxButton]::OK,
						[System.Windows.MessageBoxImage]::Error
					)
				}
			}.GetNewClosure())
		}
		
		# Load Configuration button event
		if ($this.Window.LoadConfig) {
			$this.Window.LoadConfig.add_Click({
				try {
					$configPath = Join-Path $PSScriptRoot "..\config.json"
					
					if (-not (Test-Path $configPath)) {
						$gui.WriteSafeLog("No saved configuration found at: $configPath", "WARNING")
						[System.Windows.MessageBox]::Show(
							"No saved configuration file found.`nPlease save a configuration first.",
							"Load Configuration",
							[System.Windows.MessageBoxButton]::OK,
							[System.Windows.MessageBoxImage]::Warning
						)
						return
					}
					
					# Load configuration from JSON file
					$config = Get-Content $configPath -Raw | ConvertFrom-Json
					
					# Apply to GUI fields
					if ($config.Provider) {
						foreach ($item in $gui.Window.ProviderSelect.Items) {
							if ($item.Content -eq $config.Provider) {
								$gui.Window.ProviderSelect.SelectedItem = $item
								break
							}
						}
					}
					$gui.WriteSafeLog("Configuration loaded from: $configPath", "INFO")
					[System.Windows.MessageBox]::Show(
						"Configuration loaded successfully!",
						"Load Configuration",
						[System.Windows.MessageBoxButton]::OK,
						[System.Windows.MessageBoxImage]::Information
					)
				} catch {
					$gui.WriteSafeLog("Failed to load configuration: $($_.Exception.Message)", "ERROR")
					[System.Windows.MessageBox]::Show(
						"Failed to load configuration:`n$($_.Exception.Message)",
						"Load Error",
						[System.Windows.MessageBoxButton]::OK,
						[System.Windows.MessageBoxImage]::Error
					)
				}
			}.GetNewClosure())
		}
		
		# Reset Configuration button event
		if ($this.Window.ResetConfig) {
			$this.Window.ResetConfig.add_Click({
				$result = [System.Windows.MessageBox]::Show(
					"Are you sure you want to reset all configuration to defaults?`nThis will clear all current settings.",
					"Reset Configuration",
					[System.Windows.MessageBoxButton]::YesNo,
					[System.Windows.MessageBoxImage]::Question
				)
				
				if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
					try {
						# Reset provider selection
						$gui.Window.ProviderSelect.SelectedIndex = -1
						
						# Clear dynamic voice options
						$voicePanel = $gui.Window.FindName('VoiceOptionsPanel')
						if ($null -ne $voicePanel) {
							$voicePanel.Children.Clear()
						}
						
						# Clear provider configurations
						$providers = Get-AvailableTTSProviders
						if ($providers) {
							foreach ($providerName in $providers) {
								$providerInstance = Get-TTSProvider -ProviderName $providerName
								if ($providerInstance -and $providerInstance.Configuration) {
									$providerInstance.Configuration = @{}
								}
							}
						}
						
						# Clear activity log
						if ($gui.Window.LogOutput) {
							$gui.Window.LogOutput.Text = ""
						}
						
						$gui.WriteSafeLog("Configuration reset to defaults", "INFO")
						[System.Windows.MessageBox]::Show(
							"Configuration has been reset to defaults.",
							"Reset Complete",
							[System.Windows.MessageBoxButton]::OK,
							[System.Windows.MessageBoxImage]::Information
						)
					} catch {
						$gui.WriteSafeLog("Failed to reset configuration: $($_.Exception.Message)", "ERROR")
						[System.Windows.MessageBox]::Show(
							"Failed to reset configuration:`n$($_.Exception.Message)",
							"Reset Error",
							[System.Windows.MessageBoxButton]::OK,
							[System.Windows.MessageBoxImage]::Error
						)
					}
				}
			}.GetNewClosure())
		}
		
		$this.WriteSafeLog("Event handlers wired successfully", "DEBUG")
	}

	[void]WriteSafeLog($Message, $Level = "INFO") {
		# Write to console/file via logging system (this will also update GUI via the logging module)
		if (Get-Command Add-ApplicationLog -ErrorAction SilentlyContinue) {
			Add-ApplicationLog -Message $Message -Level $Level
		} else {
			# Fallback: Write to console and GUI manually
			$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
			$consoleEntry = "[$timestamp] [$Level] [GUI] $Message"
			$Colour = switch ($Level) {
				"ERROR" { "Red" }
				"WARNING" { "Yellow" }
				"DEBUG" { "Gray" }
				default { "White" }
			}
			Write-Host $consoleEntry -ForegroundColor $Colour
			
			# Update GUI log output
			if ($this.Window -and $this.Window.LogOutput) {
				try {
					$guiTimestamp = Get-Date -Format "HH:mm:ss"
					$logEntry = "[$guiTimestamp] [$Level] $Message`r`n"
					
					$this.Window.Dispatcher.Invoke([Action]{
						$this.Window.LogOutput.AppendText($logEntry)
						$this.Window.LogOutput.ScrollToEnd()
					})
				} catch {
					# Silently handle UI update errors
				}
			}
		}
	}

	[object]ConvertXAMLtoWindow($XAML) {
		# WPF availability is verified before calling this method
		# Clean up XAML string - remove any trailing quotes that might be included from here-string parsing
		$cleanXAML = $XAML
		if ($cleanXAML.EndsWith('"')) {
			$cleanXAML = $cleanXAML.Substring(0, $cleanXAML.Length - 1)
			$this.WriteSafeLog("DEBUG: Removed trailing quote from XAML", "DEBUG")
		}
		$this.WriteSafeLog("DEBUG: XAML length: $($cleanXAML.Length), starts with: $($cleanXAML.Substring(0, 50))", "DEBUG")
		
		try {
			$reader = [System.Xml.XmlReader]::Create([IO.StringReader]$cleanXAML)
			$result = [System.Windows.Markup.XamlReader]::Load($reader)
			$reader.Close()
			$this.WriteSafeLog("DEBUG: XAML parsed successfully, result type: $($result.GetType().Name)", "DEBUG")
			
			# Bind named elements to the window object for easy access
			$reader = [System.Xml.XmlReader]::Create([IO.StringReader]$cleanXAML)
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
		} catch {
			$msg = "ERROR: WPF XAML loading or parsing failed: $($_.Exception.Message)"
			if ($_.Exception.InnerException) {
				$msg += " | InnerException: $($_.Exception.InnerException.Message)"
			}
			$this.WriteSafeLog($msg, "ERROR")
			return $null
		}
	}

	[object]GetGUIConfiguration() {
		# ... Get GUI configuration logic ...
		# For now, return $null to avoid missing return error
		return $null
	}
}

function New-GUI {
	param(

		[string]$Profile = "Default"
	)
	return [GUI]::new($Profile)
}

function Show-AdvancedVoiceSettings {
	<#
	.SYNOPSIS
		Shows advanced voice settings Dialogue for the specified TTS provider
	.DESCRIPTION
		This function displays provider-specific advanced voice options Dialogue.
		Currently only OpenAI is fully implemented.
	.PARAMETER Provider
		The name of the TTS provider (e.g., "OpenAI", "ElevenLabs", etc.)
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[string]$Provider
	)

	try {
		Add-ApplicationLog -Module "GUI" -Message "Opening advanced voice settings for provider: $Provider" -Level "INFO"

		# Get provider instance
		$providerInstance = Get-TTSProvider -ProviderName $Provider
		if (-not $providerInstance) {
			Add-ApplicationLog -Module "GUI" -Message "Provider instance not found for $Provider" -Level "ERROR"
			[System.Windows.MessageBox]::Show(
				"Provider not found. Please ensure the provider module is loaded.",
				"Advanced Settings Error",
				[System.Windows.MessageBoxButton]::OK,
				[System.Windows.MessageBoxImage]::Error
			)
			return
		}

		# Check if provider has ShowAdvancedVoiceDialog method
		if (-not ($providerInstance.PSObject.Methods.Name -contains 'ShowAdvancedVoiceDialog')) {
			Add-ApplicationLog -Module "GUI" -Message "Advanced voice Dialogue not yet implemented for $Provider" -Level "WARNING"
			[System.Windows.MessageBox]::Show(
				"Advanced voice settings are not yet implemented for $Provider.`n`nThis feature is currently available for OpenAI only.",
				"Advanced Settings",
				[System.Windows.MessageBoxButton]::OK,
				[System.Windows.MessageBoxImage]::Information
			)
			return
		}

		# Get current configuration for the provider
		$currentConfig = @{}
		if ($providerInstance.Configuration -and $providerInstance.Configuration.Count -gt 0) {
			$currentConfig = $providerInstance.Configuration
			Add-ApplicationLog -Module "GUI" -Message "Using existing configuration for $Provider advanced Dialogue" -Level "DEBUG"
		} else {
			# Try to load from config.json
			try {
				$configPath = Join-Path $PSScriptRoot "..\config.json"
				if (Test-Path $configPath) {
					$savedConfig = Get-Content $configPath -Raw | ConvertFrom-Json
					if ($savedConfig.ProviderConfigurations -and $savedConfig.ProviderConfigurations.$Provider) {
						$providerConfig = $savedConfig.ProviderConfigurations.$Provider
						# Convert PSCustomObject to hashtable
						foreach ($key in $providerConfig.PSObject.Properties.Name) {
							$currentConfig[$key] = $providerConfig.$key
						}
						Add-ApplicationLog -Module "GUI" -Message "Loaded saved configuration for $Provider from config.json" -Level "DEBUG"
					}
				}
			} catch {
				Add-ApplicationLog -Module "GUI" -Message "Failed to load saved config for $Provider`: $($_.Exception.Message)" -Level "WARNING"
			}
		}

		# Call the provider's advanced Dialogue
		Add-ApplicationLog -Module "GUI" -Message "Calling ShowAdvancedVoiceDialog for $Provider" -Level "DEBUG"
		$result = $providerInstance.ShowAdvancedVoiceDialog($currentConfig)

		# Handle the result
		if ($result -and $result.Success) {
			# Update provider instance configuration with advanced options
			if (-not $providerInstance.Configuration) {
				$providerInstance.Configuration = @{}
			}

			# Merge advanced options into configuration
			foreach ($key in $result.Keys) {
				if ($key -ne 'Success') {
					$providerInstance.Configuration[$key] = $result[$key]
				}
			}

			Add-ApplicationLog -Module "GUI" -Message "Advanced voice settings saved for $Provider" -Level "INFO"
			[System.Windows.MessageBox]::Show(
				"Advanced voice settings saved successfully for $Provider!",
				"Advanced Settings",
				[System.Windows.MessageBoxButton]::OK,
				[System.Windows.MessageBoxImage]::Information
			)
		} elseif ($result -and -not $result.Success) {
			Add-ApplicationLog -Module "GUI" -Message "Advanced voice settings Dialogue Cancelled for $Provider" -Level "DEBUG"
		} else {
			Add-ApplicationLog -Module "GUI" -Message "Advanced voice settings Dialogue failed for $Provider" -Level "WARNING"
		}

	} catch {
		Add-ApplicationLog -Module "GUI" -Message "Error in Show-AdvancedVoiceSettings for $Provider`: $($_.Exception.Message)" -Level "ERROR"
		[System.Windows.MessageBox]::Show(
			"Error opening advanced voice settings:`n$($_.Exception.Message)",
			"Advanced Settings Error",
			[System.Windows.MessageBoxButton]::OK,
			[System.Windows.MessageBoxImage]::Error
		)
	}
}

Export-ModuleMember -Function New-GUI
Export-ModuleMember -Function Show-AdvancedVoiceSettings


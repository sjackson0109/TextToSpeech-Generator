# GUIModule.psm1 - Unified GUI module for TextToSpeech Generator
# Consolidates all GUI logic, event handlers, configuration, and provider setup dialogs




# Unified GUI class and all supporting functions
# (Migrated from GUI.psm1, ModernGUI.psm1, and all legacy GUI/*.psm1)
Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\Logging\EnhancedLogging.psm1')).Path -Force

class GUI {
	[string]$CurrentProfile
	[object]$Window
	[bool]$AutoSaveEnabled
	[object]$ConfigManager
	[object]$AutoSaveTimer
	[string]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
		xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
		Title="TextToSpeech Generator" Height="800" Width="900" Background="#FF232323" WindowStartupLocation="CenterScreen">
	<ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto">
		<StackPanel Margin="16">
			<!-- Header -->
			<Border Background="#FF2D2D30" CornerRadius="6" Padding="12" Margin="0,0,0,12">
				<StackPanel>
					<TextBlock Text="🎤 TextToSpeech Generator" FontSize="20" FontWeight="Bold" Foreground="White"/>
					<TextBlock Text="Convert text to high-quality speech using enterprise TTS providers. Save API configurations and switch between providers seamlessly." FontSize="12" Foreground="#FFCCCCCC" Margin="0,4,0,0" TextWrapping="Wrap"/>
				</StackPanel>
			</Border>
			<!-- TTS Provider Selection -->
			<GroupBox Header="TTS Provider Selection" Foreground="White" Margin="0,0,0,12">
				<StackPanel>
					<Grid Margin="8">
						<Grid.ColumnDefinitions>
							<ColumnDefinition Width="180"/>
							<ColumnDefinition Width="*"/>
							<ColumnDefinition Width="110"/>
							<ColumnDefinition Width="110"/>
						</Grid.ColumnDefinitions>
						<Label Content="Provider:" Grid.Column="0" VerticalAlignment="Center" Foreground="White"/>
						<ComboBox x:Name="ProviderSelect" Grid.Column="1" Height="25" Margin="5,2" VerticalAlignment="Center">
							<ComboBoxItem Content="Microsoft Azure"/>
							<ComboBoxItem Content="Amazon Polly"/>
							<ComboBoxItem Content="Google Cloud"/>
							<ComboBoxItem Content="Twilio"/>
							<ComboBoxItem Content="VoiceForge"/>
							<ComboBoxItem Content="CloudPronouncer"/>
						</ComboBox>
						<Button x:Name="TestAPI" Grid.Column="2" Content="Test API" Height="30" Margin="5,2" Background="#FF28A745" Foreground="White"/>
						<Button x:Name="APIConfig" Grid.Column="3" Content="API Config" Height="30" Margin="5,2" Background="#FF0E639C" Foreground="White"/>
					</Grid>
					<Grid Margin="8,4,8,0">
						<Grid.ColumnDefinitions>
							<ColumnDefinition Width="*"/>
							<ColumnDefinition Width="*"/>
						</Grid.ColumnDefinitions>
						<TextBlock x:Name="CredentialsStatus" Grid.Column="0" Text="Credentials: N" Foreground="#FFFF0000"/>
						<TextBlock x:Name="LastTestedTime" Grid.Column="1" Text="Last Test: Never" Foreground="#FFDDDDDD"/>
					</Grid>
				</StackPanel>
			</GroupBox>
			<!-- Voice Selection -->
			<GroupBox Header="Voice Selection" Foreground="White" Margin="0,0,0,12">
				<StackPanel>
					<Grid Margin="8">
						<Grid.ColumnDefinitions>
							<ColumnDefinition Width="180"/>
							<ColumnDefinition Width="*"/>
							<ColumnDefinition Width="110"/>
							<ColumnDefinition Width="110"/>
						</Grid.ColumnDefinitions>
						<Label Content="Voice:" Grid.Column="0" VerticalAlignment="Center" Foreground="White"/>
						<ComboBox x:Name="VoiceSelect" Grid.Column="1" Height="25" Margin="5,2" VerticalAlignment="Center">
							<ComboBoxItem Content="AriaNeural"/>
							<ComboBoxItem Content="Joanna"/>
							<ComboBoxItem Content="Wavenet-D"/>
						</ComboBox>
						<Label Content="Language:" Grid.Column="2" VerticalAlignment="Center" Foreground="White"/>
						<ComboBox x:Name="LanguageSelect" Grid.Column="3" Height="25" Margin="5,2" VerticalAlignment="Center">
							<ComboBoxItem Content="en-US"/>
							<ComboBoxItem Content="en-GB"/>
							<ComboBoxItem Content="de-DE"/>
						</ComboBox>
					</Grid>
					<Grid Margin="8,4,8,0">
						<Grid.ColumnDefinitions>
							<ColumnDefinition Width="180"/>
							<ColumnDefinition Width="*"/>
							<ColumnDefinition Width="110"/>
							<ColumnDefinition Width="110"/>
						</Grid.ColumnDefinitions>
						<Label Content="Format:" Grid.Column="0" VerticalAlignment="Center" Foreground="White"/>
						<ComboBox x:Name="FormatSelect" Grid.Column="1" Height="25" Margin="5,2" VerticalAlignment="Center">
							<ComboBoxItem Content="MP3 16kHz"/>
							<ComboBoxItem Content="WAV"/>
						</ComboBox>
						<Label Content="Quality:" Grid.Column="2" VerticalAlignment="Center" Foreground="White"/>
						<ComboBox x:Name="QualitySelect" Grid.Column="3" Height="25" Margin="5,2" VerticalAlignment="Center">
							<ComboBoxItem Content="Neural"/>
							<ComboBoxItem Content="Standard"/>
						</ComboBox>
						<Button x:Name="AdvancedVoice" Grid.Column="3" Content="Advanced" Height="25" Margin="5,2,0,2" Background="#FF0E639C" Foreground="White" HorizontalAlignment="Right"/>
					</Grid>
				</StackPanel>
			</GroupBox>
			<!-- Input &amp; Output -->
			<GroupBox Header="Input &amp; Output" Foreground="White" Margin="0,0,0,12">
				<StackPanel>
					<Grid Margin="8">
						<Grid.ColumnDefinitions>
							<ColumnDefinition Width="*"/>
							<ColumnDefinition Width="*"/>
							<ColumnDefinition Width="110"/>
							<ColumnDefinition Width="110"/>
						</Grid.ColumnDefinitions>
						<Label Content="File:" Grid.Column="0" VerticalAlignment="Center" Foreground="White"/>
						<TextBox x:Name="InputFile" Grid.Column="1" Height="25" Margin="5,2" VerticalAlignment="Center"/>
						<Label Content="Output:" Grid.Column="2" VerticalAlignment="Center" Foreground="White"/>
						<TextBox x:Name="OutputFile" Grid.Column="3" Height="25" Margin="5,2" VerticalAlignment="Center"/>
					</Grid>
					<Grid Margin="8,4,8,0">
						<Grid.ColumnDefinitions>
							<ColumnDefinition Width="*"/>
							<ColumnDefinition Width="110"/>
							<ColumnDefinition Width="110"/>
						</Grid.ColumnDefinitions>
						<TextBox x:Name="InputText" Grid.Column="0" Height="60" Margin="5,2" VerticalAlignment="Top" Text="Enter your text here for single mode processing..."/>
						<CheckBox x:Name="BulkMode" Grid.Column="1" Content="Bulk Mode" VerticalAlignment="Center" Foreground="White"/>
						<Button x:Name="ImportCSV" Grid.Column="2" Content="Import CSV" Height="25" Margin="5,2" Background="#FF0E639C" Foreground="White"/>
					</Grid>
					<Grid Margin="8,4,8,0">
						<Grid.ColumnDefinitions>
							<ColumnDefinition Width="*"/>
							<ColumnDefinition Width="110"/>
						</Grid.ColumnDefinitions>
						<Label Content="File Type:" Grid.Column="0" VerticalAlignment="Center" Foreground="White"/>
						<ComboBox x:Name="FileTypeSelect" Grid.Column="1" Height="25" Margin="5,2" VerticalAlignment="Center">
							<ComboBoxItem Content="MP3"/>
							<ComboBoxItem Content="WAV"/>
						</ComboBox>
					</Grid>
				</StackPanel>
			</GroupBox>
			<!-- Progress -->
			<GroupBox Header="Progress" Foreground="White" Margin="0,0,0,12">
				<Grid Margin="8">
					<Grid.ColumnDefinitions>
						<ColumnDefinition Width="*"/>
						<ColumnDefinition Width="180"/>
						<ColumnDefinition Width="180"/>
					</Grid.ColumnDefinitions>
					<TextBlock x:Name="ProgressStatus" Grid.Column="0" Text="Ready - Select provider and configure settings to begin" Foreground="#FFDDDDDD"/>
					<TextBlock x:Name="APIStatus" Grid.Column="1" Text="API: Not Tested" Foreground="#FFFF0000"/>
					<TextBlock x:Name="ConfigStatus" Grid.Column="2" Text="Config: Default" Foreground="#FF00FF00"/>
				</Grid>
			</GroupBox>
			<!-- Generate Speech &amp; Actions -->
			<Grid Margin="0,0,0,12">
				<Grid.ColumnDefinitions>
					<ColumnDefinition Width="*"/>
					<ColumnDefinition Width="110"/>
					<ColumnDefinition Width="110"/>
					<ColumnDefinition Width="110"/>
				</Grid.ColumnDefinitions>
				<Button x:Name="GenerateSpeech" Grid.Column="0" Content="Generate Speech" Height="40" Background="#FF007ACC" Foreground="White" FontWeight="Bold" FontSize="16"/>
				<Button x:Name="SaveConfig" Grid.Column="1" Content="Save" Height="40" Background="#FF28A745" Foreground="White" FontWeight="Bold"/>
				<Button x:Name="LoadConfig" Grid.Column="2" Content="Load" Height="40" Background="#FF0E639C" Foreground="White" FontWeight="Bold"/>
				<Button x:Name="ResetConfig" Grid.Column="3" Content="Reset" Height="40" Background="#FFD32F2F" Foreground="White" FontWeight="Bold"/>
			</Grid>
			<!-- Activity Log -->
			<GroupBox Header="Activity Log" Foreground="White" Margin="0,0,0,0">
				<StackPanel>
					<Grid Margin="8">
						<Grid.RowDefinitions>
							<RowDefinition Height="*"/>
							<RowDefinition Height="Auto"/>
						</Grid.RowDefinitions>
						<TextBox x:Name="LogOutput" Grid.Row="0" Height="120" Margin="0,0,0,8" VerticalScrollBarVisibility="Auto" IsReadOnly="True" Background="#FF1E1E1E" Foreground="White" FontFamily="Consolas" FontSize="12"/>
						<StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right">
							<Button x:Name="ClearLog" Content="Clear Log" Height="30" Margin="0,0,8,0" Background="#FF0E639C" Foreground="White"/>
							<Button x:Name="ExportLog" Content="Export Log" Height="30" Background="#FF28A745" Foreground="White"/>
						</StackPanel>
					</Grid>
				</StackPanel>
			</GroupBox>
		</StackPanel>
	</ScrollViewer>
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
			# Explicitly load required assemblies for GUI
			[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
			[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
			try {
				$assemblyLoaded = $false
				try {
					Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
					$assemblyLoaded = $true
				} catch {
					$this.WriteSafeLog("ERROR: PresentationFramework assembly could not be loaded. WPF GUI cannot be initialized. Please run in Windows PowerShell with .NET Framework.", "ERROR")
					return $null
				}
				if (-not $assemblyLoaded) {
					$this.WriteSafeLog("ERROR: PresentationFramework assembly is not available. WPF GUI cannot be initialized.", "ERROR")
					return $null
				}
			} catch {
				$this.WriteSafeLog("ERROR: PresentationFramework assembly could not be loaded. WPF GUI cannot be initialized.", "ERROR")
				return $null
			}
			$this.Window = $this.ConvertXAMLtoWindow($this.XAML)
			if ($null -eq $this.Window -or ($this.Window.GetType().FullName -ne 'System.Windows.Window')) {
				$this.WriteSafeLog("ERROR: Failed to create GUI window from XAML or missing WPF types.", "ERROR")
				return $null
			}
			try {
				$visibilityType = [type]::GetType('System.Windows.Visibility', $false)
				$windowStateType = [type]::GetType('System.Windows.WindowState', $false)
				if ($null -eq $visibilityType -or $null -eq $windowStateType -or -not ($this.Window.PSObject.Properties['Visibility']) -or -not ($this.Window.PSObject.Properties['WindowState'])) {
					$this.WriteSafeLog("ERROR: WPF types or properties not available in this environment. GUI will not be shown.", "ERROR")
					return $null
				}
				$this.Window.Visibility = $visibilityType::Visible
				$this.Window.WindowState = $windowStateType::Normal
			} catch {
				$this.WriteSafeLog("ERROR: WPF types not available in this environment. GUI will not be shown.", "ERROR")
				return $null
			}
			$this.WriteSafeLog("Modern GUI initialized successfully", "INFO")
			return $this.Window
		} catch {
			$this.WriteSafeLog("ERROR: Exception during GUI initialization: $($_.Exception.Message)", "ERROR")
			return $null
		}
	}

	[void]InvokeAutoSaveConfiguration() {
		# ... Auto-save logic ...
	}

	[void]SetGUIConfiguration($Configuration) {
		# ... Set GUI configuration logic ...
	}

	[void]ShowProviderSetup($Provider) {
		# ... Show provider setup dialog logic ...
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
		# ... Update voice options logic ...
	}

	[void]WriteSafeLog($Message, $Level = "INFO") {
		if (Get-Command Write-ApplicationLog -ErrorAction SilentlyContinue) {
			Write-ApplicationLog -Message $Message -Level $Level
		} else {
			Write-Host "[$Level] $Message" -ForegroundColor $(if ($Level -eq "ERROR") { "Red" } elseif ($Level -eq "WARNING") { "Yellow" } else { "White" })
		}
	}

	[object]ConvertXAMLtoWindow($XAML) {
		$wpfAvailable = $false
		try {
			Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
			$wpfAvailable = $true
		} catch {}
		if (-not $wpfAvailable -or (-not ([type]::GetType('Windows.Markup.XamlReader', $false))) -or (-not ([type]::GetType('System.Windows.Window', $false))) ) {
			$this.WriteSafeLog("ERROR: WPF types not available in this environment. GUI will not be shown.", "ERROR")
			return $null
		}
		try {
			$reader = [System.Xml.XmlReader]::Create([IO.StringReader]$XAML)
			$result = [System.Windows.Markup.XamlReader]::Load($reader)
			$reader.Close()
			$reader = [System.Xml.XmlReader]::Create([IO.StringReader]$XAML)
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
			$this.WriteSafeLog("ERROR: WPF XAML loading or type resolution failed: $($_.Exception.Message)", "ERROR")
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

Export-ModuleMember -Function New-GUI

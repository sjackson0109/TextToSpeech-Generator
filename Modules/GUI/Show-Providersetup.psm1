function Show-ProviderSetup {
    <#
    .SYNOPSIS
    Show provider setup dialog
    #>
    param ( [Parameter(Mandatory=$true)][string]$Provider )
    
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
            
            <!-- Provider Header -->
            <GroupBox x:Name="APIHeader" Header="Provider Setup" Margin="0,0,0,12" Foreground="White">
                <TextBlock x:Name="APIProviderInfo" Text="Configure API credentials and regional settings." 
                           Foreground="#FFAAAAAA" Margin="8" TextWrapping="Wrap"/>
            </GroupBox>
            
            <!-- Dynamic Configuration Section -->
            <GroupBox x:Name="ConfigurationSection" Header="Configuration" Margin="0,0,0,12" Foreground="White">
                <Grid x:Name="ConfigGrid" Margin="8">
                    <!-- Dynamic content will be added here -->
                </Grid>
            </GroupBox>
            
            <!-- Connection Testing -->
            <GroupBox Header="Connection Testing" Margin="0,0,0,12" Foreground="White">
                <Grid Margin="8">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="100"/>
                        <ColumnDefinition Width="280"/>
                        <ColumnDefinition Width="100"/>
                        <ColumnDefinition Width="180"/>
                    </Grid.ColumnDefinitions>
                    
                    <TextBlock x:Name="ConnectionStatus" Grid.Column="0" Grid.ColumnSpan="3" Text="Ready to validate credentials and test connectivity..." Foreground="#FFDDDDDD" VerticalAlignment="Center"/>
                    <Button x:Name="ValidateCredentials" Grid.Column="3" Content="🔍 Validate" Height="30" Margin="5,2" Background="#FF28A745" Foreground="White"/>
                </Grid>
            </GroupBox>
            
            <!-- Setup Instructions -->
            <GroupBox x:Name="APISetupGuidance" Header="Setup Instructions" Margin="0,0,0,12" Foreground="White">
                <TextBlock x:Name="APIGuidanceText" Text="Follow the instructions below to configure your API credentials." 
                           Foreground="#FFCCCCCC" Margin="8" TextWrapping="Wrap" FontSize="11" LineHeight="16"/>
            </GroupBox>
            
            <!-- Action Buttons -->
            <Grid Margin="0,16,0,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <Button x:Name="ResetToDefaults" Grid.Column="1" Content="Reset to Defaults" Width="120" Height="30" Margin="0,0,8,0" Background="#FFD32F2F" Foreground="White"/>
                <Button x:Name="SaveAndClose" Grid.Column="2" Content="Save &amp; Close" Width="100" Height="30" Background="#FF2D7D32" Foreground="White"/>
            </Grid>
            
            "Twilio" {
                $setupWindow.APIProviderInfo.Text = "Configure Twilio API credentials and settings."
                $row0 = New-Object System.Windows.Controls.RowDefinition
                $row0.Height = [System.Windows.GridLength]::new(0, [System.Windows.GridUnitType]::Auto)
                $configGrid.RowDefinitions.Add($row0)
                $row1 = New-Object System.Windows.Controls.RowDefinition
                $row1.Height = [System.Windows.GridLength]::new(0, [System.Windows.GridUnitType]::Auto)
                $configGrid.RowDefinitions.Add($row1)
                $accountSidLabel = New-Object System.Windows.Controls.Label
                $accountSidLabel.Content = "Account SID:"
                $accountSidLabel.Foreground = "White"
                $accountSidLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetRow($accountSidLabel, 0)
                [System.Windows.Controls.Grid]::SetColumn($accountSidLabel, 0)
                $configGrid.Children.Add($accountSidLabel) | Out-Null
                $accountSidBox = New-Object System.Windows.Controls.TextBox
                $accountSidBox.Name = "API_TW_AccountSID"
                $accountSidBox.Height = 25
                $accountSidBox.Margin = "5,2"
                if ($script:Window.TW_AccountSID.Text) { $accountSidBox.Text = $script:Window.TW_AccountSID.Text }
                [System.Windows.Controls.Grid]::SetRow($accountSidBox, 0)
                [System.Windows.Controls.Grid]::SetColumn($accountSidBox, 1)
                $configGrid.Children.Add($accountSidBox) | Out-Null
                $authTokenLabel = New-Object System.Windows.Controls.Label
                $authTokenLabel.Content = "Auth Token:"
                $authTokenLabel.Foreground = "White"
                $authTokenLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetRow($authTokenLabel, 0)
                [System.Windows.Controls.Grid]::SetColumn($authTokenLabel, 2)
                $configGrid.Children.Add($authTokenLabel) | Out-Null
                $authTokenBox = New-Object System.Windows.Controls.PasswordBox
                $authTokenBox.Name = "API_TW_AuthToken"
                $authTokenBox.Height = 25
                $authTokenBox.Margin = "5,2"
                if ($script:Window.TW_AuthToken.Password) { $authTokenBox.Password = $script:Window.TW_AuthToken.Password }
                [System.Windows.Controls.Grid]::SetRow($authTokenBox, 0)
                [System.Windows.Controls.Grid]::SetColumn($authTokenBox, 3)
                $configGrid.Children.Add($authTokenBox) | Out-Null
                $voiceLabel = New-Object System.Windows.Controls.Label
                $voiceLabel.Content = "Default Voice:"

                $voiceLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetRow($voiceLabel, 1)
                [System.Windows.Controls.Grid]::SetColumn($voiceLabel, 0)
                $configGrid.Children.Add($voiceLabel) | Out-Null
                $voiceBox = New-Object System.Windows.Controls.TextBox
                $voiceBox.Name = "API_TW_Voice"
                $voiceBox.Height = 25
                $voiceBox.Margin = "5,2"
                if ($script:Window.TW_Voice.Text) { $voiceBox.Text = $script:Window.TW_Voice.Text }
                [System.Windows.Controls.Grid]::SetRow($voiceBox, 1)
                [System.Windows.Controls.Grid]::SetColumn($voiceBox, 1)
                $configGrid.Children.Add($voiceBox) | Out-Null
                $guidanceText.Text = @"
        $col2 = New-Object System.Windows.Controls.ColumnDefinition  
        $col2.Width = [System.Windows.GridLength]::new(280)
        $configGrid.ColumnDefinitions.Add($col2)
        
        $col3 = New-Object System.Windows.Controls.ColumnDefinition
        $col3.Width = [System.Windows.GridLength]::new(100)
        $configGrid.ColumnDefinitions.Add($col3)
        
                $setupWindow.SaveAndClose.add_Click{
                    if ($script:Window.TW_AccountSID) { $script:Window.TW_AccountSID.Text = $accountSidBox.Text }
                    if ($script:Window.TW_AuthToken) { $script:Window.TW_AuthToken.Password = $authTokenBox.Password }
                    if ($script:Window.TW_Voice) { $script:Window.TW_Voice.Text = $voiceBox.Text }
                    Write-SafeLog -Message "Twilio configuration saved" -Level "INFO"
                    if ($script:AutoSaveEnabled) { Invoke-AutoSaveConfiguration }
                    $setupWindow.DialogResult = $true
                    $setupWindow.Close()
                }
            }
            "VoiceForge" {
                $setupWindow.APIProviderInfo.Text = "Configure VoiceForge API credentials and settings."
                $row0 = New-Object System.Windows.Controls.RowDefinition
                $row0.Height = [System.Windows.GridLength]::new(0, [System.Windows.GridUnitType]::Auto)
                $configGrid.RowDefinitions.Add($row0)
                $row1 = New-Object System.Windows.Controls.RowDefinition
                $row1.Height = [System.Windows.GridLength]::new(0, [System.Windows.GridUnitType]::Auto)
                $configGrid.RowDefinitions.Add($row1)
                $apiKeyLabel = New-Object System.Windows.Controls.Label
                $apiKeyLabel.Content = "API Key:"
                $apiKeyLabel.Foreground = "White"
                $apiKeyLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetRow($apiKeyLabel, 0)
                [System.Windows.Controls.Grid]::SetColumn($apiKeyLabel, 0)
                $configGrid.Children.Add($apiKeyLabel) | Out-Null
                $apiKeyBox = New-Object System.Windows.Controls.TextBox
                $apiKeyBox.Name = "API_VF_ApiKey"
                $apiKeyBox.Height = 25
                $apiKeyBox.Margin = "5,2"
                if ($script:Window.VF_ApiKey.Text) { $apiKeyBox.Text = $script:Window.VF_ApiKey.Text }
                [System.Windows.Controls.Grid]::SetRow($apiKeyBox, 0)
                [System.Windows.Controls.Grid]::SetColumn($apiKeyBox, 1)
                $configGrid.Children.Add($apiKeyBox) | Out-Null
                $endpointLabel = New-Object System.Windows.Controls.Label
                $endpointLabel.Content = "API Endpoint:"
                switch ($Provider) {
                    "Twilio" {
                        Import-Module -Name "Modules/TTSProviders/Twilio.psm1" -Force
                        $providerFields = GetProviderSetupFields -Provider $Provider -Window $setupWindow -ConfigGrid $configGrid -GuidanceText $guidanceText
                    }
                    "VoiceForge" {
                        Import-Module -Name "Modules/TTSProviders/VoiceForge.psm1" -Force
                        $providerFields = GetProviderSetupFields -Provider $Provider -Window $setupWindow -ConfigGrid $configGrid -GuidanceText $guidanceText
                    }
                    "Azure Cognitive Services" {
                        Import-Module -Name "Modules/TTSProviders/Azure.psm1" -Force
                        $providerFields = GetProviderSetupFields -Provider $Provider -Window $setupWindow -ConfigGrid $configGrid -GuidanceText $guidanceText
                    }
                    "Amazon Polly" {
                        Import-Module -Name "Modules/TTSProviders/Polly.psm1" -Force
                        $providerFields = GetProviderSetupFields -Provider $Provider -Window $setupWindow -ConfigGrid $configGrid -GuidanceText $guidanceText
                    }
                    "Google Cloud" {
                        Import-Module -Name "Modules/TTSProviders/GoogleCloud.psm1" -Force
                        $providerFields = GetProviderSetupFields -Provider $Provider -Window $setupWindow -ConfigGrid $configGrid -GuidanceText $guidanceText
                    }
                    "CloudPronouncer" {
                        Import-Module -Name "Modules/TTSProviders/CloudPronouncer.psm1" -Force
                        $providerFields = GetProviderSetupFields -Provider $Provider -Window $setupWindow -ConfigGrid $configGrid -GuidanceText $guidanceText
                    }
                    default {
                        # Fallback/default implementation
                        $setupWindow.APIProviderInfo.Text = "Configure provider credentials and settings."
                    }
                }
                    "Central India" = "centralindia"
                    "South India" = "southindia"
                    "West India" = "westindia"
                    "Jio India West" = "jioindiawest"
                    "Jio India Central" = "jioindiacentral"
                    "UAE North" = "uaenorth"
                    "UAE Central" = "uaecentral"
                    "Qatar Central" = "qatarcentral"
                    "Israel Central" = "israelcentral"
                    "South Africa North" = "southafricanorth"
                    "South Africa West" = "southafricawest"
                    "Brazil South" = "brazilsouth"
                    "Brazil Southeast" = "brazilsoutheast"
                    "Brazil US" = "brazilus"
                }
                
                # Add regions to dropdown with friendly names, sorted alphabetically by display name
                foreach ($regionPair in $azureRegions.GetEnumerator() | Sort-Object Key) {
                    $item = New-Object System.Windows.Controls.ComboBoxItem
                    $item.Content = $regionPair.Key  # Display friendly name
                    $item.Tag = $regionPair.Value     # Store programmatic value
                    $regionBox.Items.Add($item) | Out-Null
                    
                    # Set selected item if it matches current datacenter
                    if ($script:Window.MS_Datacenter.Text -eq $regionPair.Value) {
                        $item.IsSelected = $true
                        Write-SafeLog -Message "Pre-selecting Azure region in setup dialog: $($regionPair.Key) ($($regionPair.Value))" -Level "DEBUG"
                    }
                }
                
                # Default to East US if no selection
                if (-not $regionBox.SelectedItem -and $script:Window.MS_Datacenter.Text) {
                    # Try to find the current value and select it
                    foreach ($item in $regionBox.Items) {
                        if ($item.Tag -eq $script:Window.MS_Datacenter.Text) {
                            $item.IsSelected = $true
                            Write-SafeLog -Message "Fallback pre-selecting Azure region in setup dialog: $($item.Content) ($($item.Tag))" -Level "DEBUG"
                            break
                        }
                    }
                } elseif (-not $regionBox.SelectedItem) {
                    $regionBox.SelectedIndex = 0  # Default to East US
                    Write-SafeLog -Message "No Azure region pre-selected, defaulting to East US" -Level "DEBUG"
                }
                [System.Windows.Controls.Grid]::SetRow($regionBox, 0)
                [System.Windows.Controls.Grid]::SetColumn($regionBox, 3)
                $configGrid.Children.Add($regionBox) | Out-Null
                
                # Endpoint Label
                $endpointLabel = New-Object System.Windows.Controls.Label
                $endpointLabel.Content = "Endpoint:"
                $endpointLabel.Foreground = "White"
                $endpointLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetRow($endpointLabel, 1)
                [System.Windows.Controls.Grid]::SetColumn($endpointLabel, 0)
                $configGrid.Children.Add($endpointLabel) | Out-Null
                
                # Endpoint TextBox
                $endpointBox = New-Object System.Windows.Controls.TextBox
                $endpointBox.Name = "API_MS_Endpoint"
                $endpointBox.Height = 25
                $endpointBox.Margin = "5,2"
                $endpointBox.Text = "https://{region}.tts.speech.microsoft.com/cognitiveservices/v1"
                [System.Windows.Controls.Grid]::SetRow($endpointBox, 1)
                [System.Windows.Controls.Grid]::SetColumn($endpointBox, 1)
                [System.Windows.Controls.Grid]::SetColumnSpan($endpointBox, 3)
                $configGrid.Children.Add($endpointBox) | Out-Null
                
                # Set guidance text
                $guidanceText.Text = @"
1. Sign in to the Azure Portal (portal.azure.com) with your Microsoft account
2. Create a new 'Cognitive Services' resource or use an existing one
3. Navigate to your Cognitive Services resource > Keys and Endpoint
4. Copy the 'Key 1' value and paste it into the API Key field above
5. Select your preferred region from the dropdown (should match your Azure resource region)
6. The service endpoint will be automatically configured based on your region
7. Click 'Test Connection' to verify your credentials are working

Note: You'll need an active Azure subscription to create Cognitive Services resources. The first 5 hours of speech synthesis are free each month.
"@
                
                # Save button logic
                $setupWindow.SaveAndClose.add_Click{
                    $script:Window.MS_KEY.Text = $apiKeyBox.Text
                    # Save the programmatic region value, not the display name
                    $selectedRegion = if ($regionBox.SelectedItem -and $regionBox.SelectedItem.Tag) { 
                        $regionBox.SelectedItem.Tag 
                    } else { 
                        "eastus" 
                    }
                    $script:Window.MS_Datacenter.Text = $selectedRegion

                    Write-SafeLog -Message "Saving Azure API Key: $($script:Window.MS_KEY.Text)" -Level "INFO"
                    Write-SafeLog -Message "Azure Cognitive Services configuration saved - Region: $selectedRegion" -Level "INFO"
                    if ($script:AutoSaveEnabled) { Invoke-AutoSaveConfiguration }

                    $setupWindow.DialogResult = $true
                    $setupWindow.Close()
                }
            }
            
            "Amazon Polly" {
                # Set up Amazon Polly configuration
                $setupWindow.APIProviderInfo.Text = "Configure Amazon Polly API credentials and regional settings."
                
                # Row 0: Access Key and Region
                $row0 = New-Object System.Windows.Controls.RowDefinition
                $row0.Height = [System.Windows.GridLength]::new(0, [System.Windows.GridUnitType]::Auto)
                $configGrid.RowDefinitions.Add($row0)
                
                # Row 1: Secret Key and Session Token
                $row1 = New-Object System.Windows.Controls.RowDefinition  
                $row1.Height = [System.Windows.GridLength]::new(0, [System.Windows.GridUnitType]::Auto)
                $configGrid.RowDefinitions.Add($row1)
                
                # Access Key Label
                $accessKeyLabel = New-Object System.Windows.Controls.Label
                $accessKeyLabel.Content = "Access Key:"
                $accessKeyLabel.Foreground = "White"
                $accessKeyLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetRow($accessKeyLabel, 0)
                [System.Windows.Controls.Grid]::SetColumn($accessKeyLabel, 0)
                $configGrid.Children.Add($accessKeyLabel) | Out-Null
                
                # Access Key TextBox
                $accessKeyBox = New-Object System.Windows.Controls.TextBox
                $accessKeyBox.Name = "API_AWS_AccessKey"
                $accessKeyBox.Height = 25
                $accessKeyBox.Margin = "5,2"
                if ($script:Window.AWS_AccessKey.Text) { $accessKeyBox.Text = $script:Window.AWS_AccessKey.Text }
                [System.Windows.Controls.Grid]::SetRow($accessKeyBox, 0)
                [System.Windows.Controls.Grid]::SetColumn($accessKeyBox, 1)
                $configGrid.Children.Add($accessKeyBox) | Out-Null
                
                # Region Label
                $regionLabel = New-Object System.Windows.Controls.Label
                $regionLabel.Content = "Region:"
                $regionLabel.Foreground = "White"
                $regionLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetRow($regionLabel, 0)
                [System.Windows.Controls.Grid]::SetColumn($regionLabel, 2)
                $configGrid.Children.Add($regionLabel) | Out-Null
                
                # Region ComboBox
                $regionBox = New-Object System.Windows.Controls.ComboBox
                $regionBox.Name = "API_AWS_Region"
                $regionBox.Height = 25
                $regionBox.Margin = "5,2"
                $regionBox.IsEditable = $true
                
                # Add AWS regions with human-friendly names, sorted alphabetically
                $awsRegionMap = @{
                    "US East (N. Virginia)" = "us-east-1"
                    "US East (Ohio)" = "us-east-2"
                    "US West (N. California)" = "us-west-1"
                    "US West (Oregon)" = "us-west-2"
                    "Asia Pacific (Hong Kong)" = "ap-east-1"
                    "Asia Pacific (Mumbai)" = "ap-south-1"
                    "Asia Pacific (Hyderabad)" = "ap-south-2"
                    "Asia Pacific (Jakarta)" = "ap-southeast-3"
                    "Asia Pacific (Melbourne)" = "ap-southeast-4"
                    "Asia Pacific (Singapore)" = "ap-southeast-1"
                    "Asia Pacific (Sydney)" = "ap-southeast-2"
                    "Asia Pacific (Seoul)" = "ap-northeast-2"
                    "Asia Pacific (Tokyo)" = "ap-northeast-1"
                    "Asia Pacific (Osaka)" = "ap-northeast-3"
                    "Canada (Central)" = "ca-central-1"
                    "Canada (West)" = "ca-west-1"
                    "Europe (Frankfurt)" = "eu-central-1"
                    "Europe (Zurich)" = "eu-central-2"
                    "Europe (Stockholm)" = "eu-north-1"
                    "Europe (Milan)" = "eu-south-1"
                    "Europe (Spain)" = "eu-south-2"
                    "Europe (Ireland)" = "eu-west-1"
                    "Europe (London)" = "eu-west-2"
                    "Europe (Paris)" = "eu-west-3"
                    "Middle East (UAE)" = "me-central-1"
                    "Middle East (Bahrain)" = "me-south-1"
                    "South America (São Paulo)" = "sa-east-1"
                    "Africa (Cape Town)" = "af-south-1"
                    "US GovCloud (East)" = "us-gov-east-1"
                    "US GovCloud (West)" = "us-gov-west-1"
                    "China (Beijing)" = "cn-north-1"
                    "China (Ningxia)" = "cn-northwest-1"
                }
                $sortedAwsRegions = $awsRegionMap.GetEnumerator() | Sort-Object Key
                foreach ($regionPair in $sortedAwsRegions) {
                    $item = New-Object System.Windows.Controls.ComboBoxItem
                    $item.Content = "$($regionPair.Key) [$($regionPair.Value)]"
                    $item.Tag = $regionPair.Value
                    $regionBox.Items.Add($item) | Out-Null
                    # Set selected item if it matches current region
                    if ($script:Window.AWS_Region.SelectedItem -and $script:Window.AWS_Region.SelectedItem.Content -eq $regionPair.Value) {
                        $item.IsSelected = $true
                    }
                }
                # Default to US West (Oregon) if no selection
                if (-not $regionBox.SelectedItem) {
                    foreach ($item in $regionBox.Items) {
                        if ($item.Tag -eq "us-west-2") { $item.IsSelected = $true; break }
                    }
                }
                [System.Windows.Controls.Grid]::SetRow($regionBox, 0)
                [System.Windows.Controls.Grid]::SetColumn($regionBox, 3)
                $configGrid.Children.Add($regionBox) | Out-Null
                
                # Secret Key Label
                $secretKeyLabel = New-Object System.Windows.Controls.Label
                $secretKeyLabel.Content = "Secret Key:"
                $secretKeyLabel.Foreground = "White"
                $secretKeyLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetRow($secretKeyLabel, 1)
                [System.Windows.Controls.Grid]::SetColumn($secretKeyLabel, 0)
                $configGrid.Children.Add($secretKeyLabel) | Out-Null
                
                # Secret Key PasswordBox
                $secretKeyBox = New-Object System.Windows.Controls.TextBox
                $secretKeyBox.Name = "API_AWS_SecretKey"
                $secretKeyBox.Height = 25
                $secretKeyBox.Margin = "5,2"
                if ($script:Window.AWS_SecretKey.Text) { $secretKeyBox.Text = $script:Window.AWS_SecretKey.Text }
                [System.Windows.Controls.Grid]::SetRow($secretKeyBox, 1)
                [System.Windows.Controls.Grid]::SetColumn($secretKeyBox, 1)
                $configGrid.Children.Add($secretKeyBox) | Out-Null
                
                # Session Token Label
                $sessionTokenLabel = New-Object System.Windows.Controls.Label
                $sessionTokenLabel.Content = "Session Token:"
                $sessionTokenLabel.Foreground = "White"
                $sessionTokenLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetRow($sessionTokenLabel, 1)
                [System.Windows.Controls.Grid]::SetColumn($sessionTokenLabel, 2)
                $configGrid.Children.Add($sessionTokenLabel) | Out-Null
                
                # Session Token TextBox
                $sessionTokenBox = New-Object System.Windows.Controls.TextBox
                $sessionTokenBox.Name = "API_AWS_SessionToken"
                $sessionTokenBox.Height = 25
                $sessionTokenBox.Margin = "5,2"
                $sessionTokenBox.Text = "(Optional)"
                [System.Windows.Controls.Grid]::SetRow($sessionTokenBox, 1)
                [System.Windows.Controls.Grid]::SetColumn($sessionTokenBox, 3)
                $configGrid.Children.Add($sessionTokenBox) | Out-Null
                
                # Set guidance text
                $guidanceText.Text = @"
1. Sign in to the AWS Console (console.aws.amazon.com) with your AWS account
2. Navigate to IAM > Users and create a new user or use an existing one
3. Attach the 'AmazonPollyFullAccess' policy to the user
4. Go to Security Credentials and create a new access key
5. Copy the Access Key ID and Secret Access Key into the fields above
6. Select your preferred AWS region from the dropdown
7. Session Token is optional and only needed for temporary credentials
8. Click 'Test Connection' to verify your credentials are working

Note: You'll need an active AWS account. The first 5 million characters per month are free for the first 12 months.
"@
                
                # Save button logic
                $setupWindow.SaveAndClose.add_Click{
                    $script:Window.AWS_AccessKey.Text = $accessKeyBox.Text
                    $script:Window.AWS_SecretKey.Text = $secretKeyBox.Text
                    Write-SafeLog -Message "Amazon Polly configuration saved" -Level "INFO"
                    if ($script:AutoSaveEnabled) { Invoke-AutoSaveConfiguration }
                    $setupWindow.DialogResult = $true
                    $setupWindow.Close()
                }
            }
            
            "Google Cloud" {
                # Set up Google Cloud configuration
                $setupWindow.APIProviderInfo.Text = "Configure Google Cloud Text-to-Speech API credentials and settings."
                
                # Row 0: API Key and Project ID
                $row0 = New-Object System.Windows.Controls.RowDefinition
                $row0.Height = [System.Windows.GridLength]::new(0, [System.Windows.GridUnitType]::Auto)
                $configGrid.RowDefinitions.Add($row0)
                
                # Row 1: Region and Service Endpoint
                $row1 = New-Object System.Windows.Controls.RowDefinition  
                $row1.Height = [System.Windows.GridLength]::new(0, [System.Windows.GridUnitType]::Auto)
                $configGrid.RowDefinitions.Add($row1)
                
                # API Key Label
                $apiKeyLabel = New-Object System.Windows.Controls.Label
                $apiKeyLabel.Content = "API Key:"
                $apiKeyLabel.Foreground = "White"
                $apiKeyLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetRow($apiKeyLabel, 0)
                [System.Windows.Controls.Grid]::SetColumn($apiKeyLabel, 0)
                $configGrid.Children.Add($apiKeyLabel) | Out-Null
                
                # API Key TextBox
                $apiKeyBox = New-Object System.Windows.Controls.TextBox
                $apiKeyBox.Name = "API_GC_APIKey"
                $apiKeyBox.Height = 25
                $apiKeyBox.Margin = "5,2"
                if ($script:Window.GC_APIKey.Password) { $apiKeyBox.Text = $script:Window.GC_APIKey.Password }
                [System.Windows.Controls.Grid]::SetRow($apiKeyBox, 0)
                [System.Windows.Controls.Grid]::SetColumn($apiKeyBox, 1)
                $configGrid.Children.Add($apiKeyBox) | Out-Null
                
                # Project ID Label
                $projectIdLabel = New-Object System.Windows.Controls.Label
                $projectIdLabel.Content = "Project ID:"
                $projectIdLabel.Foreground = "White"
                $projectIdLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetRow($projectIdLabel, 0)
                [System.Windows.Controls.Grid]::SetColumn($projectIdLabel, 2)
                $configGrid.Children.Add($projectIdLabel) | Out-Null
                
                # Project ID TextBox
                $projectIdBox = New-Object System.Windows.Controls.TextBox
                $projectIdBox.Name = "API_GC_ProjectID"
                $projectIdBox.Height = 25
                $projectIdBox.Margin = "5,2"
                [System.Windows.Controls.Grid]::SetRow($projectIdBox, 0)
                [System.Windows.Controls.Grid]::SetColumn($projectIdBox, 3)
                $configGrid.Children.Add($projectIdBox) | Out-Null
                
                # Region Label
                $regionLabel = New-Object System.Windows.Controls.Label
                $regionLabel.Content = "Region:"
                $regionLabel.Foreground = "White"
                $regionLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetRow($regionLabel, 1)
                [System.Windows.Controls.Grid]::SetColumn($regionLabel, 0)
                $configGrid.Children.Add($regionLabel) | Out-Null
                
                # Region ComboBox
                $regionBox = New-Object System.Windows.Controls.ComboBox
                $regionBox.Name = "API_GC_Region"
                $regionBox.Height = 25
                $regionBox.Margin = "5,2"
                $regionBox.IsEditable = $true
                
                # Add Google Cloud regions
                $gcRegions = @("global", "us", "eu", "asia", "us-central1", "us-east1", "us-east4", "us-west1", "us-west2", "us-west3", "us-west4", "us-south1", "northamerica-northeast1", "northamerica-northeast2", "southamerica-east1", "southamerica-west1", "europe-central2", "europe-north1", "europe-southwest1", "europe-west1", "europe-west2", "europe-west3", "europe-west4", "europe-west6", "europe-west8", "europe-west9", "asia-east1", "asia-east2", "asia-northeast1", "asia-northeast2", "asia-northeast3", "asia-south1", "asia-south2", "asia-southeast1", "asia-southeast2", "australia-southeast1", "australia-southeast2", "me-central1", "me-west1", "africa-south1")
                foreach ($region in $gcRegions) {
                    $item = New-Object System.Windows.Controls.ComboBoxItem
                    $item.Content = $region
                    $regionBox.Items.Add($item) | Out-Null
                }
                
                $regionBox.Text = "global"
                [System.Windows.Controls.Grid]::SetRow($regionBox, 1)
                [System.Windows.Controls.Grid]::SetColumn($regionBox, 1)
                $configGrid.Children.Add($regionBox) | Out-Null
                
                # Service Endpoint Label
                $endpointLabel = New-Object System.Windows.Controls.Label
                $endpointLabel.Content = "Service Endpoint:"
                $endpointLabel.Foreground = "White"
                $endpointLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetRow($endpointLabel, 1)
                [System.Windows.Controls.Grid]::SetColumn($endpointLabel, 2)
                $configGrid.Children.Add($endpointLabel) | Out-Null
                
                # Service Endpoint TextBox
                $endpointBox = New-Object System.Windows.Controls.TextBox
                $endpointBox.Name = "API_GC_Endpoint"
                $endpointBox.Height = 25
                $endpointBox.Margin = "5,2"
                $endpointBox.Text = "https://texttospeech.googleapis.com/v1/text:synthesize"
                [System.Windows.Controls.Grid]::SetRow($endpointBox, 1)
                [System.Windows.Controls.Grid]::SetColumn($endpointBox, 3)
                $configGrid.Children.Add($endpointBox) | Out-Null
                
                # Set guidance text
                $guidanceText.Text = @"
1. Go to the Google Cloud Console (console.cloud.google.com)
2. Create a new project or select an existing project
3. Enable the Cloud Text-to-Speech API for your project
4. Go to APIs & Services > Credentials
5. Create a new API key (restrict it to Cloud Text-to-Speech API for security)
6. Copy your Project ID from the project dashboard
7. Enter both the API key and Project ID in the fields above
8. Select your preferred region (global is recommended for most use cases)
9. Click 'Test Connection' to verify your setup

Note: You'll need a Google Cloud account with billing enabled. The first 1 million characters per month are free.
"@
                
                # Save button logic
                $setupWindow.SaveAndClose.add_Click{
                    $script:Window.GC_APIKey.Password = $apiKeyBox.Text
                    
                    Write-SafeLog -Message "Google Cloud configuration saved" -Level "INFO"
                    if ($script:AutoSaveEnabled) { Invoke-AutoSaveConfiguration }
                    
                    $setupWindow.DialogResult = $true
                    $setupWindow.Close()
                }
            }
            
            "CloudPronouncer" {
                # Set up CloudPronouncer configuration
                $setupWindow.APIProviderInfo.Text = "Configure CloudPronouncer API credentials and settings."
                
                # Row 0: Username and API Endpoint
                $row0 = New-Object System.Windows.Controls.RowDefinition
                $row0.Height = [System.Windows.GridLength]::new(0, [System.Windows.GridUnitType]::Auto)
                $configGrid.RowDefinitions.Add($row0)
                
                # Row 1: Password and Premium Account
                $row1 = New-Object System.Windows.Controls.RowDefinition  
                $row1.Height = [System.Windows.GridLength]::new(0, [System.Windows.GridUnitType]::Auto)
                $configGrid.RowDefinitions.Add($row1)
                
                # Username Label
                $usernameLabel = New-Object System.Windows.Controls.Label
                $usernameLabel.Content = "Username:"
                $usernameLabel.Foreground = "White"
                $usernameLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetRow($usernameLabel, 0)
                [System.Windows.Controls.Grid]::SetColumn($usernameLabel, 0)
                $configGrid.Children.Add($usernameLabel) | Out-Null
                
                # Username TextBox
                $usernameBox = New-Object System.Windows.Controls.TextBox
                $usernameBox.Name = "API_CP_Username"
                $usernameBox.Height = 25
                $usernameBox.Margin = "5,2"
                if ($script:Window.CP_Username.Text) { $usernameBox.Text = $script:Window.CP_Username.Text }
                [System.Windows.Controls.Grid]::SetRow($usernameBox, 0)
                [System.Windows.Controls.Grid]::SetColumn($usernameBox, 1)
                $configGrid.Children.Add($usernameBox) | Out-Null
                
                # API Endpoint Label
                $endpointLabel = New-Object System.Windows.Controls.Label
                $endpointLabel.Content = "API Endpoint:"
                $endpointLabel.Foreground = "White"
                $endpointLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetRow($endpointLabel, 0)
                [System.Windows.Controls.Grid]::SetColumn($endpointLabel, 2)
                $configGrid.Children.Add($endpointLabel) | Out-Null
                
                # API Endpoint TextBox
                $endpointBox = New-Object System.Windows.Controls.TextBox
                $endpointBox.Name = "API_CP_Endpoint"
                $endpointBox.Height = 25
                $endpointBox.Margin = "5,2"
                $endpointBox.Text = "https://api.cloudpronouncer.com/"
                [System.Windows.Controls.Grid]::SetRow($endpointBox, 0)
                [System.Windows.Controls.Grid]::SetColumn($endpointBox, 3)
                $configGrid.Children.Add($endpointBox) | Out-Null
                
                # Password Label
                $passwordLabel = New-Object System.Windows.Controls.Label
                $passwordLabel.Content = "Password:"
                $passwordLabel.Foreground = "White"
                $passwordLabel.VerticalAlignment = "Center"
                [System.Windows.Controls.Grid]::SetRow($passwordLabel, 1)
                [System.Windows.Controls.Grid]::SetColumn($passwordLabel, 0)
                $configGrid.Children.Add($passwordLabel) | Out-Null
                
                # Password PasswordBox
                $passwordBox = New-Object System.Windows.Controls.PasswordBox
                $passwordBox.Name = "API_CP_Password"
                $passwordBox.Height = 25
                $passwordBox.Margin = "5,2"
                if ($script:Window.CP_Password.Password) { $passwordBox.Password = $script:Window.CP_Password.Password }
                [System.Windows.Controls.Grid]::SetRow($passwordBox, 1)
                [System.Windows.Controls.Grid]::SetColumn($passwordBox, 1)
                $configGrid.Children.Add($passwordBox) | Out-Null
                
                # Premium Account CheckBox
                $premiumCheckBox = New-Object System.Windows.Controls.CheckBox
                $premiumCheckBox.Name = "API_CP_Premium"
                $premiumCheckBox.Content = "Premium Account"
                $premiumCheckBox.Foreground = "White"
                $premiumCheckBox.Margin = "5,5"
                [System.Windows.Controls.Grid]::SetRow($premiumCheckBox, 1)
                [System.Windows.Controls.Grid]::SetColumn($premiumCheckBox, 2)
                [System.Windows.Controls.Grid]::SetColumnSpan($premiumCheckBox, 2)
                $configGrid.Children.Add($premiumCheckBox) | Out-Null
                
                # Set guidance text
                $guidanceText.Text = @"
1. Visit the CloudPronouncer website (cloudpronouncer.com) and create an account
2. Sign up for a free or premium account based on your needs
3. Obtain your username and password from your account dashboard
4. Enter your CloudPronouncer username in the Username field
5. Enter your CloudPronouncer password in the Password field
6. The API endpoint is pre-configured but can be modified if needed
7. Check "Premium Account" if you have a premium subscription for enhanced features
8. Click 'Test Connection' to verify your credentials are working

Note: CloudPronouncer offers high-quality text-to-speech synthesis with various voice options. Free accounts have usage limitations.
"@
                
                # Save button logic
                $setupWindow.SaveAndClose.add_Click{
                    if ($script:Window.CP_Username) { $script:Window.CP_Username.Text = $usernameBox.Text }
                    if ($script:Window.CP_Password) { $script:Window.CP_Password.Password = $passwordBox.Password }
                    
                    Write-SafeLog -Message "CloudPronouncer configuration saved" -Level "INFO"
                    if ($script:AutoSaveEnabled) { Invoke-AutoSaveConfiguration }
                    
                    $setupWindow.DialogResult = $true
                    $setupWindow.Close()
                }
            }
            
            default {
                # Default provider setup
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
                        $providerModule = "Modules/TTSProviders/Azure.psm1"
                        Import-Module $providerModule -Force
                        $config = @{}
                        foreach ($child in $configGrid.Children) {
                            if ($child.Name -like "API_MS_*") {
                                $fieldName = $child.Name.Substring($child.Name.IndexOf('_')+1)
                                $config[$fieldName] = if ($child -is [System.Windows.Controls.PasswordBox]) { $child.Password } elseif ($child -is [System.Windows.Controls.CheckBox]) { $child.IsChecked } elseif ($child -is [System.Windows.Controls.ComboBox]) { $child.SelectedItem.Content } else { $child.Text }
                            }
                        }
                        $isValid = ValidateProviderCredentials -Config $config
                        if ($isValid) {
                            $setupWindow.ConnectionStatus.Text = "✅ Credentials valid!"
                            $setupWindow.ConnectionStatus.Foreground = "#FF00FF00"
                            Update-APIStatus -SetupStatus "Validated" -SetupColor "#FF00FF00"
                        } else {
                            $setupWindow.ConnectionStatus.Text = "❌ Invalid credentials or configuration."
                            $setupWindow.ConnectionStatus.Foreground = "#FFFF0000"
                        }
                    }
                    "Amazon Polly" {
                        $providerModule = "Modules/TTSProviders/Polly.psm1"
                        Import-Module $providerModule -Force
                        $config = @{}
                        foreach ($child in $configGrid.Children) {
                            if ($child.Name -like "API_AWS_*") {
                                $fieldName = $child.Name.Substring($child.Name.IndexOf('_')+1)
                                $config[$fieldName] = if ($child -is [System.Windows.Controls.PasswordBox]) { $child.Password } elseif ($child -is [System.Windows.Controls.CheckBox]) { $child.IsChecked } elseif ($child -is [System.Windows.Controls.ComboBox]) { $child.SelectedItem.Content } else { $child.Text }
                            }
                        }
                        $isValid = ValidateProviderCredentials -Config $config
                        if ($isValid) {
                            $setupWindow.ConnectionStatus.Text = "✅ Credentials valid!"
                            $setupWindow.ConnectionStatus.Foreground = "#FF00FF00"
                            Update-APIStatus -SetupStatus "Validated" -SetupColor "#FF00FF00"
                        } else {
                            $setupWindow.ConnectionStatus.Text = "❌ Invalid credentials or configuration."
                            $setupWindow.ConnectionStatus.Foreground = "#FFFF0000"
                        }
                    }
                    "Google Cloud" {
                        $providerModule = "Modules/TTSProviders/GoogleCloud.psm1"
                        Import-Module $providerModule -Force
                        $config = @{}
                        foreach ($child in $configGrid.Children) {
                            if ($child.Name -like "API_GC_*") {
                                $fieldName = $child.Name.Substring($child.Name.IndexOf('_')+1)
                                $config[$fieldName] = if ($child -is [System.Windows.Controls.PasswordBox]) { $child.Password } elseif ($child -is [System.Windows.Controls.CheckBox]) { $child.IsChecked } elseif ($child -is [System.Windows.Controls.ComboBox]) { $child.SelectedItem.Content } else { $child.Text }
                            }
                        }
                        $isValid = ValidateProviderCredentials -Config $config
                        if ($isValid) {
                            $setupWindow.ConnectionStatus.Text = "✅ Credentials valid!"
                            $setupWindow.ConnectionStatus.Foreground = "#FF00FF00"
                            Update-APIStatus -SetupStatus "Validated" -SetupColor "#FF00FF00"
                        } else {
                            $setupWindow.ConnectionStatus.Text = "❌ Invalid credentials or configuration."
                            $setupWindow.ConnectionStatus.Foreground = "#FFFF0000"
                        }
                    }
                    "CloudPronouncer" {
                        $providerModule = "Modules/TTSProviders/CloudPronouncer.psm1"
                        Import-Module $providerModule -Force
                        $config = @{}
                        foreach ($child in $configGrid.Children) {
                            if ($child.Name -like "API_CP_*") {
                                $fieldName = $child.Name.Substring($child.Name.IndexOf('_')+1)
                                $config[$fieldName] = if ($child -is [System.Windows.Controls.PasswordBox]) { $child.Password } elseif ($child -is [System.Windows.Controls.CheckBox]) { $child.IsChecked } elseif ($child -is [System.Windows.Controls.ComboBox]) { $child.SelectedItem.Content } else { $child.Text }
                            }
                        }
                        $isValid = ValidateProviderCredentials -Config $config
                        if ($isValid) {
                            $setupWindow.ConnectionStatus.Text = "✅ Credentials valid!"
                            $setupWindow.ConnectionStatus.Foreground = "#FF00FF00"
                            Update-APIStatus -SetupStatus "Validated" -SetupColor "#FF00FF00"
                        } else {
                            $setupWindow.ConnectionStatus.Text = "❌ Invalid credentials or configuration."
                            $setupWindow.ConnectionStatus.Foreground = "#FFFF0000"
                        }
                    }
                    "Twilio" {
                        $providerModule = "Modules/TTSProviders/Twilio.psm1"
                        Import-Module $providerModule -Force
                        $config = @{}
                        foreach ($child in $configGrid.Children) {
                            if ($child.Name -like "API_TW_*") {
                                $fieldName = $child.Name.Substring($child.Name.IndexOf('_')+1)
                                $config[$fieldName] = if ($child -is [System.Windows.Controls.PasswordBox]) { $child.Password } elseif ($child -is [System.Windows.Controls.CheckBox]) { $child.IsChecked } elseif ($child -is [System.Windows.Controls.ComboBox]) { $child.SelectedItem.Content } else { $child.Text }
                            }
                        }
                        $isValid = ValidateProviderCredentials -Config $config
                        if ($isValid) {
                            $setupWindow.ConnectionStatus.Text = "✅ Credentials valid!"
                            $setupWindow.ConnectionStatus.Foreground = "#FF00FF00"
                            Update-APIStatus -SetupStatus "Validated" -SetupColor "#FF00FF00"
                        } else {
                            $setupWindow.ConnectionStatus.Text = "❌ Invalid credentials or configuration."
                            $setupWindow.ConnectionStatus.Foreground = "#FFFF0000"
                        }
                    }
                    "VoiceForge" {
                        $providerModule = "Modules/TTSProviders/VoiceForge.psm1"
                        Import-Module $providerModule -Force
                        $config = @{}
                        foreach ($child in $configGrid.Children) {
                            if ($child.Name -like "API_VF_*") {
                                $fieldName = $child.Name.Substring($child.Name.IndexOf('_')+1)
                                $config[$fieldName] = if ($child -is [System.Windows.Controls.PasswordBox]) { $child.Password } elseif ($child -is [System.Windows.Controls.CheckBox]) { $child.IsChecked } elseif ($child -is [System.Windows.Controls.ComboBox]) { $child.SelectedItem.Content } else { $child.Text }
                            }
                        }
                        $isValid = ValidateProviderCredentials -Config $config
                        if ($isValid) {
                            $setupWindow.ConnectionStatus.Text = "✅ Credentials valid!"
                            $setupWindow.ConnectionStatus.Foreground = "#FF00FF00"
                            Update-APIStatus -SetupStatus "Validated" -SetupColor "#FF00FF00"
                        } else {
                            $setupWindow.ConnectionStatus.Text = "❌ Invalid credentials or configuration."
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
        
        # Show the dialog
        $result = $setupWindow.ShowDialog()
        Write-SafeLog -Message "Setup dialog closed with result: $result" -Level "INFO"
        
    } catch {
        Write-SafeLog -Message "Error showing setup dialog: $($_.Exception.Message)" -Level "ERROR"
        [System.Windows.MessageBox]::Show("Error opening setup dialog: $($_.Exception.Message)", "Setup Error", "OK", "Error")
    }

    Export-ModuleMember -Function Show-ProviderSetup
}
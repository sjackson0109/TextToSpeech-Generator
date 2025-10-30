function Initialise-EventHandlers {
    <#
    .SYNOPSIS
    Initialise all GUI event handlers
    #>
    
    # Provider selection change
    $script:Window.ProviderSelect.add_SelectionChanged{
        $selectedProvider = $script:Window.ProviderSelect.SelectedItem.Content
        Write-SafeLog -Message "Provider switched to: $selectedProvider" -Level "INFO"
        Update-VoiceOptions -Provider $selectedProvider
        
        # Reset status when provider changes
        Update-APIStatus -SetupStatus "Click Setup" -SetupColor "#FFFF0000" -ConnectStatus "Last Connect: Never" -ConnectColor "#FFDDDDDD"
        
        # Auto-save on provider change
        if ($script:AutoSaveEnabled) {
            Invoke-AutoSaveConfiguration
        }
    }
    
    # Test API connection
    $null = $script:Window.TestAPI.Add_Click({
        $selectedProvider = $script:Window.ProviderSelect.SelectedItem.Content
        Write-SafeLog -Message "Testing API connection for: $selectedProvider" -Level "INFO"
        if ($selectedProvider -eq "Azure Cognitive Services") {
            $apiKey = $script:Window.MS_KEY.Text
            $region = $script:Window.MS_Datacenter.Text
            $tokenEndpoint = "https://$region.api.cognitive.microsoft.com/sts/v1.0/issueToken"
            $headers = @{ 'Ocp-Apim-Subscription-Key' = $apiKey }
            try {
                $token = Invoke-RestMethod -Uri $tokenEndpoint -Method POST -Headers $headers -TimeoutSec 10 -ErrorAction Stop
                Write-SafeLog -Message "Azure API token retrieved: $token" -Level "INFO"
                    # Always pass a valid SetupStatus string to avoid binding errors
                    Update-APIStatus -SetupStatus "Validated" -SetupColor "#FF00FF00" -ConnectStatus "Token retrieved" -ConnectColor "#FF00FF00"
                $script:Window.LogOutput.Text += "`nAzure API token: $token"
                if ($script:AutoSaveEnabled) { Invoke-AutoSaveConfiguration }
            } catch {
                Write-SafeLog -Message "❌ Azure API token retrieval failed: $($_.Exception.Message)" -Level "ERROR"
                    Update-APIStatus -SetupStatus "Setup Required" -SetupColor "#FFFF0000" -ConnectStatus "Token retrieval failed" -ConnectColor "#FFFF0000"
            }
        } else {
            Test-ProviderConnection -Provider $selectedProvider
        }
    })
    
    # Configure API Setup
    $script:Window.ConfigureAPI.add_Click{
        $selectedProvider = $script:Window.ProviderSelect.SelectedItem.Content
        Write-SafeLog -Message "Opening API setup for: $selectedProvider" -Level "INFO"
        Show-ProviderSetup -Provider $selectedProvider
    }
    
    # Bulk mode toggle
    $script:Window.BulkMode.add_Checked{
        $script:Window.CSVImport.IsEnabled = $true
        $script:Window.Input_Text.IsEnabled = $false
        $script:Window.Input_Text.Background = "#FFE0E0E0"
        Write-SafeLog -Message "Bulk mode enabled" -Level "INFO"
    }
    
    $script:Window.BulkMode.add_Unchecked{
        $script:Window.CSVImport.IsEnabled = $false
        $script:Window.Input_Text.IsEnabled = $true
        $script:Window.Input_Text.Background = "White"
        Write-SafeLog -Message "Single mode enabled" -Level "INFO"
    }
    
    # Window closing event - Auto-save
    $script:Window.add_Closing{
        param($sender, $e)
        try {
            Write-SafeLog -Message "Application closing - auto-saving configuration" -Level "INFO"
            Invoke-AutoSaveConfiguration
            Write-SafeLog -Message "Application session completed" -Level "INFO"
        } catch {
            Write-SafeLog -Message "Error during window close: $($_.Exception.Message)" -Level "ERROR"
            # Don't cancel the close operation even if auto-save fails
        }
    }
    
    # Text changed events for auto-save
    $script:Window.Input_Text.add_TextChanged{
        if ($script:AutoSaveEnabled) {
            Start-DelayedAutoSave
        }
    }
    
    Write-SafeLog -Message "Event handlers Initialised" -Level "INFO"
}

Export-ModuleMember -Function Initialise-EventHandlers
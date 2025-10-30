function Initialise-GUIComponents {
    <#
    .SYNOPSIS
    Initialise GUI components with default values
    #>
    
    # Set default values
    $script:Window.LogOutput.Text = ""
    $script:Window.BulkMode.IsChecked = $false
    $script:Window.CSVImport.IsEnabled = $false
    $script:Window.Input_Text.IsEnabled = $true
    
    # Initialise provider selection
    $script:Window.ProviderSelect.SelectedIndex = 0  # Default to Azure
    
    # Initialise voice options for default provider
    Update-VoiceOptions -Provider "Azure Cognitive Services"
    
    Write-SafeLog -Message "GUI components Initialised" -Level "INFO"
}

Export-ModuleMember -Function Initialise-GuiComponents
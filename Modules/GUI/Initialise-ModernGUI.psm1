function Initialise-ModernGUI {
    <#
    .SYNOPSIS
    Initialise the modern GUI with profile-based configuration
    #>
    param(
        [string]$Profile = "Default",
        [object]$ConfigurationManager = $null
    )
    
    $script:CurrentProfile = $Profile
    $script:ConfigManager = $ConfigurationManager
    
    Write-SafeLog -Message "Initializing Modern GUI with profile: $Profile" -Level "INFO"
    
    try {
        # Convert XAML to Window
        $script:Window = Convert-XAMLtoWindow -XAML $script:XAML
        $global:window = $script:Window  # For backward compatibility
        
        # Update profile display
        $script:Window.ProfileStatus.Text = $Profile
        
        # Initialise GUI components
        Initialise-GUIComponents
        Initialise-EventHandlers
        
        # Auto-load configuration
        Invoke-AutoLoadConfiguration
        
        # Ensure window is visible
        $script:Window.Visibility = [System.Windows.Visibility]::Visible
        $script:Window.WindowState = [System.Windows.WindowState]::Normal
        
        Write-SafeLog -Message "Modern GUI Initialised successfully" -Level "INFO"
        return $script:Window
        
    } catch {
        Write-SafeLog -Message "Failed to Initialise Modern GUI: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

Export-ModuleMember -Function Initialise-ModernGUI
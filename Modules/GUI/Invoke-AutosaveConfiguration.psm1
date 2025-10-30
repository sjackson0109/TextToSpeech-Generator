function Invoke-AutoSaveConfiguration {
    <#
    .SYNOPSIS
    Auto-save current configuration
    #>
    
    try {
        # For now, save directly to Default.json until we can integrate properly with config manager
        $configPath = if ($script:ConfigManager -and $script:ConfigManager.ConfigPath) {
            $script:ConfigManager.ConfigPath
        } else {
            Join-Path $PSScriptRoot "..\..\Default.json"
        }
        
        # Load existing config to preserve structure
        $existingConfig = @{}
        if (Test-Path $configPath) {
            try {
                $existingConfig = Get-Content $configPath -Raw | ConvertFrom-Json -AsHashtable
            } catch {
                Write-SafeLog -Message "Error reading existing config for save: $($_.Exception.Message)" -Level "WARNING"
                $existingConfig = @{}
            }
        }
        
        # Initialise structure if needed
        if (-not $existingConfig.ConfigVersion) { $existingConfig.ConfigVersion = "3.2" }
        if (-not $existingConfig.Profiles) { $existingConfig.Profiles = @{} }
        if (-not $existingConfig.Profiles.$script:CurrentProfile) { $existingConfig.Profiles.$script:CurrentProfile = @{} }
        
        # Get current GUI configuration
        $currentConfig = Get-GUIConfiguration
        
        # Update the profile with current settings
        $existingConfig.Profiles.$script:CurrentProfile = $currentConfig
        
        # Save back to JSON
        $existingConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
        
        $script:Window.ConfigStatus.Text = "Auto-Saved"
        $script:Window.ConfigStatus.Foreground = "#FF00FF00"
        Write-SafeLog -Message "Configuration auto-saved for profile: $script:CurrentProfile" -Level "INFO"
        
    } catch {
        Write-SafeLog -Message "Auto-save failed: $($_.Exception.Message)" -Level "ERROR"
        $script:Window.ConfigStatus.Text = "Save Error"
        $script:Window.ConfigStatus.Foreground = "#FFFF0000"
    }
}

Export-ModuleMember -Function Invoke-AutoSaveConfiguration
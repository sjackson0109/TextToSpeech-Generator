function Invoke-AutoLoadConfiguration {
    <#
    .SYNOPSIS
    Auto-load configuration on startup
    #>
    
    try {
        Write-SafeLog -Message "Auto-loading configuration for profile: $script:CurrentProfile" -Level "INFO"
        
        # For now, just load from the Default.json file directly since the config manager method isn't working
        $configPath = if ($script:ConfigManager -and $script:ConfigManager.ConfigPath) {
            $script:ConfigManager.ConfigPath
        } else {
            Join-Path $PSScriptRoot "..\..\Default.json"
        }
        
        if (Test-Path $configPath) {
            $configContent = Get-Content $configPath -Raw | ConvertFrom-Json -AsHashtable
            
            # Look for the profile configuration
            $profileConfig = $null
            if ($configContent.Profiles -and $configContent.Profiles.$script:CurrentProfile) {
                $profileConfig = $configContent.Profiles.$script:CurrentProfile
            } elseif ($configContent.Profiles -and $configContent.Profiles.Default) {
                $profileConfig = $configContent.Profiles.Default
                Write-SafeLog -Message "Profile '$script:CurrentProfile' not found, using Default" -Level "WARNING"
            } elseif ($configContent.Profiles -and $configContent.Profiles.Development) {
                $profileConfig = $configContent.Profiles.Development
                Write-SafeLog -Message "Profile '$script:CurrentProfile' not found, using Development" -Level "WARNING"
            }
            
            if ($profileConfig) {
                Apply-ConfigurationToGUI -Configuration $profileConfig
                $script:Window.ConfigStatus.Text = "Auto-Loaded"
                $script:Window.ConfigStatus.Foreground = "#FF00FF00"
                Write-SafeLog -Message "Configuration auto-loaded successfully" -Level "INFO"
            } else {
                $script:Window.ConfigStatus.Text = "No Config"
                $script:Window.ConfigStatus.Foreground = "#FFFFFF00"
                Write-SafeLog -Message "No configuration found for profile: $script:CurrentProfile" -Level "WARNING"
            }
        } else {
            $script:Window.ConfigStatus.Text = "No Config File"
            $script:Window.ConfigStatus.Foreground = "#FFFFFF00"
            Write-SafeLog -Message "Configuration file not found: $configPath" -Level "WARNING"
        }
        
    } catch {
        Write-SafeLog -Message "Auto-load failed: $($_.Exception.Message)" -Level "ERROR"
        $script:Window.ConfigStatus.Text = "Load Error"
        $script:Window.ConfigStatus.Foreground = "#FFFF0000"
    }
}

Export-ModuleMember -Function Invoke-AutoLoadConfiguration
# Legacy Configuration Migration Utility
# Converts old XML configuration to new JSON-based modular system

param(
    [string]$XmlConfigPath = ".\TextToSpeech-Generator.xml",
    [string]$OutputPath = ".\config.json",
    [switch]$BackupOriginal = $true
)

function Convert-LegacyXmlToModularConfig {
    param(
        [string]$XmlPath,
        [string]$JsonPath
    )
    
    if (-not (Test-Path $XmlPath)) {
    Write-ApplicationLog -Module "MigrateLegacyConfig" -Message "XML configuration file not found: $XmlPath" -Level "WARNING"
        return $false
    }
    
    try {
        # Load XML configuration
        [xml]$xmlConfig = Get-Content $XmlPath
        $config = $xmlConfig.configuration
        
        # Create new modular configuration structure
        $newConfig = @{
            ConfigVersion = "3.2"
            CurrentProfile = "Development"
            Profiles = @{
                Development = @{
                    Providers = @{
                        "Microsoft Azure" = @{
                            Enabled = $true
                            ApiKey = $config.MS_Key
                            Datacenter = $config.MS_Datacenter
                            AudioFormat = $config.MS_Audio_Format
                            DefaultVoice = $config.MS_Voice
                        }
                    }
                    Processing = @{
                        InputFile = $config.Input_File -replace '%userprofile%', $env:USERPROFILE
                        OutputPath = $config.Output_Path -replace '%userprofile%', $env:USERPROFILE
                        MaxParallelJobs = 2
                        Timeout = 30
                    }
                    Logging = @{
                        Level = "INFO"
                        EnableDetailedLogging = $true
                    }
                }
            }
            LastMigrated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            MigratedFrom = "TextToSpeech-Generator.xml"
        }
        
        # Save new JSON configuration
        $newConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $JsonPath -Encoding UTF8
        
        Write-Host "✓ Successfully migrated configuration from XML to JSON" -ForegroundColor Green
        Write-Host "  Source: $XmlPath" -ForegroundColor Gray
        Write-Host "  Target: $JsonPath" -ForegroundColor Gray
        
        return $true
        
    } catch {
    Write-ApplicationLog -Module "MigrateLegacyConfig" -Message "Failed to migrate configuration: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

function Show-MigrationSummary {
    Write-Host "`n=== Legacy Configuration Migration ===" -ForegroundColor Cyan
    Write-Host "This utility helps migrate from the old XML-based configuration" -ForegroundColor Yellow
    Write-Host "to the new JSON-based modular configuration system.`n" -ForegroundColor Yellow
    
    Write-Host "Benefits of the new system:" -ForegroundColor Green
    Write-Host "  ✓ Multiple environment profiles (Development/Production/Testing)" -ForegroundColor White
    Write-Host "  ✓ Enhanced security with encrypted storage options" -ForegroundColor White
    Write-Host "  ✓ Better validation and error handling" -ForegroundColor White
    Write-Host "  ✓ Support for multiple TTS providers" -ForegroundColor White
    Write-Host "  ✓ Advanced performance monitoring integration`n" -ForegroundColor White
}

# Main execution
Show-MigrationSummary

if (Test-Path $XmlConfigPath) {
    Write-Host "Found legacy XML configuration: $XmlConfigPath" -ForegroundColor Yellow
    
    if ($BackupOriginal) {
        $backupPath = "$XmlConfigPath.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $XmlConfigPath $backupPath
        Write-Host "✓ Created backup: $backupPath" -ForegroundColor Green
    }
    
    $success = Convert-LegacyXmlToModularConfig -XmlPath $XmlConfigPath -JsonPath $OutputPath
    
    if ($success) {
        Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
        Write-Host "1. Review the new configuration: $OutputPath" -ForegroundColor White
        Write-Host "2. Update any API keys or settings as needed" -ForegroundColor White
        Write-Host "3. Test with: .\StartTTS.ps1 -TestMode" -ForegroundColor White
        Write-Host "4. Consider removing the old XML file when satisfied" -ForegroundColor White
        
        Write-Host "`n=== Deprecation Notice ===" -ForegroundColor Yellow
        Write-Host "• TextToSpeech-Generator.xml is now LEGACY" -ForegroundColor Red
        Write-Host "• TextToSpeech-Generator.ps1 will be modularized in future versions" -ForegroundColor Yellow
        Write-Host "• StartTTS.ps1 is the new recommended launcher" -ForegroundColor Green
    }
} else {
    Write-Host "No legacy XML configuration found at: $XmlConfigPath" -ForegroundColor Gray
    Write-Host "The system will use default JSON configuration." -ForegroundColor Green
}
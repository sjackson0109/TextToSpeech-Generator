# Main Application Script for TextToSpeech Generator
# This script launches the modern GUI and main workflow

Import-Module (Resolve-Path (Join-Path $PSScriptRoot 'Modules/GUI/GUI.psm1')).Path -Force

# Launch the main GUI window
try {
    New-GUI -Profile "Default"
} catch {
    Write-Host "Failed to launch main GUI: $($_.Exception.Message)" -ForegroundColor Red
    Write-ApplicationLog -Module "TextToSpeech-Generator" -Message "Main GUI launch failed: $($_.Exception.Message)" -Level "ERROR"
}

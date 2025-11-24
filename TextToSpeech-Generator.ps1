# Main Application Script for TextToSpeech Generator
# This script launches the modern GUI and main workflow


# Check for GUI.psm1 existence and WPF assembly availability
$guiModulePath = Join-Path $PSScriptRoot 'Modules/GUI.psm1'
$wpfAvailable = $false
if (Test-Path $guiModulePath) {
    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
        $wpfAvailable = $true
    } catch {
        Write-Host "WPF PresentationFramework assembly not available. GUI will be disabled. CLI mode only." -ForegroundColor Yellow
        Add-ApplicationLog -Module "TextToSpeech-Generator" -Message "WPF PresentationFramework assembly not available. GUI will be disabled. CLI mode only." -Level "WARNING"
    }
    if ($wpfAvailable) {
        try {
            Import-Module $guiModulePath -Force -ErrorAction Stop
            Add-ApplicationLog -Module "TextToSpeech-Generator" -Message "Creating GUI instance..." -Level "INFO"
            $gui = New-GUI -Profile "Default"
            
            Add-ApplicationLog -Module "TextToSpeech-Generator" -Message "GUI object type: $($gui.GetType().FullName)" -Level "DEBUG"
            Add-ApplicationLog -Module "TextToSpeech-Generator" -Message "GUI object is null: $($null -eq $gui)" -Level "DEBUG"
            
            # Show the GUI and keep the application alive
            if ($gui -ne $null) {
                Add-ApplicationLog -Module "TextToSpeech-Generator" -Message "GUI object created, checking Window property..." -Level "INFO"
                Add-ApplicationLog -Module "TextToSpeech-Generator" -Message "GUI.Window is null: $($null -eq $gui.Window)" -Level "DEBUG"
                
                if ($gui.Window -ne $null) {
                    Add-ApplicationLog -Module "TextToSpeech-Generator" -Message "GUI.Window type: $($gui.Window.GetType().FullName)" -Level "DEBUG"
                } else {
                    Add-ApplicationLog -Module "TextToSpeech-Generator" -Message "GUI.Window is null - XAML conversion failed" -Level "ERROR"
                }
                
                if ($gui.Window) {
                    Add-ApplicationLog -Module "TextToSpeech-Generator" -Message "GUI window created successfully - showing interface" -Level "INFO"
                    $gui.Window.ShowDialog()
                    Add-ApplicationLog -Module "TextToSpeech-Generator" -Message "GUI window closed by user" -Level "INFO"
                } else {
                    Write-Host "GUI window property is null" -ForegroundColor Red
                    Add-ApplicationLog -Module "TextToSpeech-Generator" -Message "GUI window creation failed - Window property is null" -Level "ERROR"
                }
            } else {
                Write-Host "GUI object is null" -ForegroundColor Red
                Add-ApplicationLog -Module "TextToSpeech-Generator" -Message "GUI creation failed - New-GUI returned null" -Level "ERROR"
            }
        } catch {
            Write-Host "Failed to launch main GUI: $($_.Exception.Message)" -ForegroundColor Red
            Add-ApplicationLog -Module "TextToSpeech-Generator" -Message "Main GUI launch failed: $($_.Exception.Message)" -Level "ERROR"
        }
    } else {
        Write-Host "GUI module present but WPF unavailable. Running in CLI mode only." -ForegroundColor Yellow
        Add-ApplicationLog -Module "TextToSpeech-Generator" -Message "GUI module present but WPF unavailable. Running in CLI mode only." -Level "WARNING"
    }
} else {
    Write-Host "GUI module not found. Running in CLI mode only." -ForegroundColor Yellow
    Add-ApplicationLog -Module "TextToSpeech-Generator" -Message "GUI module not found. Running in CLI mode only." -Level "WARNING"
}

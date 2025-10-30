# Test script to verify the API setup dialog is working
Write-Host "Testing API Setup Dialog..." -ForegroundColor Green

# Give the application time to fully load
Start-Sleep -Seconds 2

# Test opening a MessageBox to confirm GUI is accessible
Add-Type -AssemblyName System.Windows.Forms
$result = [System.Windows.Forms.MessageBox]::Show("Click the ⚙️ Setup button in the TextToSpeech application to test the new styling.`n`nThe dialog should now match the original design with:`n`n• GroupBox sections with proper headers`n• Grid-based layout with labels and controls`n• Microsoft Azure region dropdown`n• Connection testing section`n• Setup instructions with detailed guidance`n• Proper styling and spacing`n`nClick OK to continue...", "API Setup Dialog Test", "OK", "Information")

Write-Host "Test completed. Check the setup dialog appearance." -ForegroundColor Yellow
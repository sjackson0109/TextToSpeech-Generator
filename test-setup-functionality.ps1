# Test script to verify the API Setup Dialogueue functionality
Write-Host "=== API Setup Dialogueue Test ===" -ForegroundColor Cyan
Write-Host "Application is running. Testing the setup Dialogueue..." -ForegroundColor Green

# Wait for the application to fully load
Start-Sleep -Seconds 3

# Create a test to verify the Dialogueue can be opened
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationFramework

Write-Host "Testing Setup Dialogueue Access..." -ForegroundColor Yellow

# Show instructions to the user
$testMessage = @"
✅ SETUP Dialogueue TEST INSTRUCTIONS:

1. The TextToSpeech Generator v3.2 should now be running
2. Click the "⚙️ Setup" button in the application
3. Verify the new Dialogueue has the following features:

EXPECTED STYLING & LAYOUT:
✓ Professional window with proper sizing (750x350 minimum)
✓ GroupBox sections with headers:
  - "Provider Setup" with description
  - "Microsoft Azure Configuration" (or selected provider)
  - "Connection Testing" with validate button
  - "Setup Instructions" with detailed guidance
✓ Grid-based layout with proper spacing
✓ Region dropdown with all Azure regions
✓ API Key and Endpoint fields
✓ "Save & Close" and "Reset to Defaults" buttons

FUNCTIONALITY TO TEST:
✓ Setup button opens the Dialogueue
✓ Region dropdown is populated
✓ API Key field accepts input
✓ Connection testing button responds
✓ Save & Close saves configuration
✓ Instructions are provider-specific

Click OK to proceed with manual testing...
"@

[System.Windows.Forms.MessageBox]::Show($testMessage, "API Setup Dialogueue Test", "OK", "Information")

Write-Host "Manual testing initiated. Please test the Setup Dialogueue functionality." -ForegroundColor Green
Write-Host "Check the console output for any errors or logging information." -ForegroundColor White
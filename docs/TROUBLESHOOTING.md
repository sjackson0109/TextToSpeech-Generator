# Troubleshooting Guide

This comprehensive guide covers common issues, solutions, and diagnostic steps for the TextToSpeech Generator.

## 🚨 Common Issues and Solutions

### Authentication Problems

#### Issue: "Authentication failed: Invalid API key"

**Symptoms**:
- Error message in log window
- No voices loaded in dropdown
- Generation fails immediately

**Solutions**:
1. **Verify API Key Format**:
   - **Azure**: 32 hexadecimal characters (0-9, a-f)
   - **Google**: Varies, typically 39+ characters with specific format
   
2. **Check Key Status**:
   - Log into provider portal
   - Verify key is active and not expired
   - Check billing status

3. **Test Key Manually**:
   ```powershell
   # Azure test
   $headers = @{"Ocp-Apim-Subscription-Key"="YOUR_KEY"}
   Invoke-RestMethod -Uri "https://eastus.api.cognitive.microsoft.com/sts/v1.0/issueToken" -Method POST -Headers $headers
   ```

#### Issue: "Failed to retrieve valid authentication token"

**Symptoms**:
- Token request fails
- Empty token response
- Subsequent API calls fail

**Solutions**:
1. **Check Network Connectivity**:
   ```powershell
   Test-NetConnection -ComputerName "eastus.api.cognitive.microsoft.com" -Port 443
   ```

2. **Verify Datacenter Region**:
   - Ensure selected region matches subscription
   - Try different region if available

3. **Check Firewall/Proxy**:
   - Allow HTTPS (443) outbound
   - Configure proxy settings if needed

### File Processing Errors

#### Issue: "CSV validation failed: Missing required columns"

**Symptoms**:
- CSV file won't load
- Error about SCRIPT or FILENAME columns
- Bulk processing unavailable

**Solutions**:
1. **Check CSV Format**:
   ```csv
   SCRIPT,FILENAME
   "Hello world",hello_world
   "Welcome message",welcome_msg
   ```

2. **Verify Column Names**:
   - Must be exactly `SCRIPT` and `FILENAME`
   - Case sensitive
   - No extra spaces

3. **Check CSV Encoding**:
   - Save as UTF-8 or ANSI
   - Avoid Unicode BOM if possible

#### Issue: "No write permissions to selected folder"

**Symptoms**:
- Cannot generate audio files
- Error during file save
- Files created but corrupted

**Solutions**:
1. **Check Folder Permissions**:
   - Right-click folder → Properties → Security
   - Ensure current user has "Modify" permissions
   
2. **Try Different Location**:
   - Use Documents or Desktop folder
   - Avoid system directories (C:\Windows, etc.)
   
3. **Run as Administrator**:
   - Right-click PowerShell → Run as Administrator
   - Execute script with elevated privileges

### Network and Connectivity

#### Issue: Connection timeouts or slow responses

**Symptoms**:
- Requests take longer than 30-60 seconds
- Intermittent failures
- Partial file generation

**Solutions**:
1. **Check Internet Speed**:
   - Ensure stable broadband connection
   - Test with speed test tool
   
2. **Try Different Datacenter**:
   - Switch to geographically closer region
   - Test multiple regions for best performance
   
3. **Adjust Rate Limiting**:
   - Increase delays between requests
   - Process smaller batches

#### Issue: SSL/TLS certificate errors

**Symptoms**:
- "The underlying connection was closed"
- SSL handshake failures
- Certificate validation errors

**Solutions**:
1. **Update PowerShell**:
   ```powershell
   $PSVersionTable.PSVersion
   # Should be 5.1 or higher
   ```

2. **Update .NET Framework**:
   - Install .NET Framework 4.7.2 or later
   - Restart system after installation

3. **Force TLS 1.2**:
   ```powershell
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
   ```

### Application Errors

#### Issue: "Could not load file or assembly" errors

**Symptoms**:
- Application won't start
- Missing DLL errors
- Assembly loading failures

**Solutions**:
1. **Install Prerequisites**:
   - .NET Framework 4.7.2+
   - PowerShell 5.1+
   - Windows Presentation Foundation

2. **Check PowerShell Execution Policy**:
   ```powershell
   Get-ExecutionPolicy
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Repair .NET Installation**:
   - Use Microsoft .NET Framework Repair Tool
   - Reinstall if necessary

#### Issue: GUI doesn't display correctly

**Symptoms**:
- Blank window
- Missing controls
- Layout corruption

**Solutions**:
1. **Check Display Settings**:
   - Ensure normal DPI settings (100-125%)
   - Try compatibility mode if needed

2. **Update Graphics Drivers**:
   - Install latest drivers for GPU
   - Try software rendering if hardware fails

3. **Clear Font Cache**:
   ```cmd
   del /q %windir%\system32\fntcache.dat
   ```

### Voice and Audio Issues

#### Issue: Generated audio is silent or corrupted

**Symptoms**:
- Audio files created but no sound
- Crackling or distorted audio
- Incorrect file format

**Solutions**:
1. **Test Different Format**:
   - Try WAV instead of MP3
   - Use different bit rates
   - Check format compatibility

2. **Verify Text Content**:
   - Ensure text isn't empty
   - Remove special characters
   - Test with simple phrase first

3. **Check Audio Players**:
   - Test files in multiple players
   - Verify system audio is working

#### Issue: "No voices found for datacenter"

**Symptoms**:
- Empty voice dropdown
- Voice selection unavailable
- API connects but no voices

**Solutions**:
1. **Verify Subscription Type**:
   - Ensure Speech service (not just Cognitive Services)
   - Check service availability in region

2. **Test Voice List API**:
   ```powershell
   # Test voice list endpoint manually
   $headers = @{"Authorization"="Bearer $token"}
   Invoke-RestMethod -Uri "https://eastus.tts.speech.microsoft.com/cognitiveservices/voices/list" -Headers $headers
   ```

## 🔍 Diagnostic Steps

### Step 1: Basic System Check

```powershell
# Check PowerShell version
$PSVersionTable

# Check .NET version
Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" -Name Release

# Test internet connectivity
Test-NetConnection -ComputerName "www.google.com" -Port 443
```

### Step 2: Application Log Analysis

Check `application.log` in the application directory:

```powershell
Get-Content .\application.log -Tail 50
```

Common log patterns:
- `[ERROR]` - Critical failures requiring attention
- `[WARNING]` - Non-critical issues that might affect performance
- `[INFO]` - Normal operation messages

### Step 3: Network Diagnostics

```powershell
# Test Azure connectivity
Test-NetConnection -ComputerName "eastus.api.cognitive.microsoft.com" -Port 443

# Test Google Cloud connectivity  
Test-NetConnection -ComputerName "texttospeech.googleapis.com" -Port 443

# Check DNS resolution
Resolve-DnsName "eastus.api.cognitive.microsoft.com"
```

### Step 4: API Validation

Use these commands to test API access directly:

**Azure Test**:
```powershell
$key = "YOUR_API_KEY"
$region = "eastus"
$headers = @{
    "Ocp-Apim-Subscription-Key" = $key
    "Content-Type" = "application/x-www-form-urlencoded"
}
$token = Invoke-RestMethod -Uri "https://$region.api.cognitive.microsoft.com/sts/v1.0/issueToken" -Method POST -Headers $headers
Write-Host "Token received: $($token.Length) characters"
```

**Google Test**:
```powershell
$key = "YOUR_API_KEY"
$headers = @{
    "Authorization" = "Bearer $key"
    "Content-Type" = "application/json"
}
$body = @{
    input = @{ text = "test" }
    voice = @{ languageCode = "en-US" }
    audioConfig = @{ audioEncoding = "MP3" }
} | ConvertTo-Json
$response = Invoke-RestMethod -Uri "https://texttospeech.googleapis.com/v1/text:synthesize" -Method POST -Headers $headers -Body $body
Write-Host "Audio content received: $($response.audioContent.Length) characters"
```

## 📊 Performance Optimisation

### Bulk Processing Optimisation

1. **Batch Size Management**:
   - Process 10-50 items at a time for optimal performance
   - Monitor system memory usage
   - Adjust based on text length

2. **Rate Limiting**:
   - Azure: 20 requests/second (free), 200/second (paid)
   - Google: 300 requests/minute (default quota)
   - Application includes automatic delays

3. **Error Recovery**:
   - Application continues processing after individual failures
   - Failed items are logged for retry
   - Partial results are preserved

### Memory Management

1. **Large CSV Files**:
   - Split files >1000 rows into smaller batches
   - Monitor system memory during processing
   - Close application between large batches

2. **Audio File Cleanup**:
   - Regularly clean temporary files
   - Monitor disk space in output folder
   - Use compression for long-term storage

## 🛠️ Advanced Troubleshooting

### Enable Debug Logging

Add this to the beginning of the script for verbose logging:

```powershell
$DebugPreference = "Continue"
$VerbosePreference = "Continue"
```

### Network Traffic Analysis

Use Fiddler or similar tools to inspect HTTP requests:

1. **Install Fiddler Classic**
2. **Enable HTTPS decryption**
3. **Run application and monitor traffic**
4. **Check request/response details**

### PowerShell Debugging

Run with step-by-step debugging:

```powershell
Set-PSBreakpoint -Script .\TextToSpeech-Generator-v1.1.ps1 -Line 500
.\TextToSpeech-Generator-v1.1.ps1
```

### Registry Investigation

Check Windows audio settings:

```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render\*" -Name FriendlyName
```

## 📞 Getting Help

### Before Requesting Support

1. **Check application logs** (`application.log`)
2. **Verify API credentials** using manual tests
3. **Test with simple input** (single short phrase)
4. **Document error messages** exactly as displayed
5. **Note system configuration** (OS, PowerShell version, .NET version)

### Information to Include

When reporting issues, include:

- **Application version**: Check version displayed in GUI
- **Error message**: Exact text from log window
- **Steps to reproduce**: Detailed sequence of actions
- **System information**: OS version, PowerShell version
- **API provider**: Azure or Google Cloud
- **Sample files**: Anonymized CSV or configuration files
- **Network environment**: Corporate/home, proxy, firewall

### Support Channels

1. **GitHub Issues**: https://github.com/sjackson0109/TextToSpeech-Generator/issues
2. **Documentation**: Check README.md and docs/ folder
3. **Community**: PowerShell community forums for general scripting help
4. **Provider Support**: Azure/Google Cloud support for API-specific issues

### Emergency Workarounds

If application is completely non-functional:

1. **Use PowerShell directly** with API calls
2. **Try online TTS services** temporarily  
3. **Use Windows built-in SAPI** for basic needs:
   ```powershell
   Add-Type -AssemblyName System.Speech
   $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
   $synth.Speak("Hello World")
   ```

---

*Last updated: October 10, 2025*
*For the most current troubleshooting information, check the [GitHub repository](https://github.com/sjackson0109/TextToSpeech-Generator).*
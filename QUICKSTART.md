# Quick Start Guide

Get up and running with TextToSpeech Generator in under 5 minutes!

## ⚡ 5-Minute Setup

### Step 1: Download and Run (30 seconds)
1. Download `TextToSpeech-Generator.ps1`
2. Right-click → "Run with PowerShell" (or open PowerShell and navigate to file)
3. If prompted about execution policy, type `Y` and press Enter

### Step 2: Choose Provider & Get API Key (2 minutes)

#### Azure Cognitive Services ✅ **PRODUCTION READY** (Recommended)
1. Visit [Azure Portal](https://portal.azure.com) (free account available)
2. Create "Microsoft Cognitive Services" resource → "Speech" - [Enrolment Link](https://azure.microsoft.com/en-us/try/cognitive-services/)
3. Copy the API Key (32 characters)
4. Note the Region (e.g., "eastus", "westeurope")
5. **Free Tier**: 500,000 characters/month
6. **Status**: Full implementation with real TTS processing

#### Google Cloud TTS ✅ **PRODUCTION READY** (High Quality)
1. Visit [Google Cloud Console](https://console.cloud.google.com)
2. Enable "Text-to-Speech API"
3. Create API Key in Credentials
4. Copy the key
5. **Free Tier**: 1 million characters/month
6. **Status**: Full implementation with real TTS processing

#### Amazon Polly ⚠️ **PLACEHOLDER ONLY** (Configuration Available)
1. Visit [AWS Console](https://aws.amazon.com/polly/)
2. Create IAM user with Polly permissions
3. Generate Access Key ID and Secret Access Key
4. **Pricing**: $4.00 per 1 million characters
5. **Status**: Creates placeholder files only, needs API implementation

#### Other Providers ⚠️ **CONFIGURATION ONLY**

**Twilio, CloudPronouncer, VoiceForge**: Configuration panels are available, but TTS processing is not yet implemented. These providers can be configured but will not generate audio files until API integration is completed.

### Step 3: Configure App (1 minute)
1. In the app, select your provider (Azure, Amazon Polly, Google Cloud, etc.)
2. Paste your API key (and secret key for AWS)
3. Select region/datacenter (for Azure and AWS)
4. Choose voice and audio format
5. Click "Save Config"

### Step 4: Test Single Script (1 minute)
1. Select "Single Script" mode
2. Type: "Hello world, this is a test"
3. Choose output directory (Desktop recommended)
4. Click "Start Processing" or press F5
5. Listen to your generated audio file!

## 🚀 First Bulk Processing

### Create Test CSV
Create a file called `test.csv`:
```csv
SCRIPT,FILENAME
"Welcome to our service","welcome"
"Thank you for calling","thanks"
"Please hold","hold_message"
```

### Process the CSV
1. Select "Bulk Processing (CSV)" mode
2. Click "Browse..." next to CSV Input File → select your `test.csv`
3. Choose output directory
4. Click "Start Processing" or press F5
5. Watch the processing log for real-time progress!

## 🎯 Tips for Success

### ✅ Do This
- **Start small**: Test with single scripts first
- **Use simple text**: Avoid special characters initially  
- **Check permissions**: Ensure you can write to output folder
- **Monitor logs**: Watch for any error messages
- **Save config**: Use Ctrl+S to save your settings

### ❌ Avoid This
- **Don't use system folders**: Avoid C:\Windows for output
- **Don't skip validation**: Always test your CSV format
- **Don't ignore errors**: Check logs if something fails
- **Don't use very long text**: Keep under 200 characters initially

## 🔧 Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **F5** | Start Processing |
| **Ctrl+R** | Start Processing (alternative) |
| **Ctrl+S** | Save configuration |
| **Ctrl+O** | Open input file |
| **Escape** | Clear log window |

## 🆘 Quick Troubleshooting

### Azure: "Authentication failed"
- ✅ Check API key is correct (no extra spaces)
- ✅ Verify datacenter region matches your subscription
- ✅ Ensure Speech service is enabled (not just Cognitive Services)

### AWS Polly: "Access Denied"
- ✅ Verify both Access Key ID and Secret Access Key
- ✅ Check IAM user has `AmazonPollyFullAccess` permissions
- ✅ Confirm AWS region is correct

### Google Cloud: "Invalid API Key"
- ✅ Ensure Text-to-Speech API is enabled
- ✅ Check API key has proper permissions
- ✅ Verify billing is enabled for your project
- ✅ Ensure internet connection is working

### "CSV validation failed" 
- ✅ Check file has SCRIPT and FILENAME columns (case-sensitive)
- ✅ Ensure no empty rows
- ✅ Use quotes around text with commas

### "No write permissions"
- ✅ Try Desktop or Documents folder instead
- ✅ Run PowerShell as Administrator if needed
- ✅ Check folder isn't read-only

### "No voices found"
- ✅ Wait a moment for voices to load after entering API key
- ✅ Try different datacenter region
- ✅ Check API subscription is active

## 📚 Next Steps

Once you're comfortable with the basics:

1. **Read the full README.md** for comprehensive features
2. **Check docs/API-SETUP.md** for advanced API configuration
3. **Explore docs/CSV-FORMAT.md** for complex CSV formatting
4. **Review docs/TROUBLESHOOTING.md** for detailed problem solving

## 🎵 Sample Voice Scripts

Try these for testing different voice styles:

**Professional Announcements**:
```csv
SCRIPT,FILENAME
"Welcome to TechCorp. Your call is important to us.","corporate_welcome"
"Thank you for your patience. A representative will be with you shortly.","professional_hold"
"Your transaction has been completed successfully.","transaction_success"
```

**Friendly Greetings**:
```csv
SCRIPT,FILENAME
"Hi there! Thanks for calling. How can I help you today?","friendly_greeting"
"Have a wonderful day and thank you for choosing us!","cheerful_goodbye"
"Great news! Your order is ready for pickup.","positive_update"
```

**Emergency Messages**:
```csv
SCRIPT,FILENAME
"Attention: This is an important system announcement.","urgent_attention"
"Please exit the building in an orderly fashion.","evacuation_notice"
"System maintenance in progress. Please try again later.","maintenance_alert"
```

## 🏆 Pro Tips

### Maximize Quality
- **Use punctuation**: Periods and commas create natural pauses
- **Spell out numbers**: "Twenty-five" sounds better than "25"
- **Avoid abbreviations**: "Doctor" instead of "Dr."
- **Test different voices**: Each has unique characteristics

### Boost Productivity  
- **Save templates**: Keep common CSV formats ready
- **Use keyboard shortcuts**: Much faster than clicking
- **Batch similar content**: Group by voice or style
- **Enable secure storage**: No need to re-enter API keys

### Enterprise Usage
- **Monitor quotas**: Check API usage regularly
- **Implement approval workflow**: Review scripts before generation
- **Standardize naming**: Use consistent filename conventions
- **Archive outputs**: Keep organized folders by date/project

---

**🎉 Congratulations!** You're now ready to create professional text-to-speech audio with ease. 

Need help? Check the [full documentation](README.md) or [troubleshooting guide](docs/TROUBLESHOOTING.md)!
# API Setup Guide - Complete Provider Overview

**Updated: October 2025** | **TextToSpeech Generator v2.0**

This guide provides detailed instructions for setting up API access for all TTS providers supported by TextToSpeech Generator v2.0.

## 🎯 **Provider Implementation Status**

| Provider | Status | Implementation | Setup Guide |
|----------|--------|----------------|-------------|
| **Microsoft Azure** | ✅ **PRODUCTION** | Full API integration | [AZURE-SETUP.md](AZURE-SETUP.md) |
| **Google Cloud** | ✅ **PRODUCTION** | Full API integration | [GOOGLE-SETUP.md](GOOGLE-SETUP.md) |
| **Amazon Polly** | ⚠️ **PLACEHOLDER** | Creates dummy files | [AWS-SETUP.md](AWS-SETUP.md) |
| **CloudPronouncer** | ⚠️ **UI ONLY** | Configuration only | [CLOUDPRONOUNCER-SETUP.md](CLOUDPRONOUNCER-SETUP.md) |
| **Twilio** | ⚠️ **UI ONLY** | Configuration only | [TWILIO-SETUP.md](TWILIO-SETUP.md) |
| **VoiceForge** | ⚠️ **UI ONLY** | Configuration only | [VOICEFORGE-SETUP.md](VOICEFORGE-SETUP.md) |

## 🚀 **Quick Start - Production Ready Providers**

For immediate TTS generation, use these fully implemented providers:

## Azure Cognitive Services Text-to-Speech

### Prerequisites
- Azure subscription (free tier available)
- Access to Azure Portal

### Step-by-Step Setup

#### 1. Create Cognitive Services Resource

1. **Login to Azure Portal**: https://portal.azure.com
2. **Create Resource**: 
   - Click "Create a resource"
   - Search for "Cognitive Services"
   - Select "Cognitive Services" (multi-service) or "Speech" (speech-only)
3. **Configure Resource**:
   - **Subscription**: Select your subscription
   - **Resource Group**: Create new or use existing
   - **Region**: Choose closest to your location for better performance
   - **Name**: Unique name for your resource
   - **Pricing Tier**: 
     - **F0 (Free)**: 5,000 transactions/month, limited features
     - **S0 (Standard)**: Pay-per-use, full features

#### 2. Get API Credentials

1. **Navigate to Resource**: Find your created resource
2. **Keys and Endpoint**:
   - Click "Keys and Endpoint" in left menu
   - Copy **Key 1** (32-character hex string)
   - Note the **Location/Region** (e.g., "eastus", "westeurope")

#### 3. Application Configuration

1. **Open TextToSpeech Generator**
2. **Select Azure Provider**: Click "Azure" radio button
3. **Enter Credentials**:
   - **Key**: Paste your API key
   - **Datacenter**: Select matching region from dropdown
4. **Test Connection**: Select a voice to verify connectivity

### Available Regions

| Region Code | Location | Recommended For |
|-------------|----------|-----------------|
| `eastus` | East US | North America East Coast |
| `westus2` | West US 2 | North America West Coast |
| `westeurope` | West Europe | Europe |
| `uksouth` | UK South | United Kingdom |
| `australiaeast` | Australia East | Australia/New Zealand |
| `southeastasia` | Southeast Asia | Asia Pacific |
| `centralindia` | Central India | India |
| `japaneast` | Japan East | Japan |

### Voice Selection

Azure offers 400+ neural voices across 140+ languages:

**Popular English Voices**:
- `en-US-SaraNeural` (Female, American)
- `en-US-GuyNeural` (Male, American)
- `en-GB-SoniaNeural` (Female, British)
- `en-GB-RyanNeural` (Male, British)
- `en-AU-NatashaNeural` (Female, Australian)

### Audio Formats

| Format | Quality | File Size | Use Case |
|--------|---------|-----------|----------|
| `riff-16khz-16bit-mono-pcm` | Highest | Large | PSTN, Professional |
| `audio-16khz-32kbitrate-mono-mp3` | Good | Medium | SIP, General Use |
| `audio-24khz-48kbitrate-mono-mp3` | High | Medium-Large | High Quality Apps |

### Pricing Information

**Free Tier (F0)**:
- 500,000 characters per month (2025 update)
- Neural voices included (limited)
- Rate limited

**Standard Tier (S0)**:
- Pay per use: $15 per 1M characters (Neural), $4 (Standard)
- No monthly limits
- All features available

📖 **[Complete Azure Setup Guide →](AZURE-SETUP.md)**

---

## Google Cloud Text-to-Speech ✅ **PRODUCTION READY**

### Prerequisites
- Google Cloud account
- Credit card for billing (free tier available)

### Step-by-Step Setup

#### 1. Create Google Cloud Project

1. **Visit Console**: https://console.cloud.google.com
2. **Create Project**:
   - Click "Select a project" → "New Project"
   - Enter project name
   - Select organization (if applicable)
   - Click "Create"

#### 2. Enable Text-to-Speech API

1. **Navigate to APIs**: Go to "APIs & Services" → "Library"
2. **Search for API**: Search "Cloud Text-to-Speech API"
3. **Enable API**: Click on the API and press "Enable"

#### 3. Create Service Account

1. **Go to Credentials**: "APIs & Services" → "Credentials"
2. **Create Credentials**: Click "Create Credentials" → "Service Account"
3. **Service Account Details**:
   - **Name**: e.g., "tts-generator-service"
   - **Description**: "TextToSpeech Generator Application"
   - Click "Create and Continue"
4. **Grant Roles**: 
   - Add role: "Cloud Text-to-Speech User"
   - Click "Continue" → "Done"

#### 4. Generate API Key

1. **Find Service Account**: In Credentials, find your service account
2. **Add Key**: Click on service account → "Keys" tab → "Add Key" → "Create new key"
3. **Key Type**: Select "JSON"
4. **Download**: Save the JSON file securely

#### 5. Extract API Key

From the downloaded JSON file, you can use either:
- **Service Account Email + Private Key** (recommended)
- **API Key** (if created separately in Credentials)

For simplicity, create an API Key:
1. **Credentials Page**: Click "Create Credentials" → "API Key"
2. **Copy Key**: Copy the generated key
3. **Restrict Key**: Click "Restrict Key" and limit to Text-to-Speech API

#### 6. Application Configuration

1. **Select Google Provider**: Click "Google" radio button
2. **Enter API Key**: Paste your API key
3. **Select Gender**: Choose Male or Female voice
4. **Test**: Try single script mode first

### Available Voices

**Wavenet Voices (High Quality)**:
- `en-US-Wavenet-A` (Male)
- `en-US-Wavenet-C` (Female)
- `en-US-Wavenet-D` (Male)
- `en-US-Wavenet-F` (Female)

**Standard Voices (Lower Cost)**:
- `en-US-Standard-B` (Male)
- `en-US-Standard-C` (Female)
- `en-US-Standard-D` (Male)

### Pricing Information

**Free Tier**:
- 1 million characters per month (WaveNet)
- 4 million characters per month (Standard)

**Paid Usage**:
- **WaveNet**: $16 per 1M characters
- **Standard**: $4 per 1M characters

---

## Security Best Practices

### API Key Security

1. **Never commit API keys** to version control
2. **Use environment variables** in production
3. **Rotate keys regularly** (monthly recommended)
4. **Restrict key permissions** to minimum required
5. **Monitor usage** for unexpected activity

### Application Security

1. **Enable secure storage** when prompted
2. **Use latest version** of the application
3. **Validate input files** before processing
4. **Run with minimum privileges**

### Network Security

1. **Use HTTPS only** (enforced by application)
2. **Configure firewall** to allow outbound HTTPS (443)
3. **Monitor network traffic** in enterprise environments
4. **Consider proxy settings** if behind corporate firewall

📖 **[Complete Google Cloud Setup Guide →](GOOGLE-SETUP.md)**

---

## ⚠️ **Configuration-Only Providers**

These providers have UI configuration but are not yet fully implemented:

### Amazon Polly ⚠️ **PLACEHOLDER**
- **Status**: Creates placeholder text files, not real audio
- **Configuration**: Complete AWS credentials interface
- **Implementation**: Planned for future release
- 📖 **[AWS Polly Setup Guide →](AWS-SETUP.md)**

### CloudPronouncer ⚠️ **UI ONLY**
- **Status**: Configuration interface only, no TTS processing
- **Use Case**: Specialized pronunciation accuracy
- **Implementation**: Requires community interest
- 📖 **[CloudPronouncer Setup Guide →](CLOUDPRONOUNCER-SETUP.md)**

### Twilio ⚠️ **UI ONLY**
- **Status**: Configuration interface only, no TTS processing
- **Use Case**: Telephony and voice applications
- **Implementation**: Lower priority, planned for 2026
- 📖 **[Twilio Setup Guide →](TWILIO-SETUP.md)**

### VoiceForge ⚠️ **UI ONLY**
- **Status**: Configuration interface only, no TTS processing
- **Use Case**: Professional and custom voices
- **Implementation**: Enterprise demand dependent
- 📖 **[VoiceForge Setup Guide →](VOICEFORGE-SETUP.md)**

---

## 🎯 **Recommended Setup Paths**

### For Immediate Use (Production Ready)
1. **Choose a Provider**: Azure (recommended for beginners) or Google Cloud (advanced features)
2. **Follow Setup Guide**: Complete provider-specific setup
3. **Test Configuration**: Use single script mode first
4. **Scale Up**: Move to bulk processing once comfortable

### For Enterprise Users
1. **Azure Cognitive Services**: Best for Microsoft ecosystem integration
2. **Google Cloud TTS**: Best for Google Cloud Platform integration
3. **Both**: Use both for redundancy and feature comparison

### For Future Planning
1. **Configure All Providers**: Set up UI configurations now
2. **Monitor Development**: Watch for implementation updates
3. **Provide Feedback**: Request features for non-implemented providers

---

## 🔒 Security Best Practices

### API Key Management
1. **Never commit API keys** to version control
2. **Use environment variables** in production
3. **Rotate keys regularly** (monthly recommended)
4. **Restrict key permissions** to minimum required
5. **Monitor usage** for unexpected activity

### Application Security
1. **Enable secure storage** when prompted (Windows Credential Manager)
2. **Use latest version** of TextToSpeech Generator
3. **Validate input files** before processing
4. **Run with minimum privileges**

### Network Security
1. **Use HTTPS only** (enforced by application)
2. **Configure firewall** to allow outbound HTTPS (443)
3. **Monitor network traffic** in enterprise environments
4. **Consider proxy settings** if behind corporate firewall

---

## 🛠️ Troubleshooting Common Issues

### Azure Issues
**401 Unauthorized**: Check API key format and region match
**403 Forbidden**: Verify billing and subscription status
**429 Rate Limited**: Implement delays, upgrade to paid tier

### Google Cloud Issues  
**Authentication Errors**: Ensure API is enabled and billing configured
**Quota Exceeded**: Monitor usage in Cloud Console
**Invalid API Key**: Check key restrictions and permissions

### Application Issues
**"Provider not implemented"**: Use Azure or Google Cloud for working TTS
**Configuration not saving**: Check write permissions, run as administrator
**No voices loading**: Verify API credentials and internet connection

### Network Issues
**Connection Timeouts**: Check internet, DNS, corporate firewall
**SSL/TLS Errors**: Update PowerShell, verify system time
**Proxy Issues**: Configure PowerShell proxy settings

📖 **[Comprehensive Troubleshooting Guide →](TROUBLESHOOTING.md)**

---

## ⚡ Quick Start Checklist

### Production TTS in 5 Minutes
1. ✅ **Choose Provider**: Azure (easiest) or Google Cloud (advanced)
2. ✅ **Create Account**: Follow provider-specific setup guide
3. ✅ **Get API Key**: Copy credentials from provider dashboard  
4. ✅ **Configure App**: Enter credentials in TextToSpeech Generator
5. ✅ **Test**: Try single script mode with "Hello world"
6. ✅ **Scale**: Move to CSV bulk processing for larger datasets

### Enterprise Deployment
1. ✅ **Security Review**: Implement key management and monitoring
2. ✅ **Provider Selection**: Choose based on ecosystem integration
3. ✅ **Redundancy**: Configure multiple providers for failover
4. ✅ **Monitoring**: Set up usage tracking and billing alerts
5. ✅ **Documentation**: Train users on TTS best practices

---

## 📚 Additional Resources

### Provider-Specific Documentation
- **[Azure Cognitive Services](AZURE-SETUP.md)**: Complete Azure TTS setup
- **[Google Cloud TTS](GOOGLE-SETUP.md)**: Complete Google Cloud setup  
- **[AWS Polly](AWS-SETUP.md)**: Placeholder implementation status
- **[CloudPronouncer](CLOUDPRONOUNCER-SETUP.md)**: Configuration-only setup
- **[Twilio](TWILIO-SETUP.md)**: Configuration-only setup
- **[VoiceForge](VOICEFORGE-SETUP.md)**: Configuration-only setup

### Application Documentation
- **[Main README](../README.md)**: Application overview and features
- **[CSV Format Guide](CSV-FORMAT.md)**: Bulk processing file format
- **[Troubleshooting Guide](TROUBLESHOOTING.md)**: Problem solving
- **[Quick Start Guide](../QUICKSTART.md)**: 5-minute setup walkthrough

### Community and Support
- **GitHub Repository**: [TextToSpeech Generator](https://github.com/sjackson0109/TextToSpeech-Generator)
- **Issues and Features**: [GitHub Issues](https://github.com/sjackson0109/TextToSpeech-Generator/issues)
- **Contributions**: [Contributing Guidelines](../CONTRIBUTING.md)

---

**🎯 Ready to start? Choose your provider and begin with the detailed setup guide!**

**Production Ready Now**: [Azure Setup](AZURE-SETUP.md) | [Google Cloud Setup](GOOGLE-SETUP.md)  
**Future Options**: [AWS](AWS-SETUP.md) | [CloudPronouncer](CLOUDPRONOUNCER-SETUP.md) | [Twilio](TWILIO-SETUP.md) | [VoiceForge](VOICEFORGE-SETUP.md)

**Google Test (PowerShell)**:
```powershell
$headers = @{
    "Authorization" = "Bearer YOUR_KEY_HERE"
    "Content-Type" = "application/json"
}
$body = '{"input":{"text":"test"},"voice":{"languageCode":"en-US"},"audioConfig":{"audioEncoding":"MP3"}}'
$uri = "https://texttospeech.googleapis.com/v1/text:synthesize"
Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
```

### Validation Tools

Use the application's built-in validation:
1. Enter API credentials
2. Select datacenter/region
3. Watch log window for connection status
4. Try single script test before bulk processing
# API Setup Guide - Complete Provider Overview

**Updated: October 2025** | **TextToSpeech Generator v3.0**

This guide provides detailed instructions for setting up API access for all TTS providers supported by TextToSpeech Generator v3.0.

## 🎉 **NEW in v3.0 - Complete Provider Implementation**

**Major Update**: All 6 TTS providers are now fully implemented with real API integration!

### What's New
- ✅ **AWS Polly**: Complete implementation with real audio synthesis
- ✅ **CloudPronouncer**: Full API integration for pronunciation accuracy
- ✅ **Twilio**: Complete TwiML generation and telephony integration
- ✅ **VoiceForge**: Full implementation with character and novelty voices
- 🔧 **Enhanced Error Handling**: Provider-specific fallback and recovery
- 📊 **Comprehensive Testing**: All providers validated and operational

### Ready for Production
All 6 providers now support:
- Real-time API calls with actual audio generation
- Complete voice selection and configuration
- Enterprise-grade error handling and recovery
- Full documentation and setup guides

## 🎯 **Provider Implementation Status - All Production Ready**

| Provider | Status | Specialization | Setup Guide |
|----------|--------|----------------|-------------|
| **Azure Cognitive Services** | ✅ **PRODUCTION** | Neural voices, enterprise integration | [AZURE-SETUP.md](AZURE-SETUP.md) |
| **Google Cloud** | ✅ **PRODUCTION** | WaveNet voices, advanced features | [GOOGLE-SETUP.md](GOOGLE-SETUP.md) |
| **Amazon Polly** | ✅ **PRODUCTION** | Neural voices, AWS ecosystem | [AWS-SETUP.md](AWS-SETUP.md) |
| **CloudPronouncer** | ✅ **PRODUCTION** | Pronunciation accuracy, complex terms | [CLOUDPRONOUNCER-SETUP.md](CLOUDPRONOUNCER-SETUP.md) |
| **Twilio** | ✅ **PRODUCTION** | Telephony integration, communication | [TWILIO-SETUP.md](TWILIO-SETUP.md) |
| **VoiceForge** | ✅ **PRODUCTION** | Character voices, creative applications | [VOICEFORGE-SETUP.md](VOICEFORGE-SETUP.md) |

## 💡 **Choose the Right Provider for Your Use Case**

### **Enterprise & General Use**
- **Azure**: Best for Microsoft ecosystem, excellent neural voices, robust free tier
- **Google Cloud**: Advanced WaveNet technology, superior voice quality, GCP integration
- **AWS Polly**: Comprehensive voice selection, strong AWS integration, neural voices

### **Specialized Applications**  
- **CloudPronouncer**: Perfect for medical, legal, or technical content requiring precise pronunciation
- **Twilio**: Ideal for phone systems, IVR, and telephony applications requiring TwiML
- **VoiceForge**: Excellent for gaming, entertainment, and creative projects with character voices

## 🚀 **Quick Start - All Providers Production Ready**

All 6 TTS providers are now fully implemented and ready for immediate use:

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

Azure Cognitive Services Speech is available in 30+ regions worldwide. Here are the most commonly used regions:

| Region Code | Location | Recommended For |
|-------------|----------|-----------------|
| **Americas** | | |
| `eastus` | East US | North America East Coast |
| `eastus2` | East US 2 | North America East Coast (backup) |
| `westus` | West US | North America West Coast |
| `westus2` | West US 2 | North America West Coast (recommended) |
| `westus3` | West US 3 | North America West Coast (latest) |
| `centralus` | Central US | North America Central |
| `southcentralus` | South Central US | North America South Central |
| `northcentralus` | North Central US | North America North Central |
| `canadacentral` | Canada Central | Canada |
| `canadaeast` | Canada East | Canada East |
| `brazilsouth` | Brazil South | South America |
| **Europe** | | |
| `westeurope` | West Europe | Europe (recommended) |
| `northeurope` | North Europe | Northern Europe |
| `uksouth` | UK South | United Kingdom |
| `ukwest` | UK West | United Kingdom West |
| `francecentral` | France Central | France |
| `germanywestcentral` | Germany West Central | Germany |
| `norwayeast` | Norway East | Norway |
| `switzerlandnorth` | Switzerland North | Switzerland |
| `swedencentral` | Sweden Central | Sweden |
| **Asia Pacific** | | |
| `eastasia` | East Asia | Hong Kong |
| `southeastasia` | Southeast Asia | Singapore (recommended) |
| `japaneast` | Japan East | Japan (recommended) |
| `japanwest` | Japan West | Japan West |
| `koreacentral` | Korea Central | South Korea |
| `australiaeast` | Australia East | Australia/New Zealand (recommended) |
| `australiasoutheast` | Australia Southeast | Australia Southeast |
| `centralindia` | Central India | India (recommended) |
| `southindia` | South India | India South |
| `westindia` | West India | India West |

**Note**: Choose the region closest to your users for optimal performance and compliance. Some regions may have different voice availability or pricing.

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
   - Select organisation (if applicable)
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

📖 **[Complete Google Cloud Setup Guide →](GOOGLE-SETUP.md)**

---

## ✅ **All Providers Now Fully Implemented**

All six TTS providers are now fully implemented and production-ready:

### Amazon Polly ✅ **FULLY IMPLEMENTED**
- **Status**: Full production implementation with real API calls
- **Configuration**: Complete AWS credentials interface
- **Features**: Neural and standard voices with AWS Signature V4 authentication
- 📖 **[AWS Polly Setup Guide →](AWS-SETUP.md)**

### CloudPronouncer ✅ **FULLY IMPLEMENTED**
- **Status**: Full production implementation with real API calls
- **Use Case**: Specialized pronunciation accuracy for complex terms
- **Features**: High-quality synthesis, SSML support, multiple audio formats
- 📖 **[CloudPronouncer Setup Guide →](CLOUDPRONOUNCER-SETUP.md)**

### Twilio ✅ **FULLY IMPLEMENTED**
- **Status**: Full production implementation with real API calls
- **Use Case**: Telephony-optimised TTS for communication workflows
- **Features**: TwiML generation, call API integration, multi-language support
- 📖 **[Twilio Setup Guide →](TWILIO-SETUP.md)**

### VoiceForge ✅ **FULLY IMPLEMENTED**
- **Status**: Full production implementation with real API calls
- **Use Case**: Character and novelty voices for creative applications
- **Features**: High-quality synthesis, SSML processing, multiple audio formats
- 📖 **[VoiceForge Setup Guide →](VOICEFORGE-SETUP.md)**

---

## 🎯 **Recommended Setup Paths**

### For Immediate Use (All Providers Production Ready)
1. **Choose a Provider**: All 6 providers are fully operational - select based on your needs
2. **Follow Setup Guide**: Complete provider-specific setup documentation
3. **Test Configuration**: Use single script mode first to verify connectivity
4. **Scale Up**: Move to bulk processing once comfortable with your chosen provider

### For Enterprise Users
1. **Microsoft Ecosystem**: Azure Cognitive Services for Office 365 integration
2. **Google Cloud Platform**: Google Cloud TTS for GCP workflow integration  
3. **AWS Infrastructure**: AWS Polly for existing AWS service integration
4. **Specialized Needs**: CloudPronouncer (accuracy), Twilio (telephony), VoiceForge (creative)
5. **Multi-Provider**: Configure multiple providers for redundancy and feature comparison

### For Advanced Users
1. **Multi-Provider Setup**: Configure multiple providers for redundancy
2. **Performance Optimisation**: Compare voice quality and latency across providers
3. **Cost Management**: Balance features vs. pricing across different providers

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
2. **Use latest version** of TextToSpeech Generator v3.0
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
- **401 Unauthorized**: Check API key format and region match
- **403 Forbidden**: Verify billing and subscription status
- **429 Rate Limited**: Implement delays, upgrade to paid tier

### Google Cloud Issues  
- **Authentication Errors**: Ensure API is enabled and billing configured
- **Quota Exceeded**: Monitor usage in Cloud Console
- **Invalid API Key**: Check key restrictions and permissions

### Application Issues
- **"Provider capabilities verified"**: All 6 providers fully operational
- **Configuration not saving**: Check write permissions, run as administrator
- **No voices loading**: Verify API credentials and internet connection

### Network Issues
- **Connection Timeouts**: Check internet, DNS, corporate firewall
- **SSL/TLS Errors**: Update PowerShell, verify system time
- **Proxy Issues**: Configure PowerShell proxy settings

📖 **[Comprehensive Troubleshooting Guide →](TROUBLESHOOTING.md)**

---

## ⚡ Quick Start Checklist

### Production TTS in 5 Minutes
1. ✅ **Choose Provider**: Any of the 6 providers based on your needs (Azure recommended for beginners)
2. ✅ **Create Account**: Follow provider-specific setup guide from the links above
3. ✅ **Get API Key**: Copy credentials from provider dashboard  
4. ✅ **Configure App**: Enter credentials in TextToSpeech Generator v3.0
5. ✅ **Test**: Try single script mode with "Hello world" to verify functionality
6. ✅ **Scale**: Move to CSV bulk processing for larger datasets

### Enterprise Deployment
1. ✅ **Security Review**: Implement key management and monitoring for all 6 providers
2. ✅ **Provider Selection**: Choose from all 6 production-ready providers based on ecosystem integration
3. ✅ **Redundancy**: Configure multiple providers for failover (all providers now support this)
4. ✅ **Monitoring**: Set up usage tracking and billing alerts across chosen providers
5. ✅ **Testing**: Validate all 6 providers in your environment before production deployment
6. ✅ **Documentation**: Train users on TTS best practices with full provider capabilities

---

## 📚 Additional Resources

### Provider-Specific Documentation
- **[Azure Cognitive Services](AZURE-SETUP.md)**: Complete Azure TTS setup with neural voices
- **[Google Cloud TTS](GOOGLE-SETUP.md)**: Complete Google Cloud setup with WaveNet voices  
- **[AWS Polly](AWS-SETUP.md)**: Full production implementation with neural voices
- **[CloudPronouncer](CLOUDPRONOUNCER-SETUP.md)**: Complete setup for pronunciation accuracy
- **[Twilio](TWILIO-SETUP.md)**: Complete setup for telephony integration
- **[VoiceForge](VOICEFORGE-SETUP.md)**: Complete setup for character voices

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

**All Providers Production Ready**: 
- **Enterprise Grade**: [Azure Setup](AZURE-SETUP.md) | [Google Cloud Setup](GOOGLE-SETUP.md) | [AWS Polly](AWS-SETUP.md)
- **Specialized Features**: [CloudPronouncer](CLOUDPRONOUNCER-SETUP.md) | [Twilio](TWILIO-SETUP.md) | [VoiceForge](VOICEFORGE-SETUP.md)

### Validation Tools

Use the application's built-in validation:
1. Enter API credentials
2. Select datacenter/region
3. Watch log window for connection status
4. Try single script test before bulk processing

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
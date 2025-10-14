# Microsoft Azure Cognitive Services TTS Setup Guide

**Updated: October 2025** | **Status: ✅ PRODUCTION READY**

Complete setup and configuration guide for Azure Cognitive Services Text-to-Speech integration with TextToSpeech Generator v2.0.

![Azure](https://img.shields.io/badge/Azure-Cognitive_Services-blue)
![TTS](https://img.shields.io/badge/TTS-Neural_Voices-green)
![Status](https://img.shields.io/badge/Status-Production_Ready-brightgreen)

## 🔵 Overview

Microsoft Azure Cognitive Services Text-to-Speech delivers industry-leading neural voices with natural prosody and clear articulation. As of October 2025, Azure offers **490+ voices across 140+ languages** with advanced neural capabilities, making it the most comprehensive TTS solution available.

**✅ Full Implementation Status**: This provider is **completely implemented** in TextToSpeech Generator v2.0 with real API calls, SSML support, and enterprise-grade error handling.

### Key Benefits
- **Neural Voice Quality**: Human-like speech with natural intonation
- **Global Reach**: 140+ languages and regional variants  
- **Flexible Pricing**: Free tier available, pay-per-use scaling
- **Enterprise Features**: Custom neural voices, SSML support
- **High Availability**: 99.9% uptime SLA with global datacenters

## 🚀 Getting Started

### Prerequisites
- Azure subscription (free tier available)
- Valid email address for account creation
- Credit card for paid features (optional for free tier)

### Cost Overview (October 2025 Pricing)
| Tier | Monthly Limit | Cost per 1M chars | Neural Voices | Custom Neural | Real-time/Batch |
|------|---------------|-------------------|---------------|---------------|------------------|
| **Free (F0)** | 500,000 characters | Free | ✅ Limited neural | ❌ | Real-time only |
| **Standard (S0)** | Unlimited | $15.00 Neural / $4.00 Standard | ✅ All voices | ✅ Available | Both modes |
| **Premium** | Unlimited | $25.00 Ultra-neural | ✅ Premium quality | ✅ Advanced | Both + priority |

**Note**: Pricing updated as of October 2025. Microsoft has increased neural voice quality and pricing reflects enhanced capabilities.

## 📋 Step-by-Step Setup

### Step 1: Create Azure Account
1. **Visit Azure Portal**: https://portal.azure.com
2. **Sign Up**: Click "Free account" if you don't have one
3. **Provide Information**: Email, phone verification, credit card (for identity verification)
4. **Complete Setup**: Follow the guided setup process

### Step 2: Create Speech Resource

#### Option A: Speech-Only Resource (Recommended)
1. **Navigate to Create Resource**: Portal home → "Create a resource"
2. **Search for Speech**: Type "Speech" in the search box
3. **Select Speech**: Choose "Speech" by Microsoft
4. **Click Create**: Begin configuration

#### Option B: Multi-Service Cognitive Services
1. **Create Resource**: Portal → "Create a resource"
2. **Search Cognitive Services**: Find "Cognitive Services"
3. **Select Multi-Service**: Provides access to all cognitive services
4. **Click Create**: Begin configuration

### Step 3: Configure Resource Settings

Fill out the resource creation form:

#### Basic Settings
- **Subscription**: Select your Azure subscription
- **Resource Group**: 
  - Create new: `tts-resources` (recommended)
  - Or use existing group
- **Region**: Choose based on your location:
  - **East US**: Best for North America East Coast
  - **West Europe**: Best for Europe
  - **Southeast Asia**: Best for Asia Pacific
  - **Australia East**: Best for Australia/New Zealand

#### Resource Details
- **Name**: Unique name (e.g., `my-company-tts-service`)
- **Pricing Tier**: 
  - **F0 (Free)**: 5,000 transactions/month, standard voices only
  - **S0 (Standard)**: Pay-per-use, all features

#### Network and Tags (Optional)
- **Network**: Leave default (All networks) for simplicity
- **Tags**: Add for organization (optional)

Click **Review + Create** → **Create**

### Step 4: Get API Credentials

After deployment completes:

1. **Go to Resource**: Click "Go to resource"
2. **Keys and Endpoint**: Click in left navigation menu
3. **Copy Credentials**:
   - **Key 1**: 32-character hexadecimal string (keep secure!)
   - **Location/Region**: Note the region code (e.g., "eastus")
   - **Endpoint**: The base URL for API calls

#### Security Best Practices
- **Key Security**: Never share or commit keys to code repositories
- **Key Rotation**: Regenerate keys monthly for production use
- **Least Privilege**: Use resource-specific keys, not subscription-wide keys
- **Monitor Usage**: Set up billing alerts to track consumption

## ⚙️ Application Configuration

### Initial Setup in TextToSpeech Generator

1. **Launch Application**: Run `TextToSpeech-Generator-v1.1.ps1`
2. **Select Azure Provider**: Click "Azure" radio button
3. **Enter API Key**: Paste your 32-character key
4. **Select Datacenter**: Choose matching region from dropdown
5. **Test Connection**: Click in the datacenter field to validate

### Voice Selection

The application will automatically load available voices. Popular options:

#### English (US) - Professional (2025 Voices)
- `en-US-AvaNeural` - Modern female voice, professional and warm
- `en-US-AndrewNeural` - Modern male voice, confident and clear  
- `en-US-AriaNeural` - Expressive female voice, natural conversation
- `en-US-BrianNeural` - Mature male voice, authoritative tone
- `en-US-ChristopherNeural` - Young male voice, friendly and energetic
- `en-US-EmmaNeural` - Young female voice, cheerful and engaging
- `en-US-JennyNeural` - Versatile female voice, widely used
- `en-US-GuyNeural` - Clear male voice, professional standard

#### English (UK) - British Accent (2025 Update)
- `en-GB-SoniaNeural` - Professional British female, RP accent
- `en-GB-RyanNeural` - Professional British male, RP accent
- `en-GB-LibbyNeural` - Modern British female, friendly tone
- `en-GB-MaisieNeural` - Young British female, contemporary accent
- `en-GB-ThomasNeural` - Young British male, modern pronunciation

#### Multi-Language Support
- `fr-FR-DeniseNeural` - French female
- `de-DE-KatjaNeural` - German female  
- `es-ES-ElviraNeural` - Spanish female
- `it-IT-ElsaNeural` - Italian female

### Audio Format Selection

Choose based on your use case:

#### High Quality (Recommended)
- **`riff-24khz-16bit-mono-pcm`** - Highest quality WAV
- **`audio-24khz-48kbitrate-mono-mp3`** - High quality MP3

#### Standard Quality
- **`riff-16khz-16bit-mono-pcm`** - Standard WAV (PSTN compatible)
- **`audio-16khz-32kbitrate-mono-mp3`** - Standard MP3 (SIP compatible)

#### Bandwidth Optimized
- **`audio-16khz-64kbitrate-mono-mp3`** - Balanced quality/size
- **`raw-16khz-16bit-mono-pcm`** - Uncompressed for processing

## 🔧 Advanced Configuration

### Custom Neural Voices

For enterprise customers, Azure offers custom neural voice creation:

1. **Requirements**: Minimum 300 sentences of training data
2. **Cost**: $2,400 setup fee + hosting costs
3. **Timeline**: 4-6 weeks development
4. **Use Cases**: Brand-specific voices, celebrity voices, multilingual consistency

Contact Microsoft for custom voice development.

### SSML Support

Azure supports Speech Synthesis Markup Language for advanced control:

```xml
<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="en-US">
    <voice name="en-US-SaraNeural">
        <prosody rate="slow" pitch="low">
            This text will be spoken slowly with a lower pitch.
        </prosody>
        <break time="500ms"/>
        <emphasis level="strong">This text is emphasized.</emphasis>
    </voice>
</speak>
```

### Regional Datacenters (October 2025)

| Region Code | Location | Latency (US East) | Neural Voices | Best For |
|-------------|----------|-------------------|---------------|----------|
| `eastus` | Virginia, US | ~15ms | ✅ Full Support | US East Coast |
| `eastus2` | Virginia, US | ~20ms | ✅ Full Support | US East Coast (backup) |
| `westus2` | Washington, US | ~60ms | ✅ Full Support | US West Coast |
| `westus3` | Phoenix, US | ~65ms | ✅ Full Support | US Southwest |
| `centralus` | Iowa, US | ~35ms | ✅ Full Support | US Central |
| `southcentralus` | Texas, US | ~40ms | ✅ Full Support | US South |
| `westeurope` | Netherlands | ~100ms | ✅ Full Support | Europe West |
| `northeurope` | Ireland | ~110ms | ✅ Full Support | Europe North |
| `uksouth` | London, UK | ~105ms | ✅ Full Support | United Kingdom |
| `francecentral` | Paris, France | ~115ms | ✅ Full Support | France |
| `germanywelcentral` | Frankfurt, Germany | ~120ms | ✅ Full Support | Germany |
| `southeastasia` | Singapore | ~170ms | ✅ Full Support | Asia Pacific |
| `eastasia` | Hong Kong | ~180ms | ✅ Full Support | East Asia |
| `japaneast` | Tokyo, Japan | ~160ms | ✅ Full Support | Japan |
| `australiaeast` | Sydney, Australia | ~190ms | ✅ Full Support | Australia/NZ |
| `canadacentral` | Toronto, Canada | ~25ms | ✅ Full Support | Canada |
| `brazilsouth` | São Paulo, Brazil | ~150ms | ✅ Full Support | South America |

Choose the closest region for optimal performance. All regions support the full range of neural voices as of October 2025.

Choose the closest region for best performance.

## 📊 Usage Monitoring

### Azure Portal Monitoring

1. **Resource Overview**: View usage statistics
2. **Metrics**: 
   - Total Calls
   - Data In/Out
   - Latency
   - Error Rate
3. **Alerts**: Set up notifications for quota limits
4. **Cost Management**: Track spending and set budgets

### Application Logging

The TextToSpeech Generator logs all API interactions:

```
2025-10-10 14:30:15 [INFO] Azure token obtained successfully
2025-10-10 14:30:16 [INFO] Loaded 187 voices from eastus datacenter
2025-10-10 14:30:45 [INFO] Generated: welcome_message (en-US-SaraNeural)
2025-10-10 14:30:47 [ERROR] Rate limit exceeded, retrying in 1 second
```

## 🚨 Troubleshooting Azure-Specific Issues

### Authentication Errors

#### "Invalid subscription key" (401 Error)
**Causes**:
- Incorrect API key
- Key for wrong service type
- Expired or deactivated key

**Solutions**:
1. Verify key in Azure Portal → Resource → Keys and Endpoint
2. Ensure you're using Key1 or Key2 (not endpoint URL)
3. Check service isn't suspended due to billing issues

#### "Access denied" (403 Error)
**Causes**:
- Insufficient quota
- Billing issues
- Service disabled

**Solutions**:
1. Check quota in Azure Portal
2. Verify billing information is current
3. Confirm service tier supports requested features

### Regional Issues

#### "Region mismatch" errors
**Cause**: API key region doesn't match selected datacenter

**Solution**: Ensure datacenter selection matches resource location:
```powershell
# Check resource location in PowerShell
Get-AzCognitiveServicesAccount -ResourceGroupName "your-rg" -Name "your-resource"
```

#### High latency or timeouts
**Solutions**:
1. Switch to closer datacenter
2. Check internet connection stability
3. Contact Azure support if persistent

### Voice Loading Issues

#### "No voices available"
**Causes**:
- Network connectivity issues
- Invalid authentication
- Service outage

**Diagnostic Steps**:
1. Test manual API call:
```powershell
$headers = @{"Authorization"="Bearer $token"}
$uri = "https://eastus.tts.speech.microsoft.com/cognitiveservices/voices/list"
Invoke-RestMethod -Uri $uri -Headers $headers
```

2. Check Azure Service Health dashboard
3. Try different datacenter region

## 💡 Best Practices

### Production Deployment

1. **Use Standard Tier**: Free tier has limitations unsuitable for production
2. **Implement Retry Logic**: Handle transient failures gracefully  
3. **Cache Tokens**: Tokens are valid for 10 minutes, reuse when possible
4. **Monitor Quotas**: Set up alerts before hitting limits
5. **Multiple Keys**: Use key rotation for zero-downtime updates

### Performance Optimization

1. **Batch Requests**: Group multiple TTS requests when possible
2. **Regional Deployment**: Use multiple regions for global applications
3. **Caching**: Cache generated audio for repeated content
4. **Connection Pooling**: Reuse HTTP connections for multiple requests

### Security Considerations

1. **Key Management**: Use Azure Key Vault in production
2. **Network Security**: Implement firewall rules and VPN access
3. **Audit Logging**: Enable diagnostic logging for compliance
4. **Data Residency**: Consider region for data sovereignty requirements

## 📞 Support and Resources

### Microsoft Support
- **Azure Portal**: Built-in support ticket system
- **Documentation**: https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/
- **Pricing Calculator**: https://azure.microsoft.com/en-us/pricing/calculator/
- **Service Health**: https://status.azure.com/

### Community Resources
- **Stack Overflow**: Tag questions with `azure-cognitive-services`
- **GitHub Samples**: https://github.com/Azure-Samples/cognitive-services-speech-sdk
- **Developer Forums**: https://docs.microsoft.com/en-us/answers/topics/azure-cognitive-services.html

### Application Support
- **TextToSpeech Generator Issues**: https://github.com/sjackson0109/TextToSpeech-Generator/issues
- **Documentation**: See `docs/TROUBLESHOOTING.md` for common problems

---

**Next Steps**: After setting up Azure, refer to the main [README.md](../README.md) for application usage instructions or [CSV-FORMAT.md](CSV-FORMAT.md) for bulk processing guidance.
# Google Cloud Text-to-Speech Setup Guide

**Updated: October 2025** | **Status: ✅ PRODUCTION READY**

Complete setup and configuration guide for Google Cloud Text-to-Speech integration with TextToSpeech Generator v2.0.

![Google Cloud](https://img.shields.io/badge/Google_Cloud-Text_to_Speech-4285F4)
![TTS](https://img.shields.io/badge/TTS-WaveNet_Voices-orange)
![Status](https://img.shields.io/badge/Status-Production_Ready-brightgreen)

## 🟡 Overview

Google Cloud Text-to-Speech delivers natural-sounding speech using breakthrough research in WaveNet and Neural2 technology. As of October 2025, Google offers **380+ voices across 50+ languages** with advanced neural capabilities and real-time synthesis.

**✅ Full Implementation Status**: This provider is **completely implemented** in TextToSpeech Generator v2.0 with real JSON API calls, advanced voice options, and comprehensive error handling.

### Key Benefits
- **WaveNet Technology**: DeepMind's breakthrough neural network for natural speech
- **High Fidelity**: 24kHz audio quality with human-like prosody
- **Competitive Pricing**: Generous free tier, cost-effective scaling
- **Advanced Features**: SSML support, custom voice models, audio effects
- **Global Infrastructure**: Low-latency access worldwide

## 🚀 Getting Started

### Prerequisites
- Google account (Gmail or Google Workspace)
- Credit card for billing verification (required even for free tier)
- Basic understanding of Google Cloud Console

### Cost Overview (October 2025 Pricing)
| Voice Type | Monthly Free Tier | Paid Rate (per 1M chars) | Quality | Real-time |
|------------|-------------------|-------------------------|---------|-----------|
| **Standard** | 4 million characters | $4.00 | Good quality | ✅ Yes |
| **WaveNet** | 1 million characters | $16.00 | Premium quality | ✅ Yes |
| **Neural2** | 1 million characters | $20.00 | Latest premium | ✅ Yes |
| **Studio** | 100,000 characters | $160.00 | Ultra-high quality | ✅ Yes |
| **Journey** | 50,000 characters | $320.00 | Conversational AI | ✅ Yes |

**Note**: Pricing updated as of October 2025. Google has introduced Journey voices for conversational AI and enhanced Neural2 capabilities.

## 📋 Step-by-Step Setup

### Step 1: Create Google Cloud Account

1. **Visit Google Cloud Console**: https://console.cloud.google.com
2. **Sign In**: Use existing Google account or create new one
3. **Accept Terms**: Review and accept Google Cloud Terms of Service
4. **Billing Setup**: Add payment method (required for verification, free tier available)
5. **Complete Profile**: Provide business information if applicable

### Step 2: Create New Project

1. **Project Selector**: Click project dropdown in top navigation
2. **New Project**: Click "NEW PROJECT"
3. **Project Details**:
   - **Project Name**: e.g., "TTS Generator Project"
   - **Organisation**: Select if applicable
   - **Location**: Choose organisation or "No organisation"
4. **Create**: Click "CREATE" button
5. **Wait for Creation**: Project setup takes 30-60 seconds

### Step 3: Enable Text-to-Speech API

1. **Navigation Menu**: Click hamburger menu (☰)
2. **APIs & Services**: Select "APIs & Services" → "Library"
3. **Search API**: Type "Cloud Text-to-Speech API"
4. **Select API**: Click on "Cloud Text-to-Speech API"
5. **Enable**: Click "ENABLE" button
6. **Wait for Activation**: API enablement takes 1-2 minutes

### Step 4: Set Up Billing (Required)

Even for free tier usage, billing must be configured:

1. **Billing Menu**: Navigation → "Billing"
2. **Link Account**: If not already linked, link billing account
3. **Set Budget Alerts**:
   - Go to "Budgets & alerts"
   - Create budget: $10-20 recommended for testing
   - Set alert thresholds: 50%, 90%, 100%

### Step 5: Create Service Account (Recommended Method)

#### Option A: Service Account with JSON Key (Most Secure)

1. **IAM & Admin**: Navigation → "IAM & Admin" → "Service accounts"
2. **Create Service Account**:
   - **Name**: `tts-generator-service`
   - **Description**: "TextToSpeech Generator Application"
   - Click "CREATE AND CONTINUE"
3. **Grant Roles**:
   - Add role: "Cloud Text-to-Speech User"
   - Click "CONTINUE" → "DONE"
4. **Create Key**:
   - Click on created service account
   - Go to "Keys" tab
   - "ADD KEY" → "Create new key"
   - Select "JSON" → "CREATE"
5. **Download Key**: Save JSON file securely (never commit to code!)

#### Option B: API Key (Simpler but Less Secure)

1. **Credentials**: "APIs & Services" → "Credentials"
2. **Create Credentials**: Click "CREATE CREDENTIALS" → "API key"
3. **Copy Key**: Copy the generated API key immediately
4. **Restrict Key** (Important):
   - Click "RESTRICT KEY"
   - **Application restrictions**: None (or IP if applicable)
   - **API restrictions**: Select "Cloud Text-to-Speech API"
   - **Save**: Click "SAVE"

### Step 6: Test API Access

#### Test with Service Account JSON
```bash
# Set environment variable (replace path)
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/service-account.json"

# Test API call
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "input":{"text":"Hello, world!"},
    "voice":{"languageCode":"en-US","name":"en-US-Wavenet-D"},
    "audioConfig":{"audioEncoding":"MP3"}
  }' \
  "https://texttospeech.googleapis.com/v1/text:synthesize"
```

#### Test with API Key
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "input":{"text":"Hello, world!"},
    "voice":{"languageCode":"en-US","name":"en-US-Wavenet-D"},
    "audioConfig":{"audioEncoding":"MP3"}
  }' \
  "https://texttospeech.googleapis.com/v1/text:synthesize?key=YOUR_API_KEY"
```

## ⚙️ Application Configuration

### Setup in TextToSpeech Generator

1. **Launch Application**: Run `TextToSpeech-Generator-v1.1.ps1`
2. **Select Google Provider**: Click "Google" radio button
3. **Enter Credentials**:
   - **API Key Method**: Paste your API key
   - **Service Account**: Use the key from JSON file
4. **Select Voice Gender**: Choose Male or Female
5. **Test Connection**: Try single script mode first

### Voice Selection

Google Cloud offers several voice categories:

#### WaveNet Voices (Premium Quality)
**English (US)**:
- `en-US-Wavenet-A` - Male, professional
- `en-US-Wavenet-C` - Female, professional  
- `en-US-Wavenet-D` - Male, friendly
- `en-US-Wavenet-F` - Female, friendly
- `en-US-Wavenet-G` - Female, young adult
- `en-US-Wavenet-H` - Female, young adult
- `en-US-Wavenet-I` - Male, young adult
- `en-US-Wavenet-J` - Male, young adult

**English (UK)**:
- `en-GB-Wavenet-A` - Female, British
- `en-GB-Wavenet-B` - Male, British
- `en-GB-Wavenet-C` - Female, British
- `en-GB-Wavenet-D` - Male, British

#### Neural2 Voices (2025 Latest Technology)
- `en-US-Neural2-A` - Male, conversational quality
- `en-US-Neural2-C` - Female, professional quality  
- `en-US-Neural2-D` - Male, expressive quality
- `en-US-Neural2-F` - Female, warm quality
- `en-US-Neural2-G` - Female, young adult quality
- `en-US-Neural2-H` - Female, mature quality
- `en-US-Neural2-I` - Male, young adult quality
- `en-US-Neural2-J` - Male, mature quality

#### Journey Voices (2025 Conversational AI)
- `en-US-Journey-D` - Male, conversational AI optimized
- `en-US-Journey-F` - Female, conversational AI optimized
- `en-US-Journey-O` - Gender-neutral, inclusive design

#### Standard Voices (Cost-Effective)
- `en-US-Standard-A` - Male, good quality
- `en-US-Standard-C` - Female, good quality
- `en-US-Standard-D` - Male, good quality
- `en-US-Standard-E` - Female, good quality

### Audio Configuration

The application automatically uses these optimal settings:

```json
{
  "audioConfig": {
    "audioEncoding": "MP3",
    "speakingRate": 1.0,
    "pitch": 0.0,
    "volumeGainDb": 0.0,
    "sampleRateHertz": 24000,
    "effectsProfileId": ["small-bluetooth-speaker-class-device"]
  }
}
```

#### Available Audio Formats
- **MP3**: Default, good compression and quality
- **LINEAR16**: Uncompressed PCM for highest quality
- **OGG_OPUS**: Efficient compression for streaming
- **MULAW**: Telephony standard (8kHz)
- **ALAW**: Alternative telephony standard

## 🔧 Advanced Configuration

### Custom Voice Models

Google offers Custom Voice for enterprise customers:

1. **Requirements**: 
   - Minimum 3,000 utterances for training
   - Professional recording environment
   - 6-10 hours of audio data
2. **Process**: 
   - Data preparation and validation
   - Model training (2-4 weeks)
   - Quality assurance testing
3. **Pricing**: Contact Google Cloud sales for pricing

### SSML Support

Google Cloud supports extensive SSML features:

```xml
<speak>
  <voice name="en-US-Wavenet-D">
    <prosody rate="slow" pitch="-2st">
      Can you hear me now?
    </prosody>
  </voice>
  <break time="1s"/>
  <voice name="en-US-Wavenet-C">
    <emphasis level="strong">Yes!</emphasis> I can hear you perfectly.
  </voice>
</speak>
```

#### SSML Features Supported
- **Voice selection**: Multiple voices in single request
- **Prosody control**: Rate, pitch, volume adjustment
- **Emphasis**: Strong, moderate, reduced emphasis
- **Breaks**: Timed pauses and sentence breaks
- **Say-as**: Number formatting, date/time pronunciation
- **Audio effects**: Telephony, small speaker optimisation

### Audio Effects Profiles

Optimise audio for different playback environments:

| Profile ID | Description | Use Case |
|------------|-------------|----------|
| `wearable-class-device` | Smartwatch/earbuds | Personal devices |
| `handset-class-device` | Phone speakers | Mobile apps |
| `headphone-class-device` | Headphones/earphones | Personal listening |
| `small-bluetooth-speaker-class-device` | Small speakers | Desktop/laptop |
| `medium-bluetooth-speaker-class-device` | Medium speakers | Home/office |
| `large-home-entertainment-class-device` | Large speakers | Home theatre |
| `large-automotive-class-device` | Car speakers | Automotive |
| `telephony-class-application` | Phone calls | VoIP/telephony |

## 📊 Usage Monitoring and Quotas

### Google Cloud Console Monitoring

1. **APIs & Services**: Navigate to "APIs & Services" → "Dashboard"
2. **Text-to-Speech API**: Click on the API for detailed metrics
3. **Quotas**: Monitor current usage against limits:
   - **Requests per minute**: 300 (default)
   - **Requests per day**: No limit (pay-per-use)
   - **Characters per request**: 5,000 maximum

#### Set Up Alerts

1. **Monitoring**: Navigation → "Monitoring"
2. **Alerting**: Create alert policies for:
   - API quota usage (80%, 90% thresholds)
   - Error rate increases
   - Billing budget thresholds
3. **Notification Channels**: Email, SMS, or Slack integration

### Application Monitoring

The TextToSpeech Generator provides detailed logging:

```
2025-10-10 14:30:15 [INFO] Google Cloud TTS request initiated
2025-10-10 14:30:16 [INFO] Voice: en-US-Wavenet-C, Characters: 156
2025-10-10 14:30:17 [INFO] Audio generated successfully, size: 47KB
2025-10-10 14:30:18 [WARNING] Approaching rate limit, adding delay
```

## 🚨 Troubleshooting Google Cloud Issues

### Authentication Errors

#### "Invalid API Key" (401 Error)
**Solutions**:
1. Verify API key in Google Cloud Console → Credentials
2. Check API restrictions include Text-to-Speech API
3. Ensure API key hasn't been regenerated

#### "Permission Denied" (403 Error)
**Causes**:
- API not enabled
- Insufficient IAM permissions
- Billing not set up

**Solutions**:
1. Re-enable Text-to-Speech API
2. Check service account has "Cloud Text-to-Speech User" role
3. Verify billing account is linked and valid

### Quota and Rate Limiting

#### "Quota Exceeded" (429 Error)
**Solutions**:
1. Check quota usage in Cloud Console
2. Request quota increase if needed
3. Implement exponential backoff in requests

#### Rate Limiting Best Practices
```javascript
// Example retry logic
const maxRetries = 3;
const baseDelay = 1000; // 1 second

for (let attempt = 0; attempt < maxRetries; attempt++) {
  try {
    // Make API request
    break;
  } catch (error) {
    if (error.status === 429 && attempt < maxRetries - 1) {
      const delay = baseDelay * Math.pow(2, attempt);
      await new Promise(resolve => setTimeout(resolve, delay));
    } else {
      throw error;
    }
  }
}
```

### Voice and Audio Issues

#### "Voice not found" errors
**Solution**: Use exact voice names from Google's voice list:
```bash
curl -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://texttospeech.googleapis.com/v1/voices"
```

#### Poor audio quality
**Solutions**:
1. Use WaveNet or Neural2 voices for best quality
2. Adjust audio effects profile for playback environment
3. Increase sample rate in audio config

## 💡 Best Practices

### Production Deployment

1. **Use Service Accounts**: More secure than API keys
2. **Implement Caching**: Cache generated audio to reduce API calls  
3. **Error Handling**: Implement robust retry logic with exponential backoff
4. **Monitoring**: Set up comprehensive alerting and logging
5. **Security**: Use IAM roles with minimal required permissions

### Performance Optimisation

1. **Batch Processing**: Group requests when possible to minimise latency
2. **Regional Deployment**: Google Cloud is global, but consider data residency
3. **Connection Reuse**: Maintain HTTP connection pools for efficiency
4. **Async Processing**: Use asynchronous requests for bulk operations

### Cost Optimisation

1. **Voice Selection**: Use Standard voices for non-critical applications
2. **Text Optimisation**: Remove unnecessary characters before synthesis
3. **Caching Strategy**: Implement intelligent caching to avoid duplicate generation
4. **Budget Alerts**: Set up proactive budget monitoring

### Security Best Practices

1. **Key Management**: 
   - Use Google Secret Manager for production
   - Rotate keys regularly
   - Never commit keys to version control
2. **Access Control**: 
   - Use principle of least privilege
   - Implement IP restrictions where possible
   - Monitor access logs regularly
3. **Network Security**:
   - Use VPC service controls for enterprise
   - Implement proper firewall rules
   - Consider private Google access

## 📞 Support and Resources

### Google Cloud Support
- **Console Help**: Built-in help chat in Cloud Console
- **Documentation**: https://cloud.google.com/text-to-speech/docs
- **Pricing**: https://cloud.google.com/text-to-speech/pricing
- **Status Page**: https://status.cloud.google.com/

### Developer Resources
- **Code Samples**: https://github.com/googleapis/nodejs-text-to-speech
- **Client Libraries**: Available in 10+ programming languages
- **Community Support**: Stack Overflow with `google-cloud-text-to-speech` tag
- **YouTube Channel**: Google Cloud Tech for tutorials and updates

### Application Support
- **TextToSpeech Generator**: https://github.com/sjackson0109/TextToSpeech-Generator/issues
- **General Troubleshooting**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## 🔗 Integration Examples

### PowerShell Example (Advanced)
```powershell
# Advanced Google Cloud TTS with SSML
$apiKey = "YOUR_API_KEY"
$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type" = "application/json"
}

$ssmlText = @"
<speak>
  <voice name="en-US-Wavenet-D">
    <prosody rate="medium" pitch="0st">
      Welcome to our service.
    </prosody>
    <break time="500ms"/>
    <emphasis level="strong">
      How can we help you today?
    </emphasis>
  </voice>
</speak>
"@

$body = @{
    input = @{
        ssml = $ssmlText
    }
    voice = @{
        languageCode = "en-US"
        name = "en-US-Wavenet-D"
    }
    audioConfig = @{
        audioEncoding = "MP3"
        speakingRate = 1.0
        pitch = 0.0
        volumeGainDb = 0.0
        effectsProfileId = @("small-bluetooth-speaker-class-device")
    }
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod -Uri "https://texttospeech.googleapis.com/v1/text:synthesize" -Method POST -Headers $headers -Body $body

# Decode and save audio
$audioBytes = [System.Convert]::FromBase64String($response.audioContent)
[System.IO.File]::WriteAllBytes("output.mp3", $audioBytes)
```

---

**Next Steps**: After setting up Google Cloud TTS, return to the main [README.md](../README.md) for application usage instructions or check [CSV-FORMAT.md](CSV-FORMAT.md) for bulk processing guidance.
# API Setup Guide

This guide provides detailed instructions for setting up API access for supported Text-to-Speech providers.

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
- 5,000 transactions per month
- Standard voices only
- Rate limited

**Standard Tier (S0)**:
- Pay per use: $4 per 1M characters (Neural voices)
- No monthly limits
- All features available

---

## Google Cloud Text-to-Speech

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

---

## Troubleshooting API Issues

### Common Azure Issues

**401 Unauthorized**:
- Check API key is correct (32 hex characters)
- Verify key isn't expired
- Ensure datacenter region matches subscription

**403 Forbidden**:
- Check subscription has available quota
- Verify service isn't suspended
- Confirm billing information is current

**429 Rate Limited**:
- Reduce request frequency
- Upgrade to paid tier
- Implement proper delays between requests

### Common Google Cloud Issues

**Authentication Errors**:
- Verify API key format
- Check Text-to-Speech API is enabled
- Confirm billing is enabled on project

**Quota Exceeded**:
- Check usage in Cloud Console
- Upgrade quotas if needed
- Monitor monthly usage

### Network Issues

**Connection Timeouts**:
- Check internet connectivity
- Verify DNS resolution
- Test with different datacenter/region
- Check corporate firewall settings

**SSL/TLS Errors**:
- Update PowerShell to latest version
- Check system date/time is correct
- Verify certificate store is updated

---

## API Testing

### Quick Test Commands

**Azure Test (PowerShell)**:
```powershell
$headers = @{
    "Ocp-Apim-Subscription-Key" = "YOUR_KEY_HERE"
    "Content-Type" = "application/x-www-form-urlencoded"
}
$uri = "https://YOUR_REGION.api.cognitive.microsoft.com/sts/v1.0/issueToken"
Invoke-RestMethod -Uri $uri -Method POST -Headers $headers
```

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
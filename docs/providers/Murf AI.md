# Murf AI TTS Provider Setup Guide

## Overview
Murf AI is a leading AI voice synthesis platform offering ultra-fast, high-quality text-to-speech with 150+ voices across 35+ languages. Features include Gen2 for content generation and Falcon for real-time voice agents.

## Features
- **Premium Voice Quality**: State-of-the-art Gen2 and Falcon models with natural-sounding prosody
- **Multilingual Support**: 35+ languages with MultiNative technology for authentic multilingual content
- **Extensive Voice Library**: 150+ voices across genders, ages, and accents
- **Multiple Models**: Gen2 for studio-quality content, Falcon for ultra-low latency (<130ms)
- **Speaking Styles**: 20+ styles including Conversational, Promo, Newscast, Storytelling, Calm, and more
- **Advanced Customization**: Control pitch, speed, emphasis, pauses, and pronunciation

## Prerequisites
- Murf AI account (free trial available)
- Valid API key from Murf AI API Dashboard

## Setup Instructions

### 1. Create Murf AI Account
1. Visit [https://murf.ai/](https://murf.ai/)
2. Click **Sign Up** in the top-right corner
3. Create account using:
   - Email and password
   - Google authentication
   - Other authentication methods
4. Verify your email address if prompted

### 2. Get Your API Key
1. Log in to your Murf AI account
2. Navigate to [https://murf.ai/api/dashboard](https://murf.ai/api/dashboard)
3. Click **Generate API Key**
4. Copy the generated API key
5. **Important**: Store your API key securely - treat it as a password

### 3. Configure in TextToSpeech-Generator
1. Launch the TextToSpeech-Generator application
2. Select **Murf AI** from the TTS Provider dropdown
3. Click the **Configure** button
4. Paste your API key in the **API Key** field
5. Click **Test Connection** to verify credentials
6. Click **Save & Close** to complete setup

## Pricing & Limits

### Free Trial
- Available for new accounts
- Limited character quota for testing
- Access to all voices and features

### Paid Plans
- **Starter**: For individuals and small teams
- **Pro**: For content creators and businesses
- **Enterprise**: Custom pricing for high-volume use

Visit [https://murf.ai/pricing](https://murf.ai/pricing) for current pricing.

## Available Voices

### Voice Samples
Murf AI offers 150+ voices including:
- **Natalie** (Female, US): Natural, warm voice for general content
- **Ken** (Male, US): Professional, authoritative voice
- **Terrell** (Male, US): Deep, engaging voice
- **Julia** (Female, US): Clear, conversational voice
- **Matthew** (Male, UK): British accent, professional tone
- **And many more across 35+ languages**

### Voice Models
- **Gen2**: Advanced model for studio-quality content generation, trained on 70,000+ hours of audio
- **Falcon**: Ultra-fast model for real-time voice agents with <130ms latency

### Speaking Styles
- Conversational
- Promo
- Newscast
- Storytelling
- Calm
- Furious
- Angry
- Sobbing
- Sad
- And more (voice-specific)

## Configuration Options

### Basic Settings
- **API Key**: Your Murf AI API key (required)
- **Voice**: Select from 150+ available voices
- **Language/Locale**: 35+ supported languages and regional variants
- **Format**: WAV, MP3, FLAC, PCM, OGG

### Advanced Settings
- **Model**: Gen2 (default) or Falcon for ultra-low latency
- **Speaking Style**: Choose from 20+ voice-specific styles
- **Pitch**: Adjust voice pitch (-50 to +50)
- **Speed/Rate**: Control speaking speed (-50 to +50)
- **Sample Rate**: 8000, 24000, 44100, or 48000 Hz
- **Channel Type**: MONO or STEREO
- **Variation**: Add natural variation in pause, pitch, and speed (0-5)

### MultiNative Feature
Enable voices to speak in multiple languages while maintaining authentic pronunciation patterns for each language.

## Supported Output Formats

| Format | Description | Use Case |
|--------|-------------|----------|
| **WAV** | Uncompressed audio (default) | Low-latency applications |
| **MP3** | Compressed, widely supported | General use, file size matters |
| **FLAC** | Lossless compression | High fidelity, smaller than WAV |
| **PCM** | Raw uncompressed audio | Telephony, DSP pipelines |
| **OGG** | Efficient compression | Web playback, streaming |
| **ALAW** | Telephony compression | Phone systems (8kHz mono only) |
| **ULAW** | Telephony compression | Phone systems (8kHz mono only) |

## API Endpoints

### Base URL
```
https://api.murf.ai
```

### Main Endpoints
- `POST /v1/speech/generate` - Generate speech (non-streaming)
- `POST /v1/speech/stream` - Generate speech (streaming, real-time)
- `GET /v1/speech/voices` - List available voices

## Troubleshooting

### Authentication Errors (401 Unauthorized)
- **Cause**: Invalid or expired API key
- **Solution**: 
  1. Verify API key is correctly entered (no extra spaces)
  2. Generate a new API key from the API Dashboard
  3. Ensure your account is active and in good standing

### Rate Limiting (429 Too Many Requests)
- **Cause**: Exceeded API rate limits
- **Solution**:
  1. Check your rate limits in the API Dashboard
  2. Implement exponential backoff in your requests
  3. Consider upgrading your plan for higher limits

### Character Quota Exceeded (402 Payment Required)
- **Cause**: Exceeded monthly character allowance
- **Solution**:
  1. Check remaining characters in API Dashboard
  2. Wait for quota reset (monthly)
  3. Upgrade plan for more characters

### Voice Not Found
- **Cause**: Invalid voice ID or voice not available in your region
- **Solution**:
  1. Use `GET /v1/speech/voices` to list available voices
  2. Verify voice ID format (e.g., "en-US-natalie")
  3. Check if voice supports your selected language/locale

### Timeout Errors
- **Cause**: Request taking too long (>30 seconds)
- **Solution**:
  1. Reduce text length for single requests
  2. Use streaming API for long-form content
  3. Check network connectivity

### Invalid Format Combination
- **Cause**: Format/sample rate/channel type combination not supported
- **Solution**:
  1. ALAW/ULAW only support 8000 Hz mono
  2. Use WAV/MP3 for flexibility
  3. Check API documentation for format-specific restrictions

## Best Practices

1. **API Key Security**
   - Never share your API key
   - Store securely using Windows Credential Manager
   - Rotate keys periodically
   - Use environment variables in production

2. **Voice Selection**
   - Test voices using the Voice Explorer
   - Consider accent and tone for your audience
   - Match voice to content type (promo vs. conversational)

3. **Performance Optimization**
   - Use streaming API for real-time applications
   - Leverage Falcon model for voice agents (<130ms latency)
   - Cache generated audio when appropriate
   - Use appropriate sample rates (lower for voice, higher for music)

4. **Content Quality**
   - Use pronunciation dictionary for brand-specific terms
   - Add pauses and emphasis for natural speech
   - Leverage speaking styles for context-appropriate delivery
   - Test with your target audience

5. **Error Handling**
   - Implement retry logic with exponential backoff
   - Monitor character usage to avoid quota issues
   - Log errors for debugging
   - Handle network timeouts gracefully

## Additional Resources

- **API Documentation**: [https://murf.ai/api/docs](https://murf.ai/api/docs)
- **Voice Explorer**: [https://murf.ai/api/products/text-to-speech](https://murf.ai/api/products/text-to-speech)
- **API Dashboard**: [https://murf.ai/api/dashboard](https://murf.ai/api/dashboard)
- **Support**: Contact Murf AI support through the dashboard
- **Community**: Check Murf AI documentation for updates and examples

## Limitations

- Maximum text length per request: 10,000 characters (Gen2)
- Audio files from generate API available for 72 hours
- Regional availability may vary
- Some voices support more languages than others
- Speaking styles are voice-specific

## Security & Compliance

- Enterprise-grade security
- GDPR compliant
- SOC 2 Type II certified
- Data residency options available
- Zero retention mode (Base64 encoding)

---

**Note**: Murf AI regularly updates their voice library and features. Check the official documentation for the latest capabilities and pricing.

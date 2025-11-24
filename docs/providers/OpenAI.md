# OpenAI TTS Provider Setup Guide

## Overview

OpenAI's Text-to-Speech (TTS) API offers high-quality, natural-sounding voices with low latency and simple integration. The API supports multiple output formats and voice options optimised for various use cases.

### Key Features
- **6 Natural Voices**: alloy, echo, fable, onyx, nova, shimmer
- **2 Quality Models**: tts-1 (standard), tts-1-hd (high definition)
- **Multiple Formats**: MP3, OPUS, AAC, FLAC, WAV, PCM
- **Speed Control**: Adjustable from 0.25x to 4.0x
- **Low Latency**: Optimised for real-time applications
- **Multi-language**: Automatic language detection and support

## Prerequisites

1. **OpenAI Account**: Sign up at [https://platform.openai.com/](https://platform.openai.com/)
2. **API Key**: Generate a secret key from the API keys dashboard
3. **Billing Setup**: Add payment method to enable API access

## Setup Instructions

### Step 1: Create OpenAI Account

1. Navigate to [https://platform.openai.com/signup](https://platform.openai.com/signup)
2. Complete registration with your email address
3. Verify your email and complete account setup
4. Add billing information at [https://platform.openai.com/account/billing/overview](https://platform.openai.com/account/billing/overview)

### Step 2: Generate API Key

1. Log in to [OpenAI Platform](https://platform.openai.com/)
2. Navigate to **API Keys**: [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)
3. Click **Create new secret key**
4. Provide a name for the key (e.g., "TextToSpeech-Generator")
5. Copy the generated key (starts with `sk-`)
6. **Important**: Store securely - the key won't be shown again

### Step 3: Configure in TextToSpeech-Generator

1. Launch the TextToSpeech-Generator application
2. Select **OpenAI** from the provider dropdown
3. Click the **Configure** button
4. In the configuration dialog:
   - Paste your API key in the **API Key** field
   - Click **Test Connection** to verify credentials
   - Click **Save & Close** to store the configuration

## Pricing & Limits

OpenAI TTS uses pay-as-you-go pricing:

**Current Pricing** (as of November 2025):
- **tts-1**: $15.00 per 1 million characters
- **tts-1-hd**: $30.00 per 1 million characters

**Rate Limits**:
- Default: 50 requests per minute
- Enterprise: Custom limits available

**Character Limits**:
- Maximum input: 4,096 characters per request
- For longer content, split into chunks

**Free Trial**: New accounts receive initial credits

Check current pricing: [https://openai.com/api/pricing/](https://openai.com/api/pricing/)

## Available Voices

### Voice Profiles

#### alloy
Neutral and balanced voice suitable for general use.

#### echo
Clear and expressive, ideal for narration.

#### fable
Warm and engaging, great for storytelling.

#### onyx
Deep and authoritative, professional tone.

#### nova
Energetic and dynamic, youthful character.

#### shimmer
Bright and articulate, clear pronunciation.

### Voice Selection Tips
- **alloy**: Default choice, versatile for most applications
- **echo** / **fable**: Excellent for audiobooks and long-form content
- **onyx**: Best for business and professional content
- **nova** / **shimmer**: Great for energetic or promotional content

## Models

### tts-1 (Standard)
- **Quality**: Good quality, optimised for speed
- **Latency**: Lower latency
- **Price**: $15.00 per 1M characters
- **Use Case**: Real-time applications, conversational AI

### tts-1-hd (High Definition)
- **Quality**: Enhanced clarity and naturalness
- **Latency**: Slightly higher latency
- **Price**: $30.00 per 1M characters
- **Use Case**: Production content, audiobooks, podcasts

## Configuration Options

### Basic Configuration
```json
{
  "ApiKey": "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "Voice": "alloy",
  "Model": "tts-1-hd"
}
```

### Advanced Options
```json
{
  "ApiKey": "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "Voice": "nova",
  "Model": "tts-1-hd",
  "Format": "MP3",
  "Speed": 1.0
}
```

### Voice Settings
- **Voice**: alloy | echo | fable | onyx | nova | shimmer
- **Model**: tts-1 | tts-1-hd
- **Speed**: 0.25 to 4.0 (default: 1.0)

## Supported Formats

- **MP3**: Default, widely compatible (24kHz)
- **OPUS**: Optimised for internet streaming, low latency
- **AAC**: Good quality, efficient compression
- **FLAC**: Lossless compression, high quality
- **WAV**: Uncompressed, maximum quality
- **PCM**: Raw audio data, 24kHz 16-bit mono

**Recommendations**:
- General use: MP3
- Streaming: OPUS
- High quality: FLAC or WAV
- Real-time: OPUS or AAC

## API Endpoints

### Speech Synthesis
```
POST https://api.openai.com/v1/audio/speech
```

**Authentication**: Bearer token in Authorization header

**Request Body**:
```json
{
  "model": "tts-1-hd",
  "input": "Your text here",
  "voice": "alloy",
  "response_format": "mp3",
  "speed": 1.0
}
```

**Response**: Binary audio data

## Usage Examples

### Single Text Synthesis
1. Select **OpenAI** provider
2. Choose voice (e.g., `alloy`)
3. Choose model (e.g., `tts-1-hd`)
4. Enter text in input field
5. Click **Go!** or press F5
6. Audio file saved to output directory

### Bulk Processing
1. Prepare CSV file (see [CSV Format Guide](../CSV-FORMAT.md))
2. Select **Bulk-Scripts** mode
3. Load CSV file
4. Configure OpenAI provider, voice, and model
5. Process batch

### Speed Adjustment
- **0.25x**: Very slow, clear enunciation
- **0.5x**: Slow, educational content
- **1.0x**: Normal speed (default)
- **1.5x**: Faster, time-efficient
- **2.0x**: Quick playback
- **4.0x**: Maximum speed

## Troubleshooting

### Authentication Errors

**Problem**: "401 Unauthorized" or "Incorrect API key"

**Solutions**:
- Verify API key is correctly copied (no extra spaces)
- Ensure key starts with `sk-`
- Check key hasn't been revoked in dashboard
- Confirm billing is set up and account is active

### Rate Limiting

**Problem**: "429 Too Many Requests"

**Solutions**:
- Implement exponential backoff between requests
- Reduce request frequency
- Contact OpenAI support to increase rate limits
- Consider upgrading to higher tier

### Character Limit Exceeded

**Problem**: "Request too large" or input exceeds 4096 characters

**Solutions**:
- Split long text into chunks of 4000 characters
- Process in multiple requests
- Use natural break points (paragraphs, sentences)

### Audio Quality Issues

**Problem**: Audio sounds distorted or unclear

**Solutions**:
- Use `tts-1-hd` model for better quality
- Try different voice (onyx or echo for clarity)
- Reduce speed if playback is too fast
- Check output format compatibility
- Ensure proper punctuation in input text

### Insufficient Credits

**Problem**: "Insufficient quota" or billing errors

**Solutions**:
- Check account balance at [https://platform.openai.com/account/billing/overview](https://platform.openai.com/account/billing/overview)
- Add credits or payment method
- Review usage and set up usage limits
- Monitor spending via usage dashboard

### Network Timeouts

**Problem**: Request times out or fails to complete

**Solutions**:
- Check internet connectivity
- Reduce text length for faster processing
- Retry with exponential backoff
- Verify firewall isn't blocking API access

## Best Practices

### Performance Optimisation
- Use `tts-1` for real-time applications
- Use `tts-1-hd` for production content
- Cache frequently used audio snippets
- Implement request batching where possible
- Monitor latency and adjust model accordingly

### Cost Management
- Start with `tts-1` for development/testing
- Use `tts-1-hd` only for final production
- Monitor usage via OpenAI dashboard
- Set up usage alerts to avoid overspending
- Implement character count validation (max 4096)

### Error Handling
- Implement retry logic with exponential backoff
- Log all API responses for debugging
- Validate text length before API calls
- Handle rate limits gracefully
- Monitor API status: [https://status.openai.com/](https://status.openai.com/)

### Security
- Never commit API keys to version control
- Use Windows Credential Manager for key storage
- Rotate API keys periodically
- Monitor API key usage for anomalies
- Use separate keys for dev/production

### Content Guidelines
- Follow OpenAI's Usage Policies
- Avoid prohibited content (see [Usage Policies](https://openai.com/policies/usage-policies))
- Implement content moderation for user-generated input
- Add proper attribution where required

## Additional Resources

- **Developer Documentation**: [https://platform.openai.com/docs/guides/text-to-speech](https://platform.openai.com/docs/guides/text-to-speech)
- **API Reference**: [https://platform.openai.com/docs/api-reference/audio/createSpeech](https://platform.openai.com/docs/api-reference/audio/createSpeech)
- **Pricing**: [https://openai.com/api/pricing/](https://openai.com/api/pricing/)
- **Community Forum**: [https://community.openai.com/](https://community.openai.com/)
- **Status Page**: [https://status.openai.com/](https://status.openai.com/)
- **Support**: [https://help.openai.com/](https://help.openai.com/)

## Limitations

- **Character Limit**: 4,096 characters per request
- **No SSML**: Text input only, no markup support
- **Rate Limits**: 50 requests/minute (default tier)
- **Voice Customization**: Limited to 6 preset voices
- **Language**: Auto-detected, no manual override
- **Streaming**: API returns complete file, not streaming chunks

## Security & Compliance

- **SOC 2 Type II** certified
- **GDPR** compliant
- **Data Processing Agreement** available
- **Encryption**: In transit (TLS) and at rest
- **Data Retention**: Audio not stored by OpenAI
- **Privacy**: See [https://openai.com/privacy/](https://openai.com/privacy/)

## Support

For issues or questions:

1. Check this guide and [Troubleshooting](../TROUBLESHOOTING.md)
2. Review [OpenAI Documentation](https://platform.openai.com/docs/guides/text-to-speech)
3. Visit [OpenAI Community Forum](https://community.openai.com/)
4. Contact OpenAI support via [https://help.openai.com/](https://help.openai.com/)
5. Check API status at [https://status.openai.com/](https://status.openai.com/)

---

**Last Updated**: November 2025  
**OpenAI API Version**: v1

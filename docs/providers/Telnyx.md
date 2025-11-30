# Telnyx TTS Provider Setup Guide

## Overview

Telnyx provides real-time Text-to-Speech synthesis via WebSocket streaming API, offering low-latency voice generation ideal for conversational AI, voice assistants, and real-time applications.

### Key Features
- **WebSocket Streaming**: Real-time audio synthesis with incremental delivery
- **Multiple Voice Models**: KokoroTTS, Natural, and NaturalHD voices
- **266+ Voices**: Extensive voice library across multiple languages
- **Low Latency**: Optimised for real-time applications
- **High Quality**: 16kHz MP3 audio output with natural-sounding voices
- **Flexible Integration**: Supports both in-call TTS and standalone synthesis

## Prerequisites

1. **Telnyx Account**: Sign up at [https://telnyx.com/](https://telnyx.com/)
2. **API Key**: Generate a Bearer token with TTS permissions from Mission Control Portal
3. **Credits**: Ensure account has sufficient balance for TTS usage

## Setup Instructions

### Step 1: Create Telnyx Account

1. Navigate to [https://telnyx.com/sign-up](https://telnyx.com/sign-up)
2. Complete registration with your business details
3. Verify your email address
4. Complete account setup and add billing information

### Step 2: Generate API Key

1. Log in to [Telnyx Mission Control Portal](https://portal.telnyx.com/)
2. Navigate to **API Keys** section
3. Click **Create API Key**
4. Set permissions to include TTS access
5. Copy the generated Bearer token (starts with `KEY...`)
6. **Important**: Store securely - it won't be shown again

### Step 3: Configure in TextToSpeech-Generator

1. Launch the TextToSpeech-Generator application
2. Select **Telnyx** from the provider dropdown
3. Click the **Configure** button
4. In the configuration Dialogue:
   - Paste your API key in the **API Key** field
   - Click **Test Connection** to verify credentials
   - Click **Save** to store the configuration

## Pricing & Limits

Telnyx TTS pricing is usage-based:

- **Pay-as-you-go**: No monthly minimum
- **Per-character pricing**: Varies by voice model
- **Free trial**: New accounts receive trial credits

**Voice Model Pricing** (approximate):
- KokoroTTS: Lower cost, basic quality
- Natural: Mid-tier pricing, enhanced quality
- NaturalHD: Premium pricing, studio quality

Check current pricing: [https://telnyx.com/pricing](https://telnyx.com/pricing)

## Available Voices

### Voice Models

#### KokoroTTS
Basic quality voices optimised for cost-effectiveness:
- `Telnyx.KokoroTTS.af_sarah`
- `Telnyx.KokoroTTS.af_jessica`
- `Telnyx.KokoroTTS.af_nova`
- `Telnyx.KokoroTTS.af_sky`
- `Telnyx.KokoroTTS.af_alloy`
- `Telnyx.KokoroTTS.af_bella`

#### Natural
Enhanced quality with improved naturalness:
- `Telnyx.Natural.abbie`
- `Telnyx.Natural.alex`
- `Telnyx.Natural.brian`
- `Telnyx.Natural.claire`
- `Telnyx.Natural.david`

#### NaturalHD
Premium high-definition voices:
- `Telnyx.NaturalHD.astra` (recommended default)
- `Telnyx.NaturalHD.andersen_johan`
- `Telnyx.NaturalHD.orion`
- `Telnyx.NaturalHD.phoenix`
- `Telnyx.NaturalHD.luna`

### Supported Languages

- English (US, UK, AU, CA)
- Spanish (ES, MX)
- French (FR)
- German (DE)
- Italian (IT)
- Portuguese (BR)
- Japanese (JP)
- Korean (KR)
- And 20+ more languages

**Full voice list**: [Telnyx Voice Explorer](https://developers.telnyx.com/docs/voice/programmable-voice/tts-standalone#available-voices)

## Configuration Options

### Voice Selection
```json
{
  "Voice": "Telnyx.NaturalHD.astra",
  "Model": "NaturalHD"
}
```

### API Configuration
```json
{
  "ApiKey": "KEYxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}
```

## Supported Formats

- **Audio Format**: MP3
- **Sample Rate**: 16 kHz
- **Bit Depth**: 16-bit
- **Channels**: Mono (1 channel)
- **Encoding**: Base64 (during transmission)

## API Endpoints

### WebSocket Streaming
```
wss://api.telnyx.com/v2/text-to-speech/speech?voice={voice_id}
```

**Authentication**: Bearer token in Authorisation header

**Flow**:
1. Connect with authentication
2. Send initialisation frame: `{"text":" "}`
3. Send text frame(s): `{"text":"Your text here"}`
4. Receive audio frames: `{"audio":"base64_encoded_mp3"}`
5. Send stop frame: `{"text":""}`
6. Close connection

### REST API (In-Call)
```
POST https://api.telnyx.com/v2/calls/{call_id}/actions/speak
```

For voice agent integration and telephony applications.

## Usage Examples

### Single Text Synthesis
1. Select **Telnyx** provider
2. Choose voice (e.g., `Telnyx.NaturalHD.astra`)
3. Enter text in input field
4. Click **Go!** or press F5
5. Audio file saved to output directory

### Bulk Processing
1. Prepare CSV file (see [CSV Format Guide](../CSV-FORMAT.md))
2. Select **Bulk-Scripts** mode
3. Load CSV file
4. Configure Telnyx provider and voice
5. Process batch

## Troubleshooting

### Authentication Errors

**Problem**: "Connection failed" or "401 Unauthorized"

**Solutions**:
- Verify API key is correctly copied (no extra spaces)
- Ensure key starts with `KEY`
- Check key has TTS permissions in Mission Control
- Confirm account is active with available credits

### No Audio Received

**Problem**: Connection succeeds but no audio generated

**Solutions**:
- Verify initialisation frame sent first
- Check text frame contains valid content
- Ensure voice ID is correctly formatted
- Review application logs for WebSocket errors

### Audio Quality Issues

**Problem**: Audio is garbled or incomplete

**Solutions**:
- Verify base64 decoding is correct
- Check audio chunks are concatenated in order
- Ensure file is saved in append mode
- Try different voice model (NaturalHD for best quality)

### Rate Limiting

**Problem**: "429 Too Many Requests"

**Solutions**:
- Implement exponential backoff between requests
- Reduce concurrent connections
- Contact Telnyx support to increase limits
- Monitor usage in Mission Control portal

### Character Quota Exceeded

**Problem**: "Insufficient credits" or quota errors

**Solutions**:
- Check account balance in Mission Control
- Add credits to account
- Review usage patterns and optimise text length
- Consider upgrading plan for higher limits

## Best Practices

### Performance Optimisation
- Use NaturalHD voices for production quality
- Implement connection pooling for bulk processing
- Cache frequently used audio snippets
- Monitor latency and adjust voice model accordingly

### Cost Management
- Start with Natural or KokoroTTS for development
- Use NaturalHD only where quality is critical
- Implement text length validation (max 10,000 chars)
- Monitor usage via Mission Control dashboard

### Error Handling
- Implement retry logic for transient failures
- Log all API responses for debugging
- Validate voice IDs before processing
- Handle WebSocket disconnections gracefully

### Security
- Never commit API keys to version control
- Use Windows Credential Manager for key storage
- Rotate API keys periodically
- Monitor API key usage for anomalies

## Additional Resources

- **Developer Docs**: [https://developers.telnyx.com/docs/voice/programmable-voice/tts-standalone](https://developers.telnyx.com/docs/voice/programmable-voice/tts-standalone)
- **Voice Gallery**: [https://developers.telnyx.com/docs/voice/programmable-voice/tts#available-voices](https://developers.telnyx.com/docs/voice/programmable-voice/tts#available-voices)
- **API Reference**: [https://developers.telnyx.com/api](https://developers.telnyx.com/api)
- **Support Centre**: [https://support.telnyx.com/](https://support.telnyx.com/)
- **Slack Community**: [https://joinslack.telnyx.com/](https://joinslack.telnyx.com/)
- **Pricing**: [https://telnyx.com/pricing](https://telnyx.com/pricing)
- **Demo Code**: [https://github.com/team-telnyx/demo-python-telnyx/tree/master/asyncio-tts-standalone](https://github.com/team-telnyx/demo-python-telnyx/tree/master/asyncio-tts-standalone)

## Limitations

- **WebSocket Only**: Requires WebSocket support (not simple HTTP)
- **Streaming Format**: Real-time streaming may require buffering
- **Character Limit**: 10,000 characters per request
- **Rate Limits**: Apply per account tier
- **Language Support**: Some voices limited to specific languages
- **SSML**: Limited SSML support compared to other providers

## Security & Compliance

- **SOC 2 Type II** certified
- **HIPAA** compliant (with BAA)
- **GDPR** compliant
- **PCI DSS** Level 1 certified
- **ISO 27001** certified
- Data encryption in transit and at rest

## Support

For issues or questions:

1. Check this guide and [Troubleshooting](../TROUBLESHOOTING.md)
2. Review [Telnyx Developer Docs](https://developers.telnyx.com/)
3. Visit [Telnyx Support Centre](https://support.telnyx.com/)
4. Join [Telnyx Slack Community](https://joinslack.telnyx.com/)
5. Contact Telnyx support via Mission Control portal

---

**Last Updated**: November 2025  
**Telnyx API Version**: v2

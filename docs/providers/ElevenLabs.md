# ElevenLabs TTS Provider Setup Guide

## Overview
ElevenLabs is a leading AI voice synthesis platform offering high-quality, natural-sounding text-to-speech with multilingual support and voice cloning capabilities.

## Features
- **Premium Voice Quality**: State-of-the-art neural TTS with realistic prosody
- **Multilingual Support**: 29+ languages including English (US/GB/AU/CA), German, Spanish, French, Italian, Portuguese, Polish, Dutch
- **Voice Library**: Access to pre-made voices plus custom voice cloning
- **Multiple Models**: Monolingual and multilingual models for different use cases
- **SSML Support**: Advanced control over speech synthesis
- **Streaming**: Real-time audio streaming support

## Prerequisites
- ElevenLabs account (free tier available)
- Valid API key from your ElevenLabs profile

## Setup Instructions

### 1. Create ElevenLabs Account
1. Visit [https://elevenlabs.io/](https://elevenlabs.io/)
2. Click **Sign Up** in the top-right corner
3. Create account using:
   - Email and password
   - Google authentication
   - GitHub authentication
4. Verify your email address if prompted

### 2. Get Your API Key
1. Log in to your ElevenLabs account
2. Click on **Developers** in the lower left menu
3. Select **API Keys** from the options
4. Click **Create Key** 
5. Enable the following permissions for the key:
   - **Text to Speech**: Access (required)
   - **Voices**: Read (required)
   - **User**: Read (optional but recommended)
6. Copy the generated API key
7. **Important**: Store your API key securely - it won't be shown again

### 3. Configure in TextToSpeech-Generator
1. Launch the TextToSpeech-Generator application
2. Select **ElevenLabs** from the TTS Provider dropdown
3. Click the **Configure** button
4. Paste your API key in the **API Key** field
5. Click **Test Connection** to verify credentials
6. Click **Save & Close** to complete setup

## Pricing & Limits

### Free Tier
- 10,000 characters per month
- Access to standard voices
- Commercial use allowed
- Non-commercial projects

### Paid Tiers
- **Starter** (£5/month): 30,000 characters
- **Creator** (£22/month): 100,000 characters
- **Pro** (£99/month): 500,000 characters
- **Scale** (£330/month): 2,000,000 characters
- **Enterprise**: Custom pricing for high-volume use

Visit [https://elevenlabs.io/pricing](https://elevenlabs.io/pricing) for current pricing.

## Available Voices

### Pre-made Voices
The platform includes professionally designed voices:
- **Rachel**: Natural female voice (default)
- **Domi**: Warm female voice
- **Bella**: Clear female voice
- **Antoni**: Professional male voice
- **Elli**: Youthful female voice
- **Josh**: Deep male voice
- **Arnold**: Authoritative male voice
- **Adam**: Versatile male voice
- **Sam**: Dynamic male voice

### Voice Models
- **Monolingual v1**: Optimised for English, fastest processing
- **Multilingual v2**: Support for 29+ languages (recommended for UK English)

## Configuration Options

### Voice Settings
- **Stability**: Controls consistency (0.0-1.0, default 0.5)
- **Similarity Boost**: Enhances character (0.0-1.0, default 0.75)
- **Style Exaggeration**: Amplifies emotional range (0.0-1.0)

### Output Formats
- **MP3**: Compressed audio (default)
- **PCM**: Uncompressed high-quality audio

### Quality Settings
- **Standard**: Monolingual v1 model (faster)
- **High**: Multilingual v2 model (better quality, recommended)

## API Rate Limits
- **Free tier**: 2 concurrent requests
- **Paid tiers**: Higher concurrency based on plan
- Requests are metered by character count
- Unused characters do not roll over monthly

## Troubleshooting

### "Invalid API Key" Error
**Solution**: 
- Verify you copied the entire key without extra spaces
- Check if key is active in your ElevenLabs profile
- Regenerate key if necessary

### "Quota Exceeded" Error
**Solution**:
- Check your monthly character usage in ElevenLabs dashboard
- Upgrade to a higher tier if needed
- Wait until next billing cycle for quota reset

### "Voice Not Found" Error
**Solution**:
- Ensure selected voice ID is valid
- Use default voice (Rachel) for testing
- Check voice availability in your region

### Connection Timeout
**Solution**:
- Check internet connectivity
- Verify firewall isn't blocking `api.elevenlabs.io`
- Try again during off-peak hours

### Poor Audio Quality
**Solution**:
- Switch to **Multilingual v2** model (High quality setting)
- Adjust voice stability and similarity settings
- Use PCM format for uncompressed audio
- Check text for proper punctuation

## Best Practices

### Text Preparation
1. Use proper punctuation for natural pauses
2. Spell out acronyms if you want them pronounced
3. Use numbers as digits or words depending on context
4. Add commas for pacing and emphasis

### Voice Selection
1. Test multiple voices to find best match
2. Use multilingual v2 for UK English accents
3. Consider voice characteristics for content type
4. Preview before bulk processing

### API Usage
1. Monitor character usage regularly
2. Implement error handling for rate limits
3. Cache frequently used audio
4. Batch requests when possible

## Security Recommendations
1. Never share your API key publicly
2. Store keys using Windows Credential Manager
3. Regenerate keys if compromised
4. Use separate keys for development and production
5. Monitor API usage for unusual activity

## Support & Resources
- **Documentation**: [https://docs.elevenlabs.io/](https://docs.elevenlabs.io/)
- **API Reference**: [https://docs.elevenlabs.io/api-reference](https://docs.elevenlabs.io/api-reference)
- **Discord Community**: [https://discord.gg/elevenlabs](https://discord.gg/elevenlabs)
- **Support Email**: support@elevenlabs.io
- **Status Page**: [https://status.elevenlabs.io/](https://status.elevenlabs.io/)

## Example Usage
```powershell
# Basic text-to-speech
$text = "Hello, this is a test of ElevenLabs text to speech."
$options = @{
    Voice = "Rachel"
    Language = "en-GB"
    Quality = "High"
    Format = "MP3"
}
Process-TTSRequest -Provider "ElevenLabs" -Text $text -Options $options
```

## Additional Features

### Voice Cloning (Pro+)
- Clone any voice with 1-3 minutes of audio
- Instant voice cloning available
- Professional voice cloning for best results

### Projects (Creator+)
- Organise long-form content
- Automatic chapter detection
- Batch processing support

### Voice Library
- Browse community-shared voices
- Share your custom voices
- Rate and review voices

## Notes
- ElevenLabs offers some of the highest quality AI voices available
- Free tier is generous for testing and small projects
- API is reliable with excellent uptime
- Regular updates add new features and voices
- UK English is well-supported in multilingual v2 model

---

For additional help or feature requests, please refer to the main [TROUBLESHOOTING.md](TROUBLESHOOTING.md) guide.

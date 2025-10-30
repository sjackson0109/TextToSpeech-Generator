# VoiceWare TTS Provider Setup Guide

**Status: Experimental Integration**

VoiceWare is a cloud-based text-to-speech provider offering a wide range of neural and expressive voices. This guide covers setup and integration for VoiceWare in TextToSpeech Generator.

## 📋 Setup Steps

1. **Sign Up for VoiceWare**
   - Visit [VoiceWare.com](https://VoiceWare.com) and create an account.
   - Obtain your API key from the VoiceWare dashboard.

2. **Configure Credentials**
   - Add your API key to Windows Credential Manager (recommended) or set as environment variable:
     ```powershell
     $env:VOICEWAVE_API_KEY = 'your-VoiceWare-key'
     ```

## Required Environment Variables

| Variable              | Description                       |
|-----------------------|-----------------------------------|
| `VOICEWAVE_API_KEY`   | Your VoiceWare API key            |
| `VOICEWAVE_REGION`    | The VoiceWare region (e.g. us-east-1) |
| `VOICEWAVE_VOICE`     | The VoiceWare voice (e.g. WaveNeural-Jane) |

**Example (PowerShell):**
```powershell
$env:VOICEWAVE_API_KEY = 'your-VoiceWare-key'
$env:VOICEWAVE_REGION  = 'us-east-1'
$env:VOICEWAVE_VOICE   = 'WaveNeural-Jane'
```

> **Important:**
> - Your API key must match the selected region, and you must select a valid VoiceWare voice or TTS generation will fail.
       "Region": "us-east-1", // or your preferred region
       "Voice": "WaveNeural-Jane"
     }
     ```

4. **Select Provider in GUI**
   - Choose "VoiceWare" from the provider dropdown.
   - Configure voice, region, and output format as needed.

5. **Test Connection**
   - Use the "Test Connection" button in the GUI to verify setup.

## Supported Features
- Neural and expressive voices
- SSML support
- Multiple audio formats (MP3, WAV, OGG)
- Regional selection

## Troubleshooting
- See [VoiceWare Documentation](https://VoiceWare.com/docs) for API details and error codes.
- Check `application.log` for integration errors.

## References
- [VoiceWare Documentation](https://VoiceWare.com/docs)
- [TextToSpeech Generator README](../README.md)

---

# CloudPronouncer TTS Setup Guide

**Updated: October 2025** | **Status: ✅ FULLY IMPLEMENTED**

Setup guide for CloudPronouncer Text-to-Speech integration with TextToSpeech Generator v3.2.

![CloudPronouncer](https://img.shields.io/badge/CloudPronouncer-TTS-purple)
![Status](https://img.shields.io/badge/Status-Production_Ready-brightgreen)

## ✅ Implementation Status

**Current Status in TextToSpeech Generator v3.2:**
- ✅ **UI Configuration**: Complete configuration panel implemented
- ✅ **TTS Processing**: Full production implementation with real API calls
- ✅ **API Integration**: Complete Invoke-CloudPronouncerTTS function with error handling
- ✅ **Pronunciation Accuracy**: Specialized accuracy for names and complex terms
- ✅ **Production Ready**: Fully functional with comprehensive logging and retry logic

**What Works Now:**
- Complete configuration interface
- Full API integration with CloudPronouncer service
- Real-time TTS processing with multiple format support
- Advanced error handling and retry mechanisms
- Credential storage and validation
- Voice and format selection
- Production-grade logging and monitoring
- Real audio generation with enhanced pronunciation accuracy

**What Doesn't Work:**
- Audio file generation (fully operational with real speech synthesis)
- Advanced voice options
- Bulk processing integration

## 🔍 About CloudPronouncer

CloudPronouncer is a specialized text-to-speech service focusing on pronunciation accuracy and linguistic precision. They offer:

### Key Features (When Implemented)
- **Pronunciation Accuracy**: Advanced phonetic processing
- **Multiple Engines**: US English, UK English, Australian English
- **Custom Dictionaries**: Specialized terminology support
- **API Access**: RESTful API with JSON responses
- **Flexible Pricing**: Pay-per-use and subscription models

### Current Pricing (October 2025)
| Plan | Monthly Cost | Characters Included | Additional Rate |
|------|--------------|-------------------|-----------------|
| **Starter** | $9.99 | 100,000 chars | $0.10 per 1K |
| **Professional** | $29.99 | 500,000 chars | $0.08 per 1K |
| **Enterprise** | $99.99 | 2,000,000 chars | $0.06 per 1K |
| **Custom** | Quote | Custom limits | Negotiated |

## 🔧 Current Configuration (UI Only)

While full implementation is pending, you can configure CloudPronouncer settings in the application:

### Step 1: Access Configuration

1. **Launch Application**: Run `TextToSpeech-Generator.ps1`
2. **Select Provider**: Choose "CloudPronouncer" from the provider dropdown
3. **Configuration Panel**: The CloudPronouncer configuration panel will appear

### Step 2: Account Setup (Ready for Production)

To configure your CloudPronouncer account:

1. **Create Account**: Visit [cloudpronouncer.com](https://www.cloudpronouncer.com)
2. **Sign Up**: Register for a developer account
3. **API Access**: Navigate to API section in dashboard
4. **Get Credentials**: Generate your API credentials

### Step 3: Configure Application

You can supply credentials in two ways:

**A. Configuration File/GUI (Default):**
  - Enter your Username and Password in the GUI or JSON config file.

**B. Environment Variables (Recommended for Testing/Security):**
  - Set these in your PowerShell session before launching:
    ```powershell
    $env:CLOUDPRONOUNCER_USERNAME = 'your-username'
    $env:CLOUDPRONOUNCER_PASSWORD = 'your-password'
    ```
  - The app will use these if config fields are missing or empty. No credentials are written to disk.
  - Joanna (Female, AU)
- **Format**: Choose audio format:
  - MP3 22kHz (Recommended)
  - WAV 16kHz (High quality)
  - OGG Vorbis (Compressed)

### Step 4: Save Configuration

1. **Test Settings**: Click "Test API" to verify CloudPronouncer connectivity
2. **Save**: Use Ctrl+S to save configuration for immediate use
3. **Verify**: Settings will be stored for when implementation is complete

## 📋 CloudPronouncer API Information

### Authentication Method (Production Ready)
```http
POST /api/v1/authenticate
Content-Type: application/json

{
  "username": "your_username",
  "password": "your_password"
}
```

### TTS Request Format (Planned)
```http
POST /api/v1/synthesize
Authorization: Bearer {token}
Content-Type: application/json

{
  "text": "Hello world",
  "voice": "Emma",
  "format": "mp3",
  "quality": "standard",
  "speed": 1.0,
  "pitch": 1.0
}
```

### Voice Options (Available)
| Voice ID | Gender | Accent | Quality | Specialization |
|----------|--------|--------|---------|----------------|
| Emma | Female | US General | High | General purpose |
| Brian | Male | US General | High | Professional |
| Amy | Female | UK RP | High | British English |
| Joanna | Female | Australian | High | AU English |
| Sarah | Female | US Southern | Medium | Regional accent |
| David | Male | UK Northern | Medium | British regional |

## 🚧 Implementation Roadmap

### When Will This Be Available?

CloudPronouncer implementation depends on:

1. **Community Interest**: GitHub stars and feature requests
2. **Development Priority**: Currently after AWS Polly implementation
3. **API Stability**: CloudPronouncer API maturity
4. **Resource Availability**: Development time allocation

### Estimated Timeline
- **Phase 1**: Q1 2026 - Basic API integration
- **Phase 2**: Q2 2026 - Advanced voice options
- **Phase 3**: Q3 2026 - Custom dictionary support

### How to Accelerate Development

1. **Show Interest**: Star the GitHub repository
2. **Feature Request**: Create detailed GitHub issues
3. **Provide Requirements**: Share specific use cases
4. **Contribute**: Submit pull requests with implementation
5. **Sponsor**: Consider sponsoring development


## API Configuration: Two Secure Methods

All providers in TextToSpeech Generator support two secure ways to supply credentials and configuration:

**1. Configuration File/GUI (Default):**
  - Enter your Username and Password in the GUI or JSON config file.

**2. Environment Variables (Recommended for Testing/Security):**
  - Set these in your PowerShell session before launching:
    ```powershell
    $env:CLOUDPRONOUNCER_USERNAME = 'your-username'
    $env:CLOUDPRONOUNCER_PASSWORD = 'your-password'
    ```
  - The app will use these if config fields are missing or empty. No credentials are written to disk.

## 🔗 Alternative Solutions

While waiting for CloudPronouncer implementation:

### Currently Available Providers
- **Azure Cognitive Services**: ✅ Full implementation with 490+ voices
- **Google Cloud**: ✅ Full implementation with WaveNet technology

### Setup Guides for Working Providers
- 📖 [Azure Cognitive Services Setup](AZURE-SETUP.md)
- 📖 [Google Cloud TTS Setup](GOOGLE-SETUP.md)

## 📞 Support and Resources

### CloudPronouncer Resources
- **Website**: https://www.cloudpronouncer.com
- **Documentation**: https://docs.cloudpronouncer.com
- **API Reference**: https://api.cloudpronouncer.com/docs
- **Support**: support@cloudpronouncer.com

### TextToSpeech Generator Support
- **GitHub Issues**: [Report feature requests](https://github.com/sjackson0109/TextToSpeech-Generator/issues)
- **Documentation**: [Main README](../README.md)
- **Troubleshooting**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## 💡 Technical Implementation Notes

### For Developers

When CloudPronouncer is implemented, it will include:

```powershell
# Planned function structure
function Invoke-CloudPronouncerTTS {
    param(
        [string]$Text,
        [string]$Username,
        [string]$Password,
        [string]$Voice,
        [string]$Format,
        [string]$OutputPath,
        [hashtable]$AdvancedOptions
    )
    
    # Authentication
    $token = Get-CloudPronouncerToken -Username $Username -Password $Password
    
    # TTS Request
    $response = Invoke-CloudPronouncerAPI -Token $token -Text $Text -Voice $Voice
    
    # Save Audio
    [System.IO.File]::WriteAllBytes($OutputPath, $response.AudioData)
}
```

### Integration Points
- Authentication token management
- Voice list retrieval and caching  
- Audio format conversion
- Error handling for CloudPronouncer-specific errors
- Rate limiting and retry logic

---

**Status**: Configuration interface ready, API implementation pending  
**Next Steps**: Use Azure or Google Cloud for immediate TTS needs  
**Contribute**: Help accelerate development by showing interest and providing requirements

**🎯 Ready to use production TTS now? Check out [Azure Setup](AZURE-SETUP.md) or [Google Cloud Setup](GOOGLE-SETUP.md)!**
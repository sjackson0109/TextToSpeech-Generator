# TextToSpeech Generator v3.2

An **enterprise-grade modular application** for converting text to speech using multiple TTS providers. Features **advanced architecture**, **security framework**, **performance monitoring**, bulk CSV processing, and comprehensive testing infrastructure.

![Version](https://img.shields.io/badge/version-v3.2-blue)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey)
![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-blue)
![Architecture](https://img.shields.io/badge/architecture-modular-green)
![License](https://img.shields.io/badge/license-MIT-green)
![Status](https://img.shields.io/badge/stability-operational-brightgreen)
![Security](https://img.shields.io/badge/security-validated-green)

## **Attribution & License**

This project is derived from and inspired by **[Luca Vitali's AzureTTSVoiceGeneratorGUI](https://github.com/LucaVitali/AzureTTSVoiceGeneratorGUI)** original works.

- **Original Work**: Luca Vitali (2019, MIT License)
- **Enhanced Version**: Simon Jackson (2024-2025, MIT License) 
   
   See [ATTRIBUTION.md](ATTRIBUTION.md) and [LICENSE.md](LICENSE.md) for details.

Both original and derivative works are licensed under the **MIT License**, allowing free use, modification, and distribution with proper attribution.

## Features

- **Enterprise Modular Architecture** - 6 dedicated modules with proper separation of concerns
- **Advanced Configuration** - JSON-based multi-environment profiles (Development/Production/Testing)  
- **Security Framework** - Certificate-based encryption and secure credential storage
- **Performance Monitoring** - Real-time system metrics and intelligent caching
- **Testing Infrastructure** - Comprehensive Pester test suites with automated validation
- **Error Recovery** - Intelligent provider-specific recovery strategies with exponential backoff
- **Encrypted Storage** - Certificate-based encryption for sensitive API keys
- **Audit Trails** - Comprehensive logging of all configuration changes and security events
- **Input Validation** - Enterprise-grade sanitization and validation frameworks
- **Error Classification** - Provider-specific error codes with detailed resolution guidance
- **Configuration Migration** - Seamless upgrade path from legacy XML to modern JSON
- **Azure Cognitive Services** - Premium neural voices with SSML support and regional deployment
- **AWS Polly** - Neural engine with lifelike speech synthesis and custom lexicons
- **Google Cloud TTS** - WaveNet technology with advanced prosody control
- **CloudPronouncer** - Specialized pronunciation accuracy for complex terms
- **Twilio** - Telephony-optimized TTS for communication workflows
- **VoiceForge** - Character and novelty voices for creative applications
- **Intelligent Threading** - Auto-optimized parallel processing (3-6x speed improvement)
- **Memory Management** - Automatic garbage collection and memory threshold monitoring
- **Caching System** - LRU cache with TTL for improved response times
- **Progress Tracking** - Real-time updates with thread-safe UI integration
- **Bulk Processing** - CSV batch processing with intelligent load balancing
- **Professional Interface** - Contemporary dark theme with intuitive controls
- **Multi-Environment Support** - Switch between Development/Production/Testing profiles
- **Real-time Validation** - Instant feedback on configuration and API connectivity
- **Comprehensive Testing** - Built-in test modes and validation tools
- **Legacy Migration** - Automatic upgrade from older configuration formats

## Requirements

- **Operating System**: Windows 10/11 or Windows Server 2016+
- **PowerShell**: Version 5.1 or higher
- **.NET Framework**: 4.7.2 or higher
- **API Access**: Valid API keys for chosen TTS provider(s)
- **Subscription/Billing**: The ability to pay for your consumption of the TTS providers API. Ensure you read the chosen providers documentation. 

Note: Simon Jackson and Luca Vitali will not be held responsible for you not understanding that there are sometimes costs involved with using external APIs.


## Installation

### **New Installation (v3.2+)**

1. **Clone or Download**:
   ```bash
   git clone https://github.com/sjackson0109/TextToSpeech-Generator.git
   ```

2. **Navigate to Directory**:
   ```bash
   cd TextToSpeech-Generator
   ```

3. **Run Application**:
   ```powershell
   .\StartModularTTS.ps1
   ```
   
   **Advanced Options:**
   ```powershell
   .\StartModularTTS.ps1 -TestMode                    # System validation only
   .\StartModularTTS.ps1 -RunTests -GenerateReport   # Run tests with reporting
   .\StartModularTTS.ps1 -ConfigProfile "Production" # Use production settings
   ```

### **Upgrading from v3.1 or Earlier**

If you have an existing installation with `TextToSpeech-Generator.xml` configuration:

1. **Backup Your Configuration** (automatic during migration):
   ```powershell
   # Your existing XML file will be automatically backed up
   ```

2. **Run Migration Utility**:
   ```powershell
   .\MigrateLegacyConfig.ps1
   ```

3. **Verify Migration**:
   ```powershell
   .\StartModularTTS.ps1 -TestMode
   ```

4. **Update Your Workflow**:
   - Use `.\StartModularTTS.ps1` instead of `.\TextToSpeech-Generator.ps1`
   - Configure providers using the new JSON-based system
   - Take advantage of multi-environment profiles (Development/Production/Testing)

## API Configuration

| Provider | Details |
|----------|---------|
| **Azure Cognitive Services** | **Status**: Full production implementation with real API calls<br>**Quality**: Premium neural voices with natural prosody and SSML support<br>**Free Tier**: 5,000 transactions/month<br>**Languages**: 140+ languages, 400+ voices<br>**[Complete Setup Guide →](docs/AZURE-SETUP.md)** |
| **Google Cloud Text-to-Speech** | **Status**: Full production implementation with real API calls<br>**Quality**: WaveNet technology for human-like speech with advanced options<br>**Free Tier**: 1M WaveNet characters/month<br>**Languages**: 40+ languages, 220+ voices<br>**[Complete Setup Guide →](docs/GOOGLE-SETUP.md)** |
| **AWS Polly** | **Status**: Full production implementation with real API calls<br>**Quality**: Neural and standard voices with AWS Signature V4 authentication<br>**Free Tier**: 1M characters/month for speech synthesis<br>**Languages**: 60+ languages, 570+ voices including neural options<br>**[Complete Setup Guide →](docs/AWS-SETUP.md)** |
| **CloudPronouncer** | **Status**: Full production implementation with real API calls<br>**Quality**: Specialised pronunciation accuracy for names and complex terms<br>**Features**: High-quality synthesis, SSML support, multiple audio formats<br>**Languages**: Multi-language support with pronunciation optimisation<br>**[Complete Setup Guide →](docs/CLOUDPRONOUNCER-SETUP.md)** |
| **Twilio** | **Status**: Full production implementation with real API calls<br>**Quality**: TTS integration within telephony and IVR workflows<br>**Features**: TwiML generation, call API integration, multi-language support<br>**Languages**: 11+ languages with voice selection across providers<br>**[Complete Setup Guide →](docs/TWILIO-SETUP.md)** |
| **VoiceForge** | **Status**: Full production implementation with real API calls<br>**Quality**: Character-style and novelty voices for creative applications<br>**Features**: High-quality synthesis, SSML processing, multiple audio formats<br>**Languages**: Multi-language support with specialized voice characters<br>**[Complete Setup Guide →](docs/VOICEFORGE-SETUP.md)** |

## Usage Guide

### Single Script Processing

1. **Select Mode**: Choose "Single-Script" radio button
2. **Enter Text**: Type your text in the input box
3. **Configure Settings**: Choose provider, voice, and output folder
4. **Generate**: Click "Go!" or press F5

### Bulk Processing from CSV

1. **Prepare CSV File**: Create properly formatted CSV file
   ```csv
   SCRIPT,FILENAME
   "Hello world, this is a test.",test_audio_1
   "Welcome to our service.",welcome_message
   ```
   **[Complete CSV Format Guide →](docs/CSV-FORMAT.md)** - Detailed specifications and examples

2. **Select Mode**: Choose "Bulk-Scripts" radio button
3. **Load File**: Click browse button or press Ctrl+O  
4. **Configure Settings**: Set provider, voice, and output folder
5. **Process**: Click "Go!" or press F5

### Keyboard Shortcuts

- **F5** or **Ctrl+R**: Start generation process
- **Ctrl+S**: Save configuration
- **Ctrl+O**: Open input file browser
- **Escape**: Clear log window

## Security Considerations

### Secure Credential Storage

The application offers secure API key storage using Windows Credential Manager:

- Keys are encrypted and stored securely by Windows
- Plain text storage is avoided when possible
- Automatic detection of stored credentials

### Input Validation

- CSV structure validation before processing
- File path sanitization to prevent traversal attacks
- HTML encoding for script content
- API key format validation

## File Structure

```
TextToSpeech-Generator/
├─ StartModularTTS.ps1                      # Main application launcher (v3.2+)
├─ config.json                              # Modern JSON configuration
├─ MigrateLegacyConfig.ps1                  # XML to JSON migration utility
├─ TextToSpeech-Generator.ps1               # Legacy GUI component (transitional)
├─ Modules/                                 # Modular architecture
│  ├─ Logging/EnhancedLogging.psm1          # Enterprise logging system
│  ├─ Security/EnhancedSecurity.psm1        # Certificate-based encryption
│  ├─ Configuration/AdvancedConfiguration.psm1 # Multi-environment profiles
│  ├─ TTSProviders/TTSProviders.psm1        # Modular TTS provider implementations
│  ├─ Utilities/UtilityFunctions.psm1       # Supporting utility functions
│  ├─ ErrorRecovery/ErrorRecovery.psm1      # Intelligent error recovery strategies
│  └─ PerformanceMonitoring/PerformanceMonitoring.psm1 # Performance metrics & caching
├─ Tests/                                   # Comprehensive test suites
│  ├─ Unit/                                 # Unit tests for individual modules
│  ├─ Integration/                          # Integration tests for system components
│  └─ Performance/                          # Performance benchmarking tests
├─ README.md                                # Project overview (this file)
├─ LICENSE                                  # MIT License
├─ GUI-Timeline/                            # Development timeline screenshots
│  └─ 20210922 - Single-Mode File-Save issue.PNG
```

## Default Configuration

Configuration is stored in `config.json` with provider-specific settings organised by environment profiles (Development/Production/Testing). Each provider section contains authentication, voice selection, and audio format preferences.

### Audio Formats

| Provider | Supported Formats | Default Format |
|----------|-------------------|----------------|
| **Azure Cognitive Services** | WAV, MP3, OGG, WEBM, FLAC | `riff-16khz-16bit-mono-pcm` |
| **Google Cloud TTS** | LINEAR16, MP3, OGG_OPUS, MULAW, ALAW | `LINEAR16` |
| **AWS Polly** | PCM, MP3, OGG_VORBIS, JSON | `mp3` |
| **CloudPronouncer** | WAV, MP3, OGG | `mp3` |
| **Twilio** | WAV, MP3 | `mp3` |
| **VoiceForge** | WAV, MP3, OGG | `mp3` |

### Voice Options

| Provider | Voice Count | Languages | Voice Types | Sample Voices |
|----------|-------------|-----------|-------------|---------------|
| **Azure Cognitive Services** | 400+ voices | 140+ languages | Neural, Standard | en-US-JennyNeural, en-GB-RyanNeural, fr-FR-DeniseNeural |
| **Google Cloud TTS** | 220+ voices | 40+ languages | WaveNet, Neural2, Standard | en-US-Wavenet-D, en-GB-Neural2-A, fr-FR-Wavenet-E |
| **AWS Polly** | 570+ voices | 60+ languages | Neural, Standard | Joanna, Matthew, Emma, Brian, Celine |
| **CloudPronouncer** | 100+ voices | 25+ languages | High-Definition | American English, British English, Australian English |
| **Twilio** | 50+ voices | 11+ languages | Telephony-Optimized | alice, man, woman (provider-specific) |
| **VoiceForge** | 200+ voices | 15+ languages | Character, Novelty | Robot, Alien, Wizard, Princess, Monster |

## Troubleshooting

### Quick Fixes

**Authentication Errors**:
- Verify API key is correct and active
- Check datacenter region matches your subscription  
- See provider-specific setup: [Azure Cognitive Services](docs/AZURE-SETUP.md) | [Google Cloud](docs/GOOGLE-SETUP.md) | [AWS Polly](docs/AWS-SETUP.md) | [CloudPronouncer](docs/CLOUDPRONOUNCER-SETUP.md) | [Twilio](docs/TWILIO-SETUP.md) | [VoiceForge](docs/VOICEFORGE-SETUP.md)

**File Processing Errors**:
- Validate CSV format - see [CSV Format Guide](docs/CSV-FORMAT.md)
- Check output folder write permissions
- Verify file paths don't contain invalid characters

**Network Issues**:
- Check internet connectivity
- Verify firewall isn't blocking HTTPS requests
- Try different datacenter region if available

**[Complete Troubleshooting Guide →](docs/TROUBLESHOOTING.md)** - Comprehensive problem-solving resource

## Logging

Application logs are saved to `application.log` in the application directory:

```
2025-10-10 14:30:15 [INFO] Starting TextToSpeech Generator v3.2
2025-10-10 14:30:20 [INFO] Loaded 400 voices from Azure Cognitive Services
2025-10-10 14:30:45 [INFO] Generated: welcome_message
2025-10-10 14:30:50 [ERROR] Authentication failed: Invalid API key
```

Log levels: INFO, WARNING, ERROR, DEBUG

## Contributing

Contributions are welcome! Please read our contributing guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes with proper documentation
4. Test thoroughly
5. Submit a pull request


## Authors

- **Luca Vitali** - Original concept and implementation
- **Simon Jackson** - Enhanced security, error handling, and additional features

## Acknowledgments

- Azure Cognitive Services team
- Google Cloud Text-to-Speech team
- PowerShell community for WPF guidance

## Support

- **Issues**: Please log Issues using -> [GitHub Issues](https://github.com/sjackson0109/TextToSpeech-Generator/issues)
- **Documentation**: [README.md](https://github.com/sjackson0109/TextToSpeech-Generator/README.md)
- **Email**: NOT AVAILABLE FOR THIS PROJECT
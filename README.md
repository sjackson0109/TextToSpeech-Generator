# TextToSpeech Generator

A professional Windows GUI application for converting text to speech using Azure Cognitive Services and Google Cloud Text-to-Speech APIs. Features bulk processing from CSV files, secure credential storage, and enterprise-grade error handling.

![Version](https://img.shields.io/badge/version-v1.21-blue)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey)
![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## 🚀 Features

- **Multiple TTS Providers**: Azure Cognitive Services and Google Cloud TTS support
- **Bulk Processing**: Convert multiple scripts from CSV files
- **Single Script Mode**: Quick conversion of individual text snippets
- **Secure Storage**: Windows Credential Manager integration for API keys
- **Professional UI**: Modern WPF interface with comprehensive controls
- **Error Recovery**: Robust error handling with detailed logging
- **Input Validation**: Comprehensive validation and sanitization
- **Keyboard Shortcuts**: Productivity-focused hotkeys
- **Progress Tracking**: Real-time status updates and logging

## 📋 Requirements

- **Operating System**: Windows 10/11 or Windows Server 2016+
- **PowerShell**: Version 5.1 or higher
- **.NET Framework**: 4.7.2 or higher
- **API Access**: Valid API keys for chosen TTS provider(s)

## 🛠️ Installation

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
   .\TextToSpeech-Generator-v1.1.ps1
   ```

## 🔑 API Configuration

Choose your preferred TTS provider and follow the detailed setup guide:

### Azure Cognitive Services ✅ **Fully Supported**
- **Quality**: Premium neural voices with natural prosody
- **Free Tier**: 5,000 transactions/month
- **Languages**: 140+ languages, 400+ voices
- 📖 **[Complete Setup Guide →](docs/AZURE-SETUP.md)**

### Google Cloud Text-to-Speech ✅ **Fully Supported**  
- **Quality**: WaveNet technology for human-like speech
- **Free Tier**: 1M WaveNet characters/month
- **Languages**: 40+ languages, 220+ voices
- 📖 **[Complete Setup Guide →](docs/GOOGLE-SETUP.md)**

### AWS Polly ⏳ **Coming Soon**
- **Status**: Planned for v1.30 release
- **Features**: Neural voices, long-form content optimization
- 📖 **[Future Plans →](docs/AWS-SETUP.md)**

### Quick Setup Summary

For immediate use:
1. **Choose Provider**: Azure (recommended for beginners) or Google Cloud
2. **Get API Key**: Follow the provider-specific setup guide above
3. **Configure App**: Enter credentials in the application
4. **Test**: Try single script mode first

## 📖 Usage Guide

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
   📖 **[Complete CSV Format Guide →](docs/CSV-FORMAT.md)** - Detailed specifications and examples

2. **Select Mode**: Choose "Bulk-Scripts" radio button
3. **Load File**: Click browse button or press Ctrl+O  
4. **Configure Settings**: Set provider, voice, and output folder
5. **Process**: Click "Go!" or press F5

### Keyboard Shortcuts

- **F5** or **Ctrl+R**: Start generation process
- **Ctrl+S**: Save configuration
- **Ctrl+O**: Open input file browser
- **Escape**: Clear log window

## 🔒 Security Features

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

## 📁 File Structure

```
TextToSpeech-Generator/
├── TextToSpeech-Generator-v1.1.ps1    # Main application
├── TextToSpeech-Generator-v1.1.xml    # Configuration file
├── README.md                           # Project overview (this file)
├── CHANGELOG.md                        # Version history and migration guide
├── QUICKSTART.md                       # 5-minute setup guide
├── docs/                              # Comprehensive documentation
│   ├── API-SETUP.md                  # General API configuration
│   ├── AZURE-SETUP.md                 # Azure Cognitive Services setup
│   ├── GOOGLE-SETUP.md                # Google Cloud TTS setup
│   ├── AWS-SETUP.md                   # AWS Polly setup (future)
│   ├── TROUBLESHOOTING.md             # Problem-solving guide
│   └── CSV-FORMAT.md                  # CSV file format specification
├── examples/                          # Sample files and templates
│   ├── sample.csv                     # Example CSV input
│   └── sample-config.xml              # Example configuration
└── GUI-Timeline/                      # Development artifacts
    └── screenshots/
```

## ⚙️ Configuration

### Audio Formats (Azure)

| Format | Description | Use Case |
|--------|-------------|----------|
| `riff-16khz-16bit-mono-pcm` | High quality WAV | PSTN/Phone systems |
| `audio-16khz-32kbitrate-mono-mp3` | Compressed MP3 | SIP/VoIP systems |
| `audio-24khz-48kbitrate-mono-mp3` | Higher quality MP3 | General use |

### Voice Options

**Azure Voices**: 400+ neural voices in 140+ languages
**Google Voices**: Wavenet and Standard voices in 40+ languages

## 🐛 Troubleshooting

### Quick Fixes

**Authentication Errors**:
- Verify API key is correct and active
- Check datacenter region matches your subscription  
- See provider-specific setup: [Azure](docs/AZURE-SETUP.md) | [Google Cloud](docs/GOOGLE-SETUP.md)

**File Processing Errors**:
- Validate CSV format - see [CSV Format Guide](docs/CSV-FORMAT.md)
- Check output folder write permissions
- Verify file paths don't contain invalid characters

**Network Issues**:
- Check internet connectivity
- Verify firewall isn't blocking HTTPS requests
- Try different datacenter region if available

📖 **[Complete Troubleshooting Guide →](docs/TROUBLESHOOTING.md)** - Comprehensive problem-solving resource

## 📊 Logging

Application logs are saved to `application.log` in the application directory:

```
2025-10-10 14:30:15 [INFO] Starting TextToSpeech Generator v1.21
2025-10-10 14:30:20 [INFO] Loaded 187 voices from Azure
2025-10-10 14:30:45 [INFO] Generated: welcome_message
2025-10-10 14:30:50 [ERROR] Authentication failed: Invalid API key
```

Log levels: INFO, WARNING, ERROR, DEBUG

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes with proper documentation
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Luca Vitali** - Original concept and implementation
- **Simon Jackson** - Enhanced security, error handling, and additional features

## 🙏 Acknowledgments

- Microsoft Azure Cognitive Services team
- Google Cloud Text-to-Speech team
- PowerShell community for WPF guidance

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/sjackson0109/TextToSpeech-Generator/issues)
- **Documentation**: [Wiki](https://github.com/sjackson0109/TextToSpeech-Generator/wiki)
- **Email**: [Support](mailto:support@example.com)

---

**Quick Start**: Run `.\TextToSpeech-Generator-v1.1.ps1`, enter your API key, select a voice, type some text, choose output folder, and click "Go!" 🎵
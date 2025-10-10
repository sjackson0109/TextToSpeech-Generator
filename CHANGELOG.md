# Changelog

All notable changes to the TextToSpeech Generator project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.21] - 2025-10-10

### Added ✨
- **Secure Credential Storage**: Windows Credential Manager integration for API keys
- **Google Cloud TTS Bulk Processing**: Complete bulk processing support for Google Cloud TTS
- **Comprehensive Input Validation**: CSV structure validation, file path sanitization, API key format validation
- **Keyboard Shortcuts**: F5/Ctrl+R (Run), Ctrl+S (Save), Ctrl+O (Open), Escape (Clear log)
- **Enhanced Error Handling**: Robust error recovery with detailed logging
- **Progress Tracking**: Real-time status updates and validation feedback
- **API Key Format Validation**: Automatic validation of Azure and Google API key formats
- **File Permission Testing**: Automatic write permission validation for output folders
- **Enhanced Tooltips**: Detailed help messages with TTS best practices
- **Application Logging**: Structured logging to application.log file
- **Rate Limiting Protection**: Automatic delays to prevent API rate limiting

### Changed 🔄
- **Security**: API keys can now be stored securely instead of plain text
- **Error Messages**: More descriptive and actionable error messages
- **UI Responsiveness**: Better feedback during file selection and validation
- **Token Management**: Improved OAuth token handling with expiration tracking
- **File Handling**: Safer file path construction using Join-Path
- **Input Sanitization**: HTML encoding and filename sanitization for security

### Fixed 🐛
- **Control Name Bug**: Fixed inconsistent XAML control names (Key vs KeyKey)
- **Authentication Issues**: Better token refresh and error handling
- **CSV Processing**: Fixed path traversal vulnerability in filename handling
- **Memory Leaks**: Proper cleanup of temporary files and resources
- **Network Timeouts**: Added timeouts to prevent hanging on network issues
- **Provider Selection**: Fixed radio button logic for TTS provider switching

### Security 🔒
- **Path Traversal Protection**: Sanitized filenames prevent directory traversal attacks
- **Input Validation**: All user inputs are validated and sanitized
- **Credential Security**: Option to store API keys in Windows Credential Manager
- **HTML Encoding**: Script content is properly encoded to prevent injection

### Deprecated ⚠️
- Plain text API key storage (will show warning, secure storage recommended)

### Removed ❌
- Duplicate assembly loading that could cause conflicts

## [v1.10] - 2021-09-22

### Added
- Single script processing mode
- CSV bulk processing mode
- Basic Azure Cognitive Services TTS integration
- Simple GUI with file selection
- Basic configuration saving

### Known Issues
- Single-mode file save issue (see GUI-Timeline/20210922 - Single-Mode File-Save issue.PNG)

## [v1.05] - 2021-09-08

### Added
- CSV file import functionality
- Bulk processing capabilities
- Basic error handling

## [v1.00] - 2019-09-02

### Added
- Initial version
- Basic TTS functionality
- Single script processing
- Azure Cognitive Services integration

---

## Migration Guide

### Upgrading from v1.10 to v1.21

1. **Backup your configuration**: Copy your existing `.xml` config file
2. **API Key Security**: You'll be prompted to store your API key securely
3. **CSV Files**: Existing CSV files are compatible, but validation is now stricter
4. **New Features**: Take advantage of keyboard shortcuts and enhanced error handling

### Breaking Changes

- **None**: v1.21 is fully backward compatible with v1.10 configurations
- **Enhanced Validation**: Some previously accepted invalid CSV files may now be rejected

### Security Recommendations

1. **Enable Secure Storage**: Allow the application to store your API key securely
2. **Update Permissions**: Ensure output folders have proper write permissions
3. **Review Logs**: Check application.log for any security warnings

---

## Planned Features (Roadmap)

### v1.30 (Next Release)
- [ ] AWS Polly TTS integration
- [ ] Twilio TTS support  
- [ ] Voice sample preview
- [ ] Batch job queuing
- [ ] Performance monitoring

### v1.40 (Future)
- [ ] Cloud Pronouncer TTS integration
- [ ] Voice Forge TTS support
- [ ] Multi-language support in UI
- [ ] Advanced audio processing options
- [ ] RESTful API interface

### v2.00 (Major Release)
- [ ] Complete UI redesign
- [ ] Plugin architecture for TTS providers
- [ ] Database storage for configurations
- [ ] Multi-user support
- [ ] Web interface option

---

## Support Policy

- **Current Release (v1.21)**: Full support with regular updates
- **Previous Release (v1.10)**: Security updates only
- **Legacy Releases (v1.05 and earlier)**: No longer supported

For support, please file an issue on [GitHub](https://github.com/sjackson0109/TextToSpeech-Generator/issues).
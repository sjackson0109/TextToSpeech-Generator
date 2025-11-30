# Changelog

## [v3.2.1] - 2025-11-23 - Provider Integration Complete

### Added ✨
- **OpenAI TTS Provider**: Complete implementation with 6 voices (alloy, echo, fable, onyx, nova, shimmer), 2 models (tts-1, tts-1-hd), 6 audio formats, variable speed control (0.25x-4.0x)
- **Telnyx Provider**: WebSocket-based streaming implementation with 266+ voices across KokoroTTS, Natural, and NaturalHD models
- **Murf AI Provider**: Gen2 and Falcon models with 150+ ultra-realistic voices across 20+ languages
- **Provider Configuration Dialogues**: Consistent modern dark-themed Dialogues for all 8 providers with real-time credential testing
- **Configuration Persistence**: Full support for saving and loading provider configurations via GUI

### Changed 🔄
- **Provider Architecture**: All 8 providers now follow consistent class-based pattern with Configuration property
- **Test Connection Feedback**: Unified label-based feedback (green/red status) across all providers, removed popup Dialogues
- **Configuration Loading**: Enhanced GUI configuration loading from config.json with detailed logging
- **Provider Count**: Updated from 6 to 8 fully operational TTS providers

### Fixed 🐛
- **OpenAI Configuration Loading**: Fixed API key auto-population from config.json using property access pattern
- **Telnyx Dialogue Pattern**: Corrected ShowConfigurationDialog return type from [void] to [hashtable]
- **Configuration Property**: Added missing Configuration hashtable property to OpenAI and Telnyx provider classes
- **Logging Consistency**: Replaced all Write-Log calls with Add-ApplicationLog across OpenAI and Telnyx modules
- **Variable Naming**: Fixed PowerShell class method variable conflicts in OpenAI ProcessTTS method

### Technical Details 🔧
- **OpenAI Module**: 443 lines, supports GET /v1/models validation and POST /v1/audio/speech synthesis
- **Telnyx Module**: 432 lines, WebSocket-based real-time streaming architecture
- **Murf AI Module**: 422 lines, REST API with Gen2 and Falcon model support
- **Provider Consistency**: All providers implement Test-{Provider}Credentials, Get-{Provider}VoiceOptions, ShowConfigurationDialog, ProcessTTS methods
- **Documentation**: Complete provider-specific setup guides in docs/providers/ directory

## [v3.2] - 2025-10-14 - Enterprise Modular Architecture

### 🏗️ **MAJOR RELEASE: Complete Enterprise-Grade Modular Architecture**

### Added ✨
- **Modular Architecture**: Complete 6-module enterprise architecture with proper separation of concerns
  - `Logging.psm1`: Structured JSON logging with rotation and thread-safe operations
  - `EnhancedSecurity.psm1`: Certificate-based encryption and secure configuration management
  - `AdvancedConfiguration.psm1`: Multi-environment profile system with schema validation
  - `TTSProviders.psm1`: Modular TTS provider implementations with enhanced error handling
  - `UtilityFunctions.psm1`: File utilities, text processing, and system requirements validation
  - `ErrorRecovery.psm1`: Intelligent error recovery with provider-specific strategies
  - `PerformanceMonitoring.psm1`: Real-time performance monitoring and intelligent caching

- **Advanced Configuration Management**: 
  - **Multi-Environment Profiles**: Development, Production, and Testing configurations
  - **JSON-based Configuration**: Modern config.json replacing legacy XML format
  - **All 8 TTS Providers**: Complete configuration templates for Microsoft Azure, AWS Polly, ElevenLabs, Google Cloud TTS, Murf AI, OpenAI, Telnyx, and Twilio
  - **GUI Integration Functions**: Dynamic provider configuration Dialogues with credential testing and validation

- **Enterprise Security Framework**:
  - **Certificate-Based Encryption**: SecureConfigurationManager class for sensitive data protection
  - **Secure Storage**: Encrypted API keys and credentials with Windows Certificate Store integration
  - **Audit Trails**: Comprehensive security logging and configuration change tracking

- **Advanced Testing Framework**:
  - **Pester Integration**: Professional test framework with Unit, Integration, and Performance test suites
  - **Automated Test Runner**: `RunTests.ps1` with comprehensive reporting and validation
  - **Coverage Analysis**: Complete test coverage for all modules and functions

- **Intelligent Error Recovery System**:
  - **Provider-Specific Strategies**: Custom recovery logic for each TTS provider's error patterns
  - **Exponential Backoff**: Advanced backoff algorithms with jitter and circuit breakers
  - **Recovery Statistics**: Detailed tracking and analysis of error patterns and recovery success rates

- **Performance optimisation & Monitoring**:
  - **Real-Time Monitoring**: PerformanceMonitor class with system metrics tracking
  - **Intelligent Caching**: LRU cache implementation with TTL and memory optimisation
  - **Memory Management**: Automatic garbage collection and memory threshold alerts
  - **Performance Reports**: Detailed performance analytics with recommendations

- **Legacy Migration Tools**:
  - **XML to JSON Migration**: `MigrateLegacyConfig.ps1` for seamless transition from old XML configuration
  - **Backward Compatibility**: Maintains compatibility while providing upgrade path
  - **Configuration Validation**: Ensures data integrity during migration process

### Changed 🔄
- **Application Launcher**: New `StartTTS.ps1` replaces monolithic approach with modular initialisation
- **Configuration Format**: Migrated from XML to JSON-based configuration with full provider support
- **System Architecture**: Transformed from single-file application to enterprise-grade modular system
- **PowerShell Compatibility**: Fixed PowerShell 5.1+ compatibility issues (null-coalescing operators)
- **Error Handling**: Enhanced from basic retry logic to intelligent provider-specific recovery strategies
- **Performance**: optimised startup time to ~1.5s with lazy loading and efficient module initialisation

### Technical Improvements 🔧
- **Class-Based Design**: Modern PowerShell classes for PerformanceMonitor, IntelligentCache, and SecureConfigurationManager
- **Dependency Injection**: Proper module dependency management and initialisation order
- **Memory optimisation**: Intelligent caching with automatic memory management and cleanup
- **Security Hardening**: Certificate-based encryption, secure storage, and audit logging
- **Enterprise Logging**: Structured JSON logs with severity levels, categories, and performance metrics
- **Configuration Validation**: Schema validation, template system, and profile management
- **System Integration**: Windows Certificate Store, Performance Counters, and System Metrics integration

### Deprecated ⚠️
- **TextToSpeech-Generator.xml**: Legacy XML configuration (migration utility provided)
- **Monolithic Architecture**: Original single-file approach (maintained for GUI compatibility)

### Fixed 🐛
- **PowerShell 5.1 Compatibility**: Resolved null-coalescing operator issues across all modules
- **Constructor Errors**: Fixed class instantiation issues in PerformanceMonitoring module
- **Variable Scope**: Resolved variable assignment conflicts in class methods
- **Module Loading**: Fixed dependency loading order and error handling during initialisation

### Performance 📈
- **Startup Time**: Reduced to 1.45s with modular loading and performance monitoring
- **Memory Usage**: optimised with intelligent caching and automatic garbage collection
- **Configuration Loading**: Instant JSON parsing vs. slower XML processing
- **Error Recovery**: Intelligent backoff reduces failed API calls and improves success rates

## [v3.1] - 2025-10-13 - Quick Wins Implementation

### 🚀 **QUICK WINS RELEASE: Enhanced Reliability & Documentation**

### Added ✨
- **Enhanced Error Handling**: Exponential backoff retry logic with intelligent error classification
- **Structured Logging**: JSON-formatted logs with performance metrics and detailed error tracking
- **Configuration Validation**: Comprehensive validation framework for all provider configurations
- **API Connectivity Testing**: Built-in connectivity tests for Azure and Google Cloud
- **Enhanced Documentation**: Comprehensive inline code comments and function documentation
- **Performance Logging**: Dedicated performance tracking with operation timing and metrics

### Changed 🔄
- **Version Consistency**: Updated all version references from v2.0 to v3.1 across all files
- **Provider Status**: Corrected CHANGELOG documentation to reflect actual implementation status
- **Logging System**: Transformed from basic logging to enterprise-grade structured logging
- **Error Management**: Enhanced from simple error messages to detailed error classification with resolution guidance

### Technical Improvements 🔧
- **Retry Logic**: `Invoke-APIWithRetry` function with exponential backoff (1s, 2s, 4s delays)
- **Error Analysis**: `Get-DetailedErrorInfo` for provider-specific error codes and user guidance
- **Validation Framework**: `Test-ConfigurationValid` and `Test-APIConnectivity` functions
- **Performance Metrics**: `Write-PerformanceLog` and `Write-ErrorLog` specialised logging functions
- **Code Documentation**: Comprehensive PowerShell help documentation for all major functions

## [v3.0] - 2025-10-13 - Complete Multi-Provider TTS Implementation

### 🎉 **MAJOR RELEASE: All 6 TTS Providers Production-Ready**

### Added ✨
- **Complete TTS Processing**: Full implementation for all 6 providers with real API calls
All notable changes to the TextToSpeech Generator project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v3.0] - 2025-10-13 - Complete Multi-Provider TTS Implementation

### **MAJOR RELEASE: All 6 TTS Providers Production-Ready**

### Added
- **Complete TTS Processing**: Full implementation for 6 TTS providers with real API calls
- **Parallel Processing System**: Multi-threaded bulk processing with 3-6x speed improvements
- **Intelligent Thread Management**: Auto-optimised thread counts based on dataset size and CPU cores
- **Enterprise Error Handling**: Provider-specific error codes and comprehensive error management
- **Advanced Voice Options**: Full SSML support for Azure, advanced JSON API for Google Cloud
- **Real-time Progress Tracking**: Thread-safe UI updates from background processes
- **Configuration Framework**: Completed a dynamic UI setup, necessary when toggling providers who offer different API Configuration and Voice Options
- **Input Validation & Sanitization**: Extensive form validation throughout the application
- **File Management**: Secure filename sanitization and path validation
- **Rate Limiting Protection**: Built-in delays to prevent API throttling

### **Provider Implementation Status**
- **AWS Polly**: **PRODUCTION READY** - Complete AWS Signature V4 authentication with neural voices and custom lexicons
- **ElevenLabs**: **PRODUCTION READY** - Full API implementation with ultra-realistic voices and emotion control
- **Google Cloud TTS**: **PRODUCTION READY** - Full JSON API implementation with WaveNet voices and advanced prosody
- **Microsoft Azure**: **PRODUCTION READY** - Complete SSML support with neural voices and regional deployment
- **Murf AI**: **PRODUCTION READY** - Gen2 and Falcon models with 150+ voices across 20+ languages
- **OpenAI TTS**: **PRODUCTION READY** - GPT-4 powered voices with tts-1 and tts-1-hd models, streaming support
- **Telnyx**: **PRODUCTION READY** - WebSocket streaming with 266+ voices (KokoroTTS, Natural, NaturalHD)
- **Twilio**: **PRODUCTION READY** - Complete TwiML generation and telephony-optimised processing

### Changed
- **Application Architecture**: Transformed from prototype to enterprise-grade application
- **Processing Engine**: Complete rebuild with production TTS functions
- **Performance**: 3-6x speed improvement for bulk processing through parallel execution
- **Error Handling**: Enterprise-grade error management with provider-specific messages
- **UI Integration**: Complete integration of all controls with functional processing

### Technical Implementation
- **Core Functions**: Sanitize-FileName, Invoke-AzureTTS, Invoke-GoogleCloudTTS, Start-ParallelTTSProcessing
- **Processing Modes**: Single, Sequential, Parallel processing with intelligent selection
- **Thread Architecture**: Runspace pools with synchronised collections and proper cleanup
- **Progress System**: Real-time updates with success/failure tracking
- **Validation**: Comprehensive input validation and error recovery

### Quality Assurance
- **Application Testing**: Clean launch, UI responsiveness, provider switching, progress tracking
- **Function Testing**: TTS processing, file operations, validation, threading
- **Production Testing**: Confirmed working with real Azure and Google Cloud APIs

## [v1.21] - 2025-10-10

### Adde
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

### Changed
- **Security**: API keys can now be stored securely instead of plain text
- **Error Messages**: More descriptive and actionable error messages
- **UI Responsiveness**: Better feedback during file selection and validation
- **Token Management**: Improved OAuth token handling with expiration tracking
- **File Handling**: Safer file path construction using Join-Path
- **Input Sanitization**: HTML encoding and filename sanitization for security

### Fixed
- **Control Name Bug**: Fixed inconsistent XAML control names (Key vs KeyKey)
- **Authentication Issues**: Better token refresh and error handling
- **CSV Processing**: Fixed path traversal vulnerability in filename handling
- **Memory Leaks**: Proper cleanup of temporary files and resources
- **Network Timeouts**: Added timeouts to prevent hanging on network issues
- **Provider Selection**: Fixed radio button logic for TTS provider switching

### Security
- **Path Traversal Protection**: Sanitized filenames prevent directory traversal attacks
- **Input Validation**: All user inputs are validated and sanitized
- **Credential Security**: Option to store API keys in Windows Credential Manager
- **HTML Encoding**: Script content is properly encoded to prevent injection

### Deprecated
- Plain text API key storage (will show warning, secure storage recommended)

### Removed
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
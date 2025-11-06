# Copilot Instructions for TextToSpeech-Generator
## Overview
TextToSpeech-Generator is a PowerShell-based application that converts text to speech using multiple TTS providers. It supports single and bulk text processing, with a modular architecture for easy extension and maintenance.   Write clear, concise, and context-aware code snippets, explanations, and instructions to help users understand and utilise the application effectively; supporting a plug-in architecture, written in UK English (not US english), and adhering to best practices writing in powershell v5.1 and v7+ compatible code syntax. Never write with code placeholders, always provide complete and valid, working code.

## Key Features
- **Configuration management:** JSON-based config files with profile support
- **GUI & CLI:** User-friendly GUI and command-line interface for flexibility
- **Modular architecture:** Each provider in its own module for easy addition/removal
- **Multiple TTS providers:** Azure, AWS, Google, Twilio, VoiceForge, VoiceWave
- **Error handling:** Robust, provider-specific error handling and recovery
- **Bulk processing:** Prepare CSV as per `docs/CSV-FORMAT.md`, process via GUI or script
- **Debugging:** Check `application.log` for INFO/WARNING/ERROR/DEBUG entries

## Patterns & Conventions
- **Provider integration:** Each TTS provider is implemented in its own module under `Modules/TTSProviders/` with provider-specific error handling and configuration
- **Security:** API keys stored via Windows Credential Manager, certificate-based encryption in `Modules/Security/EnhancedSecurity.psm1`
- **Logging:** Centralized in `Modules/Logging/Logging.psm1`, logs to `application.log` with standardized levels
- **Error recovery:** Intelligent, provider-specific strategies in `Modules/ErrorRecovery/`
- **Performance:** Real-time metrics and caching in `Modules/PerformanceMonitoring/`
- **Testing:** Pester-based test suites in `Tests/` (see `RunTests.ps1` for orchestration)
- **UI:** Modern GUI in `Modules/GUI/ModernGUI.psm1`, supports keyboard shortcuts (F5, Ctrl+R, Ctrl+S, Ctrl+O, Escape)

## Integration Points
- **External APIs:** Azure, AWS, Google, Twilio, VoiceForge (see `docs/*-SETUP.md` for each)
- **CSV input:** Bulk processing via CSV, validated and sanitized before use
- **Credential storage:** Windows Credential Manager, never store plain text keys

## Key Files & Directories
- `StartTTS.ps1` — main entry point
- `Modules/` — all core logic, organized by concern
- `Default.json` / `config.json` — main configuration
- `application.log` — runtime logs
- `Tests/` — all test scripts
- `docs/` — setup guides, troubleshooting, CSV format

## Example: Adding a New TTS Provider
1. Create a new module in `Modules/TTSProviders/`
2. Implement provider logic, error handling, and configuration parsing
3. Update configuration schema in `Default.json`
4. Add tests in `Tests/Unit/` and integration scripts in `Tests/Integration/`
5. Document setup in `docs/`

## References
- See `README.md` for full overview and workflow details
- See `docs/` for provider setup and troubleshooting

---
**Feedback:** If any section is unclear or missing, please specify so it can be improved for future AI agents.

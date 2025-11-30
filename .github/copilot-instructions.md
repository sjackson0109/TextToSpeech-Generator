# Copilot Instructions for TextToSpeech-Generator
## Overview
TextToSpeech-Generator is a PowerShell-based application that converts text to speech using multiple TTS providers. It supports single and bulk text processing, with a modular architecture for easy extension and maintenance. Write clear, concise, and context-aware code snippets, explanations, and instructions to help users understand and utilise the application effectively; supporting a plug-in architecture, written in UK English (not US English), and adhering to best practices writing in PowerShell v5.1 and v7+ compatible code syntax. Never write with code placeholders, always provide complete and valid, working code.

## Current Status (v3.2.1 - 2025-11-23)
- **8 Production-Ready TTS Providers:** AWS Polly, ElevenLabs, Google Cloud, Microsoft Azure, Murf AI, OpenAI, Telnyx, Twilio
- **Core Infrastructure Complete:** Provider dropdown selection, configuration Dialogues, credential testing, save/cancel operations all operational
- **Dynamic Voice Options - Phase 1 Complete:** OpenAI fully implemented with live API retrieval, caching, and advanced Dialogue
- **Dynamic Voice Options - Phase 2 In Progress:** ElevenLabs updated with API-based voice retrieval pattern
- **GUI Framework:** Modern dark-themed WPF GUI with real-time validation and colour-coded feedback
- **Configuration System:** JSON-based config with provider-specific settings, Windows Credential Manager integration
- **All providers follow consistent patterns:** Test-{Provider}Credentials, Get-{Provider}VoiceOptions, {Provider}TTSProvider class, ShowConfigurationDialog

## Key Features
- **Configuration management:** JSON-based config files with profile support (Default.json, config.json)
- **GUI & CLI:** User-friendly WPF GUI (Modules/GUI.psm1) and command-line interface for flexibility
- **Modular architecture:** Each provider in its own module under `Modules/Providers/` for easy addition/removal
- **8 TTS providers:** AWS Polly, ElevenLabs, Google Cloud, Microsoft Azure, Murf AI, OpenAI, Telnyx, Twilio
- **Error handling:** Robust, provider-specific error handling with Add-ApplicationLog integration
- **Bulk processing:** Prepare CSV as per `docs/CSV-FORMAT.md`, process via GUI or script
- **Debugging:** Check `application.log` for INFO/WARNING/ERROR/DEBUG entries
- **Real-time validation:** Test Connection buttons with colour-coded label feedback (green/red/yellow)

## Patterns & Conventions
- **Provider integration:** Each TTS provider module must implement:
  - `Test-{Provider}Credentials` function returning boolean
  - `Get-{Provider}VoiceOptions` function returning hashtable with Voices, Models, Formats, etc.
  - `{Provider}TTSProvider` class with [hashtable]$Configuration property
  - `ShowConfigurationDialog([hashtable]$CurrentConfig)` method returning [hashtable] (NOT [void])
  - `ProcessTTS([string]$text, [string]$outputPath)` method for audio generation
  - `New-{Provider}TTSProviderInstance` factory function
- **Configuration loading:** Use simple property access ($CurrentConfig.ApiKey) NOT .ContainsKey() which fails with PSCustomObject-to-hashtable conversions
- **Logging:** Use Add-ApplicationLog -Module "ProviderName" -Message "text" -Level "INFO/ERROR/DEBUG" (Write-Log does not exist)
- **Test button pattern:** Update TestStatus label with colours (#FF28A745 green, #FFFF0000 red, #FFFFFF00 yellow), NO MessageBox popups
- **Event handlers:** Use .GetNewClosure() on click handlers referencing outer scope variables
- **Security:** API keys stored via Windows Credential Manager, certificate-based encryption in `Modules/Security.psm1`
- **Error recovery:** Intelligent, provider-specific strategies in `Modules/ErrorRecovery.psm1`
- **Performance:** Real-time metrics and caching in `Modules/Performance.psm1`
- **Testing:** Pester-based test suites in `Tests/` (see `RunTests.ps1` for orchestration)
- **GUI:** Modern WPF GUI in `Modules/GUI.psm1`, supports keyboard shortcuts (F5, Ctrl+R, Ctrl+S, Ctrl+O, Escape)

## Integration Points
- **External APIs:** 8 providers - AWS Polly, ElevenLabs, Google Cloud, Microsoft Azure, Murf AI, OpenAI, Telnyx, Twilio (see `docs/providers/*.md` for each)
- **CSV input:** Bulk processing via CSV, validated and sanitised before use
- **Credential storage:** Windows Credential Manager, never store plain text keys
- **Dynamic voice options:** All dropdowns populated from live API responses, NO hardcoded values

## Key Files & Directories
- `StartTTS.ps1` — main entry point
- `Modules/GUI.psm1` — main WPF GUI (1529 lines), ShowProviderConfigurationDialog, voice selection interface
- `Modules/Providers.psm1` — provider factory and management
- `Modules/Providers/*.psm1` — individual TTS provider implementations (AWS Polly, ElevenLabs, Google Cloud, Microsoft Azure, Murf AI, OpenAI, Telnyx, Twilio)
- `Default.json` — default configuration schema with 3 profiles (Default, Production, Testing)
- `config.json` — active runtime configuration with API keys
- `application.log` — runtime logs with INFO/WARNING/ERROR/DEBUG levels
- `Tests/` — Pester test scripts (Unit, Integration, Performance)
- `docs/providers/` — setup guides for each TTS provider
- `docs/CSV-FORMAT.md` — bulk processing CSV format specification

## Current Development Objectives (Next Phase)

### Objective 1: Dynamic Voice Options Retrieval
**Ensure each TTS provider can use the connected session to:**
- Retrieve all voices available for the given API session via live API call
- Retrieve languages, quality, speed, and any other **common** configuration parameters from the API
- Retrieve **advanced** or **specialist** options, their supported values, and default values from the remote API
- **Implementation requirement:** Each provider's `Get-{Provider}VoiceOptions` must make live API calls, NOT return hardcoded data
- **Caching strategy:** Cache API responses for session duration to avoid excessive API calls
- **Error handling:** Gracefully handle API failures, provide fallback behaviour

### Objective 2: Dynamic GUI Population (NO Hardcoded Dropdowns)
**Update the voice selection interface for each provider to ONLY render data returned from the TTS provider's API:**
- **DO NOT PRE-CONFIGURE OR PRE-POPULATE ANY DROPDOWNS** in GUI.psm1 or provider modules
- **EVERY label/dropdown/checkbox/radio button MUST come from the common voice options** returned by `Get-{Provider}VoiceOptions`
- Dropdowns for: Voice selection, Language selection, Quality/Model selection, Speed selection, Format selection
- When user changes options and clicks **Save** (top right of main GUI form), selected options must be saved to config.json for the given TTS provider
- **Configuration persistence:** Selected voice, language, quality, speed, format saved per provider in config.json
- **Load behaviour:** On provider selection, load saved options from config.json and populate dropdowns from API, then select saved values

### Objective 3: Advanced Voice Options Dialogue
**The ADVANCED button should open an Advanced Voice Options form:**
- Call a new `ShowAdvancedVoiceDialog([hashtable]$CurrentConfig)` method on the selected provider
- Populate GUI with **advanced** or **specialist** voice options from the chosen TTS provider
- Use horizontal sliders or vertical sliders for continuous parameters (e.g., pitch, speaking rate, volume gain)
- Use appropriate controls (sliders, dropdowns, checkboxes) based on parameter type
- **Save-And-Close** button must save these advanced options to config.json under the provider's configuration
- Advanced options should be provider-specific (e.g., SSML support for Azure, emotional range for ElevenLabs, stability/similarity for voices)
- **Dialogue pattern:** Return [hashtable] with advanced settings, integrate with main configuration save workflow

## Example: Adding Dynamic Voice Retrieval to a Provider
1. Modify `Get-{Provider}VoiceOptions` to make live API call (e.g., GET /v1/voices for OpenAI)
2. Parse API response into standardised hashtable: @{Voices=@(...); Languages=@(...); Models=@(...); Formats=@(...); Speeds=@(...)}
3. Cache result in provider instance for session duration
4. Update GUI.psm1 to call `Get-{Provider}VoiceOptions` when provider selected
5. Populate dropdowns dynamically from returned hashtable
6. Implement Save handler to persist selected values to config.json
7. Implement Load handler to restore saved values when provider re-selected

## Example: Implementing Advanced Voice Dialogue
1. Create `ShowAdvancedVoiceDialog([hashtable]$CurrentConfig)` method in provider class
2. Build WPF Dialogue with provider-specific advanced controls
3. Load current advanced settings from $CurrentConfig
4. Provide sliders/controls for parameters like pitch, rate, volume, stability, emotional range
5. Implement Save-And-Close to return [hashtable] with advanced settings
6. Integrate returned hashtable into main config save workflow
7. Update config.json schema to support advanced options per provider

## References
- See `README.md` for full overview and workflow details
- See `docs/providers/*.md` for provider-specific setup and API documentation
- See `docs/CSV-FORMAT.md` for bulk processing CSV structure
- See `docs/TROUBLESHOOTING.md` for common issues and solutions
- See `CHANGELOG.md` for version history and implementation status

## Technical Debt & Known Limitations
- **Hardcoded voice options:** Current implementations return static voice lists from `Get-{Provider}VoiceOptions`, need to implement live API calls
- **Static GUI dropdowns:** Voice/language/quality dropdowns currently populate from hardcoded values, need dynamic population
- **No advanced voice controls:** Missing provider-specific advanced settings Dialogues (SSML, emotional parameters, prosody controls)
- **Configuration schema:** Need to extend config.json to support per-provider voice selections and advanced options
- **API caching:** No session-level caching of voice options, potential for excessive API calls

## Development Workflow Best Practices
- **Always test credential validation** before implementing voice retrieval
- **Use Add-ApplicationLog extensively** for debugging API calls and GUI operations
- **Follow the existing provider pattern** - consistency across all 8 providers is critical
- **Handle API errors gracefully** - network issues, rate limits, invalid responses
- **Validate user input** before saving to config.json
- **Use colour-coded feedback** for user actions (green success, red error, yellow in-progress)
- **Cache API responses** to minimise external API calls during a session
- **Document provider-specific quirks** in docs/providers/*.md files

## Code Quality Standards
- **PowerShell v5.1 and v7+ compatibility** - test on both versions
- **UK English spelling** in all user-facing strings and documentation
- **Complete implementations only** - never use placeholders like "...existing code..." or "// TODO"
- **Comprehensive error handling** - every external API call must have try/catch
- **Consistent naming conventions** - PascalCase for functions, camelCase for variables, kebab-case for file names
- **XML comments** for all exported functions with .SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE
- **Type annotations** - use [string], [hashtable], [boolean], [int] etc. explicitly

---
**Feedback:** If any section is unclear or missing, please specify so it can be improved for future AI agents.

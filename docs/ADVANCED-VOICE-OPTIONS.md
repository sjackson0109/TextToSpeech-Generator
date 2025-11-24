# Advanced Voice Options - Implementation Guide

**Version:** 3.2.1  
**Last Updated:** 2025-11-23  
**Status:** Default.json Schema Updated, OpenAI ShowAdvancedVoiceDialog Complete, Voice Library Expanded

## Recent Updates (2025-11-23)

### ✅ Format Removed from Advanced Options
- **Format (MP3/WAV/FLAC) is NOT an advanced option** - it's a basic output selection
- Removed Format dropdown from OpenAI `ShowAdvancedVoiceDialog`
- Updated Default.json to remove Format from all provider AdvancedOptions schemas
- Format now only appears in main GUI dropdowns alongside Voice/Language/Quality

### ✅ Voice Library Expansion
Significantly expanded voice selections across all 8 providers:
- **Microsoft Azure**: 11 → **38 voices** (+245%)
- **AWS Polly**: 20 → **63 voices** (+215%)
- **ElevenLabs**: 9 → **35 voices** (+289%)
- **Google Cloud**: 13 → **50 voices** (+285%)
- **Murf AI**: 10 → **36 voices** (+260%)
- **Telnyx**: 10 → **33 voices** (+230%)
- **Twilio**: 18 → **40 voices** (+122%)
- **OpenAI**: 6 voices (complete set)

### ✅ GUI Enhancement - Quality/Model Intelligence
- Updated `Modules/GUI.psm1` to handle both `Quality` and `Models` attributes
- OpenAI & Telnyx now show Models (tts-1, tts-1-hd, KokoroTTS, Natural, NaturalHD)
- All other providers show Quality (Neural, High, Standard, etc.)
- Dropdown label remains "Quality" but adapts content based on provider

## Overview

This document defines the **Advanced Voice Options** for all 8 TTS providers. Advanced options control **HOW the voice speaks** (vocal parameters), NOT basic selections like which voice/language/format/quality to use.

## Architectural Principle

### What IS Advanced
Vocal parameters that modify speech characteristics:
- **Prosody Controls**: Speed, pitch, rate, volume
- **Voice Characteristics**: Stability, tone, emphasis, style
- **Technical Audio**: Sample rate, channels, effects profiles
- **SSML Features**: Lexicons, breaks, phonemes, markup support

### What is NOT Advanced
Basic dropdown selections that choose WHAT to use:
- ❌ **Voice Selection**: Which voice to use (alloy, Rachel, Joanna, etc.)
- ❌ **Language Selection**: Which language/locale (en-US, fr-FR, etc.)
- ❌ **Format Selection**: Output file format (MP3, WAV, FLAC, etc.)
- ❌ **Quality/Model**: Which quality tier to use (tts-1, tts-1-hd, Neural, etc.)

These are **basic dropdowns** in the main GUI, NOT advanced options.

---

## Provider-Specific Advanced Options

### 1. OpenAI

**AdvancedOptions Schema:**
```json
{
  "Model": "tts-1-hd",
  "Speed": 1.0
}
```

**Controls:**
- **Speed**: Slider 0.25-4.0x (playback rate)
  - 0.25x = Very slow
  - 1.0x = Normal speed (default)
  - 4.0x = Very fast
  - Snap-to-tick: 0.25 increments
- **Model**: Dropdown (tts-1, tts-1-hd)
  - tts-1: Standard quality, faster, $15/1M chars
  - tts-1-hd: High definition, premium, $30/1M chars

**ShowAdvancedVoiceDialog Status:** ✅ Complete (Format removed, window height reduced to 420px)

**Implementation Details:**
- Speed slider: 0.25-4.0x with snap-to-tick (0.25 increments)
- Model dropdown: tts-1, tts-1-hd (shown in Quality dropdown in main GUI)
- Format dropdown: **REMOVED** - now in main GUI basic dropdowns
- Returns hashtable: `@{ Success = $true; Speed = 1.5; Model = "tts-1-hd" }`

**API Limitations:**
- No SSML support (text only)
- No pitch/volume control
- Multi-language auto-detection
- 4,096 character limit per request

---

### 2. ElevenLabs

**AdvancedOptions Schema:**
```json
{
  "Model": "eleven_multilingual_v2",
  "Stability": 0.5,
  "SimilarityBoost": 0.75,
  "EnableSSML": false
}
```

**Controls:**
- **Stability**: Slider 0.0-1.0 (emotional consistency vs expressiveness)
  - 0.0 = More variable and expressive
  - 0.5 = Balanced (default)
  - 1.0 = More stable and consistent
- **Similarity Boost**: Slider 0.0-1.0 (voice similarity to original)
  - 0.0 = More creative interpretation
  - 0.75 = High similarity (default)
  - 1.0 = Maximum similarity to reference voice
- **Enable SSML**: Checkbox (Advanced prosody markup control)
- **Model**: Dropdown (eleven_monolingual_v1, eleven_multilingual_v1, eleven_multilingual_v2)

**ShowAdvancedVoiceDialog Status:** ⏸️ Pending Implementation

**API Features:**
- SSML support for prosody control
- Voice cloning and custom voices
- Streaming support for real-time audio

---

### 3. Google Cloud TTS

**AdvancedOptions Schema:**
```json
{
  "SpeakingRate": 1.0,
  "Pitch": 0.0,
  "VolumeGainDb": 0.0,
  "EffectsProfile": "small-bluetooth-speaker-class-device"
}
```

**Controls:**
- **Speaking Rate**: Slider 0.25-4.0 (speed of speech)
  - 0.25 = Very slow
  - 1.0 = Normal speed (default)
  - 4.0 = Very fast
- **Pitch**: Slider -20.0 to +20.0 semitones
  - -20.0 = Much lower pitch
  - 0.0 = Normal pitch (default)
  - +20.0 = Much higher pitch
- **Volume Gain (dB)**: Slider -96.0 to +16.0 dB
  - -96.0 = Very quiet
  - 0.0 = Normal volume (default)
  - +16.0 = Amplified
- **Effects Profile**: Dropdown (8 optimisation profiles)
  - `wearable-class-device` (smartwatch/earbuds)
  - `handset-class-device` (phone speakers)
  - `headphone-class-device` (headphones/earphones)
  - `small-bluetooth-speaker-class-device` (desktop/laptop) **[DEFAULT]**
  - `medium-bluetooth-speaker-class-device` (home/office)
  - `large-home-entertainment-class-device` (home theatre)
  - `large-automotive-class-device` (car speakers)
  - `telephony-class-application` (VoIP/telephony)

**ShowAdvancedVoiceDialog Status:** ⏸️ Pending Implementation

**API Features:**
- Extensive SSML support (prosody, emphasis, breaks, say-as)
- WaveNet and Neural2 premium voices
- Multi-voice synthesis in single request

---

### 4. Microsoft Azure

**AdvancedOptions Schema:**
```json
{
  "SpeechRate": "medium",
  "Pitch": "medium",
  "Volume": "medium",
  "Style": "neutral",
  "Emphasis": "moderate",
  "EnableSSML": false
}
```

**Controls:**
- **Speech Rate**: Dropdown (x-slow, slow, medium, fast, x-fast)
  - x-slow, slow, **medium** (default), fast, x-fast
  - Via SSML `<prosody rate="">` attribute
- **Pitch**: Dropdown (x-low, low, medium, high, x-high)
  - x-low, low, **medium** (default), high, x-high
  - Via SSML `<prosody pitch="">` attribute
- **Volume**: Dropdown (silent, x-soft, soft, medium, loud, x-loud)
  - silent, x-soft, soft, **medium** (default), loud, x-loud
  - Via SSML `<prosody volume="">` attribute
- **Style**: Dropdown (voice-specific styles)
  - neutral, chat, customerservice, newscast, **angry**, cheerful, sad, excited, friendly, terrified, shouting, unfriendly, whispering, hopeful
  - Availability varies by voice
- **Emphasis**: Dropdown (reduced, none, moderate, strong)
  - reduced, none, **moderate** (default), strong
  - Via SSML `<emphasis level="">` attribute
- **Enable SSML**: Checkbox (Full SSML markup support)

**ShowAdvancedVoiceDialog Status:** ⏸️ Pending Implementation

**API Features:**
- Full SSML 1.0 support (prosody, emphasis, breaks, say-as, phonemes)
- Voice-specific speaking styles (chat, newscast, angry, cheerful, etc.)
- Custom Neural Voices for enterprise ($2,400 setup + hosting)
- 490+ voices across 140+ locales

---

### 5. Murf AI

**AdvancedOptions Schema:**
```json
{
  "Model": "Gen2",
  "Style": "Conversational",
  "Pitch": 0,
  "Speed": 0,
  "Variation": 0
}
```

**Controls:**
- **Model**: Dropdown (Gen2, Falcon)
  - **Gen2**: Studio-quality content generation (trained on 70,000+ hours)
  - **Falcon**: Ultra-low latency for real-time voice agents (<130ms)
- **Style**: Dropdown (20+ voice-specific styles)
  - Conversational, Promo, Newscast, Storytelling, Calm, Furious, Angry, Sobbing, Sad, etc.
  - Availability varies by voice
- **Pitch**: Slider -50 to +50
  - -50 = Much lower pitch
  - 0 = Normal pitch (default)
  - +50 = Much higher pitch
- **Speed**: Slider -50 to +50
  - -50 = Much slower
  - 0 = Normal speed (default)
  - +50 = Much faster
- **Variation**: Slider 0-5 (natural variation in pause/pitch/speed)
  - 0 = No variation (default)
  - 5 = Maximum natural variation

**ShowAdvancedVoiceDialog Status:** ⏸️ Pending Implementation

**API Features:**
- 150+ voices across 35+ languages
- MultiNative technology for authentic multilingual content
- Advanced customisation (emphasis, pauses, pronunciation)

---

### 6. AWS Polly

**AdvancedOptions Schema:**
```json
{
  "Engine": "neural",
  "SampleRate": 22050,
  "TextType": "text",
  "EnableSSML": false,
  "LexiconNames": []
}
```

**Controls:**
- **Engine**: Dropdown (standard, neural, long-form, conversational)
  - **standard**: Traditional concatenative synthesis ($4/1M chars)
  - **neural**: Deep learning natural voices ($16/1M chars) **[DEFAULT]**
  - **long-form**: Optimised for audiobooks/podcasts ($100/1M chars)
  - **conversational**: Designed for interactive apps/chatbots
- **Sample Rate**: Dropdown (8000, 16000, 22050, 24000 Hz)
  - 8000 Hz = Telephony quality
  - 16000 Hz = Standard quality
  - **22050 Hz** = High quality (default)
  - 24000 Hz = Premium quality
- **Text Type**: Radio buttons (text, ssml)
  - **text**: Plain text input (default)
  - **ssml**: SSML markup enabled
- **Enable SSML**: Checkbox (Enables SSML prosody, emphasis, breaks)
  - When enabled, supports `<prosody>`, `<emphasis>`, `<break>`, `<phoneme>`, `<sub>`, `<say-as>`
- **Lexicons**: Multi-select list (custom pronunciation dictionaries)
  - Upload custom lexicons to Polly service
  - Apply multiple lexicons per synthesis request

**ShowAdvancedVoiceDialog Status:** ⏸️ Pending Implementation

**API Features:**
- 75+ voices across 31+ languages
- Full SSML 1.1 support
- Custom lexicons for pronunciation
- Speech marks for lip-sync animation

---

### 7. Telnyx

**AdvancedOptions Schema:**
```json
{
  "Model": "NaturalHD",
  "SampleRate": 16000,
  "Channels": "MONO"
}
```

**Controls:**
- **Model**: Dropdown (KokoroTTS, Natural, NaturalHD)
  - **KokoroTTS**: Basic quality, cost-effective
  - **Natural**: Enhanced quality, improved naturalness
  - **NaturalHD**: Premium high-definition voices (default)
- **Sample Rate**: Dropdown (8000, 16000, 24000, 48000 Hz)
  - 8000 Hz = Telephony quality
  - **16000 Hz** = Standard quality (default)
  - 24000 Hz = High quality
  - 48000 Hz = Studio quality
- **Channels**: Radio buttons with orientation indicator
  - **MONO**: Single channel (default)
  - **STEREO**: Dual channel with Left ←→ Right orientation toggle

**ShowAdvancedVoiceDialog Status:** ⏸️ Pending Implementation

**API Features:**
- 266+ voices across multiple languages
- WebSocket streaming for real-time synthesis
- Low-latency optimised for conversational AI
- Incremental audio delivery

---

### 8. Twilio

**AdvancedOptions Schema:**
```json
{
  "LanguageOverride": "",
  "Loop": 1,
  "EnableSSML": false
}
```

**Controls:**
- **Language Override**: TextBox (specific language code, e.g., fr-FR, es-MX)
  - Empty = Use default language from voice selection
  - Populated = Override with specific locale (en-GB, fr-CA, es-ES, etc.)
- **Loop**: NumericUpDown 0-1000
  - 0 = Loop until hang-up (max 1,000 iterations)
  - **1** = Play once (default)
  - 2-1000 = Repeat N times
- **Enable SSML**: Checkbox (Limited SSML support for pronunciation)
  - Supports basic SSML tags via TwiML `<Say>` verb
  - Limited compared to Azure/Google Cloud

**ShowAdvancedVoiceDialog Status:** ⏸️ Pending Implementation

**API Features:**
- Uses Amazon Polly and Google TTS voices
- TwiML-based telephony integration
- Designed for IVR and phone call applications
- Per-request pricing (not per-character)

**Note:** Twilio has limited advanced options because it's telephony-focused and uses underlying Polly/Google engines. Most voice control happens through basic voice selection.

---

## Implementation Status

### Completed ✅
- **Default.json Schema**: All 8 providers updated across all 3 profiles (Default, Production, Testing)
- **OpenAI ShowAdvancedVoiceDialog**: Format dropdown removed, Speed + Model only, window height 420px
- **OpenAI.psm1**: Updated to remove Format from advanced options, log messages updated
- **Voice Library Expansion**: All providers now have comprehensive voice lists (38-63 voices per provider)
- **GUI.psm1 Enhancement**: Quality dropdown intelligently uses Models or Quality based on provider
  ```powershell
  $qualitySource = if ($voiceOptions.Models) { $voiceOptions.Models } else { $voiceOptions.Quality }
  ```

### Voice Count Summary
| Provider | Voices | Notable Additions |
|----------|--------|-------------------|
| Microsoft Azure | 38 | US (22), UK (5), AU (5), CA (2), IN (2), IE (2) |
| AWS Polly | 63 | Neural (14 US), UK (4), AU (3), 9 languages |
| ElevenLabs | 35 | Female (17), Male (18) |
| Google Cloud | 50 | Neural2/Wavenet/Studio across US/UK/AU/IN |
| Murf AI | 36 | US Female (12), US Male (12), UK (6), AU (4) |
| Telnyx | 33 | NaturalHD (10), Natural (12), KokoroTTS (11) |
| Twilio | 40 | Polly Neural/Generative + Google Chirp3-HD |
| OpenAI | 6 | alloy, echo, fable, onyx, nova, shimmer |

### Pending ⏸️
- **ElevenLabs ShowAdvancedVoiceDialog**: Stability/SimilarityBoost sliders + SSML checkbox
- **Google Cloud ShowAdvancedVoiceDialog**: SpeakingRate/Pitch/VolumeGain sliders + EffectsProfile dropdown
- **Microsoft Azure ShowAdvancedVoiceDialog**: Rate/Pitch/Volume/Style/Emphasis dropdowns + SSML checkbox
- **Murf AI ShowAdvancedVoiceDialog**: Model dropdown, Style dropdown, Pitch/Speed/Variation sliders
- **AWS Polly ShowAdvancedVoiceDialog**: Engine/SampleRate/TextType dropdowns, SSML checkbox, Lexicons multi-select
- **Telnyx ShowAdvancedVoiceDialog**: Model/SampleRate dropdowns, Channels radio with orientation toggle
- **Twilio ShowAdvancedVoiceDialog**: LanguageOverride textbox, Loop numeric, SSML checkbox

### Testing Required 🧪
- OpenAI: Verify Format removed from advanced dialog, Model in Quality dropdown
- All Providers: Test that AdvancedOptions save/load from config.json
- All Providers: Test that AdvancedOptions merge with provider configuration

---

## GUI Pattern for Advanced Dialogs

### Common Structure
All `ShowAdvancedVoiceDialog` implementations should follow this pattern:

```powershell
[hashtable] ShowAdvancedVoiceDialog([hashtable]$CurrentConfig) {
    # 1. Define XAML with dark theme (#FF1E1E1E background)
    # 2. Create WPF window (420-540 height, 540 width, centered)
    # 3. Get control references via FindName()
    # 4. Populate dropdowns/sliders with provider-specific values
    # 5. Load current configuration from $CurrentConfig
    # 6. Wire up event handlers (slider ValueChanged, Save/Cancel clicks)
    # 7. Return hashtable: @{ Success = $true; Parameter1 = value1; ... }
    # 8. Log with Add-ApplicationLog -Module "ProviderName" -Message "..." -Level "INFO"
}
```

### XAML Theme Standards
- **Window Background**: `#FF1E1E1E` (dark grey)
- **GroupBox Border**: `#FF3F3F46` BorderThickness="1"
- **TextBlock Foreground**: `White` for labels, `#FFB0B0B0` for hints
- **ComboBox/Slider Background**: `#FF3F3F46`
- **ComboBox Border**: `#FF28A745` (green accent)
- **Save Button**: `#FF28A745` (green) Background, `White` Foreground, `Bold` FontWeight
- **Cancel Button**: `#FF6C757D` (grey) Background, `White` Foreground, `Bold` FontWeight
- **Value Display**: `#FF28A745` (green) Foreground for real-time slider values

### Return Pattern
```powershell
# Success case
return @{
    Success = $true
    Speed = 1.5
    Pitch = -2.0
    EnableSSML = $false
}

# Cancel case
return @{ Success = $false }

# Error case
return @{ Success = $false; Error = $_.Exception.Message }
```

---

## Configuration Persistence

### Save Flow
1. User clicks **ADVANCED** button in main GUI
2. Provider's `ShowAdvancedVoiceDialog($CurrentConfig)` method called
3. Dialog displays current values from `$CurrentConfig.AdvancedOptions`
4. User adjusts sliders/dropdowns/checkboxes
5. User clicks **Save and Close**
6. Dialog returns hashtable with updated values
7. Main GUI merges returned values into `$this.ProviderInstance.Configuration`
8. User clicks **Save** (top-right of main form)
9. Configuration saved to `config.json` under `ProviderConfigurations.{Provider}`

### Load Flow
1. Application starts, loads `config.json`
2. User selects provider from dropdown
3. User clicks **Connect** button
4. After successful credential test, voice options populate
5. User clicks **ADVANCED** button
6. Current provider configuration passed to `ShowAdvancedVoiceDialog()`
7. Dialog pre-populates controls with saved values
8. If no saved value exists, use Default.json fallback

---

## Testing Checklist

### Per Provider
- [ ] Advanced dialog opens without errors
- [ ] All controls populate with correct values
- [ ] Current configuration loads and displays correctly
- [ ] Slider movements update real-time value displays
- [ ] Save button returns correct hashtable structure
- [ ] Cancel button returns `@{ Success = $false }`
- [ ] Configuration persists to config.json
- [ ] Configuration reloads correctly on next session
- [ ] Default.json fallback works when no config exists
- [ ] Logging captures Save/Cancel actions

### Integration
- [ ] Advanced options merge with basic voice selections (Voice/Language/Format/Quality)
- [ ] ProcessTTS method receives complete configuration including advanced options
- [ ] API calls include advanced parameters
- [ ] Audio output reflects advanced settings (speed, pitch, style, etc.)

---

## API Integration Points

Each provider's `ProcessTTS` method must read advanced options from configuration:

### Example: OpenAI
```powershell
[void] ProcessTTS([string]$text, [string]$outputPath) {
    $speed = 1.0
    if ($this.Configuration.Speed) {
        $speed = [double]$this.Configuration.Speed
    }
    
    $model = "tts-1-hd"
    if ($this.Configuration.Model) {
        $model = $this.Configuration.Model
    }
    
    $body = @{
        model = $model
        input = $text
        voice = $this.Configuration.Voice
        speed = $speed
        response_format = $this.Configuration.Format.ToLower()
    }
    
    # Make API call with advanced options...
}
```

### Example: Google Cloud
```powershell
$audioConfig = @{
    audioEncoding = $this.Configuration.Format
    speakingRate = $this.Configuration.SpeakingRate  # From AdvancedOptions
    pitch = $this.Configuration.Pitch                # From AdvancedOptions
    volumeGainDb = $this.Configuration.VolumeGainDb  # From AdvancedOptions
    effectsProfileId = @($this.Configuration.EffectsProfile)  # From AdvancedOptions
}
```

---

## Future Enhancements

### Phase 1 (Current)
- ✅ Define AdvancedOptions schema for all 8 providers
- ✅ Update Default.json with complete advanced options
- ✅ Remove Format from OpenAI advanced dialog

### Phase 2 (Next)
- ⏸️ Implement ShowAdvancedVoiceDialog for remaining 7 providers
- ⏸️ Test advanced options save/load workflow
- ⏸️ Integrate advanced parameters into ProcessTTS API calls

### Phase 3 (Future)
- SSML Editor for Azure/Google Cloud/AWS Polly
- Real-time audio preview in advanced dialog
- Advanced options presets (e.g., "Audiobook", "News", "Casual Conversation")
- Per-voice advanced option validation (some styles only work with specific voices)

---

## References

- **Main README**: [README.md](../README.md)
- **Provider Setup Guides**: [docs/providers/](providers/)
- **CSV Format**: [CSV-FORMAT.md](CSV-FORMAT.md)
- **Troubleshooting**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Copilot Instructions**: [.github/copilot-instructions.md](../.github/copilot-instructions.md)

---

**Document Version:** 1.0  
**Last Reviewed:** 2025-11-23  
**Next Review:** After Phase 2 completion

# Dynamic Voice Options Implementation Status

## Overview
Implementation of dynamic voice retrieval using **native REST API calls only** - no SDKs, no executables, pure PowerShell `Invoke-RestMethod`.

## Recent Updates (2025-11-23)

### ✅ Voice Library Expansion
All providers now have comprehensive fallback voice lists:
- **Microsoft Azure**: 38 voices (US, UK, AU, CA, IN, IE variants)
- **AWS Polly**: 63 voices (14 languages, Neural/Standard/Long-form)
- **ElevenLabs**: 35 voices (17 female, 18 male)
- **Google Cloud**: 50 voices (Neural2, Wavenet, Studio quality tiers)
- **Murf AI**: 36 voices (US, UK, AU, CA accents)
- **Telnyx**: 33 voices (NaturalHD, Natural, KokoroTTS models)
- **Twilio**: 40 voices (Polly Neural/Generative + Google Chirp3-HD)
- **OpenAI**: 6 voices (complete API set)

### ✅ GUI Quality/Model Intelligence
Updated `Modules/GUI.psm1` (line 939) to handle both Quality and Models:
```powershell
$qualitySource = if ($voiceOptions.Models) { $voiceOptions.Models } else { $voiceOptions.Quality }
```
- OpenAI shows: tts-1, tts-1-hd
- Telnyx shows: KokoroTTS, Natural, NaturalHD
- Others show: Neural, High, Standard, etc.

### ✅ Advanced Options Architecture
Format (MP3/WAV/FLAC) removed from AdvancedOptions:
- Format is now **basic selection only** (main GUI dropdown)
- Advanced options contain **vocal parameters** (speed, pitch, stability, etc.)
- All 3 profiles in Default.json updated to reflect this

## Implementation Date
2025-11-23

## Provider Status Summary

| Provider | API Status | Endpoint | Auth Method | Notes |
|----------|-----------|----------|-------------|-------|
| ✅ OpenAI | **COMPLETE** | `GET /v1/models` | Bearer token | Filters tts-* models, 30-min cache |
| ✅ ElevenLabs | **IMPLEMENTED** | `GET /v1/voices` | xi-api-key header | Voice name extraction |
| ✅ Google Cloud | **IMPLEMENTED** | `GET /v1/voices?key={API_KEY}` | API key in query OR Bearer | Language extraction |
| ✅ Microsoft Azure | **IMPLEMENTED** | 2-step: issueToken + voices/list | Ocp-Apim-Subscription-Key → Bearer | Requires region param |
| ✅ Murf AI | **IMPLEMENTED** | `GET /v1/speech/voices` | Bearer token | Voice/language extraction |
| ✅ Telnyx | **IMPLEMENTED** | `GET /v2/text-to-speech/voices` | Bearer token | Inferred endpoint |
| ⚠️ AWS Polly | **FALLBACK ONLY** | N/A (requires AWS SigV4) | AWS Signature Version 4 | Comprehensive static list |
| ✅ Twilio | **STATIC LIST** | N/A (no listing API) | N/A | Uses Polly voices via TwiML |

## Detailed Implementation

### ✅ OpenAI (REFERENCE IMPLEMENTATION)
- **File**: `Modules/Providers/OpenAI.psm1` (729 lines)
- **Function**: `Get-OpenAIVoiceOptions -ApiKey [string] -UseCache [bool]`
- **Endpoint**: `https://api.openai.com/v1/models`
- **Method**: GET
- **Headers**: `Authorisation: Bearer {API_KEY}`
- **Response Processing**: Filters `$response.data` for models matching `tts-*`
- **Caching**: 30-minute session cache with `CachedVoiceOptions`, `CacheTimestamp`, `GetVoiceOptions([bool]$ForceRefresh)` method
- **Advanced Dialogue**: `ShowAdvancedVoiceDialog` with Speed slider (0.25-4.0), Format dropdown, Model dropdown
- **Status**: **PRODUCTION READY** - Full reference implementation for all other providers

### ✅ ElevenLabs
- **File**: `Modules/Providers/ElevenLabs.psm1` (447 lines - PARTIALLY UPDATED)
- **Function**: `Get-ElevenLabsVoiceOptions -ApiKey [string] -UseCache [bool]`
- **Endpoint**: `https://api.elevenlabs.io/v1/voices`
- **Method**: GET
- **Headers**: `xi-api-key: {API_KEY}`, `Accept: application/json`
- **Response Processing**: Extracts `$response.voices | Select-Object -ExpandProperty name`
- **Fallback**: Returns 35 voices (17 female, 18 male) if API call fails
- **Status**: Get-VoiceOptions COMPLETE, class caching PENDING, ShowAdvancedVoiceDialog PENDING

### ✅ Google Cloud
- **File**: `Modules/Providers/Google Cloud.psm1` (591 lines)
- **Function**: `Get-GoogleCloudVoiceOptions -ApiKey [string] -UseCache [bool]`
- **Endpoint**: `https://texttospeech.googleapis.com/v1/voices?key={API_KEY}`
- **Method**: GET
- **Auth**: API key in query parameter (simpler than Bearer token)
- **Response Processing**: 
  - Voices: `$response.voices | ForEach-Object { $_.name }`
  - Languages: `$response.voices | ForEach-Object { $_.languageCodes } | Select-Object -Unique`
- **Fallback**: Returns 50 voices (Neural2, Wavenet, Studio) across US/UK/AU/IN if API fails
- **Status**: Get-VoiceOptions COMPLETE, class caching PENDING, ShowAdvancedVoiceDialog PENDING

### ✅ Microsoft Azure
- **File**: `Modules/Providers/Microsoft Azure.psm1` (1016 lines)
- **Function**: `Get-AzureVoiceOptions -ApiKey [string] -Region [string] -UseCache [bool]`
- **Two-Step Authentication**:
  1. **Token Request**: `POST https://{region}.api.cognitive.microsoft.com/sts/v1.0/issueToken`
     - Headers: `Ocp-Apim-Subscription-Key: {API_KEY}`
     - Returns Bearer token
  2. **Voice List**: `GET https://{region}.tts.speech.microsoft.com/cognitiveservices/voices/list`
     - Headers: `Authorisation: Bearer {TOKEN}`
- **Response Processing**:
  - Voices: `$response | ForEach-Object { $_.ShortName }`
  - Languages: `$response | ForEach-Object { $_.Locale } | Select-Object -Unique`
- **Region Parameter**: Required (eastus, westeurope, uksouth, etc.)
- **Fallback**: Returns 38 Neural voices (US, UK, AU, CA, IN, IE) if API fails
- **Status**: Get-VoiceOptions COMPLETE, class caching PENDING, ShowAdvancedVoiceDialog PENDING

### ✅ Murf AI
- **File**: `Modules/Providers/Murf AI.psm1` (425 lines)
- **Function**: `Get-MurfAIVoiceOptions -ApiKey [string] -UseCache [bool]`
- **Endpoint**: `https://api.murf.ai/v1/speech/voices`
- **Method**: GET
- **Headers**: `Authorisation: Bearer {API_KEY}`, `Content-Type: application/json`
- **Response Processing**:
  - Voices: `$response.data | ForEach-Object { $_.name }`
  - Languages: `$response.data | ForEach-Object { $_.language } | Select-Object -Unique`
- **Fallback**: Returns 36 voices across US/UK/AU/CA (GEN2/FALCON models, 5 styles)
- **Status**: Get-VoiceOptions COMPLETE, class caching PENDING, ShowAdvancedVoiceDialog PENDING

### ✅ Telnyx
- **File**: `Modules/Providers/Telnyx.psm1` (437 lines)
- **Function**: `Get-TelnyxVoiceOptions -ApiKey [string] -UseCache [bool]`
- **Endpoint**: `https://api.telnyx.com/v2/text-to-speech/voices` (INFERRED - needs verification)
- **Method**: GET
- **Headers**: `Authorisation: Bearer {API_KEY}`, `Content-Type: application/json`
- **Response Processing**: Extracts `$response.data | Select-Object -ExpandProperty name`
- **Fallback**: Returns 33 voices across KokoroTTS/Natural/NaturalHD models
- **Status**: Get-VoiceOptions COMPLETE (endpoint inferred), class caching PENDING, ShowAdvancedVoiceDialog PENDING
- **Note**: Endpoint inferred from API pattern - may need verification with actual API testing

### ⚠️ AWS Polly (FALLBACK ONLY)
- **File**: `Modules/Providers/AWS Polly.psm1` (628 lines)
- **Function**: `Get-PollyVoiceOptions -AccessKey [string] -SecretKey [string] -Region [string] -UseCache [bool]`
- **Challenge**: Requires AWS Signature Version 4 authentication (complex multi-step signing)
- **Endpoint**: `https://polly.{region}.amazonaws.com/v1/voices` (documented in AWS API reference)
- **Auth Requirements**:
  1. Create canonical request with sorted headers and SHA256 hashed payload
  2. Create string to sign with scope (date/region/service)
  3. Calculate signature using HMAC-SHA256 with derived signing key
  4. Add `Authorisation` header with signature
- **Current Implementation**: Returns comprehensive static list of 63 voices across 14 languages (Neural/Standard/Long-form)
- **Status**: **FALLBACK ONLY** - Full native REST implementation requires AWS SigV4 signing algorithm
- **Future Enhancement**: Implement AWS Signature Version 4 for live voice retrieval

### ✅ Twilio (STATIC BY DESIGN)
- **File**: `Modules/Providers/Twilio.psm1` (390 lines)
- **Function**: `Get-TwilioVoiceOptions -AccountSID [string] -AuthToken [string] -UseCache [bool]`
- **API Limitation**: Twilio uses TwiML markup language - no voice listing REST endpoint exists
- **Voice Selection Method**: Via `<Say voice="Polly.Joanna">` in TwiML XML
- **Current Implementation**: Returns comprehensive static list of 40 voices (Polly Neural/Generative + Google Chirp3-HD + legacy)
- **Voice List**: 
  - Polly Neural: 14 US voices (Joanna, Matthew, Ivy, Justin, Kendra, Kimberly, Salli, Joey, Kevin, Ruth, Stephen, Gregory, Danielle, Aria)
  - Polly Generative: 3 voices (Joanna-Generative, Matthew-Generative, Ruth-Generative)
  - UK/AU/IN/ZA/Welsh: 11 Polly voices
  - Google Chirp3-HD: 4 voices (US/GB variants)
  - Legacy: 3 voices (alice, man, woman)
- **Status**: **STATIC BY DESIGN** - No API endpoint available for voice listing
- **Note**: This is the correct implementation - Twilio voice selection happens via TwiML, not API discovery

## GUI Integration

### UpdateVoiceOptions Method (`Modules/GUI.psm1` lines 800-873)
```powershell
# Extracts API keys/credentials from provider configuration
# Passes provider-specific parameters:
- AWS Polly: AccessKey, SecretKey, Region
- Microsoft Azure: ApiKey, Region (from Datacenter property)
- Google Cloud: ApiKey (query param)
- Murf AI: ApiKey (Bearer)
- ElevenLabs: ApiKey (xi-api-key header)
- OpenAI: ApiKey (Bearer)
- Telnyx: ApiKey (Bearer)
- Twilio: AccountSID, AuthToken (not used for voice retrieval)

# Populates dropdowns dynamically from API response
- VoiceSelect: Populated from $voiceOptions.Voices array
- LanguageSelect: Populated from $voiceOptions.Languages array
- FormatSelect: Populated from $voiceOptions.Formats array
- QualitySelect: Populated from $voiceOptions.Quality array
```

## Common Pattern

All provider implementations follow this structure:

```powershell
function Get-{Provider}VoiceOptions {
    param(
        [Parameter(Mandatory=$false)]
        [string]$ApiKey,  # or provider-specific auth params
        
        [Parameter(Mandatory=$false)]
        [bool]$UseCache = $true
    )
    
    # Fallback configuration
    $defaultOptions = @{
        Voices = @(...)
        Languages = @(...)
        Formats = @(...)
        Quality = @(...)
        Defaults = @{...}
        SupportsAdvanced = $true
    }
    
    # Return defaults if no API key
    if (-not $ApiKey) {
        Add-ApplicationLog -Module "Provider" -Message "No API key, returning defaults" -Level "DEBUG"
        return $defaultOptions
    }
    
    # Try live API call
    try {
        $headers = @{...}
        $response = Invoke-RestMethod -Uri "..." -Method Get -Headers $headers -TimeoutSec 10
        
        # Extract voices, languages, etc.
        $defaultOptions.Voices = @($response.voices | ...)
        
    } catch {
        Add-ApplicationLog -Module "Provider" -Message "API failed: $($_.Exception.Message)" -Level "WARNING"
    }
    
    return $defaultOptions
}
```

## Next Steps

### Immediate (High Priority)
1. **Complete ElevenLabs**: Add caching properties to class, implement `GetVoiceOptions` method, create `ShowAdvancedVoiceDialog` with Stability/SimilarityBoost sliders
2. **Test All Providers**: Verify API calls with live credentials for Google Cloud, Azure, Murf AI, Telnyx
3. **Add Caching**: Implement 30-minute cache pattern for Google Cloud, Azure, Murf AI, ElevenLabs, Telnyx

### Medium Priority
4. **Verify Telnyx Endpoint**: Test `https://api.telnyx.com/v2/text-to-speech/voices` with live API key to confirm endpoint
5. **AWS Polly SigV4**: Research implementing AWS Signature Version 4 for native REST calls (complex but feasible)

### Low Priority (Advanced Dialogues)
6. **Google Cloud Advanced**: Speaking rate, pitch, volume gain, effects profiles sliders
7. **Azure Advanced**: Speech rate, pitch, volume, style, emphasis (SSML controls)
8. **Murf AI Advanced**: Style selection dropdown, speed/pitch sliders
9. **Telnyx Advanced**: Model selection (KokoroTTS/Natural/NaturalHD), sample rate
10. **ElevenLabs Advanced**: Stability (0-1) and Similarity Boost (0-1) sliders for emotional control

## Testing Checklist

- [ ] OpenAI: Test with live API key, verify 6 voices returned
- [ ] ElevenLabs: Test /v1/voices endpoint, verify xi-api-key auth
- [ ] Google Cloud: Test query param auth vs Bearer token
- [ ] Microsoft Azure: Test two-step token flow with eastus/westeurope regions
- [ ] Murf AI: Test Bearer auth, verify voice/language extraction
- [ ] Telnyx: Verify inferred endpoint with live API key
- [ ] AWS Polly: Confirm fallback list covers all major voices
- [ ] Twilio: Confirm static list matches TwiML documentation
- [ ] GUI: Test dropdown population switches correctly between providers
- [ ] Config: Verify voice selections save to config.json per provider
- [ ] Persistence: Confirm selections reload after application restart

## Architecture Notes

### Why Native REST?
- **No version control**: No managing SDK versions, DLL dependencies, or executable updates
- **Transparency**: Every API call visible and debuggable in application.log
- **Cross-platform**: Pure PowerShell works on v5.1 and v7+ without external dependencies
- **Security**: Direct HTTPS calls, no third-party library vulnerabilities

### Fallback Strategy
Every provider has comprehensive default values ensuring GUI always populates even if:
- API credentials missing
- Network unavailable
- API endpoint changes
- Rate limits exceeded

### Error Handling
All API calls wrapped in try/catch with:
- 10-second timeout (`-TimeoutSec 10`)
- Application log entries (INFO for success, WARNING for failure)
- Graceful fallback to defaults

## References

- **OpenAI API Docs**: https://platform.openai.com/docs/api-reference/models
- **ElevenLabs API Docs**: https://elevenlabs.io/docs/api-reference/voices
- **Google Cloud TTS**: https://cloud.google.com/text-to-speech/docs/reference/rest/v1/voices/list
- **Microsoft Azure Cognitive Services**: https://learn.microsoft.com/en-us/azure/cognitive-services/speech-service/rest-text-to-speech
- **Murf AI API**: https://docs.murf.ai/api-reference/voices
- **Telnyx Docs**: https://developers.telnyx.com/docs/text-to-speech
- **AWS Polly DescribeVoices**: https://docs.aws.amazon.com/polly/latest/dg/API_DescribeVoices.html
- **Twilio TwiML Say**: https://www.twilio.com/docs/voice/twiml/say

---

**Implementation Status**: 6 of 8 providers with live API calls, 1 comprehensive fallback (AWS Polly), 1 static by design (Twilio)

**Last Updated**: 2025-11-23

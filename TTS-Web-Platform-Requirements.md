# Functional Requirements Specification: TextToSpeech Generator Web Platform

## Project Overview

Convert the existing PowerShell-based TextToSpeech Generator to a modern, cloud-native web application using React frontend, Cloudflare Workers API backend, and D1 database storage.

### Version
- **Document Version**: 1.1
- **Date**: October 15, 2025
- **Based on**: TextToSpeech Generator v3.2 + Phase 3 + Phase 4 Requirements

### Project Scope & Strategy

**⚠️ IMPORTANT**: This is a **complete rewrite** of the PowerShell system as a web platform, NOT a migration or port. The existing PowerShell codebase serves as the functional specification and reference implementation.

#### Implementation Approach
- **Reference Implementation**: Use existing PowerShell modules (`Modules/TTSProviders/`, `config.json`, `Tests/`) as the definitive specification
- **Technology Shift**: PowerShell → TypeScript/JavaScript (Cloudflare Workers)
- **Architecture Shift**: Desktop CLI → Cloud-native web application
- **Functionality Preservation**: Maintain 100% feature parity with existing PowerShell system
- **Enhancement**: Add web-scale features (multi-tenancy, API access, real-time processing)

---

## 1. Implementation Strategy & Guidance

### 1.1 Development Phases

#### Phase 1: Foundation (Weeks 1-2)
**Priority**: Single TTS generation with API-first architecture
- ✅ Basic React SPA with authentication
- ✅ Cloudflare Workers API with one TTS provider (Azure)
- ✅ D1 database schema and basic CRUD operations
- ✅ CI/CD pipeline and deployment automation
- ✅ Single text-to-speech generation endpoint

#### Phase 2: Provider Integration (Weeks 3-4)
**Priority**: Complete TTS provider ecosystem
- ✅ All 6 TTS providers implemented (referencing PowerShell modules)
- ✅ Provider-specific voice selection and configuration
- ✅ Advanced audio controls (SSML, pitch, rate, volume)
- ✅ Provider health monitoring and failover
- ✅ Configuration management UI

#### Phase 3: Advanced Features (Weeks 5-6)
**Priority**: Batch processing and enterprise features
- ✅ Batch processing system with queue management
- ✅ Real-time job progress tracking
- ✅ File upload/download capabilities
- ✅ Usage analytics and reporting
- ✅ Admin interface and user management

#### Phase 4: Enterprise Polish (Weeks 7-8)
**Priority**: Production readiness and optimisation
- ✅ Performance optimisation and caching
- ✅ Security audit and compliance
- ✅ Comprehensive monitoring and alerting
- ✅ Documentation and API reference
- ✅ Load testing and scalability validation

### 1.2 PowerShell Code Reference Guide

#### Critical Files to Study
```
📁 Modules/TTSProviders/
├── AzureCognitive.psm1       → Azure implementation reference
├── AWSPolly.psm1             → AWS Polly implementation reference  
├── GoogleCloudTTS.psm1       → Google Cloud TTS implementation reference
├── CloudPronouncer.psm1      → CloudPronouncer implementation reference
├── Twilio.psm1               → Twilio implementation reference
└── VoiceForge.psm1           → VoiceForge implementation reference

📁 Configuration/
├── config.json               → Configuration structure and provider settings
└── AdvancedConfiguration.psm1 → Configuration management logic

📁 Tests/
├── Unit/TTSProviders.Tests.ps1 → Provider validation and testing patterns
├── Integration/              → Integration testing examples
└── Performance/              → Performance benchmarking patterns
```

#### Implementation Pattern
Each PowerShell provider module should be converted to TypeScript following this pattern:

```typescript
// Reference: Modules/TTSProviders/AzureCognitive.psm1
export class AzureTTSProvider implements TTSProvider { 
  // Convert PowerShell functions to TypeScript methods
  async generateSpeech(text: string, options: TTSOptions): Promise<AudioBuffer> {
    // Logic from Invoke-AzureTTS function
  }
  
  async getVoices(): Promise<Voice[]> {
    // Logic from Get-AzureVoices function
  }
  
  validateConfig(config: ProviderConfig): boolean {
    // Logic from Test-AzureConfiguration function
  }
}
```

### 1.3 Configuration Migration Strategy

#### Current PowerShell Configuration Structure
The existing `config.json` defines the exact structure needed:

```json
{
  "Profiles": {
    "Development": {
      "Providers": {
        "Azure Cognitive Services": {
          "Datacenter": "eastus",
          "AudioFormat": "audio-16khz-32kbitrate-mono-mp3",
          "ApiKey": "ENCRYPTED:test-key-12345",
          "AdvancedOptions": {
            "SpeechRate": "medium",
            "Pitch": "medium", 
            "Volume": "medium",
            "Style": "neutral",
            "Emphasis": "moderate"
          },
          "Enabled": true,
          "DefaultVoice": "en-US-JennyNeural"
        }
      }
    }
  }
}
```

#### Web Platform Configuration Enhancement
The web version should support the same structure but enhanced for multi-tenancy:

```typescript
interface UserProviderConfig {
  // Same structure as PowerShell config.json
  providerId: string;
  settings: {
    datacenter?: string;
    audioFormat: string;
    apiKey: string; // Encrypted in database
    advancedOptions: ProviderAdvancedOptions;
    enabled: boolean;
    defaultVoice: string;
  };
  // Web-specific additions
  userId: string;
  rateLimit?: number;
  lastUsed?: Date;
  usageStats?: UsageStatistics;
}
```

---

## 2. Architecture Overview

### 1.1 Technology Stack
- **Frontend**: React 18+ with TypeScript
- **Backend**: Cloudflare Workers (Serverless API)
- **Database**: Cloudflare D1 (SQLite-based)
- **Static Assets**: Cloudflare Pages
- **File Storage**: Cloudflare R2 (for audio files)
- **Authentication**: Cloudflare Access + JWT
- **CI/CD**: GitHub Actions
- **Monitoring**: Cloudflare Analytics + Custom metrics

### 2.2 Infrastructure Components
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   React SPA     │    │  Cloudflare      │    │  External TTS   │
│  (CF Pages)     │───▶│  Workers API     │───▶│   Providers     │
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       
         │                       ▼                       
         │              ┌─────────────────┐              
         │              │   Cloudflare    │              
         └─────────────▶│  D1 Database    │              
                        │                 │              
                        └─────────────────┘              
                                 │                       
                                 ▼                       
                        ┌─────────────────┐              
                        │  Cloudflare R2  │              
                        │ (Audio Storage) │              
                        └─────────────────┘              
```

---

## 3. PowerShell-to-Web Migration Specifications

### 3.1 Provider Implementation Mapping

#### 3.1.1 Azure Cognitive Services Migration
**Reference**: `Modules/TTSProviders/AzureCognitive.psm1`

```typescript
// PowerShell Function: Invoke-AzureTTS
export class AzureTTSProvider implements TTSProvider {
  private apiKey: string;
  private region: string;
  
  constructor(config: AzureConfig) {
    this.apiKey = config.apiKey;
    this.region = config.datacenter; // Maps to PowerShell "Datacenter" field
  }
  
  async generateSpeech(text: string, options: AzureTTSOptions): Promise<AudioBuffer> {
    // Replicate logic from Invoke-AzureTTS PowerShell function
    const ssml = this.buildSSML(text, options);
    const response = await fetch(`https://${this.region}.tts.speech.microsoft.com/cognitiveservices/v1`, {
      method: 'POST',
      headers: {
        'Ocp-Apim-Subscription-Key': this.apiKey,
        'Content-Type': 'application/ssml+xml',
        'X-Microsoft-OutputFormat': options.audioFormat || 'audio-16khz-32kbitrate-mono-mp3'
      },
      body: ssml
    });
    return response.arrayBuffer();
  }
  
  // PowerShell Function: Get-AzureVoices  
  async getVoices(): Promise<Voice[]> {
    // Replicate logic from Get-AzureVoices PowerShell function
  }
  
  // PowerShell Function: Test-AzureConfiguration
  validateConfig(config: AzureConfig): boolean {
    // Replicate validation logic from PowerShell
    return config.apiKey?.length === 32 && config.datacenter?.length > 0;
  }
  
  private buildSSML(text: string, options: AzureTTSOptions): string {
    // Replicate SSML building logic from PowerShell module
    return `<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="en-US">
      <voice name="${options.voice || 'en-US-JennyNeural'}">
        <prosody rate="${options.speechRate || 'medium'}" pitch="${options.pitch || 'medium'}" volume="${options.volume || 'medium'}">
          ${text}
        </prosody>
      </voice>
    </speak>`;
  }
}
```

#### 3.1.2 Configuration System Migration
**Reference**: `Modules/Configuration/AdvancedConfiguration.psm1`

```typescript
// PowerShell Function: Initialise-AdvancedConfiguration
export class ConfigurationManager {
  private db: D1Database;
  
  // PowerShell Function: Get-CurrentProfile
  async getCurrentProfile(userId: string): Promise<UserProfile> {
    const result = await this.db.prepare(
      'SELECT * FROM user_profiles WHERE user_id = ? AND is_active = 1'
    ).bind(userId).first();
    return result as UserProfile;
  }
  
  // PowerShell Function: Set-ProviderConfiguration  
  async setProviderConfig(userId: string, provider: string, config: ProviderConfig): Promise<void> {
    // Replicate provider configuration logic from PowerShell
    await this.db.prepare(`
      INSERT OR REPLACE INTO provider_configs (id, user_id, provider, config, is_active, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
    `).bind(
      crypto.randomUUID(),
      userId,
      provider,
      JSON.stringify(config),
      true,
      new Date().toISOString()
    ).run();
  }
  
  // PowerShell Function: Test-ProviderConfiguration
  async validateProviderConfig(provider: string, config: ProviderConfig): Promise<boolean> {
    const providerInstance = this.getProviderInstance(provider);
    return providerInstance.validateConfig(config);
  }
}
```

### 3.2 Feature Parity Requirements

#### 3.2.1 Exact Feature Mapping
Every feature in the PowerShell version MUST be replicated:

| PowerShell Feature | Web Platform Implementation | Reference File |
|-------------------|----------------------------|----------------|
| Single TTS Generation | `POST /api/v1/tts/generate` | `StartModularTTS.ps1` |
| Batch Processing | `POST /api/v1/tts/batch` | `Modules/Utilities/UtilityFunctions.psm1` |
| Provider Selection | Provider dropdown + config UI | `config.json` profiles |
| Voice Selection | Dynamic voice loading per provider | Each provider `.psm1` file |
| Audio Format Options | Format selection in UI/API | Provider-specific options |
| Advanced Controls | SSML builder + UI controls | Provider `AdvancedOptions` |
| Configuration Profiles | User profile management | `config.json` structure |
| Logging System | Cloudflare Workers logging | `Modules/Logging/EnhancedLogging.psm1` |
| Error Handling | Try/catch with user feedback | `Modules/ErrorRecovery/` |
| Performance Monitoring | Analytics dashboard | `Modules/Performance/` |

#### 3.2.2 Configuration Structure Preservation
The web platform must support the exact same configuration structure:

```typescript
// Direct mapping from config.json structure
interface WebPlatformConfig {
  profiles: {
    [profileName: string]: {
      processing: {
        outputPath: string;      // → R2 bucket path
        inputFile: string;       // → Upload endpoint
        timeout: number;         // → API timeout settings
        maxParallelJobs: number; // → Concurrency limits
      };
      providers: {
        [providerName: string]: {
          datacenter?: string;
          audioFormat: string;
          apiKey: string;
          advancedOptions: Record<string, any>;
          enabled: boolean;
          defaultVoice: string;
        };
      };
      logging: {
        level: 'DEBUG' | 'INFO' | 'WARNING' | 'ERROR';
        enableDetailedLogging: boolean;
      };
    };
  };
  currentProfile: string;
}
```

---

## 4. Functional Requirements

### 4.1 Core TTS Functionality

#### 4.1.1 Text-to-Speech Generation
- **FR-001**: Support single text input conversion to audio
- **FR-002**: Support batch text processing from CSV/JSON uploads
- **FR-003**: Support multiple TTS providers:
  - Microsoft Azure Cognitive Services
  - AWS Polly
  - Google Cloud TTS
  - CloudPronouncer
  - Twilio
  - VoiceForge
- **FR-004**: Provider-specific voice selection and configuration
- **FR-005**: Audio format selection (MP3, WAV, OGG)
- **FR-006**: Quality/bitrate configuration per provider

#### 4.1.2 Advanced Audio Controls
- **FR-007**: Speech rate adjustment (slow, medium, fast, custom)
- **FR-008**: Pitch modification support
- **FR-009**: Volume control
- **FR-010**: Speaking style selection (neutral, cheerful, sad, etc.)
- **FR-011**: Emphasis and prosody controls
- **FR-012**: SSML (Speech Synthesis Markup Language) support

### 4.2 Web Interface Requirements

#### 4.2.1 User Interface Components
- **FR-013**: Responsive design for desktop, tablet, mobile
- **FR-014**: Real-time text input with character/word count
- **FR-015**: Voice preview and selection interface
- **FR-016**: Audio player with download controls
- **FR-017**: Batch processing interface with progress tracking
- **FR-018**: Provider status dashboard
- **FR-019**: Configuration management interface
- **FR-020**: Usage analytics and reporting

#### 4.2.2 User Experience Features
- **FR-021**: Dark/light theme support
- **FR-022**: Keyboard shortcuts for common actions
- **FR-023**: Drag-and-drop file upload
- **FR-024**: Auto-save of user preferences
- **FR-025**: Recent conversions history
- **FR-026**: Export/import settings functionality

### 4.3 API Requirements (Phase 4 Features)

#### 4.3.1 REST API Endpoints
- **FR-027**: `POST /api/v1/tts/generate` - Single TTS generation
- **FR-028**: `POST /api/v1/tts/batch` - Batch TTS processing
- **FR-029**: `GET /api/v1/tts/job/{id}` - Job status and results
- **FR-030**: `GET /api/v1/providers` - Available TTS providers
- **FR-031**: `GET /api/v1/providers/{provider}/voices` - Provider voices
- **FR-032**: `GET /api/v1/health` - System health check
- **FR-033**: `GET /api/v1/usage` - Usage statistics
- **FR-034**: `POST /api/v1/auth/token` - Authentication
- **FR-035**: `DELETE /api/v1/tts/job/{id}` - Cancel/delete jobs

#### 4.3.2 API Features
- **FR-036**: RESTful design with proper HTTP status codes
- **FR-037**: JSON request/response format
- **FR-038**: OpenAPI 3.0 specification
- **FR-039**: API versioning support
- **FR-040**: Request/response compression (gzip)
- **FR-041**: Content-Type validation
- **FR-042**: Webhook support for job completion notifications

### 4.4 Authentication & Security

#### 2.4.1 Authentication System
- **FR-043**: API key-based authentication
- **FR-044**: JWT token management
- **FR-045**: User registration/login system
- **FR-046**: Role-based access control (Admin, User, API-only)
- **FR-047**: Session management and timeout
- **FR-048**: Password reset functionality

#### 2.4.2 Security Features
- **FR-049**: Rate limiting (configurable per user/API key)
- **FR-050**: Request size limits and validation
- **FR-051**: CORS policy configuration
- **FR-052**: Input sanitization and validation
- **FR-053**: Secure API key storage and rotation
- **FR-054**: Audit logging for security events
- **FR-055**: DDoS protection via Cloudflare

### 2.5 Data Management

#### 2.5.1 Database Schema
- **FR-056**: User accounts and profiles
- **FR-057**: API keys and permissions
- **FR-058**: TTS job queue and history
- **FR-059**: Provider configurations
- **FR-060**: Usage statistics and billing data
- **FR-061**: System settings and feature flags
- **FR-062**: Audio file metadata and references

#### 2.5.2 File Storage
- **FR-063**: Generated audio file storage in R2
- **FR-064**: Temporary file cleanup (TTL-based)
- **FR-065**: File access controls and signed URLs
- **FR-066**: Batch upload processing
- **FR-067**: File format conversion support
- **FR-068**: Storage quota management per user

### 2.6 Performance & Scalability

#### 2.6.1 Performance Requirements
- **FR-069**: API response time < 200ms (excluding TTS generation)
- **FR-070**: Frontend initial load < 3 seconds
- **FR-071**: Support for concurrent batch processing
- **FR-072**: Asynchronous job processing with status updates
- **FR-073**: Caching of frequently requested voices/providers
- **FR-074**: CDN optimisation for static assets

#### 2.6.2 Scalability Features
- **FR-075**: Auto-scaling via Cloudflare Workers
- **FR-076**: Database connection pooling
- **FR-077**: Queue-based batch processing
- **FR-078**: Load balancing across TTS providers
- **FR-079**: Graceful degradation when providers unavailable
- **FR-080**: Circuit breaker pattern for external APIs

### 2.7 Monitoring & Analytics

#### 2.7.1 System Monitoring
- **FR-081**: Health checks for all components
- **FR-082**: Performance metrics collection
- **FR-083**: Error tracking and alerting
- **FR-084**: Provider availability monitoring
- **FR-085**: Database performance monitoring
- **FR-086**: Real-time status dashboard

#### 2.7.2 Business Analytics
- **FR-087**: Usage statistics per user/API key
- **FR-088**: Provider usage and cost tracking
- **FR-089**: Popular voices and settings analytics
- **FR-090**: Conversion success/failure rates
- **FR-091**: User engagement metrics
- **FR-092**: Revenue and billing analytics

---

## 3. Technical Requirements

### 3.1 Frontend Specifications

#### 3.1.1 React Application
```typescript
// Core dependencies
{
  "react": "^18.2.0",
  "react-dom": "^18.2.0",
  "typescript": "^5.0.0",
  "vite": "^4.4.0",
  "@types/react": "^18.2.0"
}

// UI Framework
{
  "tailwindcss": "^3.3.0",
  "@headlessui/react": "^1.7.0",
  "react-hot-toast": "^2.4.0"
}

// State Management
{
  "@tanstack/react-query": "^4.32.0",
  "zustand": "^4.4.0"
}

// Routing and Forms
{
  "react-router-dom": "^6.15.0",
  "react-hook-form": "^7.45.0",
  "@hookform/resolvers": "^3.3.0",
  "zod": "^3.22.0"
}
```

#### 3.1.2 Key Components
- **AudioPlayer**: HTML5 audio with custom controls
- **TTSForm**: Form with voice selection and settings
- **BatchUploader**: File upload with progress tracking
- **ProviderSelector**: Dynamic provider/voice selection
- **JobQueue**: Real-time job status monitoring
- **SettingsPanel**: User preferences and API configuration
- **AnalyticsDashboard**: Usage statistics visualization

### 3.2 Backend Specifications

#### 3.2.1 Cloudflare Workers Structure
```
src/
├── workers/
│   ├── api/                 # Main API worker
│   │   ├── index.ts
│   │   ├── routes/
│   │   ├── middleware/
│   │   └── services/
│   ├── batch-processor/     # Batch job worker
│   └── webhook-handler/     # Webhook notifications
├── shared/
│   ├── types/
│   ├── utils/
│   └── validation/
└── database/
    ├── migrations/
    └── seeds/
```

#### 3.2.2 External Integrations
```typescript
// TTS Provider interfaces
interface TTSProvider {
  generateSpeech(text: string, options: TTSOptions): Promise<AudioBuffer>;
  getVoices(): Promise<Voice[]>;
  validateConfig(config: ProviderConfig): boolean;
}

// Implementations for each provider
class AzureTTSProvider implements TTSProvider { ... }
class AWSPollyProvider implements TTSProvider { ... }
class GoogleCloudTTSProvider implements TTSProvider { ... }
```

### 3.3 Database Schema

#### 3.3.1 D1 Tables
```sql
-- Users table
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  role TEXT DEFAULT 'user',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- API Keys table  
CREATE TABLE api_keys (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  key_hash TEXT NOT NULL,
  name TEXT NOT NULL,
  permissions JSON,
  rate_limit INTEGER DEFAULT 100,
  expires_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- TTS Jobs table
CREATE TABLE tts_jobs (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  provider TEXT NOT NULL,
  voice TEXT NOT NULL,
  text TEXT NOT NULL,
  options JSON,
  status TEXT DEFAULT 'pending',
  audio_url TEXT,
  error_message TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  completed_at DATETIME,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Usage Statistics table
CREATE TABLE usage_stats (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  date DATE NOT NULL,
  requests_count INTEGER DEFAULT 0,
  characters_processed INTEGER DEFAULT 0,
  audio_duration INTEGER DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Provider Configurations table
CREATE TABLE provider_configs (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  provider TEXT NOT NULL,
  config JSON NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

---

## 6. API Keys & Provider Setup Strategy

### 6.1 Existing Provider Credentials

#### 6.1.1 Current PowerShell Configuration
The existing system already has configured providers in `config.json`:

```json
// Current encrypted keys in config.json
"Azure Cognitive Services": {
  "ApiKey": "ENCRYPTED:test-key-12345",  // ← Extract this for web platform
  "Datacenter": "eastus"
},
"AWS Polly": {
  "AccessKey": "ENCRYPTED:AKIA...",      // ← Extract this for web platform  
  "SecretKey": "ENCRYPTED:secret123"
}
```

#### 6.1.2 Key Migration Strategy
**During Implementation**:
1. **Phase 1**: Use test/demo keys for initial development
2. **Phase 2**: Agent should prompt for real provider API keys
3. **Phase 3**: Import existing keys from PowerShell config (if user provides decryption)

**Key Request Flow**:
```typescript
// Implementation guidance for agent
const providerSetupFlow = {
  azure: {
    required: ['apiKey', 'region'],
    prompt: 'Please provide your Azure Cognitive Services API key and region',
    validation: 'Key should be 32 characters, region should be valid Azure region',
    testEndpoint: 'GET https://{region}.api.cognitive.microsoft.com/sts/v1.0/issuetoken'
  },
  aws: {
    required: ['accessKeyId', 'secretAccessKey', 'region'],
    prompt: 'Please provide your AWS Access Key ID, Secret Access Key, and region',
    validation: 'Access Key should start with AKIA, Secret should be 40 characters',
    testEndpoint: 'POST https://polly.{region}.amazonaws.com/'
  }
  // ... other providers
};
```

### 6.2 Progressive Provider Implementation

#### 6.2.1 Phase 1: Single Provider (Azure)
**Why Azure First**: 
- Already configured in existing PowerShell system
- Comprehensive voice selection
- Good SSML support
- Reliable API

**Implementation Priority**:
```typescript
// Phase 1 minimal implementation
export class Phase1TTSService {
  private azureProvider: AzureTTSProvider;
  
  constructor() {
    // Start with Azure only, add others in Phase 2
    this.azureProvider = new AzureTTSProvider({
      apiKey: process.env.AZURE_TTS_API_KEY,
      region: process.env.AZURE_TTS_REGION || 'eastus'
    });
  }
  
  async generateSpeech(request: TTSRequest): Promise<TTSResponse> {
    // Phase 1: Route all requests to Azure
    return this.azureProvider.generateSpeech(request.text, request.options);
  }
}
```

#### 6.2.2 Phase 2: Multi-Provider Architecture
```typescript
// Phase 2 expanded implementation
export class MultiProviderTTSService {
  private providers: Map<string, TTSProvider> = new Map();
  
  constructor() {
    // Initialise all providers that have valid configurations
    this.initialiseProviders();
  }
  
  private initialiseProviders() {
    const configs = this.loadProviderConfigs();
    
    if (configs.azure?.apiKey) {
      this.providers.set('azure', new AzureTTSProvider(configs.azure));
    }
    if (configs.aws?.accessKeyId) {
      this.providers.set('aws', new AWSPollyProvider(configs.aws));
    }
    // ... continue for all 6 providers
  }
}
```

### 6.3 Environment Setup Requirements

#### 6.3.1 Development Environment
**Required for Agent Setup**:
```bash
# Cloudflare CLI setup
npm install -g @cloudflare/wrangler-cli

# Create development workspace
mkdir tts-web-platform
cd tts-web-platform

# Initialise Cloudflare project
wrangler init tts-api --type="worker-router"
wrangler pages project create tts-frontend

# Setup database
wrangler d1 create tts-database
wrangler r2 bucket create tts-audio-storage
```

#### 6.3.2 Local Development Stack
```javascript
// package.json for local development
{
  "scripts": {
    "dev:frontend": "vite dev --port 3000",
    "dev:api": "wrangler dev --port 8787",
    "dev:db": "wrangler d1 execute tts-database --local --file=./schema.sql",
    "dev": "concurrently \"npm run dev:frontend\" \"npm run dev:api\""
  },
  "devDependencies": {
    "concurrently": "^8.2.0",
    "@cloudflare/workers-types": "^4.20231025.0"
  }
}
```

### 6.4 Testing Strategy with Existing PowerShell Tests

#### 6.4.1 Test Case Migration
**Reference**: `Tests/Unit/TTSProviders.Tests.ps1`

```typescript
// Convert PowerShell tests to TypeScript/Jest
describe('AzureTTSProvider', () => {
  // PowerShell test: "Should validate Azure configuration"  
  it('should validate Azure configuration', () => {
    const provider = new AzureTTSProvider();
    const validConfig = {
      apiKey: 'fake-azure-api-key-for-testing',
      region: 'eastus'
    };
    expect(provider.validateConfig(validConfig)).toBe(true);
  });
  
  // PowerShell test: "Should generate speech with valid input"
  it('should generate speech with valid input', async () => {
    const provider = new AzureTTSProvider(testConfig);
    const result = await provider.generateSpeech('Hello world', {
      voice: 'en-US-JennyNeural',
      format: 'audio-16khz-32kbitrate-mono-mp3'
    });
    expect(result).toBeInstanceOf(ArrayBuffer);
    expect(result.byteLength).toBeGreaterThan(0);
  });
});
```

#### 6.4.2 Integration Test Patterns
**Reference**: `Tests/Integration/SystemIntegration.Tests.ps1`

```typescript
// Convert integration tests
describe('TTS System Integration', () => {
  it('should handle provider failover', async () => {
    // Test pattern from PowerShell integration tests
    const service = new TTSService();
    
    // Simulate provider failure
    jest.spyOn(service['providers'].get('azure')!, 'generateSpeech')
        .mockRejectedValueOnce(new Error('Provider unavailable'));
    
    // Should fallback to next available provider
    const result = await service.generateSpeech({
      text: 'Test failover',
      preferredProvider: 'azure'
    });
    
    expect(result.provider).not.toBe('azure');
    expect(result.success).toBe(true);
  });
});
```

---

## 7. Deployment & CI/CD Requirements

### 7.1 GitHub Actions Workflow

#### 7.1.1 Repository Structure
```
.github/
└── workflows/
    ├── deploy-staging.yml    # Deploy to staging environment
    ├── deploy-production.yml # Deploy to production
    ├── test.yml             # Run tests and quality checks
    └── security-scan.yml    # Security and dependency scanning
```

#### 7.1.2 Deployment Pipeline
```yaml
# .github/workflows/deploy-production.yml
name: Deploy to Production

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  BASE_DOMAIN: ${{ vars.BASE_DOMAIN }}

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Build frontend
        run: npm run build
        env:
          VITE_API_BASE_URL: https://api.${{ vars.BASE_DOMAIN }}
          
      - name: Deploy to Cloudflare Pages
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: tts-generator-web
          directory: dist
          
      - name: Deploy Workers
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: deploy --env production
          
      - name: Run Database Migrations
        run: npx wrangler d1 migrations apply tts-generator-db --env production
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          CLOUDFLARE_ACCOUNT_ID: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
```

### 7.2 Required GitHub Secrets

#### 4.2.1 Cloudflare Configuration
```bash
# Required GitHub Repository Secrets:

# Cloudflare Access
CLOUDFLARE_API_TOKEN=<Global API Key or scoped token>
CLOUDFLARE_ACCOUNT_ID=<Cloudflare Account ID>
CLOUDFLARE_ZONE_ID=<DNS Zone ID for BASE_DOMAIN>

# Database
CLOUDFLARE_D1_DATABASE_ID=<D1 Database ID>

# R2 Storage
CLOUDFLARE_R2_ACCESS_KEY_ID=<R2 Access Key>
CLOUDFLARE_R2_SECRET_ACCESS_KEY=<R2 Secret Key>
CLOUDFLARE_R2_BUCKET_NAME=<R2 Bucket Name>

# JWT Configuration  
JWT_SECRET=<Strong random string for JWT signing>
JWT_ISSUER=<JWT issuer identifier>

# TTS Provider API Keys
AZURE_TTS_API_KEY=<Azure Cognitive Services Key>
AZURE_TTS_REGION=<Azure Region>

AWS_ACCESS_KEY_ID=<AWS Access Key>
AWS_SECRET_ACCESS_KEY=<AWS Secret Key>
AWS_REGION=<AWS Region>

GOOGLE_CLOUD_PROJECT_ID=<GCP Project ID>
GOOGLE_CLOUD_SERVICE_ACCOUNT=<GCP Service Account JSON>

CLOUDPRONOUNCER_API_KEY=<CloudPronouncer API Key>
CLOUDPRONOUNCER_USERNAME=<CloudPronouncer Username>

TWILIO_ACCOUNT_SID=<Twilio Account SID>
TWILIO_AUTH_TOKEN=<Twilio Auth Token>

VOICEFORGE_API_KEY=<VoiceForge API Key>
VOICEFORGE_USERNAME=<VoiceForge Username>

# Monitoring & Analytics
SENTRY_DSN=<Sentry error tracking DSN>
POSTHOG_API_KEY=<PostHog analytics key>

# Email Service (for notifications)
SENDGRID_API_KEY=<SendGrid API Key>
EMAIL_FROM_ADDRESS=<From email address>
```

#### 4.2.2 Required GitHub Repository Variables
```bash
# Repository Variables (not secret, but configurable):
BASE_DOMAIN=yourdomain.com
ENVIRONMENT=production
API_VERSION=v1
FRONTEND_SUBDOMAIN=app
API_SUBDOMAIN=api
```

### 4.3 Secret Creation Guide

#### 4.3.1 Cloudflare Setup
```bash
# 1. Create Cloudflare API Token
# Go to: https://dash.cloudflare.com/profile/api-tokens
# Template: "Custom Token"
# Permissions:
#   - Zone:Zone:Read (for all zones)
#   - Zone:DNS:Edit (for your domain)
#   - Account:Cloudflare Workers:Edit
#   - Account:D1:Edit
#   - Account:R2:Edit

# 2. Get Account ID
# Found in: Cloudflare Dashboard > Right sidebar

# 3. Get Zone ID  
# Found in: Cloudflare Dashboard > Your Domain > Overview > Right sidebar

# 4. Create D1 Database
npx wrangler d1 create tts-generator-db

# 5. Create R2 Bucket
npx wrangler r2 bucket create tts-audio-storage
```

#### 4.3.2 Provider API Keys Setup
```bash
# Azure Cognitive Services
# 1. Go to Azure Portal
# 2. Create "Cognitive Services" resource
# 3. Copy API key and region

# AWS Polly
# 1. Go to AWS IAM
# 2. Create user with Polly permissions
# 3. Generate access key pair

# Google Cloud TTS
# 1. Go to Google Cloud Console
# 2. Enable Cloud Text-to-Speech API
# 3. Create service account
# 4. Download JSON key file
# 5. Copy JSON content to secret

# Other providers - follow their respective documentation
```

---

## 8. Agent Implementation Guidelines & FAQ

### 8.1 Direct Answers to Agent Questions

#### 8.1.1 ✅ Technology Stack Confirmation
**CONFIRMED**: Use Cloudflare stack exactly as specified:
- **Frontend**: React 18+ → Cloudflare Pages
- **Backend**: TypeScript/JavaScript → Cloudflare Workers
- **Database**: SQLite → Cloudflare D1
- **Storage**: Object Storage → Cloudflare R2
- **NOT**: FastAPI, MongoDB, or traditional hosting

#### 8.1.2 ✅ Project Scope Clarification  
**CONFIRMED**: Complete rewrite using PowerShell as reference
- **DO**: Create entirely new web application from scratch
- **DO**: Use PowerShell modules as functional specification
- **DO**: Preserve exact same functionality and configuration structure
- **DON'T**: Port/migrate PowerShell code directly
- **DON'T**: Try to run PowerShell in web environment

#### 8.1.3 ✅ API Key Strategy
**PHASE 1 (Development)**: Use test/demo keys
```bash
# Test keys for development (agent can use these)
AZURE_TTS_API_KEY="demo-key-for-development"
AWS_ACCESS_KEY_ID="DEMO-ACCESS-KEY"
AWS_SECRET_ACCESS_KEY="demo-secret-key"
```

**PHASE 2 (Production)**: Prompt user for real keys
```typescript
// Agent should implement this flow
const setupWizard = {
  async promptForKeys() {
    console.log('🔑 TTS Provider Setup Required');
    console.log('Please provide API keys for TTS providers:');
    
    const keys = await inquirer.prompt([
      {
        type: 'input',
        name: 'azureApiKey',
        message: 'Azure Cognitive Services API Key:',
        validate: (input) => input.length === 32 || 'Should be 32 characters'
      },
      {
        type: 'input', 
        name: 'azureRegion',
        message: 'Azure Region (e.g., eastus):',
        default: 'eastus'
      }
      // ... continue for other providers
    ]);
    
    return keys;
  }
};
```

#### 8.1.4 ✅ Implementation Priority
**START WITH**: Phase 1 implementation
1. **Week 1**: Basic React UI + Cloudflare Workers setup
2. **Week 1**: Single TTS provider (Azure) working end-to-end
3. **Week 2**: Authentication and database integration
4. **Week 2**: Deploy to staging environment

**THEN EXPAND**: Add remaining providers and features

### 8.2 Development Workflow for Agent

#### 8.2.1 Initial Setup Checklist
```bash
# Agent should follow this exact sequence:
□ 1. Create new repository: tts-web-platform
□ 2. Initialise React frontend with Vite + TypeScript
□ 3. Initialise Cloudflare Workers project
□ 4. Set up Cloudflare D1 database
□ 5. Create basic authentication system
□ 6. Implement single Azure TTS provider
□ 7. Deploy to Cloudflare (staging)
□ 8. Add remaining TTS providers
□ 9. Implement batch processing
□ 10. Add monitoring and analytics
```

#### 8.2.2 Code Structure for Agent
```
tts-web-platform/
├── frontend/                    # React application
│   ├── src/
│   │   ├── components/
│   │   ├── services/
│   │   ├── hooks/
│   │   └── types/
│   ├── package.json
│   └── vite.config.ts
├── backend/                     # Cloudflare Workers
│   ├── src/
│   │   ├── routes/
│   │   ├── services/
│   │   ├── providers/           # TTS provider implementations
│   │   └── types/
│   ├── wrangler.toml
│   └── package.json
├── database/
│   ├── schema.sql
│   └── migrations/
└── .github/
    └── workflows/
        ├── deploy-staging.yml
        └── deploy-production.yml
```

#### 8.2.3 Provider Implementation Order
```typescript
// Agent should implement providers in this order:
const implementationOrder = [
  // Phase 1: Single provider (Week 1)
  'azure-cognitive',              // Most reliable, good docs
  
  // Phase 2: Major cloud providers (Week 2)  
  'aws-polly',                   // Second most common
  'google-cloud-tts',            // Third major cloud provider
  
  // Phase 3: Specialised providers (Week 3)
  'cloudpronouncer',             // Niche but established
  'twilio',                      // Good for programmatic use
  'voiceforge'                   // Last priority
];
```

### 8.3 Testing Instructions for Agent

#### 8.3.1 Reference Test Cases
**Agent should convert these PowerShell tests to TypeScript**:

```bash
# PowerShell tests to reference:
Tests/Unit/TTSProviders.Tests.ps1         # Provider validation tests
Tests/Unit/Configuration.Tests.ps1        # Configuration management tests
Tests/Performance/BulkProcessing.Tests.ps1 # Performance benchmarks
Tests/Integration/SystemIntegration.Tests.ps1 # End-to-end workflows
```

#### 8.3.2 Test Implementation Pattern
```typescript
// Pattern for agent to follow when converting tests:
describe('Provider Tests (from PowerShell)', () => {
  // Convert: "Should validate Azure configuration"
  it('validates Azure configuration correctly', async () => {
    const provider = new AzureTTSProvider();
    const config = { apiKey: 'test-key', region: 'eastus' };
    expect(provider.validateConfig(config)).toBe(true);
  });
  
  // Convert: "Should handle invalid API key"  
  it('rejects invalid API key', async () => {
    const provider = new AzureTTSProvider();
    const config = { apiKey: 'invalid', region: 'eastus' };
    expect(provider.validateConfig(config)).toBe(false);
  });
});
```

### 8.4 Cloudflare Account Setup

#### 8.4.1 What Agent Needs from User
**During Setup Phase**, agent should ask user for:
```bash
# Required Cloudflare Information:
1. "Do you have a Cloudflare account? (create free at cloudflare.com)"
2. "Please provide your Cloudflare Account ID (found in dashboard sidebar)"
3. "Please create and provide a Cloudflare API Token with Workers:Edit permissions"
4. "What domain will you use? (e.g., yourdomain.com)"
```

#### 8.4.2 Automated Setup Commands
**Agent can run these commands for user**:
```bash
# After getting Cloudflare credentials:
npx wrangler auth token <USER_PROVIDED_TOKEN>
npx wrangler d1 create tts-database
npx wrangler r2 bucket create tts-audio-files
npx wrangler pages project create tts-frontend
```

---

## 9. Configuration Files

### 9.1 Wrangler Configuration
```toml
# wrangler.toml
name = "tts-generator-api"
main = "src/workers/api/index.ts"
compatibility_date = "2023-10-14"

[env.production]
name = "tts-generator-api-prod"
route = { pattern = "api.${BASE_DOMAIN}/*", zone_name = "${BASE_DOMAIN}" }

[[env.production.d1_databases]]
binding = "DB"
database_name = "tts-generator-db"
database_id = "${CLOUDFLARE_D1_DATABASE_ID}"

[[env.production.r2_buckets]]
binding = "AUDIO_STORAGE"
bucket_name = "${CLOUDFLARE_R2_BUCKET_NAME}"

[env.production.vars]
ENVIRONMENT = "production"
API_VERSION = "v1"
BASE_DOMAIN = "${BASE_DOMAIN}"

[env.staging]
name = "tts-generator-api-staging"
route = { pattern = "api-staging.${BASE_DOMAIN}/*", zone_name = "${BASE_DOMAIN}" }
```

### 9.2 Frontend Configuration
```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
  },
  define: {
    __APP_VERSION__: JSON.stringify(process.env.npm_package_version),
  },
});
```

---

## 10. Testing Requirements

### 10.1 Testing Strategy
- **Unit Tests**: 80%+ code coverage
- **Integration Tests**: API endpoints and database operations
- **E2E Tests**: Critical user journeys
- **Performance Tests**: Load testing for API endpoints
- **Security Tests**: Authentication and authorisation

### 10.2 Test Files Structure
```
tests/
├── unit/
│   ├── components/
│   ├── services/
│   └── utils/
├── integration/
│   ├── api/
│   └── database/
├── e2e/
│   ├── user-flows/
│   └── admin-flows/
└── performance/
    ├── load-tests/
    └── stress-tests/
```

---

## 11. Migration Strategy

### 11.1 Data Migration
- Export existing PowerShell configurations to JSON
- Create migration scripts for user data
- Preserve TTS provider settings and preferences
- Migrate historical usage data (if applicable)

### 11.2 Feature Parity Checklist
- [ ] All TTS providers supported
- [ ] Voice selection and configuration
- [ ] Batch processing capabilities
- [ ] Audio format options
- [ ] Advanced speech controls
- [ ] Configuration profiles
- [ ] Logging and monitoring
- [ ] Error handling and recovery

---

## 12. Success Criteria

### 12.1 Performance Metrics
- API response time: < 200ms (95th percentile)
- Frontend load time: < 3 seconds
- Audio generation: < 30 seconds for 1000 characters
- Uptime: 99.9% availability

### 12.2 User Experience Goals
- Intuitive interface requiring no documentation
- Support for all major browsers and devices
- Accessibility compliance (WCAG 2.1 AA)
- Progressive Web App capabilities

### 12.3 Business Objectives
- Reduce infrastructure costs by 60% vs traditional hosting
- Support 10x more concurrent users
- Enable API monetization and usage-based billing
- Achieve sub-second global response times

---

## 13. Timeline & Milestones

### Phase 1: Foundation (Weeks 1-2)
- Set up Cloudflare infrastructure
- Create basic React application
- Implement authentication system
- Set up CI/CD pipeline

### Phase 2: Core Features (Weeks 3-4)
- Implement TTS provider integrations
- Build main user interface
- Create API endpoints
- Set up database schema

### Phase 3: Advanced Features (Weeks 5-6)
- Batch processing system
- Usage analytics and monitoring  
- Admin interface
- Performance optimisation

### Phase 4: Polish & Launch (Weeks 7-8)
- Security audit and testing
- Documentation and training
- Performance testing and optimisation
- Production deployment and monitoring

---

## Appendices

### A. Glossary
- **D1**: Cloudflare's serverless SQL database
- **R2**: Cloudflare's object storage service
- **Workers**: Cloudflare's serverless compute platform
- **Pages**: Cloudflare's static site hosting service
- **SSML**: Speech Synthesis Markup Language
- **JWT**: JSON Web Token

### B. References
- [Cloudflare Workers Documentation](https://developers.cloudflare.com/workers/)
- [Cloudflare D1 Documentation](https://developers.cloudflare.com/d1/)
- [React Documentation](https://react.dev/)
- [OpenAPI Specification](https://spec.openapis.org/oas/v3.0.3)

---

## Quick Reference for Implementation

### 🚀 Agent Quick Start Commands
```bash
# 1. Setup new project
mkdir tts-web-platform && cd tts-web-platform
npm create vite@latest frontend -- --template react-ts
npx create-cloudflare@latest backend -- --type worker-router

# 2. Initialise Cloudflare services  
npx wrangler d1 create tts-database
npx wrangler r2 bucket create tts-audio-storage
npx wrangler pages project create tts-frontend

# 3. Setup development environment
npm install && npm run dev
```

### 📋 Implementation Checklist
- [ ] **Phase 1**: React frontend + Cloudflare Workers backend
- [ ] **Phase 1**: Azure TTS provider integration  
- [ ] **Phase 1**: Basic authentication system
- [ ] **Phase 1**: Single TTS generation working end-to-end
- [ ] **Phase 2**: All 6 TTS providers implemented
- [ ] **Phase 2**: Batch processing system
- [ ] **Phase 3**: Usage analytics and monitoring
- [ ] **Phase 3**: Production deployment pipeline

### 🔑 Key Files to Reference
```
PowerShell Reference → Web Implementation
├── config.json → D1 database schema
├── Modules/TTSProviders/*.psm1 → TypeScript provider classes
├── Tests/Unit/*.Tests.ps1 → Jest/Vitest test files
└── StartModularTTS.ps1 → API endpoint logic
```

### ⚡ Success Definition
- ✅ Feature parity with PowerShell version
- ✅ All 6 TTS providers working
- ✅ Sub-200ms API response times
- ✅ Deployed on Cloudflare infrastructure
- ✅ GitHub Actions CI/CD pipeline
- ✅ Comprehensive test coverage

---

*Document prepared by: GitHub Copilot Assistant*  
*Last updated: October 15, 2025*  
*Version: 1.1 (Expanded with implementation guidance)*
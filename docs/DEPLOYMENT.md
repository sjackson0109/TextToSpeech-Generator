# Enterprise Deployment Guide

## Overview
This guide covers enterprise deployment strategies for TextToSpeech Generator v3.2 in production environments.

## Prerequisites

### System Requirements
- **Operating System**: Windows Server 2016+ or Windows 10/11 Enterprise
- **PowerShell**: Version 5.1 or higher
- **.NET Framework**: 4.7.2 or higher
- **Memory**: Minimum 4GB RAM (8GB+ recommended for bulk processing)
- **Storage**: 100MB for application + storage for audio files
- **Network**: HTTPS outbound access for TTS provider APIs

### Security Requirements
- **Certificate Store Access**: For encryption certificate creation
- **Credential Manager**: For secure API key storage
- **File System Permissions**: Read/write access to application directory
- **Registry Access**: For configuration storage (optional)

## Deployment Methods

### Method 1: Direct Installation
```powershell
# Clone repository
git clone https://github.com/sjackson0109/TextToSpeech-Generator.git
cd TextToSpeech-Generator

# Set execution policy (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run initial setup
.\StartModularTTS.ps1 -TestMode
```

### Method 2: Automated Deployment Script
```powershell
# Create deployment script
$deployScript = @"
# Automated TTS Generator Deployment
param([string]`$InstallPath = "C:\Program Files\TTSGenerator")

# Create installation directory
New-Item -ItemType Directory -Path `$InstallPath -Force

# Copy application files
Copy-Item -Path ".\*" -Destination `$InstallPath -Recurse -Force

# Create application shortcut
`$WshShell = New-Object -comObject WScript.Shell
`$Shortcut = `$WshShell.CreateShortcut("`$env:PUBLIC\Desktop\TTS Generator.lnk")
`$Shortcut.TargetPath = "powershell.exe"
`$Shortcut.Arguments = "-ExecutionPolicy Bypass -File ```"`$InstallPath\StartModularTTS.ps1```""
`$Shortcut.Save()
"@

$deployScript | Out-File -FilePath "Deploy-TTSGenerator.ps1" -Encoding UTF8
```

### Method 3: MSI Package (Advanced)
For enterprise environments requiring MSI installation packages, consider using tools like:
- **WiX Toolset**: Create Windows Installer packages
- **Advanced Installer**: GUI-based MSI creation
- **InstallShield**: Professional installation package creation

## Configuration Management

### Environment Profiles
The application supports three deployment profiles:

#### Development Profile
- Debug logging enabled
- Test API keys
- Local file paths
- Reduced performance monitoring

#### Production Profile  
- Optimised performance settings
- Encrypted API keys
- Network paths supported
- Comprehensive monitoring

#### Testing Profile
- Mock providers enabled
- Validation-only mode
- Extended logging
- Performance benchmarking

### Configuration Deployment
```powershell
# Deploy production configuration
$prodConfig = @{
    ConfigVersion = "3.2"
    CurrentProfile = "Production"
    Profiles = @{
        Production = @{
            Processing = @{
                OutputPath = "\\server\tts-output"
                MaxParallelJobs = 6
                Timeout = 60
            }
            Providers = @{
                "Azure Cognitive Services" = @{
                    ApiKey = "ENCRYPTED:base64encodedkey"
                    Datacenter = "eastus"
                    Enabled = $true
                }
            }
        }
    }
}

$prodConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath "config.json"
```

## Security Considerations

### API Key Management
1. **Never store plain-text API keys in configuration**
2. **Use the built-in encryption system**
3. **Consider Azure Key Vault for enterprise scenarios**
4. **Implement key rotation procedures**

### Network Security
- **Firewall Rules**: Allow HTTPS outbound to TTS provider endpoints
- **Proxy Configuration**: Configure proxy settings if required
- **Certificate Validation**: Ensure SSL/TLS certificate validation

### Access Control
- **File Permissions**: Restrict access to configuration files
- **User Accounts**: Run with least-privilege service accounts
- **Audit Logging**: Enable comprehensive audit trails

## Performance Optimisation

### Bulk Processing
```powershell
# Optimise for bulk processing
$bulkConfig = @{
    MaxParallelJobs = [Environment]::ProcessorCount
    ChunkSize = 1000
    CacheEnabled = $true
    MemoryThreshold = 80
}
```

### Network Optimisation
- **Connection Pooling**: Reuse HTTP connections
- **Retry Logic**: Implement exponential backoff
- **Load Balancing**: Distribute requests across regions

### Storage Optimisation
- **SSD Storage**: Use SSDs for temporary files
- **Network Storage**: Use high-speed network storage for outputs
- **Cleanup Policies**: Implement automatic cleanup of temporary files

## Monitoring and Maintenance

### Application Monitoring
```powershell
# Enable comprehensive monitoring
.\StartModularTTS.ps1 -EnablePerformanceMonitoring -GenerateReport
```

### Log Management
- **Log Rotation**: Automatic log rotation (10MB max, 5 files)
- **Centralized Logging**: Forward logs to SIEM systems
- **Error Alerting**: Configure alerts for error patterns

### Performance Metrics
Monitor these key metrics:
- **Request latency**: Time per TTS request
- **Success rate**: Percentage of successful conversions
- **Memory usage**: Application memory consumption
- **API quota**: Remaining API limits

## Troubleshooting

### Common Issues
1. **Certificate Errors**: Ensure certificate store access
2. **Network Connectivity**: Verify firewall and proxy settings
3. **Permission Errors**: Check file system permissions
4. **API Limits**: Monitor API quota consumption

### Diagnostic Commands
```powershell
# System diagnostics
.\StartModularTTS.ps1 -TestMode -RunTests

# Configuration validation
Test-ModuleConfiguration -ConfigPath "config.json"

# Network connectivity
Test-NetConnection -ComputerName "eastus.tts.speech.microsoft.com" -Port 443
```

## Backup and Recovery

### Configuration Backup
```powershell
# Automated backup script
$backupPath = "\\backup-server\tts-configs\$(Get-Date -Format 'yyyyMMdd')"
Copy-Item -Path "config.json" -Destination "$backupPath\config.json.bak"
Copy-Item -Path "application.log" -Destination "$backupPath\application.log.bak"
```

### Disaster Recovery
1. **Configuration Files**: Regular backup of config.json
2. **Encryption Certificates**: Export and securely store certificates
3. **Application State**: Document current deployment configuration
4. **Recovery Testing**: Regular recovery procedure testing

## Enterprise Integration

### Active Directory Integration
```powershell
# AD group-based access control
$adGroup = "TTS-Operators"
if ((Get-ADGroupMember -Identity $adGroup).SamAccountName -contains $env:USERNAME) {
    # Allow access
    .\StartModularTTS.ps1
} else {
    Write-Error "Access denied. Contact administrator."
}
```

### SCCM Deployment
For System Center Configuration Manager deployment:
1. Create application package with StartModularTTS.ps1
2. Configure detection rules for installed version
3. Set deployment requirements (OS version, PowerShell version)
4. Configure user experience settings

### Group Policy
Configure via Group Policy:
- **Execution Policy**: Set PowerShell execution policy
- **File Associations**: Associate .tts files with application
- **Desktop Shortcuts**: Deploy shortcuts to user desktops

## Compliance and Governance

### Audit Requirements
- **Configuration Changes**: Log all configuration modifications
- **API Usage**: Track API consumption and costs
- **User Activity**: Log user access and operations
- **Data Processing**: Maintain processing audit trails

### Data Privacy
- **GDPR Compliance**: Implement data retention policies
- **Data Classification**: Classify processed text content
- **Access Logging**: Log who processes what content
- **Data Purging**: Automatic cleanup of processed data

## Support and Maintenance

### Update Procedures
1. **Testing Environment**: Deploy updates to test environment first
2. **Validation**: Run comprehensive tests before production deployment
3. **Rollback Plan**: Maintain ability to rollback to previous version
4. **Documentation**: Update deployment documentation

### Maintenance Schedule
- **Weekly**: Review application logs and performance metrics
- **Monthly**: Update API keys and certificates as needed  
- **Quarterly**: Review and update security configurations
- **Annually**: Full security audit and penetration testing

## Contact Information

For enterprise deployment support:
- **GitHub Issues**: https://github.com/sjackson0109/TextToSpeech-Generator/issues
- **Documentation**: https://github.com/sjackson0109/TextToSpeech-Generator/blob/main/README.md
- **Security Issues**: Report via GitHub Security tab
# Enhanced Security Module for TextToSpeech Generator v3.2
# Provides certificate-based encryption, secure storage, and audit trails

Add-Type -AssemblyName System.Security

# Security configuration
$script:SecurityConfig = @{
    EncryptionKeySize = 256
    CertificateStore = "CurrentUser"
    CertificateLocation = "My"
    AuditLogPath = ""
    SecureStorageEnabled = $true
}

class SecureConfigurationManager {
    [string] $EncryptionCertThumbprint
    [hashtable] $SecureStorage
    [string] $ConfigPath
    
    SecureConfigurationManager([string]$configPath) {
        $this.ConfigPath = $configPath
        $this.SecureStorage = @{}
        $this.Initialise()
    }
    
    [void] Initialise() {
        # Initialise secure storage and certificate
        $this.EnsureEncryptionCertificate()
        $this.LoadSecureConfiguration()
    }
    
    [void] EnsureEncryptionCertificate() {
        # Find or create encryption certificate
        $certs = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object { 
            $_.Subject -like "*TextToSpeech-Generator*" -and 
            $_.HasPrivateKey -eq $true 
        }
        
        if (-not $certs) {
            Write-ApplicationLog -Message "Creating new encryption certificate for secure storage" -Level "INFO"
            $this.CreateEncryptionCertificate()
        } else {
            $this.EncryptionCertThumbprint = $certs[0].Thumbprint
            Write-ApplicationLog -Message "Using existing encryption certificate: $($this.EncryptionCertThumbprint)" -Level "INFO"
        }
    }
    
    [void] CreateEncryptionCertificate() {
        try {
            $cert = New-SelfSignedCertificate -Subject "CN=TextToSpeech-Generator-Encryption" `
                -KeyUsage KeyEncipherment,DataEncipherment `
                -Type DocumentEncryptionCert `
                -HashAlgorithm SHA256 `
                -KeyLength 2048 `
                -CertStoreLocation "Cert:\CurrentUser\My" `
                -NotAfter (Get-Date).AddYears(5)
            
            $this.EncryptionCertThumbprint = $cert.Thumbprint
            Write-ApplicationLog -Message "Created encryption certificate: $($this.EncryptionCertThumbprint)" -Level "INFO"
        }
        catch {
            Write-ErrorLog -Operation "CreateEncryptionCertificate" -Exception $_.Exception
            throw "Failed to create encryption certificate: $($_.Exception.Message)"
        }
    }
    
    [string] EncryptString([string]$plainText) {
        try {
            if ([string]::IsNullOrEmpty($plainText)) {
                return ""
            }
            
            $cert = Get-Item "Cert:\CurrentUser\My\$($this.EncryptionCertThumbprint)"
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($plainText)
            $encryptedBytes = $cert.PublicKey.Key.Encrypt($bytes, $true)
            return [Convert]::ToBase64String($encryptedBytes)
        }
        catch {
            Write-ErrorLog -Operation "EncryptString" -Exception $_.Exception
            throw "Encryption failed: $($_.Exception.Message)"
        }
    }
    
    [string] DecryptString([string]$encryptedText) {
        try {
            if ([string]::IsNullOrEmpty($encryptedText)) {
                return ""
            }
            
            $cert = Get-Item "Cert:\CurrentUser\My\$($this.EncryptionCertThumbprint)"
            $encryptedBytes = [Convert]::FromBase64String($encryptedText)
            $decryptedBytes = $cert.PrivateKey.Decrypt($encryptedBytes, $true)
            return [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
        }
        catch {
            Write-ErrorLog -Operation "DecryptString" -Exception $_.Exception
            throw "Decryption failed: $($_.Exception.Message)"
        }
    }
    
    [hashtable] EncryptConfiguration([hashtable]$config) {
        $encryptedConfig = @{}
        
        foreach ($key in $config.Keys) {
            $value = $config[$key]
            
            # Encrypt sensitive fields
            if ($key -match "APIKey|Password|Secret|Token|Key") {
                $encryptedConfig[$key] = @{
                    Value = $this.EncryptString($value)
                    Encrypted = $true
                }
                Write-SecurityLog -Event "ConfigurationEncryption" -Action "EncryptedField" -Details @{ Field = $key }
            } else {
                $encryptedConfig[$key] = @{
                    Value = $value
                    Encrypted = $false
                }
            }
        }
        
        return $encryptedConfig
    }
    
    [hashtable] DecryptConfiguration([hashtable]$encryptedConfig) {
        $config = @{}
        
        foreach ($key in $encryptedConfig.Keys) {
            $item = $encryptedConfig[$key]
            
            if ($item.Encrypted -eq $true) {
                $config[$key] = $this.DecryptString($item.Value)
                Write-SecurityLog -Event "ConfigurationDecryption" -Action "DecryptedField" -Details @{ Field = $key }
            } else {
                $config[$key] = $item.Value
            }
        }
        
        return $config
    }
    
    [void] SaveSecureConfiguration([hashtable]$config) {
        try {
            $encryptedConfig = $this.EncryptConfiguration($config)
            $configData = @{
                Version = "3.2"
                Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                CertificateThumbprint = $this.EncryptionCertThumbprint
                Configuration = $encryptedConfig
            }
            
            $json = $configData | ConvertTo-Json -Depth 10
            Set-Content -Path $this.ConfigPath -Value $json -Encoding UTF8
            
            Write-ApplicationLog -Message "Secure configuration saved to $($this.ConfigPath)" -Level "INFO"
            Write-SecurityLog -Event "ConfigurationSave" -Action "SecureConfigurationSaved" -Details @{ Path = $this.ConfigPath }
        }
        catch {
            Write-ErrorLog -Operation "SaveSecureConfiguration" -Exception $_.Exception
            throw
        }
    }
    
    [hashtable] LoadSecureConfiguration() {
        try {
            if (-not (Test-Path $this.ConfigPath)) {
                Write-ApplicationLog -Message "No secure configuration file found, using defaults" -Level "INFO"
                return @{}
            }
            
            $json = Get-Content -Path $this.ConfigPath -Raw
            $configData = $json | ConvertFrom-Json -AsHashtable
            
            # Verify certificate compatibility
            if ($configData.CertificateThumbprint -ne $this.EncryptionCertThumbprint) {
                Write-ApplicationLog -Message "Certificate mismatch - configuration may not be decryptable" -Level "WARNING"
            }
            
            $config = $this.DecryptConfiguration($configData.Configuration)
            Write-ApplicationLog -Message "Secure configuration loaded from $($this.ConfigPath)" -Level "INFO"
            Write-SecurityLog -Event "ConfigurationLoad" -Action "SecureConfigurationLoaded" -Details @{ Path = $this.ConfigPath }
            
            return $config
        }
        catch {
            Write-ErrorLog -Operation "LoadSecureConfiguration" -Exception $_.Exception
            Write-ApplicationLog -Message "Failed to load secure configuration, using defaults" -Level "WARNING"
            return @{}
        }
    }
}

function Initialise-SecuritySystem {
    <#
    .SYNOPSIS
    Initializes the security system with configuration options
    #>
    param(
        [string]$AuditLogPath = (Join-Path $PSScriptRoot "security-audit.log"),
        [bool]$EnableSecureStorage = $true
    )
    
    $script:SecurityConfig.AuditLogPath = $AuditLogPath
    $script:SecurityConfig.SecureStorageEnabled = $EnableSecureStorage
    
    Write-ApplicationLog -Message "Security system initialized - SecureStorage: $EnableSecureStorage" -Level "INFO"
}

function New-SecureConfigurationManager {
    <#
    .SYNOPSIS
    Creates a new secure configuration manager instance
    #>
    param(
        [Parameter(Mandatory=$true)][string]$ConfigPath
    )
    
    return [SecureConfigurationManager]::new($ConfigPath)
}

function Protect-SensitiveData {
    <#
    .SYNOPSIS
    Encrypts sensitive data using certificate-based encryption
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Data,
        [string]$CertificateThumbprint
    )
    
    try {
        if ([string]::IsNullOrEmpty($CertificateThumbprint)) {
            # Find default certificate
            $certs = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object { 
                $_.Subject -like "*TextToSpeech-Generator*" -and $_.HasPrivateKey -eq $true 
            }
            if ($certs) {
                $CertificateThumbprint = $certs[0].Thumbprint
            } else {
                throw "No encryption certificate found"
            }
        }
        
        $cert = Get-Item "Cert:\CurrentUser\My\$CertificateThumbprint"
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Data)
        $encryptedBytes = $cert.PublicKey.Key.Encrypt($bytes, $true)
        
        Write-SecurityLog -Event "DataEncryption" -Action "SensitiveDataEncrypted"
        return [Convert]::ToBase64String($encryptedBytes)
    }
    catch {
        Write-ErrorLog -Operation "Protect-SensitiveData" -Exception $_.Exception
        throw
    }
}

function Unprotect-SensitiveData {
    <#
    .SYNOPSIS
    Decrypts sensitive data using certificate-based encryption
    #>
    param(
        [Parameter(Mandatory=$true)][string]$EncryptedData,
        [string]$CertificateThumbprint
    )
    
    try {
        if ([string]::IsNullOrEmpty($CertificateThumbprint)) {
            # Find default certificate
            $certs = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object { 
                $_.Subject -like "*TextToSpeech-Generator*" -and $_.HasPrivateKey -eq $true 
            }
            if ($certs) {
                $CertificateThumbprint = $certs[0].Thumbprint
            } else {
                throw "No encryption certificate found"
            }
        }
        
        $cert = Get-Item "Cert:\CurrentUser\My\$CertificateThumbprint"
        $encryptedBytes = [Convert]::FromBase64String($EncryptedData)
        $decryptedBytes = $cert.PrivateKey.Decrypt($encryptedBytes, $true)
        
        Write-SecurityLog -Event "DataDecryption" -Action "SensitiveDataDecrypted"
        return [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
    }
    catch {
        Write-ErrorLog -Operation "Unprotect-SensitiveData" -Exception $_.Exception
        throw
    }
}

function Test-SecurityConfiguration {
    <#
    .SYNOPSIS
    Tests the security configuration and reports any issues
    #>
    $results = @{
        OverallStatus = "Pass"
        Tests = @()
        Recommendations = @()
    }
    
    # Test certificate availability
    $certTest = @{
        Name = "Encryption Certificate"
        Status = "Pass"
        Details = ""
    }
    
    $certs = Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object { 
        $_.Subject -like "*TextToSpeech-Generator*" -and $_.HasPrivateKey -eq $true 
    }
    
    if (-not $certs) {
        $certTest.Status = "Fail"
        $certTest.Details = "No encryption certificate found"
        $results.OverallStatus = "Fail"
        $results.Recommendations += "Create encryption certificate using Initialise-SecuritySystem"
    } else {
        $certTest.Details = "Certificate found: $($certs[0].Thumbprint)"
    }
    $results.Tests += $certTest
    
    # Test certificate expiration
    $expirationTest = @{
        Name = "Certificate Expiration"
        Status = "Pass"
        Details = ""
    }
    
    if ($certs) {
        $daysUntilExpiry = ($certs[0].NotAfter - (Get-Date)).Days
        if ($daysUntilExpiry -lt 30) {
            $expirationTest.Status = "Warning"
            $expirationTest.Details = "Certificate expires in $daysUntilExpiry days"
            $results.Recommendations += "Renew encryption certificate before expiration"
        } else {
            $expirationTest.Details = "Certificate valid for $daysUntilExpiry days"
        }
    }
    $results.Tests += $expirationTest
    
    return $results
}

function Remove-SensitiveDataFromLogs {
    <#
    .SYNOPSIS
    Sanitizes log files by removing or masking sensitive information
    #>
    param(
        [Parameter(Mandatory=$true)][string]$LogPath,
        [string[]]$SensitivePatterns = @("APIKey", "Password", "Secret", "Token", "Key")
    )
    
    try {
        if (-not (Test-Path $LogPath)) {
            Write-ApplicationLog -Message "Log file not found: $LogPath" -Level "WARNING"
            return
        }
        
        $content = Get-Content $LogPath
        $sanitized = $false
        
        foreach ($line in $content) {
            $originalLine = $line
            
            foreach ($pattern in $SensitivePatterns) {
                # Replace sensitive values with masked versions
                $line = $line -replace "($pattern[`"':]?\s*[`"']?)([^`"',}\]]+)", '${1}***REDACTED***'
            }
            
            if ($line -ne $originalLine) {
                $sanitized = $true
            }
        }
        
        if ($sanitized) {
            Set-Content -Path $LogPath -Value $content
            Write-SecurityLog -Event "LogSanitization" -Action "SensitiveDataRemoved" -Details @{ LogPath = $LogPath }
        }
    }
    catch {
        Write-ErrorLog -Operation "Remove-SensitiveDataFromLogs" -Exception $_.Exception
    }
}

function Invoke-SecureEncryption {
    <#
    .SYNOPSIS
    Encrypts a value using the security system
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$PlainTextValue
    )
    
    try {
        if (-not $script:SecurityConfig.SecureStorageEnabled) {
            return $PlainTextValue  # Return as-is if encryption disabled
        }
        
        $secureManager = New-SecureConfigurationManager -ConfigPath "dummy"
        return $secureManager.EncryptString($PlainTextValue)
    }
    catch {
        Write-ApplicationLog -Message "Encryption failed: $($_.Exception.Message)" -Level "ERROR"
        return $PlainTextValue  # Fallback to plain text
    }
}

function Invoke-SecureDecryption {
    <#
    .SYNOPSIS
    Decrypts a value using the security system
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$EncryptedValue
    )
    
    try {
        if (-not $script:SecurityConfig.SecureStorageEnabled) {
            return $EncryptedValue  # Return as-is if encryption disabled
        }
        
        $secureManager = New-SecureConfigurationManager -ConfigPath "dummy"
        return $secureManager.DecryptString($EncryptedValue)
    }
    catch {
        Write-ApplicationLog -Message "Decryption failed: $($_.Exception.Message)" -Level "WARNING"
        return "DECRYPTION_FAILED"  # Return indicator of failure
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Initialise-SecuritySystem',
    'New-SecureConfigurationManager', 
    'Protect-SensitiveData',
    'Unprotect-SensitiveData',
    'Test-SecurityConfiguration',
    'Remove-SensitiveDataFromLogs',
    'Invoke-SecureEncryption',
    'Invoke-SecureDecryption'
)
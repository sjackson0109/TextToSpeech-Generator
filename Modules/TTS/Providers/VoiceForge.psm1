Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\Logging\EnhancedLogging.psm1')).Path -Force

function New-VoiceForgeTTSProvider {
    param([hashtable]$config = $null)
    if ($null -eq $config -or $config.GetType().Name -ne 'Hashtable') { $config = @{} }
    $provider = @{}
    $provider.Name = 'VoiceForge'
    $provider.Configuration = $config
    $provider.Capabilities = @{ MaxTextLength = 3000; SupportedFormats = @('mp3','wav','ogg'); SupportsSSML = $true; SupportsNeural = $false }
    $provider.GetAvailableVoices = {
        if ($null -eq $provider.Configuration -or $provider.Configuration.GetType().Name -ne 'Hashtable') {
            Write-ApplicationLog -Message "VoiceForge GetAvailableVoices: Configuration is null or not a hashtable, returning demo voices" -Level "WARNING"
            return @('Polly','Alice','Tom')
        }
        $apiKey = $provider.Configuration["ApiKey"]
        # If not present in config, try environment variable
        if (-not $apiKey) { $apiKey = $env:VOICEFORGE_API_KEY }
        if (-not $apiKey) {
            Write-ApplicationLog -Message "VoiceForge GetAvailableVoices: No config or env var, returning demo voices" -Level "DEBUG"
            return @('Polly','Alice','Tom')
        }
        $endpoint = "https://api.voiceforge.com/v1/voices?api_key=$apiKey"
        try {
            $response = Invoke-RestMethod -Uri $endpoint -Method Get -TimeoutSec 10
            if ($response.voices) {
                return $response.voices | ForEach-Object { $_.name }
            } else {
                return @('Polly','Alice','Tom')
            }
        } catch {
            Write-ApplicationLog -Message "VoiceForge GetAvailableVoices: Exception $($_.Exception.Message)" -Level "ERROR"
            return @('Polly','Alice','Tom')
        }
    }
    return $provider
}
Export-ModuleMember -Function New-VoiceForgeTTSProvider
Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\Logging\EnhancedLogging.psm1')).Path -Force

function New-TwilioTTSProvider {
    param([hashtable]$config = $null)
    if ($null -eq $config -or $config.GetType().Name -ne 'Hashtable') { $config = @{} }
    $provider = @{}
    $provider.Name = 'Twilio'
    $provider.Configuration = $config
    $provider.Capabilities = @{ MaxTextLength = 4000; SupportedFormats = @('mp3','wav'); Premium = $false }
    $provider.GetAvailableVoices = {
        if ($null -eq $provider.Configuration -or $provider.Configuration.GetType().Name -ne 'Hashtable') {
            Write-ApplicationLog -Message "Twilio GetAvailableVoices: Configuration is null or not a hashtable, returning demo voices" -Level "WARNING"
            return @('Polly','Alice','Tom')
        }
        $accountSid = $provider.Configuration["AccountSID"]
        $authToken = $provider.Configuration["AuthToken"]
        # If not present in config, try environment variables
        if (-not $accountSid) { $accountSid = $env:TWILIO_ACCOUNT_SID }
        if (-not $authToken) { $authToken = $env:TWILIO_AUTH_TOKEN }
        if (-not $accountSid -or -not $authToken) {
            Write-ApplicationLog -Message "Twilio GetAvailableVoices: No config or env vars, returning demo voices" -Level "DEBUG"
            return @('Polly','Alice','Tom')
        }
        $endpoint = "https://api.twilio.com/2010-04-01/Accounts/$accountSid/Voices.json"
        $headers = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${accountSid}:${authToken}")) }
        try {
            $response = Invoke-RestMethod -Uri $endpoint -Method Get -Headers $headers -TimeoutSec 10
            if ($response.voices) {
                return $response.voices | ForEach-Object { $_.name }
            } else {
                return @('Polly','Alice','Tom')
            }
        } catch {
            Write-ApplicationLog -Message "Twilio GetAvailableVoices: Exception $($_.Exception.Message)" -Level "ERROR"
            return @('Polly','Alice','Tom')
        }
    }
    return $provider
}
Export-ModuleMember -Function New-TwilioTTSProvider

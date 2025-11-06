if (-not (Get-Module -Name 'Logging')) {
	Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\Logging.psm1')).Path
}
function New-VoiceWaveTTSProvider {
    param($Config)
    $obj = [PSCustomObject]@{
        ProviderName = 'VoiceWare'
        Capabilities = @('Synthesize','ListVoices')
        GetAvailableVoices = { @("WaveVoice1", "WaveVoice2") }
        ProcessTTS = {
            param($Text, $Options)
            return @{ Success = $true; Message = "VoiceWare demo output" }
        }
    }
    return $obj
}

Export-ModuleMember -Function 'New-VoiceWaveTTSProvider'

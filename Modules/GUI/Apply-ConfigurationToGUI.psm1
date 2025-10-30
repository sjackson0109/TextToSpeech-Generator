function Set-ConfigurationToGUI {
    param(
        [Parameter(Mandatory=$true)][hashtable]$Configuration
    )
    if (-not $script:Window) { return }
    if (-not $Configuration.Provider) { return }

    switch ($Configuration.Provider) {
        "Azure Cognitive Services" {
            Import-Module -Name "Modules/TTSProviders/Azure.psm1" -Force
        }
        "Amazon Polly" {
            Import-Module -Name "Modules/TTSProviders/Polly.psm1" -Force
        }
        "Google Cloud" {
            Import-Module -Name "Modules/TTSProviders/GoogleCloud.psm1" -Force
        }
        "CloudPronouncer" {
            Import-Module -Name "Modules/TTSProviders/CloudPronouncer.psm1" -Force
        }
        "Twilio" {
            Import-Module -Name "Modules/TTSProviders/Twilio.psm1" -Force
        }
        "VoiceForge" {
            Import-Module -Name "Modules/TTSProviders/VoiceForge.psm1" -Force
        }
        default {
            # Fallback: set generic fields if needed
        }
    }
}

Export-ModuleMember -Function Set-ConfigurationToGUI

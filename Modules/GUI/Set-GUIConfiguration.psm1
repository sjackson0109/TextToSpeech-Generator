function Set-GUIConfiguration {
    param(
        [Parameter(Mandatory=$true)][hashtable]$Configuration
    )
    if (-not $script:Window) { return }

    # Set selected provider
    if ($Configuration.SelectedProvider) {
        $providerCombo = $script:Window.ProviderSelect
        foreach ($item in $providerCombo.Items) {
            if ($item.Content -eq $Configuration.SelectedProvider) {
                $providerCombo.SelectedItem = $item
                break
            }
        }
    }

    # Azure Cognitive Services
    if ($Configuration.Providers["Azure Cognitive Services"]) {
        $azure = $Configuration.Providers["Azure Cognitive Services"]
        if ($script:Window.MS_KEY) { $script:Window.MS_KEY.Text = $azure.ApiKey }
        if ($script:Window.MS_Datacenter) { $script:Window.MS_Datacenter.Text = $azure.Datacenter }
        if ($script:Window.MS_Audio_Format -and $azure.AudioFormat) {
            foreach ($item in $script:Window.MS_Audio_Format.Items) {
                if ($item.Content -eq $azure.AudioFormat) { $script:Window.MS_Audio_Format.SelectedItem = $item; break }
            }
        }
        if ($script:Window.MS_Voice -and $azure.DefaultVoice) {
            foreach ($item in $script:Window.MS_Voice.Items) {
                if ($item.Content -eq $azure.DefaultVoice) { $script:Window.MS_Voice.SelectedItem = $item; break }
            }
        }
    }

    # AWS Polly
    if ($Configuration.Providers["AWS Polly"]) {
        $aws = $Configuration.Providers["AWS Polly"]
        if ($script:Window.AWS_AccessKey) { $script:Window.AWS_AccessKey.Text = $aws.AccessKey }
        if ($script:Window.AWS_SecretKey) { $script:Window.AWS_SecretKey.Text = $aws.SecretKey }
        if ($script:Window.AWS_Region -and $aws.Region) {
            foreach ($item in $script:Window.AWS_Region.Items) {
                if ($item.Content -eq $aws.Region) { $script:Window.AWS_Region.SelectedItem = $item; break }
            }
        }
        if ($script:Window.AWS_Voice -and $aws.DefaultVoice) {
            foreach ($item in $script:Window.AWS_Voice.Items) {
                if ($item.Content -eq $aws.DefaultVoice) { $script:Window.AWS_Voice.SelectedItem = $item; break }
            }
        }
    }

    # Google Cloud TTS
    if ($Configuration.Providers["Google Cloud TTS"]) {
        $gc = $Configuration.Providers["Google Cloud TTS"]
        if ($script:Window.GC_APIKey) { $script:Window.GC_APIKey.Text = $gc.ApiKey }
        if ($script:Window.GC_Language -and $gc.Language) {
            foreach ($item in $script:Window.GC_Language.Items) {
                if ($item.Content -eq $gc.Language) { $script:Window.GC_Language.SelectedItem = $item; break }
            }
        }
        if ($script:Window.GC_Voice -and $gc.DefaultVoice) {
            foreach ($item in $script:Window.GC_Voice.Items) {
                if ($item.Content -eq $gc.DefaultVoice) { $script:Window.GC_Voice.SelectedItem = $item; break }
            }
        }
    }

    # CloudPronouncer
    if ($Configuration.Providers.ContainsKey("CloudPronouncer") -and $Configuration.Providers["CloudPronouncer"]) {
        $cp = $Configuration.Providers["CloudPronouncer"]
        if ($script:Window.CP_Username) { $script:Window.CP_Username.Text = $cp.Username }
        if ($cp.ContainsKey('Password') -and $script:Window.CP_Password) { $script:Window.CP_Password.Password = $cp.Password }
        if ($script:Window.CP_Voice -and $cp.DefaultVoice) {
            foreach ($item in $script:Window.CP_Voice.Items) {
                if ($item.Content -eq $cp.DefaultVoice) { $script:Window.CP_Voice.SelectedItem = $item; break }
            }
        }
        if ($script:Window.CP_Format -and $cp.Format) {
            foreach ($item in $script:Window.CP_Format.Items) {
                if ($item.Content -eq $cp.Format) { $script:Window.CP_Format.SelectedItem = $item; break }
            }
        }
    }

    # Twilio
    if ($Configuration.Providers.ContainsKey("Twilio") -and $Configuration.Providers["Twilio"]) {
        $tw = $Configuration.Providers["Twilio"]
        if ($script:Window.TW_AccountSID) { $script:Window.TW_AccountSID.Text = $tw.AccountSID }
        if ($tw.ContainsKey('AuthToken') -and $script:Window.TW_AuthToken) { $script:Window.TW_AuthToken.Password = $tw.AuthToken }
        if ($script:Window.TW_Voice -and $tw.DefaultVoice) {
            foreach ($item in $script:Window.TW_Voice.Items) {
                if ($item.Content -eq $tw.DefaultVoice) { $script:Window.TW_Voice.SelectedItem = $item; break }
            }
        }
        if ($script:Window.TW_Format -and $tw.Format) {
            foreach ($item in $script:Window.TW_Format.Items) {
                if ($item.Content -eq $tw.Format) { $script:Window.TW_Format.SelectedItem = $item; break }
            }
        }
    }

    # VoiceForge
    if ($Configuration.Providers.ContainsKey("VoiceForge") -and $Configuration.Providers["VoiceForge"]) {
        $vf = $Configuration.Providers["VoiceForge"]
        if ($script:Window.VF_APIKey) { $script:Window.VF_APIKey.Text = $vf.ApiKey }
        if ($script:Window.VF_Endpoint) { $script:Window.VF_Endpoint.Text = $vf.Endpoint }
        if ($script:Window.VF_Voice -and $vf.DefaultVoice) {
            foreach ($item in $script:Window.VF_Voice.Items) {
                if ($item.Content -eq $vf.DefaultVoice) { $script:Window.VF_Voice.SelectedItem = $item; break }
            }
        }
        if ($script:Window.VF_Quality -and $vf.Quality) {
            foreach ($item in $script:Window.VF_Quality.Items) {
                if ($item.Content -eq $vf.Quality) { $script:Window.VF_Quality.SelectedItem = $item; break }
            }
        }
    }
}

Export-ModuleMember -Function Set-GUIConfiguration

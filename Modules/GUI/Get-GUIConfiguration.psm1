function Get-GUIConfiguration {
    <#
    .SYNOPSIS
    Extract current configuration from GUI
    #>
    $config = @{
        SelectedProvider = if ($script:Window.ProviderSelect.SelectedItem) { $script:Window.ProviderSelect.SelectedItem.Content } else { "Azure Cognitive Services" }
        Providers = @{
            "Azure Cognitive Services" = @{
                ApiKey = if ($script:Window.MS_KEY.Text) { $script:Window.MS_KEY.Text } else { "" }
                Datacenter = if ($script:Window.MS_Datacenter.Text) { $script:Window.MS_Datacenter.Text } else { "eastus" }
                AudioFormat = if ($script:Window.MS_Audio_Format.SelectedItem) { $script:Window.MS_Audio_Format.SelectedItem.Content } else { "audio-16khz-32kbitrate-mono-mp3" }
                DefaultVoice = if ($script:Window.MS_Voice.SelectedItem) { $script:Window.MS_Voice.SelectedItem.Content } else { "en-US-JennyNeural" }
            }
            "AWS Polly" = @{
                AccessKey = if ($script:Window.AWS_AccessKey.Text) { $script:Window.AWS_AccessKey.Text } else { "" }
                SecretKey = if ($script:Window.AWS_SecretKey.Text) { $script:Window.AWS_SecretKey.Text } else { "" }
                Region = if ($script:Window.AWS_Region.SelectedItem) { $script:Window.AWS_Region.SelectedItem.Content } else { "us-west-2" }
                DefaultVoice = if ($script:Window.AWS_Voice.SelectedItem) { $script:Window.AWS_Voice.SelectedItem.Content } else { "Matthew" }
            }
            "Google Cloud TTS" = @{
                ApiKey = if ($script:Window.GC_APIKey.Text) { $script:Window.GC_APIKey.Text } else { "" }
                Language = if ($script:Window.GC_Language.SelectedItem) { $script:Window.GC_Language.SelectedItem.Content } else { "en-US" }
                DefaultVoice = if ($script:Window.GC_Voice.SelectedItem) { $script:Window.GC_Voice.SelectedItem.Content } else { "en-US-Wavenet-D" }
            }
            "CloudPronouncer" = @{
                Username = if ($script:Window.CP_Username.Text) { $script:Window.CP_Username.Text } else { "" }
                Password = if ($script:Window.CP_Password.Password) { $script:Window.CP_Password.Password } else { "" }
                DefaultVoice = if ($script:Window.CP_Voice.SelectedItem) { $script:Window.CP_Voice.SelectedItem.Content } else { "Alice" }
                Format = if ($script:Window.CP_Format.SelectedItem) { $script:Window.CP_Format.SelectedItem.Content } else { "mp3" }
            }
            "Twilio" = @{
                AccountSID = if ($script:Window.TW_AccountSID.Text) { $script:Window.TW_AccountSID.Text } else { "" }
                AuthToken = if ($script:Window.TW_AuthToken.Password) { $script:Window.TW_AuthToken.Password } else { "" }
                DefaultVoice = if ($script:Window.TW_Voice.SelectedItem) { $script:Window.TW_Voice.SelectedItem.Content } else { "Polly.Joanna" }
                Format = if ($script:Window.TW_Format.SelectedItem) { $script:Window.TW_Format.SelectedItem.Content } else { "mp3" }
            }
            "VoiceForge" = @{
                ApiKey = if ($script:Window.VF_APIKey.Text) { $script:Window.VF_APIKey.Text } else { "" }
                Endpoint = if ($script:Window.VF_Endpoint.Text) { $script:Window.VF_Endpoint.Text } else { "" }
                DefaultVoice = if ($script:Window.VF_Voice.SelectedItem) { $script:Window.VF_Voice.SelectedItem.Content } else { "Frank" }
                Quality = if ($script:Window.VF_Quality.SelectedItem) { $script:Window.VF_Quality.SelectedItem.Content } else { "Standard" }
            }
        }
        Processing = @{
            BulkMode = if ($script:Window.BulkMode.IsChecked) { $script:Window.BulkMode.IsChecked } else { $false }
            InputText = if ($script:Window.Input_Text.Text) { $script:Window.Input_Text.Text } else { "" }
            OutputDirectory = if ($script:Window.Output_File.Text) { $script:Window.Output_File.Text } else { "" }
            OutputFormat = if ($script:Window.Output_Format.SelectedItem) { $script:Window.Output_Format.SelectedItem.Content } else { "MP3" }
        }
    }
    return $config
}

Export-ModuleMember -Function Get-GUIConfiguration

function Update-VoiceOptions {
    <#
    .SYNOPSIS
    Update voice options based on selected provider
    #>
    param ( [Parameter(Mandatory=$true)][string]$Provider )
    
    if (-not $script:Window) { return }
    
    # Clear current options with null checks
    if ($script:Window.MS_Voice) { $script:Window.MS_Voice.Items.Clear() }
    if ($script:Window.AWS_Voice) { $script:Window.AWS_Voice.Items.Clear() }
    if ($script:Window.GC_Voice) { $script:Window.GC_Voice.Items.Clear() }
    
    switch ($Provider) {
        "Azure Cognitive Services" {
            $voices = @("en-US-AriaNeural", "en-US-JennyNeural", "en-US-GuyNeural", "en-US-DavisNeural", "en-US-JaneNeural")
            foreach ($voice in $voices) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $voice
                if ($voice -eq "en-US-AriaNeural") { $item.IsSelected = $true }
                $script:Window.MS_Voice.Items.Add($item) | Out-Null
            }
        }
        "Amazon Polly" {
            $voices = @("Joanna", "Matthew", "Amy", "Brian", "Emma", "Ivy", "Justin", "Kendra", "Kimberly", "Salli")
            foreach ($voice in $voices) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $voice
                if ($voice -eq "Joanna") { $item.IsSelected = $true }
                $script:Window.AWS_Voice.Items.Add($item) | Out-Null
            }
        }
        "Google Cloud" {
            $voices = @("en-US-Wavenet-A", "en-US-Wavenet-B", "en-US-Wavenet-C", "en-US-Wavenet-D", "en-US-Wavenet-E", "en-US-Wavenet-F")
            foreach ($voice in $voices) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $voice
                if ($voice -eq "en-US-Wavenet-D") { $item.IsSelected = $true }
                $script:Window.GC_Voice.Items.Add($item) | Out-Null
            }
        }
        "CloudPronouncer" {
            $voices = @("Alice", "Bob", "Charlie", "Diana", "Eve")
            foreach ($voice in $voices) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $voice
                if ($voice -eq "Alice") { $item.IsSelected = $true }
                $script:Window.CP_Voice.Items.Add($item) | Out-Null
            }
        }
        "Twilio" {
            $voices = @("Polly.Joanna", "Polly.Matthew", "Polly.Amy", "Polly.Brian")
            foreach ($voice in $voices) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $voice
                if ($voice -eq "Polly.Joanna") { $item.IsSelected = $true }
                $script:Window.TW_Voice.Items.Add($item) | Out-Null
            }
        }
        "VoiceForge" {
            $voices = @("Frank", "Jill", "Paul", "Susan")
            foreach ($voice in $voices) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $voice
                if ($voice -eq "Frank") { $item.IsSelected = $true }
                $script:Window.VF_Voice.Items.Add($item) | Out-Null
            }
        }
    }
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
                ApiKey = if ($script:Window.GC_APIKey.Password) { $script:Window.GC_APIKey.Password } else { "" }
                Language = if ($script:Window.GC_Language.SelectedItem) { $script:Window.GC_Language.SelectedItem.Content } else { "en-US" }
                DefaultVoice = if ($script:Window.GC_Voice.SelectedItem) { $script:Window.GC_Voice.SelectedItem.Content } else { "en-US-Wavenet-D" }
            }
            "CloudPronouncer" = @{
                Username = if ($script:Window.CP_Username.Text) { $script:Window.CP_Username.Text } else { "" }
                Password = if ($script:Window.CP_Password.Password) { $script:Window.CP_Password.Password } else { "" }
                DefaultVoice = if ($script:Window.CP_Voice.SelectedItem) { $script:Window.CP_Voice.SelectedItem.Content } else { "Alice" }
                Format = if ($script:Window.CP_Format.SelectedItem) { $script:Window.CP_Format.SelectedItem.Content } else { "MP3" }
            }
            "Twilio" = @{
                AccountSID = if ($script:Window.TW_AccountSID.Text) { $script:Window.TW_AccountSID.Text } else { "" }
                AuthToken = if ($script:Window.TW_AuthToken.Password) { $script:Window.TW_AuthToken.Password } else { "" }
                DefaultVoice = if ($script:Window.TW_Voice.SelectedItem) { $script:Window.TW_Voice.SelectedItem.Content } else { "Polly.Joanna" }
                Format = if ($script:Window.TW_Format.SelectedItem) { $script:Window.TW_Format.SelectedItem.Content } else { "MP3" }
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
    $regionValue = $region.SelectedItem.Tag
    $payload = "{}"
    $target = "Polly_20161001.DescribeVoices"
    $endpoint = "https://polly.$regionValue.amazonaws.com/v1/voices"
    # Use AWS Tools for PowerShell if available, else fallback to REST
    if (Get-Command Get-PollyVoiceList -ErrorAction SilentlyContinue) {
        try {
            $awsCred = New-Object -TypeName Amazon.Runtime.BasicAWSCredentials($accessKey.Text, $secretKey.Text)
            $pollyClient = New-Object -TypeName Amazon.Polly.AmazonPollyClient($awsCred, $regionValue)
            $voices = $pollyClient.DescribeVoicesAsync().Result.Voices
            if ($voices.Count -gt 0) {
                $setupWindow.ConnectionStatus.Text = "✅ Credentials valid! Polly voices available."
                $setupWindow.ConnectionStatus.Foreground = "#FF00FF00"
                Update-APIStatus -SetupStatus "Validated" -SetupColor "#FF00FF00"
            } else {
                $setupWindow.ConnectionStatus.Text = "❌ No voices returned. Check permissions."
                $setupWindow.ConnectionStatus.Foreground = "#FFFF0000"
            }
        } catch {
            $setupWindow.ConnectionStatus.Text = "❌ AWS SDK error: $($_.Exception.Message)"
            $setupWindow.ConnectionStatus.Foreground = "#FFFF0000"
            Write-SafeLog -Message "AWS SDK validation failed: $($_.Exception.Message)" -Level "ERROR"
        }
    } else {
        # Fallback: REST call with detailed error logging
        try {
            $date = Get-Date -Format "yyyyMMddTHHmmssZ"
            $datestamp = Get-Date -Format "yyyyMMdd"
            $service = "polly"
            $host = "polly.$regionValue.amazonaws.com"
            $canonicalUri = "/v1/voices"
            $canonicalQueryString = ""
            $canonicalHeaders = "content-type:application/x-amz-json-1.1\nhost:$host\nx-amz-date:$date\nx-amz-target:$target\n"
            $signedHeaders = "content-type;host;x-amz-date;x-amz-target"
            $payloadHash = [BitConverter]::ToString((New-Object Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($payload))).Replace("-","").ToLower()
            $canonicalRequest = "POST`n$canonicalUri`n$canonicalQueryString`n$canonicalHeaders`n$signedHeaders`n$payloadHash"
            $credentialScope = "$datestamp/$regionValue/$service/aws4_request"
            $stringToSign = "AWS4-HMAC-SHA256`n$date`n$credentialScope`n" + [BitConverter]::ToString((New-Object Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($canonicalRequest))).Replace("-","").ToLower()
            function HmacSHA256($key, $msg) {
                $hmac = New-Object System.Security.Cryptography.HMACSHA256
                $hmac.Key = $key
                return $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($msg))
            }
            $kSecret = [Text.Encoding]::UTF8.GetBytes("AWS4$($secretKey.Text)")
            $kDate = HmacSHA256 $kSecret $datestamp
            $kRegion = HmacSHA256 $kDate $regionValue
            $kService = HmacSHA256 $kRegion $service
            $kSigning = HmacSHA256 $kService "aws4_request"
            $signature = HmacSHA256 $kSigning $stringToSign
            $signatureHex = ($signature | ForEach-Object { $_.ToString("x2") }) -join ""
            $authorization = "AWS4-HMAC-SHA256 Credential=$($accessKey.Text)/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signatureHex"
            $headers = @{
                "Content-Type" = "application/x-amz-json-1.1"
                "X-Amz-Date" = $date
                "X-Amz-Target" = $target
                "Authorization" = $authorization
                "Host" = $host
            }
            $response = Invoke-RestMethod -Uri $endpoint -Method POST -Headers $headers -Body $payload -TimeoutSec 10 -ErrorAction Stop
            if ($response.Voices -and $response.Voices.Count -gt 0) {
                $setupWindow.ConnectionStatus.Text = "✅ Credentials valid! Polly voices available."
                $setupWindow.ConnectionStatus.Foreground = "#FF00FF00"
                Update-APIStatus -SetupStatus "Validated" -SetupColor "#FF00FF00"
            } else {
                $setupWindow.ConnectionStatus.Text = "❌ No voices returned. Check permissions."
                $setupWindow.ConnectionStatus.Foreground = "#FFFF0000"
            }
        } catch {
            $errMsg = $_.Exception.Message
            $setupWindow.ConnectionStatus.Text = "❌ REST error: $errMsg"
            $setupWindow.ConnectionStatus.Foreground = "#FFFF0000"
            Write-SafeLog -Message "AWS REST validation failed: $errMsg" -Level "ERROR"
        }
    }
}
Export-ModuleMember -Function Update-VoiceOptions
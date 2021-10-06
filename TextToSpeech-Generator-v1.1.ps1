<#
TTS Voice Generator GUI
Text to Speech Bulk Generator


.SYNOPSIS
TextToSpeech-Generator.ps1

.DESCRIPTION 
PowerShell script to generate Voice Messages with Azure Cognitive Services Text to Speech
Quick Link: http://bit.ly/AzureTTSGUI


.NOTES
Written by: Luca Vitali - Microsoft Office Apps & Services MVP
Updated by: Simon Jackson - MD and Technical Architect

License: The MIT License (MIT)

Copyright (c) 2021 Luca Vitali and Simon Jackson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Change Log:
V1.00, 02/09/2019 - Initial version working with single-scripts
V1.05, 08/09/2021 - Second release, working with CSV (bulk) file-imports
V1.10, 22/09/2021 - Third release, working with CSV and Single-Scripts

Planned works:
1) Implement Radio buttons to choose alternative TTS Service Providers; adapting the GUI as each option is chosen.
2) Onboard API calls for Google Cloud TTS
3) Onboard API calls for AWS Polly TTS
4) Onboard Additional API endpoints, perhaps look to source an inclusion-config file per-provider?
#>

#region InitializeVariables
$ScriptPath = $MyInvocation.MyCommand.Path
$ConfigFile = ([System.IO.Path]::ChangeExtension($ScriptPath, "xml"))
$DefaultProvider = "Azure Cognitive Services TTS"
$DefaultMode = "Bulk File Processing"
$MS_KEY = ""
$MS_Datacenter = ""
$MS_Audio_Format = ""
$MS_Voice = ""
$GC_KEY = ""
$GC_Audio_Format = ""
$GC_Voice = ""
$InputFile = ""
$OutputPath = ""
$UserAgent = "TextToSpeech Generator"
$Version = "v1.20"
#endregion InitializeVariables

Function Get-Config () {
	if (Test-Path -Path "$($ConfigFile)") {
		try {
			$xml = [xml](get-Content -path "$($ConfigFile)")
            $MS_KEY = $xml.configuration.MS_Key
            $MS_Datacenter = $xml.configuration.MS_Datacenter
            $MS_Audio_Format = $xml.configuration.MS_Audio_Format
            $MS_Voice = $xml.configuration.MS_Voice
            $InputFile = $xml.configuration.Input_File
            $OutputPath = $xml.configuration.Output_Path
        } catch {
            $MS_KEY = ""
            $MS_Datacenter = ""
            $MS_Audio_Format = ""
            $MS_Voice = ""
            $InputFile = ""
            $OutputPath = ""
		}
	} else {
        $MS_KEY = ""
        $MS_Datacenter = ""
        $MS_Audio_Format = ""
        $MS_Voice = ""
        $InputFile = ""
        $OutputPath = ""
	}
	return $MS_KEY, $MS_Datacenter, $MS_Audio_Format, $MS_Voice, $InputFile, $OutputPath
}

Function Save-Config () {
    param (
        [string]$configFile,
        [string]$MS_KEY,
        [string]$MS_Datacenter,
        [string]$MS_Audio_Format,
        [string]$MS_Voice,
        [string]$InputFile,
        [string]$OutputPath
    )
	[xml]$Doc = New-Object System.Xml.XmlDocument
	$Dec = $Doc.CreateXmlDeclaration("1.0","UTF-8",$null)
	$Doc.AppendChild($Dec) | out-null
	$Root = $Doc.CreateNode("element","configuration",$null)
            
        #Save the Microsoft Cognative Services config in it's own node
        $Element = $Doc.CreateElement("MS_Key")
		$Element.InnerText = $MS_KEY
		$Root.AppendChild($Element) | out-null

		$Element = $Doc.CreateElement("MS_Datacenter")
		$Element.InnerText = $MS_Datacenter
        $Root.AppendChild($Element) | out-null

        $Element = $Doc.CreateElement("MS_Audio_Format")
		$Element.InnerText = $MS_Audio_Format
		$Root.AppendChild($Element) | out-null

		$Element = $Doc.CreateElement("MS_Voice")
		$Element.InnerText = $MS_Voice
		$Root.AppendChild($Element) | out-null

        #Now save the basic stuff in the configuration node.
        $Element = $Doc.CreateElement("Input_File")
		$Element.InnerText = $InputFile
        $Root.AppendChild($Element) | out-null

		$Element = $Doc.CreateElement("Output_Path")
		$Element.InnerText = $OutputPath
		$Root.AppendChild($Element) | out-null

	$Doc.AppendChild($Root) | out-null
	try {
        $Doc.Save(("$($configFile)"))
        $window.Log.Text = $window.Log.Text + "Configuration saved successfully" + "`r`n"
    }
	catch { $window.Log.Text = $window.Log.Text + "Error: Configuration save failed $($Error.Message)" + "`r`n"}
    
}

function Get-File {
    [ CmdletBinding (SupportsShouldProcess = $True, SupportsPaging = $True) ]
	param (
		[string] $Message = "Select the desired file",
		[int] $path = 0x00
	)
    [Object]$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
        InitialDirectory = [Environment]::GetFolderPath('Desktop') 
        Filter = 'CSV Files (*.csv)|*.csv|All Files (*.*)|*.*'
    }
    $File = $FileBrowser.ShowDialog()
    if ($File -ne $null) {
        return $FileBrowser.FileName
    }
    else { Write-Host "No File specified" }
}

function Get-Folder {
    [ CmdletBinding (SupportsShouldProcess = $True, SupportsPaging = $True) ]
	param (
		[string] $Message = "Select the desired folder",
		[int] $path = 0x00
	)
    [Object] $FolderObject = New-Object -ComObject Shell.Application
    $folder = $FolderObject.BrowseForFolder(0, $message, 0, $path)
    if ($folder -ne $null) { return $folder.self.Path }
    else { Write-Host "No folder specified" }
}

#region XAML window definition
$xaml = @"
<Window
   xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
   xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
   
   SizeToContent="WidthAndHeight"
   Title="$UserAgent" Height="440" Width ="800" ResizeMode="CanMinimize" ShowInTaskbar="True" WindowStartupLocation="CenterScreen" MinWidth="800" MinHeight="440">
    <Grid Margin="5,5,5,5" Height="440" VerticalAlignment="Top">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>


        <Rectangle HorizontalAlignment="Left" Height="77" Margin="5,36,0,0" Stroke="Gray" VerticalAlignment="Top" Width="700"/>

        <Label x:Name="TTS_CHOICE" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="10,22,0,0" Width="166" Background="White" Content="$DefaultProvider"/>
        
        <Label HorizontalAlignment="Left" Margin="5,1,5,0" VerticalAlignment="Top" Width="700" Background="LightGray" Content="Choose a TTS Provider:" FontWeight="Bold"/>
      
        <RadioButton x:Name="TTS_AW" Margin="200,7,0,0" GroupName="TTS_CHOICE" Foreground="Gray">Amazon</RadioButton>
        <RadioButton x:Name="TTS_MS" Margin="270,7,0,0" GroupName="TTS_CHOICE" IsChecked="true">Azure</RadioButton>
        <RadioButton x:Name="TTS_CP" Margin="330,7,0,0" GroupName="TTS_CHOICE" Foreground="Gray">CloudPronouncer</RadioButton>
        <RadioButton x:Name="TTS_GC" Margin="450,7,0,0" GroupName="TTS_CHOICE" >Google</RadioButton>
        <RadioButton x:Name="TTS_TW" Margin="520,7,0,0" GroupName="TTS_CHOICE" Foreground="Gray">Twillio</RadioButton>
        <RadioButton x:Name="TTS_VF" Margin="590,7,0,0" GroupName="TTS_CHOICE" Foreground="Gray">VoiceForge</RadioButton>




            <Label Content="Key" HorizontalAlignment="Left" Margin="10,45,0,0" VerticalAlignment="Top" Width="70"/>
            <TextBox x:Name="KeyKey" HorizontalAlignment="Left" Margin="90,46,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Height="22" Width="240"/>
            
            <Label x:Name="MS_Datacenter_Label" Content="Datacentre" HorizontalAlignment="Left" Margin="10,73,0,0" VerticalAlignment="Top"/>
            <ComboBox x:Name="MS_Datacenter" HorizontalAlignment="Left" Margin="90,74,0,0" VerticalAlignment="Top" Width="115" IsEditable="True" IsSynchronizedWithCurrentItem="True">
                <ComboBoxItem Content="australiaeast"/>
                <ComboBoxItem Content="canadacentral"/>
                <ComboBoxItem Content="centralus"/>
                <ComboBoxItem Content="eastasia"/>
                <ComboBoxItem Content="eastus"/>
                <ComboBoxItem Content="eastus2"/>
                <ComboBoxItem Content="francecentral"/>
                <ComboBoxItem Content="centralindia"/>
                <ComboBoxItem Content="japaneast"/>
                <ComboBoxItem Content="koreacentral"/>
                <ComboBoxItem Content="northcentralus"/>
                <ComboBoxItem Content="northeurope"/>
                <ComboBoxItem Content="southcentralus"/>
                <ComboBoxItem Content="southeastasia"/>
                <ComboBoxItem Content="uksouth"/>
                <ComboBoxItem Content="westeurope"/>
                <ComboBoxItem Content="westus"/>
                <ComboBoxItem Content="westus2"/>
            </ComboBox>

            <Label x:Name="MS_Audio_Format_Label" Content="Format" HorizontalAlignment="Left" Margin="370,45,0,0" VerticalAlignment="Top" Width="70"/>
            <ComboBox x:Name="MS_Audio_Format" HorizontalAlignment="Left" Margin="425,46,0,0" VerticalAlignment="Top" Width="240" IsSynchronizedWithCurrentItem="True">
                <ComboBoxItem Content="raw-16khz-16bit-mono-pcm"/>
                <ComboBoxItem Content="raw-8khz-8bit-mono-mulaw"/>
                <ComboBoxItem Content="riff-8khz-8bit-mono-alaw"/>
                <ComboBoxItem Content="riff-8khz-8bit-mono-mulaw"/>
                <ComboBoxItem Content="riff-16khz-16bit-mono-pcm" FontWeight="Bold"/>
                <ComboBoxItem Content="audio-16khz-128kbitrate-mono-mp3"/>
                <ComboBoxItem Content="audio-16khz-64kbitrate-mono-mp3"/>
                <ComboBoxItem Content="audio-16khz-32kbitrate-mono-mp3" FontWeight="Bold"/>
                <ComboBoxItem Content="raw-24khz-16bit-mono-pcm"/>
                <ComboBoxItem Content="riff-24khz-16bit-mono-pcm"/>
                <ComboBoxItem Content="audio-24khz-160kbitrate-mono-mp3"/>
                <ComboBoxItem Content="audio-24khz-96kbitrate-mono-mp3"/>
                <ComboBoxItem Content="audio-24khz-48kbitrate-mono-mp3"/>
            </ComboBox>
            <Button x:Name="MS_Audio_Format_Tip" Content="TIP" HorizontalAlignment="Left" Margin="670,46,0,0" VerticalAlignment="Top" Width="18" Height="22" BorderBrush="{x:Null}" Background="{x:Null}" HorizontalContentAlignment="Left" Padding="0" VerticalContentAlignment="Top" Foreground="#FF0066CC" />
        

            <Label x:Name="MS_Voice_Label" Content="Voice" HorizontalAlignment="Left" Margin="230,73,0,0" VerticalAlignment="Top" Width="83"/>
            <ComboBox x:Name="MS_Voice" HorizontalAlignment="Left" Margin="275,74,0,0" VerticalAlignment="Top" Width="390" IsSynchronizedWithCurrentItem="True"/>
            
            <RadioButton x:Name="Male" Margin="200,126,0,0" GroupName="GENDER_CHOICE" Visibility="Collapsed">Male</RadioButton>
            <RadioButton x:Name="Female" Margin="295,126,0,0" GroupName="GENDER_CHOICE" IsChecked="true" Visibility="Collapsed">Female</RadioButton>


        

        
        <Rectangle HorizontalAlignment="Left" Height="77" Margin="5,154,0,0" Stroke="Gray" VerticalAlignment="Top" Width="700"/>

        <Label x:Name="MODE_CHOICE" HorizontalAlignment="Left" Margin="10,141,0,0" VerticalAlignment="Top" Width="118" Background="White" Content="$DefaultMode"/>

        <Label HorizontalAlignment="Left" Margin="5,120,5,0" VerticalAlignment="Top" Width="700" Background="LightGray" Content="Select a processing mode:" FontWeight="Bold"/>
        <RadioButton x:Name="OP_BULK" Margin="200,126,0,0" GroupName="OP_CHOICE" IsChecked="true">Bulk-Scripts</RadioButton>
        <RadioButton x:Name="OP_SINGLE" Margin="295,126,0,0" GroupName="OP_CHOICE" >Single-Script</RadioButton>



            <Label x:Name="Input_File_Label" Content="Input File" HorizontalAlignment="Left" Margin="11,168,0,0" VerticalAlignment="Top" Width="74"/>
            <TextBox x:Name="Input_File" HorizontalAlignment="Left" Height="22" Margin="100,170,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="545"/>
            <Button x:Name="Input_Browse" Content="..." HorizontalAlignment="Left" Margin="650,170,0,0" VerticalAlignment="Top" Width="18" Height="22"/>
            <Button x:Name="Input_TIP" Content="TIP" HorizontalAlignment="Left" Margin="670,170,0,0" VerticalAlignment="Top" Width="18" Height="22" BorderBrush="{x:Null}" Background="{x:Null}" HorizontalContentAlignment="Left" Padding="0" VerticalContentAlignment="Top" Foreground="#FF0066CC" />
            
            <Label x:Name="Input_Script_Label" Content="Input Script" HorizontalAlignment="Left" Margin="11,161,0,0" VerticalAlignment="Top" Width="74" Visibility="Collapsed"/>
            <TextBox x:Name="Input_Script" HorizontalAlignment="Left" Height="32" Margin="100,162,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="568" Visibility="Collapsed">Please type your words to convert to file here...</TextBox>
            <Button x:Name="Input_TIP2" Content="TIP" HorizontalAlignment="Left" Margin="670,162,0,0" VerticalAlignment="Top" Width="18" Height="22" BorderBrush="{x:Null}" Background="{x:Null}" HorizontalContentAlignment="Left" Padding="0" VerticalContentAlignment="Top" Foreground="#FF0066CC" Visibility="Collapsed"/>

            <Label Content="Output Folder" HorizontalAlignment="Left" Margin="11,196,0,0" VerticalAlignment="Top" RenderTransformOrigin="0.484,0.464"/>
            <TextBox x:Name="Output_Path" HorizontalAlignment="Left" Height="22" Margin="100,198,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="545"/>
            <Button x:Name="Output_Browse" Content="..." HorizontalAlignment="Left" Margin="650,198,0,0" VerticalAlignment="Top" Width="18" Height="22"/>
            <Button x:Name="Output_TIP" Content="TIP" HorizontalAlignment="Left" Margin="670,198,0,0" VerticalAlignment="Top" Width="18" Height="22" BorderBrush="{x:Null}" Background="{x:Null}" HorizontalContentAlignment="Left" Padding="0" VerticalContentAlignment="Top" Foreground="#FF0066CC" />
        
            
        <Rectangle HorizontalAlignment="Left" Height="163" Margin="5,246,0,0" Stroke="Gray" VerticalAlignment="Top" Width="774"/>
            <Label Content="Log" HorizontalAlignment="Left" Margin="10,231,0,0" VerticalAlignment="Top" Width="30" Background="White"/>
            <TextBox x:Name="Log" TextWrapping="Wrap" AcceptsReturn="False" VerticalScrollBarVisibility="Visible" HorizontalAlignment="Left" Margin="13,227,0,0" Width="758" Height="145" Background="LightGray"/>
   

        <Button x:Name="MS_Guide" Content="MS Guide" HorizontalAlignment="Left" Margin="715,44,0,0" VerticalAlignment="Top" Width="55" Height="20" BorderBrush="{x:Null}" Background="{x:Null}" HorizontalContentAlignment="Left" Padding="0" VerticalContentAlignment="Top" Foreground="#FF0066CC" />
        <Button x:Name="MS_Sign_Up" Content="Sign-Up" HorizontalAlignment="Left" Margin="715,64,0,0" VerticalAlignment="Top" Width="55" Height="20" BorderBrush="{x:Null}" Background="{x:Null}" HorizontalContentAlignment="Left" Padding="0" VerticalContentAlignment="Top" Foreground="#FF0066CC" />
        


        <Button x:Name="Save" Content="Save" HorizontalAlignment="Left" Margin="715,4,0,0" VerticalAlignment="Top" Width="64" Height="22"/>

        <Button x:Name="Run" Content="Go!" HorizontalAlignment="Left" Margin="715,170,0,0" VerticalAlignment="Top" Width="64" Height="44"/>
        <Button x:Name="Log_Clear" Content="X" HorizontalAlignment="Left" Margin="752,260,0,0" VerticalAlignment="Top" Width="18" Height="20" Background="LightGray"/>

        <Label HorizontalAlignment="Left" Margin="0,410,0,0" VerticalAlignment="Top" Width="670" Content="Updated by sjackson0109, following the works of LucaVitali on GitHub" />
        <Button x:Name="LucaVitali_GitHub" Content="LucaVitali" HorizontalAlignment="Left" Margin="267,414,0,0" VerticalAlignment="Top" Width="53" Height="20" BorderBrush="{x:Null}" Background="{x:Null}" HorizontalContentAlignment="Left" Padding="0" VerticalContentAlignment="Top" Foreground="#FF0066CC" />
        <Button x:Name="sjackson0109_GitHub" Content="sjackson0109" HorizontalAlignment="Left" Margin="69,414,0,0" VerticalAlignment="Top" Width="73" Height="20" BorderBrush="{x:Null}" Background="{x:Null}" HorizontalContentAlignment="Left" Padding="0" VerticalContentAlignment="Top" Foreground="#FF0066CC" />

        <Label x:Name="version" HorizontalAlignment="Right" Margin="747,410,0,0" VerticalAlignment="Top" Width="40" Content=""/>

    </Grid>
</Window>
"@
#endregion

#region Code Behind
function Convert-XAMLtoWindow {
  param ( [Parameter(Mandatory=$true)][string]$XAML )
  Add-Type -AssemblyName PresentationFramework
  $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
  $result = [Windows.Markup.XAMLReader]::Load($reader)
  $reader.Close()
  $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
  while ($reader.Read())
  {
      $name=$reader.GetAttribute('Name')
      if (!$name) { $name=$reader.GetAttribute('x:Name') }
      if ($name) { $result | Add-Member NoteProperty -Name $name -Value $result.FindName($name) -Force }
  }
  $reader.Close()
  $result
}

function Show-WPFWindow {
  param ( [Parameter(Mandatory=$true)][Windows.Window]$Window )
  $result = $null
  $null = $window.Dispatcher.InvokeAsync{
    $result = $window.ShowDialog()
    Set-Variable -Name result -Value $result -Scope 1
  }.Wait()
  $result
}

function Show-ToolTip {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Windows.Forms.Control]$control,
        [string]$text = $null,
        [int]$duration = 1000
    )
    if ([string]::IsNullOrWhiteSpace($text)) { $text = $control.Tag }
    $pos = [System.Drawing.Point]::new($control.Right, $control.Top)
    $obj_tt.Show($text,$form, $pos, $duration)
}

#endregion Code Behind

#region Convert XAML to Window
$window = Convert-XAMLtoWindow -XAML $xaml 
#endregion

#region Define Event Handlers
# Right-Click XAML Text and choose WPF/Attach Events to
# add more handlers
$window.TTS_AW.add_Checked{
    $window.TTS_CHOICE.Content="AWS Polly TTS"
    $window.TTS_CHOICE.Width="86"
    $window.TTS_MS.IsChecked = $true
}
$window.TTS_MS.add_Checked{
    $window.TTS_CHOICE.Content="Azure Cognitive Services TTS"
    $window.TTS_CHOICE.Width="166"
    $window.TTS_MS.IsChecked = $true
}
$window.TTS_CP.add_Checked{
    $window.TTS_CHOICE.Content="Cloud Pronouncer TTS"
    $window.TTS_CHOICE.Width="130"
    $window.TTS_MS.IsChecked = $true
}
$window.TTS_GC.add_Checked{
    $window.Key.Width="200"
    $window.TTS_CHOICE.Content="Google Cloud TTS"
    $window.TTS_CHOICE.Width="110"
    #$window.TTS_MS.IsChecked = $true
    $window.MS_Datacenter_Label.Visibility="Collapsed"    
    $window.MS_Datacenter.Visibility="Collapsed"
    $window.MS_Audio_Format_Label.Visibility="Collapsed"    
    $window.MS_Audio_Format.Visibility="Collapsed"
    $window.MS_Audio_Format_Tip.Visibility="Collapsed"
    #$window.MS_Voice_Label.Visibility="Collapsed"    
    $window.MS_Voice.Visibility="Collapsed"
    $window.Male.Visibility="Visible"
    $window.Female.Visibility="Visible"

}
$window.TTS_TW.add_Checked{
    $window.TTS_CHOICE.Content="Twilio TTS"
    $window.TTS_CHOICE.Width="66"
    $window.TTS_MS.IsChecked = $true
}
$window.TTS_VF.add_Checked{
    $window.TTS_CHOICE.Content="Voice Forge TTS"
    $window.TTS_CHOICE.Width="96"
    $window.TTS_MS.IsChecked = $true
}

$window.OP_BULK.add_Checked{
    $window.MODE_CHOICE.Content="Bulk File Processing"
    $window.MODE_CHOICE.Width="118"
    $window.Input_File_Label.Visibility="Visible"
    $window.Input_File.Visibility="Visible"
    $window.Input_Browse.Visibility="Visible"
    $window.Input_TIP.Visibility="Visible"
    $window.Input_Script_Label.Visibility="Collapsed"
    $window.Input_Script.Visibility="Collapsed"
    $window.Input_TIP2.Visibility="Collapsed"
}   
$window.OP_SINGLE.add_Checked{
    $window.MODE_CHOICE.Content="Single Script Processing"
    $window.MODE_CHOICE.Width="138"
    $window.Input_File_Label.Visibility="Collapsed"
    $window.Input_File.Visibility="Collapsed"
    $window.Input_Browse.Visibility="Collapsed"
    $window.Input_TIP.Visibility="Collapsed"
    $window.Input_Script_Label.Visibility="Visible"
    $window.Input_Script.Visibility="Visible"
    $window.Input_TIP2.Visibility="Visible"
}


$window.Run.add_Click{
    # remove param() block if access to event information is not required
    param (
        [Parameter(Mandatory)][Object]$sender,
        [Parameter(Mandatory)][Windows.RoutedEventArgs]$e
    )
    Add-Type -AssemblyName presentationCore
    $InputFile = $window.Input_File.Text
    $OutputPath = $window.Output_Path.Text
    $window.Log.Text = ""

    # MS Azure Cognative Services / BULK
    If ( $window.TTS_MS.IsChecked -eq $true -and $window.OP_BULK.IsChecked -eq $true){
        Save-Config $Configfile $window.Key.Text $window.MS_Datacenter.Text $window.MS_Audio_Format.Text $window.MS_Voice.Text $window.Input_File.Text $window.Output_Path.Text 
        $MS_Datacenter = $window.MS_Datacenter.Text
        $MS_Audio_Format = $window.MS_Audio_Format.Text
        $MS_RequestHeaders = @{"Authorization"=$MS_OAuthToken; "Content-Type"="application/ssml+xml"; "X-Microsoft-OutputFormat"=$MS_Audio_Format; "User-Agent"=$UserAgent;}
        $MS_Voice = $window.MS_Voice.Text
        $MS_VoiceList = $( $( $( $( $MS_Voice -Replace 'Microsoft Server Speech Text to Speech Voice ','' ) -Replace [regex]::escape('(');, '' )  -Replace [regex]::escape(')');, '' ) -replace ('  ', '') )
        If ( $MS_Audio_Format.Substring($($MS_Audio_Format.Length) - 3,3) -eq "mp3" ) { $ext = "mp3" } Else { $ext = "wav" }
        Try {
            $SourceFile = Import-CSV $InputFile -Delimiter ","
            $window.Log.Text = "Importing $InputFile.$ext successful" + "`n"
            $window.Log.Text = $window.Log.Text + "Chosen Voice: $MS_VoiceList" + "`n"
            $window.Log.Text = $window.Log.Text + "Scripts found: $($SourceFile.Count + 1)" + "`n"
            $i=1; $j=0
            ForEach ($SourceRow in $SourceFile) {
                [xml]$MS_VoiceBody = "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'><voice name='" + $MS_Voice + "'>" + $($SourceRow.SCRIPT) + "</voice></speak>"
                $($SourceRow.FILENAME)
                $DestinationFile = "$OutputPath\$($SourceRow.FILENAME)_$MS_VoiceList.$ext"
                Write-Host "Attempting to generate $DestinationFile"
                Try {
                    Invoke-RestMethod -Method POST -Uri $MS_ServiceURI -Headers $MS_RequestHeaders -Body $MS_VoiceBody -ContentType "application/ssml+xml" -OutFile $DestinationFile
                    $window.Log.Text = $window.Log.Text + "Generating $($SourceRow.FILENAME) successful" + "`n"
                    $i++
                }
                Catch {
                    $window.Log.Text = $window.Log.Text + "ERROR: Generating $($SourceRow.FILENAME) failed: \n $Error[0]" + "`n"
                    $j++
                }
            }
            $window.Log.Text = $window.Log.Text + "Generating $($SourceRow.FILENAME) successful" + "`n"
        } Catch { $window.Log.Text = $window.Log.Text + "ERROR: Importing $InputFile.$ext failed: \n $Error[0]" + "`n" }
        $window.Log.Text = $window.Log.Text + "SUMMARY: $i files saved successfully" + "`n"
    }
    # MS Azure Cognative Services / SINGLE
    ElseIf ( $window.TTS_MS.IsChecked -eq $true -and $window.OP_SINGLE.IsChecked -eq $true ){
        $MS_Datacenter = $window.MS_Datacenter.Text
        $MS_Audio_Format = $window.MS_Audio_Format.Text
        $MS_Voice = $window.MS_Voice.Text
        $MS_VoiceList = $( $( $( $( $MS_Voice -Replace 'Microsoft Server Speech Text to Speech Voice ','' ) -Replace [regex]::escape('(');, '' )  -Replace [regex]::escape(')');, '' ) -replace ('  ', '') )
        If ( $MS_Audio_Format.Substring($($MS_Audio_Format.Length) - 3,3) -eq "mp3" ) { $ext = "mp3" } Else { $ext = "wav" }
        $Script=$window.Input_Script.Text
        $MS_RequestHeaders = @{"Authorization"= $MS_OAuthToken;"Content-Type"= "application/ssml+xml";"X-Microsoft-OutputFormat"= $MS_Audio_Format;"User-Agent" = "$UserAgent"}
        [xml]$MS_VoiceBody = "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'><voice name='" + $MS_Voice + "'>$Script</voice></speak>"
        $DestinationFile = "$($OutputPath)\Single-Script_$MS_VoiceList.$ext"
        Try {
            Write-Host "Sending script..."
            Invoke-RestMethod -Method POST -Uri $MS_ServiceURI -Headers $MS_RequestHeaders -Body $MS_VoiceBody -ContentType "application/ssml+xml" -OutFile $DestinationFile
            $window.Log.Text = $window.Log.Text + "Generating $DestinationFile successful" + "`n"
        }
        Catch { $window.Log.Text = $window.Log.Text + "ERROR: Saving $DestinationFile failed: \n $Error[0]" + "`n" }
    }
    
    # GCloud TTS / SINGLE
    ElseIf ( $window.TTS_GC.IsChecked -eq $true -and $window.OP_SINGLE.IsChecked -eq $true ){
        #Save-Config $Configfile $window.Key.Text $window.GC_Datacenter.Text $window.GC_Audio_Format.Text $window.GC_Voice.Text $window.Input_File.Text $window.Output_Path.Text 
        $GC_Endpoint = "https://texttospeech.googleapis.com/v1/text:synthesize"
        
        $GC_Key = $window.Key.Text
        $Script=$window.Input_Script.Text

        $GC_Audio_Format = $window.GC_Audio_Format.Text
        $GC_RequestHeaders = @{"Authorization"="Bearer $GC_Key"; "Content-Type"="application/json";}
        $languageCode = 'en'

$GC_Body = @{
    input=@{
        text = $Script
    };
    voice=@{
        languageCode=$languageCode
    };
    audioConfig=@{
        audioEncoding='MP3'
    };
}

        #Try conversion request
        try{
            $response = Invoke-RestMethod -headers $GC_RequestHeaders -Uri $GC_Endpoint -Method Post -body $(ConvertTo-Json ($GC_Body))
            #Extract the base64 encoded response
            $base64Audio = $response.audioContent

            #Produce output file
            $base64Audio | Out-File -FilePath "./google.txt" -Encoding ascii -Force
            $convertedFileName = 'GTTS-Plain-{0}.mpga' -f (get-date -f yyyy-MM-dd-hh-mm-ss)
            certutil -decode google.txt $convertedFileName
        }
        catch {
            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        }
    }
}
$window.Log_Clear.add_Click{
    param (
        [Parameter(Mandatory)][Object]$sender,
        [Parameter(Mandatory)][Windows.RoutedEventArgs]$e
    )
    $window.Log.Text = ""
}
$window.Save.add_Click{
    # remove param() block if access to event information is not required
    param (
        [Parameter(Mandatory)][Object]$sender,
        [Parameter(Mandatory)][Windows.RoutedEventArgs]$e
    )
  
    Save-Config $Configfile $window.Key.Text $window.MS_Datacenter.Text $window.MS_Audio_Format.Text $window.MS_Voice.Text $window.Input_File.Text $window.Output_Path.Text 
}
$window.Input_Browse.add_Click{
    # remove param() block if access to event information is not required
    param (
        [Parameter(Mandatory)][Object]$sender,
        [Parameter(Mandatory)][Windows.RoutedEventArgs]$e
    )
    $window.Input_File.Text = (Get-File "Select a CSV file for import")
}
$window.Output_Browse.add_Click{
    # remove param() block if access to event information is not required
    param (
        [Parameter(Mandatory)][Object]$sender,
        [Parameter(Mandatory)][Windows.RoutedEventArgs]$e
    )
    $window.Output_Path.Text = (Get-Folder "Select the output folder or create a new one")
}
$window.MS_Datacenter.add_LostFocus{
    # remove param() block if access to event information is not required
    param (
        [Parameter(Mandatory)][Object]$sender,
        [Parameter(Mandatory)][Windows.RoutedEventArgs]$e
    )
    $MS_KEY= $window.Key.Text
    $MS_Datacenter= $window.MS_Datacenter.Text
    $MS_TokenURI = "https://$($MS_Datacenter).api.cognitive.microsoft.com/sts/v1.0/issueToken"
    $MS_ServiceURI = "https://$($MS_Datacenter).tts.speech.microsoft.com/cognitiveservices/v1"
    $MS_VoiceListURI = "https://$($MS_Datacenter).tts.speech.microsoft.com/cognitiveservices/voices/list"
    $MS_TokenHeaders = @{"Content-type"= "application/x-www-form-urlencoded";"Content-Length"= "0";"Ocp-Apim-Subscription-Key"= $MS_KEY}
    $MS_OAuthToken = Invoke-RestMethod -Method POST -Uri $MS_TokenURI -Headers $MS_TokenHeaders
    $MS_Auth_Bearer = @{"Authorization"= $MS_OAuthToken}
    $MS_VoiceList = Invoke-RestMethod -Method GET -Uri $MS_VoiceListURI -Headers $MS_Auth_Bearer
    #$MS_VoiceList | fl
    $window.MS_Voice.Text= $MS_Voice
}
$window.LucaVitali_GitHub.add_Click{
    # remove param() block if access to event information is not required
    param (
        [Parameter(Mandatory)][Object]$sender,
        [Parameter(Mandatory)][Windows.RoutedEventArgs]$e
    )
    Start-Process ("https://github.com/LucaVitali");
}
$window.sjackson0109_GitHub.add_Click{
    # remove param() block if access to event information is not required
    param (
        [Parameter(Mandatory)][Object]$sender,
        [Parameter(Mandatory)][Windows.RoutedEventArgs]$e
    )
    Start-Process ("https://github.com/sjackson0109");
}
$window.Input_TIP.add_Click{
    # remove param() block if access to event information is not required
    param (
        [Parameter(Mandatory)][Object]$sender,
        [Parameter(Mandatory)][Windows.RoutedEventArgs]$e
    )
    [System.Windows.MessageBox]::Show("Please select a CSV file type. `nThe file should be comma-delimited `nand quotation encapsulated where there are spaces within the cell value. `n`nColumns: SCRIPT, FILENAME")
}
$window.MS_Audio_Format_Tip.add_Click{
    # remove param() block if access to event information is not required
    param (
        [Parameter(Mandatory)][Object]$sender,
        [Parameter(Mandatory)][Windows.RoutedEventArgs]$e
    )
    [System.Windows.MessageBox]::Show("Two audio encoding formats are marked in bold. `nThe WAV format is for PSTN grade call-quality. `nThe MP3 file is for SIP grade call-quality.")
}
$window.MS_Guide.add_Click{
    # remove param() block if access to event information is not required
    param (
        [Parameter(Mandatory)][Object]$sender,
        [Parameter(Mandatory)][Windows.RoutedEventArgs]$e
    )
    Start-Process ("https://docs.microsoft.com/en-us/azure/cognitive-services/speech-service/rest-text-to-speech");
}
$window.MS_Sign_Up.add_Click{
    # remove param() block if access to event information is not required
    param (
        [Parameter(Mandatory)][Object]$sender,
        [Parameter(Mandatory)][Windows.RoutedEventArgs]$e
    )
    Start-Process ("http://bit.ly/AzureTTSGUI");
}


# Show Window
$MS_KEY,$MS_Datacenter,$MS_Audio_Format,$MS_Voice,$InputFile,$OutputPath = Get-Config
$MS_TokenURI = "https://$($MS_Datacenter).api.cognitive.microsoft.com/sts/v1.0/issueToken"
$MS_ServiceURI = "https://$($MS_Datacenter).tts.speech.microsoft.com/cognitiveservices/v1"
$TokenHeaders = @{"Content-type"= "application/x-www-form-urlencoded";"Content-Length"= "0";"Ocp-Apim-Subscription-Key"= $MS_KEY}
$MS_OAuthToken = Invoke-RestMethod -Method POST -Uri $MS_TokenURI -Headers $TokenHeaders
$MS_VoiceListURI = "https://$($MS_Datacenter).tts.speech.microsoft.com/cognitiveservices/voices/list"
$MS_Auth_Bearer = @{"Authorization"= $MS_OAuthToken}
$MS_VoiceList = Invoke-RestMethod -Method GET -Uri $MS_VoiceListURI -Headers $MS_Auth_Bearer
$window.Key.Text= $MS_KEY
$window.MS_Datacenter.Text= $MS_Datacenter
$window.MS_Audio_Format.Text= $MS_Audio_Format
$window.MS_Voice.ItemsSource= $MS_VoiceList.Name
$window.MS_Voice.Text= $MS_Voice
$window.Output_Path.Text= $OutputPath
$window.Input_File.Text= $InputFile
$window.Version.Content= $Version
$result = Show-WPFWindow -Window $window
#region Process results
if ($result -eq $true) { } else { }
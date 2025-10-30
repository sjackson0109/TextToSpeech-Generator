function Convert-XAMLtoWindow {
    <#
    .SYNOPSIS
    Convert XAML string to WPF Window object
    #>
    param ( [Parameter(Mandatory=$true)][string]$XAML )
    Add-Type -AssemblyName PresentationFramework

    try {
        $stringReader = New-Object System.IO.StringReader($XAML)
        $xmlReader = [System.Xml.XmlReader]::Create($stringReader)
        $window = [System.Windows.Markup.XamlReader]::Load($xmlReader)
        return $window
    }
    catch {
        Write-ErrorLog -Operation "Convert-XAMLtoWindow" -Exception $_ -Context @{ XAMLLength = $XAML.Length }
        throw $_
    }
}
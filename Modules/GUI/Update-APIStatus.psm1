function Update-APIStatus {
    <#
    .SYNOPSIS
    Update the API status display below the Setup and Connect buttons, with provider-specific logic
    #>
    param (
        [Parameter(Mandatory=$true)][string]$SetupStatus,
        [Parameter(Mandatory=$false)][string]$SetupColor = "#FFFF0000",
        [Parameter(Mandatory=$false)][string]$ConnectStatus = $null,
        [Parameter(Mandatory=$false)][string]$ConnectColor = "#FFDDDDDD",
        [Parameter(Mandatory=$false)][object]$SetupWindow = $null,
        [Parameter(Mandatory=$false)][string]$Provider = $null
    )


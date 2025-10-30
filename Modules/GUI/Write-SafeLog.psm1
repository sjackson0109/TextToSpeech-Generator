function Write-SafeLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    if (Get-Command Write-ApplicationLog -ErrorAction SilentlyContinue) {
        Write-ApplicationLog -Message $Message -Level $Level
    } else {
        Write-Host "[$Level] $Message" -ForegroundColor $(if ($Level -eq "ERROR") { "Red" } elseif ($Level -eq "WARNING") { "Yellow" } else { "White" })
    }
}

Export-ModuleMember -Function Write-SafeLog
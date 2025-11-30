# PowerShell profile to ensure Logging.psm1 is always loaded globally for every session
$loggingModulePath = Join-Path $PSScriptRoot 'Modules\Logging.psm1'
if (Test-Path $loggingModulePath) {
    if (Get-Module -Name Logging) {
        Remove-Module -Name Logging -Force
    }
    Import-Module $loggingModulePath -Force -Global
}

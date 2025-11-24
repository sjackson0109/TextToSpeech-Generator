<#
.SYNOPSIS
    Converts American English spellings to British English throughout the codebase.

.DESCRIPTION
    This script searches through all PowerShell, Markdown, and text files in the project
    and replaces common American English spellings with their British English equivalents.
    Creates backups before making changes.

.PARAMETER BackupFolder
    Optional folder to store backups. Defaults to "Backups\[timestamp]"

.PARAMETER WhatIf
    Shows what would be changed without making actual changes

.EXAMPLE
    .\Convert-ToUKEnglish.ps1
    
.EXAMPLE
    .\Convert-ToUKEnglish.ps1 -WhatIf
    
.EXAMPLE
    .\Convert-ToUKEnglish.ps1 -BackupFolder ".\MyBackups"
#>

[CmdletBinding()]
param(
    [string]$BackupFolder,
    [switch]$WhatIf
)

# Define American -> British spelling mappings
# Using array of objects to handle case-sensitive replacements
$spellingReplacements = @(
    # -ize to -ise
    @{US='initialis'; UK='initialis'}  # Handles initialise, initialised, initialising, initialising
    @{US='optimis'; UK='optimis'}      # Handles optimise, optimised, optimisation, optimising
    @{US='organis'; UK='organis'}      # Handles organise, organised, organisation, organising
    @{US='authoris'; UK='authoris'}    # Handles authorise, authorised, authorisation, authorising
    @{US='specialis'; UK='specialis'}  # Handles specialise, specialised, specialisation
    @{US='recognis'; UK='recognis'}    # Handles recognise, recognised, recognition
    @{US='synchronis'; UK='synchronis'} # Handles synchronise, synchronised, synchronisation
    @{US='analys'; UK='analys'}        # Handles analyse, analysed, analysis
    @{US='categor'; UK='categor'}      # Keep same but will handle -ize ending
    @{US='customi'; UK='customi'}      # Keep same but will handle -ize ending
    @{US='moderni'; UK='moderni'}      # Keep same but will handle -ize ending
    
    # -or to -our (full words to avoid false matches)
    @{US='colour'; UK='colour'}
    @{US='colour'; UK='Colour'}
    @{US='behaviour'; UK='behaviour'}
    @{US='behaviour'; UK='Behaviour'}
    @{US='favour'; UK='favour'}
    @{US='favour'; UK='Favour'}
    @{US='favourite'; UK='favourite'}
    @{US='favourite'; UK='Favourite'}
    @{US='honour'; UK='honour'}
    @{US='honour'; UK='Honour'}
    @{US='labour'; UK='labour'}
    @{US='labour'; UK='Labour'}
    @{US='neighbour'; UK='neighbour'}
    @{US='neighbour'; UK='Neighbour'}
    
    # -er to -re
    @{US='centre'; UK='centre'}
    @{US='centre'; UK='Centre'}
    @{US='centreed'; UK='centred'}
    @{US='centreed'; UK='Centred'}
    @{US='metre'; UK='metre'}
    @{US='metre'; UK='Metre'}
    @{US='theatre'; UK='theatre'}
    @{US='theatre'; UK='Theatre'}
    
    # -og to -ogue
    @{US='Catalogueue'; UK='Catalogueueue'}
    @{US='Catalogueue'; UK='Catalogueueue'}
    @{US='Dialogueue'; UK='Dialogueueue'}
    @{US='Dialogueue'; UK='Dialogueueue'}
    
    # -ense to -ence
    @{US='defence'; UK='defence'}
    @{US='defence'; UK='Defence'}
    @{US='licence'; UK='licence'}
    @{US='licence'; UK='Licence'}
    
    # -ll words
    @{US='cancelled'; UK='cancelled'}
    @{US='cancelled'; UK='Cancelled'}
    @{US='cancelling'; UK='cancelling'}
    @{US='cancelling'; UK='Cancelling'}
    @{US='travelled'; UK='travelled'}
    @{US='travelled'; UK='Travelled'}
    @{US='travelling'; UK='travelling'}
    @{US='travelling'; UK='Travelling'}
    @{US='labelled'; UK='labelled'}
    @{US='labelled'; UK='Labelled'}
    @{US='labelling'; UK='labelling'}
    @{US='labelling'; UK='Labelling'}
)

# Files to process
$fileExtensions = @('*.ps1', '*.psm1', '*.md', '*.txt', '*.json')

# Create backup folder
if (-not $BackupFolder) {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $BackupFolder = Join-Path $PSScriptRoot "Backups\UKEnglish_$timestamp"
}

if (-not (Test-Path $BackupFolder) -and -not $WhatIf) {
    New-Item -ItemType Directory -Path $BackupFolder -Force | Out-Null
    Write-Host "Created backup folder: $BackupFolder" -ForegroundColor Green
}

# Get all files to process
$filesToProcess = @()
foreach ($ext in $fileExtensions) {
    $filesToProcess += Get-ChildItem -Path $PSScriptRoot -Filter $ext -Recurse -File | 
        Where-Object { $_.FullName -notlike "*\Backups\*" -and $_.FullName -notlike "*\.git\*" }
}

Write-Host "`nFound $($filesToProcess.Count) files to process" -ForegroundColor Cyan
Write-Host "Searching for American English spellings...`n" -ForegroundColor Cyan

$totalReplacements = 0
$filesModified = 0

foreach ($file in $filesToProcess) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    $fileReplacements = 0
    $replacementDetails = @()
    
    # Apply each spelling replacement
    foreach ($replacement in $spellingReplacements) {
        $american = $replacement.US
        $british = $replacement.UK
        
        # Use word boundary regex to avoid partial word matches
        $pattern = "\b$([regex]::Escape($american))"
        
        if ($content -match $pattern) {
            $matches = [regex]::Matches($content, $pattern)
            $count = $matches.Count
            $fileReplacements += $count
            $content = $content -replace $pattern, $british
            
            if ($WhatIf) {
                $replacementDetails += "  Would replace '$american*' -> '$british*' ($count times)"
            }
        }
    }
    
    # Show details for WhatIf
    if ($WhatIf -and $replacementDetails.Count -gt 0) {
        foreach ($detail in $replacementDetails) {
            Write-Host $detail -ForegroundColor Yellow
        }
    }
    
    # If changes were made, backup and update file
    if ($content -ne $originalContent) {
        $filesModified++
        $totalReplacements += $fileReplacements
        
        $relativePath = $file.FullName.Substring($PSScriptRoot.Length + 1)
        Write-Host "[$filesModified] $relativePath" -ForegroundColor Green
        Write-Host "    $fileReplacements replacement(s)" -ForegroundColor Gray
        
        if (-not $WhatIf) {
            # Create backup
            $backupPath = Join-Path $BackupFolder $relativePath
            $backupDir = Split-Path $backupPath -Parent
            if (-not (Test-Path $backupDir)) {
                New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            }
            Copy-Item -Path $file.FullName -Destination $backupPath -Force
            
            # Write updated content
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        }
    }
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "WhatIf Mode: No files were modified" -ForegroundColor Yellow
    Write-Host "Would modify: $filesModified files" -ForegroundColor Yellow
    Write-Host "Would make: $totalReplacements total replacements" -ForegroundColor Yellow
} else {
    Write-Host "Modified: $filesModified files" -ForegroundColor Green
    Write-Host "Total replacements: $totalReplacements" -ForegroundColor Green
    Write-Host "Backups saved to: $BackupFolder" -ForegroundColor Green
}

Write-Host "`nDone!" -ForegroundColor Cyan

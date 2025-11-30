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
$spellingReplacements = @(
    # -ize to -ise (stem replacements)
    @{US='Initializ'; UK='Initialis'; Type='Stem'}
    @{US='initializ'; UK='initialis'; Type='Stem'}
    @{US='Optimiz'; UK='Optimis'; Type='Stem'}
    @{US='optimiz'; UK='optimis'; Type='Stem'}
    @{US='Organiz'; UK='Organis'; Type='Stem'}
    @{US='organiz'; UK='organis'; Type='Stem'}
    @{US='Authoriz'; UK='Authoris'; Type='Stem'}
    @{US='authoriz'; UK='authoris'; Type='Stem'}
    @{US='Specializ'; UK='Specialis'; Type='Stem'}
    @{US='specializ'; UK='specialis'; Type='Stem'}
    @{US='Recogniz'; UK='Recognis'; Type='Stem'}
    @{US='recogniz'; UK='recognis'; Type='Stem'}
    @{US='Synchroniz'; UK='Synchronis'; Type='Stem'}
    @{US='synchroniz'; UK='synchronis'; Type='Stem'}
    @{US='Analyz'; UK='Analys'; Type='Stem'}
    @{US='analyz'; UK='analys'; Type='Stem'}
    @{US='Categoriz'; UK='Categoris'; Type='Stem'}
    @{US='categoriz'; UK='categoris'; Type='Stem'}
    @{US='Customiz'; UK='Customis'; Type='Stem'}
    @{US='customiz'; UK='customis'; Type='Stem'}
    @{US='Moderniz'; UK='Modernis'; Type='Stem'}
    @{US='moderniz'; UK='modernis'; Type='Stem'}
    
    # -or to -our (full words)
    @{US='Color'; UK='Colour'; Type='Word'}
    @{US='color'; UK='colour'; Type='Word'}
    @{US='Behavior'; UK='Behaviour'; Type='Word'}
    @{US='behavior'; UK='behaviour'; Type='Word'}
    @{US='Favor'; UK='Favour'; Type='Word'}
    @{US='favor'; UK='favour'; Type='Word'}
    @{US='Favorite'; UK='Favourite'; Type='Word'}
    @{US='favorite'; UK='favourite'; Type='Word'}
    @{US='Honor'; UK='Honour'; Type='Word'}
    @{US='honor'; UK='honour'; Type='Word'}
    @{US='Labor'; UK='Labour'; Type='Word'}
    @{US='labor'; UK='labour'; Type='Word'}
    @{US='Neighbor'; UK='Neighbour'; Type='Word'}
    @{US='neighbor'; UK='neighbour'; Type='Word'}
    
    # -er to -re (full words)
    @{US='Center'; UK='Centre'; Type='Word'}
    @{US='center'; UK='centre'; Type='Word'}
    @{US='Centered'; UK='Centred'; Type='Word'}
    @{US='centered'; UK='centred'; Type='Word'}
    @{US='Meter'; UK='Metre'; Type='Word'}
    @{US='meter'; UK='metre'; Type='Word'}
    @{US='Theater'; UK='Theatre'; Type='Word'}
    @{US='theater'; UK='theatre'; Type='Word'}
    
    # -og to -ogue (full words)
    @{US='Catalog'; UK='Catalogue'; Type='Word'}
    @{US='catalog'; UK='catalogue'; Type='Word'}
    @{US='Dialog'; UK='Dialogue'; Type='Word'}
    @{US='dialog'; UK='dialogue'; Type='Word'}
    
    # -ense to -ence (full words)
    @{US='Defense'; UK='Defence'; Type='Word'}
    @{US='defense'; UK='defence'; Type='Word'}
    @{US='License'; UK='Licence'; Type='Word'}
    @{US='license'; UK='licence'; Type='Word'}
    
    # -ll words (full words)
    @{US='Canceled'; UK='Cancelled'; Type='Word'}
    @{US='canceled'; UK='cancelled'; Type='Word'}
    @{US='Canceling'; UK='Cancelling'; Type='Word'}
    @{US='canceling'; UK='cancelling'; Type='Word'}
    @{US='Traveled'; UK='Travelled'; Type='Word'}
    @{US='traveled'; UK='travelled'; Type='Word'}
    @{US='Traveling'; UK='Travelling'; Type='Word'}
    @{US='traveling'; UK='travelling'; Type='Word'}
    @{US='Labeled'; UK='Labelled'; Type='Word'}
    @{US='labeled'; UK='labelled'; Type='Word'}
    @{US='Labeling'; UK='Labelling'; Type='Word'}
    @{US='labeling'; UK='labelling'; Type='Word'}
)

# Files to process
$fileExtensions = @('*.ps1', '*.psm1', '*.md', '*.txt', '*.json')

# Words that should NOT be replaced when they appear in quotes (framework/API terms)
$quotedExclusions = @('Center', 'center', 'Centered', 'centered', 'Color', 'color', 'Behavior', 'behavior')

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
$scriptName = Split-Path $MyInvocation.MyCommand.Path -Leaf
foreach ($ext in $fileExtensions) {
    $filesToProcess += Get-ChildItem -Path $PSScriptRoot -Filter $ext -Recurse -File | 
        Where-Object { 
            $_.FullName -notlike "*\Backups\*" -and 
            $_.FullName -notlike "*\.git\*" -and
            $_.Name -ne $scriptName
        }
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
        $type = $replacement.Type
        
        if ($type -eq 'Stem') {
            # Stem replacement: match stem + any following word characters
            # Pattern: word boundary, then our stem, then capture any word chars
            $pattern = "\b$([regex]::Escape($american))(\w+)\b"
            
            $matches = [regex]::Matches($content, $pattern)
            if ($matches.Count -gt 0) {
                $count = 0
                foreach ($match in $matches) {
                    $fullWord = $match.Value
                    $suffix = $match.Groups[1].Value
                    $britishWord = $british + $suffix
                    
                    # Only replace if not already British spelling
                    if ($fullWord -ne $britishWord) {
                        $content = $content.Replace($fullWord, $britishWord)
                        $count++
                    }
                }
                
                if ($count -gt 0) {
                    $fileReplacements += $count
                    if ($WhatIf) {
                        $replacementDetails += "  Would replace '$american*' -> '$british*' ($count times)"
                    }
                }
            }
        }
        else {
            # Full word replacement
            $pattern = "\b$([regex]::Escape($american))\b"
            
            if ($content -match $pattern) {
                # Check if this word should be excluded when in quotes
                $skipQuoted = $quotedExclusions -contains $american
                
                if ($skipQuoted) {
                    # Find all matches and only replace those NOT in quotes
                    $matches = [regex]::Matches($content, $pattern)
                    $count = 0
                    
                    foreach ($match in $matches) {
                        $position = $match.Index
                        
                        # Check if this match is within quotes
                        $beforeText = $content.Substring(0, $position)
                        $inDoubleQuotes = ($beforeText.Split('"').Count % 2) -eq 0
                        $inSingleQuotes = ($beforeText.Split("'").Count % 2) -eq 0
                        
                        # If NOT in quotes, mark for replacement
                        if ($inDoubleQuotes -and $inSingleQuotes) {
                            $count++
                        }
                    }
                    
                    if ($count -gt 0) {
                        # Replace only matches not in quotes using a callback
                        $newContent = [regex]::Replace($content, $pattern, {
                            param($m)
                            $pos = $m.Index
                            $before = $content.Substring(0, $pos)
                            $inDQ = ($before.Split('"').Count % 2) -eq 0
                            $inSQ = ($before.Split("'").Count % 2) -eq 0
                            
                            if ($inDQ -and $inSQ) {
                                return $british
                            } else {
                                return $m.Value
                            }
                        })
                        
                        $content = $newContent
                        $fileReplacements += $count
                        
                        if ($WhatIf) {
                            $replacementDetails += "  Would replace '$american' -> '$british' ($count times, excluding quoted)"
                        }
                    }
                } else {
                    # Normal replacement for non-excluded words
                    $matches = [regex]::Matches($content, $pattern)
                    $count = $matches.Count
                    $fileReplacements += $count
                    $content = $content -replace $pattern, $british
                    
                    if ($WhatIf) {
                        $replacementDetails += "  Would replace '$american' -> '$british' ($count times)"
                    }
                }
            }
        }
    }
    
    # Show details for WhatIf
    if ($WhatIf -and $replacementDetails.Count -gt 0) {
        Write-Host "`n$($file.Name):" -ForegroundColor Cyan
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
# Performance Optimisation Module for TextToSpeech Generator v3.2
# Type definitions loader

# Import required modules
Import-Module -Name "$PSScriptRoot\Logging.psm1" -Force

# Load C# type definitions
try {
    [ConnectionPool] | Out-Null
    Add-ApplicationLog -Message "ConnectionPool type already loaded" -Level "DEBUG"
} catch {
    try {
        $typeDefinitionPath = Join-Path $PSScriptRoot ".\OptimisationTypes.cs"
        
        if (Test-Path $typeDefinitionPath) {
            Add-Type -Path $typeDefinitionPath -ErrorAction Stop
            Add-ApplicationLog -Message "Loaded performance optimisation types from external file" -Level "INFO"
        } else {
            Add-ApplicationLog -Message "Type definition file not found at: $typeDefinitionPath" -Level "ERROR"
            throw "Required type definitions file not found: $typeDefinitionPath"
        }
    } catch {
        Add-ApplicationLog -Message "Failed to load types: $_" -Level "ERROR"
        throw
    }
}

# The data types are now available for use in the Performance module

# ============================================================================
# OPTIMISATION MODULE FUNCTIONS
function New-OptimisationConnectionPool {
    param(
        [string]$Provider,
        [int]$MinSize = 2,
        [int]$MaxSize = 10
    )
    return [ConnectionPool]::new($Provider, $MinSize, $MaxSize)
}

function New-OptimisationAsyncManager {
    param(
        [int]$MaxConcurrency = 5
    )
    return [AsyncOperationManager]::new($MaxConcurrency)
}

function New-OptimisationConnection {
    param(
        [string]$Provider,
        [string]$Id = ([guid]::NewGuid().ToString())
    )
    return [Connection]::new($Provider, $Id)
}

function Remove-OptimisationConnection {
    param(
        [object]$ConnectionPool,
        [object]$Connection
    )
    $ConnectionPool.ReleaseConnection($Connection)
}

function Get-OptimisationConnection {
    param(
        [object]$ConnectionPool
    )
    return $ConnectionPool.AcquireConnection()
}

function Get-OptimisationAsyncSlot {
    param(
        [object]$AsyncManager
    )
    return $AsyncManager.AvailableSlots
}

# Existing PerformanceOptimiser functions
function New-PerformanceOptimiser {
    return [PerformanceOptimiser]::new()
}

function Get-PerformanceReport {
    param([PerformanceOptimiser]$Optimiser)
    return $Optimiser.GetPerformanceReport()
}

function Optimise-ConnectionPools {
    param([PerformanceOptimiser]$Optimiser)
    $Optimiser.OptimiseConnectionPools()
}

function Clear-PerformanceCaches {
    param(
        [PerformanceOptimiser]$Optimiser,
        [string[]]$CacheTypes = @()
    )
    $Optimiser.ClearCaches($CacheTypes)
}

# Export all required module members
Export-ModuleMember -Function @(
    'New-OptimisationConnectionPool',
    'New-OptimisationAsyncManager',
    'New-OptimisationConnection',
    'Remove-OptimisationConnection',
    'Get-OptimisationConnection',
    'Get-OptimisationAsyncSlot',
    'New-PerformanceOptimiser',
    'Get-PerformanceReport', 
    'Optimise-ConnectionPools',
    'Clear-PerformanceCaches'
)

# Export key functions for use in main script
Export-ModuleMember -Function 'New-OptimisationConnectionPool', 'New-OptimisationAsyncManager'

Add-ApplicationLog -Message "Optimisation module loaded successfully" -Level "INFO"
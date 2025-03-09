# Profiling Utility Functions for Performance Measurement

# Global dictionary for profiling data
$global:ProfileData = @{}

# Function to start profiling a section
function Start-Profiling {
    param (
        [string]$Section
    )
    $global:ProfileData[$Section] = [System.Diagnostics.Stopwatch]::StartNew()
}

# Function to stop profiling a section and log time
function Stop-Profiling {
    param (
        [string]$Section
    )
    if ($global:ProfileData.ContainsKey($Section)) {
        $global:ProfileData[$Section].Stop()
        $Elapsed = $global:ProfileData[$Section].Elapsed.TotalSeconds
        Add-Content -Path "$PSScriptRoot/../log/profiling.log" -Value ("[PROFILE] {0}: {1} seconds" -f $Section, $Elapsed)
        Write-Host ("[PROFILE] {0}: {1} seconds" -f $Section, $Elapsed) -ForegroundColor Cyan
    }
}

# Function to clear profiling data
function Reset-Profiling {
    $global:ProfileData.Clear()
    Write-Host "[PROFILE] Reset profiling data." -ForegroundColor Yellow
}

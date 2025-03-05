# Import functions from separate files
. "$PSScriptRoot\Config.ps1"
. "$PSScriptRoot\Proxy.ps1"
. "$PSScriptRoot\Metadata.ps1"
. "$PSScriptRoot\ObjectDetection.ps1"

# Ask user for mode
Write-Host "Select mode:"
Write-Host "1 - Create Proxy Images (with original path metadata)"
Write-Host "2 - Restore EXIF Data to Original Files (using stored metadata)"
Write-Host "3 - Detect Objects in Proxy Images & Tag Metadata"
$Mode = Read-Host "Enter option (1, 2, or 3)"

# Execute based on user choice
if ($Mode -eq "1") {
    Write-Host "[START] Creating Proxy Images..."
    Create-Proxies $SourceFolder $ProxyFolder $ImageMagickPath $ExifToolPath $MaxConcurrentJobs
} elseif ($Mode -eq "2") {
    Write-Host "[START] Restoring EXIF Data from Proxies..."
    Restore-Exif-Metadata $ProxyFolder $SourceFolder $ExifToolPath $MaxConcurrentJobs
} elseif ($Mode -eq "3") {
    Write-Host "[START] Detecting Objects in Proxy Images..."
    Detect-Objects-In-Proxies $ProxyFolder $PythonPath $PythonScript $ExifToolPath $MaxConcurrentJobs
}

Write-Host "[INFO] Task Completed."

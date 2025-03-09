# Import functions from separate files
. "$PSScriptRoot/config/Config.ps1"
. "$PSScriptRoot/common/GetFilesToProcess.ps1"
. "$PSScriptRoot/common/Profiling.ps1"
. "$PSScriptRoot/sqlite/SQLiteUtils.ps1"
. "$PSScriptRoot/modes/CreateProxies/Proxy.ps1"
. "$PSScriptRoot/modes/UpdateMetadata/Metadata.ps1"
. "$PSScriptRoot/modes/DetectObjects/ObjectDetection.ps1"

# Ask user for mode
Write-Host "Select mode:"
Write-Host "1 - Create Proxy Images (with original path metadata)"
Write-Host "2 - Restore EXIF Data to Original Files (using stored metadata)"
Write-Host "3 - Detect Objects in Proxy Images & Tag Metadata"
$Mode = Read-Host "Enter option (1, 2, or 3)"

# Select the correct log file for each operation
$LogFile = "$PSScriptRoot/log/log_mode$Mode.log"

# Initialize database
Initialize-Database

# Check if a cached file list exists
Write-Host "[INFO] Checking cached file list in SQLite..."
$FilesToProcess = Load-Originals

if ($FilesToProcess.Count -gt 0) {
    Write-Host "[INFO] A cached file list exists for this mode."
    $UseCache = Read-Host "Do you want to use the cached list? (Y/N)"
    if ($UseCache -ne "Y") {
        Write-Host "[INFO] Rescanning files..."
        $FilesToProcess = @()
    }
}

# If cache is not used, scan for files
if ($FilesToProcess.Count -eq 0) {
    Write-Host "[INFO] Scanning folder for new files..."
    $FilesToProcess = Get-Files-To-Process -FolderPath $SourceFolder -LogFile $LogFile
    foreach ($File in $FilesToProcess) {
        Insert-Original -FilePath $File.FullName
    }
}

# Execute based on user choice
if ($Mode -eq "1") {
    Write-Host "[START] Creating Proxy Images..."
    if ($FilesToProcess.Count -gt 0) {
        Create-Proxies -FilesToProcess $FilesToProcess -ProxyFolder $ProxyFolder -ImageMagickPath $ImageMagickPath -ExifToolPath $ExifToolPath -MaxConcurrentJobs $MaxConcurrentJobs -LogFile $LogFile
    } else {
        Write-Host "[INFO] No new images to process."
    }
} elseif ($Mode -eq "2") {
    Write-Host "[START] Restoring EXIF Data from Proxies..."
    if ($FilesToProcess.Count -gt 0) {
        Restore-Exif-Metadata -FilesToProcess $FilesToProcess -ProxyFolder $ProxyFolder -SourceFolder $SourceFolder -ExifToolPath $ExifToolPath -MaxConcurrentJobs $MaxConcurrentJobs -LogFile $LogFile
    } else {
        Write-Host "[INFO] No EXIF metadata needs restoration."
    }
} elseif ($Mode -eq "3") {
    Write-Host "[START] Detecting Objects in Proxy Images..."
    if ($FilesToProcess.Count -gt 0) {
        Detect-Objects-In-Proxies -FilesToProcess $FilesToProcess -ProxyFolder $ProxyFolder -PythonPath $PythonPath -PythonScript $PythonScript -ExifToolPath $ExifToolPath -MaxConcurrentJobs $MaxConcurrentJobs -LogFile $LogFile
    } else {
        Write-Host "[INFO] No new images need object detection."
    }
}

Write-Host "[INFO] Task Completed."

# Ensure database connection is closed at script end
Register-EngineEvent PowerShell.Exiting -Action { Close-Database }

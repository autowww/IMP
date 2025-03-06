function Get-Files-To-Process {
    param (
        [string]$FolderPath,
        [string]$LogFile,
        [string]$FilterPattern = "jpg|jpeg|png|tiff|tif|bmp|gif|webp|heic|heif|jxl|psd|xcf|arw|cr2|cr3|dng|nef|orf|pef|rw2|raf|srw|srf|mef|mos|iiq|kdc|3fr|rwl|nrw|bay"
    )

    # Read processed files from log
    $ProcessedFiles = @{}
    if (Test-Path $LogFile) {
        Get-Content $LogFile | ForEach-Object { $ProcessedFiles[$_] = $true }
        Write-Host "[INFO] Skipping already processed files from log..."
    }

    Write-Host "[INFO] Scanning folder: $FolderPath for files matching: $FilterPattern"
    
    # Retrieve all matching files, excluding those already processed
    $FilesToProcess = Get-ChildItem -Path $FolderPath -Recurse -File | Where-Object { 
        $_.Extension -match $FilterPattern -and !$ProcessedFiles.ContainsKey($_.FullName) 
    }

    if ($FilesToProcess.Count -eq 0) {
        Write-Host "[INFO] No new files to process."
    }

    return $FilesToProcess
}

function Get-Files-To-Process {
    param (
        [string]$FolderPath,
        [string]$LogFile,
        [string]$FilterPattern = "jpg|jpeg|png|tiff|tif|bmp|gif|webp|heic|heif|jxl|psd|xcf|arw|cr2|cr3|dng|nef|orf|pef|rw2|raf|srw|srf|mef|mos|iiq|kdc|3fr|rwl|nrw|bay"
    )

    # Read processed files from log
    $ProcessedFiles = @{}
    if (Test-Path $LogFile) {
        Get-Content $LogFile | Where-Object { $_ -match "\S" } | ForEach-Object { $ProcessedFiles[$_] = $true }
        Write-Host "[INFO] Skipping already processed files from log..."
    }

    Write-Host "[INFO] Scanning folder: $FolderPath for files matching: $FilterPattern"

    # Retrieve all matching files
    $AllFiles = Get-ChildItem -Path $FolderPath -Recurse -File | Where-Object {
        $_.Extension -match $FilterPattern -and !$ProcessedFiles.ContainsKey($_.FullName)
    }

    # **Filter out invalid/null entries**
    $FilesToProcess = $AllFiles | Where-Object { $_ -ne $null -and -not [string]::IsNullOrWhiteSpace($_.FullName) }

    Write-Host "[DEBUG] Found $($FilesToProcess.Count) valid files to process."

    return $FilesToProcess
}


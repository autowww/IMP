# Description: PowerShell script to create image proxies using ImageMagick and ExifTool

# Function to display progress messages based on selected mode
function progressOutput {
    param (
        [string]$Type, [string]$Message, [int]$ProcessedCount, [int]$TotalFiles,
        [int]$Skipped, [int]$Created, [int]$Updated, [int]$ZeroFixed, [int]$Left, [datetime]$StartTime
    )

    if ($LoggingMode -eq "Silent") { return }

    # Calculate progress percentage
    $ProgressPercent = [math]::Round(($ProcessedCount / [math]::Max(1, $TotalFiles)) * 100, 2)

    # Ensure ETA calculations don't fail
    if ($ProcessedCount -gt 0) {
        $ElapsedTime = (Get-Date) - $StartTime
        $TimePerFile = $ElapsedTime.TotalSeconds / [math]::Max(1, $ProcessedCount)
        $ETASeconds = [math]::Round(($Left) * $TimePerFile, 0)
        $ETA_Hours = [math]::Floor($ETASeconds / 3600) -as [int]
        $ETA_Minutes = [math]::Floor(($ETASeconds % 3600) / 60) -as [int]
        $ETAFormatted = "{0}:{1:D2}" -f $ETA_Hours, $ETA_Minutes
    } else {
        $ETAFormatted = "Calculating..."
    }

    # Overwrite previous progress output line
    $OutputString = "`r[Done: $ProgressPercent%, ETA: $ETAFormatted] Total: $TotalFiles, Skipped: $Skipped, Created: $Created, Updated: $Updated, Fixed: $ZeroFixed, Left: $Left   "

    if ($LoggingMode -eq "Summary") {
        Write-Host $OutputString -NoNewline
        return
    }

    Write-Host "`r[$Type] $OutputString - $Message"
}

# Function to process a single image
function Process-Image {
    param ($File, $ProxyFolder, $ImageMagickPath, $ExifToolPath, $LogFile)

    $RelativePath = $File.FullName.Replace($SourceFolder, "").TrimStart("\")
    $ProxyFilePath = Join-Path -Path $ProxyFolder -ChildPath $RelativePath
    $ProxyDir = Split-Path -Path $ProxyFilePath -Parent
    if (!(Test-Path $ProxyDir)) { New-Item -ItemType Directory -Path $ProxyDir -Force | Out-Null }

    # Check if proxy already exists
    $Status = "NEW"
    if (Test-Path $ProxyFilePath) {
        $StoredOriginalPath = & $ExifToolPath -s3 -XMP:OriginalFileName "$ProxyFilePath"

        if ((Get-Item $ProxyFilePath).Length -eq 0) {
            Remove-Item -Force "$ProxyFilePath"
            $global:ZeroFixed++
            progressOutput "WARNING" "Zero-byte proxy deleted: $ProxyFilePath" `
                $global:ProcessedCount $global:TotalFiles $global:Skipped $global:Created `
                $global:Updated $global:ZeroFixed $global:Left $StartTime
            $Status = "RECREATED"
        }
        elseif ($StoredOriginalPath -eq $RelativePath) {
            $global:Skipped++
            progressOutput "SKIP" "$File.FullName Proxy exists & metadata correct." `
                $global:ProcessedCount $global:TotalFiles $global:Skipped $global:Created `
                $global:Updated $global:ZeroFixed $global:Left $StartTime
            return
        } else {
            $Status = "METADATA UPDATED"
            $global:Updated++
        }
    } else {
        $global:Created++
    }

    # Process the image
    & $ImageMagickPath "$File.FullName" -resize "1024x1024>" -quality 85 "$ProxyFilePath" 2>&1 | Out-Null
    & $ExifToolPath -overwrite_original -XMP:OriginalFileName="$RelativePath" "$ProxyFilePath" 2>&1 | Out-Null
    Add-Content -Path $LogFile -Value "$File.FullName | $Status"

    # Insert proxy record into SQLite
    . "$PSScriptRoot/../sqlite/SQLiteUtils.ps1"
    Insert-Proxy -OriginalFilePath $File.FullName -ProxyFilePath $ProxyFilePath
}

# Function to create proxies sequentially
function Create-Proxies {
    param ($FilesToProcess, $ProxyFolder, $ImageMagickPath, $ExifToolPath, $LogFile)

    # Prompt Logging Mode AFTER mode selection
    Write-Host "`nSelect Logging Mode:"
    Write-Host "1 - Silent Mode (No output)"
    Write-Host "2 - Summary Mode (Progress updates only)"
    Write-Host "3 - Verbose Mode (Detailed output)"
    $LoggingModeSelection = Read-Host "Enter choice (1, 2, or 3)"

    if ($LoggingModeSelection -eq "1") { $LoggingMode = "Silent" }
    elseif ($LoggingModeSelection -eq "2") { $LoggingMode = "Summary" }
    else { $LoggingMode = "Verbose" }

    Start-Profiling -Section "Proxy Image Processing"

    $global:TotalFiles = $FilesToProcess.Count
    $global:ProcessedCount = 0
    $global:Skipped = 0
    $global:Created = 0
    $global:Updated = 0
    $global:ZeroFixed = 0
    $global:Left = $global:TotalFiles
    $StartTime = Get-Date

    foreach ($File in $FilesToProcess) {
        Process-Image -File $File -ProxyFolder $ProxyFolder -ImageMagickPath $ImageMagickPath -ExifToolPath $ExifToolPath -LogFile $LogFile
        $global:ProcessedCount++
        $global:Left = $global:TotalFiles - $global:ProcessedCount
        progressOutput "INFO" "Processed: $File.FullName" `
            $global:ProcessedCount $global:TotalFiles $global:Skipped $global:Created `
            $global:Updated $global:ZeroFixed $global:Left $StartTime
    }

    Stop-Profiling -Section "Proxy Image Processing"
}

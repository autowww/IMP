function Restore-Exif-Metadata {
    param ($ProxyFolder, $SourceFolder, $ExifToolPath, $MaxConcurrentJobs, $LogFile)

    # Get only unprocessed files
    $ProxyImages = Get-Files-To-Process -FolderPath $ProxyFolder -LogFile $LogFile

    foreach ($ProxyImage in $ProxyImages) {
        $OriginalPath = & $ExifToolPath -s3 -XMP:OriginalFileName "$ProxyImage.FullName"

        if ($OriginalPath -and (Test-Path "$SourceFolder\$OriginalPath")) {
            while ((Get-Job -State Running).Count -ge $MaxConcurrentJobs) { Start-Sleep -Seconds 2; Get-Job -State Completed | Remove-Job -Force }

            Write-Host "[RESTORE] Copying metadata from $ProxyImage to $OriginalPath"
            Start-Job -ScriptBlock {
                param($ExifToolPath, $ProxyImage, $OriginalPath, $LogFile)
                & $ExifToolPath -TagsFromFile "$ProxyImage" -overwrite_original "$OriginalPath"

                # Append processed file to log
                Add-Content -Path $LogFile -Value "$OriginalPath"
            } -ArgumentList $ExifToolPath, $ProxyImage.FullName, "$SourceFolder\$OriginalPath", $LogFile
        } else {
            Write-Host "[WARNING] No matching original found for: $ProxyImage"
        }
    }
}


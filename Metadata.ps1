function Restore-Exif-Metadata {
    param ($ProxyFolder, $SourceFolder, $ExifToolPath, $MaxConcurrentJobs)

    Write-Host "[INFO] Restoring EXIF metadata from proxies to originals..."
    $ProxyImages = Get-ChildItem -Path $ProxyFolder -Recurse -File -Filter "*.jpg"

    foreach ($ProxyImage in $ProxyImages) {
        $OriginalPath = & $ExifToolPath -s3 -XMP:OriginalFileName "$ProxyImage.FullName"

        if ($OriginalPath -and (Test-Path "$SourceFolder\$OriginalPath")) {
            while ((Get-Job -State Running).Count -ge $MaxConcurrentJobs) { Start-Sleep -Seconds 2; Get-Job -State Completed | Remove-Job -Force }

            Write-Host "[RESTORE] Copying metadata from $ProxyImage to $OriginalPath"
            Start-Job -ScriptBlock {
                param($ExifToolPath, $ProxyImage, $OriginalPath)
                & $ExifToolPath -TagsFromFile "$ProxyImage" -overwrite_original "$OriginalPath"
            } -ArgumentList $ExifToolPath, $ProxyImage.FullName, "$SourceFolder\$OriginalPath"
        } else {
            Write-Host "[WARNING] No matching original found for: $ProxyImage"
        }
    }
}

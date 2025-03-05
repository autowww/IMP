function Create-Proxies {
    param ($FolderPath, $ProxyFolder, $ImageMagickPath, $ExifToolPath, $MaxConcurrentJobs)

    Write-Host "[INFO] Scanning folder: $FolderPath"
    $Images = Get-ChildItem -Path $FolderPath -Recurse -File | Where-Object { $_.Extension -match "jpg|jpeg|png|tiff|tif|bmp|gif|webp|heic|heif|jxl|psd|xcf|arw|cr2|cr3|dng|nef|orf|pef|rw2|raf|srw|srf|mef|mos|kdc|iiq|3fr|rwl|nrw|bay" }

    foreach ($Image in $Images) {
        $OriginalFile = $Image.FullName
        $RelativePath = $OriginalFile.Replace($FolderPath, "").TrimStart("\")
        $ProxyFilePath = Join-Path -Path $ProxyFolder -ChildPath $RelativePath
        $ProxyFile = "$ProxyFilePath.jpg"
        $ProxyDir = Split-Path -Path $ProxyFile -Parent

        if (!(Test-Path $ProxyDir)) { New-Item -ItemType Directory -Path $ProxyDir -Force | Out-Null }

        if (Test-Path $ProxyFile) {
            Write-Host "[SKIP] Proxy already exists: $($Image.Name)"
            continue
        }

        while ((Get-Job -State Running).Count -ge $MaxConcurrentJobs) { Start-Sleep -Seconds 2; Get-Job -State Completed | Remove-Job -Force }

        Write-Host "[PROCESS] Creating proxy: $OriginalFile"
        Start-Job -ScriptBlock {
            param($ImageMagickPath, $ExifToolPath, $OriginalFile, $ProxyFile)
            & $ImageMagickPath "$OriginalFile" -define opencl:enable=true -resize "1024x1024>" -quality 85 "$ProxyFile"
            & $ExifToolPath -overwrite_original -XMP:OriginalFileName="$OriginalFile" "$ProxyFile"
        } -ArgumentList $ImageMagickPath, $ExifToolPath, $OriginalFile, $ProxyFile
    }
}

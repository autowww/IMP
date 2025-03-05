function Detect-Objects-In-Proxies {
    param ($ProxyFolder, $PythonPath, $PythonScript, $ExifToolPath, $MaxConcurrentJobs)

    Write-Host "[INFO] Running object detection on proxy images..."
    $OutputJSON = & $PythonPath $PythonScript "`"$ProxyFolder`""

    if ($OutputJSON -match "^{") {
        $DetectedObjects = $OutputJSON | ConvertFrom-Json
    } else {
        Write-Host "[ERROR] Invalid JSON output from Python script: $OutputJSON"
        exit
    }

    foreach ($ImageName in $DetectedObjects.PSObject.Properties.Name) {
        $ImagePath = Join-Path $ProxyFolder $ImageName
        $Tags = ($DetectedObjects.$ImageName -join ", ")

        while ((Get-Job -State Running).Count -ge $MaxConcurrentJobs) { Start-Sleep -Seconds 2; Get-Job -State Completed | Remove-Job -Force }

        Write-Host "[TAGGING] $ImageName with: $Tags"
        Start-Job -ScriptBlock {
            param($ExifToolPath, $ImagePath, $Tags)
            $ExistingTags = & $ExifToolPath -s3 -XMP:Subject "$ImagePath"
            if ($ExistingTags) {
                $MergedTags = ($ExistingTags -split ", ") + $Tags
                $MergedTags = $MergedTags | Sort-Object -Unique
            } else {
                $MergedTags = $Tags
            }
            $FinalTags = $MergedTags -join ", "
            & $ExifToolPath -XMP:Subject="$FinalTags" -overwrite_original "$ImagePath"
        } -ArgumentList $ExifToolPath, $ImagePath, $Tags
    }

    Write-Host "[INFO] Object detection and tagging completed."
}


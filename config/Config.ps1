# Define paths
$SourceFolder = "G:\My Drive\Amazon Photos Downloads\Cam"
$ProxyFolder = "G:\My Drive\Proxies"
$PythonScript = ".\detect_objects.py"
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Ensure dependencies
$ImageMagickPath = Get-Command magick | Select-Object -ExpandProperty Source
$ExifToolPath = Get-Command exiftool | Select-Object -ExpandProperty Source
$PythonPath = Get-Command python | Select-Object -ExpandProperty Source

if (!(Test-Path $ImageMagickPath)) { Write-Host "[ERROR] ImageMagick not found." -ForegroundColor Red; exit }
if (!(Test-Path $ExifToolPath)) { Write-Host "[ERROR] ExifTool not found." -ForegroundColor Red; exit }
if (!(Test-Path $PythonPath)) { Write-Host "[ERROR] Python not found." -ForegroundColor Red; exit }

# Set max parallel jobs
$MaxConcurrentJobs = 10

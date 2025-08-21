$ErrorActionPreference = "Stop"

$zipUrl = "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.4.0-windows-x64.zip"
$zipFile = "libwebp.zip"
$extractPath = ".\libwebp"

try {
    if (-not (Test-Path -LiteralPath $zipFile)) {
        Write-Host "Downloading WebP utilities..."
        Invoke-WebRequest $zipUrl -OutFile $zipFile
    } else {
        Write-Host "Found existing $zipFile, skipping download."
    }

    if (-not (Test-Path -LiteralPath $extractPath)) {
        Write-Host "Extracting..."
        Expand-Archive $zipFile -DestinationPath $extractPath -Force
    } else {
        Write-Host "Found existing extraction at $extractPath, skipping extract."
    }
}
catch {
    Write-Error "Failed to download or extract WebP utilities: $_"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

$cwebp = $null
try {
    $cwebp = Get-ChildItem -Path $extractPath -Recurse -Filter "cwebp.exe" |
             Select-Object -First 1 -ExpandProperty FullName
}
catch { }

if (-not $cwebp) {
    Write-Error "cwebp.exe not found. Something went wrong with extraction."
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "Using cwebp at: $cwebp"

$pngs = Get-ChildItem -Filter *.png -File | Sort-Object Name
if ($pngs.Count -eq 0) {
    Write-Host "No PNG files found in the current directory."
} else {
    Write-Host "Converting all PNG files to lossless WebP..."
    foreach ($png in $pngs) {
        $output = "$($png.BaseName).webp"
        & $cwebp -lossless $png.FullName -o $output
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Converted $($png.Name) -> $(Split-Path $output -Leaf)"
        } else {
            Write-Host "❌ Failed to convert: $($png.Name)"
        }
    }
    Write-Host "✅ Conversion step complete."
}

$missing = @()
Get-ChildItem -Filter *.png -File | ForEach-Object {
    $webp = "$($_.BaseName).webp"
    if (-not (Test-Path -LiteralPath $webp)) {
        $missing += $_.Name
    }
}
Write-Host "==============================="
if ($missing.Count -eq 0) {
    Write-Host "✅ All PNG files have matching WebP versions."
} else {
    Write-Host "⚠️ Missing WebP files for these PNGs ($($missing.Count)):"
    $missing | ForEach-Object { Write-Host " - $_" }
}

Write-Host ""
Read-Host "Press Enter to exit"

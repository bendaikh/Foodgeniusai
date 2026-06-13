# Regenerates all favicon assets in web/ from web/favicon-source.png
# Run: powershell -ExecutionPolicy Bypass -File tools\generate_favicons.ps1
param(
    [string]$Source = "tools\favicon-source\favicon-source.png"
)

Add-Type -AssemblyName System.Drawing

if (-not (Test-Path $Source)) {
    Write-Error "Source image not found: $Source"
    exit 1
}

$srcFull = (Resolve-Path $Source).Path
Write-Host "Loading source: $srcFull"
$srcImg = [System.Drawing.Image]::FromFile($srcFull)

function Resize-Png {
    param([System.Drawing.Image]$Img, [int]$Size, [string]$OutPath)
    $bmp = New-Object System.Drawing.Bitmap $Size, $Size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality= [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($Img, 0, 0, $Size, $Size)
    $g.Dispose()
    $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "  wrote $OutPath ($Size x $Size)"
}

# PNG outputs (sizes commonly required)
$outputs = @(
    @{ Size = 16;  Path = "web\favicon-16.png" },
    @{ Size = 32;  Path = "web\favicon-32.png" },
    @{ Size = 48;  Path = "web\favicon-48.png" },
    @{ Size = 180; Path = "web\apple-touch-icon.png" },
    @{ Size = 192; Path = "web\icons\Icon-192.png" },
    @{ Size = 192; Path = "web\icons\Icon-maskable-192.png" },
    @{ Size = 512; Path = "web\icons\Icon-512.png" },
    @{ Size = 512; Path = "web\icons\Icon-maskable-512.png" },
    @{ Size = 512; Path = "web\favicon.png" }
)
foreach ($o in $outputs) {
    Resize-Png -Img $srcImg -Size $o.Size -OutPath $o.Path
}

# Build a multi-size ICO file (16, 32, 48) from PNG bytes
function Write-Ico {
    param([string[]]$PngPaths, [string]$IcoPath)
    $entries = @()
    foreach ($p in $PngPaths) {
        $bytes = [System.IO.File]::ReadAllBytes($p)
        $bmp = [System.Drawing.Image]::FromFile((Resolve-Path $p).Path)
        $w = $bmp.Width;  $h = $bmp.Height
        $bmp.Dispose()
        $entries += [PSCustomObject]@{
            Width  = $w
            Height = $h
            Bytes  = $bytes
        }
    }

    $count = $entries.Count
    $headerSize = 6
    $dirSize    = 16 * $count
    $offset     = $headerSize + $dirSize

    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)

    # ICONDIR
    $bw.Write([uint16]0)        # reserved
    $bw.Write([uint16]1)        # type = ICO
    $bw.Write([uint16]$count)   # number of images

    foreach ($e in $entries) {
        # ICONDIRENTRY
        $w8 = if ($e.Width  -ge 256) { 0 } else { [byte]$e.Width }
        $h8 = if ($e.Height -ge 256) { 0 } else { [byte]$e.Height }
        $bw.Write([byte]$w8)            # width
        $bw.Write([byte]$h8)            # height
        $bw.Write([byte]0)              # color count
        $bw.Write([byte]0)              # reserved
        $bw.Write([uint16]1)            # color planes
        $bw.Write([uint16]32)           # bits per pixel
        $bw.Write([uint32]$e.Bytes.Length) # size in bytes
        $bw.Write([uint32]$offset)      # offset
        $offset += $e.Bytes.Length
    }
    foreach ($e in $entries) {
        $bw.Write($e.Bytes)
    }

    [System.IO.File]::WriteAllBytes($IcoPath, $ms.ToArray())
    $bw.Dispose(); $ms.Dispose()
    Write-Host "  wrote $IcoPath (multi-size ICO with $count images)"
}

Write-Ico -PngPaths @("web\favicon-16.png","web\favicon-32.png","web\favicon-48.png") -IcoPath "web\favicon.ico"

$srcImg.Dispose()
Write-Host "Done."

Add-Type -AssemblyName System.Drawing

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = (Get-Item "$scriptDir\..").FullName
$sourceIcon = "$rootDir\frontend\assets\branding\ForgeDesk.png"

if (-not (Test-Path $sourceIcon)) {
    $desktopIcon = "C:\Users\ibrahxbt\Desktop\ForgeDesk.png"
    if (Test-Path $desktopIcon) {
        Copy-Item $desktopIcon $sourceIcon -Force
    } else {
        Write-Error "Source icon not found at $sourceIcon or $desktopIcon"
        exit 1
    }
}

Write-Host "Source image: $sourceIcon"
$srcBmp = [System.Drawing.Bitmap]::FromFile($sourceIcon)

function Resize-Bitmap {
    param(
        [System.Drawing.Bitmap]$source,
        [int]$width,
        [int]$height
    )
    $destRect = New-Object System.Drawing.Rectangle(0, 0, $width, $height)
    $destBmp = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $destBmp.SetResolution($source.HorizontalResolution, $source.VerticalResolution)

    $g = [System.Drawing.Graphics]::FromImage($destBmp)
    $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $wrapMode = New-Object System.Drawing.Imaging.ImageAttributes
    $wrapMode.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
    $g.DrawImage($source, $destRect, 0, 0, $source.Width, $source.Height, [System.Drawing.GraphicsUnit]::Pixel, $wrapMode)
    $g.Dispose()
    $wrapMode.Dispose()

    return $destBmp
}

function Save-Png {
    param(
        [System.Drawing.Bitmap]$source,
        [int]$width,
        [int]$height,
        [string]$outputPath
    )
    $dir = Split-Path -Parent $outputPath
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $resized = Resize-Bitmap $source $width $height
    $resized.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $resized.Dispose()
    Write-Host "  -> Generated: $outputPath ($width x $height)"
}

function Generate-Ico {
    param(
        [System.Drawing.Bitmap]$source,
        [int[]]$sizes,
        [string]$icoPath
    )
    $dir = Split-Path -Parent $icoPath
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $pngList = @()
    foreach ($sz in $sizes) {
        $bmp = Resize-Bitmap $source $sz $sz
        $ms = New-Object System.IO.MemoryStream
        $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
        $pngList += ,@($sz, $ms.ToArray())
        $ms.Dispose()
    }

    $count = $pngList.Count
    $headerSize = 6 + (16 * $count)
    $currentOffset = $headerSize

    $fs = New-Object System.IO.FileStream($icoPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
    $bw = New-Object System.IO.BinaryWriter($fs)

    # ICONDIR
    $bw.Write([uint16]0) # Reserved
    $bw.Write([uint16]1) # Type 1 = ICO
    $bw.Write([uint16]$count)

    # Entries
    foreach ($entry in $pngList) {
        $sz = $entry[0]
        $bytes = $entry[1]
        $bWidth = if ($sz -ge 256) { [byte]0 } else { [byte]$sz }
        $bHeight = if ($sz -ge 256) { [byte]0 } else { [byte]$sz }

        $bw.Write($bWidth)
        $bw.Write($bHeight)
        $bw.Write([byte]0)   # Colors
        $bw.Write([byte]0)   # Reserved
        $bw.Write([uint16]1) # Color planes
        $bw.Write([uint16]32) # Bits per pixel
        $bw.Write([uint32]$bytes.Length) # Image size
        $bw.Write([uint32]$currentOffset) # Offset

        $currentOffset += $bytes.Length
    }

    # Image byte streams
    foreach ($entry in $pngList) {
        $bytes = $entry[1]
        $bw.Write($bytes)
    }

    $bw.Flush()
    $bw.Close()
    $fs.Close()
    Write-Host "  -> Generated ICO: $icoPath with sizes: $($sizes -join ', ')"
}

Write-Host "1. Generating Android icons..."
Save-Png $srcBmp 48 48 "$rootDir\frontend\android\app\src\main\res\mipmap-mdpi\ic_launcher.png"
Save-Png $srcBmp 72 72 "$rootDir\frontend\android\app\src\main\res\mipmap-hdpi\ic_launcher.png"
Save-Png $srcBmp 96 96 "$rootDir\frontend\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png"
Save-Png $srcBmp 144 144 "$rootDir\frontend\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png"
Save-Png $srcBmp 192 192 "$rootDir\frontend\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"

Write-Host "2. Generating iOS icons..."
$iosPath = "$rootDir\frontend\ios\Runner\Assets.xcassets\AppIcon.appiconset"
Save-Png $srcBmp 20 20 "$iosPath\Icon-App-20x20@1x.png"
Save-Png $srcBmp 40 40 "$iosPath\Icon-App-20x20@2x.png"
Save-Png $srcBmp 60 60 "$iosPath\Icon-App-20x20@3x.png"
Save-Png $srcBmp 29 29 "$iosPath\Icon-App-29x29@1x.png"
Save-Png $srcBmp 58 58 "$iosPath\Icon-App-29x29@2x.png"
Save-Png $srcBmp 87 87 "$iosPath\Icon-App-29x29@3x.png"
Save-Png $srcBmp 40 40 "$iosPath\Icon-App-40x40@1x.png"
Save-Png $srcBmp 80 80 "$iosPath\Icon-App-40x40@2x.png"
Save-Png $srcBmp 120 120 "$iosPath\Icon-App-40x40@3x.png"
Save-Png $srcBmp 120 120 "$iosPath\Icon-App-60x60@2x.png"
Save-Png $srcBmp 180 180 "$iosPath\Icon-App-60x60@3x.png"
Save-Png $srcBmp 76 76 "$iosPath\Icon-App-76x76@1x.png"
Save-Png $srcBmp 152 152 "$iosPath\Icon-App-76x76@2x.png"
Save-Png $srcBmp 167 167 "$iosPath\Icon-App-83.5x83.5@2x.png"
Save-Png $srcBmp 1024 1024 "$iosPath\Icon-App-1024x1024@1x.png"

Write-Host "3. Generating macOS icons..."
$macPath = "$rootDir\frontend\macos\Runner\Assets.xcassets\AppIcon.appiconset"
Save-Png $srcBmp 16 16 "$macPath\app_icon_16.png"
Save-Png $srcBmp 32 32 "$macPath\app_icon_32.png"
Save-Png $srcBmp 64 64 "$macPath\app_icon_64.png"
Save-Png $srcBmp 128 128 "$macPath\app_icon_128.png"
Save-Png $srcBmp 256 256 "$macPath\app_icon_256.png"
Save-Png $srcBmp 512 512 "$macPath\app_icon_512.png"
Save-Png $srcBmp 1024 1024 "$macPath\app_icon_1024.png"

Write-Host "4. Generating Web icons..."
Save-Png $srcBmp 32 32 "$rootDir\frontend\web\favicon.png"
Save-Png $srcBmp 192 192 "$rootDir\frontend\web\icons\Icon-192.png"
Save-Png $srcBmp 512 512 "$rootDir\frontend\web\icons\Icon-512.png"
Save-Png $srcBmp 192 192 "$rootDir\frontend\web\icons\Icon-maskable-192.png"
Save-Png $srcBmp 512 512 "$rootDir\frontend\web\icons\Icon-maskable-512.png"

Write-Host "5. Generating Windows ICO..."
$winIcoPath = "$rootDir\frontend\windows\runner\resources\app_icon.ico"
Generate-Ico $srcBmp @(16, 32, 48, 64, 128, 256) $winIcoPath

Write-Host "6. Generating Linux icon..."
Save-Png $srcBmp 256 256 "$rootDir\frontend\linux\runner\forgedesk.png"

$srcBmp.Dispose()
Write-Host "App icon generation completed successfully for all platforms!"

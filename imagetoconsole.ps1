#imagetoconsole.ps1

param(
    $Path,
    [switch] $IsGrayscale
)

$CharHeightWidthRatio = 2.2

[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing') | Out-NUll

function Get-PixelConsoleColor ([System.Drawing.Color]$Color) {
    if ($Color.GetSaturation() -lt .2 -or $Color.GetBrightness() -gt .9 -or
        $Color.GetBrightness() -lt .1) {
        return [ConsoleColor]::White
    }
    switch ($Color.GetHue()) {
        { $_ -ge 330 -or $_ -lt 16 } { return [ConsoleColor]::Red }
        { $_ -ge 16 -and $_ -lt 90 } { return [ConsoleColor]::Yellow }
        { $_ -ge 90 -and $_ -lt 160 } { return [ConsoleColor]::Green }
        { $_ -ge 160 -and $_ -lt 210 } { return [ConsoleColor]::Cyan }
        { $_ -ge 210 -and $_ -lt 270 } { return [ConsoleColor]::Blue }
        { $_ -ge 270 -and $_ -lt 330 } { return [ConsoleColor]::Magenta }
    }
}

function Get-PixelChar ([Drawing.Color]$Color) {
    $chars = ' .,:;+iIH$@'
    $brightness = [math]::Floor($Color.GetBrightness() * $chars.Length)
    $chars[$brightness]
}

if (Test-Path $Path) {
    $Path = Get-Item $Path
    $bitmap = [Drawing.Bitmap]::FromFile($Path)
}
else {
    $response = Invoke-WebRequest $Path
    $bitmap = [Drawing.Bitmap]::FromStream($response.RawContentStream)
}

# Resize image to match pixels to characters on the console.
$x = $Host.UI.RawUI.BufferSize.Width - 1 # If 1 is not subtracted, lines will wrap
$scale = $x / $bitmap.Size.Width
# Divide scaled height by 2.2 to compensate for characters being taller than
# they are wide.
[int]$y = $bitmap.Size.Height * $scale / $CharHeightWidthRatio
$bitmap = New-Object System.Drawing.Bitmap @($bitmap, [Drawing.Size]"$x,$y")

for ($y = 0; $y -lt $bitmap.Size.Height; $y++) {
    for ($x = 0; $x -lt $bitmap.Size.Width; $x++) {
        $pixel = $bitmap.GetPixel($x, $y)
        if ($IsGrayscale) { $color = [ConsoleColor]::White }
        else { $color = Get-PixelConsoleColor $pixel }
        $character = Get-PixelChar $pixel
        Write-Host $character -ForegroundColor $color -NoNewline
    }
    Write-Host
}

<#
.Synopsis
   Writes an image to the console as colored text.
.DESCRIPTION
   Loads an image from a file path or web URL and prints it out as text. 
   Using the -IsGrayscale switch will print only white characters.
.EXAMPLE
   ImageToConsole.ps1 'http://server/path/test.jpg'
.EXAMPLE
   ImageToConsole.ps1 'C:\temp\test.gif' -IsGrayscale
#>

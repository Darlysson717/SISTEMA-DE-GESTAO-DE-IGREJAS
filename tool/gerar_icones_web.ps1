# Gera os ícones do PWA (web/icons + favicon) a partir do logo do projeto.
#
# Uso (na raiz do repositório):
#   powershell -ExecutionPolicy Bypass -File tool\gerar_icones_web.ps1
#
# Usa System.Drawing (nativo do Windows) — não requer ImageMagick.
# Os maskable usam zona segura de 80% sobre fundo sólido, conforme a spec
# de ícones maskable do W3C.

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$repo = Split-Path -Parent $PSScriptRoot
$srcPath = Join-Path $repo "Imagens\LOGO DEPARTAMENTO.png"
if (-not (Test-Path $srcPath)) {
    throw "Logo nao encontrado em $srcPath"
}

function New-Icon([string]$outPath, [int]$size, [string]$bgHex, [double]$contentRatio) {
    $src = [System.Drawing.Image]::FromFile($srcPath)
    try {
        $bmp = New-Object System.Drawing.Bitmap($size, $size)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        if ($bgHex) {
            $g.Clear([System.Drawing.ColorTranslator]::FromHtml($bgHex))
        } else {
            $g.Clear([System.Drawing.Color]::Transparent)
        }
        $content = [int]($size * $contentRatio)
        $offset = [int](($size - $content) / 2)
        $g.DrawImage($src, $offset, $offset, $content, $content)
        $g.Dispose()
        $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
        Write-Host "Gerado: $outPath"
    } finally {
        $src.Dispose()
    }
}

# Ícones normais: logo ocupa o quadro todo, fundo transparente
New-Icon (Join-Path $repo "web\icons\Icon-192.png") 192 $null 1.0
New-Icon (Join-Path $repo "web\icons\Icon-512.png") 512 $null 1.0
# Maskable: zona segura de 80% => logo em 80% do quadro, fundo claro do app
New-Icon (Join-Path $repo "web\icons\Icon-maskable-192.png") 192 "#F8FAFC" 0.8
New-Icon (Join-Path $repo "web\icons\Icon-maskable-512.png") 512 "#F8FAFC" 0.8
# Favicon
New-Icon (Join-Path $repo "web\favicon.png") 48 $null 1.0

Write-Host "Concluido."

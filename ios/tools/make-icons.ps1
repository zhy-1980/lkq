# 生成 iOS 应用图标：优先使用已有主图；否则先试 AI 生图，失败则程序化绘制克拉姆棋盘图标；最后裁切全部尺寸
param(
  [string]$SourcePath = ""
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$root   = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)   # 项目根 lkq/
$appset = Join-Path $root "ios\Carrom\Assets.xcassets\AppIcon.appiconset"
$src    = Join-Path $appset "icon_1024.png"

function Test-RealImage([string]$path) {
  # 占位图整体极亮（平均亮度 > 190 视为占位图）
  try {
    $img = [System.Drawing.Bitmap]::FromFile($path)
    $r = 0; $g = 0; $b = 0; $n = 0
    for ($x = 400; $x -lt 600; $x += 10) {
      for ($y = 400; $y -lt 600; $y += 10) {
        $c = $img.GetPixel($x, $y); $r += $c.R; $g += $c.G; $b += $c.B; $n++
      }
    }
    $img.Dispose()
    return ((($r + $g + $b) / (3 * $n)) -lt 190)
  } catch { return $false }
}

function Draw-CarromIcon([string]$outPath) {
  $s = 1024
  $bmp = New-Object System.Drawing.Bitmap($s, $s)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

  function RoundPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = 2 * $r
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
  }
  function DrawCoin([float]$cx, [float]$cy, [float]$rad, [string]$kind) {
    if ($kind -eq 'W') { $body = [System.Drawing.Color]::FromArgb(255, 243, 232, 205); $rim = [System.Drawing.Color]::FromArgb(255, 150, 130, 95) }
    elseif ($kind -eq 'B') { $body = [System.Drawing.Color]::FromArgb(255, 42, 33, 24); $rim = [System.Drawing.Color]::FromArgb(255, 12, 9, 6) }
    else { $body = [System.Drawing.Color]::FromArgb(255, 198, 55, 42); $rim = [System.Drawing.Color]::FromArgb(255, 120, 24, 16) }
    # 投影
    $sh = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(70, 0, 0, 0))
    $g.FillEllipse($sh, $cx - $rad + 4, $cy - $rad + 7, 2 * $rad, 2 * $rad)
    # 本体
    $br = New-Object System.Drawing.SolidBrush($body)
    $g.FillEllipse($br, $cx - $rad, $cy - $rad, 2 * $rad, 2 * $rad)
    # 描边
    $penW = [Math]::Max(4, $rad * 0.16)
    $pn = New-Object System.Drawing.Pen($rim, $penW)
    $g.DrawEllipse($pn, $cx - $rad + $penW / 2, $cy - $rad + $penW / 2, 2 * $rad - $penW, 2 * $rad - $penW)
    # 高光
    $hl = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(90, 255, 255, 255))
    $g.FillEllipse($hl, $cx - $rad * 0.45, $cy - $rad * 0.55, $rad * 0.55, $rad * 0.4)
    $sh.Dispose(); $br.Dispose(); $pn.Dispose(); $hl.Dispose()
  }

  # 1) 背景：深蓝夜色渐变
  $bgRect = New-Object System.Drawing.Rectangle(0, 0, $s, $s)
  $bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush($bgRect,
    [System.Drawing.Color]::FromArgb(255, 44, 54, 76),
    [System.Drawing.Color]::FromArgb(255, 13, 16, 24), 90.0)
  $g.FillRectangle($bg, 0, 0, $s, $s)
  $bg.Dispose()

  # 2) 外框木盘
  $bx = 102; $bs = 820; $brd = 96
  $frame = RoundPath $bx $bx $bs $bs $brd
  $fRect = New-Object System.Drawing.Rectangle($bx, $bx, $bs, $bs)
  $wood = New-Object System.Drawing.Drawing2D.LinearGradientBrush($fRect,
    [System.Drawing.Color]::FromArgb(255, 198, 138, 69),
    [System.Drawing.Color]::FromArgb(255, 148, 96, 40), 45.0)
  $g.FillPath($wood, $frame)
  $wood.Dispose()
  # 木框边缘暗线
  $edge = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(160, 74, 46, 18), 10)
  $g.DrawPath($edge, $frame)
  $edge.Dispose()

  # 3) 内部浅色台面
  $in = 92; $is = $bs - 2 * $in; $ir = 52
  $field = RoundPath ($bx + $in) ($bx + $in) $is $is $ir
  $fRect2 = New-Object System.Drawing.Rectangle(($bx + $in), ($bx + $in), $is, $is)
  $felt = New-Object System.Drawing.Drawing2D.LinearGradientBrush($fRect2,
    [System.Drawing.Color]::FromArgb(255, 226, 180, 118),
    [System.Drawing.Color]::FromArgb(255, 199, 148, 84), 45.0)
  $g.FillPath($felt, $field)
  $felt.Dispose()
  $fieldEdge = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(120, 110, 70, 28), 5)
  $g.DrawPath($fieldEdge, $field)
  $fieldEdge.Dispose()

  # 4) 底线（上/下两条琥珀色横线）
  $bl = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(150, 176, 116, 44), 8)
  $cx0 = $bx + $in + 60; $cx1 = $bx + $in + $is - 60
  $ys = @(($bx + $in + 128), ($bx + $in + $is - 128))
  foreach ($yy in $ys) {
    $g.DrawLine($bl, $cx0, $yy, $cx1, $yy)
  }
  $bl.Dispose()

  # 5) 中央装饰环
  $ccx = 512; $ccy = 512
  $ring = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(170, 240, 192, 112), 12)
  $g.DrawEllipse($ring, $ccx - 208, $ccy - 208, 416, 416)
  $ring.Dispose()
  $ring2 = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(110, 240, 192, 112), 7)
  $g.DrawEllipse($ring2, $ccx - 92, $ccy - 92, 184, 184)
  $ring2.Dispose()

  # 6) 四角袋口
  $off = 96
  $o1 = $bx + $in + $off
  $o2 = $bx + $in + $is - $off
  $pts = @(
    @{ x = $o1; y = $o1 },
    @{ x = $o2; y = $o1 },
    @{ x = $o1; y = $o2 },
    @{ x = $o2; y = $o2 }
  )
  foreach ($pt in $pts) {
    $pb = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 22, 15, 8))
    $g.FillEllipse($pb, $pt.x - 74, $pt.y - 74, 148, 148)
    $pb.Dispose()
    $pp = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 250, 210, 140), 8)
    $g.DrawEllipse($pp, $pt.x - 74, $pt.y - 74, 148, 148)
    $pp.Dispose()
  }

  # 7) 棋子：中央红后 + 环绕三白三黑
  DrawCoin $ccx $ccy 58 'Q'
  $ringR = 150
  for ($i = 0; $i -lt 6; $i++) {
    $ang = [Math]::PI / 6 + $i * [Math]::PI / 3
    $px = $ccx + $ringR * [Math]::Cos($ang)
    $py = $ccy + $ringR * [Math]::Sin($ang)
    $kind = if ($i % 2 -eq 0) { 'W' } else { 'B' }
    DrawCoin $px $py 52 $kind
  }

  $g.Dispose()
  $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

if ($SourcePath) {
  Copy-Item $SourcePath $src -Force
} elseif (-not (Test-Path $src) -or -not (Test-RealImage $src)) {
  # 先尝试 AI 生图一次
  try {
    $prompt = [uri]::EscapeDataString("flat iOS app icon, top view carrom board game, warm wooden square board, four corner pockets, white and black discs with one red queen, amber and dark navy palette, minimal, no text")
    $url = "https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image?prompt=$prompt&image_size=square_hd"
    Invoke-WebRequest -Uri $url -OutFile $src -UseBasicParsing -TimeoutSec 60
  } catch { Write-Host "AI 生图失败：$($_.Exception.Message)" }
  if (-not (Test-RealImage $src)) {
    Write-Host "AI 生图不可用，改用程序化绘制图标 ..."
    Draw-CarromIcon $src
  }
}

# 裁切全部 iOS 尺寸
$sizes = 20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180
$srcImg = [System.Drawing.Image]::FromFile($src)
foreach ($sz in $sizes) {
  $bmp = New-Object System.Drawing.Bitmap($sz, $sz)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.DrawImage($srcImg, 0, 0, $sz, $sz)
  $g.Dispose()
  $bmp.Save((Join-Path $appset "icon_$sz.png"), [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}
$srcImg.Dispose()
Write-Host "DONE: $appset"

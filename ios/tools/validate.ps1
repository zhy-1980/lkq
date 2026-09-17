$ErrorActionPreference = 'Stop'
$root = "c:\Users\36065\Desktop\lkq"

# 1) XML 合法性：Info.plist / LaunchScreen.storyboard
foreach ($f in @("ios\Carrom\Info.plist", "ios\Carrom\LaunchScreen.storyboard")) {
  try {
    $xml = New-Object System.Xml.XmlDocument
    $xml.Load((Join-Path $root $f))
    Write-Host "XML OK: $f"
  } catch { Write-Host "XML FAIL: $f => $($_.Exception.Message)" }
}

# 2) JSON 合法性：两个 Contents.json
foreach ($f in @("ios\Carrom\Assets.xcassets\Contents.json", "ios\Carrom\Assets.xcassets\AppIcon.appiconset\Contents.json")) {
  try {
    Get-Content (Join-Path $root $f) -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null
    Write-Host "JSON OK: $f"
  } catch { Write-Host "JSON FAIL: $f => $($_.Exception.Message)" }
}

# 3) pbxproj 花括号/圆括号平衡 + 引用的对象 ID 都有定义
$pbx = Get-Content (Join-Path $root "ios\Carrom.xcodeproj\project.pbxproj") -Raw -Encoding UTF8
$openB = ([regex]::Matches($pbx, '\{')).Count; $closeB = ([regex]::Matches($pbx, '\}')).Count
$openP = ([regex]::Matches($pbx, '\(')).Count; $closeP = ([regex]::Matches($pbx, '\)')).Count
Write-Host "pbxproj braces: $openB/$closeB parens: $openP/$closeP"
$ids = [regex]::Matches($pbx, '(?m)^\t\t([0-9A-F]{24})\s') | ForEach-Object { $_.Groups[1].Value }
$refs = [regex]::Matches($pbx, '([0-9A-F]{24})\s*/\*') | ForEach-Object { $_.Groups[1].Value }
$missing = $refs | Where-Object { $ids -notcontains $_ } | Sort-Object -Unique
if ($missing) { Write-Host ("MISSING IDs: " + ($missing -join ', ')) } else { Write-Host "pbxproj IDs: all refs defined" }
Write-Host ("defined objects: " + ($ids | Sort-Object -Unique).Count)

# 4) 图标 PNG 实际尺寸抽查
Add-Type -AssemblyName System.Drawing
foreach ($s in @(1024, 180, 167, 76)) {
  $img = [System.Drawing.Image]::FromFile((Join-Path $root "ios\Carrom\Assets.xcassets\AppIcon.appiconset\icon_$s.png"))
  Write-Host "icon_$s.png => $($img.Width)x$($img.Height)"
  $img.Dispose()
}

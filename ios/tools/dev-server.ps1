$ErrorActionPreference = 'Stop'
$root = "c:\Users\36065\Desktop\lkq"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8765/")
$listener.Start()
Write-Host "Serving $root at http://localhost:8765/"
while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  try {
    $path = [uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
    if ($path -eq "/") {
      $file = (Get-ChildItem $root -Filter *.html | Select-Object -First 1).FullName
    } else {
      $file = Join-Path $root $path.TrimStart("/")
    }
    if ((Test-Path $file -PathType Leaf) -and ((Resolve-Path $file).Path.StartsWith($root, [StringComparison]::OrdinalIgnoreCase))) {
      $bytes = [System.IO.File]::ReadAllBytes($file)
      $ext = [System.IO.Path]::GetExtension($file).ToLower()
      if ($ext -eq ".html") { $ctx.Response.ContentType = "text/html; charset=utf-8" }
      elseif ($ext -eq ".png") { $ctx.Response.ContentType = "image/png" }
      else { $ctx.Response.ContentType = "application/octet-stream" }
      $ctx.Response.ContentLength64 = $bytes.Length
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $ctx.Response.StatusCode = 404
    }
  } catch {
    try { $ctx.Response.StatusCode = 500 } catch {}
  }
  try { $ctx.Response.OutputStream.Close() } catch {}
}

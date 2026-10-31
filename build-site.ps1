# Builds the GitHub Pages files (index.html, manifest, sw.js, icons) at the repo root from feuille-de-score.html
# Usage: powershell -NoProfile -File build-site.ps1
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$out = $root
New-Item -ItemType Directory -Force $out | Out-Null
$utf8 = New-Object Text.UTF8Encoding $false

# --- index.html: the artifact page wrapped in a full document, plus PWA tags and the service worker ---
$src = [IO.File]::ReadAllText((Join-Path $root "feuille-de-score.html"), [Text.Encoding]::UTF8)
$cut = $src.IndexOf("</style>") + "</style>".Length
$head = $src.Substring(0, $cut) -replace '<meta name="claude:viewport-fit-sides"[^>]*>\r?\n', ''
$body = $src.Substring($cut)
$version = Get-Date -Format "yyyyMMdd-HHmmss"

$pwa = @"
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<link rel="manifest" href="manifest.webmanifest">
<link rel="icon" type="image/png" sizes="192x192" href="icon-192.png">
<link rel="apple-touch-icon" href="apple-touch-icon.png">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-title" content="Scores">
<meta name="apple-mobile-web-app-status-bar-style" content="default">
"@

$sw = @"
<script>
if ("serviceWorker" in navigator) navigator.serviceWorker.register("sw.js").catch(() => {});
</script>
"@

$html = "<!doctype html>`n<html lang=`"fr`">`n<head>`n$pwa`n$head`n</head>`n<body>`n$body`n$sw</body>`n</html>`n"
[IO.File]::WriteAllText((Join-Path $out "index.html"), $html, $utf8)

# --- manifest ---
$manifest = @"
{
  "name": "Feuille de score",
  "short_name": "Scores",
  "description": "Compter les points de vos jeux de societe",
  "lang": "fr",
  "start_url": "./",
  "scope": "./",
  "display": "standalone",
  "background_color": "#F2F4F0",
  "theme_color": "#1E6A4C",
  "icons": [
    { "src": "icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
"@
$manifest = $manifest.Replace("societe", "soci" + [char]0xE9 + "t" + [char]0xE9)
[IO.File]::WriteAllText((Join-Path $out "manifest.webmanifest"), $manifest, $utf8)

# --- service worker: the app works offline; a new version replaces the old cache ---
$swjs = @"
// Hors connexion : l'appli est gardee en cache, et mise a jour des qu'une nouvelle version est en ligne
const CACHE = "feuille-de-score-$version";
const FILES = ["./", "index.html", "manifest.webmanifest", "icon-192.png", "icon-512.png", "apple-touch-icon.png"];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(FILES)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(caches.keys()
    .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

self.addEventListener("fetch", e => {
  if (e.request.method !== "GET") return;
  const url = new URL(e.request.url);
  // La page : le reseau d'abord (pour avoir la derniere version), le cache si on est hors ligne
  if (e.request.mode === "navigate") {
    e.respondWith(fetch(e.request)
      .then(r => { const copy = r.clone(); caches.open(CACHE).then(c => c.put("./", copy)); return r; })
      .catch(() => caches.match("./")));
    return;
  }
  // Polices Google et fichiers de l'appli : le cache d'abord
  if (url.origin === location.origin || url.hostname.endsWith("fonts.googleapis.com") || url.hostname.endsWith("fonts.gstatic.com")) {
    e.respondWith(caches.match(e.request).then(hit => hit || fetch(e.request).then(r => {
      const copy = r.clone();
      caches.open(CACHE).then(c => c.put(e.request, copy));
      return r;
    })));
  }
});
"@
[IO.File]::WriteAllText((Join-Path $out "sw.js"), $swjs, $utf8)

# --- icons: green felt, white score card, gold star ---
Add-Type -AssemblyName System.Drawing
function New-Icon([int]$size, [string]$file, [double]$pad) {
  $bmp = New-Object Drawing.Bitmap $size, $size
  $g = [Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = "AntiAlias"
  $g.Clear([Drawing.ColorTranslator]::FromHtml("#1E6A4C"))
  $s = $size * (1 - 2 * $pad)
  $o = $size * $pad
  # card
  $cw = $s * 0.62; $ch = $s * 0.74
  $cx = $o + ($s - $cw) / 2; $cy = $o + ($s - $ch) / 2
  $r = $s * 0.07
  $path = New-Object Drawing.Drawing2D.GraphicsPath
  $path.AddArc($cx, $cy, 2*$r, 2*$r, 180, 90)
  $path.AddArc($cx + $cw - 2*$r, $cy, 2*$r, 2*$r, 270, 90)
  $path.AddArc($cx + $cw - 2*$r, $cy + $ch - 2*$r, 2*$r, 2*$r, 0, 90)
  $path.AddArc($cx, $cy + $ch - 2*$r, 2*$r, 2*$r, 90, 90)
  $path.CloseFigure()
  $g.FillPath([Drawing.Brushes]::White, $path)
  # score lines
  $pen = New-Object Drawing.Pen ([Drawing.ColorTranslator]::FromHtml("#D9E1DB")), ($s * 0.035)
  $pen.StartCap = "Round"; $pen.EndCap = "Round"
  foreach ($k in 0..2) {
    $y = $cy + $ch * (0.52 + 0.15 * $k)
    $g.DrawLine($pen, $cx + $cw * 0.18, $y, $cx + $cw * 0.82, $y)
  }
  # star
  $gold = New-Object Drawing.SolidBrush ([Drawing.ColorTranslator]::FromHtml("#B97D0C"))
  $scx = $cx + $cw / 2; $scy = $cy + $ch * 0.27; $R = $s * 0.13; $ri = $R * 0.45
  $pts = New-Object 'Drawing.PointF[]' 10
  for ($i = 0; $i -lt 10; $i++) {
    $rad = if ($i % 2 -eq 0) { $R } else { $ri }
    $a = -[Math]::PI / 2 + $i * [Math]::PI / 5
    $pts[$i] = New-Object Drawing.PointF ([float]($scx + $rad * [Math]::Cos($a))), ([float]($scy + $rad * [Math]::Sin($a)))
  }
  $g.FillPolygon($gold, $pts)
  $g.Dispose()
  $bmp.Save((Join-Path $out $file), [Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}
New-Icon 180 "apple-touch-icon.png" 0.06
New-Icon 192 "icon-192.png" 0.06
New-Icon 512 "icon-512.png" 0.12

Write-Output "Site built in $out (cache $version)"

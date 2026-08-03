# 过滤 Dart debugPrint 白名单 tag（需 adb 在 PATH，设备已连接）
# 增删 tag：修改下方 $Tags 数组
$Tags = @('[ApiHttp]', '[UcgFeed]', '[UcgLocation]', '[UcgVideo]', '[UcgCompose]', '[UcgPlay]', '[UcgUnread]', '[UcgPush]', '[UcgShare]', '[PangbaoClinic]', '[WsTransport]', '[HomeWidget]')

$ErrorActionPreference = 'Stop'
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
  Write-Error 'adb not found. Install Android platform-tools and add to PATH.'
}

try { chcp 65001 | Out-Null } catch {}
$utf8 = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $utf8
[Console]::InputEncoding = $utf8
$OutputEncoding = $utf8

$pattern = ($Tags | ForEach-Object { [regex]::Escape($_) }) -join '|'
Write-Host "Watching flutter logcat for: $($Tags -join ', ') ... (Ctrl+C to stop)" -ForegroundColor Cyan

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = 'adb'
$psi.Arguments = 'logcat -s flutter'
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.StandardOutputEncoding = $utf8
$psi.CreateNoWindow = $true

$proc = [System.Diagnostics.Process]::Start($psi)
try {
  while ($null -ne ($line = $proc.StandardOutput.ReadLine())) {
    if ($line -match $pattern) {
      Write-Output $line
    }
  }
} finally {
  if (-not $proc.HasExited) {
    $proc.Kill()
  }
  $proc.Dispose()
}

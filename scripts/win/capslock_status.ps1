Add-Type -AssemblyName System.Windows.Forms
Start-Sleep -Milliseconds 80  # caps키가 토글될 시간 살짝 대기

$isOn = [System.Windows.Forms.Control]::IsKeyLocked('CapsLock')
$exe = "C:\kanata\osd_nav.exe"
$title = "OSD_CAPS"

# 이미 떠있는 OSD_CAPS 프로세스 찾기
$existing = Get-Process | Where-Object { $_.MainWindowTitle -eq $title }

if ($isOn) {
  # 켜졌으면 -> 없으면 띄우기
  if (-not $existing) {
    & $exe CAPS
  }
} else {
  # 꺼졌으면 -> 떠있으면 죽이기
  if ($existing) {
    $existing | Stop-Process -Force
  }
}
# Jarvis uchun Windows tayyorlash: WSL2 Ubuntu + systemd + avto-yonish + uyqusiz rejim.
# Administrator PowerShell'da:
#   Set-ExecutionPolicy -Scope Process Bypass -Force; .\ornatish.ps1
# 1-marta: WSL o'rnatiladi -> kompyuter qayta yoqiladi -> Ubuntu foydalanuvchi/parol so'raydi.
# Keyin skriptni QAYTA ishga tushiring: qolgan sozlamalar qilinadi.
# Qayta ishga tushirish xavfsiz.
param([string]$Distro = "Ubuntu-24.04")

$ErrorActionPreference = "Stop"
function OK($m)   { Write-Host "OK   $m" -ForegroundColor Green }
function OGOH($m) { Write-Host "DIQQAT $m" -ForegroundColor Yellow }

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { Write-Host "XATO PowerShell'ni 'Run as administrator' bilan oching." -ForegroundColor Red; exit 1 }

# ---------------------------------------------------------------- 1) WSL + Ubuntu
$bor = $false
try { $bor = ((wsl.exe -l -q 2>$null) -replace "`0", "") -match [regex]::Escape($Distro) } catch {}
if (-not $bor) {
  Write-Host "WSL va $Distro o'rnatilmoqda (5-15 daqiqa)..."
  wsl.exe --install -d $Distro
  Write-Host ""
  Write-Host "KEYINGI QADAM: kompyuterni qayta yoqing. Ubuntu oynasi ochilsa foydalanuvchi nomi va parol bering"
  Write-Host "(parolni yozib qo'ying). Keyin shu skriptni yana bir marta ishga tushiring." -ForegroundColor Cyan
  exit 0
}
wsl.exe --set-default $Distro | Out-Null
OK "WSL: $Distro"

# ---------------------------------------------------------------- 2) systemd + WSL o'chib qolmasin
wsl.exe -d $Distro -u root -- sh -c "grep -q '^systemd=true' /etc/wsl.conf 2>/dev/null || printf '[boot]\nsystemd=true\n' >> /etc/wsl.conf"
$cfg = Join-Path $env:USERPROFILE ".wslconfig"
$matn = if (Test-Path $cfg) { Get-Content $cfg -Raw } else { "" }
if ($matn -notmatch "vmIdleTimeout") {
  if ($matn -notmatch "\[wsl2\]") { $matn += "`r`n[wsl2]`r`n" }
  $matn = $matn -replace "\[wsl2\]", "[wsl2]`r`nvmIdleTimeout=-1"
  Set-Content -Path $cfg -Value $matn -Encoding ASCII
}
OK "systemd yoqildi, WSL bo'sh turganda o'chmaydi"

# ---------------------------------------------------------------- 3) Windows'ga kirilganda WSL yonsin va yonib tursin
# WSL ichida jarayon ushlab turmasa, Ubuntu bir necha soniyada to'xtaydi. Bu vazifa uni ushlab turadi.
$exe  = "$env:WINDIR\System32\conhost.exe"
$argv = "--headless wsl.exe -d $Distro -u root --exec sleep infinity"
if (-not (Test-Path $exe)) { $exe = "wsl.exe"; $argv = "-d $Distro -u root --exec sleep infinity" }
$a = New-ScheduledTaskAction -Execute $exe -Argument $argv
$t = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$s = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
       -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) -StartWhenAvailable
$p = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName "Jarvis-WSL" -Action $a -Trigger $t -Settings $s -Principal $p -Force | Out-Null
wsl.exe --shutdown
Start-Sleep -Seconds 3
Start-ScheduledTask -TaskName "Jarvis-WSL"
Start-Sleep -Seconds 8
$sd = (wsl.exe -d $Distro -u root -- sh -c "ps -p 1 -o comm=" 2>$null) -replace "`0", ""
if ($sd -match "systemd") { OK "Jarvis-WSL vazifasi: Windows'ga kirilganda Ubuntu o'zi yonadi (systemd ishlayapti)" }
else { OGOH "systemd ko'rinmadi ($sd). 'wsl --shutdown' qilib skriptni qayta ishga tushiring." }

# ---------------------------------------------------------------- 4) Uxlamasin (tokka ulanganda), qopqoq yopilsa ham ishlasin
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
powercfg /setactive SCHEME_CURRENT
OK "Tokka ulanganda uyqu va gibernatsiya o'chdi, qopqoq yopilsa hech narsa bo'lmaydi"

Write-Host ""
Write-Host "Tayyor. Endi Ubuntu'ga kiring:  wsl -u root" -ForegroundColor Cyan
Write-Host "Keyin README'dagi 'Windows' bo'limi: Claude Code o'rnatish -> login -> 'do it'." -ForegroundColor Cyan
Write-Host "Eslatma: kompyuter qayta yonganda Jarvis faqat Windows'ga kirilgandan keyin ishga tushadi." -ForegroundColor Yellow

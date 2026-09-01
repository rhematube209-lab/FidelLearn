# =====================================================================
# 🎓 FidelLearn Windows Desktop 1-Click Installer & Launcher
# =====================================================================

$ErrorActionPreference = "Stop"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  🎓 FidelLearn - Desktop App Setup & Installation" -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ReleaseDir = Join-Path $ProjectRoot "build\windows\x64\runner\Release"
$DebugDir = Join-Path $ProjectRoot "build\windows\x64\runner\Debug"

$ExeSource = $null
if (Test-Path (Join-Path $ReleaseDir "fidel_learn.exe")) {
    $ExeSource = $ReleaseDir
} elseif (Test-Path (Join-Path $DebugDir "fidel_learn.exe")) {
    $ExeSource = $DebugDir
} else {
    Write-Host "`n[*] Building FidelLearn Windows Desktop binary..." -ForegroundColor Green
    & "C:\flutter\bin\flutter.bat" build windows --release
    if (Test-Path (Join-Path $ReleaseDir "fidel_learn.exe")) {
        $ExeSource = $ReleaseDir
    }
}

if ($ExeSource -and (Test-Path (Join-Path $ExeSource "fidel_learn.exe"))) {
    $InstallTarget = Join-Path $env:LOCALAPPDATA "Programs\FidelLearn"
    Write-Host "`n[*] Installing to: $InstallTarget" -ForegroundColor Green
    
    if (-not (Test-Path $InstallTarget)) {
        New-Item -ItemType Directory -Path $InstallTarget -Force | Out-Null
    }
    
    Copy-Item -Path "$ExeSource\*" -Destination $InstallTarget -Recurse -Force
    
    # Create Desktop Shortcut
    $WshShell = New-Object -ComObject WScript.Shell
    $DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
    $ShortcutPath = Join-Path $DesktopPath "FidelLearn.lnk"
    
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = (Join-Path $InstallTarget "fidel_learn.exe")
    $Shortcut.WorkingDirectory = $InstallTarget
    $Shortcut.Description = "FidelLearn - Offline-First National Exam Preparation"
    $Shortcut.Save()
    
    # Create Start Menu Shortcut
    $StartMenuPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Programs)
    $StartShortcut = $WshShell.CreateShortcut((Join-Path $StartMenuPath "FidelLearn.lnk"))
    $StartShortcut.TargetPath = (Join-Path $InstallTarget "fidel_learn.exe")
    $StartShortcut.WorkingDirectory = $InstallTarget
    $StartShortcut.Description = "FidelLearn - Offline-First National Exam Preparation"
    $StartShortcut.Save()
    
    Write-Host "`n[✓] FidelLearn successfully installed!" -ForegroundColor Green
    Write-Host "    - Shortcut placed on Desktop: FidelLearn.lnk" -ForegroundColor White
    Write-Host "    - Shortcut added to Start Menu: FidelLearn" -ForegroundColor White
    Write-Host "    - Executable location: $InstallTarget\fidel_learn.exe" -ForegroundColor White
    
    Write-Host "`nLaunching FidelLearn now..." -ForegroundColor Yellow
    Start-Process (Join-Path $InstallTarget "fidel_learn.exe")
} else {
    Write-Host "`n[!] Could not find compiled binary. You can launch FidelLearn in desktop mode via:" -ForegroundColor Yellow
    Write-Host "    flutter run -d windows" -ForegroundColor Cyan
}

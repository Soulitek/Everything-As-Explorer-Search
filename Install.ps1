#Requires -Version 5.1
<#
.SYNOPSIS
    Installs JumpToFolder Trigger script.
.DESCRIPTION
    Finds AutoHotkey v2 and JumpToFolder.exe, patches JumpToFolderTrigger.ahk
    with the correct path, optionally adds a Startup shortcut, and launches.
#>

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AhkScript = Join-Path $ScriptDir "JumpToFolderTrigger.ahk"

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   JumpToFolder Trigger - Installer"               -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------
# Step 1: Verify the .ahk script is present
# ------------------------------------------------------------------
if (-not (Test-Path $AhkScript)) {
    Write-Host "ERROR: JumpToFolderTrigger.ahk not found in:" -ForegroundColor Red
    Write-Host "  $ScriptDir" -ForegroundColor Red
    Write-Host ""
    Write-Host "Run this installer from the same folder as JumpToFolderTrigger.ahk." -ForegroundColor Yellow
    Write-Host ""; pause; exit 1
}

# ------------------------------------------------------------------
# Step 2: Find AutoHotkey v2
# ------------------------------------------------------------------
Write-Host "[1/3] Searching for AutoHotkey v2..." -NoNewline

$AhkExe = $null
$AhkCandidates = @(
    (Get-Command "AutoHotkey64.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
    (Get-Command "AutoHotkey.exe"   -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
    "${env:ProgramFiles}\AutoHotkey\v2\AutoHotkey64.exe",
    "${env:ProgramFiles}\AutoHotkey\v2\AutoHotkey.exe",
    "${env:ProgramFiles(x86)}\AutoHotkey\v2\AutoHotkey.exe"
) | Where-Object { $_ -and (Test-Path $_) }

foreach ($candidate in $AhkCandidates) {
    $fileVer = (Get-Item $candidate -ErrorAction SilentlyContinue).VersionInfo.FileVersion
    if ($fileVer -match '^2\.') {
        $AhkExe = $candidate
        $AhkVersion = $fileVer
        break
    }
}

if (-not $AhkExe) {
    Write-Host " NOT FOUND" -ForegroundColor Red
    Write-Host ""
    Write-Host "AutoHotkey v2 is required. Download from:" -ForegroundColor Yellow
    Write-Host "  https://www.autohotkey.com/v2/" -ForegroundColor Cyan
    Write-Host ""; pause; exit 1
}

Write-Host " v$AhkVersion" -ForegroundColor Green
Write-Host "    $AhkExe" -ForegroundColor DarkGray

# ------------------------------------------------------------------
# Step 3: Find JumpToFolder.exe
# ------------------------------------------------------------------
Write-Host "[2/3] Searching for JumpToFolder.exe..." -NoNewline

$StandardPaths = @(
    "C:\Program Files\JumpToFolder\JumpToFolder.exe",
    "C:\Program Files (x86)\JumpToFolder\JumpToFolder.exe",
    (Join-Path $env:LOCALAPPDATA "JumpToFolder\JumpToFolder.exe"),
    (Join-Path $ScriptDir "JumpToFolder.exe")
)

$JtfPath = $null
foreach ($p in $StandardPaths) {
    if (Test-Path $p) {
        $JtfPath = (Resolve-Path $p).Path
        break
    }
}

if (-not $JtfPath) {
    foreach ($parent in @("C:\Program Files", "C:\Program Files (x86)", "C:\Tools", "D:\Tools", "D:\Apps")) {
        if (Test-Path $parent) {
            $hit = Get-ChildItem -Path $parent -Filter "JumpToFolder.exe" -Recurse -ErrorAction SilentlyContinue |
                   Select-Object -First 1
            if ($hit) { $JtfPath = $hit.FullName; break }
        }
    }
}

if ($JtfPath) {
    Write-Host " Found" -ForegroundColor Green
    Write-Host "    $JtfPath" -ForegroundColor DarkGray
} else {
    Write-Host " Not found in standard locations" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Tip: you can drag-and-drop JumpToFolder.exe onto this window." -ForegroundColor DarkGray
    $inputPath = Read-Host "Enter the full path to JumpToFolder.exe"
    $inputPath  = $inputPath.Trim().Trim('"')

    if ([string]::IsNullOrWhiteSpace($inputPath)) {
        Write-Host "No path provided. Exiting." -ForegroundColor Red
        Write-Host ""; pause; exit 1
    }
    if (-not (Test-Path $inputPath)) {
        Write-Host "ERROR: Path does not exist:" -ForegroundColor Red
        Write-Host "  $inputPath" -ForegroundColor Red
        Write-Host ""; pause; exit 1
    }

    $resolved = Get-Item $inputPath
    if ($resolved.Extension -ne ".exe") {
        Write-Host "WARNING: File does not have an .exe extension. Proceeding anyway." -ForegroundColor Yellow
    }
    $JtfPath = $resolved.FullName
}

# ------------------------------------------------------------------
# Step 4: Patch JumpToFolderTrigger.ahk
# ------------------------------------------------------------------
Write-Host "[3/3] Configuring JumpToFolderTrigger.ahk..." -NoNewline

$content     = Get-Content $AhkScript -Raw -Encoding UTF8
$escapedPath = ($JtfPath -replace "'", "''") -replace '/', '\'
$pattern     = "(?m)^JumpToFolderCmd := '.*'"
$replacement = "JumpToFolderCmd := '`"$escapedPath`" -jump'"
$newContent  = $content -replace $pattern, $replacement

if ($newContent -eq $content) {
    Write-Host " ERROR" -ForegroundColor Red
    Write-Host ""
    Write-Host "Could not find the JumpToFolderCmd line in the script." -ForegroundColor Red
    Write-Host "Please edit JumpToFolderTrigger.ahk manually and update the path." -ForegroundColor Yellow
    Write-Host ""; pause; exit 1
}

Set-Content -Path $AhkScript -Value $newContent -Encoding UTF8 -NoNewline
Write-Host " Done" -ForegroundColor Green

# ------------------------------------------------------------------
# Optional: Startup shortcut
# ------------------------------------------------------------------
Write-Host ""
$addStartup = Read-Host "Add to Windows Startup (runs automatically at login)? (Y/N)"
if ($addStartup -match '^[Yy]') {
    $startupFolder = [Environment]::GetFolderPath("Startup")
    $shortcutPath  = Join-Path $startupFolder "JumpToFolderTrigger.lnk"

    $shell              = New-Object -ComObject WScript.Shell
    $shortcut           = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath       = $AhkExe           # Explicit AHK v2 exe — not the .ahk file
    $shortcut.Arguments        = "`"$AhkScript`""
    $shortcut.WorkingDirectory = $ScriptDir
    $shortcut.Description      = "JumpToFolder Trigger for Save/Open Dialogs"
    $shortcut.Save()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null

    Write-Host "Startup shortcut created:" -ForegroundColor Green
    Write-Host "  $shortcutPath" -ForegroundColor DarkGray
}

# ------------------------------------------------------------------
# Optional: Launch now
# ------------------------------------------------------------------
Write-Host ""
$launchNow = Read-Host "Launch the script now? (Y/N)"
if ($launchNow -match '^[Yy]') {
    Start-Process -FilePath $AhkExe -ArgumentList "`"$AhkScript`""
    Write-Host "Script is now running." -ForegroundColor Green
}

# ------------------------------------------------------------------
# Done
# ------------------------------------------------------------------
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   Installation complete!"                          -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
if ($launchNow -notmatch '^[Yy]') {
    Write-Host "To start manually: double-click JumpToFolderTrigger.ahk" -ForegroundColor Cyan
}
Write-Host ""
pause

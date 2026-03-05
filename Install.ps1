#Requires -Version 5.1
<#
.SYNOPSIS
    Installs JumpToFolder Trigger script by configuring the path and optionally adding to Windows Startup.
.DESCRIPTION
    Searches for JumpToFolder.exe, updates JumpToFolderTrigger.ahk with the path,
    and optionally creates a shortcut in the Startup folder.
#>

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AhkScript = Join-Path $ScriptDir "JumpToFolderTrigger.ahk"

# Check AutoHotkey v2 is installed
$AhkPath = Get-Command "AutoHotkey64.exe" -ErrorAction SilentlyContinue
if (-not $AhkPath) {
    $AhkPath = Get-Command "AutoHotkey.exe" -ErrorAction SilentlyContinue
}
if (-not $AhkPath) {
    $AhkV2Paths = @(
        "${env:ProgramFiles}\AutoHotkey\v2\AutoHotkey64.exe",
        "${env:ProgramFiles}\AutoHotkey\v2\AutoHotkey.exe",
        "${env:ProgramFiles(x86)}\AutoHotkey\v2\AutoHotkey.exe"
    )
    foreach ($p in $AhkV2Paths) {
        if (Test-Path $p) {
            $AhkPath = Get-Item $p
            break
        }
    }
}
if (-not $AhkPath) {
    Write-Host "ERROR: AutoHotkey v2 is not installed." -ForegroundColor Red
    Write-Host "Download and install from: https://www.autohotkey.com/v2/" -ForegroundColor Yellow
    exit 1
}

# Check AHK script exists
if (-not (Test-Path $AhkScript)) {
    Write-Host "ERROR: JumpToFolderTrigger.ahk not found in: $ScriptDir" -ForegroundColor Red
    exit 1
}

# Search for JumpToFolder.exe
$SearchPaths = @(
    "C:\Program Files\JumpToFolder\JumpToFolder.exe",
    "C:\Program Files (x86)\JumpToFolder\JumpToFolder.exe",
    (Join-Path $env:LOCALAPPDATA "JumpToFolder\JumpToFolder.exe"),
    (Join-Path $ScriptDir "JumpToFolder.exe")
)

$JumpToFolderPath = $null
foreach ($p in $SearchPaths) {
    if (Test-Path $p) {
        $JumpToFolderPath = (Resolve-Path $p).Path
        break
    }
}

# Fallback: search in common parent folders
if (-not $JumpToFolderPath) {
    $ParentPaths = @("C:\Program Files", "C:\Program Files (x86)", "C:\Tools", "D:\Tools", "D:\Apps")
    foreach ($parent in $ParentPaths) {
        if (Test-Path $parent) {
            $found = Get-ChildItem -Path $parent -Filter "JumpToFolder.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) {
                $JumpToFolderPath = $found.FullName
                break
            }
        }
    }
}

# Prompt if not found
if (-not $JumpToFolderPath) {
    Write-Host "JumpToFolder.exe was not found in common locations." -ForegroundColor Yellow
    Write-Host ""
    $inputPath = Read-Host "Enter the full path to JumpToFolder.exe (or drag-and-drop the file here)"
    $inputPath = $inputPath.Trim().Trim('"')
    if ([string]::IsNullOrWhiteSpace($inputPath)) {
        Write-Host "No path provided. Exiting." -ForegroundColor Red
        exit 1
    }
    if (-not (Test-Path $inputPath)) {
        Write-Host "ERROR: Path does not exist: $inputPath" -ForegroundColor Red
        exit 1
    }
    $resolved = Get-Item $inputPath
    if ($resolved.Name -ne "JumpToFolder.exe") {
        Write-Host "WARNING: File is not named JumpToFolder.exe. Using anyway." -ForegroundColor Yellow
    }
    $JumpToFolderPath = $resolved.FullName
}

# Normalize path (backslashes)
$JumpToFolderPath = $JumpToFolderPath -replace '/', '\'

# Update the AHK script
$content = Get-Content $AhkScript -Raw -Encoding UTF8
$pattern = "JumpToFolderCmd := '.*'"
$escapedPath = $JumpToFolderPath -replace "'", "''"
$replacement = "JumpToFolderCmd := '`"$escapedPath`" -jump'"
$newContent = $content -replace $pattern, $replacement

if ($newContent -eq $content) {
    Write-Host "ERROR: Could not find JumpToFolderCmd line in script. Manual edit may be required." -ForegroundColor Red
    exit 1
}

Set-Content -Path $AhkScript -Value $newContent -Encoding UTF8 -NoNewline
Write-Host "Configured JumpToFolder path: $JumpToFolderPath" -ForegroundColor Green

# Optional: Add to Startup
Write-Host ""
$addStartup = Read-Host "Add to Windows Startup? (Y/N)"
if ($addStartup -match '^[Yy]') {
    $startupFolder = [Environment]::GetFolderPath("Startup")
    $shortcutPath = Join-Path $startupFolder "JumpToFolderTrigger.lnk"

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $AhkScript
    $shortcut.WorkingDirectory = $ScriptDir
    $shortcut.Description = "JumpToFolder Trigger for Save Dialogs"
    $shortcut.Save()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null

    Write-Host "Startup shortcut created. Script will run automatically when you log in." -ForegroundColor Green
} else {
    Write-Host "Skipped startup shortcut." -ForegroundColor Gray
}

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host "Double-click JumpToFolderTrigger.ahk to run the script." -ForegroundColor Cyan
if ($addStartup -match '^[Yy]') {
    Write-Host "Or log out and back in to have it start automatically." -ForegroundColor Cyan
}

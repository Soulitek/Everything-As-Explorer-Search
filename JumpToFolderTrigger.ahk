; ============================================
; AutoHotkey v2 Script: Jump to Folder Trigger for Save Dialogs
; ============================================
; This script automatically launches JumpToFolder when you interact with
; Windows Save/Open dialogs, making it faster to navigate to folders.
;
; REQUIREMENTS:
; - AutoHotkey v2.0 or later (https://www.autohotkey.com/v2/)
; - JumpToFolder installed (https://www.voidtools.com/forum/viewtopic.php?t=2982)
;
; INSTALLATION:
; 1. Install AutoHotkey v2
; 2. Install and configure JumpToFolder
; 3. Update the path below to match YOUR JumpToFolder.exe location
; 4. Save this script as a .ahk file and double-click to run
; 5. (Optional) Add to Windows startup folder for automatic loading
;
; TRIGGERS:
; - Right-click anywhere in Save/Open dialog
; - Click on folder address/path bar
; - Click on navigation toolbar buttons
; - Click on search box
; ============================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================
; CONFIGURATION - CHANGE THIS PATH!
; ============================================
; UPDATE THIS to match where YOUR JumpToFolder.exe is installed
; Examples:
;   "C:\Program Files\JumpToFolder\JumpToFolder.exe" -jump
;   "C:\Tools\JumpToFolder\JumpToFolder.exe" -jump
;   "D:\Apps\JumpToFolder\JumpToFolder.exe" -jump

JumpToFolderCmd := '"C:\Users\Eitan\Desktop\New folder (2)\JumpToFolder.exe" -jump'

; Alternative: If you created a .lnk shortcut, you can use that instead:
; JumpToFolderCmd := '"C:\Path\To\Your\JumpToFolder.lnk"'
; ============================================

; Method 1: Right-click anywhere in Save dialog
#HotIf WinActive("ahk_class #32770")
RButton:: {
    Run JumpToFolderCmd
    return
}
#HotIf

; Method 2: Click on the folder navigation/address box (Edit2)
#HotIf WinActive("ahk_class #32770")
~LButton:: {
    ; Get the control under the mouse cursor
    MouseGetPos ,, &winID, &controlClass
    
    ; Check if clicked on navigation box, toolbar, or search box
    if (controlClass = "Edit2" or 
        controlClass = "ToolbarWindow324" or 
        controlClass = "Edit1" or
        controlClass = "DirectUIHWND3") {
        ; Small delay to let the click register
        Sleep 50
        Run JumpToFolderCmd
    }
}
#HotIf

; Alternative: Use Ctrl+Click on the navigation box (if auto-trigger is too sensitive)
/*
#HotIf WinActive("ahk_class #32770")
^LButton:: {
    MouseGetPos ,, &winID, &controlClass
    if (controlClass = "Edit2") {
        Run JumpToFolderCmd
    }
}
#HotIf
*/


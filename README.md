# JumpToFolder Trigger Script for Windows Save Dialogs

Automatically launch JumpToFolder when interacting with Windows Save/Open dialogs for faster folder navigation.

## 🎯 What This Does

Instead of right-clicking in Save dialogs and selecting "Jump to Folder..." from the context menu, this script instantly launches JumpToFolder when you:
- **Right-click** anywhere in the Save/Open dialog
- **Click** on the folder address bar
- **Click** on the navigation toolbar
- **Click** on the search box

## 📋 Requirements

1. **Windows** (7, 8, 10, or 11)
2. **AutoHotkey v2.0+** - [Download here](https://www.autohotkey.com/v2/)
3. **JumpToFolder** - [Download here](https://www.voidtools.com/forum/viewtopic.php?t=2982)

## 🚀 Installation

### Step 1: Install Prerequisites
1. Download and install **AutoHotkey v2** from https://www.autohotkey.com/v2/
2. Download and set up **JumpToFolder** from https://www.voidtools.com/forum/viewtopic.php?t=2982
3. Test JumpToFolder manually (right-click in Save dialog → "Jump to Folder...") to ensure it's configured correctly

### Step 2: Configure the Script
1. Open the `.ahk` script file in a text editor (Notepad, VS Code, etc.)
2. Find line 28 that says:
   ```
   JumpToFolderCmd := '"C:\Users\Eitan\Desktop\New folder (2)\JumpToFolder.exe" -jump'
   ```
3. **Change the path** to where YOUR JumpToFolder.exe is located. For example:
   ```
   JumpToFolderCmd := '"C:\Program Files\JumpToFolder\JumpToFolder.exe" -jump'
   ```
4. Save the file

### Step 3: Run the Script
1. Double-click the `.ahk` file to run it
2. You should see the AutoHotkey icon in your system tray (bottom-right corner)
3. Open any Save/Open dialog and test the triggers!

### Step 4: Run at Startup (Optional)
To automatically start the script when Windows boots:
1. Press `Win + R`
2. Type `shell:startup` and press Enter
3. Create a shortcut to your `.ahk` file in this folder

## 🎮 Usage

Once the script is running:

| Action | Result |
|--------|--------|
| Right-click in Save dialog | Launches JumpToFolder |
| Click folder path bar | Launches JumpToFolder |
| Click navigation buttons | Launches JumpToFolder |
| Click search box | Launches JumpToFolder |

## 🔧 Troubleshooting

### Script doesn't work
- Make sure you're running AutoHotkey **v2** (not v1)
- Check that the path to JumpToFolder.exe is correct
- Verify JumpToFolder works manually first (right-click → "Jump to Folder...")

### JumpToFolder doesn't launch
- Open Command Prompt and manually run:
  ```
  "C:\Your\Path\To\JumpToFolder.exe" -jump
  ```
- If this doesn't work, your path is incorrect

### Wrong controls are triggered
- The script detects these Windows controls:
  - `Edit2` - Address bar
  - `ToolbarWindow324` - Navigation toolbar
  - `DirectUIHWND3` - Search box
- These are standard on Windows 10/11 but may vary on older systems

## 🛠️ Customization

### Change Trigger Keys
If you don't want right-click to trigger JumpToFolder, edit the script and uncomment the alternative hotkey section:

```autohotkey
; Use Ctrl+Click instead
#HotIf WinActive("ahk_class #32770")
^LButton:: {
    MouseGetPos ,, &winID, &controlClass
    if (controlClass = "Edit2") {
        Run JumpToFolderCmd
    }
}
#HotIf
```

### Add More Triggers
To add more controls, use the diagnostic section in the script to find control class names.

## 📝 Credits

- Script created for quick JumpToFolder access
- JumpToFolder by voidtools: https://www.voidtools.com/
- AutoHotkey: https://www.autohotkey.com/

## 📄 License

Free to use and modify. Share with anyone who might find it useful!

## 🐛 Issues or Suggestions?

If you encounter problems or have ideas for improvements, feel free to modify the script or share your feedback with the community!

---

**Note:** Make sure JumpToFolder is properly configured before using this script. Test it manually first by right-clicking in a Save dialog and selecting "Jump to Folder..." from the context menu.


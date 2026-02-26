# Disable My TouchBar

A completely free macOS Touch Bar hiding tool that **perfectly blanks out the Touch Bar by double-tapping the ⌘ Command key**.

This project uses the exact same "global highest-priority pure black interface overlay" technology as paid software alternatives. It does NOT rely on any third-party tools (no skhd required), does NOT modify core system files (no SIP conflicts), and does NOT require Sudo privileges. Once running, it acts as an invisible background application silently listening for the hotkey.

## Features

- ⚡️ **Instant Response**: Directly calls SwiftUI/Cocoa low-level APIs (private `NSTouchBar` methods) with zero latency.
- 🖤 **Absolute Black**: Covers the entire Touch Bar screen space, perfectly hiding the original system Control Strip, Escape key, and return buttons.
- 🛡️ **Safe & Painless**: Does not forcefully kill processes (avoiding the flickering issues caused by process crashes and auto-restarts), requires no `sudoers` modifications, and is perfectly compatible with recent macOS versions (fully supports SIP-enabled devices).
- ⌨️ **Native Double-Tap**: Uses low-level `CGEventTap` to intercept double-taps of the ⌘ Command key.

---

## Quick Installation & Usage

### 1. Compile the Background Service

Because this involves manipulating low-level macOS UI APIs, the source code must be compiled into a binary executable before use.
Run the following in your terminal:

```bash
# Navigate to the project directory
cd path/to/DisableMyTouchBar

# Compile the Swift source code
swiftc -O disable_my_touchbar.swift -o disable_my_touchbar
```

### 2. Test Run & Authorization (Crucial Step)

For the program to globally listen to **"⌘ Command key press events"**, it MUST be granted macOS "Accessibility" permissions.

```bash
# First, run it directly in the foreground in your terminal
./disable_my_touchbar
```
*At this point, your screen will likely pop up a warning asking for Accessibility permissions.*

Open **System Settings > Privacy & Security > Accessibility**:
1. Click the **`+`** button at the bottom of the list.
2. Select the `disable_my_touchbar` file you just compiled and add it.
3. Ensure its toggle switch is turned **ON**.
*(If you have added it before but recompiled it, the signature changes. You must select the old one, click `-` to remove it, and then use `+` to add the new one again!)*

After authorizing, return to your terminal and press `Ctrl + C` to kill the foreground process.

### 3. Configure Auto-Start (LaunchAgent)

Simply copy the included plist file to your system's LaunchAgents directory:

```bash
# 1. Edit and copy the plist file
# IMPORTANT: The plist file defaults to the path /Users/shuo.wangws/Documents/antigravity/DisableMyTouchBar/disable_my_touchbar. Open com.local.disable-my-touchbar.plist with a text editor and change the ProgramArguments path to the actual absolute path where you stored the project!
cp com.local.disable-my-touchbar.plist ~/Library/LaunchAgents/

# 2. Tell the system to load this startup item
launchctl load ~/Library/LaunchAgents/com.local.disable-my-touchbar.plist

# 3. All done! Now try quickly double-tapping the ⌘ Command key.
```

---

## Logs & Troubleshooting

If the double-tap isn't working, you can check the log files located in `/tmp` to troubleshoot:

```bash
tail -f /tmp/disable_my_touchbar_err.log
```
> If you see `Double-Cmd detected!` in the logs, the listener is working. If you see `Touch Bar BLANKED`, the black screen code executed successfully.

## Uninstall

```bash
launchctl bootout gui/$(id -u)/com.local.disable-my-touchbar
rm ~/Library/LaunchAgents/com.local.disable-my-touchbar.plist
# Then simply delete this project directory
```

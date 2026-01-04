# AutoTime - Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Create Xcode Project

1. Open **Xcode**
2. File → New → Project
3. Choose **macOS** → **App**
4. Settings:
   - Product Name: `AutoTime`
   - Team: Select your team
   - Organization Identifier: `com.yourname`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - ✅ Include Tests: Optional
   - ❌ Use Core Data: **Unchecked**

### Step 2: Import Source Files

1. In Finder, navigate to:
   ```
   /Users/lelanie/Documents/App DEVS/Time Tracker/AutoTime-macOS/
   ```

2. **Delete** these default Xcode files:
   - `ContentView.swift`
   - `AutoTimeApp.swift` (we have our own)

3. **Drag and drop** the entire `AutoTime` folder into Xcode:
   - ✅ Check "Copy items if needed"
   - ✅ Check "Create groups"
   - ✅ Add to target: AutoTime

4. **Drag and drop** `AutoTime.entitlements` to the project root

### Step 3: Configure Project Settings

1. Select **AutoTime** project in navigator
2. Select **AutoTime** target
3. Go to **Signing & Capabilities** tab:
   - Team: Select your team
   - Bundle Identifier: Should show `com.yourname.AutoTime`
   - Code Signing Entitlements: Select `AutoTime.entitlements`

4. Go to **General** tab:
   - Minimum Deployments: Set to **macOS 13.0**

5. Go to **Info** tab:
   - Ensure `Info.plist` is selected as the info plist file

### Step 4: Build & Run

1. Press **⌘R** or click the Play button
2. The app should build successfully
3. Look for the **clock icon** in your menu bar

### Step 5: Grant Permissions

1. Click the clock icon → You'll see a permission alert
2. Click **"Open System Settings"**
3. System Settings → Privacy & Security → Accessibility
4. Click the lock icon to unlock
5. Toggle **AutoTime** to ON
6. Return to the app

### Step 6: Start Tracking

1. Click the **clock icon** in menu bar
2. Select **"Start Workday"**
3. Choose Company and Allocation (optional)
4. Click **"Begin Tracking"**
5. Open **"Open Dashboard"** to see your tracking

## ✅ That's It!

The app is now tracking your active applications automatically.

## Common Issues

### "Failed to build" error
- Make sure all files are added to the AutoTime target
- Clean build folder: Product → Clean Build Folder (⌘⇧K)

### Menu bar icon doesn't appear
- Check Console.app for errors
- Ensure `Info.plist` has `LSUIElement = true`

### Window titles not detected
- Grant Accessibility permissions
- Restart the app after granting permissions

### Code signing error
- Ensure you have a valid Apple Developer account
- Select your Team in Signing & Capabilities

## File Checklist

Make sure these files are in your Xcode project:

```
✓ AutoTimeApp.swift
✓ AppDelegate.swift
✓ Info.plist
✓ AutoTime.entitlements
✓ Models/
  ✓ TimeEntry.swift
  ✓ ActivityTracker.swift
  ✓ AppMonitor.swift
✓ Views/
  ✓ DashboardView.swift
  ✓ StartupModalView.swift
✓ Utilities/
  ✓ WindowTitleParser.swift
  ✓ IdleMonitor.swift
  ✓ CSVExporter.swift
```

## Next Steps

- Test the 5-minute sticky rule by switching apps
- Try editing entries in the dashboard
- Export a CSV to see the timesheet format
- Customize blacklisted apps or parsing rules

For detailed documentation, see [README.md](README.md).

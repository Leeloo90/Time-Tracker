# AutoTime - Complete Setup Guide

## Prerequisites
- ✅ macOS 13.0 or later
- ⏳ Xcode 15.0+ (installing from App Store)
- ✅ Apple ID (for code signing)

---

## Part 1: After Xcode Installs

### 1. Launch Xcode for the First Time

1. **Open Xcode** from Applications folder or Spotlight (⌘Space → type "Xcode")
2. **Accept the license agreement** when prompted
3. **Wait for additional components** to install (may take 5-10 minutes)
4. You'll see the Xcode welcome screen

---

## Part 2: Create the Project

### 2. Create New Project

1. In Xcode welcome window, click **"Create New Project"**
   - OR: File → New → Project (⇧⌘N)

2. **Select macOS → App**
   ```
   Platform: macOS
   Application: App
   ```
   Click **Next**

3. **Configure Project**:
   ```
   Product Name: AutoTime
   Team: Select your personal team (your Apple ID)
   Organization Identifier: com.yourname (or use your email domain)
   Bundle Identifier: (auto-fills to com.yourname.AutoTime)
   Interface: SwiftUI
   Language: Swift
   Storage: None
   ☐ Include Tests (optional)
   ```
   Click **Next**

4. **Choose Save Location**:
   - Navigate to: `/Users/lelanie/Documents/App DEVS/Time Tracker/`
   - Create a new folder called **"AutoTime-Xcode"** (to keep it separate from our source)
   - Click **Create**

---

## Part 3: Import Source Files

### 3. Delete Default Files

In Xcode's left sidebar (Project Navigator):
1. **Right-click** on `ContentView.swift` → Delete → Move to Trash
2. **Right-click** on `AutoTimeApp.swift` → Delete → Move to Trash

### 4. Add Our Source Files

**Method 1: Drag & Drop (Easiest)**

1. Open **Finder** and navigate to:
   ```
   /Users/lelanie/Documents/App DEVS/Time Tracker/AutoTime-macOS/
   ```

2. In **Finder**, select the **entire `AutoTime` folder**

3. **Drag** it into Xcode's left sidebar, drop it on the "AutoTime" project

4. In the dialog that appears:
   ```
   ☑ Copy items if needed
   ☑ Create groups
   ☑ Add to targets: AutoTime
   ```
   Click **Finish**

5. **Drag** `AutoTime.entitlements` file into Xcode (same process)

**Method 2: Add Files (Alternative)**

1. Right-click on "AutoTime" in Xcode sidebar
2. Select "Add Files to AutoTime..."
3. Navigate to the `AutoTime-macOS` folder
4. Select `AutoTime` folder and `AutoTime.entitlements`
5. Ensure "Copy items if needed" is checked
6. Click "Add"

### 5. Verify Files Are Added

Your Xcode project navigator should now look like:
```
AutoTime
├── AutoTime
│   ├── AutoTimeApp.swift
│   ├── AppDelegate.swift
│   ├── Info.plist
│   ├── Models
│   │   ├── ActivityTracker.swift
│   │   ├── AppMonitor.swift
│   │   └── TimeEntry.swift
│   ├── Views
│   │   ├── DashboardView.swift
│   │   └── StartupModalView.swift
│   └── Utilities
│       ├── CSVExporter.swift
│       ├── IdleMonitor.swift
│       └── WindowTitleParser.swift
├── AutoTime.entitlements
└── Assets.xcassets
```

---

## Part 4: Configure Project

### 6. Select Project Settings

1. Click **"AutoTime"** at the top of the left sidebar (blue icon)
2. Ensure **"AutoTime"** target is selected (not the project)

### 7. General Tab

1. Click **"General"** tab
2. **Minimum Deployments**: Change to **macOS 13.0**

### 8. Signing & Capabilities Tab

1. Click **"Signing & Capabilities"** tab
2. **Automatically manage signing**: ☑ Checked
3. **Team**: Select your team (your Apple ID / Personal Team)
4. **Bundle Identifier**: Should show `com.yourname.AutoTime`

### 9. Build Settings Tab

1. Click **"Build Settings"** tab
2. Search for **"Code Signing Entitlements"**
3. Set value to: `AutoTime.entitlements`
4. Search for **"Info.plist File"**
5. Ensure it points to: `AutoTime/Info.plist`

---

## Part 5: Build & Run

### 10. Build the App

1. Select **"My Mac"** as the run destination (top toolbar)
2. Press **⌘B** to build
   - OR: Product → Build

3. **Wait for build to complete** (should say "Build Succeeded")

### 11. Run the App

1. Press **⌘R** to run
   - OR: Product → Run
   - OR: Click the ▶ play button

2. The app should launch!

---

## Part 6: First Run Setup

### 12. Grant Accessibility Permissions

When you first run the app:

1. You'll see a **permission dialog** from AutoTime
2. Click **"Open System Settings"**
3. System Settings will open to **Privacy & Security → Accessibility**
4. Click the **🔒 lock icon** to unlock (enter your password)
5. Find **"AutoTime"** in the list
6. Toggle it **ON** ✅
7. **Close** System Settings

### 13. Start Using AutoTime

1. Look for the **clock icon** (⏰) in your menu bar (top-right)
2. **Click the clock icon**
3. Select **"Start Workday"**
4. Choose Company and Allocation (or leave blank)
5. Click **"Begin Tracking"**
6. Select **"Open Dashboard"** to see your tracking

---

## Troubleshooting

### Build Errors

**Error: "Cannot find 'NSWorkspace' in scope"**
- **Fix**: Ensure `import AppKit` is at the top of files that need it
- Rebuild: ⇧⌘K (Clean) then ⌘B (Build)

**Error: "Code signing error"**
- **Fix**: Go to Signing & Capabilities → select your Team
- If no team available, sign in with Apple ID in Xcode → Settings → Accounts

**Error: "Missing Info.plist"**
- **Fix**: Ensure `AutoTime/Info.plist` is in your project
- Build Settings → Info.plist File → set to `AutoTime/Info.plist`

### Runtime Issues

**Menu bar icon doesn't appear**
- Check Console.app for crash logs
- Ensure `LSUIElement = true` in Info.plist
- Restart Xcode and rebuild

**"Window titles not detected"**
- Grant Accessibility permissions
- Restart the app after granting permissions
- Check System Settings → Privacy → Accessibility

**App crashes on launch**
- Open Console.app
- Filter for "AutoTime"
- Look for error messages
- Check that all Swift files are added to the AutoTime target

---

## Testing the App

### Test Checklist

1. **Menu bar icon visible** ✓
2. **Can start workday** ✓
3. **Dashboard opens** ✓
4. **Switch between apps** (Chrome → DaVinci → etc.)
5. **Check if entries appear in dashboard** ✓
6. **Edit an entry** (click on Company field, change it)
7. **Test 5-minute sticky rule**:
   - Start with one app
   - Switch to another
   - Switch back within 5 min
   - Verify no new entry was created
8. **Test idle detection**:
   - Start tracking
   - Don't touch mouse/keyboard for 5 min
   - Verify session closes
9. **Export CSV** ✓
10. **Stop workday** ✓

---

## Next Steps After Testing

### Make It Run on Login

1. System Settings → General → Login Items
2. Click **"+"** under "Open at Login"
3. Navigate to your built app:
   ```
   ~/Library/Developer/Xcode/DerivedData/AutoTime-.../Build/Products/Debug/AutoTime.app
   ```
4. Add it to login items

### Create a Release Build

1. Product → Archive
2. Distribute App → Copy App
3. Move `AutoTime.app` to `/Applications`
4. Run from Applications folder

### Customize

See [README.md](README.md) for:
- Adding custom blacklist apps
- Adding custom window title parsers
- Changing time thresholds
- Styling modifications

---

## Getting Help

- **Build issues**: Clean build folder (⇧⌘K), restart Xcode
- **Permission issues**: Check System Settings → Privacy & Security
- **Crashes**: Check Console.app for logs
- **Feature questions**: See [README.md](README.md)

---

**Ready to build? Follow the steps above after Xcode finishes installing!** 🚀

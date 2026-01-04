# AutoTime - Native macOS App

A native macOS menu bar application for automatic time tracking with the 5-minute sticky rule.

## Features

- **Menu Bar Integration**: Lives in your macOS menu bar
- **Automatic App Tracking**: Monitors active applications via NSWorkspace
- **Window Title Detection**: Extracts project names from window titles (requires Accessibility permissions)
- **5-Minute Sticky Rule**: Smart switching logic to filter out brief interruptions
- **Idle Detection**: Automatically closes sessions after 5 minutes of inactivity
- **Blacklist Support**: Ignores specified apps (Finder, System Settings, etc.)
- **Editable Dashboard**: Interactive table with inline editing
- **CSV Export**: Export timesheets in standardized format
- **Data Persistence**: Automatic saving via UserDefaults

## Project Structure

```
AutoTime/
├── AutoTimeApp.swift          # Main app entry point
├── AppDelegate.swift          # Menu bar & lifecycle management
├── Models/
│   ├── TimeEntry.swift        # Data model
│   ├── ActivityTracker.swift  # Core tracking logic (5-min rule)
│   └── AppMonitor.swift       # NSWorkspace monitoring
├── Views/
│   ├── DashboardView.swift    # Main dashboard UI
│   └── StartupModalView.swift # Session configuration modal
├── Utilities/
│   ├── WindowTitleParser.swift # Project name parsing
│   ├── IdleMonitor.swift      # HID event monitoring
│   └── CSVExporter.swift      # Export functionality
├── Info.plist                 # App configuration
└── AutoTime.entitlements      # Permissions
```

## Building the App

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- Apple Developer account (for code signing)

### Steps to Create Xcode Project

1. **Open Xcode**
2. **Create a new project**:
   - Choose "macOS" → "App"
   - Product Name: `AutoTime`
   - Bundle Identifier: `com.yourname.AutoTime`
   - Interface: SwiftUI
   - Language: Swift
   - Uncheck "Use Core Data"

3. **Import the source files**:
   - Delete the default `ContentView.swift` file
   - Drag all files from `AutoTime-macOS/AutoTime/` into your Xcode project
   - Ensure "Copy items if needed" is checked
   - Add to target: AutoTime

4. **Configure the project**:
   - Select your project in the navigator
   - Go to "Signing & Capabilities"
   - Add your Team
   - Add capability: "App Sandbox" (then disable it in entitlements)
   - Ensure `AutoTime.entitlements` is selected in "Code Signing Entitlements"

5. **Set deployment target**:
   - General tab → Minimum Deployments: macOS 13.0

6. **Build and Run**:
   - Press ⌘R or Product → Run
   - The app will appear in your menu bar (clock icon)

### First Run Setup

When you first run the app:

1. **Grant Accessibility Permissions**:
   - The app will prompt you to grant Accessibility permissions
   - Go to System Settings → Privacy & Security → Accessibility
   - Enable AutoTime

2. **Start Tracking**:
   - Click the clock icon in the menu bar
   - Select "Start Workday"
   - Configure Company and Allocation (optional)
   - Click "Begin Tracking"

3. **View Dashboard**:
   - Click menu bar icon → "Open Dashboard"
   - See your tracked time entries
   - Edit any field by clicking on it
   - Export to CSV when ready

## How It Works

### 5-Minute Sticky Rule

When you switch from App A to App B:
- A "pending switch" timer starts
- If you return to App A within 5 minutes → switch is cancelled, time continues on App A
- If you stay on App B for 5+ minutes → switch is committed, new entry created for App B

### Idle Detection

- Monitors keyboard and mouse events
- After 5 minutes of no input → current session closes at last activity time
- Resumes when you return to work

### Blacklist Apps

Apps in the blacklist (Finder, System Settings, etc.):
- Do not create time entries
- If active for 5+ minutes → previous session is terminated
- Treated as idle/break time

### Window Title Parsing

The app intelligently parses project names from window titles:
- **DaVinci Resolve**: `"DaVinci Resolve - Project Name"` → `"Project Name"`
- **Browsers**: Tab title becomes the project name
- **Final Cut Pro**: `"Project Name - Final Cut Pro"` → `"Project Name"`
- **Other apps**: Full window title is used

## Customization

### Adding Custom Apps to Blacklist

Edit [AppMonitor.swift](AutoTime/Models/AppMonitor.swift:24):
```swift
static let blacklistedApps = ["Finder", "System Settings", "Your App Here"]
```

### Adding Custom Parsing Rules

Edit [WindowTitleParser.swift](AutoTime/Utilities/WindowTitleParser.swift):
```swift
case "Your App":
    return customParsingLogic(title)
```

### Changing Time Thresholds

Edit [ActivityTracker.swift](AutoTime/Models/ActivityTracker.swift:26-27):
```swift
private let stickyThresholdSeconds: TimeInterval = 300 // 5 minutes
private let idleThresholdSeconds: TimeInterval = 300 // 5 minutes
```

## Troubleshooting

### App not detecting window titles
- Ensure Accessibility permissions are granted
- Restart the app after granting permissions

### Menu bar icon not appearing
- Check that `LSUIElement` is set to `true` in Info.plist
- This makes the app run as a menu bar-only app (no Dock icon)

### Tracking not working
- Check Console.app for error messages
- Look for AutoTime logs (marked with 🔍 🚫 ✅ ❌ 💤 emojis)

### Build errors
- Ensure deployment target is macOS 13.0+
- Clean build folder: Product → Clean Build Folder
- Delete DerivedData: ~/Library/Developer/Xcode/DerivedData

## Known Limitations

- Requires Accessibility permissions (user must grant manually)
- Cannot track apps in fullscreen mode reliably
- Some apps don't expose window titles via Accessibility API
- Sandbox restrictions prevent some system-level monitoring

## Future Enhancements

- [ ] Cloud sync for timesheet data
- [ ] Custom company/allocation templates
- [ ] Keyboard shortcut customization
- [ ] Weekly/monthly analytics
- [ ] Notification system for idle warnings
- [ ] Integration with project management tools
- [ ] Multiple timesheet profiles

## License

Copyright © 2026. All rights reserved.

## Support

For issues or questions, please check the troubleshooting section above.

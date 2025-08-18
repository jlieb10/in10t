# in10t - iOS Development Project

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Current Repository State
This repository is currently in initial setup phase with only basic configuration files:
- README.md (minimal project description)
- .gitignore (configured for iOS/Xcode/Swift development)
- No source code or Xcode project files exist yet

## Working Effectively

### Initial Setup (when project files are added)
When Xcode project files are present, follow these steps:
- Open the repository in Xcode: `open *.xcodeproj` or `open *.xcworkspace` (if using CocoaPods/SPM)
- Install dependencies if Package.swift exists: Xcode will automatically resolve Swift Package Manager dependencies
- If Podfile exists: `pod install` -- takes 2-5 minutes typically. NEVER CANCEL. Set timeout to 15+ minutes.
- If Cartfile exists: `carthage update --platform iOS` -- takes 5-15 minutes. NEVER CANCEL. Set timeout to 30+ minutes.

### Building the Project
Once Xcode project files exist:
- Build from Xcode: Product → Build (⌘+B)
- Build from command line: `xcodebuild -project *.xcodeproj -scheme [SCHEME_NAME] -destination 'platform=iOS Simulator,name=iPhone 15' build` -- takes 3-10 minutes. NEVER CANCEL. Set timeout to 20+ minutes.
- If using workspace: `xcodebuild -workspace *.xcworkspace -scheme [SCHEME_NAME] -destination 'platform=iOS Simulator,name=iPhone 15' build`

### Testing
When test files are present:
- Run tests in Xcode: Product → Test (⌘+U)
- Run tests from command line: `xcodebuild test -project *.xcodeproj -scheme [SCHEME_NAME] -destination 'platform=iOS Simulator,name=iPhone 15'` -- takes 5-20 minutes depending on test suite size. NEVER CANCEL. Set timeout to 30+ minutes.
- Run specific test: `xcodebuild test -project *.xcodeproj -scheme [SCHEME_NAME] -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:[TARGET_NAME]/[TEST_CLASS]/[TEST_METHOD]`

### Development Workflow
- Always ensure iOS Simulator is available before running builds or tests
- Use appropriate iOS deployment targets based on project configuration
- Check project settings for minimum iOS version requirements
- When adding new Swift files, ensure they're added to the correct target membership

## Validation Requirements

### Pre-commit Validation
Always run these validation steps before committing changes:
- Build the project successfully without warnings
- Run all unit tests and ensure they pass
- Check for Swift lint issues if SwiftLint is configured
- Verify app launches successfully in iOS Simulator
- Test key user flows manually in the simulator

### Manual Testing Scenarios
Once the app has functionality, always test these scenarios after making changes:
- App launch and initial screen display
- Navigation between main screens
- Core feature functionality specific to the app's purpose
- Memory usage and performance in iOS Simulator

## iOS Development Environment Requirements

### Required Tools
- Xcode (latest stable version recommended)
- iOS Simulator (comes with Xcode)
- Command Line Tools: `xcode-select --install`

### Optional but Recommended Tools
- CocoaPods: `sudo gem install cocoapods` (if Podfile exists)
- Carthage: `brew install carthage` (if Cartfile exists)
- SwiftLint: `brew install swiftlint` (for code quality)

## Common iOS Development Commands

### Project Information
- List available schemes: `xcodebuild -list -project *.xcodeproj`
- List simulators: `xcrun simctl list devices available`
- Get project info: `xcodebuild -showBuildSettings -project *.xcodeproj`

### Dependency Management
- Update Swift Package Manager dependencies: Open Xcode → File → Packages → Update to Latest Package Versions
- Install CocoaPods dependencies: `pod install`
- Update CocoaPods dependencies: `pod update`
- Install Carthage dependencies: `carthage bootstrap --platform iOS`

### Simulator Management
- Boot simulator: `xcrun simctl boot "iPhone 15"`
- List running simulators: `xcrun simctl list devices booted`
- Reset simulator: `xcrun simctl erase all`

## Repository Structure Expectations

This repository contains the "in10t" (Intentional) iOS app - a session-based screen time control app using Screen Time APIs:

```
/
├── Intentional.xcodeproj/         # Xcode project file
├── Package.swift                  # Swift Package Manager dependencies
├── Sources/
│   ├── App/                      # Main iOS app target
│   │   ├── IntentionalApp.swift
│   │   ├── Environment/
│   │   ├── Features/
│   │   │   ├── Auth/            # Authentication (Apple/Google/Email)
│   │   │   ├── Onboarding/      # Welcome and permissions
│   │   │   ├── Quotas/          # App quota management
│   │   │   ├── Today/           # Daily usage dashboard
│   │   │   ├── Session/         # Active session management
│   │   │   ├── Paywall/         # StoreKit subscriptions
│   │   │   ├── Logs/            # Usage history
│   │   │   └── Settings/        # User preferences
│   │   └── Services/
│   │       ├── ScreenTime/      # FamilyControls, ManagedSettings
│   │       ├── Persistence/     # Local + Cloud storage
│   │       └── Notifications/   # Local notifications
│   ├── Extensions/
│   │   ├── DeviceActivityMonitorExtension/
│   │   ├── ShieldConfigurationExtension/
│   │   └── ShieldActionExtension/
│   └── Widgets/                 # Home Screen widgets
├── Tests/
│   ├── Unit/
│   └── UITests/
├── fastlane/                    # Deployment automation
├── README.md
└── .gitignore
```

**Key Technical Details:**
- **Minimum iOS:** 17.0+ (required for latest Screen Time APIs)
- **Primary Frameworks:** SwiftUI, FamilyControls, ManagedSettings, DeviceActivity, ActivityKit, StoreKit 2
- **Architecture:** MVVM with dependency injection
- **Authentication:** Sign in with Apple, Google Sign-In, Firebase Auth
- **Storage:** App Group UserDefaults + Firebase/Supabase cloud sync
- **Extensions Required:** DeviceActivityMonitor, ShieldConfiguration, ShieldAction

## Timing Expectations and Timeouts

### Critical Timing Information
- **Pod install**: 2-5 minutes typical, up to 15 minutes with many dependencies. NEVER CANCEL.
- **Carthage update**: 5-15 minutes typical, up to 30 minutes with large frameworks. NEVER CANCEL.
- **Xcode build**: 3-10 minutes for clean build, 30 seconds for incremental. NEVER CANCEL builds before 20 minutes.
- **Test suite**: 5-20 minutes depending on coverage and UI tests. NEVER CANCEL before 30 minutes.
- **Simulator boot**: 30-60 seconds typically.

### Recommended Timeout Values
- Build commands: Set timeout to 20+ minutes minimum
- Test commands: Set timeout to 30+ minutes minimum
- Dependency installation: Set timeout to 30+ minutes minimum

## Troubleshooting Common Issues

### Build Issues
- Clean build folder: Product → Clean Build Folder (⌘+Shift+K) in Xcode
- Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Reset Package Cache: File → Packages → Reset Package Caches in Xcode

### Simulator Issues
- If simulator won't boot: `xcrun simctl shutdown all && xcrun simctl boot "iPhone 15"`
- If simulator is unresponsive: Reset simulator content and settings

### Dependency Issues
- CocoaPods cache issues: `pod cache clean --all && pod install`
- SPM cache issues: Delete Package.resolved and reset package caches in Xcode

## Current Status: Full iOS App Implementation

This repository contains the complete "in10t" (Intentional) iOS app implementation featuring:

**Core Features:**
- Session-based app usage control via Screen Time APIs
- Live Activity countdown timers during active sessions  
- Freemium model with StoreKit 2 subscriptions
- Multi-provider authentication (Apple, Google, Email)
- Cloud sync with Firebase/Supabase
- Streak tracking and usage analytics

**Technical Implementation:**
- **Main App:** SwiftUI-based with MVVM architecture
- **Extensions:** DeviceActivityMonitor, ShieldConfiguration, ShieldAction
- **Live Activities:** Dynamic Island and Lock Screen countdown display
- **Screen Time Integration:** FamilyControls for app selection, ManagedSettings for blocking
- **Cloud Storage:** Encrypted user data with indefinite retention until manual deletion

**Development Notes:**
1. Requires iOS 17+ and Family Controls entitlement from Apple
2. Must test on physical device (Screen Time APIs don't work in Simulator)
3. Need Apple Developer Program membership for proper testing
4. App Extensions require separate bundle identifiers and provisioning profiles

**Building and Testing:**
- Use `Intentional.xcodeproj` (not the generic in10t name referenced in base instructions)
- Main scheme: "Intentional" 
- Extension schemes: "DeviceActivityMonitorExtension", "ShieldConfigurationExtension", "ShieldActionExtension"
- Required physical device testing for Screen Time functionality
- Cloud services require API keys configuration (see Environment/ folder)

Always build and test thoroughly after making any code changes to ensure iOS app functionality remains intact.
# Intentional - iOS Screen Time Control App

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Current Repository State
This repository contains a complete iOS app implementation with:
- Intentional.xcodeproj (Xcode project)
- 27 Swift source files across main app and 3 extensions
- Swift Package Manager dependencies (Firebase, Google Sign-In)
- Complete feature modules for Screen Time control functionality

## Working Effectively

### Initial Setup
ALWAYS run these commands in exact order:
1. **Clone and open repository**:
   ```bash
   git clone https://github.com/jlieb10/in10t.git
   cd in10t
   open Intentional.xcodeproj
   ```

2. **Resolve Swift Package Manager dependencies**:
   - Xcode automatically resolves dependencies on first build
   - If issues occur: File → Packages → Reset Package Caches
   - Dependencies: Firebase SDK (Auth, Firestore), Google Sign-In

### Building the Project
**CRITICAL**: Set timeout to 60+ minutes for all build commands. NEVER CANCEL builds before completion.

1. **Build from Xcode** (RECOMMENDED):
   ```
   Product → Build (⌘+B)
   ```
   - First build: 10-15 minutes. NEVER CANCEL.
   - Incremental builds: 1-2 minutes

2. **Build from command line**:
   ```bash
   # Main app target - takes 10-15 minutes. NEVER CANCEL. Set timeout to 60+ minutes.
   xcodebuild -project Intentional.xcodeproj -scheme Intentional -destination 'platform=iOS Simulator,name=iPhone 15' build
   
   # All targets including extensions - takes 15-20 minutes. NEVER CANCEL. Set timeout to 60+ minutes.
   xcodebuild -project Intentional.xcodeproj -alltargets -destination 'platform=iOS Simulator,name=iPhone 15' build
   ```

### Testing
**CRITICAL**: Set timeout to 90+ minutes for test commands. NEVER CANCEL tests before completion.

1. **Unit Tests** (Simulator only):
   ```bash
   # Takes 5-10 minutes. NEVER CANCEL. Set timeout to 30+ minutes.
   xcodebuild test -project Intentional.xcodeproj -scheme Intentional -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

2. **Physical Device Testing** (REQUIRED for Screen Time APIs):
   ```bash
   # Replace iPhone-15 with your device name. Takes 10-15 minutes. NEVER CANCEL. Set timeout to 60+ minutes.
   xcodebuild test -project Intentional.xcodeproj -scheme Intentional -destination 'platform=iOS,name=Your-Device-Name'
   ```

3. **Manual Testing Scenarios** (REQUIRED after any changes):
   - Launch app and complete sign-in flow
   - Grant Family Controls permission
   - Select apps using FamilyActivityPicker
   - Start a session and verify Live Activity appears
   - Test shield screens when apps are blocked
   - Verify cloud sync by signing out/in

## Validation Requirements

### Pre-commit Validation
ALWAYS run these validation steps before committing changes:

1. **Build validation**:
   ```bash
   # Clean build - takes 15-20 minutes. NEVER CANCEL. Set timeout to 60+ minutes.
   xcodebuild clean build -project Intentional.xcodeproj -scheme Intentional -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

2. **Test validation**:
   ```bash
   # Unit tests - takes 10-15 minutes. NEVER CANCEL. Set timeout to 45+ minutes.
   xcodebuild test -project Intentional.xcodeproj -scheme Intentional -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

3. **SwiftLint validation** (if configured):
   ```bash
   # Install if not present
   brew install swiftlint
   # Run linting - takes 30-60 seconds
   swiftlint
   ```

4. **Package dependency validation**:
   ```bash
   # Resolve packages - takes 2-5 minutes. NEVER CANCEL. Set timeout to 15+ minutes.
   xcodebuild -resolvePackageDependencies -project Intentional.xcodeproj
   ```

### MANDATORY Manual Testing Scenarios
**CRITICAL**: These scenarios MUST be tested on physical device after ANY changes:

1. **Authentication Flow**:
   - Launch app → Sign in with Apple → Verify cloud sync
   - Sign out → Sign in with Google → Verify data persistence
   - Create email account → Test password reset flow

2. **Onboarding Flow**:
   - Grant Family Controls permission (may require developer profile)
   - Select 3+ apps using FamilyActivityPicker
   - Configure session quotas (duration, daily limits)
   - Complete onboarding and reach main dashboard

3. **Session Management**:
   - Start session for selected app → Verify Live Activity appears
   - Open managed app → Verify shield screen appears
   - Wait for session end → Verify app becomes blocked
   - Test grace period for Pro users (if applicable)

4. **Subscription Flow**:
   - Navigate to paywall → Test subscription purchase
   - Verify Pro features unlock after purchase
   - Test subscription management and cancellation

5. **Data Persistence**:
   - Create session logs → Sign out → Sign in → Verify data synced
   - Test offline usage → Come back online → Verify sync

## iOS Development Environment Requirements

### Required Tools
**CRITICAL**: Install these tools in exact order:

1. **Xcode 15.0+** with iOS 17.0+ SDK:
   - Download from Mac App Store or developer.apple.com
   - Install iOS 17.0+ simulators: Xcode → Window → Devices and Simulators → Simulators → "+"

2. **Command Line Tools**:
   ```bash
   xcode-select --install
   ```

3. **Apple Developer Program membership** (REQUIRED):
   - Family Controls entitlement requires approval from Apple
   - Physical device testing requires paid membership
   - App extensions require proper provisioning profiles

### Optional but Recommended Tools
```bash
# SwiftLint for code quality
brew install swiftlint

# Fastlane for deployment automation
sudo gem install fastlane
```

### Environment Setup Verification
Run these commands to verify setup:

```bash
# Verify Xcode installation
xcode-select --version
xcodebuild -version

# List available simulators
xcrun simctl list devices available | grep iPhone

# Verify Swift Package Manager
swift package --version
```

## Common iOS Development Commands

### Project Information
```bash
# List all schemes and targets
xcodebuild -list -project Intentional.xcodeproj

# Show build settings
xcodebuild -showBuildSettings -project Intentional.xcodeproj -target Intentional

# List available simulators
xcrun simctl list devices available
```

### Dependency Management
**CRITICAL**: Swift Package Manager is used (NOT CocoaPods/Carthage)

```bash
# Reset package cache if issues occur - takes 2-3 minutes. NEVER CANCEL. Set timeout to 10+ minutes.
rm -rf ~/Library/Developer/Xcode/DerivedData
xcodebuild -resolvePackageDependencies -project Intentional.xcodeproj

# Update packages (in Xcode): File → Packages → Update to Latest Package Versions
```

### Simulator Management
```bash
# Boot specific simulator - takes 30-60 seconds
xcrun simctl boot "iPhone 15"

# List running simulators
xcrun simctl list devices booted

# Reset simulator if issues occur
xcrun simctl erase "iPhone 15"

# Shutdown all simulators
xcrun simctl shutdown all
```

### Build Troubleshooting
```bash
# Clean build folder - takes 1-2 minutes
xcodebuild clean -project Intentional.xcodeproj -scheme Intentional

# Delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clear Swift package cache
rm -rf ~/Library/Caches/org.swift.swiftpm
```

## Repository Structure

This repository contains the "Intentional" iOS app - a complete session-based screen time control application using iOS Screen Time APIs:

```
/
├── Intentional.xcodeproj/         # Xcode project file
├── Package.swift                  # Swift Package Manager dependencies
├── Sources/
│   ├── App/                      # Main iOS app target (27 Swift files)
│   │   ├── IntentionalApp.swift   # App entry point with Firebase config
│   │   ├── Environment/           # Dependency injection container
│   │   ├── Features/             # Feature-based modules:
│   │   │   ├── Auth/             # Apple/Google/Email authentication
│   │   │   ├── Onboarding/       # Welcome flow & Family Controls permissions
│   │   │   ├── Quotas/           # App selection & quota management
│   │   │   ├── Today/            # Main dashboard with usage stats
│   │   │   ├── Session/          # Active session management & Live Activities
│   │   │   ├── Paywall/          # StoreKit 2 subscriptions & billing
│   │   │   ├── Logs/             # Usage history & analytics
│   │   │   └── Settings/         # User preferences & account management
│   │   └── Services/             # Core business logic:
│   │       ├── ScreenTime/       # FamilyControls, ManagedSettings APIs
│   │       ├── Persistence/      # Local storage + Firebase cloud sync
│   │       └── Notifications/    # Local notifications for sessions
│   ├── Extensions/               # Required App Extensions:
│   │   ├── DeviceActivityMonitorExtension/  # Monitor app usage events
│   │   ├── ShieldConfigurationExtension/    # Configure app blocking UI
│   │   └── ShieldActionExtension/           # Handle user actions on shields
│   └── Core/                     # Shared models and utilities
├── README.md                     # Project overview and setup instructions
├── DEVELOPMENT.md                # Detailed development guide
└── .gitignore                    # Git ignore rules for iOS/Xcode
```

### Key Technical Details
- **Minimum iOS**: 17.0+ (REQUIRED for latest Screen Time APIs)
- **Language**: Swift 5.9+ with SwiftUI
- **Architecture**: MVVM with dependency injection
- **Primary Frameworks**: 
  - FamilyControls (app selection & management)
  - ManagedSettings (app blocking configuration)
  - DeviceActivity (usage monitoring)
  - ActivityKit (Live Activities for countdown timers)
  - StoreKit 2 (subscriptions)
  - AuthenticationServices (Sign in with Apple)
- **Dependencies**: Firebase Auth, Firebase Firestore, Google Sign-In
- **Extensions Required**: 3 app extensions for Screen Time functionality
- **Bundle IDs**:
  - Main: `com.jlieb10.intentional`
  - DeviceActivityMonitor: `com.jlieb10.intentional.DeviceActivityMonitor`
  - ShieldConfiguration: `com.jlieb10.intentional.ShieldConfiguration`
  - ShieldAction: `com.jlieb10.intentional.ShieldAction`

## Timing Expectations and Timeouts

### CRITICAL Timing Information - NEVER CANCEL These Operations

**Build Operations:**
- **Clean build**: 15-20 minutes. NEVER CANCEL. Set timeout to 60+ minutes.
- **Incremental build**: 1-3 minutes. NEVER CANCEL. Set timeout to 10+ minutes.
- **All targets build**: 20-25 minutes. NEVER CANCEL. Set timeout to 90+ minutes.
- **Extension builds**: 5-10 minutes each. NEVER CANCEL. Set timeout to 30+ minutes per extension.

**Testing Operations:**
- **Unit tests**: 10-15 minutes. NEVER CANCEL. Set timeout to 45+ minutes.
- **Integration tests**: 15-25 minutes. NEVER CANCEL. Set timeout to 90+ minutes.
- **Full test suite**: 25-35 minutes. NEVER CANCEL. Set timeout to 120+ minutes.
- **Physical device tests**: 20-30 minutes. NEVER CANCEL. Set timeout to 90+ minutes.

**Dependency Resolution:**
- **Swift Package Manager**: 3-8 minutes. NEVER CANCEL. Set timeout to 30+ minutes.
- **Package cache reset**: 2-5 minutes. NEVER CANCEL. Set timeout to 20+ minutes.
- **First-time dependency fetch**: 10-15 minutes. NEVER CANCEL. Set timeout to 60+ minutes.

**Development Operations:**
- **Simulator boot**: 30-90 seconds. Set timeout to 5+ minutes.
- **App installation on device**: 2-5 minutes. NEVER CANCEL. Set timeout to 15+ minutes.
- **Xcode project opening**: 1-3 minutes for initial indexing.

### Recommended Minimum Timeout Values
- **Build commands**: 60+ minutes minimum
- **Test commands**: 90+ minutes minimum  
- **Package resolution**: 30+ minutes minimum
- **Device operations**: 15+ minutes minimum

### Why These Operations Take Time
- **Screen Time APIs**: Require complex entitlement verification
- **3 App Extensions**: Each built and signed separately
- **Firebase Dependencies**: Large framework compilation
- **SwiftUI Preview**: Compilation cache generation
- **Code Signing**: Multiple bundle ID validation

## Troubleshooting Common Issues

### Build Issues

#### Swift Package Manager Resolution Failure
```
Error: Package resolution failed / Dependencies could not be resolved
```
**Solution**:
```bash
# Clear all caches - takes 3-5 minutes. NEVER CANCEL. Set timeout to 20+ minutes.
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/org.swift.swiftpm
# Re-resolve in Xcode: File → Packages → Reset Package Caches
xcodebuild -resolvePackageDependencies -project Intentional.xcodeproj
```

#### Family Controls Entitlement Missing
```
Error: Provisioning profile doesn't include the Family Controls capability
```
**Solution**: 
- Request Family Controls entitlement from Apple Developer Portal (can take 1-2 weeks for approval)
- Ensure all bundle IDs have the entitlement enabled
- Regenerate provisioning profiles after entitlement approval

#### App Extensions Build Failure
```
Error: Extension bundle identifier does not match expected format
```
**Solution**:
```bash
# Verify bundle IDs match expected format:
# Main: com.jlieb10.intentional
# Extensions: com.jlieb10.intentional.[ExtensionName]
xcodebuild -showBuildSettings -project Intentional.xcodeproj | grep PRODUCT_BUNDLE_IDENTIFIER
```

#### Code Signing Issues
```
Error: Code signing failed / No valid provisioning profile found
```
**Solution**:
- Select development team for ALL targets (main app + 3 extensions)
- Ensure App Group ID exists: `group.com.jlieb10.intentional`
- Add App Group capability to all targets

### Runtime Issues

#### Screen Time APIs Not Working
**Symptoms**: Shield screens don't appear, apps not blocked, Family Controls authorization fails

**Solutions**:
- **CRITICAL**: Must use physical device (Screen Time APIs don't work in Simulator)
- Grant Family Controls permission: Settings → Screen Time → Family Controls
- Verify App Group container access
- Check system logs:
```bash
log stream --predicate 'subsystem == "com.apple.ScreenTimeAgent"'
```

#### Firebase Authentication Failures
**Symptoms**: Sign-in fails, cloud sync doesn't work

**Solutions**:
- Add `GoogleService-Info.plist` to Xcode project
- Verify Firebase project configuration
- Enable Authentication methods in Firebase Console
- Check network connectivity

#### Live Activities Not Appearing
**Symptoms**: Session countdowns don't show in Dynamic Island

**Solutions**:
- Ensure ActivityKit framework is linked
- Verify Live Activities entitlement is enabled
- Test on iOS 16.1+ device (required for Live Activities)
- Check notification permissions are granted

### Simulator Issues

#### Simulator Won't Boot
```bash
# Reset and restart simulator - takes 2-3 minutes
xcrun simctl shutdown all
xcrun simctl erase all
xcrun simctl boot "iPhone 15"
```

#### Simulator Performance Issues
```bash
# Reset simulator content and settings
xcrun simctl erase "iPhone 15"
# Or use: Device → Erase All Content and Settings in Simulator menu
```

## Special Requirements for Screen Time APIs

### CRITICAL Physical Device Requirements
**Screen Time APIs DO NOT WORK in iOS Simulator**. ALL Screen Time functionality testing MUST be done on physical device.

### Required Entitlements (Must Be Approved by Apple)
1. **Family Controls** - Request from Apple Developer Portal
2. **App Groups** - `group.com.jlieb10.intentional`  
3. **ActivityKit** - For Live Activities countdown timers

### Development Team Setup Requirements
1. **Apple Developer Program membership** (paid account required)
2. **Family Controls entitlement approval** (submit request to Apple, 1-2 weeks processing)
3. **Proper code signing** for all 4 targets (main app + 3 extensions)
4. **Physical iOS 17+ device** for testing

### Device Testing Checklist
Before testing ANY Screen Time functionality:
- [ ] Deploy to physical device (iOS 17+)
- [ ] Grant Family Controls permission in Settings → Screen Time → Family Controls
- [ ] Sign in to test cloud authentication
- [ ] Complete onboarding to select managed apps
- [ ] Test session start/end cycle with Live Activities
- [ ] Verify shield screens appear when apps are blocked

### Screen Time API Debugging
```bash
# Monitor Screen Time system logs on device
log stream --predicate 'subsystem == "com.apple.ScreenTimeAgent"'

# Check Family Controls authorization status  
log stream --predicate 'subsystem == "com.apple.FamilyControls"'

# Monitor extension activity
log stream --predicate 'subsystem CONTAINS "intentional"'
```

## Common Validation Workflows

### After Making Code Changes
ALWAYS run this complete validation sequence:

1. **Clean Build** (15-20 minutes):
   ```bash
   xcodebuild clean build -project Intentional.xcodeproj -scheme Intentional -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

2. **Unit Tests** (10-15 minutes):
   ```bash
   xcodebuild test -project Intentional.xcodeproj -scheme Intentional -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

3. **Physical Device Deploy and Test** (MANDATORY for Screen Time features):
   - Build and run on physical device
   - Test changed functionality manually
   - Verify Screen Time APIs still work correctly

4. **SwiftLint Check** (if configured):
   ```bash
   swiftlint
   ```

### Before Committing Changes
Run complete validation suite:
```bash
# Full clean build with all targets - takes 20-25 minutes. NEVER CANCEL. Set timeout to 90+ minutes.
xcodebuild clean build -project Intentional.xcodeproj -alltargets -destination 'platform=iOS Simulator,name=iPhone 15'

# Complete test suite - takes 25-35 minutes. NEVER CANCEL. Set timeout to 120+ minutes.
xcodebuild test -project Intentional.xcodeproj -scheme Intentional -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Key File Locations to Know

### Most Frequently Modified Files
- `Sources/App/IntentionalApp.swift` - App entry point and configuration
- `Sources/App/Features/*/` - All feature modules (Auth, Session, Today, etc.)
- `Sources/App/Services/ScreenTime/` - Core Screen Time API integration
- `Sources/App/Environment/` - Dependency injection and app state
- `Sources/Extensions/*/` - App extensions for Screen Time functionality

### Configuration Files
- `Package.swift` - Swift Package Manager dependencies
- `Intentional.xcodeproj/project.pbxproj` - Xcode project configuration
- `Sources/App/Environment/FirebaseConfig.swift` - Firebase setup
- `.gitignore` - Configured for iOS development

### Always Check These After Changes
- Verify all 4 targets still build successfully
- Test authentication flow on device
- Ensure Screen Time permissions still granted
- Validate Live Activities appear during sessions
- Check cloud sync still functions
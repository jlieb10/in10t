# IN10T - iOS Screen Time Control App

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Current Repository State
This repository contains a complete iOS app implementation with:
- IN10T.xcodeproj (Xcode project)
- 27 Swift source files across main app and 3 extensions
- Swift Package Manager dependencies (Firebase, Google Sign-In)
- Complete feature modules for Screen Time control functionality

## Working Effectively

### Initial Setup
ALWAYS run these commands in exact order:
1. **Clone and open repository**:
   ```bash
   # Replace <your-repository-url> with your fork or the canonical repo as appropriate
   git clone <your-repository-url>
   cd in10t
   open IN10T.xcodeproj
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
   xcodebuild -project IN10T.xcodeproj -scheme IN10T -destination 'platform=iOS Simulator,name=iPhone 15' build
   
   # Main app target - takes 10-15 minutes. NEVER CANCEL. Set timeout to 60+ minutes.
   # Timeout is set conservatively to account for possible delays in dependency resolution, network issues, or CI/CD resource contention.
   xcodebuild -project IN10T.xcodeproj -scheme IN10T -destination 'platform=iOS Simulator,name=iPhone 15' build
   
   # All targets including extensions - takes 15-20 minutes. NEVER CANCEL. Set timeout to 60+ minutes.
   # Timeout is set conservatively to account for possible delays in dependency resolution, network issues, or CI/CD resource contention.
   xcodebuild -project IN10T.xcodeproj -alltargets -destination 'platform=iOS Simulator,name=iPhone 15' build
   ```

### Testing
**CRITICAL**: Set timeout to 90+ minutes for test commands. NEVER CANCEL tests before completion.

1. **Unit Tests** (Simulator only):
   ```bash
   # Takes 5-10 minutes. NEVER CANCEL. Set timeout to 30+ minutes.
   xcodebuild test -project IN10T.xcodeproj -scheme IN10T -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

2. **Physical Device Testing** (REQUIRED for Screen Time APIs):
   ```bash
   # Replace iPhone-15 with your device name. Takes 10-15 minutes. NEVER CANCEL. Set timeout to 60+ minutes.
   xcodebuild test -project IN10T.xcodeproj -scheme IN10T -destination 'platform=iOS,name=Your-Device-Name'
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
   xcodebuild clean build -project IN10T.xcodeproj -scheme IN10T -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

2. **Test validation**:
   ```bash
   # Unit tests - takes 10-15 minutes. NEVER CANCEL. Set timeout to 45+ minutes.
   xcodebuild test -project IN10T.xcodeproj -scheme IN10T -destination 'platform=iOS Simulator,name=iPhone 15'
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
   xcodebuild -resolvePackageDependencies -project IN10T.xcodeproj
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
xcodebuild -list -project IN10T.xcodeproj

# Show build settings
xcodebuild -showBuildSettings -project IN10T.xcodeproj -target Intentional

# List available simulators
xcrun simctl list devices available
```

### Dependency Management
**CRITICAL**: Swift Package Manager is used (NOT CocoaPods/Carthage)

```bash
# Reset package cache if issues occur - takes 2-3 minutes. NEVER CANCEL. Set timeout to 10+ minutes.
rm -rf ~/Library/Developer/Xcode/DerivedData
xcodebuild -resolvePackageDependencies -project IN10T.xcodeproj

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
xcodebuild clean -project IN10T.xcodeproj -scheme IN10T

# Delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clear Swift package cache
rm -rf ~/Library/Caches/org.swift.swiftpm
```

## Repository Structure

This repository contains the "Intentional" iOS app - a complete session-based screen time control application using iOS Screen Time APIs:

```
/
├── IN10T.xcodeproj/         # Xcode project file
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
  - Main: `com.jlieb10.in10t`
  - DeviceActivityMonitor: `com.jlieb10.in10t.DeviceActivityMonitor`
  - ShieldConfiguration: `com.jlieb10.in10t.ShieldConfiguration`
  - ShieldAction: `com.jlieb10.in10t.ShieldAction`

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
xcodebuild -resolvePackageDependencies -project IN10T.xcodeproj
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
# Main: com.jlieb10.in10t
# Extensions: com.jlieb10.in10t.[ExtensionName]
xcodebuild -showBuildSettings -project IN10T.xcodeproj | grep PRODUCT_BUNDLE_IDENTIFIER
```

#### Code Signing Issues
```
Error: Code signing failed / No valid provisioning profile found
```
**Solution**:
- Select development team for ALL targets (main app + 3 extensions)
- Ensure App Group ID exists: `group.com.jlieb10.in10t`
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
2. **App Groups** - `group.com.jlieb10.in10t`  
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
   xcodebuild clean build -project IN10T.xcodeproj -scheme IN10T -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

2. **Unit Tests** (10-15 minutes):
   ```bash
   xcodebuild test -project IN10T.xcodeproj -scheme IN10T -destination 'platform=iOS Simulator,name=iPhone 15'
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
xcodebuild clean build -project IN10T.xcodeproj -alltargets -destination 'platform=iOS Simulator,name=iPhone 15'

# Complete test suite - takes 25-35 minutes. NEVER CANCEL. Set timeout to 120+ minutes.
xcodebuild test -project IN10T.xcodeproj -scheme IN10T -destination 'platform=iOS Simulator,name=iPhone 15'
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
- `IN10T.xcodeproj/project.pbxproj` - Xcode project configuration
- `Sources/App/Environment/FirebaseConfig.swift` - Firebase setup
- `.gitignore` - Configured for iOS development

### Always Check These After Changes
- Verify all 4 targets still build successfully
- Test authentication flow on device
- Ensure Screen Time permissions still granted
- Validate Live Activities appear during sessions
- Check cloud sync still functions

## Quick Reference Commands

### Essential Build Commands (Copy-Paste Ready)
```bash
# Clean build everything - takes 20-25 minutes. NEVER CANCEL. Set timeout to 90+ minutes.
xcodebuild clean build -project IN10T.xcodeproj -alltargets -destination 'platform=iOS Simulator,name=iPhone 15'

# Run unit tests - takes 10-15 minutes. NEVER CANCEL. Set timeout to 45+ minutes.
xcodebuild test -project IN10T.xcodeproj -scheme IN10T -destination 'platform=iOS Simulator,name=iPhone 15'

# Build for physical device - takes 15-20 minutes. NEVER CANCEL. Set timeout to 60+ minutes.
xcodebuild build -project IN10T.xcodeproj -scheme IN10T -destination 'generic/platform=iOS'

# Clear all caches when build issues occur - takes 3-5 minutes. NEVER CANCEL. Set timeout to 20+ minutes.
rm -rf ~/Library/Developer/Xcode/DerivedData && rm -rf ~/Library/Caches/org.swift.swiftpm && xcodebuild -resolvePackageDependencies -project IN10T.xcodeproj
```

### Project Inspection Commands
```bash
# List all available schemes and targets
xcodebuild -list -project IN10T.xcodeproj

# Show build settings for main target
xcodebuild -showBuildSettings -project IN10T.xcodeproj -target Intentional

# List available simulators
xcrun simctl list devices available | grep iPhone

# Check bundle identifiers for all targets
xcodebuild -showBuildSettings -project IN10T.xcodeproj | grep PRODUCT_BUNDLE_IDENTIFIER
```

## Development Tips

### When Adding New Features
1. Always add to appropriate feature module under `Sources/App/Features/`
2. Follow MVVM pattern - create View, ViewModel, and Model files
3. Add to dependency injection container in `Sources/App/Environment/`
4. Update unit tests if test infrastructure exists
5. Test on physical device if feature uses Screen Time APIs

### When Modifying Screen Time Functionality
1. **ALWAYS test on physical device** - Screen Time APIs don't work in Simulator
2. Check that Family Controls authorization is still granted
3. Verify App Group container access still works
4. Test all 3 app extensions still function correctly
5. Monitor system logs for Screen Time API errors

### When Working with Authentication
1. Test all auth providers: Apple, Google, Email
2. Verify Firebase configuration in `GoogleService-Info.plist`  
3. Test sign-out/sign-in flow to ensure data persistence
4. Check cloud sync functionality after auth changes
5. Test account deletion flow if modified

### When Updating Dependencies
1. Always use Xcode's Package Manager UI: File → Packages → Update to Latest Package Versions
2. Test build after dependency updates - takes 15-25 minutes for clean build
3. Verify Firebase and Google Sign-In still work after updates
4. Check for breaking API changes in updated dependencies
5. Test on physical device to ensure Screen Time APIs still function

### Common File Operations Reference
```bash
# Find all Swift files in project
find Sources -name "*.swift" | wc -l

# Search for specific functionality
grep -r "FamilyControls" Sources/
grep -r "Firebase" Sources/

# View project structure 
tree Sources/ -d

# Check git status and recent changes
git status && git log --oneline -10
```

## Emergency Troubleshooting

### When Nothing Builds
1. Clean everything: `xcodebuild clean -project IN10T.xcodeproj`
2. Quit Xcode completely
3. Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`  
4. Clear SPM cache: `rm -rf ~/Library/Caches/org.swift.swiftpm`
5. Restart Xcode and let it re-index
6. Reset Package Cache: File → Packages → Reset Package Caches
7. Try build again (takes 20-25 minutes)

### When Screen Time APIs Stop Working
1. Verify physical device is being used (not Simulator)
2. Check Family Controls permission: Settings → Screen Time → Family Controls
3. Verify App Group: `group.com.jlieb10.in10t` exists and is enabled
4. Check all bundle IDs are correctly signed with development team
5. Try deleting and reinstalling app on device
6. Check Apple Developer Portal for entitlement status

### When Tests Fail After Changes
1. Run individual test to isolate failure
2. Check if failure is simulator vs device specific  
3. Verify authentication flow still works (many tests depend on it)
4. Check if Firebase configuration is correct
5. Run clean build before running tests again
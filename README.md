# IN10T - Session-Based Screen Time Control

Transform your relationship with technology through mindful, session-based app usage.

![iOS](https://img.shields.io/badge/iOS-17.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Overview

IN10T is a comprehensive iOS app that helps users build healthy screen time habits through:

- **Session-based app control** using iOS Screen Time APIs
- **Live Activity countdown timers** in Dynamic Island and Lock Screen
- **Freemium model** with StoreKit 2 subscriptions
- **Multi-provider authentication** (Apple, Google, Email)
- **Cloud sync** with Firebase/Supabase for data persistence

## Architecture

The app follows a clean MVVM architecture with SwiftUI and leverages iOS 17's latest APIs:

### Core Components

- **Main App**: SwiftUI-based interface with tab navigation
- **Extensions**: DeviceActivityMonitor, ShieldConfiguration, ShieldAction
- **Live Activities**: Dynamic Island and Lock Screen countdown display
- **Screen Time Integration**: FamilyControls for app selection, ManagedSettings for blocking
- **Cloud Storage**: Encrypted user data with indefinite retention

### Technical Stack

- **Platform**: iOS 17.0+ (required for latest Screen Time APIs)
- **Language**: Swift 5.9+ with SwiftUI
- **Architecture**: MVVM with Dependency Injection
- **Key Frameworks**:
  - FamilyControls, ManagedSettings, DeviceActivity
  - ActivityKit (Live Activities)
  - StoreKit 2 (Subscriptions)
  - AuthenticationServices (Sign in with Apple)
  - Firebase/Supabase (Cloud storage)

## Features

### Core Functionality
- [x] Session-based app usage control
- [x] Live Activity countdown timers 
- [x] Daily quota management with streak tracking
- [x] Shield gates with intention setting
- [x] Grace time for Pro users
- [x] Multi-app management

### Authentication & Sync
- [x] Sign in with Apple
- [x] Google Sign-In integration
- [x] Email/password authentication
- [x] Cloud data synchronization
- [x] Account deletion with data export

### Monetization
- [x] Freemium model (1 app, 10min sessions, 1x/day)
- [x] Pro subscription (unlimited apps, custom durations)
- [x] StoreKit 2 implementation
- [x] 7-day free trial
- [x] Subscription management

## Project Structure

```
IN10T/
├── IN10T.xcodeproj/               # Xcode project
├── Package.swift                  # Swift Package Manager
├── Sources/
│   ├── App/                      # Main iOS app
│   │   ├── Environment/          # DI container, app groups
│   │   ├── Features/            # Feature modules
│   │   │   ├── Auth/            # Authentication
│   │   │   ├── Onboarding/      # Welcome flow
│   │   │   ├── Quotas/          # App management
│   │   │   ├── Today/           # Main dashboard
│   │   │   ├── Session/         # Active sessions
│   │   │   ├── Paywall/         # Subscriptions
│   │   │   ├── Logs/            # Usage history
│   │   │   └── Settings/        # User preferences
│   │   └── Services/           # Core services
│   │       ├── ScreenTime/     # Screen Time APIs
│   │       ├── Persistence/    # Local + Cloud storage
│   │       └── Notifications/  # Local notifications
│   ├── Extensions/             # App Extensions
│   │   ├── DeviceActivityMonitorExtension/
│   │   ├── ShieldConfigurationExtension/
│   │   └── ShieldActionExtension/
│   ├── Widgets/               # Home Screen widgets
│   └── Core/                  # Shared models
├── Tests/                     # Unit and UI tests
├── fastlane/                  # Deployment automation
└── README.md
```

## Quick Start Guide

**New to iOS development? Follow this path:**

```
1. Setup Environment (30 min)
   ↓
2. Clone & Explore (15 min)  
   ↓
3. Request Entitlements (5 min + 1-2 weeks wait)
   ↓
4. Configure Services (60 min)
   ↓ 
5. First Build (30 min)
   ↓
6. Test Basic Features (30 min)
   ↓
7. Wait for Entitlements ⏳
   ↓
8. Test Screen Time Features (60 min)
```

**Parallel track while waiting for entitlements:**
- Develop UI components
- Implement authentication
- Build subscription flow
- Create tests
- Design app icon and assets

1. ✅ **Setup environment** (30 minutes): Install Xcode, create Apple Developer account
2. ✅ **Clone and explore** (15 minutes): Download code, open in Xcode, explore structure  
3. ✅ **Request entitlements** (5 minutes to submit, 1-2 weeks processing): Submit Family Controls request
4. ✅ **Configure services** (60 minutes): Set up Firebase, App Store Connect while waiting for entitlement
5. ✅ **First build** (30 minutes): Configure Bundle IDs, build for device
6. ✅ **Test basic features** (30 minutes): Authentication, UI navigation, subscription flow
7. ⏳ **Wait for entitlements**: Continue UI development until Apple approves Family Controls
8. ✅ **Test Screen Time features** (60 minutes): Full functionality testing after approval

**Total setup time**: ~3 hours active work + 1-2 weeks waiting

**💡 Pro Tips:**
- Start with entitlement request first (longest wait time)
- Use sandbox Apple ID for subscription testing
- Keep physical device connected during development
- Save all configuration values (Bundle IDs, Firebase keys) in a note

## Table of Contents

- [Overview](#overview)
- [Quick Start Guide](#quick-start-guide)
- [Features](#features)
- [Project Structure](#project-structure)
- [Setup Instructions](#setup-instructions)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Building and Running](#building-and-running)
  - [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Usage Flow](#usage-flow)
- [Development Notes](#development-notes)
- [Contributing](#contributing)

## Setup Instructions

### Prerequisites

### Prerequisites

**What you'll need before starting:**

1. **Mac computer** running macOS 13.0+ (required for Xcode 15)
2. **Xcode 15.0+** ([Download from Mac App Store](https://apps.apple.com/app/xcode/id497799835))
3. **Apple Developer Account** ([Sign up at developer.apple.com](https://developer.apple.com/programs/))
   - **Individual**: $99/year
   - **Organization**: $99/year
   - Required for Family Controls entitlement and App Store submission
4. **Physical iPhone** running iOS 17.0+ 
   - Screen Time APIs don't work in iOS Simulator
   - Must be connected for testing and development
5. **Basic knowledge helpful** (but not required):
   - Xcode interface basics
   - Understanding of Bundle IDs and App Store Connect
   - iOS app development concepts

**Estimated setup time**: 2-3 hours (plus 1-2 weeks for Apple entitlement approval)

**Don't have some prerequisites?**
- **No Apple Developer Account**: You can still clone and explore the code, but won't be able to run on device
- **No iOS 17+ device**: Consider upgrading or borrowing a device - Simulator won't work for Screen Time features
- **New to Xcode**: Consider completing Apple's [Xcode tutorial](https://developer.apple.com/tutorials/app-dev-training/) first

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/jlieb10/in10t.git
   cd in10t
   ```

2. **Open in Xcode**:
   ```bash
   open IN10T.xcodeproj
   ```

3. **Configure Bundle Identifiers** (Detailed in [DEVELOPMENT.md - Bundle ID Setup](DEVELOPMENT.md#bundle-id-setup)):
   
   Bundle Identifiers uniquely identify your app and its extensions. You'll need to configure these in both Xcode and Apple Developer Portal:
   
   **In Xcode:**
   - Select your project in the navigator → Select each target → General tab → Bundle Identifier
   - **Main app**: `com.jlieb10.in10t` (or use your own domain like `com.yourname.in10t`)
   - **DeviceActivityMonitor**: `com.jlieb10.in10t.DeviceActivityMonitor`
   - **ShieldConfiguration**: `com.jlieb10.in10t.ShieldConfiguration`
   - **ShieldAction**: `com.jlieb10.in10t.ShieldAction`
   
   **In Apple Developer Portal** ([developer.apple.com/account/resources/identifiers](https://developer.apple.com/account/resources/identifiers)):
   - Click the "+" button to create new App IDs for each bundle identifier above
   - Enable required capabilities for each (see DEVELOPMENT.md for detailed instructions)

4. **Set up App Groups** (Detailed in [DEVELOPMENT.md - App Groups Setup](DEVELOPMENT.md#app-groups-setup)):
   
   App Groups allow your main app and extensions to share data:
   
   **In Apple Developer Portal** ([developer.apple.com/account/resources/identifiers](https://developer.apple.com/account/resources/identifiers)):
   - Go to "Identifiers" → Select "App Groups" → Click "+" 
   - Create App Group: `group.com.jlieb10.in10t` (or use your domain)
   - Description: "IN10T App Group for data sharing"
   
   **In Xcode:**
   - Select each target → Signing & Capabilities → Click "+ Capability" 
   - Add "App Groups" capability
   - Check the box for `group.com.jlieb10.in10t`
   - **Must be added to ALL 4 targets** (main app + 3 extensions)

5. **Configure Entitlements** (Detailed in [DEVELOPMENT.md - Entitlements Guide](DEVELOPMENT.md#entitlements-guide)):
   
   Family Controls is a restricted entitlement that requires Apple approval:
   
   **Request Family Controls Entitlement:**
   - Visit [Apple Developer Portal - Additional Capabilities](https://developer.apple.com/contact/request/family-controls/)
   - Submit request with justification for Screen Time API usage
   - **⏰ Processing time: 1-2 weeks**
   - You'll receive email confirmation when approved
   
   **Add to Xcode (after approval):**
   - Main app target → Signing & Capabilities → "+ Capability" → "Family Controls"
   - Extensions don't need this capability, only the main app

6. **Set up Firebase** (Detailed in [DEVELOPMENT.md - Firebase Setup](DEVELOPMENT.md#firebase-setup)):
   
   Firebase provides authentication and cloud storage for the app:
   
   **Create Firebase Project:**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Click "Create a project" → Name it "IN10T" or similar
   - Disable Google Analytics (optional for this project)
   - Click "Create project"
   
   **Add iOS App:**
   - Click "Add app" → Select iOS icon
   - **iOS bundle ID**: `com.jlieb10.in10t` (must match your main app bundle ID)
   - App nickname: "IN10T" (optional)
   - Skip App Store ID for now
   
   **Download Configuration File:**
   - Download `GoogleService-Info.plist` file
   - **In Xcode**: Drag the file to your project root (same level as Sources folder)
   - ✅ Check "Add to target" for the main app target
   - ✅ Ensure "Copy items if needed" is checked
   
   **Enable Firebase Services:**
   - In Firebase Console → Build section:
     - **Authentication**: Enable → Sign-in method → Enable Apple, Google, Email/Password
     - **Firestore Database**: Create database → Start in production mode → Choose location
   
   **Get Google Sign-In Configuration:**
   - Authentication → Sign-in method → Google → Copy "Web client ID"
   - You'll need this for Google Sign-In setup (saved in `GoogleService-Info.plist`)

7. **Configure Subscription Products** (Detailed in [DEVELOPMENT.md - Subscription Setup](DEVELOPMENT.md#subscription-setup)):
   
   Set up in-app purchases for the Pro subscription:
   
   **App Store Connect Setup** ([appstoreconnect.apple.com](https://appstoreconnect.apple.com)):
   - My Apps → Create new app or select existing
   - **Bundle ID**: Select `com.jlieb10.in10t` from dropdown
   - Complete basic app information
   
   **Create Subscription Group:**
   - Features → In-App Purchases → Manage → Create Subscription Group
   - **Name**: "IN10T Pro Subscription"
   - **Reference Name**: "intentional_pro_group"
   
   **Create Subscription Products:**
   
   **Monthly Subscription:**
   - Create Auto-Renewable Subscription
   - **Product ID**: `intentional_pro_monthly`
   - **Reference Name**: "IN10T Pro Monthly"
   - **Subscription Group**: Select the group created above
   - **Price**: £4.99/month (or your preferred price)
   - **Subscription Duration**: 1 Month
   
   **Annual Subscription:**
   - **Product ID**: `intentional_pro_annual`
   - **Reference Name**: "IN10T Pro Annual"
   - **Price**: £29.99/year (or your preferred price)
   - **Subscription Duration**: 1 Year
   
   **Add Free Trial (Both Products):**
   - Subscription Pricing → Introductory Offers
   - **Offer Type**: Free
   - **Duration**: 1 Week (7 days)
   - **Applies to**: New subscribers only
   
   **⚠️ Important**: Products must be submitted for review before testing

### Building and Running

After completing the setup steps above, you're ready to build and test:

1. **Connect your iPhone**:
   - Use Lightning/USB-C cable to connect to your Mac
   - Trust the computer if prompted on your iPhone
   - In Xcode: Window → Devices and Simulators → Verify your device appears

2. **Select your device**:
   - In Xcode toolbar, click the device dropdown (next to scheme)
   - Select your connected iPhone (not "iOS Simulator")

3. **Build and run**:
   - Click ▶️ (Run) button or press ⌘+R
   - **First build takes 5-10 minutes** (downloading Firebase dependencies)
   - App will install and launch on your iPhone

4. **Grant permissions** (first launch):
   - **Family Controls**: Settings → Screen Time → Family Controls → Toggle ON
   - **Notifications**: Allow when prompted
   - **Sign in**: Test with Apple ID, Google, or email

5. **Test core functionality**:
   - Complete onboarding flow
   - Select apps using FamilyActivityPicker
   - Start a session and verify Live Activities appear
   - Try opening a blocked app to see shield screen

**⚠️ Common First Build Issues:**

**"Failed to register bundle identifier":**
- Your Bundle ID conflicts with existing app
- Solution: Change Bundle IDs to use your own domain (e.g., `com.yourname.in10t`)

**"Provisioning profile doesn't include Family Controls":**
- Family Controls entitlement not approved yet
- Solution: Submit request to Apple (takes 1-2 weeks) or continue without Screen Time features

**"No development team selected":**
- Select your Apple Developer account in Signing & Capabilities
- Solution: Project → Target → Signing & Capabilities → Team dropdown

**Build takes forever:**
- First build downloads Firebase (~100MB) and other dependencies
- Solution: Be patient, subsequent builds are much faster (30 seconds)

For more detailed troubleshooting, see [DEVELOPMENT.md - Troubleshooting](#troubleshooting).

### Testing

**🚨 CRITICAL: Screen Time APIs require a physical iOS 17+ device**

Screen Time APIs (FamilyControls, ManagedSettings, DeviceActivity) do not work in iOS Simulator. All Screen Time functionality must be tested on a real iPhone or iPad.

#### Quick Build Verification

```bash
# Navigate to project directory
cd /path/to/in10t

# Build for simulator (basic functionality only)
xcodebuild -project IN10T.xcodeproj -scheme IN10T -destination 'platform=iOS Simulator,name=iPhone 15' build

# Build for physical device (full functionality) 
xcodebuild -project IN10T.xcodeproj -scheme IN10T -destination 'generic/platform=iOS' build

# Run unit tests (if available)
xcodebuild test -project IN10T.xcodeproj -scheme IN10T -destination 'platform=iOS Simulator,name=iPhone 15'
```

#### Manual Testing Checklist (Physical Device Required)

**Basic App Functionality:**
1. ✅ App launches without crashes
2. ✅ Firebase configuration loads (check Xcode console for Firebase messages)
3. ✅ Authentication screens appear
4. ✅ Can create account with Apple/Google/Email

**Screen Time Integration:**
5. ✅ Family Controls permission can be requested (Settings → Screen Time → Family Controls)
6. ✅ App selection screen (FamilyActivityPicker) works without errors
7. ✅ Can select multiple apps and save configuration
8. ✅ Sessions can be started/stopped

**Live Activities & Blocking:**
9. ✅ Live Activities appear in Dynamic Island during active sessions
10. ✅ Shield screens appear when trying to open blocked apps
11. ✅ Session countdowns work correctly
12. ✅ Apps become accessible again after session ends

**Cloud Sync & Subscriptions:**
13. ✅ Data syncs when signing out and back in
14. ✅ Subscription purchase flow works (use sandbox account)
15. ✅ Pro features unlock after subscription

#### Testing Without Family Controls Entitlement

If your Family Controls entitlement isn't approved yet, you can still test most features:

**Working features:**
- Authentication and user accounts
- Firebase cloud sync
- App UI and navigation
- Subscription purchase flow
- Settings and preferences

**Non-working features (will show errors):**
- App selection with FamilyActivityPicker
- Actual app blocking/shields
- Live Activities for sessions
- DeviceActivity monitoring

**Mock testing approach:**
- Use the app's UI to navigate through all screens
- Test authentication and account creation
- Verify Firebase data storage
- Test subscription flow with sandbox account
- The app should handle Family Controls errors gracefully

#### Performance Testing

**Memory Usage:**
- Monitor memory usage in Xcode (Debug → Memory)
- App should use <100MB under normal operation
- Watch for memory leaks during session management

**Battery Impact:**
- Test with iOS Settings → Battery → Battery Usage
- Screen Time monitoring should have minimal background impact
- Live Activities should not significantly drain battery

#### Debugging Screen Time Issues

If Screen Time features aren't working:

1. **Check device compatibility**:
   - iOS 17.0+ required
   - Physical device (not Simulator)
   - Family Controls permission granted in Settings

2. **Verify entitlements**:
   ```bash
   # Check if Family Controls entitlement is present
   codesign -d --entitlements - /path/to/your/app.ipa
   ```

3. **Monitor system logs**:
   ```bash
   # Connect iPhone to Mac, open Console.app
   # Filter for "ScreenTime" or "FamilyControls"
   # Look for authorization and API call errors
   ```

4. **Test incremental functionality**:
   - Start with basic FamilyControls authorization
   - Test app selection without saving
   - Test session creation without blocking
   - Test Live Activities separately

For comprehensive debugging guides, see [DEVELOPMENT.md - Debugging Screen Time Issues](#debugging-screen-time-issues).

## Troubleshooting

### Common Setup Issues

#### "Cannot find Xcode project"
**Symptoms**: `xcodebuild: error: 'IN10T.xcodeproj' does not exist`

**Solutions**:
- Ensure you're in the correct directory: `cd /path/to/in10t`
- Use the correct project name: `IN10T.xcodeproj` (not `Intentional.xcodeproj`)
- List files to verify: `ls -la *.xcodeproj`

#### "No development team selected"
**Symptoms**: Build fails with signing errors

**Solutions**:
1. **In Xcode**: Project → Each Target → Signing & Capabilities
2. **Team**: Select your Apple Developer account from dropdown
3. **Bundle Identifier**: Ensure it matches your Apple Developer Portal App IDs
4. **Automatically manage signing**: Should be checked
5. **Do this for ALL 4 targets** (main app + 3 extensions)

#### "Provisioning profile doesn't include the Family Controls capability"
**Symptoms**: Build succeeds but Family Controls features don't work

**Root cause**: Family Controls entitlement not approved by Apple yet

**Solutions**:
- **Short-term**: Continue development without Screen Time features
- **Long-term**: Submit Family Controls entitlement request (takes 1-2 weeks)
- **Testing**: Use mock data and UI testing until approval

#### "GoogleService-Info.plist not found"
**Symptoms**: Firebase authentication doesn't work

**Solutions**:
1. **Download again**: Firebase Console → Project Settings → Your app → Download plist
2. **Add to Xcode**: Right-click project root → Add Files → Select plist file
3. **Target membership**: Check ONLY main app target (not extensions)
4. **Location**: Should be at project root level, not in Sources folder

#### "Failed to resolve package dependencies"
**Symptoms**: Build hangs or fails during dependency resolution

**Solutions**:
```bash
# Clear Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clear Swift Package Manager cache
rm -rf ~/Library/Caches/org.swift.swiftpm

# In Xcode: File → Packages → Reset Package Caches
```

### Runtime Issues

#### Family Controls Authorization Fails
**Symptoms**: App crashes or shows errors when requesting Family Controls permission

**Debugging steps**:
1. **Check entitlement status**: Verify Apple approved your Family Controls request
2. **Physical device**: Ensure testing on real iPhone/iPad (not Simulator)
3. **iOS version**: Requires iOS 17.0+
4. **System settings**: Settings → Screen Time → Family Controls should be available

#### App Selection Screen (FamilyActivityPicker) Doesn't Appear
**Common causes**:
- **Simulator usage**: Screen Time APIs don't work in Simulator
- **Missing entitlement**: Family Controls not approved
- **Wrong authorization**: FamilyControls authorization not granted

**Solutions**:
- Test on physical device only
- Check Xcode console for FamilyControls error messages
- Verify authorization code is correct (see `Sources/App/Services/ScreenTime/`)

#### Firebase Authentication Not Working
**Debugging steps**:
1. **Check console logs**: Look for Firebase initialization messages
2. **Bundle ID mismatch**: Firebase project must match Xcode Bundle ID exactly
3. **GoogleService-Info.plist**: Must be added to main app target only
4. **Network**: Ensure device has internet connection

#### Live Activities Don't Appear
**Requirements for Live Activities**:
- iOS 16.1+ (for basic Live Activities)
- iOS 17.0+ (for enhanced Dynamic Island features)
- ActivityKit entitlement enabled
- Notifications permission granted

**Solutions**:
- Check iOS version compatibility
- Verify ActivityKit is linked in project
- Test notification permissions

#### Shield Screens Don't Block Apps
**Common causes**:
- Extensions not properly configured
- App Groups not set up correctly
- Bundle IDs mismatch between targets

**Solutions**:
1. **Verify all 4 bundle IDs** are correct and match Apple Developer Portal
2. **Check App Groups**: All targets must have `group.com.jlieb10.in10t`
3. **Extension signing**: All extensions must be signed with same team

### Development Environment Issues

#### Xcode Won't Open Project
**Symptoms**: Double-clicking project file does nothing or shows errors

**Solutions**:
1. **Command line**: `open IN10T.xcodeproj` from terminal
2. **Xcode version**: Ensure Xcode 15.0+ is installed
3. **Permissions**: Check file permissions: `ls -la IN10T.xcodeproj`
4. **Corruption**: Re-clone the repository if project file is corrupted

#### Build Takes Forever
**Normal behavior on first build**:
- Firebase SDK download: ~100MB
- Google Sign-In dependencies
- Swift Package Manager resolution
- **Expected time**: 5-10 minutes on first build

**Solutions**:
- Be patient on first build
- Subsequent builds should take 30-60 seconds
- Use faster internet connection if available
- Close other Xcode projects to free up resources

#### "Source control operation failed"
**Symptoms**: Git operations fail in Xcode

**Solutions**:
```bash
# Check git status
git status

# Reset git state if needed
git reset --hard HEAD

# Clear Xcode source control cache
rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages
```

### Device-Specific Issues

#### iPhone Not Recognized by Xcode
**Solutions**:
1. **Trust computer**: Unlock iPhone → Trust this computer when prompted
2. **Update iOS**: Ensure iOS 17.0+
3. **Cable**: Try different Lightning/USB-C cable
4. **Restart**: Restart both Mac and iPhone
5. **Xcode refresh**: Window → Devices and Simulators → Refresh

#### App Crashes on Device Launch
**Debugging steps**:
1. **Console.app**: Monitor crash logs on Mac
2. **Xcode logs**: View debug output in Xcode console
3. **Provisioning**: Ensure app is properly signed
4. **Dependencies**: Verify all frameworks are embedded

### Getting Help

If you're still stuck after trying these solutions:

1. **Check existing issues**: [GitHub Issues](https://github.com/jlieb10/in10t/issues)
2. **Create new issue**: Include error messages, Xcode version, iOS version, device model
3. **Join discussions**: [GitHub Discussions](https://github.com/jlieb10/in10t/discussions)
4. **Apple forums**: For Xcode-specific issues: [Apple Developer Forums](https://developer.apple.com/forums/)

**When reporting issues, include**:
- Xcode version
- iOS version
- Device model
- Error messages (exact text)
- Steps to reproduce
- Whether Family Controls entitlement is approved

## Usage Flow

### Initial Setup
1. User signs in (Apple/Google/Email)
2. Grants Family Controls permission
3. Selects apps to manage using FamilyActivityPicker
4. Configures session quotas (duration, daily limit, intention)

### Daily Usage
1. User opens managed app → Shield gate appears
2. User sets intention and starts session
3. Live Activity shows countdown in Dynamic Island/Lock Screen
4. App access granted for configured duration
5. Session automatically ends, shields re-enabled
6. Usage tracked for streak calculation

### Freemium → Pro Upgrade
- Free users hit limits → Paywall presented
- 7-day trial → Full Pro access
- Subscription managed via App Store

## Development Notes

### Screen Time API Limitations
- **Physical device required**: APIs don't work in iOS Simulator
- **Family Controls entitlement**: Must be requested from Apple
- **User privacy**: Cannot access app content, only usage tokens
- **System enforcement**: Shields managed by iOS, not the app

### Architecture Decisions
- **App Groups**: Required for data sharing with extensions
- **MVVM + SwiftUI**: Modern iOS development best practices
- **Dependency Injection**: Testable and maintainable code
- **Cloud-first**: Data persistence with offline fallback

### Testing Strategy
- **Unit Tests**: Business logic and data models
- **Integration Tests**: API interactions and data flow
- **Manual Testing**: Screen Time functionality on device
- **TestFlight**: Beta testing with real users

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support & Resources

### Documentation
- **Setup Guide**: This README covers basic setup and common issues
- **Advanced Development**: [DEVELOPMENT.md](DEVELOPMENT.md) has detailed technical guides  
- **Apple Documentation**: 
  - [Family Controls Framework](https://developer.apple.com/documentation/familycontrols)
  - [Screen Time API Guide](https://developer.apple.com/documentation/screentime)
  - [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit)

### Getting Help
- **Issues**: Report bugs and feature requests via [GitHub Issues](https://github.com/jlieb10/in10t/issues)  
- **Discussions**: Join the conversation in [GitHub Discussions](https://github.com/jlieb10/in10t/discussions)
- **Apple Support**: [Apple Developer Forums](https://developer.apple.com/forums/) for Xcode and iOS issues

### Community Resources
- **Firebase Documentation**: [firebase.google.com/docs](https://firebase.google.com/docs)
- **SwiftUI Tutorials**: [Apple's SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- **iOS Development**: [Apple Developer Documentation](https://developer.apple.com/documentation/)

### Quick Reference
- **Bundle IDs**: `com.jlieb10.in10t` (main), `.DeviceActivityMonitor`, `.ShieldConfiguration`, `.ShieldAction`
- **App Group**: `group.com.jlieb10.in10t`
- **Subscription IDs**: `intentional_pro_monthly`, `intentional_pro_annual`
- **Minimum iOS**: 17.0+
- **Xcode Version**: 15.0+

---

Built with ❤️ for intentional technology use
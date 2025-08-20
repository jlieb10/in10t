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

## Setup Instructions

### Prerequisites

1. **Xcode 15.0+** with iOS 17.0+ SDK
2. **Apple Developer Program** membership (required for Family Controls entitlement)
3. **Physical iOS device** (Screen Time APIs don't work in Simulator)

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

3. **Configure Bundle Identifiers**:
   - Main app: `com.jlieb10.in10t`
   - DeviceActivityMonitor: `com.jlieb10.in10t.DeviceActivityMonitor`
   - ShieldConfiguration: `com.jlieb10.in10t.ShieldConfiguration`
   - ShieldAction: `com.jlieb10.in10t.ShieldAction`

4. **Set up App Groups**:
   - Create App Group: `group.com.jlieb10.in10t`
   - Add to all targets in Capabilities

5. **Configure Entitlements**:
   - Request **Family Controls** entitlement from Apple Developer Portal
   - Add to main app target capabilities

6. **Set up Firebase** (for authentication and cloud storage):
   - Create Firebase project
   - Add `GoogleService-Info.plist` to project
   - Enable Authentication and Firestore

7. **Configure Subscription Products**:
   - Create products in App Store Connect:
     - `intentional_pro_monthly`: £4.99/month
     - `intentional_pro_annual`: £29.99/year
   - Set up 7-day free trial

### Building and Running

1. **Select a physical device** (required for Screen Time APIs)
2. **Build and run** the main target
3. **Grant permissions** when prompted:
   - Family Controls authorization
   - Notification permissions
   - Sign in to test cloud sync

### Testing

**🚨 IMPORTANT: Screen Time APIs require a physical iOS device (iOS 17+)**

```bash
# Build for simulator (limited functionality)
xcodebuild -project IN10T.xcodeproj -scheme IN10T -destination 'platform=iOS Simulator,name=iPhone 15' build

# Build for physical device (full functionality) 
xcodebuild -project IN10T.xcodeproj -scheme IN10T -destination 'generic/platform=iOS' build

# Run unit tests
xcodebuild test -project IN10T.xcodeproj -scheme IN10T -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Manual Testing Checklist:**
1. ✅ App launches without crashes
2. ✅ Firebase configuration loads (check console logs)
3. ✅ Authentication screens appear
4. ✅ Family Controls permission can be requested
5. ✅ App selection screen (FamilyActivityPicker) works
6. ✅ Sessions can be started/stopped
7. ✅ Live Activities appear during sessions
8. ✅ Shield screens block selected apps

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

## Support

- **Documentation**: See [DEVELOPMENT.md](DEVELOPMENT.md) and this README
- **Issues**: Report bugs and feature requests via [GitHub Issues](https://github.com/jlieb10/in10t/issues)  
- **Discussions**: Join the conversation in [GitHub Discussions](https://github.com/jlieb10/in10t/discussions)

---

Built with ❤️ for intentional technology use
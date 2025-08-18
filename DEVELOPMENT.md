# Development Setup Guide

## Prerequisites

### Required Tools
- **Xcode 15.0+** with iOS 17.0+ SDK
- **Apple Developer Program** membership
- **Physical iOS device** for testing (Screen Time APIs don't work in Simulator)

### Optional Tools
- **SwiftLint**: `brew install swiftlint`
- **Fastlane**: `gem install fastlane`

## Initial Setup

### 1. Apple Developer Configuration

#### App Identifiers
Create the following App IDs in Apple Developer Portal:
- `com.jlieb10.intentional` (Main App)
- `com.jlieb10.intentional.DeviceActivityMonitor`
- `com.jlieb10.intentional.ShieldConfiguration`  
- `com.jlieb10.intentional.ShieldAction`

#### Entitlements
- **Family Controls**: Request this restricted entitlement from Apple
- **App Groups**: `group.com.jlieb10.intentional`
- **Associated Domains**: If implementing Safari extension

#### Provisioning Profiles
Create development and distribution profiles for all bundle IDs.

### 2. Firebase Setup

1. Create a new Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an iOS app with bundle ID: `com.jlieb10.intentional`
3. Download `GoogleService-Info.plist` and add to Xcode project
4. Enable the following services:
   - **Authentication**: Apple, Google, Email/Password
   - **Firestore Database**: Production mode
   - **Cloud Functions**: Optional for advanced features

### 3. Google Sign-In Setup

1. In Firebase Console → Authentication → Sign-in method → Google
2. Enable Google sign-in
3. Note the Web client ID (for GIDClientID)
4. Add OAuth 2.0 URL schemes to Info.plist

### 4. App Store Connect Setup

#### Subscription Products
Create the following in-app purchases:
- **Monthly**: `intentional_pro_monthly` - £4.99/month with 7-day trial
- **Annual**: `intentional_pro_annual` - £29.99/year with 7-day trial

#### App Information
- **Bundle ID**: `com.jlieb10.intentional`
- **Category**: Productivity
- **Age Rating**: 4+ (suitable for all ages)
- **Privacy Policy URL**: Required for App Store submission

## Development Workflow

### Building the Project

1. **Clone and open**:
   ```bash
   git clone https://github.com/jlieb10/in10t.git
   cd in10t
   open Intentional.xcodeproj
   ```

2. **Configure signing**:
   - Select your development team
   - Ensure all targets use the same team
   - Verify bundle IDs match your App Store Connect configuration

3. **Install dependencies**:
   - Xcode will automatically resolve Swift Package Manager dependencies
   - First build may take 5-10 minutes

### Testing

#### Unit Tests
```bash
xcodebuild test \
  -project Intentional.xcodeproj \
  -scheme Intentional \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

#### Manual Testing (Required for Screen Time APIs)
1. **Deploy to physical device** - Screen Time APIs don't work in Simulator
2. **Grant Family Controls permission** - Required for app selection
3. **Test full user flow**:
   - Sign in → Select apps → Configure quotas → Test session flow

#### Common Testing Scenarios
- Family Controls authorization flow
- App selection with FamilyActivityPicker
- Session start/end with Live Activities
- Subscription purchase flow
- Data sync across sign-out/sign-in

### Debugging Screen Time Issues

Screen Time APIs have specific requirements and limitations:

#### Common Issues:
- **"Family Controls not authorized"**: Request entitlement from Apple Developer
- **"Shields not working"**: Ensure App Groups are configured correctly
- **"Extensions not loading"**: Check bundle IDs and provisioning profiles
- **"Live Activities not showing"**: Verify ActivityKit entitlement

#### Debug Tools:
```bash
# View system logs for Screen Time
log stream --predicate 'subsystem == "com.apple.ScreenTimeAgent"'

# Check Family Controls status
log stream --predicate 'subsystem == "com.apple.FamilyControls"'
```

## Deployment

### TestFlight

Use Fastlane for automated builds:

```bash
# Install Fastlane
gem install fastlane

# Initialize
cd fastlane
fastlane init

# Build and upload to TestFlight
fastlane beta
```

### App Store Release

1. **Pre-submission checklist**:
   - [ ] All entitlements approved by Apple
   - [ ] Subscription products configured
   - [ ] Privacy policy and terms links working
   - [ ] App tested on multiple devices
   - [ ] Screenshot and metadata prepared

2. **Release process**:
   ```bash
   fastlane release
   ```

## Architecture Decision Records

### Why Screen Time APIs?
- Native iOS integration provides system-level enforcement
- User privacy: app content never accessed, only usage tokens
- Future-proof: Apple's recommended approach for screen time apps

### Why SwiftUI + MVVM?
- Modern iOS development best practices
- Reactive UI updates with @Published properties
- Better testing through separation of concerns

### Why Firebase over Custom Backend?
- Faster development iteration
- Built-in authentication providers
- Offline-first with automatic sync
- Scalable without infrastructure management

### Why StoreKit 2?
- Modern subscription management
- Better transaction verification
- Improved user experience with subscription sheets

## Troubleshooting

### Common Build Issues

#### Family Controls Entitlement
```
Error: Provisioning profile doesn't include the Family Controls capability
```
**Solution**: Request restricted entitlement from Apple Developer Portal

#### App Group Configuration
```
Error: Unable to access App Group container
```
**Solution**: Ensure App Group ID matches across all targets and provisioning profiles

#### Package Dependencies
```
Error: Package resolution failed
```
**Solution**: 
```bash
# Clear package cache
rm -rf .build
# Re-resolve
xcodebuild -resolvePackageDependencies
```

### Runtime Issues

#### Screen Time APIs Not Working
- **Simulator**: Use physical device
- **Permissions**: Check Family Controls authorization
- **Extensions**: Verify all bundle IDs and signing

#### Cloud Sync Issues
- **Authentication**: Verify Firebase configuration
- **Network**: Check internet connectivity
- **Firestore Rules**: Ensure read/write permissions

## Performance Guidelines

### Memory Management
- Use weak references in closures to avoid retain cycles
- Profile with Instruments for memory leaks
- Implement proper cleanup in extensions

### Battery Optimization
- Minimize background processing
- Use efficient Core Data queries
- Batch cloud sync operations

### User Experience
- Implement proper loading states
- Handle network errors gracefully
- Provide offline fallback functionality

## Security Considerations

### Data Privacy
- Never store sensitive data unencrypted
- Use App Group container for shared data
- Implement proper data deletion on account removal

### Authentication
- Use secure token storage (Keychain)
- Implement proper session management
- Handle authentication errors gracefully

### Screen Time Data
- Only process usage tokens, never app content
- Respect user privacy boundaries
- Follow Apple's Screen Time guidelines
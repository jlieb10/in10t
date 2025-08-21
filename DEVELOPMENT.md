# Development Setup Guide

## Table of Contents

- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Development Workflow](#development-workflow)
- [Deployment](#deployment)
- [Architecture Decision Records](#architecture-decision-records)
- [Troubleshooting](#troubleshooting)
- [Beginner-Friendly Setup Guide](#beginner-friendly-setup-guide)
  - [Bundle ID Setup](#bundle-id-setup)
  - [App Groups Setup](#app-groups-setup)
  - [Entitlements Guide](#entitlements-guide)
  - [Firebase Setup](#firebase-setup)
  - [Subscription Setup](#subscription-setup)
  - [First-Time Xcode Setup](#first-time-xcode-setup)
- [Performance Guidelines](#performance-guidelines)
- [Security Considerations](#security-considerations)

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
- `com.jlieb10.in10t` (Main App)
- `com.jlieb10.in10t.DeviceActivityMonitor`
- `com.jlieb10.in10t.ShieldConfiguration`  
- `com.jlieb10.in10t.ShieldAction`

#### Entitlements
- **Family Controls**: Request this restricted entitlement from Apple
- **App Groups**: `group.com.jlieb10.in10t`
- **Associated Domains**: If implementing Safari extension

#### Provisioning Profiles
Create development and distribution profiles for all bundle IDs.

### 2. Firebase Setup

1. Create a new Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an iOS app with bundle ID: `com.jlieb10.in10t`
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
- **Bundle ID**: `com.jlieb10.in10t`
- **Category**: Productivity
- **Age Rating**: 4+ (suitable for all ages)
- **Privacy Policy URL**: Required for App Store submission

## Development Workflow

### Building the Project

1. **Clone and open**:
   ```bash
   git clone https://github.com/jlieb10/in10t.git
   cd in10t
   open IN10T.xcodeproj
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
- **Simulator**: Use physical device - Screen Time APIs don't work in Simulator
- **Permissions**: Check Family Controls authorization in Settings → Screen Time → Family Controls
- **Extensions**: Verify all bundle IDs and signing are correct

#### Cloud Sync Issues
- **Authentication**: Verify Firebase configuration or add GoogleService-Info.plist
- **Network**: Check internet connectivity
- **Firestore Rules**: Ensure read/write permissions

#### "No Editor" or Missing Files in Xcode
1. **Close Xcode completely**
2. **Open the project directly**: `open IN10T.xcodeproj` (not Intentional.xcodeproj)
3. **Select a file in Project Navigator** to show editor
4. **If files appear red/missing**: 
   - Select file → File Inspector → Location → Choose correct path under Sources/
   - Or delete and re-add files using Add Files to "IN10T"

#### Build Failures
**"No such module 'Firebase'"**
- Solution: File → Packages → Reset Package Caches, then clean build

**"Family Controls entitlement missing"**
- Solution: Request Family Controls entitlement from Apple Developer Portal (takes 1-2 weeks)

**"App Group container not found"**
- Solution: Verify App Group ID `group.com.jlieb10.in10t` exists in all target capabilities

#### Project Won't Open or Compile
1. **Clean everything**:
   ```bash
   # Delete derived data
   rm -rf ~/Library/Developer/Xcode/DerivedData
   
   # Clear SPM cache  
   rm -rf ~/Library/Caches/org.swift.swiftpm
   ```

2. **Reset packages in Xcode**: File → Packages → Reset Package Caches

3. **Rebuild**: Product → Clean Build Folder, then Build

## Beginner-Friendly Setup Guide

## Beginner-Friendly Setup Guide

### Bundle ID Setup

Bundle Identifiers are unique strings that identify your app and its components across Apple's systems. Think of them like domain names for your app.

#### Creating Bundle IDs in Apple Developer Portal

1. **Login to Apple Developer Portal**: 
   - Go to [developer.apple.com/account](https://developer.apple.com/account)
   - Sign in with your Apple Developer account

2. **Navigate to Identifiers**:
   - Click "Certificates, Identifiers & Profiles"
   - Click "Identifiers" in the sidebar
   - Click the "+" button (top-left)

3. **Create App IDs** (create all 4):
   
   **Main App ID:**
   - Select "App IDs" → "App" → Continue
   - **Description**: "IN10T Main App"
   - **Bundle ID**: Explicit → `com.jlieb10.in10t`
   - **Capabilities**: Check "Family Controls", "App Groups", "Sign In with Apple"
   - Register
   
   **DeviceActivityMonitor Extension:**
   - **Description**: "IN10T Device Activity Monitor"
   - **Bundle ID**: `com.jlieb10.in10t.DeviceActivityMonitor`
   - **Capabilities**: Check "App Groups" only
   - Register
   
   **ShieldConfiguration Extension:**
   - **Description**: "IN10T Shield Configuration"
   - **Bundle ID**: `com.jlieb10.in10t.ShieldConfiguration`
   - **Capabilities**: Check "App Groups" only
   - Register
   
   **ShieldAction Extension:**
   - **Description**: "IN10T Shield Action"
   - **Bundle ID**: `com.jlieb10.in10t.ShieldAction`
   - **Capabilities**: Check "App Groups" only
   - Register

#### Configuring Bundle IDs in Xcode

1. **Open your project in Xcode**: `open IN10T.xcodeproj`
2. **Select project** in navigator (top item)
3. **For each target**:
   - Select target → General tab
   - **Bundle Identifier**: Enter the matching ID from Apple Developer Portal
   - **Team**: Select your development team
   - **Signing & Capabilities**: Verify "Automatically manage signing" is checked

**⚠️ Common Issues:**
- Bundle IDs must be lowercase with no spaces or special characters except dots and hyphens
- Each extension's Bundle ID must start with the main app's Bundle ID
- If you change Bundle IDs, you'll need to update them in Apple Developer Portal too

### App Groups Setup

App Groups allow your main app and extensions to share data securely. This is essential for Screen Time functionality.

#### Creating App Group in Apple Developer Portal

1. **Navigate to Identifiers**:
   - [developer.apple.com/account/resources/identifiers](https://developer.apple.com/account/resources/identifiers)
   - Click "Identifiers" → "App Groups" (from dropdown) → "+"

2. **Create App Group**:
   - **Description**: "IN10T Data Sharing Group"
   - **Identifier**: `group.com.jlieb10.in10t`
   - **Register**

3. **Add App Group to each App ID**:
   - Go back to "App IDs" in the dropdown
   - **For each of your 4 App IDs**:
     - Click App ID → "Edit"
     - Check "App Groups" capability
     - Configure → Check your `group.com.jlieb10.in10t`
     - Save

#### Adding App Groups in Xcode

1. **For each target** (main app + 3 extensions):
   - Select target → Signing & Capabilities
   - Click "+ Capability" (top-left)
   - Double-click "App Groups"
   - Check the box for `group.com.jlieb10.in10t`

2. **Verify configuration**:
   - You should see "App Groups" capability for all 4 targets
   - Each should have `group.com.jlieb10.in10t` enabled

**⚠️ Common Issues:**
- Must be added to ALL targets (main app + all 3 extensions)
- Group identifier must start with "group."
- If you see "Unable to access App Group container" errors, check this setup

### Entitlements Guide

Entitlements are special permissions that allow your app to use specific iOS features. Family Controls is a restricted entitlement requiring Apple approval.

#### Requesting Family Controls Entitlement

1. **Prepare your request**:
   - **App Description**: Explain that IN10T is a screen time control app
   - **Use Case**: "Session-based app blocking using ManagedSettings and DeviceActivity"
   - **Benefits**: "Helps users build healthy digital habits through mindful app usage"

2. **Submit request**:
   - Go to [developer.apple.com/contact/request/family-controls](https://developer.apple.com/contact/request/family-controls)
   - Fill out the form with your app's details
   - **Processing time**: 1-2 weeks typically

3. **After approval**:
   - You'll receive email confirmation
   - The entitlement becomes available in Apple Developer Portal
   - You can then add it to your App ID and use it in Xcode

#### Adding Entitlements in Xcode (After Approval)

1. **Family Controls** (Main app only):
   - Select main app target → Signing & Capabilities
   - Click "+ Capability" → "Family Controls"

2. **Other required capabilities**:
   - **App Groups**: All targets (covered above)
   - **Background Modes**: Main app (if using background processing)
   - **ActivityKit**: Main app (for Live Activities)

**⚠️ Important Notes:**
- Family Controls entitlement can take weeks to approve
- You can develop most of the app without it, but Screen Time features won't work
- Extensions don't need Family Controls entitlement, only the main app
- Test your entitlement approval by building and running on device

### Firebase Setup

Firebase provides authentication and cloud database services. Here's a complete setup guide:

#### Creating Firebase Project

1. **Go to Firebase Console**:
   - Visit [console.firebase.google.com](https://console.firebase.google.com)
   - Click "Create a project"

2. **Project configuration**:
   - **Project name**: "IN10T" (or any name you prefer)
   - **Project ID**: Will be auto-generated (e.g., `in10t-12345`)
   - **Google Analytics**: Disable for now (can enable later)
   - Click "Create project"

#### Adding iOS App to Firebase

1. **Add app**:
   - In your Firebase project, click "Add app" → iOS icon
   - **iOS bundle ID**: `com.jlieb10.in10t` (must match exactly)
   - **App nickname**: "IN10T iOS" (optional, for your reference)
   - **App Store ID**: Leave blank for now
   - Click "Register app"

2. **Download config file**:
   - Download `GoogleService-Info.plist`
   - **IMPORTANT**: This file contains your Firebase keys

#### Adding GoogleService-Info.plist to Xcode

1. **Add to project**:
   - In Xcode, right-click your project root (next to Sources folder)
   - Choose "Add Files to [ProjectName]"
   - Select the downloaded `GoogleService-Info.plist`
   - ✅ Check "Copy items if needed"
   - ✅ Check "Add to target" for the main app target only
   - Click "Add"

2. **Verify placement**:
   - File should appear in your project navigator at the root level
   - Should NOT be inside Sources folder
   - Should have target membership only for main app (not extensions)

#### Enabling Firebase Services

**Authentication:**
1. **Enable Authentication**:
   - Firebase Console → Build → Authentication
   - Click "Get started"
   - Go to "Sign-in method" tab

2. **Configure providers**:
   
   **Apple Sign-In:**
   - Click "Apple" → Enable toggle
   - No additional configuration needed
   - Save
   
   **Google Sign-In:**
   - Click "Google" → Enable toggle  
   - **Project support email**: Your email address
   - Save and copy the "Web client ID" (you'll need this)
   
   **Email/Password:**
   - Click "Email/Password" → Enable toggle
   - Save

**Firestore Database:**
1. **Create database**:
   - Firebase Console → Build → Firestore Database
   - Click "Create database"
   - **Security rules**: Start in production mode (we'll configure rules later)
   - **Location**: Choose closest to your users (e.g., europe-west1)
   - Click "Done"

2. **Configure security rules** (in Firestore → Rules):
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users can read/write their own data
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
         
         // Allow access to user's subcollections
         match /{document=**} {
           allow read, write: if request.auth != null && request.auth.uid == userId;
         }
       }
     }
   }
   ```

**⚠️ Security Note**: These rules allow authenticated users to access only their own data.

#### Testing Firebase Integration

1. **Build and run your app** on a physical device
2. **Check Xcode console** for Firebase initialization messages:
   ```
   [Firebase] API key found, Firebase app will be configured
   ```
3. **Test authentication** by trying to sign in with Apple or Google
4. **Check Firebase Console** → Authentication → Users to see if accounts are created

**Common Firebase Issues:**

**"GoogleService-Info.plist not found":**
- Ensure file is in project root (not in Sources folder)
- Check target membership is set to main app only

**"Invalid Bundle ID":**
- Bundle ID in Xcode must exactly match what you configured in Firebase
- Check General tab of main app target

**Authentication not working:**
- Verify you enabled the sign-in methods in Firebase Console
- Check that your Bundle ID is correct in both Xcode and Firebase
- For Google Sign-In, ensure you have the latest GoogleService-Info.plist

### Subscription Setup

StoreKit 2 subscriptions require configuration in App Store Connect. Here's a complete guide:

#### App Store Connect Basic Setup

1. **Create app in App Store Connect**:
   - Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - My Apps → "+" → New App
   - **iOS** platform
   - **Name**: "IN10T" or your preferred name
   - **Primary Language**: English (or your language)
   - **Bundle ID**: Select `com.jlieb10.in10t` from dropdown
   - **SKU**: `com.jlieb10.in10t` (or any unique identifier)

2. **Complete required information**:
   - **Privacy Policy URL**: Required for any app with user accounts
   - **Category**: Productivity
   - **Age Rating**: Complete the questionnaire (likely 4+ for this app)

#### Creating Subscription Group

Subscriptions must be organized in groups. Even with just monthly/annual options, you need a group:

1. **Navigate to subscriptions**:
   - Your app → Features → In-App Purchases
   - Click "Manage" next to Auto-Renewable Subscriptions

2. **Create subscription group**:
   - Click "Create Subscription Group"
   - **Reference Name**: "IN10T Pro Subscription"
   - **Display Name**: "IN10T Pro" (users will see this)
   - Save

#### Creating Subscription Products

**Monthly Subscription:**

1. **Create subscription**:
   - In your subscription group, click "+"
   - **Product ID**: `intentional_pro_monthly` (must match your code)
   - **Reference Name**: "Monthly Pro Subscription"
   - **Subscription Duration**: 1 Month

2. **Subscription Information**:
   - **Display Name**: "Monthly Pro"
   - **Description**: "Unlimited apps and sessions with premium features"
   - **Review Screenshot**: Upload a screenshot of your paywall

3. **Pricing**:
   - Click "Add Pricing"
   - **Price**: £4.99 (or your preferred price)
   - **Territory**: Select countries where you'll sell
   - Save

4. **Introductory Offers**:
   - **Offer Type**: Free Trial
   - **Duration**: 1 Week
   - **Eligible**: New subscribers only
   - This gives users 7 days free before first payment

**Annual Subscription:**

1. **Create subscription**:
   - **Product ID**: `intentional_pro_annual`
   - **Reference Name**: "Annual Pro Subscription"  
   - **Subscription Duration**: 1 Year

2. **Pricing and setup**:
   - **Display Name**: "Annual Pro"
   - **Description**: "Unlimited apps and sessions with premium features - Save 50%!"
   - **Price**: £29.99 (or your preferred price)
   - **Introductory Offer**: 1 Week Free Trial

#### Subscription Review Process

1. **Submit for review**:
   - Both subscriptions must be submitted for review before testing
   - In each subscription, click "Submit for Review"
   - **Review Notes**: Explain that it's a screen time control app

2. **Testing before approval**:
   - Create sandbox test accounts in App Store Connect
   - Users → Sandbox Testers → "+"
   - Test purchases with these accounts on development builds

3. **Review timeline**:
   - Subscriptions typically take 24-48 hours to review
   - You'll get email notification when approved
   - Can test immediately with sandbox accounts

#### Code Integration Verification

Your subscription product IDs are already configured in the code:

**Check Sources/App/Environment/AppGroup.swift:**
```swift
// These should match your App Store Connect product IDs
static let monthlySubscriptionID = "intentional_pro_monthly"
static let annualSubscriptionID = "intentional_pro_annual"
```

**⚠️ Important Notes:**
- Product IDs in code must exactly match App Store Connect
- Prices are managed in App Store Connect, not in code
- Free trial is configured in App Store Connect, not in code
- Test subscriptions thoroughly before releasing

### First-Time Xcode Setup

1. **Install Xcode 15.0+** from Mac App Store
2. **Install Command Line Tools**: `xcode-select --install`
3. **Clone the repository**: `git clone https://github.com/jlieb10/in10t.git`
4. **Open project**: `cd in10t && open IN10T.xcodeproj`

### When You First Open the Project

The project should now show all files properly organized under Sources/. If you see missing files or "No Editor":

1. **Check you opened IN10T.xcodeproj** (not the old Intentional.xcodeproj.backup)
2. **Select any Swift file** in the navigator to show the editor
3. **If files are missing**: Delete and re-add from Sources/ directory

### Development Team Setup

1. **In Project Settings** → Select your development team for ALL targets:
   - IN10T (main app)
   - DeviceActivityMonitor  
   - ShieldConfiguration
   - ShieldAction

2. **Add capabilities** for each target:
   - App Groups: `group.com.jlieb10.in10t`
   - Family Controls (main app only)

### Testing Setup

1. **Connect a physical iPhone** (iOS 17+)
2. **Select device as run destination** (not Simulator)
3. **Build and run** - first build takes 5-10 minutes
4. **Grant permissions** when app launches

### Common First-Build Issues

**"Failed to resolve package dependencies"**
- Wait for Xcode to finish downloading packages (5-10 minutes)
- If stuck: File → Packages → Reset Package Caches

**"No development team selected"**
- Select your team in Project Settings → Signing & Capabilities for all 4 targets

**"Provisioning profile doesn't match"**
- Change bundle IDs if needed, or create App IDs in Apple Developer Portal

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

## Additional Resources

### Apple Documentation
- **Family Controls Framework**: [developer.apple.com/documentation/familycontrols](https://developer.apple.com/documentation/familycontrols)
- **Screen Time API Guide**: [developer.apple.com/documentation/screentime](https://developer.apple.com/documentation/screentime) 
- **DeviceActivity Framework**: [developer.apple.com/documentation/deviceactivity](https://developer.apple.com/documentation/deviceactivity)
- **ManagedSettings Framework**: [developer.apple.com/documentation/managedsettings](https://developer.apple.com/documentation/managedsettings)
- **StoreKit 2**: [developer.apple.com/documentation/storekit](https://developer.apple.com/documentation/storekit)
- **App Groups**: [developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)

### Firebase Documentation
- **iOS Setup Guide**: [firebase.google.com/docs/ios/setup](https://firebase.google.com/docs/ios/setup)
- **Authentication**: [firebase.google.com/docs/auth/ios/start](https://firebase.google.com/docs/auth/ios/start)
- **Firestore**: [firebase.google.com/docs/firestore/quickstart](https://firebase.google.com/docs/firestore/quickstart)
- **Security Rules**: [firebase.google.com/docs/firestore/security/get-started](https://firebase.google.com/docs/firestore/security/get-started)

### App Store Connect Guides  
- **Managing Subscriptions**: [help.apple.com/app-store-connect](https://help.apple.com/app-store-connect)
- **TestFlight**: [developer.apple.com/testflight/](https://developer.apple.com/testflight/)
- **App Review Guidelines**: [developer.apple.com/app-store/review/guidelines/](https://developer.apple.com/app-store/review/guidelines/)

### Development Tools
- **Xcode Documentation**: [developer.apple.com/xcode/](https://developer.apple.com/xcode/)
- **iOS Simulator**: [developer.apple.com/documentation/xcode/running-your-app-in-simulator-or-on-a-device](https://developer.apple.com/documentation/xcode/running-your-app-in-simulator-or-on-a-device)
- **Instruments**: [developer.apple.com/xcode/features/](https://developer.apple.com/xcode/features/)
- **SwiftLint**: [github.com/realm/SwiftLint](https://github.com/realm/SwiftLint)
- **Fastlane**: [fastlane.tools](https://fastlane.tools)

### Community Resources
- **Apple Developer Forums**: [developer.apple.com/forums/](https://developer.apple.com/forums/)
- **Swift Forums**: [forums.swift.org](https://forums.swift.org)
- **Reddit iOS Programming**: [reddit.com/r/iOSProgramming](https://reddit.com/r/iOSProgramming)
- **Stack Overflow iOS**: [stackoverflow.com/questions/tagged/ios](https://stackoverflow.com/questions/tagged/ios)
# Firebase Analytics Setup Instructions for NgonNest

## Overview
This document provides step-by-step instructions to configure Firebase Analytics for the NgonNest Flutter application.

## Prerequisites
- Firebase account
- Flutter project configured
- Android and/or iOS development environment

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `ngonnest-analytics`
4. Enable Google Analytics for the project
5. Choose or create a Google Analytics account

## Step 2: Add Android App

1. In Firebase Console, click "Add app" and select Android
2. Enter Android package name: `com.ngonnest.ngonnest_app`
3. Enter app nickname: `NgonNest Android`
4. Download `google-services.json`
5. Place the file in: `android/app/google-services.json`

## Step 3: Add iOS App (Optional)

1. In Firebase Console, click "Add app" and select iOS
2. Enter iOS bundle ID: `com.ngonnest.ngonnestApp`
3. Enter app nickname: `NgonNest iOS`
4. Download `GoogleService-Info.plist`
5. Place the file in: `ios/Runner/GoogleService-Info.plist`

## Step 4: Configure Android

Add to `android/build.gradle` (project level):
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

Add to `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation 'com.google.firebase:firebase-analytics'
}
```

## Step 5: Configure iOS (if applicable)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Drag `GoogleService-Info.plist` into the Runner target
3. Ensure it's added to the target membership

## Step 6: Verify Installation

Run the following command to verify Firebase is properly configured:
```bash
flutter packages get
flutter run
```

Check the logs for Firebase initialization messages.

## Step 7: Analytics Events

The NgonNest app is configured with the following custom analytics events:

### MVP Critical Events
- `onboarding_flow_started` - User starts onboarding
- `onboarding_flow_completed` - User completes onboarding
- `core_action` - Core app actions (item_added, item_updated, etc.)
- `flow_started` - UX flow tracking (add_product, onboarding, etc.)
- `flow_completed` - UX flow completion

### MVP High Priority Events
- `offline_session_started` - User goes offline
- `offline_session_ended` - User comes back online
- `migration_attempt` - Database migration started
- `migration_completed` - Database migration finished (success/failure)

### User Properties
- `household_size` - Number of people in household
- `household_type` - Type of housing (apartment/house)
- `primary_language` - User's preferred language
- `low_storage` - Device has low storage

## Step 8: Testing Analytics

To test analytics in debug mode:
1. Enable debug mode: `adb shell setprop debug.firebase.analytics.app com.ngonnest.ngonnest_app`
2. Use Firebase DebugView in the console
3. Trigger events by using the app (onboarding, adding products, etc.)

## Step 9: Privacy Compliance

The analytics implementation follows privacy best practices:
- No personally identifiable information (PII) is collected
- Data is aggregated and anonymized
- Users can opt-out through app settings
- Complies with GDPR and local privacy regulations

## Troubleshooting

### Common Issues
1. **Build errors**: Ensure `google-services.json` is in the correct location
2. **Analytics not working**: Check Firebase project configuration and app package names
3. **iOS build issues**: Verify `GoogleService-Info.plist` is added to the target

### Debug Commands
```bash
# Check Firebase configuration
flutter packages get
flutter clean
flutter build apk --debug

# View analytics in real-time (Android)
adb shell setprop debug.firebase.analytics.app com.ngonnest.ngonnest_app
```

## Next Steps

After Firebase is configured:
1. Monitor analytics in Firebase Console
2. Set up custom dashboards for stakeholder metrics
3. Configure alerts for critical events
4. Review and optimize event tracking based on usage patterns

## Support

For issues with Firebase setup:
- [Firebase Documentation](https://firebase.google.com/docs/flutter/setup)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- NgonNest development team

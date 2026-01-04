# Firebase Remote Config & Dynamic Content Guide

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Setup Instructions](#setup-instructions)
4. [Using Remote Config](#using-remote-config)
5. [Dynamic Content Management](#dynamic-content-management)
6. [A/B Testing](#ab-testing)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

## Overview

This guide explains how to use Firebase Remote Config and Dynamic Content in the NgonNest Flutter application. These features allow you to modify your app's behavior and appearance without publishing an app update.

## Architecture

The implementation consists of four main services:

1. **RemoteConfigService**: Handles all Remote Config operations
2. **DynamicContentService**: Manages remote assets and content
3. **FeatureFlagService**: Manages feature flags and app configuration
4. **ABTestingService**: Handles A/B testing and experiment assignments

## Setup Instructions

### 1. Firebase Configuration

1. Ensure you have the following dependencies in your `pubspec.yaml`:
   ```yaml
   dependencies:
     firebase_core: ^2.24.2
     firebase_remote_config: ^5.4.2
     http: ^1.1.0
     provider: ^6.1.2
   ```

2. Run `flutter pub get` to install dependencies.

3. In the Firebase Console, enable Remote Config for your project.

### 2. Initialize Services

In your `main.dart`, wrap your app with `ServiceProvider`:

```dart
void main() async {
  // ... other initialization code
  
  runApp(
    ServiceProvider(
      child: MultiProvider(
        // ... your existing providers
        child: MyApp(),
      ),
    ),
  );
}
```

## Using Remote Config

### Accessing Remote Config Values

```dart
final remoteConfig = RemoteConfigService();
await remoteConfig.initialize();

// Get a boolean value
bool isFeatureEnabled = remoteConfig.getBool('feature_name');

// Get a string value
String welcomeMessage = remoteConfig.getString('welcome_message');

// Get a JSON object
Map<String, dynamic> config = remoteConfig.getJson('app_config');
```

### Setting Default Values

Always set default values in `RemoteConfigService._defaults`:

```dart
static const Map<String, dynamic> _defaults = {
  'feature_premium_banner_enabled': false,
  'welcome_message': 'Welcome to NgonNest!',
  // Add more defaults here
};
```

## Dynamic Content Management

### Fetching Remote Content

```dart
final dynamicContent = DynamicContentService();
await dynamicContent.initialize();

// Get remote content
final content = await dynamicContent.getContent('home_banner');

// Get a remote image
final imageFile = await dynamicContent.getCachedImage('banner_image');
if (imageFile != null) {
  // Use the image file
  Image.file(imageFile);
}
```

### Preloading Content

Preload content during app startup:

```dart
await dynamicContent.preloadContent([
  'home_banner',
  'premium_features',
  'onboarding_steps',
]);
```

## A/B Testing

### Setting Up Experiments

1. In the Firebase Console, go to A/B Testing > Create Experiment > Remote Config
2. Define your experiment variants and targeting
3. Add the experiment parameters to your app

### Using Experiments in Code

```dart
final abTesting = ABTestingService();
await abTesting.initialize();

// Get the current variant for an experiment
final variant = abTesting.getExperimentVariant('homepage_layout_v1');

// Track experiment exposure
await abTesting.trackExperimentExposure('homepage_layout_v1');

// Track conversion
await abTesting.trackExperimentConversion(
  'homepage_layout_v1',
  'purchase_completed',
  additionalParams: {'amount': 9.99},
);
```

## Best Practices

1. **Always provide defaults**: Ensure your app works without network connectivity
2. **Use meaningful parameter names**: Make them descriptive and consistent
3. **Cache remote content**: Use `DynamicContentService` to cache assets locally
4. **Monitor performance**: Keep an eye on fetch times and cache hits/misses
5. **Version your experiments**: Append version numbers to experiment names (e.g., `homepage_v2`)
6. **Clean up unused parameters**: Remove old parameters from the Firebase Console

## Troubleshooting

### Common Issues

1. **Values not updating**:
   - Check fetch intervals (minimum 1 hour in production)
   - Call `forceFetch()` in debug mode to bypass caching

2. **App crashes on startup**:
   - Verify all required Firebase services are initialized
   - Check for null values in your default config

3. **Content not loading**:
   - Verify network connectivity
   - Check Firebase Storage rules for the content bucket

### Debugging

In debug mode, you can enable verbose logging:

```dart
if (kDebugMode) {
  await FirebaseRemoteConfig.instance.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(minutes: 1),
    minimumFetchInterval: Duration.zero, // Disable caching in debug
  ));
}
```

## Next Steps

1. Set up monitoring in Firebase Console
2. Create dashboards for key metrics
3. Set up alerts for configuration issues
4. Implement automated testing for critical feature flags

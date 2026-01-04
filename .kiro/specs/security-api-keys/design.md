# Design Document - API Keys Security

## Overview

This design implements a comprehensive security solution to remove hardcoded API keys from the NgonNest application and establish a secure configuration management system. The solution uses environment variables, Flutter's build-time configuration, code obfuscation, and encrypted local storage to protect sensitive credentials.

The current vulnerability exposes Supabase API keys in `lib/config/supabase_config.dart`, making them easily extractable through APK decompilation. This design eliminates that risk while maintaining the offline-first architecture and supporting multiple deployment environments.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Build Time                               │
│  ┌──────────────┐      ┌─────────────────┐                 │
│  │ Environment  │─────▶│  Build Script   │                 │
│  │  Variables   │      │  (dart-define)  │                 │
│  └──────────────┘      └────────┬────────┘                 │
│                                  │                           │
│                                  ▼                           │
│                         ┌────────────────┐                  │
│                         │  Compiled App  │                  │
│                         │  (Obfuscated)  │                  │
│                         └────────┬───────┘                  │
└──────────────────────────────────┼──────────────────────────┘
                                   │
┌──────────────────────────────────┼──────────────────────────┐
│                     Runtime                                  │
│                                   ▼                          │
│                         ┌────────────────┐                  │
│                         │  Config        │                  │
│                         │  Service       │                  │
│                         └────┬───────────┘                  │
│                              │                               │
│              ┌───────────────┼───────────────┐             │
│              ▼               ▼               ▼             │
│     ┌────────────┐  ┌────────────┐  ┌────────────┐       │
│     │  Flutter   │  │  Firebase  │  │  Fallback  │       │
│     │  Secure    │  │  Remote    │  │  Defaults  │       │
│     │  Storage   │  │  Config    │  │            │       │
│     └────────────┘  └────────────┘  └────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

### Component Interaction Flow

1. **Build Time**: Environment variables are injected via `--dart-define`
2. **Compilation**: Code is obfuscated for release builds
3. **Runtime**: ConfigService loads configuration from secure sources
4. **Fallback**: If remote config fails, use encrypted local storage
5. **Validation**: All config values are validated before use

## Components and Interfaces

### 1. ConfigService

Central service for managing all application configuration.

```dart
class ConfigService {
  static ConfigService? _instance;
  static ConfigService get instance => _instance ??= ConfigService._();
  
  // Environment detection
  AppEnvironment get currentEnvironment;
  bool get isProduction;
  bool get isDevelopment;
  
  // Supabase configuration
  Future<SupabaseConfig> getSupabaseConfig();
  
  // Firebase Remote Config
  Future<void> initializeRemoteConfig();
  Future<Map<String, dynamic>> getRemoteConfig();
  
  // Secure storage
  Future<void> saveSecureConfig(String key, String value);
  Future<String?> getSecureConfig(String key);
  
  // Validation
  bool validateConfig(Map<String, dynamic> config);
}
```

### 2. SupabaseConfig (Refactored)

Secure configuration loader without hardcoded keys.

```dart
class SupabaseConfig {
  final String url;
  final String anonKey;
  final AppEnvironment environment;
  
  const SupabaseConfig({
    required this.url,
    required this.anonKey,
    required this.environment,
  });
  
  // Load from build-time constants
  factory SupabaseConfig.fromEnvironment() {
    return SupabaseConfig(
      url: const String.fromEnvironment('SUPABASE_URL'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      environment: _detectEnvironment(),
    );
  }
  
  // Validation
  bool isValid() {
    return url.isNotEmpty && 
           anonKey.isNotEmpty && 
           !url.contains('YOUR_') &&
           !anonKey.contains('YOUR_');
  }
}
```

### 3. BuildConfigService

Handles build-time configuration injection.

```dart
class BuildConfigService {
  // Read dart-define values
  static String getDefine(String key, {String defaultValue = ''});
  
  // Environment detection
  static AppEnvironment detectEnvironment();
  
  // Build validation
  static bool validateBuildConfig();
}
```

### 4. SecureStorageService

Encrypted local storage for sensitive configuration.

```dart
class SecureStorageService {
  final FlutterSecureStorage _storage;
  
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
  
  // Encryption helpers
  Future<String> encrypt(String plainText);
  Future<String> decrypt(String cipherText);
}
```

### 5. RemoteConfigService

Firebase Remote Config integration for non-sensitive settings.

```dart
class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;
  
  Future<void> initialize();
  Future<void> fetchAndActivate();
  
  String getString(String key, {String defaultValue = ''});
  int getInt(String key, {int defaultValue = 0});
  bool getBool(String key, {bool defaultValue = false});
  
  // Cache management
  Future<void> setConfigSettings(RemoteConfigSettings settings);
}
```

## Data Models

### AppEnvironment Enum

```dart
enum AppEnvironment {
  development,
  staging,
  production;
  
  bool get isProduction => this == AppEnvironment.production;
  bool get isDevelopment => this == AppEnvironment.development;
  bool get isStaging => this == AppEnvironment.staging;
}
```

### ConfigValidationResult

```dart
class ConfigValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  
  const ConfigValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
  
  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: No Hardcoded Secrets in Source

*For any* source file in the codebase, scanning for hardcoded API keys should return zero matches after implementation.

**Validates: Requirements 1.1, 1.2**

### Property 2: Environment Isolation

*For any* build configuration (dev/staging/prod), the loaded API keys should match only that environment's credentials and never cross-contaminate.

**Validates: Requirements 2.1, 2.2, 2.3, 2.4**

### Property 3: Obfuscation Preservation

*For any* release build, decompiling the APK/IPA should not reveal readable API keys or sensitive configuration values.

**Validates: Requirements 3.1, 3.2**

### Property 4: Configuration Fallback Chain

*For any* configuration key, if remote config fails, the system should successfully fall back to secure local storage, and if that fails, to safe defaults without crashing.

**Validates: Requirements 4.2, 4.4**

### Property 5: Encryption Round-Trip

*For any* sensitive configuration value stored locally, encrypting then decrypting should produce the original value without data loss.

**Validates: Requirements 5.1, 5.3**

### Property 6: Build Script Validation

*For any* build attempt with missing required environment variables, the build script should fail immediately with a clear error message before compilation starts.

**Validates: Requirements 6.2, 6.4**

### Property 7: No Secrets in Logs

*For any* log output (debug or release), scanning for API keys or tokens should return zero matches.

**Validates: Requirements 7.4**

### Property 8: Configuration Validation

*For any* loaded configuration object, the validation method should correctly identify invalid URLs, empty keys, or placeholder values.

**Validates: Requirements 7.1, 7.2**

## Error Handling

### Build-Time Errors

1. **Missing Environment Variables**
   - Error: "Required environment variable SUPABASE_URL not found"
   - Action: Fail build immediately with setup instructions
   - Recovery: Developer sets environment variables and rebuilds

2. **Invalid Configuration Format**
   - Error: "SUPABASE_URL is not a valid URL format"
   - Action: Fail build with validation details
   - Recovery: Developer corrects the value

3. **Obfuscation Failure**
   - Error: "Code obfuscation failed during release build"
   - Action: Fail build and preserve debug symbols
   - Recovery: Check Flutter/Dart SDK version compatibility

### Runtime Errors

1. **Configuration Load Failure**
   - Error: "Failed to load Supabase configuration"
   - Action: Log error, attempt fallback to cached config
   - Recovery: Use last known good configuration or safe defaults
   - User Impact: App continues in offline mode

2. **Remote Config Timeout**
   - Error: "Firebase Remote Config fetch timeout"
   - Action: Use cached remote config values
   - Recovery: Retry on next app start
   - User Impact: None (transparent fallback)

3. **Secure Storage Corruption**
   - Error: "Failed to decrypt stored configuration"
   - Action: Clear corrupted data, re-initialize
   - Recovery: Prompt user to re-authenticate if needed
   - User Impact: May need to log in again

4. **Invalid API Key at Runtime**
   - Error: "Supabase authentication failed: invalid API key"
   - Action: Disable cloud sync, enable offline-only mode
   - Recovery: Check for app updates with corrected keys
   - User Impact: Cloud sync disabled, local data preserved

### Error Logging Strategy

```dart
class ConfigErrorLogger {
  static void logBuildError(String message, {StackTrace? stackTrace});
  static void logRuntimeError(String message, {StackTrace? stackTrace});
  static void logSecurityWarning(String message);
  
  // Never log sensitive data
  static String sanitizeForLogging(String message) {
    // Remove any potential API keys, tokens, or credentials
    return message.replaceAll(RegExp(r'[A-Za-z0-9]{20,}'), '[REDACTED]');
  }
}
```

## Testing Strategy

### Unit Tests

1. **ConfigService Tests**
   - Test environment detection logic
   - Test configuration validation
   - Test fallback chain (remote → local → defaults)
   - Test error handling for each failure mode

2. **SupabaseConfig Tests**
   - Test loading from environment variables
   - Test validation logic for URLs and keys
   - Test environment-specific configuration

3. **SecureStorageService Tests**
   - Test encryption/decryption round-trip
   - Test storage and retrieval
   - Test handling of corrupted data
   - Test cleanup on uninstall

4. **BuildConfigService Tests**
   - Test dart-define value reading
   - Test environment detection
   - Test build validation logic

### Integration Tests

1. **End-to-End Configuration Flow**
   - Test complete flow from build to runtime
   - Verify no hardcoded keys in compiled output
   - Test environment switching

2. **Fallback Chain Integration**
   - Simulate remote config failure
   - Verify fallback to local storage
   - Verify fallback to defaults

3. **Security Validation**
   - Decompile test APK and scan for secrets
   - Verify obfuscation is applied
   - Test log output for leaked secrets

### Property-Based Tests

Using the `test` package with custom generators:

1. **Property Test: No Secrets in Source**
   ```dart
   test('No API keys in source files', () {
     final sourceFiles = Directory('lib').listSync(recursive: true);
     for (final file in sourceFiles) {
       if (file is File && file.path.endsWith('.dart')) {
         final content = file.readAsStringSync();
         expect(content, isNot(contains(RegExp(r'eyJ[A-Za-z0-9_-]{20,}'))));
       }
     }
   });
   ```

2. **Property Test: Environment Isolation**
   ```dart
   test('Environment configs never cross-contaminate', () {
     for (final env in AppEnvironment.values) {
       final config = ConfigService.instance.getConfigForEnvironment(env);
       expect(config.environment, equals(env));
       // Verify keys match expected pattern for this environment
     }
   });
   ```

3. **Property Test: Encryption Round-Trip**
   ```dart
   test('Encryption preserves data integrity', () async {
     final testValues = ['test123', 'api_key_xyz', ''];
     for (final value in testValues) {
       final encrypted = await secureStorage.encrypt(value);
       final decrypted = await secureStorage.decrypt(encrypted);
       expect(decrypted, equals(value));
     }
   });
   ```

### Manual Testing Checklist

- [ ] Build app with missing env vars → should fail with clear error
- [ ] Build app for dev environment → should use dev config
- [ ] Build app for production → should use prod config
- [ ] Decompile release APK → should not find readable API keys
- [ ] Run app offline → should use cached config
- [ ] Clear app data → should re-initialize config
- [ ] Check logs in release mode → should not contain secrets
- [ ] Test on Android 8.0 device → should work correctly
- [ ] Test on iOS 12 device → should work correctly

## Implementation Notes

### Build Script Setup

Create `scripts/build_with_env.sh`:

```bash
#!/bin/bash

# Load environment variables
if [ -f .env ]; then
  export $(cat .env | xargs)
else
  echo "Error: .env file not found"
  exit 1
fi

# Validate required variables
required_vars=("SUPABASE_URL" "SUPABASE_ANON_KEY" "ENVIRONMENT")
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: $var is not set"
    exit 1
  fi
done

# Build with dart-define
flutter build apk \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=ENVIRONMENT="$ENVIRONMENT" \
  --obfuscate \
  --split-debug-info=build/debug-info \
  --release
```

### Environment File Template

Create `.env.example`:

```bash
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here

# Environment (development, staging, production)
ENVIRONMENT=development

# Firebase (optional)
FIREBASE_API_KEY=your_firebase_key_here
```

### CI/CD Integration

For GitHub Actions:

```yaml
- name: Build Release APK
  env:
    SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
    SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
    ENVIRONMENT: production
  run: |
    flutter build apk \
      --dart-define=SUPABASE_URL="$SUPABASE_URL" \
      --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
      --dart-define=ENVIRONMENT="$ENVIRONMENT" \
      --obfuscate \
      --split-debug-info=build/debug-info \
      --release
```

### Security Validation Script

Create `scripts/validate_security.sh`:

```bash
#!/bin/bash

echo "Scanning for hardcoded secrets..."

# Patterns to search for
patterns=(
  "eyJ[A-Za-z0-9_-]{20,}"  # JWT tokens
  "sk_[a-zA-Z0-9]{20,}"     # Secret keys
  "pk_[a-zA-Z0-9]{20,}"     # Public keys
)

found_secrets=0

for pattern in "${patterns[@]}"; do
  if grep -r -E "$pattern" lib/ --exclude-dir=.dart_tool; then
    echo "❌ Found potential secret matching pattern: $pattern"
    found_secrets=1
  fi
done

if [ $found_secrets -eq 0 ]; then
  echo "✅ No hardcoded secrets found"
  exit 0
else
  echo "❌ Security validation failed"
  exit 1
fi
```

## Migration Strategy

### Phase 1: Preparation (Day 1)

1. Create `.env.example` template
2. Document setup process for developers
3. Create build scripts
4. Set up CI/CD secrets

### Phase 2: Implementation (Day 1-2)

1. Implement ConfigService
2. Implement SecureStorageService
3. Refactor SupabaseConfig
4. Add validation logic

### Phase 3: Testing (Day 2)

1. Run unit tests
2. Run integration tests
3. Manual security validation
4. Decompile and verify obfuscation

### Phase 4: Deployment (Day 2)

1. Update developer documentation
2. Notify team of new build process
3. Update CI/CD pipelines
4. Archive old configuration files

## Performance Considerations

- **Build Time**: Obfuscation adds ~30 seconds to release builds
- **Runtime**: Config loading adds <100ms to app startup
- **Storage**: Encrypted config uses <1KB of secure storage
- **Network**: Remote config fetch is async and non-blocking

## Security Considerations

- Never commit `.env` files to version control
- Rotate API keys if they were previously exposed
- Use different keys for each environment
- Enable Supabase RLS policies
- Monitor for unauthorized API usage
- Set up alerts for suspicious activity

## Backward Compatibility

This change is **not backward compatible** with existing builds. All developers must:

1. Update their local environment setup
2. Use new build scripts
3. Clear old configuration from devices during testing

Existing production users will need to update to the new version, but their local data remains intact.

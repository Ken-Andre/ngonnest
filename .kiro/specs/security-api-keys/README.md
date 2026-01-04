# API Keys Security Spec

## Status: Ready for Implementation ✅

## Overview

This spec addresses the **CRITICAL** security vulnerability where Supabase API keys are hardcoded in plain text in the NgonNest application source code. This is Priority #1 from the security audit.

## Problem

Currently in `lib/config/supabase_config.dart`:
- Supabase URL and anon keys are hardcoded as string constants
- Anyone can decompile the APK and extract these credentials
- No environment separation (dev/staging/prod use same keys)
- Keys cannot be rotated without code changes
- **This is a blocker for App Store/Play Store submission**

## Solution

Implement a comprehensive security solution:
1. Remove all hardcoded API keys from source code
2. Use environment variables with `--dart-define` at build time
3. Enable code obfuscation for release builds
4. Implement encrypted local storage for sensitive config
5. Add Firebase Remote Config for non-sensitive settings
6. Create automated security validation tools

## Estimated Time

**2 days** (as per audit recommendation)

## Files to Create

- `lib/services/config_service.dart` - Central configuration management
- `lib/services/secure_storage_service.dart` - Encrypted local storage
- `lib/services/build_config_service.dart` - Build-time configuration
- `lib/services/remote_config_service.dart` - Firebase Remote Config
- `lib/services/config_error_logger.dart` - Error handling
- `lib/models/config_validation_result.dart` - Validation results
- `scripts/build_with_env.sh` - Build script (Unix/Mac)
- `scripts/build_with_env.bat` - Build script (Windows)
- `scripts/validate_security.sh` - Security validation
- `.env.example` - Environment template
- `docs/ENVIRONMENT_SETUP.md` - Developer documentation

## Files to Modify

- `lib/config/supabase_config.dart` - Remove hardcoded keys
- `lib/services/auth_service.dart` - Use new configuration
- `lib/services/sync_service.dart` - Use new configuration
- `pubspec.yaml` - Add dependencies
- `android/app/build.gradle` - Obfuscation settings
- `.gitignore` - Exclude `.env` files
- CI/CD configuration files

## Dependencies to Add

```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
  firebase_remote_config: ^4.3.0
```

## Getting Started

To begin implementation:

1. Read the requirements document: `requirements.md`
2. Review the design document: `design.md`
3. Follow the tasks in order: `tasks.md`
4. Start with Task 1: Set up environment configuration infrastructure

## Testing Strategy

- **Unit Tests**: All services (ConfigService, SecureStorageService, etc.)
- **Property-Based Tests** (optional): Encryption, validation, security
- **Integration Tests**: End-to-end configuration flow
- **Manual Testing**: Decompile APK and verify no secrets exposed

## Success Criteria

✅ No hardcoded API keys in source code
✅ Release APK passes security scan
✅ Decompiled APK does not reveal secrets
✅ Code is obfuscated in release builds
✅ Environment switching works correctly
✅ All tests pass
✅ Documentation is complete

## Next Steps

Once this spec is complete:
1. Rotate all exposed API keys in Supabase
2. Update production deployment process
3. Notify all developers of new build process
4. Move to next critical issue: Alert Persistence

## Related Specs

- `sync-improvements` - Will benefit from secure configuration
- `budget-critical-fixes` - Can proceed after security is fixed

## Priority

🔴 **CRITICAL** - Must be completed before App Store/Play Store submission

# Tech Context - NgoNest

## Technologies Used

### Core Framework
- **Flutter 3.x**: Cross-platform mobile development framework
- **Dart 3.x**: Programming language for Flutter development
- **Material Design 3**: UI component library and design system

### Database & Storage
- **SQLite**: Primary data storage with encryption
- **sqflite**: Flutter package for SQLite database access
- **path_provider**: File system path management
- **shared_preferences**: Simple key-value storage for settings

### State Management & Architecture
- **Provider**: State management and dependency injection
- **MVVM Pattern**: Model-View-ViewModel architectural pattern
- **Repository Pattern**: Data access abstraction layer
- **Static Services**: Some services (BudgetService) use static methods for simplicity
- **Hybrid Approach**: Mix of ChangeNotifier and static patterns based on use case

### Networking & Connectivity
- **connectivity_plus**: Real-time network connectivity monitoring with stream support
- **http**: HTTP client for API calls and pre-flight checks
- **firebase_core**: Firebase integration
- **firebase_remote_config**: Remote configuration management
- **ConnectivityService**: Custom service with pre-flight checks and error detection

### UI & User Experience
- **intl**: Internationalization and localization
- **cached_network_image**: Image caching for performance
- **flutter_local_notifications**: Local notification management
- **percent_indicator**: Progress indicators and charts
- **syncfusion_flutter_charts**: Advanced charting components

### Development & Testing
- **flutter_test**: Unit and widget testing framework
- **integration_test**: Integration testing support
- **mockito**: Mocking framework for unit tests
- **build_runner**: Code generation tool

### Analytics & Monitoring
- **firebase_analytics**: User behavior analytics
- **firebase_crashlytics**: Crash reporting and monitoring
- **firebase_performance**: Performance monitoring

## Development Setup

### Environment Requirements
- **Flutter SDK**: Version 3.16.0 or higher
- **Dart SDK**: Version 3.2.0 or higher
- **Android Studio**: For Android development and emulation
- **Xcode**: For iOS development (macOS only)
- **VS Code/Cursor**: Recommended IDE with Flutter extensions

### Project Structure
```
lib/
├── config/           # Configuration files and constants
├── models/           # Data models and entities
├── providers/        # State management providers
├── repository/       # Data access repositories
├── screens/          # UI screens and pages
├── services/         # Business logic and external services
├── theme/            # App theming and styling
├── utils/            # Utility functions and helpers
└── widgets/          # Reusable UI components
```

### Key Dependencies (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  shared_preferences: ^2.2.2
  connectivity_plus: ^5.0.2
  http: ^1.1.0
  intl: ^0.19.0
  firebase_core: ^2.24.2
  firebase_analytics: ^10.7.4
  firebase_crashlytics: ^3.4.9
  cached_network_image: ^3.3.0
  flutter_local_notifications: ^16.3.2
  percent_indicator: ^4.2.3
  syncfusion_flutter_charts: ^24.2.7
  # ... additional dependencies

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.7
```

## Technical Constraints

### Performance Requirements
- **App Size**: Must remain under 25MB for APK
- **Memory Usage**: Optimized for devices with 2GB RAM
- **Load Time**: All screens must load within 2 seconds
- **Battery Impact**: Less than 1% battery consumption per day
- **Offline Performance**: 100% functionality without internet

### Platform Compatibility
- **Android**: Minimum SDK 21 (Android 8.0), target SDK 34
- **iOS**: Minimum iOS 12.0 (if supported in future)
- **Web**: Progressive Web App support (future enhancement)

### Security Requirements
- **Database Encryption**: AES-256 encryption for SQLite
- **Secure Storage**: Encrypted storage for sensitive data
- **Network Security**: HTTPS for all external communications
- **Data Privacy**: Local-first approach with optional cloud sync

## Tool Usage Patterns

### Development Workflow
1. **Code Generation**: Using build_runner for data models
2. **Testing**: Unit tests for services, widget tests for UI components
3. **Linting**: Dart analysis with strict rules enabled
4. **Formatting**: Dart format for consistent code style

### Database Management
1. **Migrations**: Version-controlled database schema changes
   - Local: v12 with percentage column for budget_categories
   - Cloud: Migration SQL ready but not yet applied
2. **Backup/Restore**: Automated data backup functionality
3. **Indexing**: Strategic database indexes for performance
4. **Encryption**: Planned but not yet implemented
5. **Schema Compatibility**: Critical issue - INTEGER vs UUID mismatch between local and cloud

### State Management Patterns
1. **Provider Setup**: MultiProvider in main.dart for app-wide state
2. **ViewModel Pattern**: Business logic separated from UI
3. **Repository Injection**: Services injected via Provider
4. **Error Handling**: Centralized error management

### Internationalization
1. **ARB Files**: Separate translation files for each language
2. **Locale Provider**: Dynamic language switching
3. **RTL Support**: Right-to-left language support preparation
4. **Cultural Adaptation**: Localized formats for dates, numbers, currency

## Build and Deployment

### Build Configurations
- **Debug**: Development builds with debugging enabled
- **Profile**: Performance testing builds
- **Release**: Production builds with optimization
- **App Bundle**: Google Play Store optimized format

### Code Quality Tools
- **Analysis Options**: Strict linting rules for code quality
- **Testing Coverage**: Minimum 80% code coverage requirement
- **Performance Monitoring**: Firebase Performance integration
- **Crash Reporting**: Firebase Crashlytics for production monitoring

### Asset Management
- **Image Optimization**: WebP format for better compression
- **Icon Generation**: Multiple icon sizes for different devices
- **Font Management**: Custom fonts with fallbacks
- **Localization Assets**: Language-specific images and icons

## Development Best Practices

### Code Organization
- **Feature-based Structure**: Related files grouped by feature
- **Separation of Concerns**: Clear boundaries between layers
- **Consistent Naming**: PascalCase for classes, camelCase for methods
- **Documentation**: Comprehensive comments for public APIs

### Performance Optimization
- **Lazy Loading**: Components loaded only when needed
- **Image Caching**: Aggressive caching for frequently used images
- **List Virtualization**: Efficient rendering of large lists
- **Background Processing**: Heavy tasks moved to background isolates

### Error Handling
- **Global Error Handler**: Centralized error management
- **User-Friendly Messages**: Localized error messages
- **Graceful Degradation**: App continues working with reduced functionality
- **Logging**: Comprehensive logging for debugging

### Testing Strategy
- **Unit Tests**: Business logic and utility functions
- **Widget Tests**: UI components and interactions
- **Integration Tests**: Complete user workflows
- **Performance Tests**: Load testing and memory profiling

## Future Technical Considerations

### Scalability Planning
- **Database Optimization**: Query optimization and indexing strategy
- **State Management**: Potential migration to more advanced state management
- **Architecture Evolution**: Modular architecture for feature expansion
- **Performance Monitoring**: Enhanced analytics and monitoring

### Platform Expansion
- **Web Support**: Progressive Web App implementation
- **Desktop Support**: Windows, macOS, Linux versions
- **Wear OS**: Smartwatch integration for quick inventory checks
- **TV Support**: Large screen optimization for family use

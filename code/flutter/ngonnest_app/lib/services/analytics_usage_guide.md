# NgonNest Analytics Usage Guide

## Overview
This guide explains how to use the AnalyticsService in NgonNest to track user behavior and app performance according to the analytics specification document.

## Quick Start

### Basic Usage
```dart
// Get the analytics service
final analytics = context.read<AnalyticsService>();

// Log a simple event
await analytics.logEvent('user_action', parameters: {
  'action_type': 'button_clicked',
  'screen': 'dashboard',
});
```

## MVP Critical Metrics Implementation

### 1. Onboarding Tracking
```dart
// In onboarding screen initState
await analytics.logOnboardingStarted();
await analytics.logFlowStarted('onboarding');

// When onboarding completes
await analytics.logOnboardingCompleted();
await analytics.logFlowCompleted('onboarding');

// Set household profile for segmentation
await analytics.setHouseholdProfile(
  householdSize: 4,
  householdType: 'apartment',
  primaryLanguage: 'français',
);
```

### 2. Core Action Tracking
```dart
// Track item-related actions
await analytics.logItemAction('added', params: {
  'product_type': 'consumable',
  'category': 'hygiene',
});

await analytics.logItemAction('updated', params: {
  'product_id': '123',
  'field_changed': 'quantity',
});

await analytics.logItemAction('deleted', params: {
  'product_type': 'durable',
});

// Track other core actions
await analytics.logInventoryAction('viewed');
await analytics.logBudgetAction('created');
await analytics.logAlertAction('dismissed');
```

### 3. UX Flow Tracking
```dart
// Start tracking a flow
await analytics.logFlowStarted('add_product');

// Complete the flow successfully
await analytics.logFlowCompleted('add_product', additionalParams: {
  'product_category': 'kitchen',
  'completion_method': 'manual_entry',
});

// Or abandon the flow
await analytics.logFlowAbandoned('add_product', reason: 'user_cancelled');
```

## MVP High Priority Metrics

### 1. Offline Session Tracking
```dart
// Automatically tracked by ConnectivityService
// Manual tracking if needed:
await analytics.logOfflineSessionStarted();
await analytics.logOfflineSessionEnded();
```

### 2. Database Migration Tracking
```dart
// Automatically tracked in db.dart
// Manual tracking for custom migrations:
await analytics.logMigrationAttempt(fromVersion, toVersion);
await analytics.logMigrationSuccess(fromVersion, toVersion, durationMs);
await analytics.logMigrationFailure(fromVersion, toVersion, errorCode);
```

## Post-MVP Metrics

### 1. Feature Adoption Tracking
```dart
// Track when user first uses a feature
await analytics.logFeatureFirstUse('auto_suggestions');
await analytics.logFeatureFirstUse('budget_alerts');
await analytics.logFeatureFirstUse('inventory_export');
```

### 2. Sync Performance Tracking
```dart
// Track sync operations
await analytics.logSyncAttemptStarted();
await analytics.logSyncAttemptEnded(true); // success
await analytics.logSyncAttemptEnded(false, errorCode: 'network_timeout');
```

### 3. Database Performance Tracking
```dart
// Track critical database operations
await analytics.logDatabaseOperation('load_inventory', durationMs: 150);
await analytics.logDatabaseOperation('save_product', durationMs: 45);
```

### 4. User Interaction Tracking
```dart
// Track empty state interactions
await analytics.logEmptyStateCTAClicked('empty_inventory');

// Track settings changes
await analytics.logSettingChanged('notification_enabled', 'true');

// Track alert feedback
await analytics.logAlertFeedback('alert_123', 'useful');
```

## Best Practices

### 1. Event Naming Convention
- Use snake_case for event names
- Format: `verb_noun_status` (e.g., `flow_started`, `item_added_success`)
- Be consistent across the app

### 2. Parameter Guidelines
- Keep parameter names descriptive but concise
- Use consistent parameter names across similar events
- Avoid PII (personally identifiable information)

### 3. Error Handling
```dart
try {
  await analytics.logCoreAction('item_added');
} catch (e) {
  // Analytics errors should not break app functionality
  print('Analytics error: $e');
}
```

### 4. Performance Considerations
- Analytics calls are async but non-blocking
- Events are queued and sent in batches
- Avoid excessive event logging in tight loops

## Common Patterns

### 1. Screen View Tracking
```dart
class MyScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsService>().logEvent('screen_viewed', parameters: {
        'screen_name': 'inventory',
      });
    });
  }
}
```

### 2. Button Click Tracking
```dart
ElevatedButton(
  onPressed: () async {
    await context.read<AnalyticsService>().logEvent('button_clicked', parameters: {
      'button_name': 'add_product',
      'screen': 'dashboard',
    });
    // Handle button action
  },
  child: Text('Add Product'),
)
```

### 3. Form Completion Tracking
```dart
class FormScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    analytics.logFlowStarted('product_form');
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      await analytics.logFlowCompleted('product_form');
      // Submit form
    } else {
      await analytics.logFlowAbandoned('product_form', reason: 'validation_failed');
    }
  }
}
```

## Debugging Analytics

### 1. Enable Debug Logging
```dart
// In development, enable verbose logging
if (kDebugMode) {
  await analytics.logEvent('debug_event', parameters: {
    'debug_info': 'test_data',
  });
}
```

### 2. Test Events
```dart
// Create test events for development
await analytics.logEvent('test_event', parameters: {
  'test_parameter': 'test_value',
  'timestamp': DateTime.now().millisecondsSinceEpoch,
});
```

### 3. Validate Implementation
```dart
// Check if analytics is properly initialized
if (analytics.observer != null) {
  print('Analytics properly initialized');
} else {
  print('Analytics initialization failed');
}
```

## Privacy and Compliance

### 1. Data Collection Guidelines
- Never log PII (names, emails, addresses)
- Aggregate and anonymize data when possible
- Respect user privacy preferences

### 2. User Consent
```dart
// Check user consent before logging sensitive events
final hasConsent = await SettingsService.hasAnalyticsConsent();
if (hasConsent) {
  await analytics.logEvent('sensitive_event');
}
```

### 3. Data Retention
- Events are automatically managed by Firebase
- Configure retention policies in Firebase Console
- Implement local data cleanup if needed

## Troubleshooting

### Common Issues
1. **Events not appearing**: Check Firebase configuration and network connectivity
2. **Build errors**: Ensure Firebase dependencies are properly configured
3. **Performance issues**: Reduce event frequency or batch events

### Debug Commands
```bash
# Enable Firebase debug mode
adb shell setprop debug.firebase.analytics.app com.ngonnest.ngonnest_app

# View real-time events in Firebase Console DebugView
```

## Integration with Stakeholder Dashboards

### 1. DevOps Metrics
- Monitor `migration_completed` events for database stability
- Track `offline_session_*` events for offline usage patterns
- Watch `db_operation` events for performance optimization

### 2. Finance/Investor Metrics
- Analyze `onboarding_flow_completed` for conversion rates
- Monitor `core_action` events for user engagement
- Track retention through user properties and session data

### 3. Product Owner Metrics
- Review `flow_*` events for UX optimization
- Monitor `empty_state_cta_clicked` for UI effectiveness
- Analyze user paths through custom funnels

### 4. Marketing Metrics
- Track acquisition sources through user properties
- Monitor feature adoption rates
- Analyze user segments for targeting

## Next Steps

1. Implement remaining post-MVP metrics based on product needs
2. Set up custom dashboards in Firebase Console
3. Configure automated alerts for critical metrics
4. Regular review and optimization of tracked events

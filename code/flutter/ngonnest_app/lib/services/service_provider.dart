import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ngonnest_app/services/remote_config_service.dart';
import 'package:ngonnest_app/services/dynamic_content_service.dart';
import 'package:ngonnest_app/services/feature_flag_service.dart';
import 'package:ngonnest_app/services/ab_testing_service.dart';

class ServiceProvider extends StatelessWidget {
  final Widget child;
  
  const ServiceProvider({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Remote Config Service
        Provider<RemoteConfigService>(
          create: (_) => RemoteConfigService(),
          dispose: (_, service) {},
        ),
        
        // Dynamic Content Service
        Provider<DynamicContentService>(
          create: (_) => DynamicContentService(),
          dispose: (_, service) {},
        ),
        
        // Feature Flag Service
        Provider<FeatureFlagService>(
          create: (_) => FeatureFlagService(),
          dispose: (_, service) {},
        ),
        
        // A/B Testing Service
        Provider<ABTestingService>(
          create: (_) => ABTestingService(),
          dispose: (_, service) {},
        ),
      ],
      child: child,
    );
  }
  
  // Helper method to get services from context
  static T of<T>(BuildContext context, {bool listen = false}) {
    try {
      return Provider.of<T>(context, listen: listen);
    } catch (e) {
      debugPrint('Error getting service $T: $e');
      throw Exception('Service $T not found. Make sure ServiceProvider is an ancestor of this widget.');
    }
  }
  
  // Initialize all services
  static Future<void> initializeServices(BuildContext context) async {
    try {
      final remoteConfig = of<RemoteConfigService>(context);
      final dynamicContent = of<DynamicContentService>(context);
      final featureFlags = of<FeatureFlagService>(context);
      final abTesting = of<ABTestingService>(context);
      
      // Initialize services in parallel
      await Future.wait([
        remoteConfig.initialize(),
        dynamicContent.initialize(),
        featureFlags.initialize(),
        abTesting.initialize(),
      ]);
      
      // Preload common content
      await _preloadCommonContent(dynamicContent);
      
    } catch (e) {
      debugPrint('Error initializing services: $e');
      rethrow;
    }
  }
  
  // Preload common content
  static Future<void> _preloadCommonContent(DynamicContentService dynamicContent) async {
    try {
      await dynamicContent.preloadContent([
        'home_banner',
        'premium_features',
        'onboarding_steps',
      ]);
    } catch (e) {
      debugPrint('Error preloading common content: $e');
    }
  }
}

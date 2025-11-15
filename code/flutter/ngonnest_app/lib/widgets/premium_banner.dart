import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ab_testing_service.dart';
import '../services/analytics_service.dart';
import '../services/feature_flag_service.dart';
import '../services/remote_config_service.dart';

class PremiumBanner extends StatefulWidget {
  const PremiumBanner({super.key});

  @override
  State<PremiumBanner> createState() => _PremiumBannerState();
}

class _PremiumBannerState extends State<PremiumBanner> {
  @override
  void initState() {
    super.initState();
    // Track banner exposure when it appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackBannerExposure();
    });
  }

  void _trackBannerExposure() {
    final featureFlagService = context.read<FeatureFlagService>();
    final abTestingService = context.read<ABTestingService>();
    final analytics = context.read<AnalyticsService>();

    // Track feature exposure
    featureFlagService.trackFeatureExposure('premium_banner');

    // Track A/B test exposure
    abTestingService.trackExperimentExposure('homepage_layout_v1');
    abTestingService.trackExperimentExposure('cta_button_color_v1');

    // Track banner exposure
    analytics.logEvent(
      'premium_banner_exposed',
      parameters: {
        'source': 'dashboard',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final remoteConfig = context.watch<RemoteConfigService>();
    final analytics = context.read<AnalyticsService>();

    // Check if premium banner should be shown
    if (!remoteConfig.isPremiumBannerEnabled) {
      return const SizedBox.shrink();
    }

    // Get banner content from Remote Config
    final title = remoteConfig.getString('premium_banner_title');
    final description = remoteConfig.getString('premium_banner_description');

    // Get A/B test variants from Remote Config (simplified)
    final layoutVariant = remoteConfig.getString('homepage_layout_v1_variant');
    final buttonColorVariant = remoteConfig.getString(
      'cta_button_color_v1_variant',
    );

    // Determine button color based on A/B test
    Color buttonColor;
    switch (buttonColorVariant) {
      case 'blue_variant':
        buttonColor = Colors.blue;
        break;
      case 'green_variant':
        buttonColor = Colors.green;
        break;
      default:
        buttonColor = Theme.of(context).primaryColor;
    }

    // Determine layout based on A/B test
    final isNewLayout = layoutVariant == 'variant_a';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
            Theme.of(context).primaryColor.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.yellow.shade400, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),

          // Show premium features if using new layout
          if (isNewLayout) ...[
            const SizedBox(height: 16),
            _buildFeaturesList(remoteConfig),
          ],

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleUpgradeClick(
                    analytics,
                    layoutVariant,
                    buttonColorVariant,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Upgrade Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => _handleDismiss(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.8),
                ),
                child: const Text('Maybe Later'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(RemoteConfigService remoteConfig) {
    final featuresData = remoteConfig.getJson('premium_features_list');
    final features = List<String>.from(featuresData['features'] ?? []);

    if (features.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Premium Features:',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...features.map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.yellow.shade400,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  feature,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleUpgradeClick(
    AnalyticsService analytics,
    String layoutVariant,
    String buttonColorVariant,
  ) {
    // Track the upgrade click event
    analytics.logEvent(
      'premium_upgrade_click',
      parameters: {
        'source': 'banner',
        'layout_variant': layoutVariant,
        'button_color_variant': buttonColorVariant,
      },
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redirecting to premium upgrade...'),
        backgroundColor: Colors.green,
      ),
    );

    // TODO: Navigate to actual premium upgrade/payment screen
    // TODO: Implement in-app purchase flow with revenue tracking
    // TODO: Add subscription management interface
    // Navigator.of(context).pushNamed('/premium-upgrade');
  }

  void _handleDismiss() {
    // Track dismiss action
    context.read<AnalyticsService>().logEvent('premium_banner_dismissed');

    // Hide the banner (you could implement this with a provider)
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Banner dismissed. You can change this in settings.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

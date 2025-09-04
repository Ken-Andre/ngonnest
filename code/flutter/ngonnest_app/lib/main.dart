import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/household_service.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart'; // Import DatabaseService
import 'services/background_task_service.dart'; // Import BackgroundTaskService
import 'theme/app_theme.dart';
import 'theme/theme_mode_notifier.dart'; // Import the new file
import 'screens/preferences_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Workmanager
  Workmanager().initialize(
    callbackDispatcher, // The top-level function specified in background_task_service.dart
    isInDebugMode: true, // Set to false in production
  );

  final constraints = Constraints(
    networkType: NetworkType.connected, // A hint that the task is important
  );

  // Register a periodic task to check for alerts (e.g., every 15 minutes)
  Workmanager().registerPeriodicTask(
    "ngonnest_alert_check_task",
    "alertCheckTask",
    frequency: const Duration(minutes: 15), // Run every 15 minutes
    initialDelay: const Duration(minutes: 1), // Start after 1 minute
    constraints: constraints,
  );

  // Initialize notifications
  await NotificationService.initialize();

  final initialThemeMode = await ThemeModeNotifier.loadThemeMode();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ThemeModeNotifier(initialThemeMode),
        ),
        Provider<DatabaseService>(
          create: (context) => DatabaseService(),
        ), // Provide DatabaseService
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeModeNotifier>().themeMode;
    return MaterialApp(
      title: 'NgonNest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/preferences': (context) => const PreferencesScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 1000));
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 1000));
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      final hasProfile = await HouseholdService.hasHouseholdProfile();

      if (mounted) {
        if (hasProfile) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          Navigator.of(context).pushReplacementNamed('/onboarding');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animation
              ScaleTransition(
                scale: _logoAnimation,
                child: Icon(Icons.home_rounded, size: 120, color: Colors.white),
              ),

              const SizedBox(height: 40),

              // App name animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'NgonNest',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 48,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tagline animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Gestion intelligente de votre foyer',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 80),

              // Loading indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

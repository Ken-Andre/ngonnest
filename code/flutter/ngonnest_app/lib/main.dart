import 'dart:isolate';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:ngonnest_app/services/console_logger.dart';
import 'package:ngonnest_app/services/error_logger_service.dart';
import 'package:ngonnest_app/services/analytics_service.dart';

import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Import for FFI
import 'package:workmanager/workmanager.dart';
import 'l10n/app_localizations.dart';

import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/developer_console_screen.dart';
import 'screens/edit_product_screen.dart';
import 'services/household_service.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart'; // Import DatabaseService
import 'services/background_task_service.dart'; // Import BackgroundTaskService
import 'services/connectivity_service.dart'; // Import ConnectivityService
import 'widgets/connectivity_banner.dart'; // Import ConnectivityBanner
import 'theme/app_theme.dart';
import 'theme/theme_mode_notifier.dart'; // Import the new file
import 'screens/preferences_screen.dart';
import 'providers/locale_provider.dart';
import 'providers/foyer_provider.dart';
import 'services/settings_service.dart';
import 'services/price_service.dart';
import 'services/budget_service.dart';
import 'models/objet.dart'; // Added import for Objet

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (only on mobile platforms)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await Firebase.initializeApp();
      await AnalyticsService().initialize();
      ConsoleLogger.info('[Main] Firebase and Analytics initialized.');
    } catch (e) {
      ConsoleLogger.error('Main', 'FirebaseInit', e);
    }
  }

  // Initialize sqflite FFI for desktop and testing environments
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    ConsoleLogger.info('[Main] SQFlite FFI initialized for desktop.');
  }

  // Initialisation du logger simple
  ConsoleLogger.init(LogMode.debug);

  // 🚀 HOOK GLOBAL ERREURS FLUTTER - Capture 100% des erreurs non gérées
  // Only set up in non-test environments to avoid conflicts with Flutter Test framework
  if (!Platform.environment.containsKey('FLUTTER_TEST')) {
    FlutterError.onError = (FlutterErrorDetails details) async {
      await ErrorLoggerService.logError(
        component: 'FlutterFramework',
        operation: 'renderError',
        error: details.exception,
        stackTrace: details.stack ?? StackTrace.current,
        severity: ErrorSeverity.high,
        metadata: {
          'library': details.library,
          'context': details.context?.toString(),
          'summary': details.summary.toString(),
          'silentCrash': true,
        },
      );
      // Log console également
      debugPrint('🔴 [FLUTTER ERROR] ${details.exception.toString()}');
    };
  }

  // Capture erreurs Isolates non gérées
  Isolate.current.addErrorListener(
    RawReceivePort((dynamic pair) async {
      final errorAndStacktrace = pair as List<dynamic>;
      await ErrorLoggerService.logError(
        component: 'Isolate',
        operation: 'backgroundError',
        error: errorAndStacktrace.first,
        stackTrace: errorAndStacktrace.last ?? StackTrace.current,
        severity: ErrorSeverity.critical,
        metadata: {'isolate': 'background'},
      );
    }).sendPort,
  );

  // Initialize Workmanager only if not on web and not in a test environment
  final isTesting = Platform.environment.containsKey('FLUTTER_TEST');
  if (!kIsWeb && !isTesting) {
    ConsoleLogger.info('[Main] Initializing Workmanager...');
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Désactivé pour respecter la confidentialité
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
    ConsoleLogger.info('[Main] Workmanager initialized and task registered.');
  } else {
    if (isTesting)
      ConsoleLogger.info(
        '[Main] Workmanager initialization skipped (FLUTTER_TEST environment).',
      );
    if (kIsWeb)
      ConsoleLogger.info(
        '[Main] Workmanager initialization skipped (Web environment).',
      );
  }

  // Initialize notifications
  await NotificationService.initialize();

  // Initialize settings service
  await SettingsService.initialize();

  final initialThemeMode = await ThemeModeNotifier.loadThemeMode();

  // Initialize locale provider
  final localeProvider = LocaleProvider();
  await localeProvider.initialize();

  // Initialize foyer provider to retrieve stored household ID
  final foyerProvider = FoyerProvider();
  await foyerProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ThemeModeNotifier(initialThemeMode),
        ),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<FoyerProvider>.value(value: foyerProvider),
        Provider<DatabaseService>(
          create: (context) => DatabaseService(),
        ), // Provide DatabaseService
        Provider<AnalyticsService>(
          create: (context) => AnalyticsService(),
        ), // Provide AnalyticsService
        ChangeNotifierProvider<ConnectivityService>(
          create: (context) => ConnectivityService(),
        ), // Provide ConnectivityService
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
    final locale = context.watch<LocaleProvider>().locale;
    final analyticsService = context.read<AnalyticsService>();

    return MaterialApp(
      navigatorObservers: analyticsService.observer != null
          ? [analyticsService.observer!]
          : [],
      title: 'NgonNest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleProvider.supportedLocales,
      home: const AppWithConnectivityOverlay(child: SplashScreen()),
      routes: {
        '/onboarding': (context) =>
            const AppWithConnectivityOverlay(child: OnboardingScreen()),
        '/preferences': (context) =>
            const AppWithConnectivityOverlay(child: PreferencesScreen()),
        '/dashboard': (context) =>
            const AppWithConnectivityOverlay(child: DashboardScreen()),
        '/add-product': (context) =>
            const AppWithConnectivityOverlay(child: AddProductScreen()),
        '/inventory': (context) =>
            const AppWithConnectivityOverlay(child: InventoryScreen()),
        '/budget': (context) =>
            const AppWithConnectivityOverlay(child: BudgetScreen()),
        '/settings': (context) =>
            const AppWithConnectivityOverlay(child: SettingsScreen()),
        '/developer-console': (context) =>
            const AppWithConnectivityOverlay(child: DeveloperConsoleScreen()),
        '/edit-objet': (context) {
          final objet = ModalRoute.of(context)?.settings.arguments as Objet?;
          if (objet == null) {
            // Optionally, log an error or navigate to a default error screen
            // For now, navigating back to inventory as a fallback
            ErrorLoggerService.logError(
              component: 'MyAppRouter',
              operation: 'navigateToEditObjet',
              error:
                  'Attempted to navigate to /edit-objet with null Objet argument.',
              severity: ErrorSeverity.medium,
              stackTrace: StackTrace.current,
            );
            return const AppWithConnectivityOverlay(child: InventoryScreen());
          }
          return AppWithConnectivityOverlay(
            child: EditProductScreen(objet: objet),
          );
        },
      },
    );
  }
}

/// Wrapper widget qui affiche la bannière de connectivité en overlay sur tous les écrans
class AppWithConnectivityOverlay extends StatelessWidget {
  final Widget child;

  const AppWithConnectivityOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // L'écran principal
        child,
        // La bannière de connectivité en overlay
        Positioned(
          top: MediaQuery.of(context).padding.top + 8, // Respecter la safe area
          left: 16,
          right: 16,
          child: const ConnectivityBanner(),
        ),
      ],
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
      // Initialize Phase 2 components
      await _initializePhase2Components();

      final hasProfile = await HouseholdService.hasHouseholdProfile();

      if (mounted) {
        if (hasProfile) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          Navigator.of(context).pushReplacementNamed('/onboarding');
        }
      }
    } catch (e, stackTrace) {
      // Added stackTrace
      await ErrorLoggerService.logError(
        // Log error during user status check
        component: 'SplashScreen',
        operation: '_checkUserStatus',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
      );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    }
  }

  Future<void> _initializePhase2Components() async {
    try {
      // Initialize product prices database
      await PriceService.initializeProductPrices();

      // Initialize recommended budgets if user has a profile
      final hasProfile = await HouseholdService.hasHouseholdProfile();
      if (hasProfile) {
        final foyerId = context.read<FoyerProvider>().foyerId;
        if (foyerId != null) {
          await BudgetService.initializeRecommendedBudgets(foyerId);
        }
      }
    } catch (e, stackTrace) {
      // Added stackTrace
      // Log error but don't block app startup
      await ErrorLoggerService.logError(
        component: 'SplashScreen',
        operation: '_initializePhase2Components',
        error: e,
        stackTrace: stackTrace, // Pass stackTrace
        severity: ErrorSeverity.medium,
      );
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

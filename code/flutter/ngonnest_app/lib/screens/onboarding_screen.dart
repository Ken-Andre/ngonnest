import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/foyer.dart';
import '../models/household_profile.dart';
import '../providers/foyer_provider.dart';
import '../services/analytics_service.dart';
import '../services/household_service.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  PageController _pageController = PageController();
  int _currentStep = 0;
  String _selectedLanguage = Language.francais;
  String _selectedHouseholdSize = '';
  String _selectedHousingType = '';
  bool _isLoading = false;
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _roomsController = TextEditingController();

  final List<Map<String, dynamic>> _householdSizes = [
    {
      'id': 'small',
      'label': 'Petit (1-2 personnes)',
      'icon': '👤',
      'personCount': 2,
    },
    {
      'id': 'medium',
      'label': 'Moyen (3-4 personnes)',
      'icon': '👥',
      'personCount': 4,
    },
    {
      'id': 'large',
      'label': 'Grand (5+ personnes)',
      'icon': '👨‍👩‍👧‍👦',
      'personCount': 6,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Track onboarding started
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsService>().logOnboardingStarted();
      context.read<AnalyticsService>().logFlowStarted('onboarding');
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _budgetController.dispose();
    _roomsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _submitOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isLoading = true);

    try {
      // Utiliser firstWhere avec orElse pour éviter les exceptions
      final selectedSizeData = _householdSizes.firstWhere(
        (size) => size['id'] == _selectedHouseholdSize,
        orElse: () => _householdSizes.first, // Valeur par défaut
      );

      final nbPersonnes = selectedSizeData['personCount'] as int;
      final nbPieces = nbPersonnes <= 2
          ? 2
          : nbPersonnes <= 4
          ? 3
          : 4;
      final budget = double.tryParse(
        _budgetController.text.replaceAll(',', '.'),
      );
      // final nbPieces = int.tryParse(_roomsController.text) ?? 0;

      final foyer = Foyer(
        nbPersonnes: nbPersonnes,
        nbPieces: nbPieces,
        typeLogement: _selectedHousingType,
        langue: _selectedLanguage,
        budgetMensuelEstime: budget,
      );

      final id = await HouseholdService.saveFoyer(foyer);
      if (!mounted) return;
      final savedFoyer = foyer.copyWith(id: id.toString());
      context.read<FoyerProvider>().setFoyer(savedFoyer);

      // Track onboarding completion and household profile setup
      final analyticsService = context.read<AnalyticsService>();
      await analyticsService.logOnboardingCompleted();
      await analyticsService.logFlowCompleted('onboarding');
      await analyticsService.setHouseholdProfile(
        householdSize: nbPersonnes,
        householdType: _selectedHousingType,
        primaryLanguage: _selectedLanguage,
      );

      if (mounted) {
        // Show sync offer dialog after profile creation
        await _showSyncOfferDialog();
      }
    } catch (e, stackTrace) {
      // Log the error for debugging
      print('Backup Error: $e');
      print('StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutralLightGrey,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress and back button
            _buildHeader(),

            // Content area
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildLanguageStep(),
                  _buildHouseholdSizeStep(),
                  _buildHousingTypeStep(),
                  _buildBudgetStep(),
                  _buildRoomsStep(),
                ],
              ),
            ),

            // Bottom section with navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Back button row
          if (_currentStep > 0)
            Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _previousStep,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.back,
                        color: AppTheme.primaryGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Retour',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          const SizedBox(height: 12),

          // Progress indicator
          Row(
            children: List.generate(5, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 4 ? 6 : 0),
                  height: 3,
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? AppTheme.primaryGreen
                        : AppTheme.neutralGrey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageStep() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Welcome section - Reduced padding
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20), // Reduced from 32
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '🏠',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontSize: 32,
                          ), // Reduced font size using theme
                    ),
                    const SizedBox(height: 12), // Reduced from 24
                    Text(
                      'Bienvenue !',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neutralBlack,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8), // Reduced from 16
                    Text(
                      'NgonNest vous aide à gérer vos produits ménagers facilement',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.neutralGrey,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20), // Reduced from 40

              Text(
                'Sélectionnez votre langue',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutralBlack,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 12), // Reduced from 24
              // Language options
              ...Language.values.map((lang) => _buildLanguageOption(lang)),

              const SizedBox(height: 16),

              // Time estimate - Moved above spacer, wrapped in container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.clock,
                      color: AppTheme.primaryGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      // Added Expanded to prevent overflow
                      child: Text(
                        'Temps estimé: < 2 minutes',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Minimum spacing at bottom for navigation
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String lang) {
    final isSelected = _selectedLanguage == lang;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => setState(() => _selectedLanguage = lang),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryGreen
                  : AppTheme.neutralGrey.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Text(Language.getFlag(lang), style: TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  Language.getDisplayName(lang),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.neutralBlack,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: Colors.white,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHouseholdSizeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          Text(
            'Votre foyer',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.neutralBlack,
              fontSize: 24,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Sélectionnez la taille de votre foyer',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.neutralGrey,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),

          // Household size options
          ..._householdSizes.map((size) => _buildHouseholdSizeOption(size)),

          // Minimum spacing at bottom for navigation
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildHouseholdSizeOption(Map<String, dynamic> size) {
    final isSelected = _selectedHouseholdSize == size['id'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => setState(() => _selectedHouseholdSize = size['id']!),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryGreen
                  : AppTheme.neutralGrey.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(size['icon']!, style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      size['label']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.neutralBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Recommandé pour ${size['personCount']} personnes',
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppTheme.neutralGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: Colors.white,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHousingTypeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          Text(
            'Type de logement',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.neutralBlack,
              fontSize: 24,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Pour des recommandations personnalisées',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.neutralGrey,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),

          // Housing type options
          ...LogementType.values.map((type) => _buildHousingTypeOption(type)),

          // Minimum spacing at bottom for navigation
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildHousingTypeOption(String type) {
    final isSelected = _selectedHousingType == type;
    final icon = type == LogementType.appartement
        ? CupertinoIcons.building_2_fill
        : CupertinoIcons.house_fill;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => setState(() => _selectedHousingType = type),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryGreen
                  : AppTheme.neutralGrey.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? Colors.white : AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  LogementType.getDisplayName(type),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.neutralBlack,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: Colors.white,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Budget mensuel estimé',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.neutralBlack,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppTheme.neutralBlack, fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'Montant en €',
              filled: true,
              fillColor: AppTheme.neutralWhite,
              labelStyle: TextStyle(color: AppTheme.neutralGrey, fontSize: 16),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildRoomsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Nombre de pièces',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.neutralBlack,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _roomsController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.neutralBlack, fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'Pièces',
              filled: true,
              fillColor: AppTheme.neutralWhite,
              labelStyle: TextStyle(color: AppTheme.neutralGrey, fontSize: 16),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    bool canProceed = false;

    switch (_currentStep) {
      case 0:
        canProceed = _selectedLanguage.isNotEmpty;
        break;
      case 1:
        canProceed = _selectedHouseholdSize.isNotEmpty;
        break;
      case 2:
        canProceed = _selectedHousingType.isNotEmpty;
        break;
      case 3:
        // Allow proceeding if budget field is empty or contains a valid number
        final budgetText = _budgetController.text.trim();
        canProceed = budgetText.isEmpty || _isValidNumber(budgetText);
        break;
      case 4:
        // Allow proceeding if rooms field is empty or contains a valid integer
        final roomsText = _roomsController.text.trim();
        canProceed = roomsText.isEmpty || _isValidInteger(roomsText);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 16),
          color: canProceed && !_isLoading
              ? AppTheme.primaryGreen
              : AppTheme.neutralGrey,
          borderRadius: BorderRadius.circular(12),
          onPressed: canProceed && !_isLoading ? _nextStep : null,
          child: _isLoading
              ? const CupertinoActivityIndicator(color: Colors.white)
              : Text(
                  _currentStep == 4 ? 'Terminer' : 'Continuer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  /// Helper method to check if a string represents a valid number
  bool _isValidNumber(String value) {
    final number = double.tryParse(value.replaceAll(',', '.'));
    return number != null && number >= 0;
  }

  /// Helper method to check if a string represents a valid integer
  bool _isValidInteger(String value) {
    final number = int.tryParse(value);
    return number != null && number >= 0;
  }

  /// Show sync offer dialog after profile creation
  Future<void> _showSyncOfferDialog() async {
    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(CupertinoIcons.cloud, color: AppTheme.primaryGreen, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.syncDataQuestion,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutralBlack,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.syncDataExplanation,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.neutralGrey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.info_circle,
                    color: AppTheme.primaryGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vos données restent privées et sécurisées',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.noLater,
              style: TextStyle(color: AppTheme.neutralGrey, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              l10n.yes,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      // User accepted sync - navigate to authentication
      await _handleSyncAccepted();
    } else {
      // User declined sync - show message and continue to dashboard
      await _handleSyncDeclined();
    }
  }

  /// Handle when user accepts sync offer
  Future<void> _handleSyncAccepted() async {
    if (!mounted) return;

    // Navigate to authentication screen with onboarding context
    Navigator.of(context).pushReplacementNamed(
      '/authentication',
      arguments: {
        'source': 'onboarding',
        'contextMessage': 'Connectez-vous pour activer la synchronisation',
      },
    );
  }

  /// Handle when user declines sync offer
  Future<void> _handleSyncDeclined() async {
    final l10n = AppLocalizations.of(context)!;

    // Show message about enabling sync later
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.syncLaterMessage),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );

      // Log analytics event
      final analyticsService = context.read<AnalyticsService>();
      await analyticsService.logEvent('onboarding_sync_declined');

      // Navigate to dashboard
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/foyer.dart';
import '../models/household_profile.dart';
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

  final List<Map<String, dynamic>> _householdSizes = [
    {'id': 'small', 'label': 'Petit (1-2 personnes)', 'icon': '👤', 'personCount': 2},
    {'id': 'medium', 'label': 'Moyen (3-4 personnes)', 'icon': '👥', 'personCount': 4},
    {'id': 'large', 'label': 'Grand (5+ personnes)', 'icon': '👨‍👩‍👧‍👦', 'personCount': 6},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
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
      final selectedSizeData = _householdSizes.firstWhere((size) => size['id'] == _selectedHouseholdSize);
      final nbPersonnes = selectedSizeData['personCount'] as int;
      final nbPieces = nbPersonnes <= 2 ? 2 : nbPersonnes <= 4 ? 3 : 4;

      final foyer = Foyer(
        nbPersonnes: nbPersonnes,
        nbPieces: nbPieces,
        typeLogement: _selectedHousingType,
        langue: _selectedLanguage,
      );

      await HouseholdService.saveFoyer(foyer);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
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
      padding: const EdgeInsets.all(16),
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
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Retour',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 16),
          
          // Progress indicator
          Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: index <= _currentStep 
                        ? AppTheme.primaryGreen 
                        : AppTheme.neutralGrey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          // Welcome section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '🏠',
                  style: TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 24),
                Text(
                  'Bienvenue !',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neutralBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'NgonNest vous aide à gérer vos produits ménagers facilement',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.neutralGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          Text(
            'Sélectionnez votre langue',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.neutralBlack,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Language options
          ...Language.values.map((lang) => _buildLanguageOption(lang)),
          
          const Spacer(),
          
          // Time estimate
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.clock,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Temps estimé: < 2 minutes',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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
              color: isSelected ? AppTheme.primaryGreen : AppTheme.neutralGrey.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Text(
                Language.getFlag(lang),
                style: TextStyle(fontSize: 24),
              ),
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          Text(
            'Votre foyer',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.neutralBlack,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Sélectionnez la taille de votre foyer',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.neutralGrey,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Household size options
          ..._householdSizes.map((size) => _buildHouseholdSizeOption(size)),
          
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildHouseholdSizeOption(Map<String, dynamic> size) {
    final isSelected = _selectedHouseholdSize == size['id'];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => setState(() => _selectedHouseholdSize = size['id']!),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryGreen : AppTheme.neutralGrey.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.2) 
                      : AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    size['icon']!,
                    style: TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      size['label']!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.neutralBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recommandé pour ${size['personCount']} personnes',
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected 
                            ? Colors.white.withOpacity(0.8) 
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
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHousingTypeStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          
          Text(
            'Type de logement',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.neutralBlack,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Pour des recommandations personnalisées',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.neutralGrey,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Housing type options
          ...LogementType.values.map((type) => _buildHousingTypeOption(type)),
          
          const Spacer(),
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
      margin: const EdgeInsets.only(bottom: 16),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => setState(() => _selectedHousingType = type),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryGreen : AppTheme.neutralGrey.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.2) 
                      : AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isSelected ? Colors.white : AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  LogementType.getDisplayName(type),
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
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final canProceed = _currentStep == 0 && _selectedLanguage.isNotEmpty ||
        _currentStep == 1 && _selectedHouseholdSize.isNotEmpty ||
        _currentStep == 2 && _selectedHousingType.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 16),
          color: canProceed ? AppTheme.primaryGreen : AppTheme.neutralGrey,
          borderRadius: BorderRadius.circular(16),
          onPressed: canProceed && !_isLoading ? _nextStep : null,
          child: _isLoading
              ? const CupertinoActivityIndicator(color: Colors.white)
              : Text(
                  _currentStep == 2 ? 'Terminer' : 'Continuer',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

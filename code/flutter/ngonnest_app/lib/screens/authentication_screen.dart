import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_import_service.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cloud_import_dialog.dart';

/// Écran d'authentification pour NgonNest
/// Permet la connexion via email/mot de passe ou OAuth (Google, Apple)
class AuthenticationScreen extends StatefulWidget {
  final String? contextMessage;
  final String? source;

  const AuthenticationScreen({super.key, this.contextMessage, this.source});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AuthService _authService;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _authService = AuthService.instance;

    // Listen to auth service changes
    _authService.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {
        _isLoading = _authService.isLoading;
        _errorMessage = _authService.errorMessage;
      });

      // Handle successful authentication from onboarding
      if (_authService.isAuthenticated && widget.source == 'onboarding') {
        _handleOnboardingAuthSuccess();
      }

      // Handle successful authentication from settings
      if (_authService.isAuthenticated && widget.source == 'settings') {
        _handleSettingsAuthSuccess();
      }
    }
  }

  /// Handle successful authentication from onboarding flow
  Future<void> _handleOnboardingAuthSuccess() async {
    try {
      // Check for cloud data
      final cloudImportService = CloudImportService();
      final hasCloudData = await cloudImportService.checkCloudData();

      if (hasCloudData) {
        // Show cloud import dialog
        await _showCloudImportDialog(cloudImportService);
      } else {
        // No cloud data, enable sync and navigate to dashboard
        await _enableSyncAndNavigate();
      }
    } catch (e) {
      // Handle error gracefully
      await _enableSyncAndNavigate();
    }
  }

  /// Show cloud import dialog for onboarding flow
  Future<void> _showCloudImportDialog(
    CloudImportService cloudImportService,
  ) async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CloudImportDialog(
        cloudImportService: cloudImportService,
        onImportComplete: () {
          // Import completed, enable sync and navigate
          _enableSyncAndNavigate();
        },
      ),
    );

    if (result == false || result == null) {
      // User skipped import, still enable sync and navigate
      await _enableSyncAndNavigate();
    }
  }

  /// Handle successful authentication from settings flow
  Future<void> _handleSettingsAuthSuccess() async {
    try {
      // Check for cloud data
      final cloudImportService = CloudImportService();
      final hasCloudData = await cloudImportService.checkCloudData();

      if (hasCloudData) {
        // Show import options dialog for settings
        await _showSettingsImportDialog(cloudImportService);
      } else {
        // No cloud data, just return success to settings screen
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      // Handle error gracefully, still return success
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  /// Show import options dialog for settings flow
  Future<void> _showSettingsImportDialog(
    CloudImportService cloudImportService,
  ) async {
    if (!mounted) return;

    // For now, just return success - import options will be handled in settings
    // This will be enhanced in subtask 6.4
    Navigator.of(context).pop(true);
  }

  /// Enable sync service and navigate to dashboard
  Future<void> _enableSyncAndNavigate() async {
    try {
      final syncService = SyncService();
      await syncService.enableSync(userConsent: true);

      // Trigger initial sync if no cloud data (to upload local profile)
      final cloudImportService = CloudImportService();
      final hasCloudData = await cloudImportService.checkCloudData();

      if (!hasCloudData) {
        // No cloud data exists, trigger initial sync to upload local data
        await syncService.forceSyncWithFeedback(null);
      }

      // Log analytics event
      final analyticsService = AnalyticsService();
      await analyticsService.logEvent('onboarding_completed_with_sync');

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      // Even if sync fails, navigate to dashboard
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    }
  }

  void _clearMessages() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
    _authService.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo and welcome section
              _buildHeader(context, l10n),

              const SizedBox(height: 32),

              // Context message if provided
              if (widget.contextMessage != null) ...[
                _buildContextMessage(context),
                const SizedBox(height: 24),
              ],

              // Tab bar for Email and OAuth
              _buildTabBar(context, l10n),

              const SizedBox(height: 24),

              // Tab view content
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 300,
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: _EmailAuthTab(
                          onClearMessages: _clearMessages,
                          isLoading: _isLoading,
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: _OAuthTab(
                          onClearMessages: _clearMessages,
                          isLoading: _isLoading,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Error message display
              if (_errorMessage != null) _buildErrorMessage(context),

              // Success message display
              if (_successMessage != null) _buildSuccessMessage(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // NgonNest logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.home_rounded, size: 40, color: Colors.white),
        ),

        const SizedBox(height: 16),

        // App name
        Text(
          l10n.appTitle,
          style: theme.textTheme.displayMedium?.copyWith(
            color: AppTheme.primaryGreen,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        // Welcome message
        Text(
          'Bienvenue !',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildContextMessage(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.contextMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: theme.colorScheme.onSurface,
        labelStyle: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.titleMedium,
        tabs: const [
          Tab(text: 'Email', icon: Icon(Icons.email_outlined)),
          Tab(text: 'Réseaux sociaux', icon: Icon(Icons.share_outlined)),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.primaryRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _successMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Email authentication tab with form validation
class _EmailAuthTab extends StatefulWidget {
  final VoidCallback onClearMessages;
  final bool isLoading;

  const _EmailAuthTab({required this.onClearMessages, required this.isLoading});

  @override
  State<_EmailAuthTab> createState() => _EmailAuthTabState();
}

class _EmailAuthTabState extends State<_EmailAuthTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();

  bool _isSignUpMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir votre email';
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir votre mot de passe';
    }

    if (value.length < 6) {
      return 'Mot de passe trop court (min 6 caractères)';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (_isSignUpMode) {
      if (value == null || value.isEmpty) {
        return 'Veuillez confirmer votre mot de passe';
      }

      if (value != _passwordController.text) {
        return 'Les mots de passe ne correspondent pas';
      }
    }

    return null;
  }

  String? _validateFullName(String? value) {
    if (_isSignUpMode) {
      if (value == null || value.isEmpty) {
        return 'Veuillez saisir votre nom complet';
      }

      if (value.trim().split(' ').length < 2) {
        return 'Veuillez saisir votre prénom et nom';
      }
    }

    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.onClearMessages();

    try {
      final authService = AuthService.instance;

      if (_isSignUpMode) {
        await authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
        );
      } else {
        await authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (mounted && authService.isAuthenticated) {
        // Success - navigation will be handled by parent
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSignUpMode
                  ? 'Compte créé avec succès !'
                  : 'Connexion réussie !',
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      // Error handling is done by AuthService and displayed in parent
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignUpMode = !_isSignUpMode;
      // Clear form when switching modes
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _fullNameController.clear();
    });
    widget.onClearMessages();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full name field (only in sign-up mode)
          if (_isSignUpMode) ...[
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                hintText: 'Prénom Nom',
                prefixIcon: Icon(Icons.person_outline),
              ),
              textInputAction: TextInputAction.next,
              validator: _validateFullName,
              enabled: !widget.isLoading,
            ),
            const SizedBox(height: 16),
          ],

          // Email field
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'votre@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validateEmail,
            enabled: !widget.isLoading,
          ),

          const SizedBox(height: 16),

          // Password field
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              hintText: 'Minimum 6 caractères',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: _isSignUpMode
                ? TextInputAction.next
                : TextInputAction.done,
            validator: _validatePassword,
            enabled: !widget.isLoading,
            onFieldSubmitted: _isSignUpMode ? null : (_) => _handleSubmit(),
          ),

          // Confirm password field (only in sign-up mode)
          if (_isSignUpMode) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                hintText: 'Retapez votre mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              validator: _validateConfirmPassword,
              enabled: !widget.isLoading,
              onFieldSubmitted: (_) => _handleSubmit(),
            ),
          ],

          const SizedBox(height: 24),

          // Submit button
          ElevatedButton(
            onPressed: widget.isLoading ? null : _handleSubmit,
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isSignUpMode ? 'Créer un compte' : 'Se connecter',
                    style: const TextStyle(fontSize: 18),
                  ),
          ),

          const SizedBox(height: 16),

          // Toggle between sign-in and sign-up
          TextButton(
            onPressed: widget.isLoading ? null : _toggleMode,
            child: Text(
              _isSignUpMode
                  ? 'Déjà un compte ? Se connecter'
                  : 'Pas de compte ? Créer un compte',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// OAuth authentication tab with Google and Apple sign-in buttons
class _OAuthTab extends StatefulWidget {
  final VoidCallback onClearMessages;
  final bool isLoading;

  const _OAuthTab({required this.onClearMessages, required this.isLoading});

  @override
  State<_OAuthTab> createState() => _OAuthTabState();
}

class _OAuthTabState extends State<_OAuthTab> {
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    widget.onClearMessages();

    try {
      final authService = AuthService.instance;
      final success = await authService.signInWithGoogle();

      if (mounted && success && authService.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion Google réussie !'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      // Error handling is done by AuthService and displayed in parent
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isAppleLoading = true;
    });

    widget.onClearMessages();

    try {
      final authService = AuthService.instance;
      final success = await authService.signInWithApple();

      if (mounted && success && authService.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion Apple réussie !'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      // Error handling is done by AuthService and displayed in parent
    } finally {
      if (mounted) {
        setState(() {
          _isAppleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAnyLoading =
        widget.isLoading || _isGoogleLoading || _isAppleLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Information text
        Text(
          'Connectez-vous rapidement avec votre compte existant',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Google Sign-In Button
        _OAuthButton(
          onPressed: isAnyLoading ? null : _handleGoogleSignIn,
          isLoading: _isGoogleLoading,
          icon: _buildGoogleIcon(),
          text: 'Continuer avec Google',
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          borderColor: Colors.grey.shade300,
        ),

        const SizedBox(height: 16),

        // Apple Sign-In Button
        _OAuthButton(
          onPressed: isAnyLoading ? null : _handleAppleSignIn,
          isLoading: _isAppleLoading,
          icon: const Icon(Icons.apple, color: Colors.white, size: 24),
          text: 'Continuer avec Apple',
          backgroundColor: Colors.black,
          textColor: Colors.white,
          borderColor: Colors.black,
        ),

        const SizedBox(height: 32),

        // Divider with "ou" text
        Row(
          children: [
            Expanded(
              child: Divider(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ou',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Link to email tab
        TextButton(
          onPressed: isAnyLoading
              ? null
              : () {
                  // Switch to email tab
                  final authScreen = context
                      .findAncestorStateOfType<_AuthenticationScreenState>();
                  authScreen?._tabController.animateTo(0);
                },
          child: Text(
            'Utiliser votre email',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://developers.google.com/identity/images/g-logo.png',
          ),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// Custom OAuth button widget
class _OAuthButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget icon;
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const _OAuthButton({
    required this.onPressed,
    required this.isLoading,
    required this.icon,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

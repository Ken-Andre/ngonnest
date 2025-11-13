import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_import_service.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../utils/autofill_utils.dart';
import '../widgets/cloud_import_dialog.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

/// Écran d'authentification unifié pour NgonNest
/// Interface unique avec email/mot de passe et OAuth (Google, Apple)
class AuthenticationScreen extends StatefulWidget {
  final String? contextMessage;
  final String? source;

  const AuthenticationScreen({super.key, this.contextMessage, this.source});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  late AuthService _authService;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUpMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  String? _errorMessage;
  String? _successMessage;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;
  bool _awaitingEmailConfirmation = false;
  int _resendCooldownSeconds = 0;
  Timer? _resendTimer;
  bool _isNavigating = false; // Prevent multiple navigation attempts

  @override
  void initState() {
    super.initState();
    _authService = AuthService.instance;

    // Listen to auth service changes
    _authService.addListener(_onAuthStateChanged);

    // Listen for deep links for email confirmation
    _setupDeepLinkListener();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _authService.removeListener(_onAuthStateChanged);
    _linkSub?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {
        _isLoading = _authService.isLoading;
        _errorMessage = _authService.errorMessage;
      });

      // Handle successful authentication from onboarding
      if (_authService.isAuthenticated && widget.source == 'onboarding' && !_isNavigating) {
        _isNavigating = true;
        _handleOnboardingAuthSuccess();
        return;
      }

      // Handle successful authentication from settings
      if (_authService.isAuthenticated && widget.source == 'settings' && !_isNavigating) {
        _isNavigating = true;
        _handleSettingsAuthSuccess();
        return;
      }

      // Handle successful authentication from regular login/signup (no specific source)
      if (_authService.isAuthenticated && widget.source == null && !_isNavigating) {
        _isNavigating = true;
        _handleRegularAuthSuccess();
        return;
      }
    }
  }

  void _setupDeepLinkListener() {
    _appLinks = AppLinks();
    // Stream listener
    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingLink(uri);
    }, onError: (_) {});
  }

  void _handleIncomingLink(Uri uri) async {
    // Expecting: io.supabase.ngonnest:/login-callback/ or http://localhost:3000/?code=...
    // Handle both the app deep link and the localhost redirect (when user clicks email on different device)
    if (uri.scheme == 'io.supabase.ngonnest' && uri.path.contains('login-callback')) {
      if (!mounted) return;
      // Exchange code for session if there's a code parameter
      final code = uri.queryParameters['code'];
      if (code != null) {
        try {
          await _authService.exchangeCodeForSession(code);
        } catch (e) {
          // Error already handled by AuthService
        }
      }
      setState(() {
        _isSignUpMode = false; // Switch to sign-in
        _awaitingEmailConfirmation = false;
        _successMessage = AppLocalizations.of(context)!.signInSuccessful;
        _errorMessage = null;
      });
    } else if (uri.host == 'localhost' && uri.queryParameters.containsKey('code')) {
      // Handle localhost redirect (from email clicked on different device)
      final code = uri.queryParameters['code'];
      if (code != null && mounted) {
        try {
          await _authService.exchangeCodeForSession(code);
          if (mounted && _authService.isAuthenticated) {
            setState(() {
              _isSignUpMode = false;
              _awaitingEmailConfirmation = false;
              _successMessage = AppLocalizations.of(context)!.signInSuccessful;
              _errorMessage = null;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Erreur lors de la confirmation. Veuillez réessayer de vous connecter.';
            });
          }
        }
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

  /// Handle successful authentication from regular login/signup flow
  Future<void> _handleRegularAuthSuccess() async {
    try {
      // Check for cloud data
      final cloudImportService = CloudImportService();
      final hasCloudData = await cloudImportService.checkCloudData();

      if (!mounted) return;

      if (hasCloudData) {
        // Show cloud import dialog
        await _showCloudImportDialog(cloudImportService);
      } else {
        // No cloud data, enable sync and navigate to dashboard
        await _enableSyncAndNavigate();
      }
    } catch (e) {
      // Handle error gracefully - still navigate to dashboard
      if (mounted) {
        await _enableSyncAndNavigate();
      }
    }
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

  bool get _isAnyLoading => _isLoading || _isGoogleLoading || _isAppleLoading;

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context)!;

    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterEmail;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return l10n.invalidEmail;
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context)!;

    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterPassword;
    }

    if (value.length < 8) {
      return l10n.passwordTooShort;
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final l10n = AppLocalizations.of(context)!;

    if (_isSignUpMode) {
      if (value == null || value.isEmpty) {
        return l10n.pleaseConfirmPassword;
      }

      if (value != _passwordController.text) {
        return l10n.passwordsDoNotMatch;
      }
    }

    return null;
  }

  String? _validateFullName(String? value) {
    final l10n = AppLocalizations.of(context)!;

    if (_isSignUpMode) {
      if (value == null || value.isEmpty) {
        return l10n.pleaseEnterFullName;
      }

      if (value.trim().split(' ').length < 2) {
        return l10n.pleaseEnterFirstAndLastName;
      }
    }

    return null;
  }

  Future<void> _handleEmailSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _clearMessages();

    try {
      final authService = AuthService.instance;
      final l10n = AppLocalizations.of(context)!;

      if (_isSignUpMode) {
        await authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
        );
        // Always show email confirmation guidance after signup
        // Supabase may return a session but email still needs confirmation
        if (mounted) {
          setState(() {
            _awaitingEmailConfirmation = true;
            // Show both success and guidance message
            _successMessage = '${l10n.accountCreatedSuccessfully}\n\n${l10n.checkYourEmailToConfirm}';
          });
        }
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
                  ? l10n.accountCreatedSuccessfully
                  : l10n.signInSuccessful,
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      // Error handling is done by AuthService and displayed in parent
    }
  }

  Future<void> _handleResendConfirmation() async {
    if (_resendCooldownSeconds > 0) return;
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    final ok = await _authService.resendConfirmationEmail(email);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      if (ok) {
        _successMessage = l10n.success;
        _startResendCooldown(60);
      } else {
        _errorMessage = _authService.errorMessage ?? l10n.networkError;
        _startResendCooldown(60);
      }
    });
  }

  void _startResendCooldown(int seconds) {
    _resendCooldownSeconds = seconds;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _resendCooldownSeconds--;
        if (_resendCooldownSeconds <= 0) {
          _resendCooldownSeconds = 0;
          t.cancel();
        }
      });
    });
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    _clearMessages();

    try {
      final authService = AuthService.instance;
      final l10n = AppLocalizations.of(context)!;
      final success = await authService.signInWithGoogle();

      if (mounted && success && authService.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.googleSignInSuccessful),
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

    _clearMessages();

    try {
      final authService = AuthService.instance;
      final l10n = AppLocalizations.of(context)!;
      final success = await authService.signInWithApple();

      if (mounted && success && authService.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.appleSignInSuccessful),
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
    _clearMessages();
  }

  Widget _buildGoogleIcon() {
    // Use a simple icon for tests to avoid network issues
    return const Icon(Icons.g_mobiledata, color: Colors.blue, size: 24);
  }

  Widget _buildOAuthButton({
    required VoidCallback? onPressed,
    required bool isLoading,
    required Widget icon,
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
  }) {
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

              // Unified authentication form
              _buildAuthForm(context, l10n),

              const SizedBox(height: 24),

              // Social login divider
              _buildSocialDivider(context, l10n),

              const SizedBox(height: 24),

              // Social login buttons
              _buildSocialButtons(context, l10n),

              const SizedBox(height: 24),

              // Sign up toggle
              _buildSignUpToggle(context, l10n),

              const SizedBox(height: 16),

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

        // Welcome message - now localized
        Text(
          l10n.welcome,
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

  Widget _buildAuthForm(BuildContext context, AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full name field (only in sign-up mode)
          if (_isSignUpMode) ...[
            TextFormField(
              controller: _fullNameController,
              decoration: AutofillUtils.applyAutofillDecoration(
                InputDecoration(
                  labelText: l10n.fullName,
                  hintText: l10n.pleaseEnterFirstAndLastName,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                label: l10n.fullName,
                icon: Icons.person_outline,
              ),
              textInputAction: TextInputAction.next,
              autofillHints: AutofillUtils.getFullNameAutofillHints(),
              keyboardType: AutofillUtils.getFullNameInputType(),
              validator: _validateFullName,
              enabled: !_isAnyLoading,
            ),
            const SizedBox(height: 16),
          ],

          // Email field
          TextFormField(
            controller: _emailController,
            decoration: AutofillUtils.applyAutofillDecoration(
              InputDecoration(
                labelText: l10n.email,
                hintText: 'votre@email.com',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              label: l10n.email,
              icon: Icons.email_outlined,
            ),
            keyboardType: AutofillUtils.getEmailInputType(),
            textInputAction: TextInputAction.next,
            autofillHints: AutofillUtils.getEmailAutofillHints(),
            validator: _validateEmail,
            enabled: !_isAnyLoading,
          ),

          const SizedBox(height: 16),

          // Password field
          TextFormField(
            controller: _passwordController,
            decoration: AutofillUtils.applyAutofillDecoration(
              InputDecoration(
                labelText: l10n.password,
                hintText: l10n.passwordTooShort,
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
              label: l10n.password,
              icon: Icons.lock_outline,
            ),
            obscureText: _obscurePassword,
            textInputAction: _isSignUpMode
                ? TextInputAction.next
                : TextInputAction.done,
            autofillHints: AutofillUtils.getPasswordAutofillHints(),
            keyboardType: AutofillUtils.getPasswordInputType(),
            validator: _validatePassword,
            enabled: !_isAnyLoading,
            onFieldSubmitted: _isSignUpMode
                ? null
                : (_) => _handleEmailSubmit(),
          ),

          // Confirm password field (only in sign-up mode)
          if (_isSignUpMode) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: AutofillUtils.applyAutofillDecoration(
                InputDecoration(
                  labelText: l10n.confirmPassword,
                  hintText: l10n.pleaseConfirmPassword,
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
                label: l10n.confirmPassword,
                icon: Icons.lock_outline,
              ),
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              autofillHints: AutofillUtils.getConfirmPasswordAutofillHints(),
              keyboardType: AutofillUtils.getPasswordInputType(),
              validator: _validateConfirmPassword,
              enabled: !_isAnyLoading,
              onFieldSubmitted: (_) => _handleEmailSubmit(),
            ),
          ],

          const SizedBox(height: 24),

          // Submit button
          ElevatedButton(
            onPressed: _isAnyLoading ? null : _handleEmailSubmit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isSignUpMode ? l10n.signUp : l10n.signIn,
                    style: const TextStyle(fontSize: 18),
                  ),
          ),

          // Post-signup guidance and resend
          if (_isSignUpMode && _awaitingEmailConfirmation) ...[
            const SizedBox(height: 12),
            Text(
              l10n.accountCreatedSuccessfully,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: (_isAnyLoading || _resendCooldownSeconds > 0)
                    ? null
                    : _handleResendConfirmation,
                child: Text(
                  _resendCooldownSeconds > 0
                      ? '${l10n.retry} (${_resendCooldownSeconds}s)'
                      : l10n.retry,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSocialDivider(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Divider(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.or,
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
    );
  }

  Widget _buildSocialButtons(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Google Sign-In Button
        _buildOAuthButton(
          onPressed: _isAnyLoading ? null : _handleGoogleSignIn,
          isLoading: _isGoogleLoading,
          icon: _buildGoogleIcon(),
          text: l10n.continueWithGoogle,
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          borderColor: Colors.grey.shade300,
        ),

        const SizedBox(height: 16),

        // Apple Sign-In Button
        _buildOAuthButton(
          onPressed: _isAnyLoading ? null : _handleAppleSignIn,
          isLoading: _isAppleLoading,
          icon: const Icon(Icons.apple, color: Colors.white, size: 24),
          text: l10n.continueWithApple,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          borderColor: Colors.black,
        ),
      ],
    );
  }

  Widget _buildSignUpToggle(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: _isAnyLoading ? null : _toggleMode,
      child: Text(
        _isSignUpMode ? l10n.alreadyHaveAccount : l10n.noAccount,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.primaryGreen,
          fontWeight: FontWeight.w500,
        ),
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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/userprofile.dart';
import 'console_logger.dart';
import 'error_logger_service.dart';
import 'settings_service.dart';

/// Service d'authentification Supabase pour NgonNest
/// Gère l'authentification utilisateur et les sessions
class AuthService extends ChangeNotifier {
  static AuthService? _instance;
  late SupabaseClient _supabase;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // État d'authentification
  bool _isAuthenticated = false;
  User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  static AuthService get instance {
    _instance ??= AuthService._internal();
    return _instance!;
  }

  AuthService._internal() {
    _initializeSupabase();
    _setupAuthListener();
  }

  /// Exchange email confirmation code for a session
  Future<bool> exchangeCodeForSession(String code) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Exchange the code for a session using Supabase
      // For email confirmation after signup, use OtpType.signup
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.signup,
        token: code,
      );

      if (response.session != null) {
        _isAuthenticated = true;
        _currentUser = response.user;
        await _storeSession(response.session!);
        ConsoleLogger.info(
          '[AuthService] Email confirmed and session created: ${response.user?.email}',
        );

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e, stackTrace) {
      ConsoleLogger.error(
        'AuthService',
        'exchangeCodeForSession',
        e,
        stackTrace: stackTrace,
      );

      await ErrorLoggerService.logError(
        component: 'AuthService',
        operation: 'exchangeCodeForSession',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'code_provided': code.isNotEmpty},
      );

      _errorMessage = _getReadableErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Renvoyer l'email de confirmation d'inscription
  Future<bool> resendConfirmationEmail(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Supabase v2 – renvoi d'OTP pour confirmation de signup
      await _supabase.auth.resend(type: OtpType.signup, email: email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      ConsoleLogger.error(
        'AuthService',
        'resendConfirmationEmail',
        e,
        stackTrace: stackTrace,
      );

      await ErrorLoggerService.logError(
        component: 'AuthService',
        operation: 'resendConfirmationEmail',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
        metadata: {'email': email},
      );

      _errorMessage = _getReadableErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _initializeSupabase() {
    try {
      _supabase = Supabase.instance.client;
      ConsoleLogger.info(
        '[AuthService] Supabase client initialized successfully',
      );

      // Verify configuration is valid and restore session if available
      final config = _supabase.auth.currentSession;
      if (config == null) {
        ConsoleLogger.info('[AuthService] No active session found');
        // Essayer de restaurer depuis secure storage
        _restoreSessionFromStorage();
      } else {
        _isAuthenticated = true;
        _currentUser = config.user;
        ConsoleLogger.info(
          '[AuthService] Existing session found for: ${config.user.email}',
        );
      }
    } catch (e, stackTrace) {
      ConsoleLogger.error(
        'AuthService',
        '_initializeSupabase',
        e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  void _setupAuthListener() {
    // Écouter les changements d'état d'authentification
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _isAuthenticated = true;
        _currentUser = session.user;
        _storeSession(session);
        ConsoleLogger.info(
          '[AuthService] User signed in: ${session.user.email}',
        );
      } else if (event == AuthChangeEvent.signedOut) {
        _isAuthenticated = false;
        _currentUser = null;
        _clearSecureStorage();
        ConsoleLogger.info('[AuthService] User signed out');
      } else if (event == AuthChangeEvent.tokenRefreshed && session != null) {
        _currentUser = session.user;
        _storeSession(session);
        ConsoleLogger.info(
          '[AuthService] Token refreshed for user: ${session.user.email}',
        );
      } else if (event == AuthChangeEvent.passwordRecovery) {
        ConsoleLogger.info('[AuthService] Password recovery initiated');
      }

      _isLoading = false;

      ConsoleLogger.info(
        '[AuthService] Auth state changed: $event, User: ${_currentUser?.email}',
      );

      notifyListeners();
    });
  }

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Wrapper pour exécuter les actions d'authentification avec gestion d'erreurs
  Future<bool> _executeAuthAction(
    Future<void> Function() action, {
    required String operation,
    Map<String, dynamic>? errorMetadata,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await action();

      return true;
    } catch (e, stackTrace) {
      ConsoleLogger.error('AuthService', operation, e, stackTrace: stackTrace);

      await ErrorLoggerService.logError(
        component: 'AuthService',
        operation: operation,
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: errorMetadata,
      );

      _errorMessage = _getReadableErrorMessage(e);
      notifyListeners();

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inscription avec email et mot de passe
  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await signUpWithEmail(
        email: email,
        password: password,
        fullName: '$firstName $lastName',
      );
      return response.session != null;
    } catch (e) {
      return false;
    }
  }

  /// Sign up with email and password (new method for requirements)
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final nameParts = fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.supabase.ngonnest:/login-callback/',
        data: {
          'full_name': fullName,
          'first_name': firstName,
          'last_name': lastName,
          'created_at': DateTime.now().toIso8601String(),
          'source': 'mobile_app',
        },
      );

      if (response.session != null) {
        _isAuthenticated = true;
        _currentUser = response.user;
        await _storeSession(response.session!);

        try {
          // Créer le profil utilisateur dans la table profiles
          await _createUserProfile(response.user!, firstName, lastName);
          ConsoleLogger.info(
            '[AuthService] User signed up successfully: ${response.user!.email}',
          );
        } catch (e, stackTrace) {
          // Si la création du profil échoue, c'est une erreur critique
          ConsoleLogger.error(
            'AuthService',
            'signUpWithEmail - profile creation',
            e,
            stackTrace: stackTrace,
          );

          await ErrorLoggerService.logError(
            component: 'AuthService',
            operation: 'signUpWithEmail - profile creation',
            error: e,
            stackTrace: stackTrace,
            severity: ErrorSeverity.high,
            metadata: {'email': email, 'full_name': fullName},
          );

          rethrow; // Laisser l'erreur remonter
        }
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e, stackTrace) {
      ConsoleLogger.error(
        'AuthService',
        'signUpWithEmail',
        e,
        stackTrace: stackTrace,
      );

      await ErrorLoggerService.logError(
        component: 'AuthService',
        operation: 'signUpWithEmail',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'email': email, 'full_name': fullName},
      );

      _errorMessage = _getReadableErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Connexion avec email et mot de passe
  Future<bool> signIn({required String email, required String password}) async {
    try {
      final response = await signInWithEmail(email: email, password: password);
      return response.session != null;
    } catch (e) {
      return false;
    }
  }

  /// Sign in with email and password (new method for requirements)
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        _isAuthenticated = true;
        _currentUser = response.user;
        await _storeSession(response.session!);
        ConsoleLogger.info(
          '[AuthService] User signed in successfully: ${response.user?.email}',
        );
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e, stackTrace) {
      ConsoleLogger.error(
        'AuthService',
        'signInWithEmail',
        e,
        stackTrace: stackTrace,
      );

      await ErrorLoggerService.logError(
        component: 'AuthService',
        operation: 'signInWithEmail',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'email': email},
      );

      _errorMessage = _getReadableErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Déconnexion
  Future<bool> signOut() async {
    return _executeAuthAction(
      () async {
        await _supabase.auth.signOut();
        await _clearSecureStorage();
        _isAuthenticated = false;
        _currentUser = null;
        ConsoleLogger.info('[AuthService] User signed out successfully');
      },
      operation: 'signOut',
      errorMetadata: {'user_id': _currentUser?.id},
    );
  }

  /// Reset du mot de passe
  Future<bool> resetPassword(String email) async {
    return _executeAuthAction(
      () async {
        await _supabase.auth.resetPasswordForEmail(email);
        ConsoleLogger.info(
          '[AuthService] Password reset email sent to: $email',
        );
      },
      operation: 'resetPassword',
      errorMetadata: {'email': email},
    );
  }

  /// Mise à jour du mot de passe (nécessite d'être connecté)
  Future<bool> updatePassword(String newPassword) async {
    return _executeAuthAction(
      () async {
        await _supabase.auth.updateUser(UserAttributes(password: newPassword));
        ConsoleLogger.info('[AuthService] Password updated successfully');
      },
      operation: 'updatePassword',
      errorMetadata: {'user_id': _currentUser?.id},
    );
  }

  /// Mise à jour du profil utilisateur
  Future<bool> updateProfile({String? firstName, String? lastName}) async {
    if (_currentUser == null) return false;

    return _executeAuthAction(
      () async {
        final updates = <String, dynamic>{};
        if (firstName != null) updates['first_name'] = firstName;
        if (lastName != null) updates['last_name'] = lastName;
        updates['updated_at'] = DateTime.now().toIso8601String();

        await _supabase
            .from(SupabaseConfig.profilesTable)
            .update(updates)
            .eq('id', _currentUser!.id);

        ConsoleLogger.info('[AuthService] Profile updated successfully');
      },
      operation: 'updateProfile',
      errorMetadata: {
        'user_id': _currentUser!.id,
        'first_name': firstName,
        'last_name': lastName,
      },
    );
  }

  /// Créer le profil utilisateur dans Supabase
  Future<void> _createUserProfile(
    User user,
    String firstName,
    String lastName,
  ) async {
    await _supabase.from(SupabaseConfig.profilesTable).insert({
      'id': user.id,
      'email': user.email,
      'first_name': firstName,
      'last_name': lastName,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'source': 'mobile_app',
    });

    ConsoleLogger.info('[AuthService] User profile created in Supabase');
  }

  /// Ensure user profile exists in Supabase
  Future<UserProfile?> _ensureUserProfileExists(User user) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        return UserProfile.fromJson(response);
      }

      // Create minimal profile
      final fullName = user.userMetadata?['full_name'] ?? user.email ?? '';
      final nameParts = fullName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      await _createUserProfile(user, firstName, lastName);
      return await getUserProfile();
    } catch (e, stackTrace) {
      ConsoleLogger.error(
        'AuthService',
        '_ensureUserProfileExists',
        e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Obtenir le profil utilisateur
  Future<UserProfile?> getUserProfile() async {
    if (_currentUser == null) return null;

    try {
      final response = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select()
          .eq('id', _currentUser!.id)
          .maybeSingle();

      return UserProfile.fromJson(response!);
    } catch (e, stackTrace) {
      ConsoleLogger.error(
        'AuthService',
        'getUserProfile',
        e,
        stackTrace: stackTrace,
      );

      await ErrorLoggerService.logError(
        component: 'AuthService',
        operation: 'getUserProfile',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.low,
        metadata: {'user_id': _currentUser!.id},
      );

      return null;
    }
  }

  /// Initialiser la session au démarrage de l'app
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check for existing session
      final session = _supabase.auth.currentSession;
      if (session != null) {
        _isAuthenticated = true;
        _currentUser = session.user;
        await _fetchAndStoreHouseholdId(session.user);
        ConsoleLogger.info(
          '[AuthService] Session restored for user: ${_currentUser!.email}',
        );
      } else {
        _isAuthenticated = false;
        _currentUser = null;
        ConsoleLogger.info('[AuthService] No active session found');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      ConsoleLogger.error(
        'AuthService',
        'initialize',
        e,
        stackTrace: stackTrace,
      );

      await ErrorLoggerService.logError(
        component: 'AuthService',
        operation: 'initialize',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
      );

      _isAuthenticated = false;
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Store session securely
  Future<void> _storeSession(Session session) async {
    try {
      await _secureStorage.write(
        key: 'access_token',
        value: session.accessToken,
      );
      await _secureStorage.write(
        key: 'refresh_token',
        value: session.refreshToken,
      );
      await _secureStorage.write(key: 'user_id', value: session.user.id);
      // Fetch and store household ID from user profile
      await _fetchAndStoreHouseholdId(session.user);
      ConsoleLogger.info('[AuthService] Session stored securely');
    } catch (e, stackTrace) {
      ConsoleLogger.error(
        'AuthService',
        '_storeSession',
        e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fetch user profile and store household ID locally
  Future<void> _fetchAndStoreHouseholdId(User user) async {
    try {
      // Ensure user profile exists first
      final userProfile = await _ensureUserProfileExists(user);
      if (userProfile != null) {
        // Query households table directly using profiles.id -> households.user_id relationship
        final householdResponse = await _supabase
            .from('households')
            .select('id')
            .eq('user_id', userProfile.id)
            .maybeSingle();

        if (householdResponse != null) {
          final householdId = householdResponse['id'] as String;
          await SettingsService.initialize();
          await SettingsService.setHouseholdId(householdId);
          ConsoleLogger.info(
            '[AuthService] Household ID found and stored locally: $householdId',
          );
        } else {
          // If no household exists, create a new household for the user
          final newHouseholdId = await _createHouseholdForUser(userProfile);
          if (newHouseholdId != null) {
            await SettingsService.initialize();
            await SettingsService.setHouseholdId(newHouseholdId);
            ConsoleLogger.info(
              '[AuthService] New household created and stored: $newHouseholdId',
            );
          } else {
            ConsoleLogger.warning(
              '[AuthService] Failed to create household for user: ${user.id}',
            );
          }
        }
      }
    } catch (e, stackTrace) {
      ConsoleLogger.error(
        'AuthService',
        '_fetchAndStoreHouseholdId',
        e,
        stackTrace: stackTrace,
      );

      await ErrorLoggerService.logError(
        component: 'AuthService',
        operation: '_fetchAndStoreHouseholdId',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'user_id': user.id},
      );
    }
  }

  /// Create a new household for the user and update their profile
  Future<String?> _createHouseholdForUser(UserProfile userProfile) async {
    try {
      // Create a new household in the database
      final householdResponse = await _supabase
          .from('households')
          .insert({
            'user_id': userProfile.id,
            'nb_personnes': userProfile.nbPersonnes ?? 4,
            'nb_pieces': userProfile.nbPieces ?? 3,
            'type_logement': userProfile.typeLogement ?? 'appartement',
            'langue': userProfile.langue ?? 'fr',
            'budget_mensuel_estime': userProfile.budgetMensuelEstime ?? 0.0,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final newHouseholdId = householdResponse['id'] as String;

      // Update the user's profile with the new household ID
      await _supabase
          .from(SupabaseConfig.profilesTable)
          .update({'household_id': newHouseholdId})
          .eq('id', userProfile.id);

      ConsoleLogger.info(
        '[AuthService] Household created for user: $newHouseholdId',
      );
      return newHouseholdId;
    } catch (e, stackTrace) {
      ConsoleLogger.error(
        'AuthService',
        '_createHouseholdForUser',
        e,
        stackTrace: stackTrace,
      );

      await ErrorLoggerService.logError(
        component: 'AuthService',
        operation: '_createHouseholdForUser',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
        metadata: {'user_id': userProfile.id},
      );
      return null;
    }
  }

  /// Public method to ensure household exists for current user
  Future<String?> ensureHouseholdExists() async {
    if (_currentUser == null) {
      throw Exception('User must be authenticated to ensure household exists');
    }

    await _fetchAndStoreHouseholdId(_currentUser!);
    await SettingsService.initialize();
    return await SettingsService.getHouseholdId();
  }

  /// Restaure la session depuis secure storage si possible
  Future<void> _restoreSessionFromStorage() async {
    try {
      final accessToken = await _secureStorage.read(key: 'access_token');
      final refreshToken = await _secureStorage.read(key: 'refresh_token');

      if (accessToken != null && refreshToken != null) {
        // Essayer de rafraîchir la session
        final refreshed = await refreshSession();
        if (refreshed) {
          ConsoleLogger.info('[AuthService] Session restored from storage');
        }
      }
    } catch (e) {
      ConsoleLogger.warning(
        '[AuthService] Could not restore session from storage: $e',
      );
    }
  }

  /// Clear secure storage
  Future<void> _clearSecureStorage() async {
    try {
      await _secureStorage.deleteAll();
      ConsoleLogger.info('[AuthService] Secure storage cleared');
    } catch (e, stackTrace) {
      ConsoleLogger.error(
        'AuthService',
        '_clearSecureStorage',
        e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Refresh the current session token
  Future<bool> refreshSession() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.auth.refreshSession();

      if (response.session != null) {
        _isAuthenticated = true;
        _currentUser = response.session!.user;
        await _storeSession(response.session!);
        ConsoleLogger.info('[AuthService] Session refreshed successfully');

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Session refresh failed, sign out user
        await signOut();
        return false;
      }
    } catch (e, stackTrace) {
      ConsoleLogger.error(
        'AuthService',
        'refreshSession',
        e,
        stackTrace: stackTrace,
      );

      await ErrorLoggerService.logError(
        component: 'AuthService',
        operation: 'refreshSession',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.high,
        metadata: {'user_id': _currentUser?.id},
      );

      // Session refresh failed, sign out user
      await signOut();
      return false;
    }
  }

  /// Check if the current session is expired
  bool isSessionExpired() {
    final session = _supabase.auth.currentSession;
    if (session == null) return true;

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      session.expiresAt! * 1000,
    );
    final now = DateTime.now();

    // Consider session expired if it expires within the next 5 minutes
    return expiresAt.isBefore(now.add(const Duration(minutes: 5)));
  }

  /// Get session expiry time
  DateTime? getSessionExpiryTime() {
    final session = _supabase.auth.currentSession;
    if (session?.expiresAt == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(session!.expiresAt! * 1000);
  }

  /// Obtenir les statistiques d'utilisation (pour monitoring)
  Map<String, dynamic> getStats() {
    final lastSignInAt = _currentUser?.lastSignInAt;
    return {
      'is_authenticated': isAuthenticated,
      'user_email': _currentUser?.email,
      'user_id': _currentUser?.id,
      'last_sign_in': lastSignInAt != null && lastSignInAt is DateTime
          ? lastSignInAt.toString()
          : lastSignInAt?.toString(),
      'is_loading': _isLoading,
    };
  }

  /// Nettoyer les erreurs affichées
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Sign in with OAuth provider
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final result = await _supabase.auth.signInWithOAuth(
        provider,
        redirectTo: 'io.supabase.ngonnest:/login-callback/',
      );

      ConsoleLogger.info(
        '[AuthService] OAuth sign in initiated for provider: $provider',
      );

      // Note: OAuth completion will be handled by the auth state listener
      return result;
    } catch (e, stackTrace) {
      ConsoleLogger.error(
        'AuthService',
        'signInWithOAuth',
        e,
        stackTrace: stackTrace,
      );

      await ErrorLoggerService.logError(
        component: 'AuthService',
        operation: 'signInWithOAuth',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'provider': provider.toString()},
      );

      _errorMessage = _getReadableErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google OAuth
  Future<bool> signInWithGoogle() async {
    return signInWithOAuth(OAuthProvider.google);
  }

  /// Sign in with Apple OAuth
  Future<bool> signInWithApple() async {
    return signInWithOAuth(OAuthProvider.apple);
  }

  /// Convertir erreurs Supabase en messages français lisibles
  String _getReadableErrorMessage(dynamic error) {
    // Gestion spécifique des AuthApiException (rate limiting, etc.)
    if (error is AuthException) {
      // Vérifier si c'est un rate limit (429) avec code spécifique
      final errorString = error.toString();
      if (errorString.contains('over_email_send_rate_limit') ||
          errorString.contains('429')) {
        // Extraire le temps d'attente du message si disponible
        final secondsMatch = RegExp(
          r'after (\d+) seconds?',
        ).firstMatch(errorString);
        if (secondsMatch != null) {
          final seconds = int.tryParse(secondsMatch.group(1) ?? '');
          if (seconds != null) {
            final minutes = seconds ~/ 60;
            final remainingSeconds = seconds % 60;
            if (minutes > 0) {
              return 'Trop de tentatives. Veuillez réessayer dans $minutes minute${minutes > 1 ? 's' : ''}${remainingSeconds > 0 ? ' et $remainingSeconds seconde${remainingSeconds > 1 ? 's' : ''}' : ''}.';
            } else {
              return 'Trop de tentatives. Veuillez réessayer dans $seconds seconde${seconds > 1 ? 's' : ''}.';
            }
          }
        }
        return 'Trop de tentatives. Veuillez réessayer dans quelques minutes.';
      }

      // Autres cas d'AuthException
      switch (error.message) {
        case 'User already registered':
          return 'Cet email est déjà utilisé';
        case 'Invalid login credentials':
          return 'Email ou mot de passe incorrect';
        case 'Email not confirmed':
          return 'Veuillez confirmer votre email avant de vous connecter';
        case 'Password should be at least 6 characters':
          return 'Le mot de passe doit contenir au moins 8 caractères';
        case 'Password should be at least 8 characters.':
          return 'Le mot de passe doit contenir au moins 8 caractères';
        case 'Invalid email':
          return 'Adresse email invalide';
        case 'Too many requests':
          return 'Trop de tentatives, veuillez réessayer plus tard';
        case 'OAuth provider error':
          return 'Erreur de connexion avec le fournisseur. Vérifiez vos autorisations.';
        default:
          // Vérifier si c'est un problème réseau dans le message
          if (error.message.toLowerCase().contains('network') ||
              error.message.toLowerCase().contains('connection') ||
              error.message.toLowerCase().contains('timeout')) {
            return 'Problème de connexion. Vérifiez votre réseau internet.';
          }
          return 'Erreur d\'authentification: ${error.message}';
      }
    }

    // Gestion des erreurs réseau (AuthRetryableFetchException, SocketException, etc.)
    final errorString = error.toString().toLowerCase();

    // Erreurs de résolution DNS / connexion
    if (errorString.contains('failed host lookup') ||
        errorString.contains('no address associated') ||
        errorString.contains('socketexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection timed out') ||
        errorString.contains('network is unreachable')) {
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
    }

    // Erreurs réseau génériques
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('internet')) {
      return 'Erreur de connexion internet. Vérifiez votre réseau.';
    }

    // Timeout
    if (errorString.contains('timeout') ||
        errorString.contains('deadline exceeded')) {
      return 'Délai d\'attente dépassé. Vérifiez votre connexion.';
    }

    // Erreur serveur (5xx)
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return 'Le serveur est temporairement indisponible. Réessayez plus tard.';
    }

    return 'Une erreur inattendue s\'est produite';
  }
}

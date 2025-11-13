import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Types d'erreurs pour la classification des retry
enum RetryErrorType {
  network,
  rateLimit,
  server,
  timeout,
  unknown,
}

/// Configuration pour les stratégies de retry
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final List<RetryErrorType> retryableErrors;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.retryableErrors = const [
      RetryErrorType.network,
      RetryErrorType.rateLimit,
      RetryErrorType.timeout,
    ],
  });

  /// Configuration optimisée pour l'authentification Supabase
  static const RetryConfig authConfig = RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 2),
    maxDelay: Duration(seconds: 60),
    backoffMultiplier: 2.5,
    retryableErrors: [
      RetryErrorType.network,
      RetryErrorType.rateLimit,
      RetryErrorType.timeout,
    ],
  );

  /// Configuration pour les opérations réseau générales
  static const RetryConfig networkConfig = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 10),
    backoffMultiplier: 2.0,
    retryableErrors: [
      RetryErrorType.network,
      RetryErrorType.timeout,
    ],
  );
}

/// Service de retry avec backoff exponentiel
/// Inspiré des meilleures pratiques AWS, Google, et Stripe
class RetryService {
  static final RetryService _instance = RetryService._internal();
  factory RetryService() => _instance;
  RetryService._internal();

  final Random _random = Random();

  /// Exécute une opération avec retry automatique
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation,
    RetryConfig config, {
    String operationName = 'operation',
    void Function(int attempt, dynamic error)? onRetry,
    void Function(dynamic error)? onFailure,
  }) async {
    dynamic lastError;
    Duration currentDelay = config.initialDelay;

    for (int attempt = 1; attempt <= config.maxAttempts; attempt++) {
      try {
        debugPrint('[RetryService] Tentative $attempt/$config.maxAttempts pour $operationName');
        final result = await operation();
        return result;
      } catch (error, stackTrace) {
        lastError = error;
        final errorType = _classifyError(error);

        debugPrint('[RetryService] Erreur tentative $attempt: $errorType - $error');

        // Vérifier si l'erreur est retryable
        if (!config.retryableErrors.contains(errorType) || attempt >= config.maxAttempts) {
          debugPrint('[RetryService] Erreur non retryable ou max tentatives atteintes');
          onFailure?.call(error);
          throw error; // Relancer l'erreur originale
        }

        // Calculer le délai avec jitter
        final delayWithJitter = _calculateDelayWithJitter(currentDelay, config.maxDelay);

        debugPrint('[RetryService] Retry dans ${delayWithJitter.inMilliseconds}ms');

        onRetry?.call(attempt, error);

        // Attendre avant la prochaine tentative
        await Future.delayed(delayWithJitter);

        // Augmenter le délai pour la prochaine tentative
        currentDelay = Duration(
          milliseconds: min(
            (currentDelay.inMilliseconds * config.backoffMultiplier).round(),
            config.maxDelay.inMilliseconds,
          ),
        );
      }
    }

    // Cette ligne ne devrait jamais être atteinte, mais au cas où
    onFailure?.call(lastError);
    throw lastError ?? Exception('Retry failed after $config.maxAttempts attempts');
  }

  /// Classifie une erreur pour déterminer si elle est retryable
  RetryErrorType _classifyError(dynamic error) {
    if (error == null) return RetryErrorType.unknown;

    final errorString = error.toString().toLowerCase();

    // Erreurs réseau
    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('dns') ||
        errorString.contains('host lookup') ||
        errorString.contains('no address associated') ||
        errorString.contains('failed host lookup')) {
      return RetryErrorType.network;
    }

    // Rate limiting (Supabase)
    if (errorString.contains('rate limit') ||
        errorString.contains('too many requests') ||
        errorString.contains('429') ||
        errorString.contains('over_email_send_rate_limit')) {
      return RetryErrorType.rateLimit;
    }

    // Timeout
    if (errorString.contains('timeout') ||
        errorString.contains('deadline exceeded')) {
      return RetryErrorType.timeout;
    }

    // Erreurs serveur (5xx)
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504') ||
        errorString.contains('server error')) {
      return RetryErrorType.server;
    }

    return RetryErrorType.unknown;
  }

  /// Calcule le délai avec jitter pour éviter les thundering herd
  Duration _calculateDelayWithJitter(Duration baseDelay, Duration maxDelay) {
    // Ajouter un jitter de ±25%
    final jitterRange = (baseDelay.inMilliseconds * 0.25).round();
    final jitter = _random.nextInt(jitterRange * 2) - jitterRange;
    final delayWithJitter = baseDelay.inMilliseconds + jitter;

    return Duration(
      milliseconds: min(delayWithJitter, maxDelay.inMilliseconds),
    );
  }

  /// Vérifie si une erreur spécifique est retryable selon la config
  bool isRetryableError(dynamic error, RetryConfig config) {
    final errorType = _classifyError(error);
    return config.retryableErrors.contains(errorType);
  }

  /// Obtient un message d'attente convivial pour l'utilisateur
  String getRetryMessage(int attempt, int maxAttempts, RetryErrorType errorType) {
    final remaining = maxAttempts - attempt;

    switch (errorType) {
      case RetryErrorType.rateLimit:
        return remaining > 0
            ? 'Limite de taux atteinte. Nouvelle tentative dans quelques secondes...'
            : 'Limite de taux atteinte. Veuillez réessayer plus tard.';

      case RetryErrorType.network:
        return remaining > 0
            ? 'Problème de connexion. Nouvelle tentative...'
            : 'Problème de connexion réseau. Vérifiez votre connexion.';

      case RetryErrorType.timeout:
        return remaining > 0
            ? 'Délai dépassé. Nouvelle tentative...'
            : 'Délai dépassé. Vérifiez votre connexion.';

      case RetryErrorType.server:
        return remaining > 0
            ? 'Problème serveur temporaire. Nouvelle tentative...'
            : 'Service temporairement indisponible.';

      default:
        return remaining > 0
            ? 'Nouvelle tentative en cours...'
            : 'Échec de l\'opération.';
    }
  }
}

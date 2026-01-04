import 'package:flutter/foundation.dart';

import '../config/cameroon_prices.dart';
import '../models/alert.dart';
import '../models/foyer.dart';
import '../models/objet.dart';
import '../repository/alert_state_repository.dart';
import '../repository/foyer_repository.dart';
import '../repository/inventory_repository.dart';
import '../services/database_service.dart';
import 'error_logger_service.dart';
import 'prediction_service.dart';

/// Service for generating and managing alerts based on inventory and budget data
/// Provides comprehensive alert system for stock, budget, recommendations, expiration, and maintenance
class AlertGenerationService {
  static final AlertGenerationService _instance =
      AlertGenerationService._internal();
  factory AlertGenerationService() => _instance;
  AlertGenerationService._internal();

  late final DatabaseService _databaseService;
  late final InventoryRepository _inventoryRepository;
  late final FoyerRepository _foyerRepository;
  late final AlertStateRepository _alertStateRepository;

  /// Initialize the service with database service
  Future<void> initialize(DatabaseService databaseService) async {
    _databaseService = databaseService;
    _inventoryRepository = InventoryRepository(_databaseService);
    _foyerRepository = FoyerRepository(_databaseService);
    _alertStateRepository = AlertStateRepository(_databaseService);
  }

  /// Génère toutes les alertes pour un foyer
  Future<List<Alert>> generateAllAlerts(int foyerId) async {
    try {
      final alerts = <Alert>[];

      // Récupérer les données du foyer et inventaire
      final foyer = await _foyerRepository.get();
      final inventory = await _inventoryRepository.getAll(foyerId);

      if (foyer == null || inventory.isEmpty) {
        return alerts;
      }

      // Récupérer les états persistants des alertes
      final alertStates = await _alertStateRepository.getAllAlertStates();

      // 1. Alertes de rupture de stock
      alerts.addAll(await _generateStockAlerts(inventory));

      // 2. Alertes budgétaires
      alerts.addAll(await _generateBudgetAlerts(foyer, inventory));

      // 3. Alertes de recommandations
      alerts.addAll(await _generateRecommendationAlerts(foyer, inventory));

      // 4. Alertes d'expiration
      alerts.addAll(await _generateExpirationAlerts(inventory));

      // 5. Alertes de maintenance (durables)
      alerts.addAll(await _generateMaintenanceAlerts(inventory));

      // Appliquer les états persistants (lu/résolu)
      for (var i = 0; i < alerts.length; i++) {
        final alert = alerts[i];
        if (alertStates.containsKey(alert.id)) {
          final state = alertStates[alert.id]!;
          alerts[i] = alert.copyWith(
            isRead: state.isRead,
            isResolved: state.isResolved,
          );
        }
      }

      // Trier par priorité et urgence
      alerts.sort((a, b) {
        final priorityComparison = a.priority.index.compareTo(b.priority.index);
        if (priorityComparison != 0) return priorityComparison;
        return a.urgencyScore.compareTo(b.urgencyScore);
      });

      return alerts;
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'AlertGenerationService',
        operation: 'generateAllAlerts',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'foyerId': foyerId},
      );
      return [];
    }
  }

  /// Mark an alert as read
  Future<void> markAlertAsRead(int alertId) async {
    try {
      await _alertStateRepository.markAlertAsRead(alertId);
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'AlertGenerationService',
        operation: 'markAlertAsRead',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'alertId': alertId},
      );
      rethrow;
    }
  }

  /// Mark an alert as resolved
  Future<void> markAlertAsResolved(int alertId) async {
    try {
      await _alertStateRepository.markAlertAsResolved(alertId);
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'AlertGenerationService',
        operation: 'markAlertAsResolved',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'alertId': alertId},
      );
      rethrow;
    }
  }

  /// Génère les alertes de rupture de stock
  Future<List<Alert>> _generateStockAlerts(List<Objet> inventory) async {
    final alerts = <Alert>[];

    for (final item in inventory) {
      if (item.type != TypeObjet.consommable) continue;

      final daysUntilRupture = PredictionService.getDaysUntilRupture(item);

      if (daysUntilRupture != null) {
        if (daysUntilRupture <= 0) {
          // Rupture immédiate
          alerts.add(
            Alert(
              id: 1000 + (item.id ?? 0),
              type: AlertType.stockCritical,
              priority: AlertPriority.critical,
              title: '🚨 Stock épuisé',
              message: '${item.nom} est en rupture de stock',
              productId: item.id?.toString(),
              productName: item.nom,
              urgencyScore: 100,
              actionRequired: true,
              suggestedActions: [
                'Acheter immédiatement',
                'Vérifier les alternatives',
              ],
              createdAt: DateTime.now(),
            ),
          );
        } else if (daysUntilRupture <= item.seuilAlerteJours) {
          // Rupture proche
          alerts.add(
            Alert(
              id: 2000 + (item.id ?? 0),
              type: AlertType.stockLow,
              priority: AlertPriority.high,
              title: '⚠️ Stock faible',
              message: '${item.nom} sera épuisé dans $daysUntilRupture jour(s)',
              productId: item.id?.toString(),
              productName: item.nom,
              urgencyScore: 80 - (daysUntilRupture.toInt() * 10),
              actionRequired: true,
              suggestedActions: [
                'Ajouter à la liste de courses',
                'Planifier un achat',
              ],
              createdAt: DateTime.now(),
              metadata: {'daysUntilRupture': daysUntilRupture},
            ),
          );
        }
      }

      // Alerte basée sur la quantité restante
      // Prevent division by zero error
      if (item.quantiteInitiale > 0) {
        final percentageRemaining =
            (item.quantiteRestante / item.quantiteInitiale) * 100;
        if (percentageRemaining <= 20 && percentageRemaining > 0) {
          alerts.add(
            Alert(
              id: 3000 + (item.id ?? 0),
              type: AlertType.stockLow,
              priority: AlertPriority.medium,
              title: '📦 Quantité faible',
              message: '${item.nom}: ${percentageRemaining.toInt()}% restant',
              productId: item.id?.toString(),
              productName: item.nom,
              urgencyScore: 60 - percentageRemaining.toInt(),
              actionRequired: false,
              suggestedActions: [
                'Surveiller la consommation',
                'Prévoir un réapprovisionnement',
              ],
              createdAt: DateTime.now(),
              metadata: {'percentageRemaining': percentageRemaining},
            ),
          );
        }
      }
    }

    return alerts;
  }

  /// Génère les alertes budgétaires
  Future<List<Alert>> _generateBudgetAlerts(
    Foyer foyer,
    List<Objet> inventory,
  ) async {
    final alerts = <Alert>[];

    try {
      // Calculer le budget mensuel estimé
      final monthlyItems = <BudgetItem>[];
      double totalMonthlyBudget = 0.0;

      for (final item in inventory) {
        if (item.type != TypeObjet.consommable ||
            item.frequenceAchatJours == null) {
          continue;
        }

        final monthlyQuantity =
            (30.0 / item.frequenceAchatJours!) * item.quantiteInitiale;
        monthlyItems.add(
          BudgetItem(
            productName: item.nom,
            quantity: monthlyQuantity,
            category: item.categorie,
          ),
        );
      }

      if (monthlyItems.isNotEmpty) {
        final budgetEstimate = CameroonPrices.calculateBudget(monthlyItems);
        totalMonthlyBudget = budgetEstimate.totalAverage;

        // Estimation du budget par personne
        final budgetPerPerson = totalMonthlyBudget / foyer.nbPersonnes;

        // Alertes selon le budget
        if (budgetPerPerson > 50000) {
          // > 50k FCFA par personne/mois
          alerts.add(
            Alert(
              id: 8000 + (int.tryParse(foyer.id ?? '0') ?? 0),
              type: AlertType.budgetHigh,
              priority: AlertPriority.medium,
              title: '💰 Budget élevé',
              message:
                  'Budget estimé: ${totalMonthlyBudget.toInt()} FCFA/mois (${budgetPerPerson.toInt()} FCFA/personne)',
              urgencyScore: 40,
              actionRequired: false,
              suggestedActions: [
                'Rechercher des alternatives moins chères',
                'Optimiser les quantités',
                'Comparer les prix',
              ],
              createdAt: DateTime.now(),
              metadata: {
                'totalBudget': totalMonthlyBudget,
                'budgetPerPerson': budgetPerPerson,
                'reliability': budgetEstimate.reliabilityLevel,
              },
            ),
          );
        }

        // Alerte si couverture prix faible
        if (budgetEstimate.coveragePercentage < 60) {
          alerts.add(
            Alert(
              id: 9000 + (int.tryParse(foyer.id ?? '0') ?? 0),
              type: AlertType.budgetUncertain,
              priority: AlertPriority.low,
              title: '📊 Estimation incertaine',
              message:
                  'Prix disponibles pour ${budgetEstimate.coveragePercentage.toInt()}% des produits',
              urgencyScore: 20,
              actionRequired: false,
              suggestedActions: [
                'Ajouter les prix manquants',
                'Vérifier les estimations',
              ],
              createdAt: DateTime.now(),
              metadata: {
                'coverage': budgetEstimate.coveragePercentage,
                'missingItems': budgetEstimate.missingItems,
              },
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur calcul budget: $e');
      }
    }

    return alerts;
  }

  /// Génère les alertes de recommandations
  Future<List<Alert>> _generateRecommendationAlerts(
    Foyer foyer,
    List<Objet> inventory,
  ) async {
    final alerts = <Alert>[];

    // Produits essentiels manquants
    final essentialProducts = [
      'riz',
      'huile_palme',
      'savon_marseille',
      'papier_toilette',
    ];
    final existingProducts = inventory.map((i) => i.nom.toLowerCase()).toSet();

    for (final essential in essentialProducts) {
      if (!existingProducts.any(
        (name) => name.contains(essential.replaceAll('_', ' ')),
      )) {
        final price = CameroonPrices.getPrice(essential);
        alerts.add(
          Alert(
            id: 4000 + essential.hashCode.abs(),
            type: AlertType.recommendation,
            priority: AlertPriority.medium,
            title: '💡 Produit essentiel manquant',
            message:
                '${price?.name ?? essential} n\'est pas dans votre inventaire',
            urgencyScore: 30,
            actionRequired: false,
            suggestedActions: [
              'Ajouter à l\'inventaire',
              'Ajouter à la liste de courses',
            ],
            createdAt: DateTime.now(),
            metadata: {
              'productName': price?.name ?? essential,
              'estimatedPrice': price?.averagePrice,
            },
          ),
        );
      }
    }

    // Recommandations selon la taille du foyer
    final familySize = foyer.nbPersonnes;
    if (familySize >= 5) {
      // Grandes familles - recommander achats en gros
      final smallQuantityItems = inventory
          .where(
            (i) => i.type == TypeObjet.consommable && i.quantiteInitiale < 5,
          )
          .toList();

      if (smallQuantityItems.length >= 3) {
        alerts.add(
          Alert(
            id: 5000 + (int.tryParse(foyer.id ?? '0') ?? 0),
            type: AlertType.recommendation,
            priority: AlertPriority.low,
            title: '🛒 Achat en gros recommandé',
            message:
                'Pour une famille de $familySize personnes, acheter en plus grandes quantités peut être économique',
            urgencyScore: 15,
            actionRequired: false,
            suggestedActions: [
              'Considérer les achats en gros',
              'Comparer les prix au kg/litre',
            ],
            createdAt: DateTime.now(),
            metadata: {'familySize': familySize},
          ),
        );
      }
    }

    return alerts;
  }

  /// Génère les alertes d'expiration
  Future<List<Alert>> _generateExpirationAlerts(List<Objet> inventory) async {
    final alerts = <Alert>[];
    final now = DateTime.now();

    for (final item in inventory) {
      if (item.dateRupturePrev == null) continue;

      final daysUntilExpiry = item.dateRupturePrev!.difference(now).inDays;

      if (daysUntilExpiry <= 0) {
        alerts.add(
          Alert(
            id: 6000 + (item.id ?? 0),
            type: AlertType.expired,
            priority: AlertPriority.high,
            title: '⚠️ Produit expiré',
            message: '${item.nom} a expiré',
            productId: item.id?.toString(),
            productName: item.nom,
            urgencyScore: 90,
            actionRequired: true,
            suggestedActions: [
              'Vérifier l\'état du produit',
              'Remplacer si nécessaire',
              'Retirer de l\'inventaire',
            ],
            createdAt: DateTime.now(),
          ),
        );
      } else if (daysUntilExpiry <= 7) {
        alerts.add(
          Alert(
            id: 7000 + (item.id ?? 0),
            type: AlertType.expiringSoon,
            priority: AlertPriority.medium,
            title: '⏰ Expiration proche',
            message: '${item.nom} expire dans $daysUntilExpiry jour(s)',
            productId: item.id?.toString(),
            productName: item.nom,
            urgencyScore: 70 - (daysUntilExpiry * 5).toInt(),
            actionRequired: false,
            suggestedActions: [
              'Utiliser en priorité',
              'Vérifier la date d\'expiration',
            ],
            createdAt: DateTime.now(),
            metadata: {'daysUntilExpiry': daysUntilExpiry},
          ),
        );
      }
    }

    return alerts;
  }

  /// Génère les alertes de maintenance pour les biens durables
  Future<List<Alert>> _generateMaintenanceAlerts(List<Objet> inventory) async {
    final alerts = <Alert>[];
    final now = DateTime.now();

    for (final item in inventory) {
      if (item.type != TypeObjet.durable || item.dateAchat == null) continue;

      final daysSincePurchase = now.difference(item.dateAchat!).inDays;

      // Maintenance selon la catégorie
      final maintenanceIntervals = {
        'electromenager': 365, // 1 an
        'electronique': 730, // 2 ans
        'mobilier': 1095, // 3 ans
        'vehicule': 180, // 6 mois
      };

      final interval = maintenanceIntervals[item.categorie] ?? 730;

      if (daysSincePurchase >= interval) {
        alerts.add(
          Alert(
            id: 10000 + (item.id ?? 0),
            type: AlertType.maintenanceDue,
            priority: AlertPriority.low,
            title: '🔧 Maintenance recommandée',
            message:
                '${item.nom} pourrait nécessiter une maintenance (${(daysSincePurchase / 365).toInt()} an(s))',
            productId: item.id?.toString(),
            productName: item.nom,
            urgencyScore: 25,
            actionRequired: false,
            suggestedActions: [
              'Vérifier l\'état général',
              'Planifier une maintenance',
              'Consulter le manuel',
            ],
            createdAt: DateTime.now(),
            metadata: {
              'daysSincePurchase': daysSincePurchase,
              'category': item.categorie,
            },
          ),
        );
      }
    }

    return alerts;
  }

  /// Filtre les alertes selon les préférences utilisateur
  List<Alert> filterAlerts(List<Alert> alerts, {
    AlertPriority? minPriority,
    List<AlertType>? types,
    bool actionRequiredOnly = false,
    bool includeRead = false,
    bool includeResolved = false,
  }) {
    return alerts.where((alert) {
      if (!includeRead && alert.isRead) return false;
      if (!includeResolved && alert.isResolved) return false;
      
      if (minPriority != null &&
          alert.priority.index > minPriority.index) {
        return false;
      }
      if (types != null && !types.contains(alert.type)) {
        return false;
      }
      if (actionRequiredOnly && !alert.actionRequired) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Marque une alerte comme résolue (alias pour compatibilité)
  /// Utilise AlertStateRepository pour la persistance
  Future<void> resolveAlert(int alertId) async {
    try {
      await _alertStateRepository.markAlertAsResolved(alertId);
      if (kDebugMode) {
        print('Alert resolved: $alertId');
      }
    } catch (e, stackTrace) {
      await ErrorLoggerService.logError(
        component: 'AlertGenerationService',
        operation: 'resolveAlert',
        error: e,
        stackTrace: stackTrace,
        severity: ErrorSeverity.medium,
        metadata: {'alertId': alertId},
      );
    }
  }
}



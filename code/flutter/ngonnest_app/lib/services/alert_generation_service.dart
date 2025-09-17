import 'package:flutter/foundation.dart';

import '../config/cameroon_prices.dart';
import '../models/foyer.dart';
import '../models/objet.dart';
import '../repository/foyer_repository.dart';
import '../repository/inventory_repository.dart';
import '../services/database_service.dart';
import 'error_logger_service.dart';
import 'prediction_service.dart';

/// Service for generating and managing alerts based on inventory and budget data
/// Provides comprehensive alert system for stock, budget, recommendations, expiration, and maintenance
///
/// ⚠️ CRITICAL TODOs FOR CLIENT DELIVERY:
/// TODO: ALERT_PERSISTENCE - Alert read/resolved states are NOT persisted (lines 520-548)
///       - markAlertAsRead() and markAlertAsResolved() are placeholder methods
///       - No database table exists for alert states
///       - Users cannot track which alerts they've seen
/// TODO: ALERT_INTEGRATION - Service is not properly integrated with UI
///       - Dashboard may not display alerts correctly
///       - No real-time alert updates
/// TODO: ALERT_TESTING - Alert generation logic needs validation
///       - Budget alert thresholds may not work as expected
///       - Expiration date calculations need verification
class AlertGenerationService {
  static final AlertGenerationService _instance =
      AlertGenerationService._internal();
  factory AlertGenerationService() => _instance;
  AlertGenerationService._internal();

  late final DatabaseService _databaseService;
  late final InventoryRepository _inventoryRepository;
  late final FoyerRepository _foyerRepository;

  /// Initialize the service with database service
  Future<void> initialize(DatabaseService databaseService) async {
    _databaseService = databaseService;
    _inventoryRepository = InventoryRepository(_databaseService);
    _foyerRepository = FoyerRepository(_databaseService);
  }

  /// Génère toutes les alertes pour un foyer
  Future<List<Alert>> generateAllAlerts(String foyerId) async {
    try {
      final alerts = <Alert>[];

      // Convert String foyerId to int for repository calls
      final foyerIdInt = int.tryParse(foyerId);
      if (foyerIdInt == null) {
        if (kDebugMode) {
          print('Invalid foyer ID: $foyerId');
        }
        return alerts;
      }

      // Récupérer les données du foyer et inventaire
      final foyer = await _foyerRepository.get();
      final inventory = await _inventoryRepository.getAll(foyerIdInt);

      if (foyer == null || inventory.isEmpty) {
        return alerts;
      }

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
              id: 'stock_critical_${item.id}',
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
              id: 'stock_low_${item.id}',
              type: AlertType.stockLow,
              priority: AlertPriority.high,
              title: '⚠️ Stock faible',
              message: '${item.nom} sera épuisé dans $daysUntilRupture jour(s)',
              productId: item.id?.toString(),
              productName: item.nom,
              urgencyScore: 80 - (daysUntilRupture * 10),
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
              id: 'quantity_low_${item.id}',
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
            item.frequenceAchatJours == null)
          continue;

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
              id: 'budget_high_${foyer.id ?? 'unknown'}',
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
              id: 'budget_uncertainty_${foyer.id ?? 'unknown'}',
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
            id: 'missing_essential_$essential',
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
            id: 'bulk_purchase_recommendation_${foyer.id ?? 'unknown'}',
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
            id: 'expired_${item.id}',
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
            id: 'expiring_soon_${item.id}',
            type: AlertType.expiringSoon,
            priority: AlertPriority.medium,
            title: '⏰ Expiration proche',
            message: '${item.nom} expire dans $daysUntilExpiry jour(s)',
            productId: item.id?.toString(),
            productName: item.nom,
            urgencyScore: 70 - (daysUntilExpiry * 5),
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
            id: 'maintenance_due_${item.id}',
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
  List<Alert> filterAlerts(List<Alert> alerts, AlertFilter filter) {
    return alerts.where((alert) {
      if (filter.minPriority != null &&
          alert.priority.index > filter.minPriority!.index) {
        return false;
      }
      if (filter.types != null && !filter.types!.contains(alert.type)) {
        return false;
      }
      if (filter.actionRequiredOnly && !alert.actionRequired) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Marque une alerte comme lue
  Future<void> markAlertAsRead(String alertId) async {
    // TODO: Implémenter la persistance des alertes lues
    if (kDebugMode) {
      print('Alert marked as read: $alertId');
    }
  }

  /// Marque une alerte comme résolue
  Future<void> resolveAlert(String alertId) async {
    // TODO: Implémenter la persistance des alertes résolues
    if (kDebugMode) {
      print('Alert resolved: $alertId');
    }
  }
}

/// Modèle pour une alerte
class Alert {
  final String id;
  final AlertType type;
  final AlertPriority priority;
  final String title;
  final String message;
  final String? productId;
  final String? productName;
  final int urgencyScore; // 0-100
  final bool actionRequired;
  final List<String> suggestedActions;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final bool isResolved;

  const Alert({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    this.productId,
    this.productName,
    required this.urgencyScore,
    required this.actionRequired,
    required this.suggestedActions,
    required this.createdAt,
    this.metadata,
    this.isRead = false,
    this.isResolved = false,
  });

  Alert copyWith({bool? isRead, bool? isResolved}) {
    return Alert(
      id: id,
      type: type,
      priority: priority,
      title: title,
      message: message,
      productId: productId,
      productName: productName,
      urgencyScore: urgencyScore,
      actionRequired: actionRequired,
      suggestedActions: suggestedActions,
      createdAt: createdAt,
      metadata: metadata,
      isRead: isRead ?? this.isRead,
      isResolved: isResolved ?? this.isResolved,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'priority': priority.toString(),
      'title': title,
      'message': message,
      'productId': productId,
      'productName': productName,
      'urgencyScore': urgencyScore,
      'actionRequired': actionRequired,
      'suggestedActions': suggestedActions,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
      'isRead': isRead,
      'isResolved': isResolved,
    };
  }
}

/// Types d'alertes
enum AlertType {
  stockCritical,
  stockLow,
  budgetHigh,
  budgetUncertain,
  recommendation,
  expired,
  expiringSoon,
  maintenanceDue,
}

/// Priorités d'alertes
enum AlertPriority {
  critical, // Rouge - Action immédiate requise
  high, // Orange - Action requise bientôt
  medium, // Jaune - À surveiller
  low, // Bleu - Information
}

/// Filtre pour les alertes
class AlertFilter {
  final AlertPriority? minPriority;
  final List<AlertType>? types;
  final bool actionRequiredOnly;

  const AlertFilter({
    this.minPriority,
    this.types,
    this.actionRequiredOnly = false,
  });
}

// TODO-S1: AlertGenerationService - Persistence Implementation (HIGH PRIORITY)
// Description: Implement persistence for alert read/resolved states
// Details:
// - Add database table for alert states (see TODO-D1 in db.dart)
// - Implement markAlertAsRead() method to save read state to alert_states table
// - Implement markAlertAsResolved() method to save resolved state to alert_states table
// - Add alert state filtering in getFilteredAlerts() to exclude read/resolved alerts
// - Add methods: getAlertState(alertId), isAlertRead(alertId), isAlertResolved(alertId)
// Impact: Users can't track which alerts they've seen or resolved
// Required methods to add:
//   Future<void> markAlertAsRead(int alertId)
//   Future<void> markAlertAsResolved(int alertId)
//   Future<bool> isAlertRead(int alertId)
//   Future<bool> isAlertResolved(int alertId)
//   Future<List<Alert>> getFilteredAlerts({bool includeRead = false, bool includeResolved = false})

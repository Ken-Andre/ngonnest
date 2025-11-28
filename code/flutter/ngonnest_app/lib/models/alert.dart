/// Types d'alertes unifiés
enum AlertType {
  stockCritical,
  stockLow,
  budgetHigh,
  budgetUncertain,
  recommendation,
  expired,
  expiringSoon,
  maintenanceDue,
  reminder, // Legacy
  system,   // Legacy
}

/// Priorités d'alertes unifiées
enum AlertPriority {
  critical, // Rouge - Action immédiate requise
  high,     // Orange - Action requise bientôt
  medium,   // Jaune - À surveiller
  low,      // Bleu - Information
}

class Alert {
  final int id;
  final int? idFoyer; // Optionnel car certaines alertes sont générées à la volée
  final String? idObjet; // Changé en String? pour compatibilité avec productId
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
  final DateTime? dateLecture;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final bool isResolved;

  const Alert({
    required this.id,
    this.idFoyer,
    this.idObjet,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    this.productId,
    this.productName,
    this.urgencyScore = 0,
    this.actionRequired = false,
    this.suggestedActions = const [],
    required this.createdAt,
    this.dateLecture,
    this.metadata,
    this.isRead = false,
    this.isResolved = false,
  });

  Alert copyWith({
    int? id,
    int? idFoyer,
    String? idObjet,
    AlertType? type,
    AlertPriority? priority,
    String? title,
    String? message,
    String? productId,
    String? productName,
    int? urgencyScore,
    bool? actionRequired,
    List<String>? suggestedActions,
    DateTime? createdAt,
    DateTime? dateLecture,
    Map<String, dynamic>? metadata,
    bool? isRead,
    bool? isResolved,
  }) {
    return Alert(
      id: id ?? this.id,
      idFoyer: idFoyer ?? this.idFoyer,
      idObjet: idObjet ?? this.idObjet,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      message: message ?? this.message,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      urgencyScore: urgencyScore ?? this.urgencyScore,
      actionRequired: actionRequired ?? this.actionRequired,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      createdAt: createdAt ?? this.createdAt,
      dateLecture: dateLecture ?? this.dateLecture,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      isResolved: isResolved ?? this.isResolved,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_foyer': idFoyer,
      'id_objet': idObjet,
      'type_alerte': type.toString().split('.').last,
      'priorite': priority.toString().split('.').last,
      'titre': title,
      'message': message,
      'product_id': productId,
      'product_name': productName,
      'urgency_score': urgencyScore,
      'action_required': actionRequired ? 1 : 0,
      'date_creation': createdAt.toIso8601String(),
      'date_lecture': dateLecture?.toIso8601String(),
      'lu': isRead ? 1 : 0,
      'resolu': isResolved ? 1 : 0,
      // Note: suggestedActions et metadata ne sont pas persistés dans la table standard pour l'instant
      // ou nécessiteraient une sérialisation JSON si la table le supporte
    };
  }

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'],
      idFoyer: map['id_foyer'],
      idObjet: map['id_objet']?.toString(),
      type: _parseAlertType(map['type_alerte']),
      priority: _parseAlertPriority(map['priorite'] ?? map['urgences']), // Fallback pour compatibilité
      title: map['titre'] ?? '',
      message: map['message'] ?? '',
      productId: map['product_id'] ?? map['id_objet']?.toString(),
      productName: map['product_name'],
      urgencyScore: map['urgency_score'] ?? 0,
      actionRequired: map['action_required'] == 1,
      createdAt: map['date_creation'] != null
          ? DateTime.parse(map['date_creation'])
          : DateTime.now(),
      dateLecture: map['date_lecture'] != null
          ? DateTime.parse(map['date_lecture'])
          : null,
      isRead: map['lu'] == 1,
      isResolved: map['resolu'] == 1,
    );
  }

  static AlertType _parseAlertType(String? value) {
    if (value == null) return AlertType.system;
    try {
      return AlertType.values.firstWhere(
        (e) => e.toString().split('.').last == value,
      );
    } catch (_) {
      // Mapping legacy
      if (value == 'stock_faible') return AlertType.stockLow;
      if (value == 'expiration_proche') return AlertType.expiringSoon;
      return AlertType.system;
    }
  }

  static AlertPriority _parseAlertPriority(String? value) {
    if (value == null) return AlertPriority.medium;
    try {
      return AlertPriority.values.firstWhere(
        (e) => e.toString().split('.').last == value,
      );
    } catch (_) {
      // Mapping legacy (Urgency -> Priority)
      if (value == 'high') return AlertPriority.high;
      if (value == 'low') return AlertPriority.low;
      return AlertPriority.medium;
    }
  }

  // Helper methods for display
  static String getTypeDisplayName(AlertType type) {
    switch (type) {
      case AlertType.stockCritical:
        return 'Rupture de stock';
      case AlertType.stockLow:
        return 'Stock faible';
      case AlertType.budgetHigh:
        return 'Budget élevé';
      case AlertType.budgetUncertain:
        return 'Budget incertain';
      case AlertType.recommendation:
        return 'Recommandation';
      case AlertType.expired:
        return 'Produit expiré';
      case AlertType.expiringSoon:
        return 'Expiration proche';
      case AlertType.maintenanceDue:
        return 'Maintenance requise';
      case AlertType.reminder:
        return 'Rappel';
      case AlertType.system:
        return 'Système';
    }
  }

  static String getPriorityDisplayName(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.critical:
        return 'Critique';
      case AlertPriority.high:
        return 'Élevée';
      case AlertPriority.medium:
        return 'Moyenne';
      case AlertPriority.low:
        return 'Faible';
    }
  }
}


enum AlertType {
  stockFaible,
  expirationProche,
  reminder,
  system
}

enum AlertUrgency {
  low,
  medium,
  high
}

class Alert {
  final int? id;
  final int idFoyer;
  final int? idObjet;
  final AlertType typeAlerte;
  final String titre;
  final String message;
  final AlertUrgency urgences;
  final DateTime dateCreation;
  final DateTime? dateLecture;
  final bool lu;
  final bool resolu;

  const Alert({
    this.id,
    required this.idFoyer,
    this.idObjet,
    required this.typeAlerte,
    required this.titre,
    required this.message,
    required this.urgences,
    required this.dateCreation,
    this.dateLecture,
    this.lu = false,
    this.resolu = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_foyer': idFoyer,
      'id_objet': idObjet,
      'type_alerte': typeAlerte.toString().split('.').last,
      'titre': titre,
      'message': message,
      'urgences': urgences.toString().split('.').last,
      'date_creation': dateCreation.toIso8601String(),
      'date_lecture': dateLecture?.toIso8601String(),
      'lu': lu ? 1 : 0,
      'resolu': resolu ? 1 : 0,
    };
  }

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'],
      idFoyer: map['id_foyer'],
      idObjet: map['id_objet'],
      typeAlerte: AlertType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type_alerte'],
        orElse: () => AlertType.system,
      ),
      titre: map['titre'] ?? '',
      message: map['message'] ?? '',
      urgences: AlertUrgency.values.firstWhere(
        (e) => e.toString().split('.').last == map['urgences'],
        orElse: () => AlertUrgency.medium,
      ),
      dateCreation: map['date_creation'] != null
          ? DateTime.parse(map['date_creation'])
          : DateTime.now(),
      dateLecture: map['date_lecture'] != null
          ? DateTime.parse(map['date_lecture'])
          : null,
      lu: map['lu'] == 1,
      resolu: map['resolu'] == 1,
    );
  }

  Alert copyWith({
    int? id,
    int? idFoyer,
    int? idObjet,
    AlertType? typeAlerte,
    String? titre,
    String? message,
    AlertUrgency? urgences,
    DateTime? dateCreation,
    DateTime? dateLecture,
    bool? lu,
    bool? resolu,
  }) {
    return Alert(
      id: id ?? this.id,
      idFoyer: idFoyer ?? this.idFoyer,
      idObjet: idObjet ?? this.idObjet,
      typeAlerte: typeAlerte ?? this.typeAlerte,
      titre: titre ?? this.titre,
      message: message ?? this.message,
      urgences: urgences ?? this.urgences,
      dateCreation: dateCreation ?? this.dateCreation,
      dateLecture: dateLecture ?? this.dateLecture,
      lu: lu ?? this.lu,
      resolu: resolu ?? this.resolu,
    );
  }

  // Helper methods for display
  static String getTypeDisplayName(AlertType type) {
    switch (type) {
      case AlertType.stockFaible:
        return 'Stock faible';
      case AlertType.expirationProche:
        return 'Expiration proche';
      case AlertType.reminder:
        return 'Rappel';
      case AlertType.system:
        return 'Système';
    }
  }

  static String getUrgencyDisplayName(AlertUrgency urgency) {
    switch (urgency) {
      case AlertUrgency.low:
        return 'Faible';
      case AlertUrgency.medium:
        return 'Moyen';
      case AlertUrgency.high:
        return 'Élevé';
    }
  }
}

import '../utils/id_utils.dart';

class HouseholdProfile {
  final int? id;
  final int nbPersonnes;
  final int nbPieces;
  final String typeLogement;
  final String langue;
  final double? budgetMensuelEstime;

  const HouseholdProfile({
    this.id,
    required this.nbPersonnes,
    required this.nbPieces,
    required this.typeLogement,
    required this.langue,
    this.budgetMensuelEstime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nb_personnes': nbPersonnes,
      'nb_pieces': nbPieces,
      'type_logement': typeLogement,
      'langue': langue,
      'budget_mensuel_estime': budgetMensuelEstime,
    };
  }

  factory HouseholdProfile.fromMap(Map<String, dynamic> map) {
    return HouseholdProfile(
      id: IdUtils.toIntId(map['id']),
      nbPersonnes: IdUtils.toInt(map['nb_personnes']) ?? 1,
      nbPieces: IdUtils.toInt(map['nb_pieces']) ?? 1,
      typeLogement: map['type_logement'] as String? ?? '',
      langue: map['langue'] as String? ?? 'fr',
      budgetMensuelEstime: IdUtils.toDouble(map['budget_mensuel_estime']),
    );
  }

  HouseholdProfile copyWith({
    int? id,
    int? nbPersonnes,
    int? nbPieces,
    String? typeLogement,
    String? langue,
    double? budgetMensuelEstime,
  }) {
    return HouseholdProfile(
      id: id ?? this.id,
      nbPersonnes: nbPersonnes ?? this.nbPersonnes,
      nbPieces: nbPieces ?? this.nbPieces,
      typeLogement: typeLogement ?? this.typeLogement,
      langue: langue ?? this.langue,
      budgetMensuelEstime: budgetMensuelEstime ?? this.budgetMensuelEstime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HouseholdProfile &&
        other.id == id &&
        other.nbPersonnes == nbPersonnes &&
        other.typeLogement == typeLogement;
  }

  @override
  int get hashCode {
    return id.hashCode ^ nbPersonnes.hashCode ^ typeLogement.hashCode;
  }
}

class LogementType {
  static const String appartement = 'appartement';
  static const String maison = 'maison';

  static const List<String> values = [appartement, maison];

  static String getDisplayName(String value) {
    switch (value) {
      case appartement:
        return 'Appartement';
      case maison:
        return 'Maison';
      default:
        return value;
    }
  }
}

class Language {
  static const String francais = 'fr';
  static const String anglais = 'en';

  static const List<String> values = [francais, anglais];

  static String getDisplayName(String value) {
    switch (value) {
      case francais:
        return 'Français';
      case anglais:
        return 'English';
      default:
        return 'Français'; // Default to French
    }
  }

  static String getFlag(String value) {
    switch (value) {
      case francais:
        return '🇫🇷';
      case anglais:
        return '🇬🇧';
      default:
        return '🇫🇷';
    }
  }
}

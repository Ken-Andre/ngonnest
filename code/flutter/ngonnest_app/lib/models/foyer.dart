class Foyer {
  final int? id;
  final int nbPersonnes;
  final int nbPieces;
  final String typeLogement;
  final String langue;
  final double? budgetMensuelEstime;

  Foyer({
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

  factory Foyer.fromMap(Map<String, dynamic> map) {
    return Foyer(
      id: map['id'],
      nbPersonnes: map['nb_personnes'],
      nbPieces: map['nb_pieces'] ?? 1,
      typeLogement: map['type_logement'],
      langue: map['langue'],
      budgetMensuelEstime: map['budget_mensuel_estime'],
    );
  }

  Foyer copyWith({
    int? id,
    int? nbPersonnes,
    int? nbPieces,
    String? typeLogement,
    String? langue,
    double? budgetMensuelEstime,
  }) {
    return Foyer(
      id: id ?? this.id,
      nbPersonnes: nbPersonnes ?? this.nbPersonnes,
      nbPieces: nbPieces ?? this.nbPieces,
      typeLogement: typeLogement ?? this.typeLogement,
      langue: langue ?? this.langue,
      budgetMensuelEstime: budgetMensuelEstime ?? this.budgetMensuelEstime,
    );
  }
}

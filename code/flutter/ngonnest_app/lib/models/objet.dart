enum TypeObjet { consommable, durable }
enum MethodePrevision { frequence, debit }

class Objet {
  final int? id;
  final int idFoyer;
  final String nom;
  final String categorie;
  final TypeObjet type;
  final String? room; // Room/location where the item is stored
  final DateTime? dateAchat;
  final int? dureeViePrevJours;
  final DateTime? dateRupturePrev;
  final double quantiteInitiale;
  final double quantiteRestante;
  final String unite;
  final double? tailleConditionnement;
  final double? prixUnitaire;
  final MethodePrevision? methodePrevision;
  final int? frequenceAchatJours;
  final double? consommationJour;
  final int seuilAlerteJours;
  final double seuilAlerteQuantite;
  final String? commentaires; // Commentaires personnels pour durables

  Objet({
    this.id,
    required this.idFoyer,
    required this.nom,
    required this.categorie,
    required this.type,
    this.room,
    this.dateAchat,
    this.dureeViePrevJours,
    this.dateRupturePrev,
    required this.quantiteInitiale,
    required this.quantiteRestante,
    required this.unite,
    this.tailleConditionnement,
    this.prixUnitaire,
    this.methodePrevision,
    this.frequenceAchatJours,
    this.consommationJour,
    this.seuilAlerteJours = 3,
    this.seuilAlerteQuantite = 1,
    this.commentaires, // Optionnel pour durables
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_foyer': idFoyer,
      'nom': nom,
      'categorie': categorie,
      'type': type.toString().split('.').last,
      'room': room,
      'date_achat': dateAchat?.toIso8601String(),
      'duree_vie_prev_jours': dureeViePrevJours,
      'date_rupture_prev': dateRupturePrev?.toIso8601String(),
      'quantite_initiale': quantiteInitiale,
      'quantite_restante': quantiteRestante,
      'unite': unite,
      'taille_conditionnement': tailleConditionnement,
      'prix_unitaire': prixUnitaire,
      'methode_prevision': methodePrevision?.toString().split('.').last,
      'frequence_achat_jours': frequenceAchatJours,
      'consommation_jour': consommationJour,
      'seuil_alerte_jours': seuilAlerteJours,
      'seuil_alerte_quantite': seuilAlerteQuantite,
      'commentaires': commentaires,
    };
  }

  factory Objet.fromMap(Map<String, dynamic> map) {
    return Objet(
      id: map['id'],
      idFoyer: map['id_foyer'],
      nom: map['nom'],
      categorie: map['categorie'],
      type: TypeObjet.values.firstWhere((e) => e.toString().split('.').last == map['type']),
      room: map['room'],
      dateAchat: map['date_achat'] != null ? DateTime.parse(map['date_achat']) : null,
      dureeViePrevJours: map['duree_vie_prev_jours'],
      dateRupturePrev: map['date_rupture_prev'] != null ? DateTime.parse(map['date_rupture_prev']) : null,
      quantiteInitiale: map['quantite_initiale'],
      quantiteRestante: map['quantite_restante'],
      unite: map['unite'],
      tailleConditionnement: map['taille_conditionnement'],
      prixUnitaire: map['prix_unitaire'],
      methodePrevision: map['methode_prevision'] != null
          ? MethodePrevision.values.firstWhere((e) => e.toString().split('.').last == map['methode_prevision'])
          : null,
      frequenceAchatJours: map['frequence_achat_jours'],
      consommationJour: map['consommation_jour'],
      seuilAlerteJours: map['seuil_alerte_jours'] ?? 3,
      seuilAlerteQuantite: map['seuil_alerte_quantite'] ?? 1,
      commentaires: map['commentaires'],
    );
  }

  Objet copyWith({
    int? id,
    int? idFoyer,
    String? nom,
    String? categorie,
    TypeObjet? type,
    String? room,
    DateTime? dateAchat,
    int? dureeViePrevJours,
    DateTime? dateRupturePrev,
    double? quantiteInitiale,
    double? quantiteRestante,
    String? unite,
    double? tailleConditionnement,
    double? prixUnitaire,
    MethodePrevision? methodePrevision,
    int? frequenceAchatJours,
    double? consommationJour,
    int? seuilAlerteJours,
    double? seuilAlerteQuantite,
    String? commentaires,
  }) {
    return Objet(
      id: id ?? this.id,
      idFoyer: idFoyer ?? this.idFoyer,
      nom: nom ?? this.nom,
      categorie: categorie ?? this.categorie,
      type: type ?? this.type,
      room: room ?? this.room,
      dateAchat: dateAchat ?? this.dateAchat,
      dureeViePrevJours: dureeViePrevJours ?? this.dureeViePrevJours,
      dateRupturePrev: dateRupturePrev ?? this.dateRupturePrev,
      quantiteInitiale: quantiteInitiale ?? this.quantiteInitiale,
      quantiteRestante: quantiteRestante ?? this.quantiteRestante,
      unite: unite ?? this.unite,
      tailleConditionnement: tailleConditionnement ?? this.tailleConditionnement,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      methodePrevision: methodePrevision ?? this.methodePrevision,
      frequenceAchatJours: frequenceAchatJours ?? this.frequenceAchatJours,
      consommationJour: consommationJour ?? this.consommationJour,
      seuilAlerteJours: seuilAlerteJours ?? this.seuilAlerteJours,
      seuilAlerteQuantite: seuilAlerteQuantite ?? this.seuilAlerteQuantite,
      commentaires: commentaires ?? this.commentaires,
    );
  }
}

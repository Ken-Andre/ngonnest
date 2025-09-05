import '../models/objet.dart';

/// Service responsable des calculs de prévision de rupture de stock
class PredictionService {

  /// Calcule la date de rupture prévue pour un consommable
  /// selon la méthode de prévision spécifiée
  static DateTime? calculateRuptureDate(Objet objet) {
    // Early validation checks
    if (objet.type == TypeObjet.durable) {
      return null; // Les durables n'ont pas de date de rupture
    }

    if (objet.dateAchat == null) {
      return null; // Besoin de la date d'achat pour calculer
    }

    if (objet.methodePrevision == null) {
      return null; // Méthode de prévision non définie
    }

    switch (objet.methodePrevision!) {
      case MethodePrevision.frequence:
        return _calculateFrequencyDate(objet);
      case MethodePrevision.debit:
        return _calculateDebitDate(objet);
      default:
        return null;
    }
  }

  /// Calcule la date de rupture selon la méthode fréquence
  /// Formule: date_achat + frequence_achat_jours
  static DateTime? _calculateFrequencyDate(Objet objet) {
    if (objet.frequenceAchatJours == null || objet.frequenceAchatJours! <= 0) {
      return null; // Fréquence invalide
    }

    return objet.dateAchat!.add(Duration(days: objet.frequenceAchatJours!));
  }

  /// Calcule la date de rupture selon la méthode débit
  /// Formule: date_achat + (quantite_initiale / consommation_jour)
  static DateTime? _calculateDebitDate(Objet objet) {
    if (objet.consommationJour == null || objet.consommationJour! <= 0) {
      return null; // Consommation invalide
    }

    if (objet.quantiteInitiale <= 0) {
      return null; // Quantité invalide
    }

    // Calcul du nombre de jours: quantite_initiale / consommation_jour
    final daysUntilRupture = objet.quantiteInitiale / objet.consommationJour!;
    final daysRounded = daysUntilRupture.round();

    if (daysRounded <= 0) {
      return objet.dateAchat; // Rupture immédiate
    }

    return objet.dateAchat!.add(Duration(days: daysRounded));
  }

  /// Met à jour la date de rupture d'un objet et le retourne modifié
  static Objet updateRuptureDate(Objet objet) {
    final newRuptureDate = calculateRuptureDate(objet);
    return objet.copyWith(dateRupturePrev: newRuptureDate);
  }

  /// Vérifie si un objet est en rupture de stock (basé sur date actuelle)
  static bool isRuptureExpired(Objet objet) {
    if (objet.dateRupturePrev == null) {
      return false; // Pas de date de rupture définie
    }

    return DateTime.now().isAfter(objet.dateRupturePrev!);
  }

  /// Calcule le nombre de jours avant rupture
  static int? getDaysUntilRupture(Objet objet) {
    if (objet.dateRupturePrev == null) {
      return null;
    }

    final now = DateTime.now();
    final ruptureDate = objet.dateRupturePrev!;

    if (now.isAfter(ruptureDate)) {
      // Déjà en rupture
      return (ruptureDate.difference(now).inDays).abs() * -1;
    }

    return ruptureDate.difference(now).inDays;
  }

  /// Vérifie si l'objet est proche de la rupture selon le seuil d'alerte
  static bool isNearRupture(Objet objet) {
    final daysUntil = getDaysUntilRupture(objet);

    if (daysUntil == null) {
      return false; // Impossible de déterminer
    }

    // Si déjà en rupture ou dans les jours d'alerte
    return daysUntil <= objet.seuilAlerteJours;
  }

  /// Valide les paramètres nécessaires pour le calcul selon la méthode choisie
  static List<String> validateCalculation(Objet objet) {
    final errors = <String>[];

    if (objet.type == TypeObjet.durable) {
      return errors; // Skip validation pour durables
    }

    if (objet.dateAchat == null) {
      errors.add('Date d\'achat manquante');
    }

    if (objet.methodePrevision == null) {
      errors.add('Méthode de prévision non définie');
      return errors; // Skip other validations
    }

    switch (objet.methodePrevision!) {
      case MethodePrevision.frequence:
        if (objet.frequenceAchatJours == null || objet.frequenceAchatJours! <= 0) {
          errors.add('Fréquence d\'achat invalide (doit être > 0)');
        }
        break;

      case MethodePrevision.debit:
        if (objet.consommationJour == null || objet.consommationJour! <= 0) {
          errors.add('Consommation journalière invalide (doit être > 0)');
        }
        if (objet.quantiteInitiale <= 0) {
          errors.add('Quantité initiale invalide (doit être > 0)');
        }
        break;
    }

    return errors;
  }

  /// Calcule la date de rupture pour les tests unitaires
  /// Version isolée pour testing
  static DateTime? calculateRuptureDateForTest({
    required DateTime dateAchat,
    required MethodePrevision methodePrevision,
    int? frequenceAchatJours,
    double? quantiteInitiale,
    double? consommationJour,
  }) {
    final objet = Objet(
      id: null,
      idFoyer: 1,
      nom: 'Test Object',
      categorie: 'test',
      type: TypeObjet.consommable,
      dateAchat: dateAchat,
      quantiteInitiale: quantiteInitiale ?? 10.0,
      quantiteRestante: quantiteInitiale ?? 10.0,
      unite: 'unités',
      methodePrevision: methodePrevision,
      frequenceAchatJours: frequenceAchatJours,
      consommationJour: consommationJour,
    );

    return calculateRuptureDate(objet);
  }
}

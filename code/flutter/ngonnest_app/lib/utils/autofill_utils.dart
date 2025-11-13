import 'package:flutter/material.dart';

/// Utilitaires pour l'autofill des formulaires dans NgonNest
/// Fournit des configurations standard pour les champs de formulaire
/// afin d'améliorer l'expérience utilisateur avec les gestionnaires de mots de passe
class AutofillUtils {
  /// Configuration pour le champ email
  static List<String> getEmailAutofillHints() {
    return [AutofillHints.email];
  }

  /// Configuration pour le champ nom complet
  static List<String> getFullNameAutofillHints() {
    return [AutofillHints.name];
  }

  /// Configuration pour le champ mot de passe
  static List<String> getPasswordAutofillHints() {
    return [AutofillHints.password];
  }

  /// Configuration pour la confirmation du mot de passe
  static List<String> getConfirmPasswordAutofillHints() {
    return [AutofillHints.newPassword];
  }

  /// Type de clavier pour email
  static TextInputType getEmailInputType() {
    return TextInputType.emailAddress;
  }

  /// Type de clavier pour nom complet
  static TextInputType getFullNameInputType() {
    return TextInputType.name;
  }

  /// Type de clavier pour mot de passe
  static TextInputType getPasswordInputType() {
    return TextInputType.visiblePassword;
  }

  /// Active l'autofill pour un TextFormField
  static InputDecoration applyAutofillDecoration(
    InputDecoration decoration, {
    required String label,
    IconData? icon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}

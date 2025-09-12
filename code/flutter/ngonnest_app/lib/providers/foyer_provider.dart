import 'package:flutter/material.dart';
import '../services/household_service.dart';

class FoyerProvider extends ChangeNotifier {
  int? _foyerId;

  int? get foyerId => _foyerId;

  Future<void> loadFoyerId() async {
    try {
      final foyer = await HouseholdService.getFoyer();
      _foyerId = foyer?.id;
      notifyListeners();
    } catch (_) {
      // Silently fail; ID will remain null
    }
  }

  void setFoyerId(int id) {
    if (_foyerId != id) {
      _foyerId = id;
      notifyListeners();
    }
  }
}

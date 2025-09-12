import 'package:flutter/material.dart';
import '../services/household_service.dart';

class FoyerProvider extends ChangeNotifier {
  int? _foyerId;

  int? get foyerId => _foyerId;

  Future<void> initialize() async {
    final foyer = await HouseholdService.getFoyer();
    _foyerId = foyer?.id;
    notifyListeners();
  }

  void setFoyerId(int id) {
    _foyerId = id;
    notifyListeners();
  }

  void clear() {
    _foyerId = null;
    notifyListeners();
  }
}

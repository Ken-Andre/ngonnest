import 'package:flutter/material.dart';
import '../services/household_service.dart';

import '../models/foyer.dart';

class FoyerProvider extends ChangeNotifier {
  Foyer? _foyer;

  Foyer? get foyer => _foyer;
  int? get foyerId => _foyer?.id;

  Future<void> initialize() async {
    _foyer = await HouseholdService.getFoyer();
    notifyListeners();
  }

  void setFoyer(Foyer foyer) {
    if (_foyer?.id != foyer.id || _foyer != foyer) {
      _foyer = foyer;
      notifyListeners();
    }
  }

  void clear() {
    _foyer = null;
    notifyListeners();
  }
}

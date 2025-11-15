import 'package:flutter/material.dart';

import '../models/foyer.dart';
import '../services/household_service.dart';

class FoyerProvider extends ChangeNotifier {
  Foyer? _foyer;

  Foyer? get foyer => _foyer;
  String? get foyerId => _foyer?.id?.toString();

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

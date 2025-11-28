import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ngonnest_app/services/database_service.dart';
import 'package:ngonnest_app/models/alert.dart';

void main() {
  late DatabaseService databaseService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseService = DatabaseService();
  });

  test('should initialize database', () async {
    final db = await databaseService.database;
    expect(db.isOpen, true);
  });

  test('should save and retrieve alert state', () async {
    const alertId = 123;
    
    // Save state
    await databaseService.saveAlertState(alertId, isRead: true, isResolved: false);
    
    // Retrieve state
    final states = await databaseService.getAlertStates();
    expect(states.containsKey(alertId), true);
    expect(states[alertId]!['isRead'], true);
    expect(states[alertId]!['isResolved'], false);
    
    // Update state
    await databaseService.saveAlertState(alertId, isResolved: true);
    
    // Retrieve updated state
    final updatedStates = await databaseService.getAlertStates();
    expect(updatedStates[alertId]!['isRead'], true); // Should remain true
    expect(updatedStates[alertId]!['isResolved'], true);
  });
}

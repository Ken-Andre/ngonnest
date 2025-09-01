import 'package:sqflite/sqflite.dart';
import '../models/household_profile.dart';
import '../db.dart';

class HouseholdService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  // Create or update household profile
  static Future<int> saveHouseholdProfile(HouseholdProfile profile) async {
    final db = await database;
    
    // Check if profile already exists
    final existing = await getHouseholdProfile();
    if (existing != null) {
      // Update existing profile
      return await db.update(
        'foyer',
        profile.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      // Insert new profile
      return await db.insert('foyer', profile.toMap());
    }
  }

  // Get household profile
  static Future<HouseholdProfile?> getHouseholdProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('foyer');
    
    if (maps.isNotEmpty) {
      return HouseholdProfile.fromMap(maps.first);
    }
    return null;
  }

  // Check if household profile exists
  static Future<bool> hasHouseholdProfile() async {
    final profile = await getHouseholdProfile();
    return profile != null;
  }

  // Delete household profile
  static Future<int> deleteHouseholdProfile() async {
    final db = await database;
    return await db.delete('foyer');
  }
}


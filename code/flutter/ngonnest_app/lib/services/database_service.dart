import 'package:sqflite/sqflite.dart';
import '../models/foyer.dart';
import '../models/objet.dart';
import '../models/alert.dart';
import '../db.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  // Foyer operations
  Future<Foyer?> getFoyer() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('foyer', limit: 1);
    if (maps.isEmpty) return null;
    return Foyer.fromMap(maps.first);
  }

  Future<int> insertFoyer(Foyer foyer) async {
    final db = await database;
    return await db.insert('foyer', foyer.toMap());
  }

  Future<int> updateFoyer(Foyer foyer) async {
    final db = await database;
    return await db.update(
      'foyer',
      foyer.toMap(),
      where: 'id = ?',
      whereArgs: [foyer.id],
    );
  }

  Future<int> deleteFoyer(int id) async {
    final db = await database;
    return await db.delete(
      'foyer',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Objet operations
  Future<List<Objet>> getObjets({int? idFoyer, TypeObjet? type}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (idFoyer != null) {
      whereClause = 'id_foyer = ?';
      whereArgs.add(idFoyer);
    }

    if (type != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'type = ?';
      whereArgs.add(type.toString().split('.').last);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'objet',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'categorie ASC, nom ASC',
    );

    return List.generate(maps.length, (i) => Objet.fromMap(maps[i]));
  }

  Future<Objet?> getObjet(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'objet',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Objet.fromMap(maps.first);
  }

  Future<int> insertObjet(Objet objet) async {
    final db = await database;
    return await db.insert('objet', objet.toMap());
  }

  Future<int> updateObjet(Objet objet) async {
    final db = await database;
    return await db.update(
      'objet',
      objet.toMap(),
      where: 'id = ?',
      whereArgs: [objet.id],
    );
  }

  Future<int> deleteObjet(int id) async {
    final db = await database;
    return await db.delete(
      'objet',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get total object count
  Future<int> getTotalObjetCount(int idFoyer) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM objet WHERE id_foyer = ?', [idFoyer]));
    return count ?? 0;
  }

  // Get expiring soon object count
  Future<int> getExpiringSoonObjetCount(int idFoyer) async {
    final db = await database;
    final now = DateTime.now();
    final warningDate = now.add(const Duration(days: 5));

    final count = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) FROM objet 
      WHERE id_foyer = ? 
      AND (
        (type = 'consommable' AND quantite_restante <= seuil_alerte_quantite)
        OR (type = 'consommable' AND date_rupture_prev IS NOT NULL AND date_rupture_prev <= ?)
        OR (type = 'durable' AND date_achat IS NOT NULL AND duree_vie_prev_jours IS NOT NULL 
            AND date(?, '+' || duree_vie_prev_jours || ' days') <= ?)
      )
    ''', [
      idFoyer,
      now.add(const Duration(days: 3)).toIso8601String(),
      now.toIso8601String(),
      now.add(const Duration(days: 3)).toIso8601String(),
    ]));
    return count ?? 0;
  }

  // Get objects with alerts (for dashboard)
  Future<List<Objet>> getObjetsWithAlerts(int idFoyer) async {
    final db = await database;
    final now = DateTime.now();
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM objet 
      WHERE id_foyer = ? 
      AND (
        (type = 'consommable' AND quantite_restante <= seuil_alerte_quantite)
        OR (type = 'consommable' AND date_rupture_prev IS NOT NULL AND date_rupture_prev <= ?)
        OR (type = 'durable' AND date_achat IS NOT NULL AND duree_vie_prev_jours IS NOT NULL 
            AND date(?, '+' || duree_vie_prev_jours || ' days') <= ?)
      )
      ORDER BY 
        CASE 
          WHEN type = 'consommable' AND quantite_restante <= seuil_alerte_quantite THEN 1
          WHEN type = 'consommable' AND date_rupture_prev IS NOT NULL AND date_rupture_prev <= ? THEN 2
          ELSE 3
        END,
        categorie ASC, nom ASC
    ''', [
      idFoyer,
      now.add(const Duration(days: 3)).toIso8601String(),
      now.toIso8601String(),
      now.add(const Duration(days: 3)).toIso8601String(),
      now.add(const Duration(days: 3)).toIso8601String(),
    ]);

    return List.generate(maps.length, (i) => Objet.fromMap(maps[i]));
  }

  // Get budget calculation
  Future<Map<String, double>> getBudgetMensuel(int idFoyer) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        categorie,
        SUM(
          CASE 
            WHEN methode_prevision = 'frequence' THEN (prix_unitaire * 30.0 / frequence_achat_jours)
            WHEN methode_prevision = 'debit' THEN (prix_unitaire * consommation_jour * 30.0 / taille_conditionnement)
            ELSE 0
          END
        ) as budget_categorie
      FROM objet 
      WHERE id_foyer = ? 
      AND type = 'consommable' 
      AND prix_unitaire IS NOT NULL
      AND (
        (methode_prevision = 'frequence' AND frequence_achat_jours > 0)
        OR (methode_prevision = 'debit' AND consommation_jour > 0 AND taille_conditionnement > 0)
      )
      GROUP BY categorie
    ''', [idFoyer]);

    final Map<String, double> budget = {};
    for (final map in maps) {
      budget[map['categorie']] = map['budget_categorie'];
    }
    return budget;
  }

  // Alert operations (US-2.1 & US-2.4)
  Future<List<Alert>> getAlerts({int? idFoyer, bool? unreadOnly}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (idFoyer != null) {
      // Join with objet table to filter by foyer
      final sql = '''
        SELECT a.* FROM alertes a
        INNER JOIN objet o ON a.id_objet = o.id
        WHERE o.id_foyer = ?
        ${unreadOnly == true ? 'AND a.lu = 0' : ''}
        ORDER BY a.date_creation DESC
      ''';
      final List<Map<String, dynamic>> maps = await db.rawQuery(sql, [idFoyer]);
      return List.generate(maps.length, (i) => Alert.fromMap(maps[i]));
    } else {
      if (unreadOnly == true) {
        whereClause = 'lu = 0';
      }
      final List<Map<String, dynamic>> maps = await db.query(
        'alertes',
        where: whereClause.isEmpty ? null : whereClause,
        orderBy: 'date_creation DESC',
      );
      return List.generate(maps.length, (i) => Alert.fromMap(maps[i]));
    }
  }

  Future<Alert?> getAlert(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'alertes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Alert.fromMap(maps.first);
  }

  Future<int> insertAlert(Alert alert) async {
    final db = await database;
    return await db.insert('alertes', alert.toMap());
  }

  Future<int> updateAlert(Alert alert) async {
    final db = await database;
    return await db.update(
      'alertes',
      alert.toMap(),
      where: 'id = ?',
      whereArgs: [alert.id],
    );
  }

  Future<int> deleteAlert(int id) async {
    final db = await database;
    return await db.delete(
      'alertes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Insert objet and generate associated alerts
  Future<int> insertObjetWithAlerts(Objet objet, int idFoyer) async {
    final db = await database;
    final objetId = await db.insert('objet', objet.toMap());
    if (objetId > 0) {
      await generateAlerts(idFoyer); // Generate alerts after inserting the object
    }
    return objetId;
  }

  Future<int> markAlertAsRead(int id) async {
    final db = await database;
    return await db.update(
      'alertes',
      {
        'lu': 1,
        'date_lecture': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllReadAlerts(int idFoyer) async {
    final db = await database;
    final sql = '''
      DELETE FROM alertes
      WHERE lu = 1 AND id_objet IN (
        SELECT id FROM objet WHERE id_foyer = ?
      )
    ''';
    return await db.rawDelete(sql, [idFoyer]);
  }

  // Generate alerts for low stock and expiry (US-2.4)
  Future<void> generateAlerts(int idFoyer) async {
    final db = await database;
    final now = DateTime.now();
    final warningDate = now.add(const Duration(days: 5));

    // Generate low stock alerts
    await db.rawInsert('''
      INSERT INTO alertes (id_objet, type_alerte, titre, message, urgences, date_creation, lu, resolu)
      SELECT
        o.id,
        'stock_faible',
        'Stock faible',
        o.nom || ' est en rupture de stock (quantité restante: ' || o.quantite_restante || ')',
        CASE WHEN o.quantite_restante <= 1 THEN 'high' ELSE 'medium' END,
        ?,
        0,
        0
      FROM objet o
      LEFT JOIN alertes a ON a.id_objet = o.id AND a.type_alerte = 'stock_faible' AND a.resolu = 0
      WHERE o.id_foyer = ?
        AND o.type = 'consommable'
        AND o.quantite_restante <= o.seuil_alerte_quantite
        AND a.id IS NULL
    ''', [now.toIso8601String(), idFoyer]);

    // Generate expiry alerts
    await db.rawInsert('''
      INSERT INTO alertes (id_objet, type_alerte, titre, message, urgences, date_creation, lu, resolu)
      SELECT
        o.id,
        'expiration_proche',
        'Expiration proche',
        o.nom || ' expire bientôt (le ' || date(o.date_rupture_prev) || ')',
        CASE WHEN date(o.date_rupture_prev) <= date(?) THEN 'high' ELSE 'medium' END,
        ?,
        0,
        0
      FROM objet o
      LEFT JOIN alertes a ON a.id_objet = o.id AND a.type_alerte = 'expiration_proche' AND a.resolu = 0
      WHERE o.id_foyer = ?
        AND o.date_rupture_prev IS NOT NULL
        AND date(o.date_rupture_prev) <= date(?)
        AND a.id IS NULL
    ''', [now.add(const Duration(days: 2)).toIso8601String(), now.toIso8601String(), idFoyer, warningDate.toIso8601String()]);
  }

  // Close database
  Future<void> close() async {
    if (_database != null) {
      final db = _database!;
      _database = null; // Reset the static instance
      await db.close();
    }
  }
}

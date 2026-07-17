import 'package:sqflite/sqflite.dart';

/// Favorites, view history, downloads, collections and premium unlocks —
/// all stored locally so the app is fully offline.
class UserDataSource {
  UserDataSource(this.db);

  final Database db;

  int get _now => DateTime.now().millisecondsSinceEpoch;

  // ---- Favorites ----------------------------------------------------------
  Future<void> toggleFavorite(String id) async {
    final removed =
        await db.delete('favorites', where: 'design_id = ?', whereArgs: [id]);
    if (removed == 0) {
      await db.insert('favorites', {'design_id': id, 'added_at': _now});
    }
  }

  Future<bool> isFavorite(String id) async {
    final rows = await db.query('favorites',
        where: 'design_id = ?', whereArgs: [id], limit: 1);
    return rows.isNotEmpty;
  }

  Future<List<String>> favoriteIds() async {
    final rows = await db.query('favorites', orderBy: 'added_at DESC');
    return rows.map((r) => r['design_id']! as String).toList();
  }

  // ---- Views / recents -----------------------------------------------------
  Future<void> recordView(String id) => db.rawInsert('''
        INSERT INTO views (design_id, view_count, last_viewed) VALUES (?, 1, ?)
        ON CONFLICT(design_id)
        DO UPDATE SET view_count = view_count + 1, last_viewed = excluded.last_viewed
        ''', [id, _now]);

  Future<List<String>> recentlyViewedIds({int limit = 30}) async {
    final rows =
        await db.query('views', orderBy: 'last_viewed DESC', limit: limit);
    return rows.map((r) => r['design_id']! as String).toList();
  }

  Future<List<String>> mostViewedIds({int limit = 30}) async {
    final rows =
        await db.query('views', orderBy: 'view_count DESC', limit: limit);
    return rows.map((r) => r['design_id']! as String).toList();
  }

  // ---- Downloads ------------------------------------------------------------
  Future<void> recordDownload(String id, String filePath) => db.insert(
        'downloads',
        {'design_id': id, 'file_path': filePath, 'downloaded_at': _now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<Map<String, String>> downloads() async {
    final rows = await db.query('downloads', orderBy: 'downloaded_at DESC');
    return {
      for (final r in rows) r['design_id']! as String: r['file_path']! as String
    };
  }

  // ---- Collections -----------------------------------------------------------
  Future<int> createCollection(String name) =>
      db.insert('collections', {'name': name, 'created_at': _now});

  Future<List<Map<String, Object?>>> collections() => db.rawQuery('''
        SELECT c.id, c.name, COUNT(i.design_id) AS count
        FROM collections c
        LEFT JOIN collection_items i ON i.collection_id = c.id
        GROUP BY c.id ORDER BY c.created_at DESC
        ''');

  Future<void> addToCollection(int collectionId, String designId) => db.insert(
        'collection_items',
        {'collection_id': collectionId, 'design_id': designId, 'added_at': _now},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

  Future<void> removeFromCollection(int collectionId, String designId) =>
      db.delete('collection_items',
          where: 'collection_id = ? AND design_id = ?',
          whereArgs: [collectionId, designId]);

  Future<void> deleteCollection(int collectionId) async {
    await db.delete('collection_items',
        where: 'collection_id = ?', whereArgs: [collectionId]);
    await db.delete('collections', where: 'id = ?', whereArgs: [collectionId]);
  }

  Future<List<String>> collectionItemIds(int collectionId) async {
    final rows = await db.query('collection_items',
        where: 'collection_id = ?',
        whereArgs: [collectionId],
        orderBy: 'added_at DESC');
    return rows.map((r) => r['design_id']! as String).toList();
  }

  // ---- Premium unlocks (via rewarded ads) -------------------------------------
  Future<void> unlockPremium(String id) => db.insert(
        'unlocked_premium',
        {'design_id': id, 'unlocked_at': _now},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

  Future<bool> isUnlocked(String id) async {
    final rows = await db.query('unlocked_premium',
        where: 'design_id = ?', whereArgs: [id], limit: 1);
    return rows.isNotEmpty;
  }
}

import 'package:sqflite/sqflite.dart';

import '../../domain/repositories/design_repository.dart';

/// Raw SQL access to the design database (read-only, FTS5-backed).
class LocalDesignSource {
  LocalDesignSource(this.db);

  final Database db;

  (String, List<Object?>) _where(DesignFilter f) {
    final clauses = <String>[];
    final args = <Object?>[];
    if (f.category != null) {
      clauses.add('category = ?');
      args.add(f.category);
    }
    if (f.subcategory != null) {
      clauses.add('subcategory = ?');
      args.add(f.subcategory);
    }
    if (f.festival != null) {
      clauses.add('festival = ?');
      args.add(f.festival);
    }
    if (f.color != null) {
      clauses.add('dominant_color LIKE ?');
      args.add('${f.color}%');
    }
    if (f.premiumOnly) clauses.add('is_premium = 1');
    return (clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}', args);
  }

  String _orderBy(DesignSort sort) => switch (sort) {
        DesignSort.newest => 'created_at DESC',
        // Deterministic pseudo-trending: rotates daily without a server.
        DesignSort.trending => "substr(hash, 1 + (strftime('%j','now') % 8), 8)",
        DesignSort.mostViewed => 'phash', // overridden by view-join in repository
        DesignSort.mostDownloaded => 'hash',
        DesignSort.random => 'RANDOM()',
      };

  Future<List<Map<String, Object?>>> list({
    required DesignFilter filter,
    required DesignSort sort,
    required int limit,
    required int offset,
  }) {
    final (where, args) = _where(filter);
    return db.rawQuery(
      'SELECT * FROM designs $where ORDER BY ${_orderBy(sort)} LIMIT ? OFFSET ?',
      [...args, limit, offset],
    );
  }

  Future<List<Map<String, Object?>>> search({
    required String query,
    required DesignFilter filter,
    required int limit,
    required int offset,
  }) {
    final sanitized = _ftsQuery(query);
    if (sanitized.isEmpty) {
      return list(
          filter: filter, sort: DesignSort.newest, limit: limit, offset: offset);
    }
    final (where, args) = _where(filter);
    final and = where.isEmpty ? '' : where.replaceFirst('WHERE', 'AND');
    return db.rawQuery('''
      SELECT d.* FROM designs_fts f
      JOIN designs d ON d.id = f.id
      WHERE designs_fts MATCH ? $and
      ORDER BY rank LIMIT ? OFFSET ?
      ''', [sanitized, ...args, limit, offset]);
  }

  /// Escape user input for FTS5: quote each token, join with implicit AND,
  /// add prefix matching on the last token for search-as-you-type.
  String _ftsQuery(String raw) {
    final tokens = raw
        .replaceAll(RegExp(r'["*^]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return '';
    final quoted = tokens.map((t) => '"${t.replaceAll('"', '')}"').toList();
    quoted[quoted.length - 1] = '${quoted.last}*';
    return quoted.join(' ');
  }

  Future<Map<String, Object?>?> byId(String id) async {
    final rows =
        await db.query('designs', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, Object?>>> byIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final marks = List.filled(ids.length, '?').join(',');
    return db.rawQuery('SELECT * FROM designs WHERE id IN ($marks)', ids);
  }

  Future<List<Map<String, Object?>>> related({
    required String id,
    required String category,
    required String subcategory,
    required int limit,
  }) {
    return db.rawQuery('''
      SELECT *, (CASE WHEN subcategory = ? THEN 0 ELSE 1 END) AS r
      FROM designs WHERE category = ? AND id != ?
      ORDER BY r, RANDOM() LIMIT ?
      ''', [subcategory, category, id, limit]);
  }

  Future<List<Map<String, Object?>>> categoriesWithCounts() {
    return db.rawQuery('''
      SELECT c.id, c.name, c.subcategories, COUNT(d.id) AS count
      FROM categories c LEFT JOIN designs d ON d.category = c.id
      GROUP BY c.id ORDER BY count DESC, c.name
      ''');
  }

  Future<List<String>> festivals() async {
    final rows = await db.rawQuery(
        'SELECT DISTINCT festival FROM designs WHERE festival IS NOT NULL ORDER BY festival');
    return rows.map((r) => r['festival']! as String).toList();
  }

  Future<Map<String, Object?>?> deterministicDaily() async {
    final rows = await db.rawQuery('''
      SELECT * FROM designs
      ORDER BY substr(hash || strftime('%Y%j','now'), 3, 10) LIMIT 1
      ''');
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> totalCount() async {
    return Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM designs')) ??
        0;
  }
}

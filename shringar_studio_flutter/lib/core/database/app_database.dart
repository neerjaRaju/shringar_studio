import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import '../network/update_service.dart';

/// Owns the read-only design database (seeded from assets, replaced by the
/// incremental updater) and the local user database (favorites, views,
/// downloads, collections, recents).
class AppDatabase {
  AppDatabase._(this.designDb, this.userDb);

  final Database designDb;
  final Database userDb;

  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final designPath = p.join(dir.path, AppConstants.dbFileName);

    if (!File(designPath).existsSync()) {
      await _copyFromAssets(designPath);
    }

    // Apply an incremental DB downloaded in the background on a prior launch.
    await applyStagedUpdate(designPath);

    final designDb = await openDatabase(designPath, readOnly: true);
    final userDb = await openDatabase(
      p.join(dir.path, 'user_data.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE favorites (
            design_id TEXT PRIMARY KEY,
            added_at INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE views (
            design_id TEXT PRIMARY KEY,
            view_count INTEGER NOT NULL DEFAULT 0,
            last_viewed INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE downloads (
            design_id TEXT PRIMARY KEY,
            file_path TEXT NOT NULL,
            downloaded_at INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE collections (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            created_at INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE collection_items (
            collection_id INTEGER NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
            design_id TEXT NOT NULL,
            added_at INTEGER NOT NULL,
            PRIMARY KEY (collection_id, design_id)
          )''');
        await db.execute('''
          CREATE TABLE unlocked_premium (
            design_id TEXT PRIMARY KEY,
            unlocked_at INTEGER NOT NULL
          )''');
      },
    );
    return AppDatabase._(designDb, userDb);
  }

  static Future<void> _copyFromAssets(String destination) async {
    final data = await rootBundle.load(AppConstants.assetDbPath);
    await File(destination).writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
  }

  /// Atomically swap in a freshly-downloaded database file (used by the
  /// manual "Check for updates" flow in Settings).
  static Future<Database> replaceDesignDb(
      Database current, File downloaded) async {
    final path = current.path;
    await current.close();
    await downloaded.copy(path);
    await downloaded.delete();
    return openDatabase(path, readOnly: true);
  }

  /// If a staged DB (downloaded in the background last launch) exists and is a
  /// valid SQLite file, move it into place and promote its pending version to
  /// applied. Runs before the DB is opened, so it's a safe file-level swap.
  static Future<void> applyStagedUpdate(String designPath) async {
    try {
      final staged = File(await UpdateService.stagedPath());
      if (!staged.existsSync()) return;
      final header = String.fromCharCodes(
          (await staged.openRead(0, 15).first).take(15));
      if (!header.startsWith('SQLite format 3')) {
        await staged.delete();
        return;
      }
      await staged.copy(designPath);
      await staged.delete();
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getString('db_version_pending');
      if (pending != null) {
        await prefs.setString('db_version', pending);
        await prefs.remove('db_version_pending');
      }
    } on Exception {
      // If anything goes wrong, keep the existing DB untouched.
    }
  }
}

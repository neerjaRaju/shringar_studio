import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Incremental updater backed by GitHub Releases — the app's only "backend".
///
/// Two entry points:
///  * [checkAndStage] — called in the background on every launch. Fetches
///    `update.json`; if a newer DB exists it downloads it to a *staged* file
///    and records the pending version. It is NOT applied live (swapping the
///    open, read-only database mid-session risks corruption).
///  * [AppDatabase.applyStagedUpdate] — called at startup *before* the DB is
///    opened; if a staged file is present it replaces the active DB, so the
///    download made on the previous launch takes effect on the next one.
///
/// New images arrive lazily through the CDN URLs already stored in each row,
/// so only the small SQLite file is ever downloaded.
class UpdateService {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _versionKey = 'db_version'; // currently-applied version
  static const _pendingKey = 'db_version_pending'; // downloaded, awaiting apply
  static const stagedFileName = 'shringar_new.db';

  static Future<String> stagedPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, stagedFileName);
  }

  /// Returns update metadata if the latest release is newer than both the
  /// applied version and any already-staged (pending) version.
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final resp = await _client
          .get(Uri.parse(AppConstants.updateJsonUrl))
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final remote = json['version'] as String? ?? '';
      final prefs = await SharedPreferences.getInstance();
      final applied = prefs.getString(_versionKey) ?? '';
      final pending = prefs.getString(_pendingKey) ?? '';
      if (remote.isEmpty || remote == applied || remote == pending) return null;
      return UpdateInfo(
        version: remote,
        totalDesigns: json['total_designs'] as int? ?? 0,
        newDesignIds:
            (json['new_design_ids'] as List? ?? const []).cast<String>(),
        dbUrl: json['db_url'] as String? ?? AppConstants.dbDownloadUrl,
      );
    } on Exception {
      return null; // offline — app keeps working from the local DB
    }
  }

  /// Downloads the new database to the staged file. Caller decides when to
  /// swap it in (live, from Settings) or leave it for startup to apply.
  Future<File?> downloadDatabase(UpdateInfo info) async {
    try {
      final resp = await _client
          .get(Uri.parse(info.dbUrl))
          .timeout(const Duration(minutes: 5));
      if (resp.statusCode != 200 || resp.bodyBytes.length < 4096) return null;
      // integrity check: SQLite magic header
      final header = String.fromCharCodes(resp.bodyBytes.take(15));
      if (!header.startsWith('SQLite format 3')) return null;
      final tmp = File(await stagedPath());
      await tmp.writeAsBytes(resp.bodyBytes, flush: true);
      return tmp;
    } on Exception {
      return null;
    }
  }

  /// Background startup flow: check → download to staged file → record pending.
  /// Returns the [UpdateInfo] that was staged, or null if nothing to do.
  /// The staged DB is applied by [AppDatabase.applyStagedUpdate] next launch.
  Future<UpdateInfo?> checkAndStage() async {
    final info = await checkForUpdate();
    if (info == null) return null;
    final file = await downloadDatabase(info);
    if (file == null) return null;
    await setPending(info.version);
    return info;
  }

  Future<void> setPending(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingKey, version);
  }

  Future<void> markUpdated(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_versionKey, version);
    if (prefs.getString(_pendingKey) == version) {
      await prefs.remove(_pendingKey);
    }
  }
}

class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.totalDesigns,
    required this.newDesignIds,
    required this.dbUrl,
  });

  final String version;
  final int totalDesigns;
  final List<String> newDesignIds;
  final String dbUrl;
}

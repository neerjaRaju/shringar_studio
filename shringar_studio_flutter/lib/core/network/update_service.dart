import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Incremental updater backed by GitHub Releases — the app's only "backend".
///
/// Flow: fetch `update.json` from the latest release; if its version differs
/// from the locally-stored one, download the new SQLite file and hand it to
/// [AppDatabase.replaceDesignDb]. New images arrive lazily through the CDN
/// URLs already inside the database, so nothing else needs downloading.
class UpdateService {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _versionKey = 'db_version';

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final resp = await _client
          .get(Uri.parse(AppConstants.updateJsonUrl))
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final remote = json['version'] as String? ?? '';
      final prefs = await SharedPreferences.getInstance();
      final local = prefs.getString(_versionKey) ?? '';
      if (remote.isEmpty || remote == local) return null;
      return UpdateInfo(
        version: remote,
        totalDesigns: json['total_designs'] as int? ?? 0,
        newDesignIds:
            (json['new_design_ids'] as List? ?? const []).cast<String>(),
        dbUrl: json['db_url'] as String? ?? AppConstants.dbDownloadUrl,
      );
    } on Exception {
      return null; // offline — app keeps working from local DB
    }
  }

  /// Downloads the new database to a temp file. Caller swaps it in.
  Future<File?> downloadDatabase(UpdateInfo info) async {
    try {
      final resp = await _client
          .get(Uri.parse(info.dbUrl))
          .timeout(const Duration(minutes: 5));
      if (resp.statusCode != 200 || resp.bodyBytes.length < 4096) return null;
      // basic integrity check: SQLite magic header
      final header = String.fromCharCodes(resp.bodyBytes.take(15));
      if (!header.startsWith('SQLite format 3')) return null;
      final dir = await getApplicationDocumentsDirectory();
      final tmp = File(p.join(dir.path, 'shringar_new.db'));
      await tmp.writeAsBytes(resp.bodyBytes, flush: true);
      return tmp;
    } on Exception {
      return null;
    }
  }

  Future<void> markUpdated(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_versionKey, version);
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

import '../../core/constants/app_constants.dart';
import '../../domain/entities/design.dart';
import '../../domain/entities/design_category.dart';
import '../../domain/repositories/design_repository.dart';
import '../sources/local_design_source.dart';
import '../sources/user_data_source.dart';

class DesignRepositoryImpl implements DesignRepository {
  DesignRepositoryImpl(this._local, this._user);

  final LocalDesignSource _local;
  final UserDataSource _user;

  List<Design> _map(List<Map<String, Object?>> rows) =>
      rows.map(Design.fromMap).toList();

  @override
  Future<List<Design>> list({
    DesignFilter filter = const DesignFilter(),
    DesignSort sort = DesignSort.newest,
    int limit = AppConstants.pageSize,
    int offset = 0,
  }) async {
    // "Most viewed / downloaded" are personal, offline stats.
    if (sort == DesignSort.mostViewed) {
      final ids = await _user.mostViewedIds(limit: limit);
      return byIds(ids);
    }
    return _map(await _local.list(
        filter: filter, sort: sort, limit: limit, offset: offset));
  }

  @override
  Future<List<Design>> search(
    String query, {
    DesignFilter filter = const DesignFilter(),
    int limit = AppConstants.pageSize,
    int offset = 0,
  }) async =>
      _map(await _local.search(
          query: query, filter: filter, limit: limit, offset: offset));

  @override
  Future<Design?> byId(String id) async {
    final row = await _local.byId(id);
    return row == null ? null : Design.fromMap(row);
  }

  @override
  Future<List<Design>> byIds(List<String> ids) async {
    final rows = await _local.byIds(ids);
    final byId = {for (final r in rows) r['id']! as String: Design.fromMap(r)};
    // preserve requested order (recents, favorites)
    return [for (final id in ids) if (byId[id] != null) byId[id]!];
  }

  @override
  Future<List<Design>> related(Design design, {int limit = 12}) async =>
      _map(await _local.related(
        id: design.id,
        category: design.category,
        subcategory: design.subcategory,
        limit: limit,
      ));

  @override
  Future<List<DesignCategory>> categories() async =>
      (await _local.categoriesWithCounts()).map(DesignCategory.fromMap).toList();

  @override
  Future<List<String>> festivals() => _local.festivals();

  @override
  Future<Design?> dailyDesign() async {
    final row = await _local.deterministicDaily();
    return row == null ? null : Design.fromMap(row);
  }

  @override
  Future<Design?> randomDesign() async {
    final rows = await _local.list(
      filter: const DesignFilter(),
      sort: DesignSort.random,
      limit: 1,
      offset: 0,
    );
    return rows.isEmpty ? null : Design.fromMap(rows.first);
  }

  @override
  Future<int> totalCount() => _local.totalCount();
}

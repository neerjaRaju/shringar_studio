import '../entities/design.dart';
import '../entities/design_category.dart';

/// Sort orders supported by list queries.
enum DesignSort { newest, trending, mostViewed, mostDownloaded, random }

/// Filters applied to search / list queries.
class DesignFilter {
  const DesignFilter({
    this.category,
    this.subcategory,
    this.festival,
    this.color,
    this.premiumOnly = false,
  });

  final String? category;
  final String? subcategory;
  final String? festival;

  /// Hex prefix match on dominant color, e.g. '#c5'.
  final String? color;
  final bool premiumOnly;
}

abstract interface class DesignRepository {
  Future<List<Design>> list({
    DesignFilter filter = const DesignFilter(),
    DesignSort sort = DesignSort.newest,
    int limit,
    int offset,
  });

  Future<List<Design>> search(
    String query, {
    DesignFilter filter = const DesignFilter(),
    int limit,
    int offset,
  });

  Future<Design?> byId(String id);
  Future<List<Design>> byIds(List<String> ids);
  Future<List<Design>> related(Design design, {int limit});
  Future<List<DesignCategory>> categories();
  Future<List<String>> festivals();
  Future<Design?> dailyDesign();
  Future<Design?> randomDesign();
  Future<int> totalCount();
}

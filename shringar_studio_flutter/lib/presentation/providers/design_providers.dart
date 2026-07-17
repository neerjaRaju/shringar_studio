import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/design.dart';
import '../../domain/entities/design_category.dart';
import '../../domain/repositories/design_repository.dart';
import 'core_providers.dart';

/// Categories (with counts) for the Categories tab.
final categoriesProvider = FutureProvider<List<DesignCategory>>(
  (ref) => ref.watch(designRepositoryProvider).categories(),
);

final festivalsProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(designRepositoryProvider).festivals(),
);

final dailyDesignProvider = FutureProvider<Design?>(
  (ref) => ref.watch(designRepositoryProvider).dailyDesign(),
);

/// Home carousels keyed by sort.
final homeSectionProvider =
    FutureProvider.family<List<Design>, DesignSort>((ref, sort) {
  return ref.watch(designRepositoryProvider).list(sort: sort, limit: 20);
});

final relatedProvider =
    FutureProvider.family<List<Design>, Design>((ref, design) {
  return ref.watch(designRepositoryProvider).related(design);
});

/// A reusable paginated feed controller (infinite scroll).
class DesignFeedState {
  const DesignFeedState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 0,
  });

  final List<Design> items;
  final bool isLoading;
  final bool hasMore;
  final int page;

  DesignFeedState copyWith({
    List<Design>? items,
    bool? isLoading,
    bool? hasMore,
    int? page,
  }) =>
      DesignFeedState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
      );
}

class DesignFeedNotifier extends StateNotifier<DesignFeedState> {
  DesignFeedNotifier(this._repo, this._query) : super(const DesignFeedState()) {
    loadMore();
  }

  final DesignRepository _repo;
  final FeedQuery _query;

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    final offset = state.page * AppConstants.pageSize;
    final batch = _query.search != null && _query.search!.isNotEmpty
        ? await _repo.search(_query.search!,
            filter: _query.filter, offset: offset)
        : await _repo.list(
            filter: _query.filter, sort: _query.sort, offset: offset);
    state = state.copyWith(
      items: [...state.items, ...batch],
      isLoading: false,
      hasMore: batch.length == AppConstants.pageSize,
      page: state.page + 1,
    );
  }

  Future<void> refresh() async {
    state = const DesignFeedState();
    await loadMore();
  }
}

class FeedQuery {
  const FeedQuery({
    this.search,
    this.filter = const DesignFilter(),
    this.sort = DesignSort.newest,
  });

  final String? search;
  final DesignFilter filter;
  final DesignSort sort;

  @override
  bool operator ==(Object other) =>
      other is FeedQuery &&
      other.search == search &&
      other.sort == sort &&
      other.filter.category == filter.category &&
      other.filter.subcategory == filter.subcategory &&
      other.filter.festival == filter.festival &&
      other.filter.color == filter.color &&
      other.filter.premiumOnly == filter.premiumOnly;

  @override
  int get hashCode => Object.hash(search, sort, filter.category,
      filter.subcategory, filter.festival, filter.color, filter.premiumOnly);
}

final designFeedProvider = StateNotifierProvider.family<DesignFeedNotifier,
    DesignFeedState, FeedQuery>(
  (ref, query) => DesignFeedNotifier(ref.watch(designRepositoryProvider), query),
);

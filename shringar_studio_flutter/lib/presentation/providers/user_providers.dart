import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/design.dart';
import 'core_providers.dart';

/// Favorites -----------------------------------------------------------------
final favoriteIdsProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(ref),
);

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier(this._ref) : super({}) {
    _load();
  }
  final Ref _ref;

  Future<void> _load() async {
    final ids = await _ref.read(userDataSourceProvider).favoriteIds();
    state = ids.toSet();
  }

  Future<void> toggle(String id) async {
    await _ref.read(userDataSourceProvider).toggleFavorite(id);
    state = state.contains(id)
        ? (Set<String>.from(state)..remove(id))
        : (Set<String>.from(state)..add(id));
  }

  bool isFavorite(String id) => state.contains(id);
}

final favoriteDesignsProvider = FutureProvider<List<Design>>((ref) async {
  final ids = ref.watch(favoriteIdsProvider).toList();
  return ref.watch(designRepositoryProvider).byIds(ids);
});

/// Recently viewed & most viewed ----------------------------------------------
final recentlyViewedProvider = FutureProvider<List<Design>>((ref) async {
  final ids = await ref.watch(userDataSourceProvider).recentlyViewedIds();
  return ref.watch(designRepositoryProvider).byIds(ids);
});

/// Downloads -------------------------------------------------------------------
final downloadsProvider = FutureProvider<List<Design>>((ref) async {
  final map = await ref.watch(userDataSourceProvider).downloads();
  return ref.watch(designRepositoryProvider).byIds(map.keys.toList());
});

/// Premium unlock state --------------------------------------------------------
final unlockedProvider =
    StateNotifierProvider<UnlockedNotifier, Set<String>>(
  (ref) => UnlockedNotifier(ref),
);

class UnlockedNotifier extends StateNotifier<Set<String>> {
  UnlockedNotifier(this._ref) : super({});
  final Ref _ref;

  Future<bool> isUnlocked(String id) async {
    if (state.contains(id)) return true;
    final unlocked = await _ref.read(userDataSourceProvider).isUnlocked(id);
    if (unlocked) state = {...state, id};
    return unlocked;
  }

  Future<void> unlock(String id) async {
    await _ref.read(userDataSourceProvider).unlockPremium(id);
    state = {...state, id};
  }
}

/// Collections -----------------------------------------------------------------
final collectionsProvider = FutureProvider<List<Map<String, Object?>>>(
  (ref) => ref.watch(userDataSourceProvider).collections(),
);

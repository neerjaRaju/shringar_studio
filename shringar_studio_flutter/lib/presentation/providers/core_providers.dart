import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';
import '../../core/network/update_service.dart';
import '../../data/repositories/design_repository_impl.dart';
import '../../data/sources/local_design_source.dart';
import '../../data/sources/user_data_source.dart';
import '../../domain/repositories/design_repository.dart';

/// Dependency injection graph via Riverpod.

/// Overridden in [main] after async open.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

/// Bumped when the design DB is swapped live by the auto-updater, forcing the
/// data source (and everything downstream) to rebuild against the new DB.
final libraryRevisionProvider = StateProvider<int>((_) => 0);

final localDesignSourceProvider = Provider<LocalDesignSource>((ref) {
  ref.watch(libraryRevisionProvider);
  return LocalDesignSource(ref.watch(appDatabaseProvider).designDb);
});

final userDataSourceProvider = Provider<UserDataSource>(
  (ref) => UserDataSource(ref.watch(appDatabaseProvider).userDb),
);

final designRepositoryProvider = Provider<DesignRepository>(
  (ref) => DesignRepositoryImpl(
    ref.watch(localDesignSourceProvider),
    ref.watch(userDataSourceProvider),
  ),
);

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

final totalCountProvider = FutureProvider<int>(
  (ref) => ref.watch(designRepositoryProvider).totalCount(),
);

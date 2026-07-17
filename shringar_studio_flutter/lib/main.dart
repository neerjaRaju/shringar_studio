import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/ads/ad_manager.dart';
import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/core_providers.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await AppDatabase.open();
  final prefs = await SharedPreferences.getInstance();

  // Ads initialise in the background; UI never blocks on them.
  AdManager.instance.initialize();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const ShringarApp(),
    ),
  );
}

class ShringarApp extends ConsumerWidget {
  const ShringarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final useDynamic = settings.dynamicColor;
        return MaterialApp.router(
          title: 'Shringar Studio',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(useDynamic ? lightDynamic : null),
          darkTheme: AppTheme.dark(useDynamic ? darkDynamic : null),
          themeMode: settings.themeMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}

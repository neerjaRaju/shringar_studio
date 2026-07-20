import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/ads/ad_manager.dart';
import 'core/database/app_database.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/core_providers.dart';
import 'presentation/providers/design_providers.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/router/app_router.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Applies any DB staged on a previous launch, then opens it.
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

class ShringarApp extends ConsumerStatefulWidget {
  const ShringarApp({super.key});

  @override
  ConsumerState<ShringarApp> createState() => _ShringarAppState();
}

class _ShringarAppState extends ConsumerState<ShringarApp>
    with WidgetsBindingObserver {
  bool _firstResume = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Auto-update: check GitHub Releases, download if newer, apply live.
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoUpdate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Show the app-open ad only when returning to the foreground — never over
    // the cold-start/splash, per AdMob app-open policy.
    if (state == AppLifecycleState.resumed) {
      if (_firstResume) {
        _firstResume = false;
        return;
      }
      AdManager.instance.showAppOpenIfAvailable();
    }
  }

  Future<void> _autoUpdate() async {
    final svc = ref.read(updateServiceProvider);
    final info = await svc.checkForUpdate();
    if (info == null) return; // up to date or offline

    final file = await svc.downloadDatabase(info);
    if (file == null) return; // download failed — try again next launch

    // Live-swap the design DB and refresh everything that reads from it.
    await ref.read(appDatabaseProvider).reopenDesignDb(file);
    await svc.markUpdated(info.version);
    if (!mounted) return;
    ref.read(libraryRevisionProvider.notifier).state++;
    ref.invalidate(categoriesProvider);
    ref.invalidate(festivalsProvider);
    ref.invalidate(dailyDesignProvider);
    ref.invalidate(totalCountProvider);

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Library updated — ${info.totalDesigns} designs now available'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final useDynamic = settings.dynamicColor;
        return MaterialApp.router(
          title: 'Shringar Studio',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: scaffoldMessengerKey,
          theme: AppTheme.light(useDynamic ? lightDynamic : null),
          darkTheme: AppTheme.dark(useDynamic ? darkDynamic : null),
          themeMode: settings.themeMode,
          routerConfig: appRouter,
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final scheme = Theme.of(context).colorScheme;
            // System navigation bar: white with dark icons in light mode;
            // matches the dark surface in dark mode.
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor:
                  isDark ? scheme.surface : Colors.white,
              systemNavigationBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarDividerColor: Colors.transparent,
            ));
            return child!;
          },
        );
      },
    );
  }
}

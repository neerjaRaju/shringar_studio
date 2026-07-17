import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/category/category_screen.dart';
import '../screens/collections/collections_screen.dart';
import '../screens/detail/detail_screen.dart';
import '../screens/downloads/downloads_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/home/home_shell.dart';
import '../screens/premium/premium_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/slideshow/slideshow_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Bottom-nav shell: Home / Categories / Search / Favorites.
    ShellRoute(
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeTab()),
        GoRoute(
            path: '/categories', builder: (_, __) => const CategoriesTab()),
        GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
        GoRoute(
            path: '/favorites', builder: (_, __) => const FavoritesScreen()),
      ],
    ),
    GoRoute(
      path: '/category/:id',
      builder: (_, state) => CategoryScreen(
        categoryId: state.pathParameters['id']!,
        categoryName: state.uri.queryParameters['name'] ?? 'Category',
      ),
    ),
    GoRoute(
      path: '/design/:id',
      builder: (_, state) => DetailScreen(designId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/downloads', builder: (_, __) => const DownloadsScreen()),
    GoRoute(path: '/collections', builder: (_, __) => const CollectionsScreen()),
    GoRoute(path: '/premium', builder: (_, __) => const PremiumScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/slideshow', builder: (_, __) => const SlideshowScreen()),
  ],
  errorBuilder: (_, state) => Scaffold(
    body: Center(child: Text('Route not found: ${state.uri}')),
  ),
);

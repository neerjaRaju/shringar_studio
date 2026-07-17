import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/design_category.dart';
import '../../providers/design_providers.dart';
import 'home_tab.dart';

export 'home_tab.dart' show HomeTab;

/// Bottom-navigation shell wrapping the four primary tabs.
class HomeShell extends StatelessWidget {

  const HomeShell({super.key, required this.child});
  final Widget child;

  static const _tabs = ['/', '/categories', '/search', '/favorites'];

  int _indexFor(String location) {
    if (location.startsWith('/categories')) return 1;
    if (location.startsWith('/search')) return 2;
    if (location.startsWith('/favorites')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _indexFor(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Categories'),
          NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'Search'),
          NavigationDestination(
              icon: Icon(Icons.favorite_outline),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favorites'),
        ],
      ),
    );
  }
}

/// Categories tab (grid of category cards).
class CategoriesTab extends ConsumerWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cats) => GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: cats.length,
          itemBuilder: (context, i) => _CategoryCard(category: cats[i]),
        ),
      ),
    );
  }
}

/// Category card with a representative cover image (emoji fallback when the
/// category has no designs yet).
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});
  final DesignCategory category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
            '/category/${category.id}?name=${Uri.encodeComponent(category.name)}'),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (category.coverUrl != null)
              CachedNetworkImage(
                imageUrl: category.coverUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _emojiBg(scheme),
                placeholder: (_, __) => Container(color: scheme.surfaceContainerHighest),
              )
            else
              _emojiBg(scheme),
            // dark gradient for legible text
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  Text('${category.count} designs',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emojiBg(ColorScheme scheme) => Container(
        color: scheme.primaryContainer,
        alignment: Alignment.center,
        child: Text(category.emoji, style: const TextStyle(fontSize: 42)),
      );
}

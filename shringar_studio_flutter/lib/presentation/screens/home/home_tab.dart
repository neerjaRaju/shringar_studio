import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shringar_studio/presentation/providers/core_providers.dart';

import '../../../core/utils/cdn_image.dart';
import '../../../domain/entities/design.dart';
import '../../../domain/repositories/design_repository.dart';
import '../../providers/design_providers.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/design_card.dart';

/// Home tab: daily design, trending / newest / most-viewed carousels,
/// festival chips and quick actions.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Shringar Studio'),
            actions: [
              IconButton(
                  tooltip: 'Random',
                  icon: const Icon(Icons.shuffle),
                  onPressed: () async {
                    final d =
                        await ref.read(designRepositoryProvider).randomDesign();
                    if (d != null && context.mounted) {
                      context.push('/design/${d.id}');
                    }
                  }),
              IconButton(
                  tooltip: 'Slideshow',
                  icon: const Icon(Icons.slideshow),
                  onPressed: () => context.push('/slideshow')),
              IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push('/settings')),
            ],
          ),
          const SliverToBoxAdapter(child: _DailyDesign()),
          const SliverToBoxAdapter(child: _QuickActions()),
          const SliverToBoxAdapter(child: _FestivalChips()),
          _section(context, 'Trending', DesignSort.trending),
          _section(context, 'Newest', DesignSort.newest),
          _section(context, 'Recently Added', DesignSort.newest),
          const SliverToBoxAdapter(
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: BannerAdWidget()))),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, DesignSort sort) =>
      SliverToBoxAdapter(child: _Carousel(title: title, sort: sort));
}

class _DailyDesign extends ConsumerWidget {
  const _DailyDesign();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyDesignProvider);
    return daily.maybeWhen(
      data: (d) => d == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: GestureDetector(
                onTap: () => context.push('/design/${d.id}'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: CdnImage(url: d.imageUrl, fit: BoxFit.cover),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20)),
                              child: const Text('✨ Design of the Day',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 260,
                              child: Text(d.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.download_outlined, 'Downloads', '/downloads'),
      (Icons.collections_bookmark_outlined, 'Collections', '/collections'),
      (Icons.workspace_premium_outlined, 'Premium', '/premium'),
      (Icons.slideshow_outlined, 'Slideshow', '/slideshow'),
    ];
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final (icon, label, route) = actions[i];
          return InkWell(
            onTap: () => context.push(route),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(icon)),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FestivalChips extends ConsumerWidget {
  const _FestivalChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final festivals = ref.watch(festivalsProvider);
    return festivals.maybeWhen(
      data: (list) => list.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ActionChip(
                    avatar: const Text('🎉'),
                    label: Text(list[i]),
                    onPressed: () =>
                        context.push('/search?festival=${list[i]}'),
                  ),
                ),
              ),
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Carousel extends ConsumerWidget {
  const _Carousel({required this.title, required this.sort});
  final String title;
  final DesignSort sort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(homeSectionProvider(sort));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 190,
          child: data.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (List<Design> items) => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              itemBuilder: (_, i) => SizedBox(
                width: 140,
                child: DesignCard(
                    design: items[i], heroPrefix: 'carousel-$title'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';

import '../../../core/ads/ad_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/design.dart';
import '../../providers/core_providers.dart';
import '../../providers/design_providers.dart';
import '../../providers/user_providers.dart';
import '../../widgets/design_card.dart';

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({super.key, required this.designId});
  final String designId;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  Design? _design;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(designRepositoryProvider);
    final design = await repo.byId(widget.designId);
    if (design == null) return;
    await ref.read(userDataSourceProvider).recordView(design.id);
    final unlocked = design.isPremium
        ? await ref.read(unlockedProvider.notifier).isUnlocked(design.id)
        : true;
    AdManager.instance.maybeShowInterstitial();
    if (mounted) setState(() {
      _design = design;
      _unlocked = unlocked;
    });
  }

  bool get _locked => (_design?.isPremium ?? false) && !_unlocked;

  Future<void> _unlock() async {
    final earned = await AdManager.instance.showRewarded();
    if (!earned) return;
    await ref.read(unlockedProvider.notifier).unlock(_design!.id);
    if (mounted) setState(() => _unlocked = true);
  }

  Future<File> _cachedFile(String url) =>
      DefaultCacheManager().getSingleFile(url);

  Future<void> _share() async {
    final file = await _cachedFile(_design!.imageUrl);
    await Share.shareXFiles([XFile(file.path)], text: _design!.title);
  }

  Future<void> _download() async {
    final cached = await _cachedFile(_design!.imageUrl);
    final dir = await getApplicationDocumentsDirectory();
    final dest = File('${dir.path}/downloads/${_design!.id}.webp');
    await dest.parent.create(recursive: true);
    await cached.copy(dest.path);
    await ref
        .read(userDataSourceProvider)
        .recordDownload(_design!.id, dest.path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to downloads')),
      );
    }
  }

  Future<void> _setWallpaper() async {
    final file = await _cachedFile(_design!.imageUrl);
    try {
      await WallpaperManagerPlus()
          .setWallpaper(file, WallpaperManagerPlus.homeScreen);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallpaper set')),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final design = _design;
    if (design == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final favorites = ref.watch(favoriteIdsProvider);
    final isFav = favorites.contains(design.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(design.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : null),
            onPressed: () =>
                ref.read(favoriteIdsProvider.notifier).toggle(design.id),
          ),
          IconButton(icon: const Icon(Icons.share), onPressed: _share),
        ],
      ),
      body: ListView(
        children: [
          _imageViewer(design),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(design.title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(design.description,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                _metaChips(design),
                const SizedBox(height: 12),
                _colorPalette(design),
                const SizedBox(height: 12),
                _tags(design),
                const SizedBox(height: 16),
                _actions(),
                const SizedBox(height: 24),
                Text('Related designs',
                    style: Theme.of(context).textTheme.titleMedium),
                _related(design),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageViewer(Design design) {
    return AspectRatio(
      aspectRatio: design.aspectRatio.clamp(0.6, 1.4),
      child: Hero(
        tag: 'grid-${design.id}',
        child: Stack(
          fit: StackFit.expand,
          children: [
            PhotoView(
              imageProvider: CachedNetworkImageProvider(design.imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              backgroundDecoration:
                  BoxDecoration(color: Theme.of(context).colorScheme.surface),
            ),
            if (_locked) _lockOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _lockOverlay() => Positioned.fill(
        child: ClipRect(
          child: Container(
            color: Colors.black.withValues(alpha: 0.72),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  const Text('Premium design',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _unlock,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Watch ad to unlock'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _metaChips(Design design) => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          Chip(label: Text(design.subcategory)),
          Chip(label: Text('Difficulty: ${design.difficulty}')),
          if (design.festival != null) Chip(label: Text('🎉 ${design.festival}')),
          Chip(label: Text(design.orientation)),
        ],
      );

  Widget _colorPalette(Design design) => Row(
        children: [
          const Text('Palette: '),
          for (final c in design.colors)
            Container(
              margin: const EdgeInsets.only(right: 6),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: hexToColor(c),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12),
              ),
            ),
        ],
      );

  Widget _tags(Design design) => Wrap(
        spacing: 6,
        children: design.tags
            .map((t) => ActionChip(
                label: Text('#$t'),
                onPressed: () => context.push('/search?q=$t')))
            .toList(),
      );

  Widget _actions() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionBtn(Icons.download, 'Download', _locked ? null : _download),
          _actionBtn(Icons.wallpaper, 'Wallpaper', _locked ? null : _setWallpaper),
          _actionBtn(Icons.share, 'Share', _locked ? null : _share),
        ],
      );

  Widget _actionBtn(IconData icon, String label, VoidCallback? onTap) => Column(
        children: [
          IconButton.filledTonal(onPressed: onTap, icon: Icon(icon)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );

  Widget _related(Design design) {
    final related = ref.watch(relatedProvider(design));
    return related.maybeWhen(
      data: (items) => SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          itemBuilder: (_, i) => SizedBox(
              width: 130,
              child: DesignCard(design: items[i], heroPrefix: 'related')),
        ),
      ),
      orElse: () => const SizedBox(height: 8),
    );
  }
}

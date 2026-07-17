import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../providers/user_providers.dart';
import '../../widgets/design_card.dart';
import '../../widgets/empty_state.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: downloads.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.download_outlined,
                message: 'No downloads yet.\nDownloaded designs work offline.')
            : MasonryGridView.count(
                padding: const EdgeInsets.all(4),
                crossAxisCount: 2,
                itemCount: items.length,
                itemBuilder: (_, i) => AspectRatio(
                  aspectRatio: items[i].aspectRatio.clamp(0.6, 1.4),
                  child: DesignCard(design: items[i], heroPrefix: 'dl'),
                ),
              ),
      ),
    );
  }
}

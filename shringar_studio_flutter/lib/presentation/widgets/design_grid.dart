import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../providers/design_providers.dart';
import 'design_card.dart';
import 'empty_state.dart';

/// Infinite-scrolling masonry grid backed by a [FeedQuery].
class DesignGrid extends ConsumerStatefulWidget {
  const DesignGrid({super.key, required this.query, this.heroPrefix = 'grid'});

  final FeedQuery query;
  final String heroPrefix;

  @override
  ConsumerState<DesignGrid> createState() => _DesignGridState();
}

class _DesignGridState extends ConsumerState<DesignGrid> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.position.pixels >=
          _controller.position.maxScrollExtent - 600) {
        ref.read(designFeedProvider(widget.query).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(designFeedProvider(widget.query));
    if (state.items.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.items.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        message: 'No designs found.\nTry a different search or filter.',
      );
    }
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(designFeedProvider(widget.query).notifier).refresh(),
      child: MasonryGridView.count(
        controller: _controller,
        padding: const EdgeInsets.all(4),
        crossAxisCount: 2,
        itemCount: state.items.length + (state.hasMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const AspectRatio(
              aspectRatio: 0.75,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final design = state.items[index];
          return AspectRatio(
            aspectRatio: design.aspectRatio.clamp(0.6, 1.4),
            child: DesignCard(design: design, heroPrefix: widget.heroPrefix),
          );
        },
      ),
    );
  }
}

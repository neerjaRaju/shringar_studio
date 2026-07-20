import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/utils/cdn_image.dart';
import '../../domain/entities/design.dart';

/// Grid/list card showing a design thumbnail with a premium badge overlay.
class DesignCard extends StatelessWidget {
  const DesignCard({super.key, required this.design, this.heroPrefix = 'grid'});

  final Design design;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.push('/design/${design.id}'),
      child: Card(
        margin: const EdgeInsets.all(4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: '$heroPrefix-${design.id}',
              child: CdnImage(
                url: design.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: Shimmer.fromColors(
                  baseColor: scheme.surfaceContainerHighest,
                  highlightColor: scheme.surfaceContainer,
                  child: Container(color: scheme.surfaceContainerHighest),
                ),
                errorWidget: Container(
                  color: scheme.surfaceContainerHighest,
                  child: Icon(Icons.image_not_supported_outlined,
                      color: scheme.onSurfaceVariant),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
                  ),
                ),
                child: Text(
                  design.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (design.isPremium)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.workspace_premium, size: 12, color: Colors.white),
                    SizedBox(width: 2),
                    Text('PRO',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

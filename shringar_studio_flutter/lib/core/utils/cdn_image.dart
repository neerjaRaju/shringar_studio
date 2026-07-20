import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Converts a jsDelivr GitHub CDN URL to the equivalent raw.githubusercontent
/// URL (a different host / network path), used as an automatic fallback.
///
///   https://cdn.jsdelivr.net/gh/OWNER/REPO@main/path/x.webp
///   -> https://raw.githubusercontent.com/OWNER/REPO/main/path/x.webp
String? rawFallbackUrl(String url) {
  if (!url.contains('cdn.jsdelivr.net/gh/')) return null;
  final converted = url
      .replaceFirst('cdn.jsdelivr.net/gh/', 'raw.githubusercontent.com/')
      .replaceFirst('@main/', '/main/');
  return converted == url ? null : converted;
}

/// Network image that transparently falls back from jsDelivr to GitHub raw
/// when the primary CDN fails (cold cache, connection reset, edge hiccup).
/// Both are cached on disk via [CachedNetworkImage].
class CdnImage extends StatefulWidget {
  const CdnImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  final String url;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  State<CdnImage> createState() => _CdnImageState();
}

class _CdnImageState extends State<CdnImage> {
  late String _current = widget.url;
  bool _triedFallback = false;

  @override
  void didUpdateWidget(CdnImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _current = widget.url;
      _triedFallback = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: _current,
      fit: widget.fit,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) =>
          widget.placeholder ?? const ColoredBox(color: Color(0x11000000)),
      errorWidget: (context, url, error) {
        // On first failure, swap to the raw.githubusercontent fallback once.
        if (!_triedFallback) {
          final fallback = rawFallbackUrl(widget.url);
          if (fallback != null) {
            _triedFallback = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _current = fallback);
            });
            return widget.placeholder ??
                const ColoredBox(color: Color(0x11000000));
          }
        }
        return widget.errorWidget ??
            const ColoredBox(
              color: Color(0x22000000),
              child: Icon(Icons.image_not_supported_outlined),
            );
      },
    );
  }
}

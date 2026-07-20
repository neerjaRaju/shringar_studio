import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Some ISPs (notably in India) reset TLS connections to `cdn.jsdelivr.net`.
/// To stay resilient we serve every GitHub-hosted asset through an ordered
/// list of mirrors and use whichever the user's network allows. All mirrors
/// serve the identical file from the same GitHub repo.
///
/// Given a jsDelivr URL like:
///   https://cdn.jsdelivr.net/gh/OWNER/REPO@main/path/x.webp
/// we derive equivalents on other hosts.
List<String> imageUrlCandidates(String url) {
  final candidates = <String>[];
  void add(String u) {
    if (u.isNotEmpty && !candidates.contains(u)) candidates.add(u);
  }

  String? owner, repo, ref, path;
  final js = RegExp(r'cdn\.jsdelivr\.net/gh/([^/]+)/([^@]+)@([^/]+)/(.+)$')
      .firstMatch(url);
  final raw = RegExp(r'raw\.githubusercontent\.com/([^/]+)/([^/]+)/([^/]+)/(.+)$')
      .firstMatch(url);
  final m = js ?? raw;
  if (m != null) {
    owner = m.group(1);
    repo = m.group(2);
    ref = m.group(3);
    path = m.group(4);
  }

  if (owner != null && repo != null && ref != null && path != null) {
    // GitHub's own host — most universally reachable.
    add('https://raw.githubusercontent.com/$owner/$repo/$ref/$path');
    // Statically (Cloudflare-backed) — usually reachable where jsDelivr is not.
    add('https://cdn.statically.io/gh/$owner/$repo/$ref/$path');
    // jsDelivr alternates that bypass the commonly-blocked cdn. hostname.
    add('https://fastly.jsdelivr.net/gh/$owner/$repo@$ref/$path');
    add('https://gcore.jsdelivr.net/gh/$owner/$repo@$ref/$path');
    // Original jsDelivr last (works fine for most users; disk-cached).
    add('https://cdn.jsdelivr.net/gh/$owner/$repo@$ref/$path');
  }
  add(url); // always keep the original as a final resort
  return candidates;
}

/// Network image that cascades through [imageUrlCandidates] until one host
/// succeeds. Each successful image is disk-cached by [CachedNetworkImage].
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
  late List<String> _candidates = imageUrlCandidates(widget.url);
  int _index = 0;

  @override
  void didUpdateWidget(CdnImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _candidates = imageUrlCandidates(widget.url);
      _index = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeholder =
        widget.placeholder ?? const ColoredBox(color: Color(0x11000000));
    return CachedNetworkImage(
      imageUrl: _candidates[_index],
      fit: widget.fit,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => placeholder,
      errorWidget: (context, url, error) {
        if (_index < _candidates.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _index++);
          });
          return placeholder;
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

/// Downloads a GitHub-hosted asset (for share / download / wallpaper),
/// trying each mirror until one works. Returns null if all fail.
Future<File?> fetchImageFileWithFallback(String url) async {
  for (final candidate in imageUrlCandidates(url)) {
    try {
      final file = await DefaultCacheManager().getSingleFile(candidate);
      if (await file.length() > 0) return file;
    } on Exception {
      continue;
    }
  }
  return null;
}

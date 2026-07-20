import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// Full-screen, pinch-to-zoom image viewer with double-tap zoom and pan.
class FullScreenImageViewer extends StatelessWidget {
  const FullScreenImageViewer({
    super.key,
    required this.imageProvider,
    required this.heroTag,
    this.title,
  });

  final ImageProvider imageProvider;
  final String heroTag;
  final String? title;

  static Future<void> open(
    BuildContext context, {
    required ImageProvider imageProvider,
    required String heroTag,
    String? title,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => FullScreenImageViewer(
          imageProvider: imageProvider,
          heroTag: heroTag,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: title == null
            ? null
            : Text(title!,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: PhotoView(
        imageProvider: imageProvider,
        heroAttributes: PhotoViewHeroAttributes(tag: heroTag),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 5,
        initialScale: PhotoViewComputedScale.contained,
        enableRotation: false,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (_, __) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
        ),
      ),
    );
  }
}

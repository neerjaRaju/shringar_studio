import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/design.dart';
import '../../../domain/repositories/design_repository.dart';
import '../../providers/core_providers.dart';

/// Auto-advancing full-screen slideshow / wallpaper preview mode.
class SlideshowScreen extends ConsumerStatefulWidget {
  const SlideshowScreen({super.key});

  @override
  ConsumerState<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends ConsumerState<SlideshowScreen> {
  final _controller = PageController();
  List<Design> _items = [];
  Timer? _timer;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await ref
        .read(designRepositoryProvider)
        .list(sort: DesignSort.random, limit: 40);
    if (mounted) {
      setState(() => _items = items);
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_playing || _items.isEmpty || !_controller.hasClients) return;
      final next = ((_controller.page ?? 0).round() + 1) % _items.length;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
            onPressed: () => setState(() => _playing = !_playing),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _controller,
              itemCount: _items.length,
              itemBuilder: (_, i) => InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: _items[i].imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
    );
  }
}

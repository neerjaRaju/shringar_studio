import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../domain/repositories/design_repository.dart';
import '../../providers/design_providers.dart';
import '../../widgets/design_grid.dart';

/// FTS5 search with voice input, plus category / festival / color filters.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _speech = SpeechToText();
  String _query = '';
  String? _category;
  String? _festival;
  String? _color;
  bool _listening = false;

  static const _palette = <(String, Color)>[
    ('#8e', Color(0xFF8E1B3A)),
    ('#c9', Color(0xFFC9A227)),
    ('#1b', Color(0xFF1B4D8E)),
    ('#2e', Color(0xFF2E8B57)),
    ('#f0', Color(0xFFF08080)),
    ('#6a', Color(0xFF6A0DAD)),
  ];

  bool _initFromRoute = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read route query params here (not in initState) — inherited widgets like
    // GoRouterState are only available after initState completes. Guarded so it
    // only applies once.
    if (_initFromRoute) return;
    _initFromRoute = true;
    final params = GoRouterState.of(context).uri.queryParameters;
    final fest = params['festival'];
    if (fest != null) _festival = fest;
    final q = params['q'];
    if (q != null && q.isNotEmpty) {
      _query = q;
      _controller.text = q;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final available = await _speech.initialize();
    if (!available) return;
    setState(() => _listening = true);
    await _speech.listen(onResult: (r) {
      setState(() {
        _controller.text = r.recognizedWords;
        _query = r.recognizedWords;
      });
      if (r.finalResult) setState(() => _listening = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = FeedQuery(
      search: _query,
      filter: DesignFilter(
          category: _category, festival: _festival, color: _color),
    );
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search 300k+ designs…',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(_listening ? Icons.mic : Icons.mic_none,
                  color: _listening ? Colors.red : null),
              onPressed: _toggleVoice,
            ),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      body: Column(
        children: [
          _filters(),
          Expanded(child: DesignGrid(query: query, heroPrefix: 'search')),
        ],
      ),
    );
  }

  Widget _filters() {
    final categories = ref.watch(categoriesProvider);
    final festivals = ref.watch(festivalsProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          categories.maybeWhen(
            data: (cats) => _dropdown(
              hint: 'Category',
              value: _category,
              items: {for (final c in cats) c.id: c.name},
              onChanged: (v) => setState(() => _category = v),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          festivals.maybeWhen(
            data: (list) => _dropdown(
              hint: 'Festival',
              value: _festival,
              items: {for (final f in list) f: f},
              onChanged: (v) => setState(() => _festival = v),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          for (final (hex, color) in _palette)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(
                    () => _color = _color == hex ? null : hex),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: color,
                  child: _color == hex
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String hint,
    required String? value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButton<String>(
      value: value,
      hint: Text(hint),
      underline: const SizedBox.shrink(),
      items: [
        DropdownMenuItem(value: null, child: Text('All ${hint}s')),
        ...items.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
      ],
      onChanged: onChanged,
    );
  }
}

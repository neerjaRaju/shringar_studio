import 'dart:convert';

class DesignCategory {
  const DesignCategory({
    required this.id,
    required this.name,
    required this.subcategories,
    this.count = 0,
    this.coverUrl,
  });

  final String id;
  final String name;
  final List<String> subcategories;
  final int count;

  /// Thumbnail URL of a representative design, or null if the category is empty.
  final String? coverUrl;

  factory DesignCategory.fromMap(Map<String, Object?> map) => DesignCategory(
        id: map['id']! as String,
        name: map['name']! as String,
        subcategories: map['subcategories'] is String
            ? (jsonDecode(map['subcategories']! as String) as List).cast<String>()
            : const [],
        count: (map['count'] as num?)?.toInt() ?? 0,
        coverUrl: map['cover'] as String?,
      );

  /// Emoji used on category cards (pure presentation sugar).
  String get emoji => const {
        'mehndi': '🌿', 'blouse': '👚', 'rangoli': '🎨', 'hairstyle': '💇‍♀️',
        'makeup': '💄', 'nail_art': '💅', 'jewellery': '💍', 'saree_draping': '🥻',
        'lehenga': '👗', 'kurti': '👘', 'salwar': '🧵', 'dupatta': '🧣',
        'wedding_decor': '💒', 'bridal_look': '👰', 'diwali': '🪔', 'holi': '🌈',
        'navratri': '🪩', 'eid': '🌙', 'christmas_decor': '🎄', 'cake_decor': '🎂',
        'birthday_decor': '🎈', 'footwear': '👡', 'handbags': '👜',
      }[id] ?? '✨';
}

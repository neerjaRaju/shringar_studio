import 'dart:convert';

/// Immutable domain entity for a design. 100% null safe, value semantics.
class Design {
  const Design({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.tags,
    required this.festival,
    required this.difficulty,
    required this.style,
    required this.colors,
    required this.dominantColor,
    required this.orientation,
    required this.width,
    required this.height,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.createdAt,
    required this.isPremium,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String subcategory;
  final List<String> tags;
  final String? festival;
  final String difficulty;
  final String style;
  final List<String> colors;
  final String dominantColor;
  final String orientation;
  final int width;
  final int height;
  final String imageUrl;
  final String thumbnailUrl;
  final DateTime createdAt;
  final bool isPremium;

  double get aspectRatio => height == 0 ? 1 : width / height;

  factory Design.fromMap(Map<String, Object?> map) {
    List<String> jsonList(Object? v) {
      if (v is List) return v.cast<String>();
      if (v is String && v.isNotEmpty) {
        return (jsonDecode(v) as List).cast<String>();
      }
      return const [];
    }

    return Design(
      id: map['id']! as String,
      title: map['title']! as String,
      description: map['description'] as String? ?? '',
      category: map['category']! as String,
      subcategory: map['subcategory'] as String? ?? '',
      tags: jsonList(map['tags']),
      festival: map['festival'] as String?,
      difficulty: map['difficulty'] as String? ?? 'medium',
      style: map['style'] as String? ?? '',
      colors: jsonList(map['colors']),
      dominantColor: map['dominant_color'] as String? ?? '#000000',
      orientation: map['orientation'] as String? ?? 'square',
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      imageUrl: map['image_url']! as String,
      thumbnailUrl: map['thumbnail_url']! as String,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime(2026),
      isPremium: (map['is_premium'] as num?) == 1,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'subcategory': subcategory,
        'tags': jsonEncode(tags),
        'festival': festival,
        'difficulty': difficulty,
        'style': style,
        'colors': jsonEncode(colors),
        'dominant_color': dominantColor,
        'orientation': orientation,
        'width': width,
        'height': height,
        'image_url': imageUrl,
        'thumbnail_url': thumbnailUrl,
        'created_at': createdAt.toIso8601String(),
        'is_premium': isPremium ? 1 : 0,
      };

  @override
  bool operator ==(Object other) => other is Design && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shringar_studio/domain/entities/design.dart';

void main() {
  group('Design.fromMap', () {
    final map = <String, Object?>{
      'id': 'abc123',
      'title': 'Royal Bridal Mehndi',
      'description': 'A royal arabic bridal mehndi design.',
      'category': 'mehndi',
      'subcategory': 'Bridal',
      'tags': '["mehndi","bridal","royal"]',
      'festival': 'Diwali',
      'difficulty': 'hard',
      'style': 'royal arabic',
      'colors': '["#5a1f0a","#c58b52"]',
      'dominant_color': '#5a1f0a',
      'orientation': 'portrait',
      'width': 1024,
      'height': 1536,
      'hash': 'deadbeef',
      'phash': '00ff00ff',
      'image_url': 'https://cdn/x.webp',
      'thumbnail_url': 'https://cdn/t.webp',
      'created_at': '2026-01-01T00:00:00Z',
      'is_premium': 1,
    };

    test('parses json-encoded lists', () {
      final d = Design.fromMap(map);
      expect(d.tags, ['mehndi', 'bridal', 'royal']);
      expect(d.colors, ['#5a1f0a', '#c58b52']);
      expect(d.isPremium, true);
      expect(d.festival, 'Diwali');
    });

    test('computes aspect ratio', () {
      final d = Design.fromMap(map);
      expect(d.aspectRatio, closeTo(1024 / 1536, 0.0001));
    });

    test('round-trips through toMap', () {
      final d = Design.fromMap(map);
      final d2 = Design.fromMap(d.toMap());
      expect(d2.id, d.id);
      expect(d2.tags, d.tags);
      expect(d2.isPremium, d.isPremium);
    });

    test('equality by id', () {
      expect(Design.fromMap(map), Design.fromMap({...map, 'title': 'Other'}));
    });

    test('tolerates missing optional fields', () {
      final d = Design.fromMap({
        'id': 'x',
        'title': 'T',
        'category': 'mehndi',
        'image_url': 'a',
        'thumbnail_url': 'b',
      });
      expect(d.tags, isEmpty);
      expect(d.difficulty, 'medium');
      expect(d.isPremium, false);
    });
  });
}

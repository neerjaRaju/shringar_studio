import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shringar_studio/data/repositories/design_repository_impl.dart';
import 'package:shringar_studio/data/sources/local_design_source.dart';
import 'package:shringar_studio/data/sources/user_data_source.dart';
import 'package:shringar_studio/domain/repositories/design_repository.dart';

/// In-memory database mirroring the builder's schema, used to exercise the
/// repository and FTS5 queries without a device.
Future<Database> _seedDb() async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  await db.execute('''
    CREATE TABLE designs (
      id TEXT PRIMARY KEY, title TEXT, description TEXT, category TEXT,
      subcategory TEXT, tags TEXT, festival TEXT, difficulty TEXT, style TEXT,
      colors TEXT, dominant_color TEXT, orientation TEXT, width INTEGER,
      height INTEGER, hash TEXT, phash TEXT, image_url TEXT, thumbnail_url TEXT,
      created_at TEXT, updated_at TEXT, is_premium INTEGER, language TEXT,
      prompt_fingerprint TEXT)''');
  await db.execute('''
    CREATE TABLE categories (id TEXT PRIMARY KEY, name TEXT, subcategories TEXT)''');
  await db.execute('''
    CREATE VIRTUAL TABLE designs_fts USING fts5(
      id UNINDEXED, title, description, category, subcategory, tags, festival,
      style, tokenize='porter unicode61')''');

  await db.insert('categories',
      {'id': 'mehndi', 'name': 'Mehndi', 'subcategories': '["Bridal"]'});

  for (var i = 0; i < 5; i++) {
    final row = {
      'id': 'id$i',
      'title': 'Royal Bridal Mehndi $i',
      'description': 'A dense bridal mehndi design.',
      'category': 'mehndi',
      'subcategory': 'Bridal',
      'tags': '["mehndi","bridal"]',
      'festival': i.isEven ? 'Diwali' : null,
      'difficulty': 'hard',
      'style': 'royal arabic',
      'colors': '["#5a1f0a"]',
      'dominant_color': '#5a1f0a',
      'orientation': 'portrait',
      'width': 1024,
      'height': 1536,
      'hash': 'hash$i',
      'phash': 'phash$i',
      'image_url': 'https://cdn/$i.webp',
      'thumbnail_url': 'https://cdn/t$i.webp',
      'created_at': '2026-01-0${i + 1}T00:00:00Z',
      'updated_at': '2026-01-0${i + 1}T00:00:00Z',
      'is_premium': i % 5 == 0 ? 1 : 0,
      'language': 'en',
      'prompt_fingerprint': 'fp$i',
    };
    await db.insert('designs', row);
    await db.insert('designs_fts', {
      'id': 'id$i',
      'title': row['title'],
      'description': row['description'],
      'category': 'mehndi',
      'subcategory': 'Bridal',
      'tags': 'mehndi bridal',
      'festival': row['festival'] ?? '',
      'style': 'royal arabic',
    });
  }
  return db;
}

void main() {
  late Database db;
  late DesignRepository repo;

  setUp(() async {
    db = await _seedDb();
    repo = DesignRepositoryImpl(LocalDesignSource(db), UserDataSource(db));
  });

  tearDown(() => db.close());

  test('list newest sorts by created_at desc', () async {
    final items = await repo.list(sort: DesignSort.newest, limit: 10);
    expect(items.first.id, 'id4');
    expect(items.length, 5);
  });

  test('FTS search matches tokens with prefix', () async {
    expect((await repo.search('bri')).length, 5); // prefix match on "bridal"
    expect((await repo.search('mehndi')).length, 5);
    expect((await repo.search('zzz')).isEmpty, true);
  });

  test('category filter', () async {
    final items =
        await repo.list(filter: const DesignFilter(category: 'mehndi'));
    expect(items.length, 5);
  });

  test('festival filter', () async {
    final items =
        await repo.list(filter: const DesignFilter(festival: 'Diwali'));
    expect(items.length, 3);
  });

  test('color filter matches hex prefix', () async {
    final items = await repo.list(filter: const DesignFilter(color: '#5a'));
    expect(items.length, 5);
  });

  test('byIds preserves order', () async {
    final items = await repo.byIds(['id3', 'id1']);
    expect(items.map((d) => d.id), ['id3', 'id1']);
  });

  test('related excludes self and stays in category', () async {
    final self = (await repo.byId('id0'))!;
    final related = await repo.related(self);
    expect(related.every((d) => d.id != 'id0'), true);
    expect(related.every((d) => d.category == 'mehndi'), true);
  });

  test('total count', () async {
    expect(await repo.totalCount(), 5);
  });

  test('categories carry counts', () async {
    final cats = await repo.categories();
    expect(cats.single.count, 5);
  });
}

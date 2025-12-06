@TestOn('browser')
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_cache_manager/smart_cache_manager.dart';

// This test file doesn't import dart:io, so it should compile and run on Web.
void main() {
  group('Smart Cache Web Tests', () {
    setUp(() async {
      // Force initialization.
      // Note: We don't specify config params that rely on directories.
      // On web, storage path args are ignored anyway.
      await SmartCache.initialize(
        config: SmartCacheConfig(
          useRam: false, // Should use IndexedDB
        ),
      );
      await SmartCache.instance.clear();
    });

    test('Can write and read from IndexedDB', () async {
      await SmartCache.instance.put(key: 'web_user', data: {'name': 'Web'});
      final data = await SmartCache.instance.get<Map>(key: 'web_user');

      expect(data, isNotNull);
      expect(data!['name'], 'Web');
    });

    test('Data persists in IndexedDB (Mock Simulation)', () async {
      await SmartCache.instance.put(key: 'persistent_web', data: 'saved');

      // Simulate generic reload by clearing LRU memory but keeping DB
      // We can't fully simulate page reload in a single test run easily without creating a new isolate/context,
      // but we can check if re-init reads from DB.

      // Force re-init logic (which rehydrates from DB)
      await SmartCache.initialize(config: SmartCacheConfig(useRam: false));

      final val = await SmartCache.instance.get(key: 'persistent_web');
      expect(val, 'saved');
    });
  });
}

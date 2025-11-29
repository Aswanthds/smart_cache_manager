import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:smart_cache_manager/smart_cache_manager.dart';

void main() {
  // 1. Setup the Mock File System
  // This tricks the package into using a temp folder on your PC instead of a phone.
  setUpAll(() {
    PathProviderPlatform.instance = FakePathProviderPlatform();
  });

  group('Smart Cache Manager Tests', () {
    // Run before EVERY single test to ensure a clean slate
    setUp(() async {
      await SmartCache.initialize(
        config: SmartCacheConfig(
          maxObjects: 3, // Small capacity for easy LRU testing
          defaultExpiry: const Duration(
            seconds: 2,
          ), // Short time for Expiry testing
        ),
      );
      await SmartCache.instance.clear();
    });

    test('CRUD: Can save and retrieve data', () async {
      await SmartCache.instance.put(key: 'user', data: {'name': 'Aswanth'});

      final result = await SmartCache.instance.get<Map>(key: 'user');

      expect(result, isNotNull);
      expect(result!['name'], 'Aswanth');
    });

    test('Expiry: Data should vanish after expiry time', () async {
      // 1. Save with short expiry (1 second)
      await SmartCache.instance.put(
        key: 'temp',
        data: 'data',
        expiry: const Duration(seconds: 1),
      );

      // 2. Verify it's there
      expect(await SmartCache.instance.get(key: 'temp'), 'data');

      // 3. Wait for 1.1 seconds
      await Future.delayed(const Duration(milliseconds: 1100));

      // 4. Verify it's GONE
      expect(await SmartCache.instance.get(key: 'temp'), isNull);
    });

    test('LRU Logic: Should evict the oldest unused item', () async {
      // Capacity is 3. We add 4 items.
      await SmartCache.instance.put(key: 'A', data: 1);
      await SmartCache.instance.put(key: 'B', data: 2);
      await SmartCache.instance.put(key: 'C', data: 3);

      // Cache is [C, B, A]

      await SmartCache.instance.put(key: 'D', data: 4);

      // Cache is [D, C, B]. 'A' should be evicted.

      expect(await SmartCache.instance.get(key: 'A'), isNull); // A is gone
      expect(await SmartCache.instance.get(key: 'B'), 2); // B is still there
      expect(await SmartCache.instance.get(key: 'D'), 4); // D is there
    });

    test('LRU Logic: Accessing an item saves it from eviction', () async {
      // Capacity is 3.
      await SmartCache.instance.put(key: 'A', data: 1);
      await SmartCache.instance.put(key: 'B', data: 2);
      await SmartCache.instance.put(key: 'C', data: 3);

      // Current Order: [C, B, A] (A is oldest)

      // ACTION: Access 'A'. This should make 'A' the NEWEST.
      await SmartCache.instance.get(key: 'A');

      // Current Order: [A, C, B] (B is now oldest!)

      await SmartCache.instance.put(key: 'D', data: 4);

      // 'D' forces an eviction. 'B' should die. 'A' should survive.

      expect(
        await SmartCache.instance.get(key: 'B'),
        isNull,
        reason: "B should be evicted",
      );
      expect(
        await SmartCache.instance.get(key: 'A'),
        1,
        reason: "A should survive because we accessed it",
      );
    });
  });
}

// --- MOCK CLASS ---
// This mocks the Native Platform Channel
class FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    return Directory.systemTemp.createTempSync().path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.createTempSync().path;
  }
}

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:smart_cache_manager/smart_cache_manager.dart';

// --- MOCK CLASS ---
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory testDir;

  MockPathProviderPlatform(this.testDir);

  @override
  Future<String?> getTemporaryPath() async {
    return testDir.path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return testDir.path;
  }
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    // Create a persistent temp dir for the suite
    tempDir = await Directory.systemTemp.createTemp('smart_cache_test_suite');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);
  });

  tearDownAll(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    // Clean up files before each test to ensure isolation
    if (await tempDir.exists()) {
      for (var entity in tempDir.listSync()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }

    // Default initialization
    await SmartCache.initialize(
      config: SmartCacheConfig(
        maxObjects: 5,
        defaultExpiry: const Duration(seconds: 2),
        useRam: false, // Force file storage to test persistence issues
      ),
    );
    await SmartCache.instance.clear();
  });

  group('Core Functionality (CRUD)', () {
    test('Can save and retrieve data', () async {
      await SmartCache.instance.put(key: 'user', data: {'name': 'Aswanth'});
      final result = await SmartCache.instance.get<Map>(key: 'user');

      expect(result, isNotNull);
      expect(result!['name'], 'Aswanth');
    });

    test('Can save and retrieve null values', () async {
      await SmartCache.instance.put<String>(key: 'null_val', data: null);
      final result = await SmartCache.instance.get<String>(key: 'null_val');
      expect(result, isNull);

      // Verify it actually exists as a cache entry (key should be in storage)
      // Since we can't easily check private storage, we verify no error occurs.
    });

    test('Can remove specific item', () async {
      await SmartCache.instance.put(key: 'to_remove', data: 'bye');
      expect(await SmartCache.instance.get(key: 'to_remove'), 'bye');

      await SmartCache.instance.remove(key: 'to_remove');
      expect(await SmartCache.instance.get(key: 'to_remove'), isNull);
    });

    test('Clear wipes everything', () async {
      await SmartCache.instance.put(key: '1', data: 1);
      await SmartCache.instance.put(key: '2', data: 2);

      await SmartCache.instance.clear();

      expect(await SmartCache.instance.get(key: '1'), isNull);
      expect(await SmartCache.instance.get(key: '2'), isNull);
    });
  });

  group('Robustness & Error Handling', () {
    test('Type mismatch returns null but preserves file', () async {
      // 1. Save as String
      await SmartCache.instance.put<String>(
        key: 'mismatch',
        data: 'I am a string',
      );

      // 2. Try to Get as int (Should fail safely)
      final val = await SmartCache.instance.get<int>(key: 'mismatch');
      expect(val, isNull); // Should return null, not throw

      // 3. Verify file is NOT deleted by getting correctly
      final valCorrect = await SmartCache.instance.get<String>(key: 'mismatch');
      expect(valCorrect, 'I am a string');
    });

    test('Corrupt file is automatically deleted', () async {
      // 1. Manually create a corrupt cache file
      final file = File('${tempDir.path}/corrupt_key.cache');
      await file.writeAsString(
        '{ "rubbish": true }',
      ); // Missing keys like 'expiryTime'

      // 2. Try to Get
      final val = await SmartCache.instance.get<String>(key: 'corrupt_key');
      expect(val, isNull);

      // 3. Verify file is deleted
      expect(await file.exists(), isFalse);
    });
  });

  group('Eviction Policies (LRU)', () {
    setUp(() async {
      // Re-init with small capacity
      await SmartCache.initialize(
        config: SmartCacheConfig(
          maxObjects: 3,
          defaultExpiry: const Duration(seconds: 10),
        ),
      );
      await SmartCache.instance.clear();
    });

    test('Evicts oldest added item when full', () async {
      // Add A, B, C
      await SmartCache.instance.put(key: 'A', data: 1);
      await SmartCache.instance.put(key: 'B', data: 2);
      await SmartCache.instance.put(key: 'C', data: 3);
      // Order: [C, B, A] (A oldest)

      // Add D -> Evicts A
      await SmartCache.instance.put(key: 'D', data: 4);

      expect(await SmartCache.instance.get(key: 'A'), isNull);
      expect(await SmartCache.instance.get(key: 'B'), 2);
      expect(await SmartCache.instance.get(key: 'D'), 4);
    });

    test('Accessing usage updates LRU position', () async {
      // Add A, B, C
      await SmartCache.instance.put(key: 'A', data: 1);
      await SmartCache.instance.put(key: 'B', data: 2);
      await SmartCache.instance.put(key: 'C', data: 3);
      // Order: [C, B, A]

      // Access A -> Moves to front
      await SmartCache.instance.get(key: 'A');
      // Order: [A, C, B] (B is now oldest)

      // Add D -> Evicts B
      await SmartCache.instance.put(key: 'D', data: 4);

      expect(
        await SmartCache.instance.get(key: 'B'),
        isNull,
        reason: 'B should be evicted',
      );
      expect(
        await SmartCache.instance.get(key: 'A'),
        1,
        reason: 'A should be saved',
      );
    });
  });

  group('Expiry Logic', () {
    test('Item expires after duration', () async {
      await SmartCache.instance.put(
        key: 'quick',
        data: 'run',
        expiry: const Duration(milliseconds: 500),
      );

      // Immediately check
      expect(await SmartCache.instance.get(key: 'quick'), 'run');

      // Wait
      await Future.delayed(const Duration(milliseconds: 600));

      // Check again
      expect(await SmartCache.instance.get(key: 'quick'), isNull);
    });
  });

  group('Persistence & Rehydration', () {
    test('Data persists across re-initialization', () async {
      await SmartCache.instance.put(key: 'persist', data: 'stay');

      // Re-initialize (simulates app restart)
      await SmartCache.initialize(config: SmartCacheConfig(useRam: false));

      final val = await SmartCache.instance.get(key: 'persist');
      expect(val, 'stay');
    });

    test('Expired items are cleaned up during initialization', () async {
      // 1. write file manually to simulate old state
      // We can't access private _storageEngine
      // But we can use the public put with short expiry and wait.

      await SmartCache.instance.put(
        key: 'expired_on_boot',
        data: 'gone',
        expiry: const Duration(milliseconds: 100),
      );
      await Future.delayed(const Duration(milliseconds: 300));

      // At this point file exists but is expired.
      // Re-init should detect and delete it.

      await SmartCache.initialize(config: SmartCacheConfig(useRam: false));

      // Check file existence directly
      final cacheFile = File('${tempDir.path}/expired_on_boot.cache');
      expect(
        await cacheFile.exists(),
        isFalse,
        reason: 'Init should cleanup expired files',
      );
    });
  });
}

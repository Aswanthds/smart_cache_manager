// File: lib/smart_cache_manager.dart

import 'smart_cache_manager.dart';
import 'src/smart_cache_manager_impl.dart';
export 'smart_cache_contract.dart';
export 'src/models/cache_entry.dart';

/// The main entry point for the package.
class SmartCache {
  // 1. Private static instance
  static SmartCacheManagerImpl? _instance;

  // 2. Private constructor to prevent "new SmartCache()" calls
  SmartCache._();

  // ... private members ...
  /// Access the Singleton instance of the cache manager.
  ///
  /// **Note:** If [initialize] has not been called yet, this will automatically
  /// create an instance using the **default configuration** (Disk storage, 100 items).
  ///
  /// Usage:
  /// ```dart
  /// await SmartCache.instance.put('key', 'value');
  /// ```
  static SmartCacheBase get instance {
    _instance ??= SmartCacheManagerImpl(SmartCacheConfig());
    return _instance!;
  }

  /// Initializes the cache manager with a specific configuration.
  ///
  /// This should be called **once** at the start of your application (e.g., in `main()`)
  /// before using [instance].
  ///
  /// - [config]: The custom settings for capacity, expiry, and storage location.
  ///   If null, default settings are used.
  ///
  /// Usage:
  /// ``` dart
  /// await SmartCache.initialize(
  ///   config: SmartCacheConfig(
  ///     maxObjects: 50,
  ///     useRam: true,
  ///   ),
  /// );
  /// ```
  static Future<void> initialize({SmartCacheConfig? config}) async {
    _instance = SmartCacheManagerImpl(config ?? SmartCacheConfig());
    await _instance!.init();
  }
}

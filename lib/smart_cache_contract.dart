/// Defines the logic used to decide which item to remove
/// when the cache reaches its [SmartCacheConfig.maxObjects] limit.
enum EvictionStrategy {
  /// **Least Recently Used**:
  /// Removes the item that hasn't been accessed (read or written)
  /// for the longest time. This is the default and recommended strategy.
  lru,

  /// **First In, First Out**:
  /// Removes the oldest item based strictly on when it was created.
  /// Accessing an item does NOT save it from eviction.
  fifo,
}

class SmartCacheConfig {
  /// The maximum number of items allowed in the cache.
  ///
  /// Once this limit is reached, the [strategy] (e.g., LRU) is triggered
  /// to remove the oldest item before adding a new one.
  final int maxObjects;

  /// The default duration for which an item remains valid.
  ///
  /// This value is used if no specific `expiry` is provided when calling [put].
  /// After this duration, the item is considered stale and will be removed
  /// upon next access.
  final Duration defaultExpiry;

  /// The eviction policy to use when [maxObjects] is reached.
  ///
  /// Defaults to [EvictionStrategy.lru] (Least Recently Used).
  final EvictionStrategy strategy;

  /// Determines where the file cache is stored on the device.
  ///
  /// - `true`: Uses the **Application Documents Directory**. Data persists
  ///   until the user uninstalls the app or clears data manually.
  /// - `false` (default): Uses the **Temporary Directory**. The OS may delete
  ///   these files at any time to free up space.
  ///
  /// *Ignored if [useRam] is set to true.*
  final bool isPersistent;

  /// Determines the storage engine used.
  ///
  /// - `true`: Uses **RAM (Memory)**. Operations are ultra-fast, but data
  ///   is **lost immediately** when the app is closed or restarted.
  /// - `false` (default): Uses **File Storage**. Data persists across app restarts.
  final bool useRam;

  SmartCacheConfig({
    this.maxObjects = 100,
    this.defaultExpiry = const Duration(hours: 1),
    this.strategy = EvictionStrategy.lru,
    this.isPersistent = false,
    this.useRam = false,
  });
}

// --- Public API Contract ---
abstract class SmartCacheBase {
  // 1. Initialization (must be called before use)
  Future<void> init();

  /// Saves data to the cache and persists it to the disk.
  ///
  /// If the cache is full, this will trigger the [EvictionStrategy] to
  /// remove an old item.
  ///
  /// - [key]: A unique string to identify the data.
  /// - [data]: The dynamic data to store (must be JSON encodable).
  /// - [expiry]: Optional. How long this specific item should live.
  ///   If null, uses the default from config.
  ///
  /// Example:
  /// ```dart
  /// await Cache.put('user_id', 123, expiry: Duration(minutes: 5));
  /// ```
  Future<void> put<T>({Duration? expiry, required String key, T? data});

  /// Retrieves a value from the cache by its [key].
  ///
  /// This method performs several checks:
  /// 1. **Existence**: Checks if the file exists on the storage engine.
  /// 2. **Corruption**: If the file is corrupt (invalid JSON), it deletes the file and returns `null`.
  /// 3. **Expiry**: If the item has passed its `expiryTime`, it deletes the file and returns `null`.
  ///
  /// **Side Effect**:
  /// If the item is valid, this triggers [EvictionManager.updateUsage],
  /// moving the item to the front of the queue (if using LRU strategy).
  Future<T?> get<T>({ required String key});

  /// Removes a specific item from the cache.
  ///
  /// This deletes the physical file from the disk and removes the entry
  /// from the internal memory tracking (LRU/FIFO list).
  Future<void> remove( {required String key});

  /// Wipes the entire cache.
  ///
  /// 1. Deletes all cache files from the directory.
  /// 2. Resets the internal memory counters and pointers.
  Future<void> clear();
}

import 'dart:async';
import 'dart:convert';
import 'package:idb_shim/idb_browser.dart';
import 'package:smart_cache_manager/src/engine/storage_scope.dart';

// Constants for the database structure
const String _dbName = 'SmartCacheDB';
const String _storeName = 'cache_entries';

class IndexedDBStorageEngine implements StorageEngine {
  late IdbFactory idbFactory;
  late Database _db;

  // --- Initialization ---

  @override
  Future<void> init(bool isPersistent) async {
    // 1. Get the factory instance (idb_shim handles browser detection)
    idbFactory = getIdbFactory()!;

    // 2. Open the database
    // We only create the object store once via onVersionChange.
    _db = await idbFactory.open(
      _dbName,
      version: 1,
      onUpgradeNeeded: (event) {
        if (event.oldVersion < 1) {
          // Create the object store where all key-value pairs live.
          // The keyPath is not strictly needed since we use the cache key as the record key.
          _db = event.database;
          _db.createObjectStore(_storeName);
        }
      },
    );
  }

  // --- Write ---

  @override
  Future<bool> write({
    required String key,
    required Map<String, dynamic> data,
  }) async {
    // Start a transaction (read-write mode)
    final transaction = _db.transaction(_storeName, idbModeReadWrite);
    final store = transaction.objectStore(_storeName);

    // Convert Map to JSON string for efficient storage
    await store.put(jsonEncode(data), key);

    // Wait for the transaction to complete
    await transaction.completed;
    return true;
  }

  // --- Read ---

  @override
  Future<Map<String, dynamic>?> read({required String key}) async {
    final transaction = _db.transaction(_storeName, idbModeReadOnly);
    final store = transaction.objectStore(_storeName);

    // Get the data by key
    final result = await store.getObject(key);

    await transaction.completed;

    if (result == null) return null;

    // Decode the JSON string back to Map
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  // --- Delete ---

  @override
  Future<void> delete({required String key}) async {
    final transaction = _db.transaction(_storeName, idbModeReadWrite);
    final store = transaction.objectStore(_storeName);

    await store.delete(key);
    await transaction.completed;
  }

  // --- Read All Keys (For Rehydration/LRU Logic) ---

  @override
  Future<List<String>> getAllKeys() async {
    final transaction = _db.transaction(_storeName, idbModeReadOnly);
    final store = transaction.objectStore(_storeName);

    // IndexedDB retrieves keys efficiently
    final keys = await store.getAllKeys();

    await transaction.completed;

    // IndexedDB keys are typically strings, but ensure proper mapping
    return keys.map((key) => key.toString()).toList();
  }

  // --- Clear All ---

  @override
  Future<void> clearAll() async {
    final transaction = _db.transaction(_storeName, idbModeReadWrite);
    final store = transaction.objectStore(_storeName);

    await store.clear();
    await transaction.completed;
  }
}

StorageEngine getPersistentEngine() => IndexedDBStorageEngine();

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smart_cache_manager/smart_cache_manager.dart';
import 'package:smart_cache_manager/src/engine/storage_scope.dart';
import 'package:smart_cache_manager/src/engine/stub_storage.dart'
    if (dart.library.io) 'package:smart_cache_manager/src/engine/file_storage.dart'
    if (dart.library.html) 'package:smart_cache_manager/src/engine/indexed_db_storage.dart';

import 'algorithms/eviction_policy.dart';
import 'engine/memory_storage.dart'; // Your LRU Manager

class SmartCacheManagerImpl implements SmartCacheBase {
  final SmartCacheConfig config;
  final LRUEvictionManager _evictionManager;
  late final StorageEngine _storageEngine;

  SmartCacheManagerImpl(this.config)
    : _evictionManager = LRUEvictionManager(
        capacity: config.maxObjects,
        strategy: config.strategy,
      ) {
    if (config.useRam) {
      _storageEngine = MemoryStorageEngine();
    } else {
      // Uses the conditional import to get FileStorage (Mobile) or IndexedDB (Web) automatically
      _storageEngine = getPersistentEngine();
    }
  }

  @override
  Future<void> init() async {
    await _storageEngine.init(config.isPersistent);

    // --- REHYDRATION LOGIC ---

    // 1. Get all file keys from disk
    final keys = await _storageEngine.getAllKeys();

    if (keys.isEmpty) return;

    List<CacheEntry> validEntries = [];

    // 2. Read each file to get its metadata (Expiry & Access Time)
    for (final key in keys) {
      final data = await _storageEngine.read(key: key);
      if (data != null) {
        try {
          final entry = CacheEntry.fromJson(data);

          // Filter out expired items immediately (Clean up while we are here!)
          if (entry.expiryTime.isBefore(DateTime.now())) {
            await _storageEngine.delete(key: key);
          } else {
            validEntries.add(entry);
          }
        } catch (e) {
          // Corrupt file? Delete it.
          await _storageEngine.delete(key: key);
        }
      }
    }

    // 3. Sort by Access Time (Oldest -> Newest)
    // We do this so when we 'put' them into the manager, the newest ones end up at the Head.
    validEntries.sort((a, b) => a.accessTime.compareTo(b.accessTime));

    // 4. Feed them into the LRU Manager
    for (final entry in validEntries) {
      // We use 'put' to rebuild the Linked List in memory
      _evictionManager.put(entry);
    }

    // Now RAM and Disk are perfectly synced!
  }

  @override
  Future<void> put<T>({Duration? expiry, required String key, T? data}) async {
    // a. Create a new entry model
    final newEntry = CacheEntry(
      key: key,
      data: data,
      expiryTime: DateTime.now().add(expiry ?? config.defaultExpiry),
    );

    // b. Write data to disk (File I/O)
    // NOTE: Requires converting the CacheEntry to a Map<String, dynamic> first!
    await _storageEngine.write(key: key, data: newEntry.toJson());

    // c. Update LRU list and check capacity (Memory Logic)
    _evictionManager.put(newEntry);

    for (final evictedKey in _evictionManager.evictIfNeeded()) {
      await _storageEngine.delete(key: evictedKey);
      // print("Sync: Deleted evicted file for $evictedKey");
    }
  }

  // 3. The GET method: reads, validates, and updates LRU
  @override
  Future<T?> get<T>({required String key}) async {
    final dataMap = await _storageEngine.read(key: key);
    if (dataMap == null) return null;

    try {
      // Try to parse the data
      final entry = CacheEntry.fromJson(dataMap);

      // ... check expiry logic ...
      if (entry.expiryTime.isBefore(DateTime.now())) {
        await remove(key: key);
        return null;
      }

      _evictionManager.updateUsage(entry);

      // Attempt to cast safely.
      // If T is nullable, valid nulls pass.
      // If T is non-nullable, nulls passed as T? might need checking?
      // Actually 'as T?' is the safe cast for return type T?.
      return entry.data as T?;
    } on FormatException catch (e) {
      // 🛡️ CORRUPTION DETECTED!
      // Only invalid JSON or missing fields trigger deletion.
      debugPrint(
        "SmartCache: Found corrupt file for key '$key'. Deleting it. Error: $e",
      );
      await remove(key: key);
      return null;
    } catch (e) {
      // Handle other errors (like TypeErrors) without deleting the file
      debugPrint("SmartCache: Error reading key '$key': $e");
      return null;
    }
  }

  @override
  Future<void> remove({required String key}) async {
    await _storageEngine.delete(key: key);

    _evictionManager.remove(key);
  }

  @override
  Future<void> clear() async {
    await _storageEngine.clearAll();

    _evictionManager.clear();
  }
}

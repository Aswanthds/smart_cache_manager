import 'package:smart_cache_manager/smart_cache_manager.dart';

class LRUEvictionManager {
  // 1. Map for fast lookup (Key -> Entry)
  final Map<String, CacheEntry> _cacheMap = {};

  // 2. Capacity constraint
  final int capacity;
  final EvictionStrategy strategy;
  // 3. Pointers for the Doubly Linked List
  CacheEntry? _head; // MRU (Most Recently Used)
  CacheEntry? _tail; // LRU (Least Recently Used)

  LRUEvictionManager({required this.capacity, required this.strategy});

  // --- PUBLIC API (Called by SmartCacheManagerImpl) ---

  /// Adds a new item. If it exists, updates it.
  /// Marks the new item as MRU (Most Recently Used).
  void put(CacheEntry entry) {
    if (_cacheMap.containsKey(entry.key)) {
      // If it exists, detach the old node first so we can re-add the new one
      _removeNode(_cacheMap[entry.key]!);
    }

    _cacheMap[entry.key] = entry;
    _addHead(entry); // Add to front (MRU)
  }

  /// Updates an existing item's position to MRU (Cache Hit).
  void updateUsage(CacheEntry entry) {
    if (strategy == EvictionStrategy.fifo) {
      // FIFO Logic: Do NOTHING.
      // We don't care if it was accessed. We only care when it was created.
      return;
    }
    // We strictly use the instance from our map to ensure pointer integrity
    if (_cacheMap.containsKey(entry.key)) {
      final existingEntry = _cacheMap[entry.key]!;
      _moveToHead(existingEntry);
    }
  }

  /// Removes an item explicitly.
  void remove(String key) {
    if (_cacheMap.containsKey(key)) {
      final entry = _cacheMap[key]!;
      _removeNode(entry);
      _cacheMap.remove(key);
    }
  }

  /// Clears all internal state.
  void clear() {
    _cacheMap.clear();
    _head = null;
    _tail = null;
  }

  /// Checks capacity and evicts the LRU (Tail) if necessary.
  /// Checks capacity and evicts the LRU (Tail) if necessary.
  /// Returns a list of keys that were removed so the StorageEngine can delete them.
  List<String> evictIfNeeded() {
    List<String> evictedKeys = [];

    // While loop handles rare cases where we might be over capacity by >1
    while (_cacheMap.length > capacity && _tail != null) {
      final victim = _tail!;

      // Remove the LRU item
      _removeNode(victim);
      _cacheMap.remove(victim.key);

      // Add to our list of victims
      evictedKeys.add(victim.key);
    }

    return evictedKeys;
  }

  // --- INTERNAL LINKED LIST HELPERS (The O(1) Logic) ---

  void _moveToHead(CacheEntry entry) {
    if (entry == _head) return; // Already at front

    _removeNode(entry); // Detach
    _addHead(entry); // Re-attach at front
  }

  void _addHead(CacheEntry entry) {
    entry.next = _head;
    entry.prev = null;

    if (_head != null) {
      _head!.prev = entry;
    }
    _head = entry;

    // If list was empty, head is also tail
    _tail ??= _head;
  }

  void _removeNode(CacheEntry entry) {
    // 1. Update the previous node's "next" pointer
    if (entry.prev != null) {
      entry.prev!.next = entry.next;
    } else {
      // If no prev, this node was the Head
      _head = entry.next;
    }

    // 2. Update the next node's "prev" pointer
    if (entry.next != null) {
      entry.next!.prev = entry.prev;
    } else {
      // If no next, this node was the Tail
      _tail = entry.prev;
    }

    // 3. Nullify pointers to prevent memory leaks
    entry.next = null;
    entry.prev = null;
  }
}

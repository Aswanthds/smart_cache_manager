import 'package:smart_cache_manager/src/engine/storage_scope.dart';

class MemoryStorageEngine implements StorageEngine {
  // The "Database" is just a variable in RAM
  final Map<String, Map<String, dynamic>> _memory = {};

  @override
  Future<void> init(bool isPersistent) async {
    // RAM needs no setup!
  }

  @override
  Future<Map<String, dynamic>?> read({required String key}) async {
    return _memory[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _memory.remove(key);
  }

  @override
  Future<void> clearAll() async {
    _memory.clear();
  }

  @override
  Future<List<String>> getAllKeys() async {
    return _memory.keys.toList();
  }

  @override
  Future<void> write({
    required String key,
    required Map<String, dynamic> data,
  }) async {
    _memory[key] = data;
  }
}

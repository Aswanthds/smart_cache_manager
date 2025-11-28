class MemoryStorageEngine {
  // The "Database" is just a variable in RAM
  final Map<String, Map<String, dynamic>> _memory = {};

  Future<void> init() async {
    // RAM needs no setup!
  }

  Future<void> write(String key, Map<String, dynamic> data) async {
    _memory[key] = data;
  }

  Future<Map<String, dynamic>?> read(String key) async {
    return _memory[key];
  }

  Future<void> delete(String key) async {
    _memory.remove(key);
  }

  Future<void> clearAll() async {
    _memory.clear();
  }
}

abstract class StorageEngine {
  Future<void> init(bool isPersistent);
  Future<void> write({required String key, required Map<String, dynamic> data});
  Future<Map<String, dynamic>?> read({required String key});
  Future<void> delete({required String key});
  Future<List<String>> getAllKeys();
  Future<void> clearAll();
}

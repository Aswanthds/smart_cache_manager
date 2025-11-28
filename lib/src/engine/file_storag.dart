import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class FileStorageEngine {
  // This holds the path to your cache directory
  late final Directory _cacheDir;

  // Initialize the engine by finding the correct OS path
  Future<void> init(bool isPersistent) async {
    if (isPersistent) {
      _cacheDir = await getApplicationDocumentsDirectory();
    } else {
      _cacheDir = await getTemporaryDirectory();
    }
  }

  // Get a list of all keys currently stored on disk
  Future<List<String>> getAllKeys() async {
    if (!await _cacheDir.exists()) return [];

    final List<String> keys = [];
    await for (final entity in _cacheDir.list()) {
      if (entity is File && entity.path.endsWith('.cache')) {
        // Extract "my_key" from "/path/to/my_key.cache"
        final filename = entity.uri.pathSegments.last;
        final key = filename.replaceAll('.cache', '');
        keys.add(key);
      }
    }
    return keys;
  }

  // Brief: Writes data to a file. Requires JSON encoding.
  Future<void> write(String key, Map<String, dynamic> data) async {
    final file = File('${_cacheDir.path}/$key.cache');
    final jsonString = jsonEncode(data);
    await file.writeAsString(jsonString);
  }

  // Brief: Reads data from a file. Returns null if not found.
  Future<Map<String, dynamic>?> read(String key) async {
    try {
      final file = File('${_cacheDir.path}/$key.cache');
      final contents = await file.readAsString();
      return jsonDecode(contents) as Map<String, dynamic>;
    } catch (e) {
      // Handles FileSystemException (file not found)
      return null;
    }
  }

  // Brief: Deletes a specific file.
  Future<void> delete(String key) async {
    final file = File('${_cacheDir.path}/$key.cache');
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> clearAll() async {
    // Check if directory exists first
    if (await _cacheDir.exists()) {
      // Iterate through all files in the directory
      await for (final entity in _cacheDir.list()) {
        // Only delete files that end with .cache (safety check)
        if (entity is File && entity.path.endsWith('.cache')) {
          await entity.delete();
        }
      }
    }
  }
}


# Smart Cache Manager 🚀

[![Pub Version](https://img.shields.io/pub/v/smart_cache_manager)](https://pub.dev/packages/smart_cache_manager)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A robust, high-performance Flutter caching library that automatically manages storage using **LRU (Least Recently Used)** logic.

It persists data to the disk (so it survives app restarts) but automatically cleans up old or unused items to prevent storage bloat. Perfect for caching API responses, user profiles, or heavy JSON data.

## ✨ Features

* **🧠 Smart Eviction:** Automatically removes the least recently used items when capacity is reached.
* **💾 Persistent:** Saves data to the device's file system (Disk) by default.
* **🔄 Smart Rehydration:** On app startup, it reads the disk, removes expired items, and restores the LRU order perfectly.
* **🌐 Web Ready:** Uses IndexedDB automatically on the web for true persistence (no local storage limits).
* **⚡ RAM Support:** Optional in-memory storage for ultra-fast, volatile access.
* **⏰ Auto-Expiry:** Set a "Time-to-Live" (TTL) for items. Stale items are deleted automatically.
* **🛡️ Crash Proof:** Detects and safely deletes corrupted files (e.g., from a crash during write) to prevent app crashes.

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  smart_cache_manager: ^1.0.0
````

## 🚀 Usage

### 1\. Initialization

Initialize the cache **once** in your `main()` function. This runs the rehydration logic to sync memory with disk.

```dart
import 'package:smart_cache_manager/smart_cache_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize with custom configuration
  await SmartCache.initialize(
    config: SmartCacheConfig(
      maxObjects: 100, // Cache up to 100 items
      defaultExpiry: const Duration(hours: 1), // Default life of 1 hour
      isPersistent: false, // false = Temporary Dir, true = Documents Dir
    ),
  );

  runApp(const MyApp());
}
```

### 2\. Basic Operations

Use the static `SmartCache.instance` to access methods anywhere in your app.

```dart
// --- Save Data ---
// Uses Named Parameters: key and data
await SmartCache.instance.put(
  key: 'user_profile', 
  data: {
    'name': 'Aswanth', 
    'role': 'Developer'
  }
);

// You can also override the expiry for specific items
await SmartCache.instance.put(
  key: 'flash_sale', 
  data: itemsList, 
  expiry: const Duration(minutes: 5),
);

// --- Retrieve Data ---
final profile = await SmartCache.instance.get<Map>(key: 'user_profile');

if (profile != null) {
  print("User: ${profile['name']}");
} else {
  // Item does not exist, was evicted (LRU), or expired.
  // Fetch from API again.
}

// --- Remove Data ---
await SmartCache.instance.remove(key: 'user_profile');

// --- Clear All ---
await SmartCache.instance.clear();
```

## ⚙️ Configuration

Pass `SmartCacheConfig` during initialization to customize behavior:

| Property | Type | Default | Description |
|---|---|---|---|
| `maxObjects` | `int` | `100` | Maximum number of items allowed. LRU triggers when this is exceeded. |
| `defaultExpiry` | `Duration` | `1 hour` | How long an item lives if no specific expiry is given. |
| `strategy` | `EvictionStrategy` | `lru` | Choose `lru` (Least Recently Used) or `fifo` (First In First Out). |
| `isPersistent` | `bool` | `false` | `true` uses Documents directory (safe). `false` uses Temp directory (OS cleans it). |
| `useRam` | `bool` | `false` | If `true`, stores data in RAM only (lost on restart). |

## 🐛 Bugs or Requests

If you encounter any problems or have a feature request, please open an issue on GitHub.

[File an Issue](https://github.com/your_username/smart_cache_manager/issues)

## 🤝 Contributing

Contributions are welcome\!

1.  Fork the project.
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4.  Run tests (`flutter test`).
5.  Push to the branch (`git push origin feature/AmazingFeature`).
6.  Open a Pull Request.

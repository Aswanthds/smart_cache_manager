# Smart Cache Manager 🚀

A robust, high-performance Flutter caching library that automatically manages storage using **LRU (Least Recently Used)** logic.

It persists data to the disk (so it survives app restarts) but automatically cleans up old or unused items to prevent storage bloat. Perfect for caching API responses, user profiles, or heavy JSON data.

## ✨ Features

* **🧠 Smart Eviction:** Automatically removes the least recently used items when capacity is reached.
* **💾 Persistent:** Saves data to the device's file system (Disk) by default.
* **⚡ RAM Support:** Optional in-memory storage for ultra-fast, volatile access.
* **⏰ Auto-Expiry:** Set a "Time-to-Live" (TTL) for items (e.g., 5 minutes). Stale items are deleted automatically.
* **🔒 Type Safe:** Uses Generics (`<T>`) to ensure you get back the data type you saved.
* **🛡️ Crash Proof:** Handles corrupted files gracefully and re-hydrates state on app restart.

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  smart_cache_manager: ^1.0.0
```


## 🚀 Usage

### 1\. Initialization

Initialize the cache **once** in your `main()` function. This sets up the storage engine and re-hydrates the LRU tracker.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
// You can save basic types or JSON Maps
await SmartCache.instance.put('user_profile', {
  'name': 'Aswanth', 
  'role': 'Developer'
});

// You can also override the expiry for specific items
await SmartCache.instance.put(
  'flash_sale', 
  itemsList, 
  expiry: const Duration(minutes: 5),
);

// --- Retrieve Data ---
final profile = await SmartCache.instance.get<Map>('user_profile');

if (profile != null) {
  print("User: ${profile['name']}");
} else {
  // Item does not exist, was evicted (LRU), or expired.
  // Fetch from API again.
}

// --- Remove Data ---
await SmartCache.instance.remove('user_profile');

// --- Clear All ---
await SmartCache.instance.clear();
```

## ⚙️ Configuration (`SmartCacheConfig`)

| Property | Type | Default | Description |
|---|---|---|---|
| `maxObjects` | `int` | `100` | Maximum number of items allowed. LRU triggers when this is exceeded. |
| `defaultExpiry` | `Duration` | `1 hour` | How long an item lives if no specific expiry is given. |
| `strategy` | `EvictionStrategy` | `lru` | Choose `lru` (Least Recently Used) or `fifo` (First In First Out). |
| `isPersistent` | `bool` | `false` | If `true`, uses the Documents directory (safe from OS cleanup). |
| `useRam` | `bool` | `false` | If `true`, stores data in RAM only (lost on restart). |

## 🐛 Bugs or Requests

If you encounter any problems or have a feature request, please open an issue on GitHub.

[File an Issue](https://github.com/your_username/smart_cache_manager/issues)


## 🤝 Contributing

Contributions are welcome\! Please run the tests before submitting a PR:

```bash
flutter test
```

Contributions are welcome!
1. Fork the project.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

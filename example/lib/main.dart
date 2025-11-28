import 'package:flutter/material.dart';
import 'package:smart_cache_manager/smart_cache_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SmartCache.initialize(
    config: SmartCacheConfig(
      maxObjects: 2, // Tiny capacity for testing!
      defaultExpiry: const Duration(minutes: 5),
      isPersistent: false,
      strategy: EvictionStrategy.lru,
      useRam: false,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Smart Cache Demo')),
        body: const CacheTestScreen(),
      ),
    );
  }
}

class CacheTestScreen extends StatefulWidget {
  const CacheTestScreen({super.key});

  @override
  State<CacheTestScreen> createState() => _CacheTestScreenState();
}

class _CacheTestScreenState extends State<CacheTestScreen> {
  String _logs = "Logs will appear here...\n";

  void _log(String message) {
    setState(() {
      _logs += "$message\n";
    });
    print(message);
  }

  // TEST 1: Add Items
  Future<void> _addItems() async {
    final userProfile = {
      "id": "usr_8823",
      "name": "Aswanth",
      "role": "Flutter Developer",
      "is_active": true,
      "skills": ["Dart", "C++", "OS Architecture"],
      "stats": {"projects": 12, "followers": 340},
    };

    // 2. Save it (SmartCache handles the Map automatically)
    await cache.put<Map<String, dynamic>>(
      key: 'user_profile',
      data: userProfile,
    );
    _log(userProfile.toString());
    // Now Cache should be [D, C, B]. 'A' should be gone.
  }

  final cache = SmartCache.instance;

  Future<void> _readItems() async {
    _log("--- Reading Back ---");

    final cachedData = await cache.get<Map<String, dynamic>>(
      key: 'user_profile',
    );
    _log("Read user_profile: $cachedData ");

    final b = await cache.get<String>(key: 'B');
    _log("Read B: $b (Expected: Beta)");

    final d = await cache.get<String>(key: 'D');
    _log("Read D: $d (Expected: Delta)");
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _addItems,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              "1. Fill Cache (Trigger LRU)",
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _readItems,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              "2. Read & Verify",
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              await cache.clear();
              _log("--- Cache Cleared ---");
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              "Clear All",
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Console Logs:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black12,
              child: SingleChildScrollView(
                child: Text(_logs, style: const TextStyle()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

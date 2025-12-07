import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:smart_cache_manager/smart_cache_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SmartCache.initialize(
    config: SmartCacheConfig(
      maxObjects: 2, // Tiny capacity for testing!
      defaultExpiry: const Duration(minutes: 5),
      isPersistent: true,
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
      _logs += "$message}\n";
    });
    log(message);
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

    final lengthydata = {
      "request_id": "req_1A2B3C4D5E",
      "timestamp": "2025-12-06T07:38:00Z",
      "user_info": {
        "id": "usr_8823",
        "name": "Aswanth",
        "role": "Flutter Developer",
        "last_login_ms": 1733441880000,
        "is_pro_member": true,
      },
      "dashboard_stats": {
        "total_projects": 12,
        "active_tasks": 54,
        "tasks_completed_today": 8,
        "weekly_commit_avg": 24.5,
        "status": "Healthy",
      },
      "recent_projects": [
        {
          "project_id": "proj_001_cache",
          "name": "Smart Cache Manager 🚀",
          "status": "Active",
          "priority": "High",
          "due_date": "2026-01-15",
          "progress_percent": 85,
          "team_members": ["Aswanth", "John", "Sarah"],
          "metrics": {"loc": 4500, "tests_passed": 98, "bugs_reported": 1},
        },
        {
          "project_id": "proj_002_period",
          "name": "Period Tracker UI 🌸",
          "status": "Design Review",
          "priority": "Medium",
          "due_date": "2026-02-01",
          "progress_percent": 50,
          "team_members": ["Aswanth", "Lisa"],
          "metrics": {"loc": 1200, "tests_passed": 70, "bugs_reported": 0},
        },
        {
          "project_id": "proj_003_portfolio",
          "name": "Personal Portfolio Site",
          "status": "Completed",
          "priority": "Low",
          "due_date": "2025-11-20",
          "progress_percent": 100,
          "team_members": ["Aswanth"],
          "metrics": {"loc": 250, "tests_passed": 100, "bugs_reported": 0},
        },
      ],
      "pending_notifications": [
        {
          "type": "comment",
          "source": "John",
          "message": "Check PR #45 on Cache Manager.",
        },
        {
          "type": "deadline",
          "source": "System",
          "message": "Portfolio site passed due date.",
        },
      ],
      "configuration": {
        "theme": "dark",
        "language": "en_US",
        "notifications_enabled": true,
        "cache_ttl_min": 60,
      },
    };
    // 2. Save it (SmartCache handles the Map automatically)
    await cache.put<Map<String, dynamic>>(
      key: 'user_profile',
      data: userProfile,
    );
    await cache.put<Map<String, dynamic>>(
      key: 'lengthydata',
      data: lengthydata,
    );
    _log("--- Cache Filled ---");
    // Now Cache should be [D, C, B]. 'A' should be gone.
  }

  final cache = SmartCache.instance;

  Future<void> _readItems() async {
    _log("--- Reading Back ---");

    final cachedData = await cache.get<Map<String, dynamic>>(
      key: 'user_profile',
    );
    final lengthydata = await cache.get<Map<String, dynamic>>(
      key: 'lengthydata',
    );

    _log("Read user_profile: ${printPrettyJson(cachedData ?? {})} ");
    _log("Read Lengthy: ${printPrettyJson(lengthydata ?? {})} ");
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
              _logs = '';
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

String printPrettyJson(Map<String, dynamic> jsonData) {
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  String prettyJson = encoder.convert(jsonData);
  return prettyJson;
}

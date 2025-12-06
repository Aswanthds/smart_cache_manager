## 🚀 1.1.0

This release brings full web support and improves stability across all platforms.

### ✨ New Features
* **Web Compatibility:** Added full support for Flutter Web. The package now automatically uses `IndexedDB` for persistent storage on the web.
* **Conditional Imports:** Removed direct dependencies on `dart:io`, ensuring the package compiles purely on all supported platforms (Mobile, Desktop, Web).
* **Improved Type Safety:** The `get<T>()` method now handles type mismatches gracefully (returns `null` instead of crashing) and detects corrupt files for auto-cleanup.

### 🛠 Fixes
* **MissingPluginException (Web):** Fixed issues where file-based storage was attempted on the web.
* **Persistence Logic:** Fixed critical bugs in the storage engine selector to ensure data is saved to the correct location based on platform.

### 🗑️ Breaking Changes
Storage Migration Required: Data stored using version 1.0.x's custom JSON files will not be automatically migrated to the new idb_shim/IndexedDB backend in version 1.1.0. Users upgrading should expect their existing cache to be cleared upon initialization.

## 1.0.3
* Updated Readme.md with latest changes

## 1.0.2
* Fix some eviction policy issues.
* Clears test run with all tests passed.


## 1.0.1
* Fix formatting issues to improve pub points.

## 1.0.0
* 🎉 Initial Release.
* Added `SmartCache` singleton for global access.
* Implemented **LRU (Least Recently Used)** eviction strategy.
* Added **FIFO (First In First Out)** strategy support.
* Implemented robust **FileStorageEngine** with JSON persistence.
* Added automatic file corruption handling (zombie file cleanup).
* Added `initializeCache` for custom configuration on startup.
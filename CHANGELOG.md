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
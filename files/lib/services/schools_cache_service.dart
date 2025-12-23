import '../models/school_models.dart';

class SchoolsCacheService {
  static List<School>? _cachedSchools;
  static DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration =
      Duration(minutes: 5); // Cache for 5 minutes

  /// Get cached schools if available and not expired
  static List<School>? getCachedSchools() {
    if (_cachedSchools != null && _lastCacheTime != null) {
      final now = DateTime.now();
      final timeDifference = now.difference(_lastCacheTime!);

      if (timeDifference < _cacheValidDuration) {
        print(
            '🏫 [SCHOOLS CACHE] Returning cached schools (${_cachedSchools!.length} schools)');
        return _cachedSchools;
      } else {
        print('🏫 [SCHOOLS CACHE] Cache expired, clearing cached data');
        _cachedSchools = null;
        _lastCacheTime = null;
      }
    }
    return null;
  }

  /// Cache schools data
  static void cacheSchools(List<School> schools) {
    _cachedSchools = schools;
    _lastCacheTime = DateTime.now();
    print('🏫 [SCHOOLS CACHE] Cached ${schools.length} schools');
  }

  /// Clear cached data
  static void clearCache() {
    _cachedSchools = null;
    _lastCacheTime = null;
    print('🏫 [SCHOOLS CACHE] Cache cleared');
  }

  /// Check if cache is valid
  static bool isCacheValid() {
    if (_cachedSchools != null && _lastCacheTime != null) {
      final now = DateTime.now();
      final timeDifference = now.difference(_lastCacheTime!);
      return timeDifference < _cacheValidDuration;
    }
    return false;
  }

  /// Get cache info
  static Map<String, dynamic> getCacheInfo() {
    return {
      'hasData': _cachedSchools != null,
      'schoolCount': _cachedSchools?.length ?? 0,
      'lastCacheTime': _lastCacheTime?.toIso8601String(),
      'isValid': isCacheValid(),
    };
  }
}

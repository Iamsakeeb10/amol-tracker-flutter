import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  LocalStorageService._();

  static const String amalLogsBox = 'amal_logs';
  static const String prefsBox = 'prefs';
  static const String cacheBox = 'app_cache';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(amalLogsBox)) {
      await Hive.openBox<dynamic>(amalLogsBox);
    }
    if (!Hive.isBoxOpen(prefsBox)) {
      await Hive.openBox<dynamic>(prefsBox);
    }
    if (!Hive.isBoxOpen(cacheBox)) {
      await Hive.openBox<dynamic>(cacheBox);
    }
  }

  static Future<void> clearAll() async {
    if (Hive.isBoxOpen(amalLogsBox)) {
      await Hive.box<dynamic>(amalLogsBox).clear();
    }
    if (Hive.isBoxOpen(prefsBox)) {
      await Hive.box<dynamic>(prefsBox).clear();
    }
    if (Hive.isBoxOpen(cacheBox)) {
      await Hive.box<dynamic>(cacheBox).clear();
    }
  }

  static Box<dynamic> get _box {
    if (!Hive.isBoxOpen(amalLogsBox)) {
      throw StateError(
        'Hive box $amalLogsBox is not open. Call initialize() first.',
      );
    }
    return Hive.box<dynamic>(amalLogsBox);
  }

  static Box<dynamic> get _prefs {
    if (!Hive.isBoxOpen(prefsBox)) {
      throw StateError(
        'Hive box $prefsBox is not open. Call initialize() first.',
      );
    }
    return Hive.box<dynamic>(prefsBox);
  }

  static Box<dynamic> get _cache {
    if (!Hive.isBoxOpen(cacheBox)) {
      throw StateError(
        'Hive box $cacheBox is not open. Call initialize() first.',
      );
    }
    return Hive.box<dynamic>(cacheBox);
  }

  /// Persists a log or draft as JSON-like map (Hive dynamic).
  static Future<void> saveLog(String key, Map<String, dynamic> data) async {
    await _box.put(key, data);
  }

  static Map<String, dynamic>? getLog(String key) {
    final v = _box.get(key);
    if (v is Map) {
      return Map<String, dynamic>.from(v.cast<dynamic, dynamic>());
    }
    return null;
  }

  static Future<void> deleteLog(String key) async {
    await _box.delete(key);
  }

  static Future<void> setPref(String key, dynamic value) async {
    await _prefs.put(key, value);
  }

  static T getPref<T>(String key, T fallback) {
    final value = _prefs.get(key);
    if (value is T) return value;
    return fallback;
  }

  static Future<void> saveCache(String key, String value) async {
    await _cache.put(key, value);
  }

  static String? getCache(String key) {
    final value = _cache.get(key);
    return value is String ? value : null;
  }

  static const String _amalFieldsCacheKey = 'amal_fields_data';

  static Future<void> saveAmalFieldsCache(
    List<Map<String, dynamic>> fields,
  ) async {
    await _cache.put(_amalFieldsCacheKey, fields);
  }

  static List<Map<String, dynamic>>? getAmalFieldsCache() {
    final value = _cache.get(_amalFieldsCacheKey);
    if (value is! List) return null;
    try {
      return value
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return null;
    }
  }
}

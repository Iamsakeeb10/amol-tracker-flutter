import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  LocalStorageService._();

  static const String amalLogsBox = 'amal_logs';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(amalLogsBox)) {
      await Hive.openBox<dynamic>(amalLogsBox);
    }
  }

  static Future<void> clearAll() async {
    if (Hive.isBoxOpen(amalLogsBox)) {
      await Hive.box<dynamic>(amalLogsBox).clear();
    }
  }

  static Box<dynamic> get _box {
    if (!Hive.isBoxOpen(amalLogsBox)) {
      throw StateError('Hive box $amalLogsBox is not open. Call initialize() first.');
    }
    return Hive.box<dynamic>(amalLogsBox);
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
}

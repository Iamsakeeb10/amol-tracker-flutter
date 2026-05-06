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
}

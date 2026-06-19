import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/quran_database_service.dart';

final quranDatabaseProvider = FutureProvider<QuranDatabaseService>((ref) async {
  ref.keepAlive();
  final service = await QuranDatabaseService.open();
  ref.onDispose(service.close);
  return service;
});

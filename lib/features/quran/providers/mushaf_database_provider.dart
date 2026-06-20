import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/mushaf_database_service.dart';

final mushafDatabaseProvider = FutureProvider<MushafDatabaseService>((ref) async {
  ref.keepAlive();
  final service = await MushafDatabaseService.open();
  ref.onDispose(service.close);
  return service;
});

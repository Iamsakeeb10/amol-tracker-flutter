import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/local_storage_service.dart';
import 'auth_provider.dart';

final showBattleTeaserProvider = FutureProvider.autoDispose.family<bool, String>((ref, uid) async {
  final hasSeenLocal = LocalStorageService.getHasSeenBattleTeaser();
  if (hasSeenLocal) return false;

  final hasRespondedRemote = await ref.read(firestoreServiceProvider).hasRespondedToBattleTeaser(uid);
  if (hasRespondedRemote) {
    await LocalStorageService.saveHasSeenBattleTeaser(true);
    return false;
  }
  return true;
});

final battleInterestMetricsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  return ref.read(firestoreServiceProvider).getBattleInterestMetrics();
});

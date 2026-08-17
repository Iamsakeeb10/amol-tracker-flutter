import 'package:cloud_firestore/cloud_firestore.dart';
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

final dailyBattleUsersProvider = FutureProvider.autoDispose<int>((ref) async {
  final now = DateTime.now();
  final todayString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  
  final aggregateQuery = await FirebaseFirestore.instance
      .collection('users')
      .where('lastBattleDate', isEqualTo: todayString)
      .count()
      .get();
      
  return aggregateQuery.count ?? 0;
});

final dailyTotalBattlesProvider = FutureProvider.autoDispose<int>((ref) async {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  
  final aggregateQuery = await FirebaseFirestore.instance
      .collection('battles')
      .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
      .count()
      .get();
      
  return aggregateQuery.count ?? 0;
});

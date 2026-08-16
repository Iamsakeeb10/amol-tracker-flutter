import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/battle_model.dart';
import '../../../../providers/auth_provider.dart';
import '../models/battle_result_model.dart';
import '../models/battle_history_model.dart';
import '../models/player_answer_model.dart';
import '../repositories/battle_repository.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/user_model.dart';

// Assuming running in emulator for local dev. Replace with actual URL in production.
// For Android emulator it usually needs 10.0.2.2 instead of localhost, 
// but we'll use a configurable string or localhost by default.
final battleBaseUrlProvider = Provider<String>((ref) {
  // Use dart-define for environment variable support
  // e.g. flutter build apk --release --dart-define=BATTLE_API_URL=http://127.0.0.1:8788
  return const String.fromEnvironment(
    'BATTLE_API_URL',
    defaultValue: 'https://amol-battle-api.amol-dua.workers.dev',
  );
});

final battleRepositoryProvider = Provider<BattleRepository>((ref) {
  final baseUrl = ref.watch(battleBaseUrlProvider);
  return BattleRepository(
    baseUrl: baseUrl,
    auth: FirebaseAuth.instance,
  );
});

final battleStreamProvider = StreamProvider.family.autoDispose<BattleModel?, String>((ref, code) {
  return FirebaseFirestore.instance
      .collection('battles')
      .doc(code)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;
    final data = snapshot.data();
    if (data == null) return null;
    data['id'] = snapshot.id;
    return BattleModel.fromJson(data);
  });
});

final battleQuestionsProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, code) async {
  final repo = ref.watch(battleRepositoryProvider);
  return repo.getBattleQuestions(code: code);
});

final battleResultProvider = StreamProvider.family.autoDispose<BattleResultModel?, String>((ref, code) {
  return FirebaseFirestore.instance
      .collection('battleResults')
      .doc(code)
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;
    final data = snapshot.data();
    if (data == null) return null;
    data['id'] = snapshot.id;
    return BattleResultModel.fromJson(data);
  });
});

final battleHistoryProvider = StreamProvider.autoDispose<List<BattleHistoryModel>>((ref) {
  final user = ref.watch(currentUserProvider).asData?.value;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('battleHistory')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => BattleHistoryModel.fromJson(doc.data())).toList();
  });
});

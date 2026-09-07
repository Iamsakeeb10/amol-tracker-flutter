import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalStreakResult {
  const PersonalStreakResult({
    required this.amolId,
    required this.currentStreak,
    required this.bestStreak,
  });

  final String amolId;
  final int currentStreak;
  final int bestStreak;

  factory PersonalStreakResult.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return PersonalStreakResult(
      amolId: (data['amolId'] as String?) ?? doc.id,
      currentStreak: (data['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (data['bestStreak'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'amolId': amolId,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
    };
  }
}

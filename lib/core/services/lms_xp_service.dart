import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/lms_level_config.dart';

class LmsXpAwardResult {
  const LmsXpAwardResult({
    required this.previousXp,
    required this.newXp,
    required this.leveledUp,
    required this.newLevelIndex,
  });

  final int previousXp;
  final int newXp;
  final bool leveledUp;
  final int newLevelIndex;
}

class LmsXpService {
  LmsXpService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int xpLessonComplete = 10;
  static const int xpQuizPassBase = 5;
  static const int xpCourseComplete = 50;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  /*
  Purpose:
  Atomically award LMS XP and detect level-up transitions.

  Response:
  LmsXpAwardResult with previous/new XP and level-up flag.

  Business Rules:
  - Uses FieldValue.increment for concurrent-safe writes.
  - Level computed from kLmsLevelTiers thresholds.
  - amount must be positive.

  Flow:
  1. Read current lmsXp (default 0).
  2. Increment by amount via transaction or increment + read.
  3. Compare old vs new level index.

  Side Effects:
  - Updates users/{uid}.lmsXp in Firestore.

  Failure Cases:
  - Missing user doc or permission errors propagate to caller.
  */
  Future<LmsXpAwardResult> awardXp({
    required String uid,
    required int amount,
  }) async {
    if (uid.isEmpty || amount <= 0) {
      return const LmsXpAwardResult(
        previousXp: 0,
        newXp: 0,
        leveledUp: false,
        newLevelIndex: 0,
      );
    }

    final docRef = _userDoc(uid);
    return _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);
      final previousXp = (snap.data()?['lmsXp'] as num?)?.toInt() ?? 0;
      final newXp = previousXp + amount;
      transaction.set(
        docRef,
        <String, dynamic>{'lmsXp': FieldValue.increment(amount)},
        SetOptions(merge: true),
      );
      final oldLevel = lmsLevelFromXp(previousXp).tier.index;
      final newLevel = lmsLevelFromXp(newXp).tier.index;
      return LmsXpAwardResult(
        previousXp: previousXp,
        newXp: newXp,
        leveledUp: newLevel > oldLevel,
        newLevelIndex: newLevel,
      );
    });
  }

  int quizPassXpBonus(int score, int totalQuestions) {
    if (totalQuestions <= 0) return xpQuizPassBase;
    final ratio = score / totalQuestions;
    return xpQuizPassBase + (ratio * 10).round();
  }
}

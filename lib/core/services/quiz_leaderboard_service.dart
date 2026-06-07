import 'package:cloud_firestore/cloud_firestore.dart';

class QuizLeaderboardService {
  QuizLeaderboardService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /*
  Purpose:
  Build a global quiz score leaderboard from all user quiz attempts.

  Response:
  List of maps: uid, score (sum of best score per quiz), ordered desc.

  Business Rules:
  - Only passed attempts contribute to a user's best score per quiz.
  - Per quiz, keep the highest score; ties keep the existing value.
  - Users with zero passed quiz points are excluded.
  - Returns at most [limit] entries.

  Flow:
  1. collectionGroup query on quizAttempts.
  2. Group by uid → quizId → best passed score.
  3. Sum best scores per uid and sort descending.

  Side Effects:
  - One Firestore read (collection group).

  Failure Cases:
  - Firestore errors bubble to caller.
  */
  Future<List<Map<String, dynamic>>> fetchLeaderboard({int limit = 50}) async {
    final snap = await _firestore.collectionGroup('quizAttempts').get();
    final bestByUidQuiz = <String, Map<String, int>>{};

    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['passed'] != true) continue;

      final uid = doc.reference.parent.parent?.id ?? '';
      if (uid.isEmpty) continue;

      final quizId = (data['quizId'] as String?) ?? '';
      if (quizId.isEmpty) continue;

      final score = (data['score'] as num?)?.toInt() ?? 0;
      final quizScores = bestByUidQuiz.putIfAbsent(uid, () => <String, int>{});
      final existing = quizScores[quizId] ?? 0;
      if (score > existing) {
        quizScores[quizId] = score;
      }
    }

    final rows = <Map<String, dynamic>>[];
    for (final entry in bestByUidQuiz.entries) {
      final total = entry.value.values.fold<int>(0, (acc, v) => acc + v);
      if (total <= 0) continue;
      rows.add(<String, dynamic>{'uid': entry.key, 'score': total});
    }

    rows.sort(
      (a, b) => (b['score'] as int).compareTo(a['score'] as int),
    );

    if (limit > 0 && rows.length > limit) {
      return rows.sublist(0, limit);
    }
    return rows;
  }
}

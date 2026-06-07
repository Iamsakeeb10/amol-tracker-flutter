import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/islamic_date_service.dart';
import '../core/services/quiz_leaderboard_service.dart';
import 'auth_provider.dart';

final quizLeaderboardServiceProvider = Provider<QuizLeaderboardService>(
  (ref) => QuizLeaderboardService(),
);

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.isAnonymousDisplay,
    required this.score,
    this.attemptCount,
  });

  final String uid;
  final String displayName;
  final bool isAnonymousDisplay;
  final int score;
  final int? attemptCount;
}

String _safeName(String value) =>
    value.trim().isEmpty ? 'Anonymous' : value.trim();

final dailyLeaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  final today = IslamicDateService.getCurrentIslamicDateStringSafe();
  final fs = ref.read(firestoreServiceProvider);
  return fs.communityDayStream(today).asyncMap((rows) async {
    final users = await fs.usersByIds(rows.map((r) => r.uid));
    final entries = <LeaderboardEntry>[];
    for (final row in rows) {
      final user = users[row.uid];
      final showOnLeaderboard = user?.showOnLeaderboard ?? true;
      if (!showOnLeaderboard) continue;
      entries.add(
        LeaderboardEntry(
          uid: row.uid,
          displayName: _safeName(user?.name ?? row.displayName),
          isAnonymousDisplay:
              user?.isAnonymousDisplay ?? row.isAnonymousDisplay,
          score: row.score,
        ),
      );
    }
    return entries;
  });
});

final weeklyLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((
  ref,
) async {
  final fs = ref.read(firestoreServiceProvider);
  final rows = await fs.weeklyLeaderboard();
  final users = await fs.usersByIds(
    rows.map((row) => (row['uid'] as String?) ?? ''),
  );
  final entries = <LeaderboardEntry>[];
  for (final row in rows) {
    final uid = (row['uid'] as String?) ?? '';
    if (uid.isEmpty) continue;
    final user = users[uid];
    final showOnLeaderboard = user?.showOnLeaderboard ?? true;
    if (!showOnLeaderboard) continue;
    entries.add(
      LeaderboardEntry(
        uid: uid,
        displayName: _safeName(
          user?.name ?? (row['displayName'] as String? ?? ''),
        ),
        isAnonymousDisplay:
            user?.isAnonymousDisplay ??
            (row['isAnonymousDisplay'] as bool? ?? false),
        score: row['score'] as int? ?? 0,
      ),
    );
  }
  return entries;
});

final streakLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((
  ref,
) async {
  final fs = ref.read(firestoreServiceProvider);
  final rows = await fs.streakLeaderboard();
  final users = await fs.usersByIds(
    rows.map((row) => (row['uid'] as String?) ?? ''),
  );
  final entries = <LeaderboardEntry>[];
  for (final row in rows) {
    final uid = (row['uid'] as String?) ?? '';
    if (uid.isEmpty) continue;
    final user = users[uid];
    final showOnLeaderboard = user?.showOnLeaderboard ?? true;
    if (!showOnLeaderboard) continue;
    entries.add(
      LeaderboardEntry(
        uid: uid,
        displayName: _safeName(
          user?.name ?? (row['displayName'] as String? ?? ''),
        ),
        isAnonymousDisplay:
            user?.isAnonymousDisplay ??
            (row['isAnonymousDisplay'] as bool? ?? false),
        score: row['score'] as int? ?? 0,
      ),
    );
  }
  return entries;
});

final quizLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((
  ref,
) async {
  final rows =
      await ref.read(quizLeaderboardServiceProvider).fetchLeaderboard();
  final fs = ref.read(firestoreServiceProvider);
  final users = await fs.usersByIds(
    rows.map((row) => (row['uid'] as String?) ?? ''),
  );
  final entries = <LeaderboardEntry>[];
  for (final row in rows) {
    final uid = (row['uid'] as String?) ?? '';
    if (uid.isEmpty) continue;
    final user = users[uid];
    final showOnLeaderboard = user?.showOnLeaderboard ?? true;
    if (!showOnLeaderboard) continue;
    entries.add(
      LeaderboardEntry(
        uid: uid,
        displayName: _safeName(user?.name ?? ''),
        isAnonymousDisplay: user?.isAnonymousDisplay ?? false,
        score: row['score'] as int? ?? 0,
        attemptCount: row['attemptCount'] as int? ?? 0,
      ),
    );
  }
  return entries;
});

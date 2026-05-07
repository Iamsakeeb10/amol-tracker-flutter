import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/hijri_helper.dart';
import 'auth_provider.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.isAnonymousDisplay,
    required this.score,
  });

  final String uid;
  final String displayName;
  final bool isAnonymousDisplay;
  final int score;
}

String _safeName(String value) => value.trim().isEmpty ? 'Anonymous' : value.trim();

final dailyLeaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  final today = HijriHelper.todayString();
  return ref.read(firestoreServiceProvider).communityDayStream(today).map(
    (rows) => rows
        .map(
          (row) => LeaderboardEntry(
            uid: row.uid,
            displayName: _safeName(row.displayName),
            isAnonymousDisplay: row.isAnonymousDisplay,
            score: row.score,
          ),
        )
        .toList(),
  );
});

final weeklyLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((
  ref,
) async {
  final rows = await ref.read(firestoreServiceProvider).weeklyLeaderboard();
  return rows
      .map(
        (row) => LeaderboardEntry(
          uid: row['uid'] as String? ?? '',
          displayName: _safeName(row['displayName'] as String? ?? ''),
          isAnonymousDisplay: row['isAnonymousDisplay'] as bool? ?? false,
          score: row['score'] as int? ?? 0,
        ),
      )
      .where((row) => row.uid.isNotEmpty)
      .toList();
});

final streakLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((
  ref,
) async {
  final rows = await ref.read(firestoreServiceProvider).streakLeaderboard();
  return rows
      .map(
        (row) => LeaderboardEntry(
          uid: row['uid'] as String? ?? '',
          displayName: _safeName(row['displayName'] as String? ?? ''),
          isAnonymousDisplay: row['isAnonymousDisplay'] as bool? ?? false,
          score: row['score'] as int? ?? 0,
        ),
      )
      .where((row) => row.uid.isNotEmpty)
      .toList();
});

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../core/services/islamic_date_service.dart';
import '../core/services/quiz_leaderboard_service.dart';
import 'auth_provider.dart';
import 'history_provider.dart';

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

// ---------------------------------------------------------------------------
// Refresh signal — bump this to force all FutureProvider leaderboards to
// re-execute while the watching widget is on screen, so the shimmer shows.
// ---------------------------------------------------------------------------
class LeaderboardRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final leaderboardRefreshProvider =
    NotifierProvider<LeaderboardRefreshNotifier, int>(
  LeaderboardRefreshNotifier.new,
);

// ---------------------------------------------------------------------------
// Daily leaderboard — uses a real-time Firestore stream so it always live.
// ---------------------------------------------------------------------------
final dailyLeaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  final authState = ref.watch(currentUserProvider).asData?.value;
  final currentUserGender = authState?.gender;

  final today = IslamicDateService.getCurrentIslamicDateStringSafe();
  final fs = ref.read(firestoreServiceProvider);
  print('🏆 [DailyLeaderboard] Current user gender: $currentUserGender');
  return fs.communityDayStream(today, genderFilter: currentUserGender).asyncMap((rows) async {
    print('🏆 [DailyLeaderboard] Fetched ${rows.length} rows from server stream');
    final users = await fs.usersByIds(rows.map((r) => r.uid));
    final entries = <LeaderboardEntry>[];
    for (final row in rows) {
      final user = users[row.uid];
      final showOnLeaderboard = user?.showOnLeaderboard ?? true;
      if (!showOnLeaderboard) continue;
      
      // Filter by gender locally as a fallback (though the server stream also filters)
      if (currentUserGender != null && user?.gender != null && user?.gender != currentUserGender) {
        print('🏆 [DailyLeaderboard] 🚫 Filtering out user ${user?.name} (${user?.uid}) because their gender is ${user?.gender}');
        continue;
      }
      // If user gender is completely unknown, we might still want to skip them if we strictly enforce it
      if (currentUserGender != null && user?.gender == null) {
        print('🏆 [DailyLeaderboard] 🚫 Filtering out user ${user?.name} (${user?.uid}) because their gender is NULL');
        continue;
      }
      
      print('🏆 [DailyLeaderboard] ✅ Including user ${user?.name} (${user?.uid}) - gender: ${user?.gender}');

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

// ---------------------------------------------------------------------------
// Weekly leaderboard
// ---------------------------------------------------------------------------
final weeklyLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>(
  (ref) async {
  // Re-execute whenever leaderboardRefreshProvider is bumped.
  ref.watch(leaderboardRefreshProvider);

  final authState = ref.watch(currentUserProvider).asData?.value;
  final currentUserGender = authState?.gender;

  final fs = ref.read(firestoreServiceProvider);
  final rows = await fs.weeklyLeaderboard();
  final users = await fs.usersByIds(
    rows.map((row) => (row['uid'] as String?) ?? ''),
  );
  final entries = <LeaderboardEntry>[];
  for (final row in rows) {
    print('🌟 [WeeklyLeaderboard] Current user gender: $currentUserGender');
    final uid = (row['uid'] as String?) ?? '';
    if (uid.isEmpty) continue;
    final user = users[uid];
    final showOnLeaderboard = user?.showOnLeaderboard ?? true;
    if (!showOnLeaderboard) continue;

    // Filter by gender
    if (currentUserGender != null && user?.gender != null && user?.gender != currentUserGender) {
      print('🌟 [WeeklyLeaderboard] 🚫 Filtering out user ${user?.name} (${uid}) because their gender is ${user?.gender}');
      continue;
    }
    if (currentUserGender != null && user?.gender == null) {
      print('🌟 [WeeklyLeaderboard] 🚫 Filtering out user ${user?.name} (${uid}) because their gender is NULL');
      continue;
    }
    print('🌟 [WeeklyLeaderboard] ✅ Including user ${user?.name} (${uid}) - gender: ${user?.gender}');

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

// ---------------------------------------------------------------------------
// Monthly leaderboard
// ---------------------------------------------------------------------------
final monthlyLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>(
  (ref) async {
  // Re-execute whenever leaderboardRefreshProvider is bumped.
  ref.watch(leaderboardRefreshProvider);

  final authState = ref.watch(currentUserProvider).asData?.value;
  final currentUserGender = authState?.gender;

  final fs = ref.read(firestoreServiceProvider);
  final rows = await fs.monthlyLeaderboard();
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

    print('🌙 [MonthlyLeaderboard] Current user gender: $currentUserGender');
    // Filter by gender
    if (currentUserGender != null && user?.gender != null && user?.gender != currentUserGender) {
      print('🌙 [MonthlyLeaderboard] 🚫 Filtering out user ${user?.name} (${uid}) because their gender is ${user?.gender}');
      continue;
    }
    if (currentUserGender != null && user?.gender == null) {
      print('🌙 [MonthlyLeaderboard] 🚫 Filtering out user ${user?.name} (${uid}) because their gender is NULL');
      continue;
    }
    print('🌙 [MonthlyLeaderboard] ✅ Including user ${user?.name} (${uid}) - gender: ${user?.gender}');

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

// ---------------------------------------------------------------------------
// Streak leaderboard
// ---------------------------------------------------------------------------
final streakLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>(
  (ref) async {
  // Re-execute whenever leaderboardRefreshProvider is bumped.
  ref.watch(leaderboardRefreshProvider);

  final authState = ref.watch(currentUserProvider).asData?.value;
  final currentUserGender = authState?.gender;

  final fs = ref.read(firestoreServiceProvider);
  final result = await fs.streakLeaderboard(genderFilter: currentUserGender);
  final rows = result.rows;
  final users = await fs.usersByIds(
    rows.map((row) => (row['uid'] as String?) ?? ''),
  );
  // Compute the current user's live streak to override the Firestore value.
  final authUid = ref.read(authStateProvider).asData?.value?.uid;
  final liveStreak = ref.read(liveStreakProvider).value;
  final entries = <LeaderboardEntry>[];
  for (final row in rows) {
    final uid = (row['uid'] as String?) ?? '';
    if (uid.isEmpty) continue;
    final user = users[uid];
    
    // Local fallback gender filter
    if (currentUserGender != null && user?.gender != null && user?.gender != currentUserGender) {
      continue;
    }
    if (currentUserGender != null && user?.gender == null) {
      continue;
    }
    
    final showOnLeaderboard = user?.showOnLeaderboard ?? true;
    if (!showOnLeaderboard) continue;
    
    // We expect the server stream to filter correctly, but let's log the users it returns
    print('🔥 [StreakLeaderboard] ✅ Server included user ${user?.name} (${uid}) - gender: ${user?.gender}');

    if (currentUserGender != null && user?.gender == null) continue;

    // Override the current user's score with the live streak value.
    final score = (uid == authUid && liveStreak != null)
        ? liveStreak
        : (row['score'] as int? ?? 0);
    entries.add(
      LeaderboardEntry(
        uid: uid,
        displayName: _safeName(
          user?.name ?? (row['displayName'] as String? ?? ''),
        ),
        isAnonymousDisplay:
            user?.isAnonymousDisplay ??
            (row['isAnonymousDisplay'] as bool? ?? false),
        score: score,
      ),
    );
  }
  // Re-sort after override since the current user's position may have changed.
  entries.sort((a, b) => b.score.compareTo(a.score));
  return entries;
});

// ---------------------------------------------------------------------------
// Quiz leaderboard
// ---------------------------------------------------------------------------
final quizLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>(
  (ref) async {
  // Re-execute whenever leaderboardRefreshProvider is bumped.
  ref.watch(leaderboardRefreshProvider);

  final authState = ref.watch(currentUserProvider).asData?.value;
  final currentUserGender = authState?.gender;

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

    // Filter by gender
    if (currentUserGender != null && user?.gender != null && user?.gender != currentUserGender) {
      continue;
    }
    if (currentUserGender != null && user?.gender == null) {
      continue;
    }
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

// ---------------------------------------------------------------------------
// Battle leaderboard — real-time StreamProvider ranked by battleScore
// ---------------------------------------------------------------------------
final battleLeaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  final authState = ref.watch(currentUserProvider).asData?.value;
  final currentUserGender = authState?.gender;

  return FirebaseFirestore.instance
      .collection('users')
      .where('gender', isEqualTo: currentUserGender)
      .orderBy('battleScore', descending: true)
      .limit(50)
      .snapshots()
      .asyncMap((snapshot) async {
    final fs = ref.read(firestoreServiceProvider);
    final uids = snapshot.docs.map((d) => d.id);
    final users = await fs.usersByIds(uids);

    final entries = <LeaderboardEntry>[];
    for (final doc in snapshot.docs) {
      final uid = doc.id;
      final data = doc.data();
      final battleScore = (data['battleScore'] as num?)?.toInt() ?? 0;
      if (battleScore == 0) continue;

      final user = users[uid];
      final showOnLeaderboard = user?.showOnLeaderboard ?? true;
      if (!showOnLeaderboard) continue;
      if (currentUserGender != null && user?.gender != null && user?.gender != currentUserGender) continue;
      if (currentUserGender != null && user?.gender == null) continue;

      entries.add(LeaderboardEntry(
        uid: uid,
        displayName: _safeName(user?.name ?? (data['displayName'] as String? ?? '')),
        isAnonymousDisplay: user?.isAnonymousDisplay ?? false,
        score: battleScore,
        attemptCount: (data['battlePlays'] as num?)?.toInt() ?? 0,
      ));
    }
    return entries;
  });
});

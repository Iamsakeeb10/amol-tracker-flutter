import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

class BattleLeaderboardScreen extends StatelessWidget {
  final String currentUserGender;

  const BattleLeaderboardScreen({
    super.key,
    required this.currentUserGender,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Battle Leaderboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('gender', isEqualTo: currentUserGender)
            .orderBy('battleScore', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong. Pull to refresh.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _EmptyState();
          }

          // Build ranked list with a stable rank index.
          final entries = List.generate(docs.length, (i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _LeaderboardEntry(
              uid: docs[i].id,
              rank: i + 1,
              name: (data['displayName'] ?? 'Unknown') as String,
              photoUrl: data['photoUrl'] as String?,
              score: (data['battleScore'] ?? 0) as int,
              wins: (data['battleWins'] ?? 0) as int,
              plays: (data['battlePlays'] ?? 0) as int,
            );
          });

          final currentUserEntry = currentUid == null
              ? null
              : entries.where((e) => e.uid == currentUid).firstOrNull;

          return CustomScrollView(
            slivers: [
              // Pinned "You" card — only shown if the current user is on
              // this leaderboard and not already in the visible top slice.
              if (currentUserEntry != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: _LeaderboardRow(
                      entry: currentUserEntry,
                      displayName: 'You',
                      isCurrentUser: true,
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = entries[index];
                      return Column(
                        children: [
                          _LeaderboardRow(
                            entry: entry,
                            displayName: entry.name,
                            isCurrentUser: entry.uid == currentUid,
                          ),
                          if (index != entries.length - 1)
                            Divider(
                              height: 1,
                              thickness: 0.5,
                              color: AppColors.border,
                            ),
                        ],
                      );
                    },
                    childCount: entries.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          );
        },
      ),
    );
  }
}

class _LeaderboardEntry {
  final String uid;
  final int rank;
  final String name;
  final String? photoUrl;
  final int score;
  final int wins;
  final int plays;

  const _LeaderboardEntry({
    required this.uid,
    required this.rank,
    required this.name,
    required this.photoUrl,
    required this.score,
    required this.wins,
    required this.plays,
  });

  int get losses => plays - wins;
}

class _LeaderboardRow extends StatelessWidget {
  final _LeaderboardEntry entry;
  final String displayName;
  final bool isCurrentUser;

  const _LeaderboardRow({
    required this.entry,
    required this.displayName,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isCurrentUser
        ? AppColors.accentSurface
        : Colors.transparent;
    final nameColor =
        isCurrentUser ? AppColors.accent : AppColors.textPrimary;
    final subColor = isCurrentUser
        ? AppColors.accent.withOpacity(0.85)
        : AppColors.textSecondary;
    final scoreColor = isCurrentUser ? AppColors.accent : AppColors.textPrimary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Center(child: _RankIndicator(rank: entry.rank)),
          ),
          SizedBox(width: AppSpacing.sm),
          _Avatar(
            photoUrl: entry.photoUrl,
            name: displayName,
            accent: isCurrentUser,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: nameColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.wins}W · ${entry.losses}L',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
              ],
            ),
          ),
          Text(
            '${entry.score}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: scoreColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankIndicator extends StatelessWidget {
  final int rank;

  const _RankIndicator({required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank == 1) {
      return const Icon(Icons.emoji_events, color: Color(0xFFBA7517), size: 20);
    }
    return Text(
      '$rank',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final bool accent;

  const _Avatar({required this.photoUrl, required this.name, required this.accent});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const size = 38.0;

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsCircle(size),
        ),
      );
    }
    return _initialsCircle(size);
  }

  Widget _initialsCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent
            ? AppColors.accentSurface.withOpacity(0.6)
            : AppColors.accentSurface,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_outlined,
                size: 40, color: AppColors.textSecondary),
            SizedBox(height: AppSpacing.sm),
            Text(
              'No battles yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Play a Knowledge Battle to appear on the leaderboard.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
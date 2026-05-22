import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/leaderboard_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';
import '../../../../shared/widgets/streak_badge.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int _periodIndex = 0;
  bool get _isStreak => _periodIndex == 2;

  void _logDebug(String message) {
    if (kDebugMode) {
      debugPrint('[Leaderboard] $message');
    }
  }

  String _displayName(LeaderboardEntry user) => user.isAnonymousDisplay
      ? '🕌 ${AppLocalizations.of(context)!.anonymous}'
      : user.displayName;

  String _statLabel() => _isStreak
      ? AppLocalizations.of(context)!.historyDays
      : AppLocalizations.of(context)!.pointsAbbr;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final periods = [l10n.weekly, l10n.daily, l10n.streak];
    final authUid = ref.watch(authStateProvider).asData?.value?.uid;
    final data = _periodIndex == 0
        ? ref.watch(weeklyLeaderboardProvider)
        : _periodIndex == 1
        ? ref.watch(dailyLeaderboardProvider)
        : ref.watch(streakLeaderboardProvider);

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.more),
        ),
        title: Text(
          l10n.leaderboard,
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 4.h, 0, 24.h),
        children: [
          _Tabs(
            value: _periodIndex,
            options: periods,
            onChanged: (i) => setState(() => _periodIndex = i),
          ),
          SizedBox(height: 16.h),
          data.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            data: (entries) {
              if (entries.isEmpty) {
                return CardContainer(
                  child: Text(
                    l10n.leaderboardBeFirstToday,
                    style: AppTextStyles.bodyLarge(context),
                  ),
                );
              }
              final top3 = entries.take(3).toList();
              final nudge = _buildNudge(entries, authUid);
              final userIndex = authUid == null
                  ? -1
                  : entries.indexWhere((u) => u.uid == authUid);
              final pinnedUser = userIndex >= 0 ? entries[userIndex] : null;

              return Column(
                children: [
                  _Podium(top3: top3, displayName: _displayName),
                  SizedBox(height: 18.h),
                  ...entries.asMap().entries.map((e) {
                    final rank = e.key + 1;
                    final user = e.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: _RankRow(
                        rank: rank,
                        user: user,
                        statLabel: _statLabel(),
                        displayName: _displayName(user),
                        isYou: user.uid == authUid,
                        maxScore: entries.first.score,
                        onTap: () => context.push(
                          '${AppRoutes.userProfile}/${user.uid}',
                        ),
                      ),
                    );
                  }),
                  if (pinnedUser != null && userIndex >= 3) ...[
                    SizedBox(height: 8.h),
                    CardContainer.gold(
                      child: Row(
                        children: [
                          Icon(Icons.push_pin_outlined, color: AppColors.gold),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              l10n.leaderboardYourRank(
                                userIndex + 1,
                                pinnedUser.score,
                                _statLabel(),
                              ),
                              style: AppTextStyles.bodyMedium(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 16.h),
                  CardContainer.gold(
                    child: Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: AppColors.goldLight,
                          size: 20.r,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            nudge,
                            style: AppTextStyles.bodyLarge(
                              context,
                            ).copyWith(fontSize: 13.sp),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: _buildLoading,
            error: (error, _) => CardContainer(
              child: Text(
                l10n.leaderboardLoadFailed,
                style: AppTextStyles.bodyMedium(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Shimmer.fromColors(
            baseColor: AppColors.cardDark,
            highlightColor: AppColors.cardBorder,
            child: Container(
              height: 58.h,
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _buildNudge(List<LeaderboardEntry> entries, String? authUid) {
    if (authUid == null || entries.length < 2) {
      final message = AppLocalizations.of(
        context,
      )!.leaderboardNudgeKeepClimbing;
      _logDebug(
        'nudge=keep-climbing periodIndex=$_periodIndex isStreak=$_isStreak '
        'authUid=$authUid entries=${entries.length} message="$message"',
      );
      return message;
    }
    final meIndex = entries.indexWhere((u) => u.uid == authUid);
    if (meIndex <= 0) {
      final message = AppLocalizations.of(context)!.leaderboardNudgeTop;
      _logDebug(
        'nudge=top periodIndex=$_periodIndex isStreak=$_isStreak '
        'authUid=$authUid meIndex=$meIndex entries=${entries.length} '
        'message="$message"',
      );
      return message;
    }
    final meScore = entries[meIndex].score;
    final isSecondPlace = meIndex == 1;
    final targetIndex = isSecondPlace ? 0 : 1;
    final targetScore = entries[targetIndex].score;
    final behind = (targetScore - meScore).clamp(0, 99999);
    final l10n = AppLocalizations.of(context)!;
    final message = _isStreak
        ? (isSecondPlace
              ? l10n.leaderboardNudgeBehindFirstDays(behind)
              : l10n.leaderboardNudgeBehindDays(behind))
        : (isSecondPlace
              ? l10n.leaderboardNudgeBehindFirstPoints(behind)
              : l10n.leaderboardNudgeBehindPoints(behind));
    _logDebug(
      'nudge=behind periodIndex=$_periodIndex isStreak=$_isStreak '
      'authUid=$authUid meIndex=$meIndex meScore=$meScore '
      'targetIndex=$targetIndex targetScore=$targetScore behind=$behind '
      'entries=${entries.length} message="$message"',
    );
    return message;
  }
}

class _Tabs extends StatelessWidget {
  final int value;
  final List<String> options;
  final ValueChanged<int> onChanged;
  const _Tabs({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(99.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final selected = i == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: selected ? AppColors.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(99.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  options[i],
                  style: AppTextStyles.button(context).copyWith(
                    fontSize: 12.sp,
                    color: selected
                        ? AppColors.emeraldDeep
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> top3;
  final String Function(LeaderboardEntry user) displayName;
  const _Podium({required this.top3, required this.displayName});

  @override
  Widget build(BuildContext context) {
    if (top3.length < 3) return const SizedBox();
    final order = [top3[1], top3[0], top3[2]];
    final heights = [64.h, 88.h, 56.h];
    final ranks = [2, 1, 3];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340.w;
        return SizedBox(
          height: compact ? 216.h : 200.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              final user = order[i];
              final name = displayName(user);
              final initial = name.isEmpty
                  ? '?'
                  : name.substring(0, 1).toUpperCase();
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AvatarChip(
                        initial: user.isAnonymousDisplay ? '🕌' : initial,
                        color: user.isAnonymousDisplay
                            ? AppColors.cardBorder
                            : AppColors.gold,
                        size: ranks[i] == 1 ? 56 : 44,
                        ring: ranks[i] == 1,
                        fontSize: ranks[i] == 1 ? 22 : 18,
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge(
                          context,
                        ).copyWith(fontSize: 12.sp),
                      ),
                      Text(
                        '${user.score}',
                        style: AppTextStyles.goldNumeric(
                          context,
                        ).copyWith(fontSize: 16.sp),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        height: compact ? heights[i] + 8.h : heights[i],
                        decoration: BoxDecoration(
                          color: ranks[i] == 1
                              ? AppColors.gold
                              : AppColors.goldCard,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(10.r),
                          ),
                          border: Border.all(color: AppColors.goldBorder),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${ranks[i]}',
                          style: AppTextStyles.displayMedium(context).copyWith(
                            color: ranks[i] == 1
                                ? AppColors.emeraldDeep
                                : AppColors.gold,
                            fontSize: 26.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final LeaderboardEntry user;
  final String statLabel;
  final String displayName;
  final bool isYou;
  final int maxScore;
  final VoidCallback onTap;

  const _RankRow({
    required this.rank,
    required this.user,
    required this.statLabel,
    required this.displayName,
    required this.isYou,
    required this.maxScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CardContainer(
        color: isYou ? AppColors.goldCard : AppColors.cardDark,
        borderColor: isYou ? AppColors.goldBorder : AppColors.cardBorder,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          children: [
            SizedBox(
              width: 28.w,
              child: Text(
                '$rank',
                style: AppTextStyles.goldNumeric(
                  context,
                ).copyWith(fontSize: 18.sp),
              ),
            ),
            AvatarChip(
              initial: user.isAnonymousDisplay
                  ? '🕌'
                  : displayName.substring(0, 1).toUpperCase(),
              color: user.isAnonymousDisplay
                  ? AppColors.cardBorder
                  : AppColors.gold,
              size: 32,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyLarge(
                            context,
                          ).copyWith(fontSize: 13.sp),
                        ),
                      ),
                      if (isYou) ...[
                        SizedBox(width: 6.w),
                        Pill(
                          text: AppLocalizations.of(context)!.you,
                          color: AppColors.goldCard,
                          textColor: AppColors.gold,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  ScoreBar(
                    value: maxScore == 0
                        ? 0
                        : (user.score / maxScore).clamp(0.0, 1.0),
                    height: 4,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              '${user.score}',
              style: AppTextStyles.goldNumeric(
                context,
              ).copyWith(fontSize: 16.sp),
            ),
            SizedBox(width: 2.w),
            Text(
              statLabel,
              style: AppTextStyles.bodySmall(context).copyWith(fontSize: 10.sp),
            ),
          ],
        ),
      ),
    );
  }
}

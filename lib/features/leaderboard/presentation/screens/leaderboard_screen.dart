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
import '../widgets/quiz_leaderboard_stat.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int _periodIndex = 0;
  bool get _isStreak => _periodIndex == 2;
  bool get _isQuiz => _periodIndex == 3;

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
    final periods = [l10n.weekly, l10n.daily, l10n.streak, l10n.leaderboardQuizTab];
    final authUid = ref.watch(authStateProvider).asData?.value?.uid;
    final data = switch (_periodIndex) {
      0 => ref.watch(weeklyLeaderboardProvider),
      1 => ref.watch(dailyLeaderboardProvider),
      2 => ref.watch(streakLeaderboardProvider),
      _ => ref.watch(quizLeaderboardProvider),
    };

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
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(0, 4.h, 0, 0),
            sliver: SliverToBoxAdapter(
              child: _Tabs(
                value: _periodIndex,
                options: periods,
                onChanged: (i) => setState(() => _periodIndex = i),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          ...data.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            data: (entries) => _buildDataSlivers(
              context,
              entries: entries,
              authUid: authUid,
              l10n: l10n,
            ),
            loading: () => [SliverToBoxAdapter(child: _buildLoading())],
            error: (error, _) => [
              SliverToBoxAdapter(
                child: CardContainer(
                  child: Text(
                    l10n.leaderboardLoadFailed,
                    style: AppTextStyles.bodyMedium(context),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(child: SizedBox(height: 24.h)),
        ],
      ),
    );
  }

  List<Widget> _buildDataSlivers(
    BuildContext context, {
    required List<LeaderboardEntry> entries,
    required String? authUid,
    required AppLocalizations l10n,
  }) {
    if (entries.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: CardContainer(
            child: Text(
              _isQuiz
                  ? l10n.leaderboardQuizBeFirst
                  : l10n.leaderboardBeFirstToday,
              style: AppTextStyles.bodyLarge(context),
            ),
          ),
        ),
      ];
    }

    final top3 = entries.take(3).toList();
    final nudge = _buildNudge(entries, authUid);
    final userIndex =
        authUid == null ? -1 : entries.indexWhere((u) => u.uid == authUid);
    final pinnedUser = userIndex >= 0 ? entries[userIndex] : null;
    final maxScore = entries.first.score;
    final statLabel = _statLabel();

    return [
      if (_isQuiz)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Text(
              l10n.leaderboardQuizTiebreakerHint,
              style: AppTextStyles.bodySmall(context).copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      SliverToBoxAdapter(
        child: _Podium(
          top3: top3,
          displayName: _displayName,
          isQuiz: _isQuiz,
        ),
      ),
      SliverToBoxAdapter(child: SizedBox(height: 18.h)),
      SliverPadding(
        padding: EdgeInsets.zero,
        sliver: SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final user = entries[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _RankRow(
                rank: index + 1,
                user: user,
                statLabel: statLabel,
                displayName: _displayName(user),
                isYou: user.uid == authUid,
                maxScore: maxScore,
                isQuiz: _isQuiz,
                onTap: () =>
                    context.push('${AppRoutes.userProfile}/${user.uid}'),
              ),
            );
          },
        ),
      ),
      if (pinnedUser != null && userIndex >= 3) ...[
        SliverToBoxAdapter(child: SizedBox(height: 8.h)),
        SliverToBoxAdapter(
          child: CardContainer.gold(
            child: Row(
              children: [
                Icon(Icons.push_pin_outlined, color: AppColors.gold),
                SizedBox(width: 8.w),
                Expanded(
                  child: _isQuiz
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.leaderboardYourRankNumber(userIndex + 1),
                              style: AppTextStyles.bodyMedium(context),
                            ),
                            SizedBox(height: 6.h),
                            QuizLeaderboardStat(
                              points: pinnedUser.score,
                              attempts: pinnedUser.attemptCount ?? 0,
                            ),
                          ],
                        )
                      : Text(
                          l10n.leaderboardYourRank(
                            userIndex + 1,
                            pinnedUser.score,
                            statLabel,
                          ),
                          style: AppTextStyles.bodyMedium(context),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
      SliverToBoxAdapter(child: SizedBox(height: 16.h)),
      SliverToBoxAdapter(
        child: CardContainer.gold(
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
      ),
    ];
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
        : _isQuiz
        ? (isSecondPlace
              ? l10n.leaderboardNudgeBehindFirstQuizPoints(behind)
              : l10n.leaderboardNudgeBehindQuizPoints(behind))
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
                    fontSize: options.length > 3 ? 11.sp : 12.sp,
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
  final bool isQuiz;
  const _Podium({
    required this.top3,
    required this.displayName,
    this.isQuiz = false,
  });

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
                      if (isQuiz)
                        QuizLeaderboardStat(
                          points: user.score,
                          attempts: user.attemptCount ?? 0,
                          compact: true,
                        )
                      else
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
  final bool isQuiz;
  final VoidCallback onTap;

  const _RankRow({
    required this.rank,
    required this.user,
    required this.statLabel,
    required this.displayName,
    required this.isYou,
    required this.maxScore,
    this.isQuiz = false,
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
            if (isQuiz)
              QuizLeaderboardStat(
                points: user.score,
                attempts: user.attemptCount ?? 0,
              )
            else ...[
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
          ],
        ),
      ),
    );
  }
}

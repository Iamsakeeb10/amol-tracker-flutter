import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/analytics_service.dart';
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
  const LeaderboardScreen({super.key, this.initialTabIndex});
  final int? initialTabIndex;

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  late int _periodIndex;
  bool _initialLoadComplete = false;
  Timer? _loadTimeout;
  bool get _isStreak => _periodIndex == 3;
  bool get _isQuiz => _periodIndex == 4;

  // Pagination state
  static const int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();
  int _displayedCount = 20;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logLeaderboardOpened();
    _periodIndex = widget.initialTabIndex ?? 0;
    _startLoadTimeout();
    _scrollController.addListener(_onScroll);
    // Invalidate all leaderboard providers to fetch fresh data on screen open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(weeklyLeaderboardProvider);
      ref.invalidate(monthlyLeaderboardProvider);
      ref.invalidate(dailyLeaderboardProvider);
      ref.invalidate(streakLeaderboardProvider);
      ref.invalidate(quizLeaderboardProvider);
    });
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _startLoadTimeout() {
    _loadTimeout?.cancel();
    _loadTimeout = Timer(const Duration(seconds: 3), () {
      if (mounted && !_initialLoadComplete) {
        setState(() => _initialLoadComplete = true);
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore) return;
    final max = _scrollController.position.maxScrollExtent;
    final cur = _scrollController.offset;
    if (max - cur < 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    final data = switch (_periodIndex) {
      0 => ref.read(weeklyLeaderboardProvider),
      1 => ref.read(monthlyLeaderboardProvider),
      2 => ref.read(dailyLeaderboardProvider),
      3 => ref.read(streakLeaderboardProvider),
      _ => ref.read(quizLeaderboardProvider),
    };
    data.whenData((entries) {
      if (_displayedCount >= entries.length) return;
      setState(() {
        _isLoadingMore = true;
        _displayedCount += _pageSize;
      });
      // Simulate a brief delay so the loading indicator is visible.
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _isLoadingMore = false);
      });
    });
  }

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
    final periods = [
      l10n.weekly,
      l10n.monthly,
      l10n.daily,
      l10n.streak,
      l10n.leaderboardQuizTab,
    ];
    final authUid = ref.watch(authStateProvider).asData?.value?.uid;
    final data = switch (_periodIndex) {
      0 => ref.watch(weeklyLeaderboardProvider),
      1 => ref.watch(monthlyLeaderboardProvider),
      2 => ref.watch(dailyLeaderboardProvider),
      3 => ref.watch(streakLeaderboardProvider),
      _ => ref.watch(quizLeaderboardProvider),
    };

    // Determine pinned user for the fixed bottom card.
    LeaderboardEntry? pinnedEntry;
    int pinnedRank = -1;
    data.whenData((entries) {
      if (authUid == null || entries.isEmpty) return;
      final idx = entries.indexWhere((u) => u.uid == authUid);
      if (idx >= 5) {
        pinnedEntry = entries[idx];
        pinnedRank = idx + 1;
      }
    });

    return AppScaffold(
      padding: EdgeInsets.zero,
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
      body: Column(
        children: [
          // Tabs pinned at top — never scroll.
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
            child: _Tabs(
              value: _periodIndex,
              options: periods,
              onChanged: (i) => setState(() {
                _periodIndex = i;
                _initialLoadComplete = false;
                _displayedCount = _pageSize;
                _isLoadingMore = false;
                _startLoadTimeout();
              }),
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    ...data.when(
                      skipLoadingOnRefresh: false,
                      skipLoadingOnReload: false,
                      data: (entries) {
                        if (!_initialLoadComplete) {
                          if (entries.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() => _initialLoadComplete = true);
                              }
                            });
                          } else {
                            return [SliverToBoxAdapter(child: _buildLoading())];
                          }
                        }
                        return _buildDataSlivers(
                          context,
                          entries: entries,
                          authUid: authUid,
                          l10n: l10n,
                        );
                      },
                      loading: () => [
                        SliverToBoxAdapter(child: _buildLoading()),
                      ],
                      error: (error, _) {
                        if (!_initialLoadComplete) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => _initialLoadComplete = true);
                            }
                          });
                        }
                        return [
                          SliverToBoxAdapter(
                            child: CardContainer(
                              child: Text(
                                l10n.leaderboardLoadFailed,
                                style: AppTextStyles.bodyMedium(context),
                              ),
                            ),
                          ),
                        ];
                      },
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                  ],
                ),
                // Bottom fade scroll affordance.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 40.h,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.emeraldDeep.withValues(alpha: 0),
                            AppColors.emeraldDeep,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Fixed bottom card for user ranked outside top 5.
          if (pinnedEntry != null)
            _PinnedBottomCard(
              entry: pinnedEntry!,
              rank: pinnedRank,
              isQuiz: _isQuiz,
              statLabel: _statLabel(),
              displayName: _displayName(pinnedEntry!),
            ),
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
    final userIndex = authUid == null
        ? -1
        : entries.indexWhere((u) => u.uid == authUid);
    final shouldPin = userIndex >= 5;
    final maxScore = entries.first.score;
    final statLabel = _statLabel();

    // Build the visible entries for the normal list.
    // When pinned (rank > 5), exclude the current user from the list.
    final visibleEntries = shouldPin
        ? [for (int i = 0; i < entries.length; i++) if (i != userIndex) entries[i]]
        : entries;

    // Apply pagination: only show up to _displayedCount entries.
    final displayedEntries = visibleEntries
        .take(_displayedCount.clamp(0, visibleEntries.length))
        .toList();
    final hasMore = displayedEntries.length < visibleEntries.length;

    return [
      if (_isQuiz)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
          sliver: SliverToBoxAdapter(
            child: Text(
              l10n.leaderboardQuizTiebreakerHint,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        sliver: SliverToBoxAdapter(
          child: SizedBox(
            height: 220.h,
            child: _Podium(
              top3: top3,
              displayName: _displayName,
              isQuiz: _isQuiz,
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(child: SizedBox(height: 18.h)),
      SliverPadding(
        padding: EdgeInsets.zero,
        sliver: SliverList.builder(
          itemCount: displayedEntries.length,
          itemBuilder: (context, index) {
            final user = displayedEntries[index];
            // Compute the original rank in the full list.
            final originalIndex = shouldPin
                ? (index >= userIndex ? index + 1 : index)
                : index;
            return Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
              child: _RankRow(
                rank: originalIndex + 1,
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
      // Loading more indicator.
      if (_isLoadingMore)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Center(
              child: SizedBox(
                height: 20.r,
                width: 20.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2.r,
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
        ),
      // "Load more" sentinel at bottom to trigger scroll-based loading.
      if (hasMore && !_isLoadingMore)
        SliverToBoxAdapter(child: SizedBox(height: 1.h)),
      SliverToBoxAdapter(child: SizedBox(height: 8.h)),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 0),
        sliver: SliverToBoxAdapter(
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
            baseColor: AppColors.cardBorder,
            highlightColor: AppColors.cardBorder.withValues(alpha: 1),
            child: Container(
              height: 58.h,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
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
    if (meIndex < 0) {
      final message = AppLocalizations.of(
        context,
      )!.leaderboardNudgeKeepClimbing;
      _logDebug(
        'nudge=not-found periodIndex=$_periodIndex isStreak=$_isStreak '
        'authUid=$authUid entries=${entries.length} message="$message"',
      );
      return message;
    }
    if (meIndex == 0) {
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

/// Fixed card at the bottom of the screen for the current user when ranked > 5.
class _PinnedBottomCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool isQuiz;
  final String statLabel;
  final String displayName;

  const _PinnedBottomCard({
    required this.entry,
    required this.rank,
    required this.isQuiz,
    required this.statLabel,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.emeraldDeep,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          child: Row(
            children: [
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: AppTextStyles.goldNumeric(context).copyWith(
                    color: AppColors.emeraldDeep,
                    fontSize: 16.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.you,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    if (isQuiz)
                      QuizLeaderboardStat(
                        points: entry.score,
                        attempts: entry.attemptCount ?? 0,
                        compact: true,
                      )
                    else
                      Text(
                        '${entry.score} $statLabel',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                  ],
                ),
              ),
              AvatarChip(
                initial: entry.isAnonymousDisplay
                    ? '🕌'
                    : displayName.substring(0, 1).toUpperCase(),
                color: entry.isAnonymousDisplay
                    ? AppColors.cardBorder
                    : AppColors.gold,
                size: 36,
              ),
            ],
          ),
        ),
      ),
    );
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
                    fontSize: options.length > 4
                        ? 10.sp
                        : (options.length > 3 ? 11.sp : 12.sp),
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
    // order: [2nd, 1st, 3rd]
    final order = [top3[1], top3[0], top3[2]];
    final ranks = [2, 1, 3];
    final pillarColors = [AppColors.goldCard, AppColors.gold, AppColors.goldCard];
    final rankColors = [AppColors.gold, AppColors.emeraldDeep, AppColors.gold];

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalH = constraints.maxHeight;
        final totalW = constraints.maxWidth;
        final colW = totalW / 3;
        final gap = totalH * 0.025;
        // Pillar heights as fraction — rank 1 tallest, rank 3 shortest.
        final pillarH = [totalH * 0.35, totalH * 0.50, totalH * 0.28];

        return SizedBox(
          height: totalH,
          width: totalW,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Pillars at bottom.
              for (int i = 0; i < 3; i++)
                Positioned(
                  left: i * colW + 6,
                  right: (2 - i) * colW + 6,
                  bottom: 0,
                  height: pillarH[i],
                  child: Container(
                    decoration: BoxDecoration(
                      color: pillarColors[i],
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8.r),
                      ),
                      border: Border.all(color: AppColors.goldBorder),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${ranks[i]}',
                      style: AppTextStyles.displayMedium(context).copyWith(
                        color: rankColors[i],
                        fontSize: 22.sp,
                      ),
                    ),
                  ),
                ),
              // Content on top of each pillar.
              for (int i = 0; i < 3; i++)
                Positioned(
                  left: i * colW,
                  right: (2 - i) * colW,
                  bottom: pillarH[i] + gap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AvatarChip(
                        initial: order[i].isAnonymousDisplay
                            ? '🕌'
                            : (displayName(order[i]).isEmpty
                                    ? '?'
                                    : displayName(order[i])
                                        .substring(0, 1))
                                .toUpperCase(),
                        color: order[i].isAnonymousDisplay
                            ? AppColors.cardBorder
                            : AppColors.gold,
                        size: ranks[i] == 1 ? 50 : 42,
                        ring: ranks[i] == 1,
                        fontSize: ranks[i] == 1 ? 20 : 16,
                      ),
                      SizedBox(height: gap),
                      Text(
                        displayName(order[i]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      if (isQuiz)
                        QuizLeaderboardStat(
                          points: order[i].score,
                          attempts: order[i].attemptCount ?? 0,
                          compact: true,
                        )
                      else
                        Text(
                          '${order[i].score}',
                          style: AppTextStyles.goldNumeric(context).copyWith(
                            fontSize: 14.sp,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
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
                style: AppTextStyles.bodySmall(
                  context,
                ).copyWith(fontSize: 10.sp),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

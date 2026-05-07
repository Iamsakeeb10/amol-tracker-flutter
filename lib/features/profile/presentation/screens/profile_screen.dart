import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../models/badge_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../shared/widgets/badge_tile.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/streak_badge.dart';
import '../../../../l10n/app_localizations.dart';

final profileRecentLogsProvider =
    FutureProvider.family<List<AmalLogModel>, int>((ref, limit) async {
      final user = ref.watch(authStateProvider).asData?.value;
      if (user == null) return <AmalLogModel>[];
      return ref
          .read(firestoreServiceProvider)
          .getRecentLogs(user.uid, limit: limit);
    });

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSavingName = false;
  bool _isSavingPrivacy = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authUser = ref.watch(authStateProvider).asData?.value;
    final user = ref.watch(currentUserProvider).asData?.value;
    final weekLogs =
        ref.watch(profileRecentLogsProvider(7)).asData?.value ?? [];
    final monthLogs =
        ref.watch(profileRecentLogsProvider(30)).asData?.value ?? [];

    if (authUser == null || user == null) {
      return AppScaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    if (_nameController.text != user.name) {
      _nameController.text = user.name;
      _nameController.selection = TextSelection.collapsed(
        offset: _nameController.text.length,
      );
    }

    final initial = user.name.trim().isEmpty
        ? '?'
        : user.name.trim().substring(0, 1).toUpperCase();
    final averageScore = monthLogs.isEmpty
        ? 0
        : (monthLogs.map((e) => e.score).reduce((a, b) => a + b) /
                  monthLogs.length)
              .round();

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.more),
        ),
        title: Text(l10n.profile, style: AppTextStyles.headlineMedium(context)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 4.h, 0, 24.h),
        children: [
          Center(
            child: AvatarChip(
              initial: user.isAnonymousDisplay ? '🕌' : initial,
              color: AppColors.gold,
              size: 88,
              ring: true,
              fontSize: 34,
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: AppTextStyles.displayMedium(context),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: l10n.displayName,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isSavingName
                      ? null
                      : () => _saveName(authUser.uid, _nameController.text),
                  icon: _isSavingName
                      ? SizedBox(
                          width: 16.r,
                          height: 16.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gold,
                          ),
                        )
                      : Icon(Icons.check_circle_outline, color: AppColors.gold),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            l10n.memberSince(user.createdAt.year),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(context),
          ),
          SizedBox(height: 12.h),
          Center(child: StreakBadge(days: user.currentStreak)),
          SizedBox(height: 18.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340.w;
              return GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
                childAspectRatio: compact ? 1.02 : 1.28,
                children: [
                  StatCard(
                    label: l10n.streak,
                    value: '${user.currentStreak}',
                    sublabel: l10n.historyDays,
                    prominent: true,
                  ),
                  StatCard(
                    label: l10n.best,
                    value: '${user.bestStreak}',
                    sublabel: l10n.historyDays,
                    prominent: true,
                  ),
                  StatCard(
                    label: l10n.avg,
                    value: '$averageScore',
                    sublabel: l10n.outOf100Compact,
                    prominent: true,
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 18.h),
          Text(l10n.thisWeek, style: AppTextStyles.headlineMedium(context)),
          SizedBox(height: 8.h),
          _WeekChart(logs: weekLogs),
          SizedBox(height: 18.h),
          CardContainer(
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: user.isAnonymousDisplay,
              onChanged: _isSavingPrivacy
                  ? null
                  : (value) => _saveAnonymous(authUser.uid, value),
              title: Text(
                l10n.showAnonymousCommunity,
                style: AppTextStyles.bodyLarge(context),
              ),
              subtitle: Text(
                user.isAnonymousDisplay
                    ? l10n.anonymousEnabled
                    : l10n.realNameVisible,
                style: AppTextStyles.bodySmall(context),
              ),
            ),
          ),
          SizedBox(height: 18.h),
          Text(l10n.badges, style: AppTextStyles.headlineMedium(context)),
          SizedBox(height: 8.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340.w;
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10.h,
                crossAxisSpacing: 10.w,
                childAspectRatio: compact ? 1.05 : 1.5,
                children: kBadgeDefinitions.map((b) {
                  final unlocked = user.badges.contains(b.id);
                  final progress = _badgeProgress(
                    b,
                    user.currentStreak,
                    unlocked,
                  );
                  return BadgeTile(
                    badge: b,
                    unlocked: unlocked,
                    progress: progress,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  double _badgeProgress(
    BadgeDefinition badge,
    int currentStreak,
    bool unlocked,
  ) {
    if (unlocked) return 1;
    if (badge.streakThreshold == null || badge.streakThreshold == 0) return 0;
    return (currentStreak / badge.streakThreshold!).clamp(0.0, 1.0);
  }

  Future<void> _saveName(String uid, String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) return;
    setState(() => _isSavingName = true);
    try {
      await ref
          .read(firestoreServiceProvider)
          .updateUserDisplayFields(uid, name: name);
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _saveAnonymous(String uid, bool value) async {
    setState(() => _isSavingPrivacy = true);
    try {
      await ref
          .read(firestoreServiceProvider)
          .updateUserDisplayFields(uid, isAnonymousDisplay: value);
    } finally {
      if (mounted) setState(() => _isSavingPrivacy = false);
    }
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.logs});

  final List<AmalLogModel> logs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CardContainer(
      child: SizedBox(
        height: 130.h,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _buildBars(l10n)
              .map(
                (b) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${(b.value * 100).round()}',
                          style: AppTextStyles.bodySmall(context).copyWith(
                            fontSize: 9.sp,
                            color: b.missed ? AppColors.danger : AppColors.gold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          height: 80.h * b.value,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: b.missed
                                  ? const [
                                      AppColors.danger,
                                      AppColors.dangerLight,
                                    ]
                                  : const [AppColors.gold, AppColors.goldLight],
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(4.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          b.label,
                          style: AppTextStyles.bodySmall(
                            context,
                          ).copyWith(fontSize: 10.sp),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  List<_ChartBar> _buildBars(AppLocalizations l10n) {
    final seed = <_ChartBar>[
      _ChartBar(label: l10n.weekdayMon, value: 0),
      _ChartBar(label: l10n.weekdayTue, value: 0),
      _ChartBar(label: l10n.weekdayWed, value: 0),
      _ChartBar(label: l10n.weekdayThu, value: 0),
      _ChartBar(label: l10n.weekdayFri, value: 0),
      _ChartBar(label: l10n.weekdaySat, value: 0),
      _ChartBar(label: l10n.weekdaySun, value: 0),
    ];
    if (logs.isEmpty) return seed;
    final tail = logs.length <= 7 ? logs : logs.sublist(logs.length - 7);
    final bars = List<_ChartBar>.from(seed);
    for (var i = 0; i < tail.length; i++) {
      final score = tail[i].score.clamp(0, 100);
      bars[7 - tail.length + i] = _ChartBar(
        label: bars[7 - tail.length + i].label,
        value: score / 100.0,
        missed: score < 50,
      );
    }
    return bars;
  }
}

class _ChartBar {
  const _ChartBar({
    required this.label,
    required this.value,
    this.missed = false,
  });
  final String label;
  final double value;
  final bool missed;
}

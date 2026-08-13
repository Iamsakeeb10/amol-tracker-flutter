import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/default_amal_fields.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../providers/amal_fields_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/history_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../shared/widgets/badge_tile.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../features/syllabus/presentation/widgets/lms_xp_widgets.dart';
import '../../../../shared/widgets/streak_badge.dart';
import '../../../../features/reports/presentation/widgets/report_prayer_breakdown.dart';

final profileRecentLogsProvider =
    FutureProvider.family<List<AmalLogModel>, int>((ref, limit) async {
      ref.watch(amalLogRefreshProvider);
      final user = ref.watch(authStateProvider).asData?.value;
      if (user == null) return <AmalLogModel>[];
      return ref
          .read(firestoreServiceProvider)
          .getRecentLogs(user.uid, limit: limit);
    });

final profileMonthAvgScoreProvider = Provider.autoDispose<int>((ref) {
  final logs = ref.watch(profileRecentLogsProvider(30)).asData?.value ?? [];
  if (logs.isEmpty) return 0;
  return (logs
              .map((e) => e.maxScore > 0 ? (e.score / e.maxScore) * 100 : 0.0)
              .reduce((a, b) => a + b) /
          logs.length)
      .round();
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSavingPrivacy = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenViewed('profile');
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
    final averageScore = ref.watch(profileMonthAvgScoreProvider);

    if (authUser == null || user == null) {
      return AppScaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final initial = user.name.trim().isEmpty
        ? '?'
        : user.name.trim().substring(0, 1).toUpperCase();
    final fields = ref.watch(amalFieldsListProvider);
    const maxScore = kDefaultMaxDailyScore;
    final liveStreak = ref.watch(liveStreakProvider).value ?? user.currentStreak;

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.more),
        ),
        title: Text(l10n.profile, style: AppTextStyles.headlineMedium(context)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(0, 4.h, 0, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
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
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40.w),
                            child: Text(
                              user.name.trim().isEmpty
                                  ? l10n.displayName
                                  : user.name,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.displayMedium(context),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: () =>
                                _showEditNameDialog(authUser.uid, user.name),
                            tooltip: l10n.displayName,
                            icon: Icon(
                              Icons.edit_rounded,
                              color: AppColors.gold,
                            ),
                          ),
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
                  Center(child: StreakBadge(days: liveStreak)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(top: 18.h),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
                childAspectRatio: profileStatGridAspectRatio(context),
              ),
              delegate: SliverChildListDelegate([
                StatCard(
                  label: l10n.streak,
                  value: '$liveStreak',
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
                  sublabel: '/$maxScore',
                  prominent: true,
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(top: 18.h),
            sliver: SliverToBoxAdapter(
              child: LmsXpProfileSection(lmsXp: user.lmsXp),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(top: 18.h),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.thisWeek,
                    style: AppTextStyles.headlineMedium(context),
                  ),
                  SizedBox(height: 8.h),
                  _WeekChart(
                    logs: weekLogs,
                    createdAt: user.createdAt,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(top: 18.h),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.prayerHabits,
                    style: AppTextStyles.headlineMedium(context),
                  ),
                  SizedBox(height: 8.h),
                  ReportPrayerBreakdownSection(
                    logs: monthLogs,
                    fields: fields,
                    compact: true,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(top: 18.h),
            sliver: SliverToBoxAdapter(
              child: CardContainer(
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
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(top: 18.h),
            sliver: SliverToBoxAdapter(
              child: CardContainer(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.history, color: AppColors.gold, size: 24.r),
                  title: Text(
                    l10n.localeName == 'bn' ? 'ব্যাটেল হিস্ট্রি' : 'Battle History',
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20.r),
                  onTap: () {
                    // Requires go_router import
                    context.push(AppRoutes.battleHistory);
                  },
                ),
              ),
            ),
          ),
          ProfileBadgesSection(
            unlockedBadgeIds: user.badges,
            currentStreak: liveStreak,
          ),
        ],
      ),
    );
  }

  Future<void> _showEditNameDialog(String uid, String currentName) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => _EditNameDialog(uid: uid, currentName: currentName),
    );
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

class _EditNameDialog extends ConsumerStatefulWidget {
  const _EditNameDialog({required this.uid, required this.currentName});

  final String uid;
  final String currentName;

  @override
  ConsumerState<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends ConsumerState<_EditNameDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = l10n.displayName);
      return;
    }
    if (name == widget.currentName.trim()) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = '';
    });

    try {
      await ref
          .read(firestoreServiceProvider)
          .updateUserDisplayFields(widget.uid, name: name);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      child: CardContainer(
        padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 14.h),
        borderColor: AppColors.goldBorder.withValues(alpha: 0.8),
        color: AppColors.emeraldMid.withValues(alpha: 0.98),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24.r,
            offset: Offset(0, 10.h),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42.r,
                  height: 42.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.goldCard,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.goldBorder),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: AppColors.gold,
                    size: 22.r,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    l10n.displayName,
                    style: AppTextStyles.bodyLarge(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700, fontSize: 15.sp),
                  ),
                ),
                IconButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: 20.r,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.r),
              decoration: BoxDecoration(
                color: AppColors.emeraldDeep.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.goldBorder.withValues(alpha: 0.45),
                ),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLength: 30,
                enabled: !_isSaving,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: AppTextStyles.bodyLarge(context),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: l10n.displayName,
                  errorText: _errorText.isEmpty ? null : _errorText,
                  hintStyle: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(color: AppColors.textMuted),
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
                SizedBox(width: 8.w),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.emeraldDeep,
                  ),
                  icon: _isSaving
                      ? SizedBox(
                          width: 14.r,
                          height: 14.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.emeraldDeep,
                          ),
                        )
                      : Icon(Icons.check_rounded, size: 16.r),
                  label: Text(
                    MaterialLocalizations.of(context).saveButtonLabel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({
    required this.logs,
    required this.createdAt,
  });

  final List<AmalLogModel> logs;
  final DateTime createdAt;

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
                          b.notJoined
                              ? '--'
                              : '${b.displayScore}',
                          style: AppTextStyles.bodySmall(context).copyWith(
                            fontSize: 9.sp,
                            color: b.notJoined
                                ? AppColors.textMuted
                                : (b.missed
                                      ? AppColors.danger
                                      : AppColors.gold),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          height: 80.h *
                              (b.notJoined
                                  ? 0
                                  : (b.displayScore / b.maxScore)
                                      .clamp(0.0, 1.0)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: b.notJoined
                                  ? const [
                                      AppColors.cardBorder,
                                      AppColors.cardBorder,
                                    ]
                                  : (b.missed
                                        ? const [
                                            AppColors.danger,
                                            AppColors.dangerLight,
                                          ]
                                        : const [
                                            AppColors.gold,
                                            AppColors.goldLight,
                                          ]),
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
      _ChartBar(label: l10n.weekdayMon, displayScore: 0, maxScore: 1),
      _ChartBar(label: l10n.weekdayTue, displayScore: 0, maxScore: 1),
      _ChartBar(label: l10n.weekdayWed, displayScore: 0, maxScore: 1),
      _ChartBar(label: l10n.weekdayThu, displayScore: 0, maxScore: 1),
      _ChartBar(label: l10n.weekdayFri, displayScore: 0, maxScore: 1),
      _ChartBar(label: l10n.weekdaySat, displayScore: 0, maxScore: 1),
      _ChartBar(label: l10n.weekdaySun, displayScore: 0, maxScore: 1),
    ];
    final createdDate = DateTime(
      createdAt.toLocal().year,
      createdAt.toLocal().month,
      createdAt.toLocal().day,
    );
    final now = DateTime.now().toLocal();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final bars = List<_ChartBar>.from(seed);
    for (var i = 0; i < 7; i++) {
      final day = DateTime(weekStart.year, weekStart.month, weekStart.day + i);
      if (day.isBefore(createdDate)) {
        bars[i] = _ChartBar(
          label: bars[i].label,
          displayScore: 0,
          maxScore: 1,
          notJoined: true,
        );
      }
    }
    if (logs.isEmpty) return bars;
    final tail = logs.length <= 7 ? logs : logs.sublist(logs.length - 7);
    for (var i = 0; i < tail.length; i++) {
      final logMax = tail[i].maxScore <= 0 ? 1 : tail[i].maxScore;
      final score = tail[i].score.clamp(0, logMax);
      final index = 7 - tail.length + i;
      if (bars[index].notJoined) continue;
      bars[index] = _ChartBar(
        label: bars[index].label,
        displayScore: score,
        maxScore: logMax,
        missed: score < (logMax * 0.5).round(),
      );
    }
    return bars;
  }
}

class _ChartBar {
  const _ChartBar({
    required this.label,
    required this.displayScore,
    required this.maxScore,
    this.missed = false,
    this.notJoined = false,
  });
  final String label;
  final int displayScore;
  final int maxScore;
  final bool missed;
  final bool notJoined;
}

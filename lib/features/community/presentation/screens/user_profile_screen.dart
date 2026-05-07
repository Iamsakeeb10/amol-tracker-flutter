import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/hijri_helper.dart';
import '../../../../core/utils/streak_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/streak_badge.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? selectedHijriDate;
  final AmalLogModel? selectedLogFallback;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.selectedHijriDate,
    this.selectedLogFallback,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _sendingDua = false;
  bool _savingOwnProfile = false;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fs = ref.read(firestoreServiceProvider);
    final me = ref.watch(currentUserProvider).asData?.value;
    final isOwn = me?.uid == widget.userId;

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.community),
        ),
        title: Text(
          l10n.userProfile,
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: StreamBuilder<UserModel?>(
        stream: fs.userStream(widget.userId),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = userSnap.data;
          if (user == null) {
            return Center(
              child: Text(
                l10n.profileUnavailable,
                style: AppTextStyles.bodyMedium(context),
              ),
            );
          }
          if (_nameController.text.isEmpty) {
            _nameController.text = user.name;
          }

          return FutureBuilder<_ProfileData>(
            future: _loadProfileData(fs, user.uid),
            builder: (context, dataSnap) {
              if (dataSnap.connectionState == ConnectionState.waiting &&
                  !dataSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (dataSnap.hasError) {
                debugPrint('[UserProfileError] ${dataSnap.error}');
              }
              final profileData = dataSnap.data;
              final selectedLog = profileData?.selectedLog;
              final weekly = profileData?.weeklyLogs ?? const <AmalLogModel>[];
              final avgScore = profileData?.avgScore ?? 0;
              final selectedScore = selectedLog?.score ?? 0;
              final effectiveDate =
                  profileData?.effectiveDate ?? HijriHelper.todayString();
              final dateIsToday = effectiveDate == HijriHelper.todayString();
              final displayStreak = resolveDisplayedStreakValues(
                currentStreak: user.currentStreak,
                bestStreak: user.bestStreak,
                hasSubmittedToday: dateIsToday && selectedLog != null,
              );
              final displayAnonymous = user.isAnonymousDisplay && !isOwn;
              final shownName = displayAnonymous
                  ? l10n.anonymous
                  : (user.name.trim().isEmpty
                        ? l10n.communityMember
                        : user.name.trim());
              debugPrint(
                '[UserProfileBuild] uid=${user.uid} date=$effectiveDate selectedScore=$selectedScore selectedLogPresent=${selectedLog != null} displayStreakCurrent=${displayStreak.currentStreak} rawCurrent=${user.currentStreak}',
              );

              return ListView(
                padding: EdgeInsets.fromLTRB(0, 6.h, 0, 24.h),
                children: [
                  Center(
                    child: AvatarChip(
                      initial: displayAnonymous
                          ? '🕌'
                          : (shownName.isNotEmpty
                                ? shownName.substring(0, 1).toUpperCase()
                                : 'A'),
                      color: displayAnonymous
                          ? AppColors.emeraldLight
                          : AppColors.emeraldMid,
                      size: 76,
                      ring: true,
                      fontSize: 28,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    shownName,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displayMedium(context),
                  ),
                  SizedBox(height: 6.h),
                  Center(child: StreakBadge(days: displayStreak.currentStreak)),
                  SizedBox(height: 14.h),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 340.w;
                      return GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8.h,
                        crossAxisSpacing: 8.w,
                        childAspectRatio: compact ? 1.05 : 1.28,
                        children: [
                          StatCard(
                            label: dateIsToday ? l10n.today : l10n.selected,
                            value: '$selectedScore',
                            sublabel: l10n.outOf100Compact,
                            prominent: true,
                          ),
                          StatCard(
                            label: l10n.best,
                            value: '${displayStreak.bestStreak}',
                            sublabel: l10n.historyDays,
                            prominent: true,
                          ),
                          StatCard(
                            label: l10n.avg,
                            value: '$avgScore',
                            sublabel: l10n.outOf100Compact,
                            prominent: true,
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    dateIsToday
                        ? l10n.todaysAmal
                        : l10n.amalOnDate(
                            HijriHelper.displayFromStorage(effectiveDate),
                          ),
                    style: AppTextStyles.headlineMedium(context),
                  ),
                  SizedBox(height: 8.h),
                  CardContainer(
                    child: Column(
                      children: [
                        for (var i = 0; i < kAmalFields.length; i++) ...[
                          _AmalReadOnlyRow(
                            field: kAmalFields[i],
                            done:
                                (selectedLog?.toggles[kAmalFields[i].id] ??
                                false),
                          ),
                          if (i != kAmalFields.length - 1)
                            SizedBox(height: 8.h),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    l10n.last7Days,
                    style: AppTextStyles.headlineMedium(context),
                  ),
                  SizedBox(height: 8.h),
                  _WeeklyBars(logs: weekly),
                  SizedBox(height: 16.h),
                  if (isOwn) ...[
                    Text(
                      l10n.profileSettings,
                      style: AppTextStyles.headlineMedium(context),
                    ),
                    SizedBox(height: 8.h),
                    CardContainer(
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: l10n.displayName,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              l10n.showAnonymousCommunity,
                              style: AppTextStyles.bodyMedium(
                                context,
                              ).copyWith(color: AppColors.textPrimary),
                            ),
                            value: user.isAnonymousDisplay,
                            onChanged: _savingOwnProfile
                                ? null
                                : (value) async {
                                    setState(() => _savingOwnProfile = true);
                                    try {
                                      await fs.updateUser(user.uid, {
                                        'isAnonymousDisplay': value,
                                      });
                                    } finally {
                                      if (mounted)
                                        setState(
                                          () => _savingOwnProfile = false,
                                        );
                                    }
                                  },
                          ),
                          SizedBox(height: 8.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _savingOwnProfile
                                  ? null
                                  : () async {
                                      final trimmed = _nameController.text
                                          .trim();
                                      if (trimmed.isEmpty) return;
                                      setState(() => _savingOwnProfile = true);
                                      try {
                                        await fs.updateUser(user.uid, {
                                          'name': trimmed,
                                        });
                                      } finally {
                                        if (mounted) {
                                          setState(
                                            () => _savingOwnProfile = false,
                                          );
                                        }
                                      }
                                    },
                              child: Text(
                                _savingOwnProfile
                                    ? l10n.saving
                                    : l10n.saveProfile,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _sendingDua || me == null
                            ? null
                            : () => _sendDua(
                                context,
                                fs,
                                me.uid,
                                widget.userId,
                                me.isAnonymousDisplay
                                    ? l10n.anonymous
                                    : (me.name.trim().isEmpty
                                          ? l10n.communityMember
                                          : me.name.trim()),
                              ),
                        icon: Icon(
                          Icons.volunteer_activism_outlined,
                          size: 18.r,
                        ),
                        label: Text(_sendingDua ? l10n.sending : l10n.sendDua),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<_ProfileData> _loadProfileData(FirestoreService fs, String uid) async {
    final today = HijriHelper.todayString();
    final effectiveDate = widget.selectedHijriDate ?? today;
    final fallback =
        (widget.selectedLogFallback != null &&
            widget.selectedLogFallback!.uid == uid &&
            widget.selectedLogFallback!.hijriDate == effectiveDate)
        ? widget.selectedLogFallback
        : null;
    final selectedLog = await fs.getLog(uid, effectiveDate);
    debugPrint(
      '[UserProfile] uid=$uid date=$effectiveDate fetched=${selectedLog != null} fallback=${fallback != null}',
    );
    if (fallback != null) {
      debugPrint(
        '[UserProfileFallback] uid=${fallback.uid} date=${fallback.hijriDate} score=${fallback.score} toggles=${fallback.toggles}',
      );
    }
    if (selectedLog != null) {
      debugPrint(
        '[UserProfileFetched] uid=${selectedLog.uid} date=${selectedLog.hijriDate} score=${selectedLog.score} toggles=${selectedLog.toggles}',
      );
    }
    List<AmalLogModel> weekly = const <AmalLogModel>[];
    try {
      weekly = await fs.getRecentLogs(uid, limit: 7);
    } catch (e) {
      debugPrint('[UserProfileWeeklyError] uid=$uid error=$e');
    }
    final avgScore = weekly.isEmpty
        ? 0
        : (weekly.map((e) => e.score).reduce((a, b) => a + b) / weekly.length)
              .round();
    return _ProfileData(
      selectedLog: selectedLog ?? fallback,
      weeklyLogs: weekly,
      avgScore: avgScore,
      effectiveDate: effectiveDate,
    );
  }

  Future<void> _sendDua(
    BuildContext context,
    FirestoreService fs,
    String senderUid,
    String recipientUid,
    String senderName,
  ) async {
    setState(() => _sendingDua = true);
    try {
      final today = HijriHelper.todayString();
      final exists = await fs.hasSentDuaToday(
        senderUid: senderUid,
        recipientUid: recipientUid,
        hijriDate: today,
      );
      if (exists) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.alreadySentDuaToday),
          ),
        );
        return;
      }
      await fs.sendDua(
        senderUid: senderUid,
        senderName: senderName,
        recipientUid: recipientUid,
        hijriDate: today,
        message: AppLocalizations.of(context)!.duaFromSender(senderName),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.duaSent)),
      );
    } finally {
      if (mounted) setState(() => _sendingDua = false);
    }
  }
}

class _AmalReadOnlyRow extends StatelessWidget {
  const _AmalReadOnlyRow({required this.field, required this.done});

  final AmalField field;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26.r,
          height: 26.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done ? AppColors.goldCard : AppColors.cardDark,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: done ? AppColors.goldBorder : AppColors.cardBorder,
            ),
          ),
          child: Icon(
            amalFieldIcon(field.id),
            size: 14.r,
            color: done ? AppColors.gold : AppColors.textMuted,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            field.label,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textPrimary),
          ),
        ),
        Icon(
          done ? Icons.check_circle : Icons.cancel_outlined,
          size: 18.r,
          color: done ? AppColors.success : AppColors.danger,
        ),
      ],
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.logs});

  final List<AmalLogModel> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return CardContainer(
        child: Text(
          AppLocalizations.of(context)!.noRecentLogs,
          style: AppTextStyles.bodyMedium(context),
        ),
      );
    }
    final bars = logs.take(7).toList();
    return CardContainer(
      child: SizedBox(
        height: 130.h,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: bars.map((log) {
            final ratio = (log.score / 100).clamp(0.0, 1.0);
            final missed = log.score < 50;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${log.score}',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontSize: 10.sp,
                        color: missed ? AppColors.danger : AppColors.gold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      height: 80.h * ratio,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: missed
                              ? const [AppColors.danger, AppColors.dangerLight]
                              : const [AppColors.gold, AppColors.goldLight],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(4.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      log.hijriDate.split('-').last,
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.selectedLog,
    required this.weeklyLogs,
    required this.avgScore,
    required this.effectiveDate,
  });

  final AmalLogModel? selectedLog;
  final List<AmalLogModel> weeklyLogs;
  final int avgScore;
  final String effectiveDate;
}

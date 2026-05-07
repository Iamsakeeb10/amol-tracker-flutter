import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/islamic_date_service.dart';
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
            return const _UserProfileLoadingShimmer();
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
                return const _UserProfileLoadingShimmer();
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
                  profileData?.effectiveDate ??
                  IslamicDateService.getCurrentIslamicDateString();
              final dateIsToday =
                  effectiveDate ==
                  IslamicDateService.getCurrentIslamicDateString();
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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      shownName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.displayMedium(context),
                    ),
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
                            value: selectedLog?.toggles[kAmalFields[i].id],
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
                                      if (mounted) {
                                        setState(
                                          () => _savingOwnProfile = false,
                                        );
                                      }
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
    final today = IslamicDateService.getCurrentIslamicDateString();
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
    final l10n = AppLocalizations.of(context)!;
    debugPrint('👆 Send Dua pressed sender=$senderUid recipient=$recipientUid');
    setState(() => _sendingDua = true);
    try {
      final today = IslamicDateService.getCurrentIslamicDateString();
      final exists = await fs.hasSentDuaToday(
        senderUid: senderUid,
        recipientUid: recipientUid,
        hijriDate: today,
      );
      if (exists) {
        debugPrint('⛔ blocked_already_sent recipient=$recipientUid');
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.alreadySentDuaToday)));
        return;
      }
      await fs.sendDua(
        senderUid: senderUid,
        senderName: senderName,
        recipientUid: recipientUid,
        hijriDate: today,
        message: l10n.duaFromSender(senderName),
      );
      debugPrint('🎉 Send Dua completed recipient=$recipientUid');
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.duaSent)));
    } finally {
      if (mounted) setState(() => _sendingDua = false);
    }
  }
}

class _AmalReadOnlyRow extends StatelessWidget {
  const _AmalReadOnlyRow({required this.field, required this.value});

  final AmalField field;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final done = field.type == AmalType.numeric
        ? getNumericValue(value, field.maxValue) > 0
        : value == true;
    final numericValue = field.type == AmalType.numeric
        ? getNumericValue(value, field.maxValue)
        : null;
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
            field.labelBn,
            style: AppTextStyles.bodyMedium(
              context,
            ).copyWith(color: AppColors.textPrimary),
          ),
        ),
        if (field.type == AmalType.numeric)
          Text(
            '${_toBengaliNumeral(numericValue!)}/${_toBengaliNumeral(field.maxValue)}',
            style: AppTextStyles.pill(context).copyWith(
              color: numericValue > 0 ? AppColors.gold : AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          Icon(
            done ? Icons.check_circle : Icons.cancel_outlined,
            size: 18.r,
            color: done ? AppColors.success : AppColors.danger,
          ),
      ],
    );
  }
}

String _toBengaliNumeral(int number) {
  const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return number
      .toString()
      .split('')
      .map((digit) => bnDigits[int.parse(digit)])
      .join();
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
            final ratio = (log.score / kMaxDailyScore).clamp(0.0, 1.0);
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

class _UserProfileLoadingShimmer extends StatelessWidget {
  const _UserProfileLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.emeraldMid.withValues(alpha: 0.35),
      child: ListView(
        padding: EdgeInsets.fromLTRB(0, 6.h, 0, 24.h),
        children: [
          Center(
            child: Container(
              width: 76.r,
              height: 76.r,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Center(
            child: Container(
              width: 160.w,
              height: 18.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8.h,
            crossAxisSpacing: 8.w,
            childAspectRatio: 1.2,
            children: List.generate(
              3,
              (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            width: 110.w,
            height: 16.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: index == 4 ? 0 : 8.h),
                  child: Container(
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            width: 90.w,
            height: 16.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            height: 130.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
        ],
      ),
    );
  }
}

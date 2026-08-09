import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/constants/default_amal_fields.dart';
import '../../../../core/utils/score_calculator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/dua_push_debug.dart';
import '../../../../core/utils/hijri_helper.dart';
import '../../../../core/utils/streak_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/amal_fields_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/history_provider.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../shared/widgets/badge_tile.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/streak_badge.dart';
import '../../../../features/reports/presentation/widgets/report_prayer_breakdown.dart';

const _kDuaPhrases = [
  'মাশা আল্লাহ',
  'আলহামদুলিল্লাহ',
  'সুবহানাল্লাহ',
  'আল্লাহু আকবার',
  'জাযাকাল্লাহু খায়রান',
  'বারাকাল্লাহু ফিক',
  'আমীন',
];

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
  String? _nameSyncedForUid;

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
    final locale = Localizations.localeOf(context).languageCode;
    final fields = ref.watch(amalFieldsListProvider);
    const maxScore = kDefaultMaxDailyScore;
    final fs = ref.read(firestoreServiceProvider);
    final me = ref.watch(currentUserProvider).asData?.value;
    final isOwn = me?.uid == widget.userId;
    final logRefresh = ref.watch(amalLogRefreshProvider);

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
          if (_nameSyncedForUid != user.uid) {
            _nameSyncedForUid = user.uid;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _nameSyncedForUid != user.uid) return;
              _nameController.text = user.name;
            });
          }

          return FutureBuilder<_ProfileData>(
            key: ValueKey(
              'profile-$logRefresh-${widget.userId}-${widget.selectedHijriDate}',
            ),
            future: _loadProfileData(fs, user),
            builder: (context, dataSnap) {
              if (dataSnap.connectionState == ConnectionState.waiting &&
                  !dataSnap.hasData) {
                return const _UserProfileLoadingShimmer();
              }
              final profileData = dataSnap.data;
              final selectedLog = profileData?.selectedLog;
              final weekly = profileData?.weeklyLogs ?? const <AmalLogModel>[];
              final avgScore = profileData?.avgScore ?? 0;
              final selectedScore = selectedLog?.score ?? 0;
              final effectiveDate =
                  profileData?.effectiveDate ??
                  IslamicDateService.getCurrentIslamicDateStringSafe();
              final dateIsToday =
                  effectiveDate ==
                  IslamicDateService.getCurrentIslamicDateStringSafe();
              final computedStreak = profileData?.computedStreak ?? 0;
              final bestStreak = user.bestStreak;
              final displayStreak = DisplayStreakValues(
                currentStreak: computedStreak,
                bestStreak: bestStreak < computedStreak
                    ? computedStreak
                    : bestStreak,
              );
              final displayAnonymous = user.isAnonymousDisplay && !isOwn;
              final shownName = displayAnonymous
                  ? l10n.anonymous
                  : (user.name.trim().isEmpty
                        ? l10n.communityMember
                        : user.name.trim());

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(0, 6.h, 0, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Center(
                            child: AvatarChip(
                              initial: displayAnonymous
                                  ? '🕌'
                                  : (shownName.isNotEmpty
                                        ? shownName
                                              .substring(0, 1)
                                              .toUpperCase()
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
                          Center(
                            child: StreakBadge(
                              days: displayStreak.currentStreak,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(top: 14.h),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8.h,
                        crossAxisSpacing: 8.w,
                        childAspectRatio: profileStatGridAspectRatio(context),
                      ),
                      delegate: SliverChildListDelegate([
                        StatCard(
                          label: dateIsToday ? l10n.today : l10n.selected,
                          value: '$selectedScore',
                          sublabel: '/$maxScore',
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
                          sublabel: '/$maxScore',
                          prominent: true,
                        ),
                      ]),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(top: 16.h, bottom: 24.h),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                    child: Builder(
                      builder: (context) {
                        final activeIds =
                            selectedLog?.activeFieldIds.toSet() ?? const <String>{};
                        final displayFields = activeIds.isEmpty
                            ? fields
                            : fields
                                .where((f) => activeIds.contains(f.id))
                                .toList();
                        return Column(
                          children: [
                            for (var i = 0; i < displayFields.length; i++) ...[
                              _AmalReadOnlyRow(
                                field: displayFields[i],
                                locale: locale,
                                value: selectedLog?.toggles[displayFields[i].id],
                              ),
                              if (i != displayFields.length - 1)
                                SizedBox(height: 8.h),
                            ],
                          ],
                        );
                      },
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
                  Text(
                    l10n.prayerStats,
                    style: AppTextStyles.headlineMedium(context),
                  ),
                  SizedBox(height: 8.h),
                  ReportPrayerBreakdownSection(
                    logs: weekly,
                    fields: fields,
                    compact: true,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    l10n.badges,
                    style: AppTextStyles.headlineMedium(context),
                  ),
                  SizedBox(height: 8.h),
                  ProfileBadgesGrid(
                    unlockedBadgeIds: user.badges,
                    currentStreak: displayStreak.currentStreak,
                  ),
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
                            : () => _showDuaSheet(
                                context: context,
                                fs: fs,
                                senderUid: me.uid,
                                recipientUid: widget.userId,
                                senderName: me.isAnonymousDisplay
                                    ? l10n.anonymous
                                    : (me.name.trim().isEmpty
                                          ? l10n.communityMember
                                          : me.name.trim()),
                                senderGender: me.gender,
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
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<_ProfileData> _loadProfileData(FirestoreService fs, UserModel user) async {
    final today = IslamicDateService.getCurrentIslamicDateStringSafe();
    final effectiveDate = widget.selectedHijriDate ?? today;
    final fallback =
        (widget.selectedLogFallback != null &&
            widget.selectedLogFallback!.uid == user.uid &&
            widget.selectedLogFallback!.hijriDate == effectiveDate)
        ? widget.selectedLogFallback
        : null;
    final selectedLog = await fs.getLog(user.uid, effectiveDate);
    // Fetch 30 logs to compute an accurate streak (not just 7).
    List<AmalLogModel> allLogs = const <AmalLogModel>[];
    try {
      allLogs = await fs.getRecentLogs(user.uid, limit: 30);
    } catch (_) {}
    // Compute streak from actual logs, excluding backfilled submissions.
    final loggedDates = <String>{
      for (final log in allLogs)
        if (!isBackfilledLog(log)) log.hijriDate,
    };
    final frozenDates = <String>{
      if (user.streakFreezeDate.isNotEmpty) user.streakFreezeDate,
    };
    final computedStreak = computeStreakFromLogs(
      loggedDates: loggedDates,
      todayHijri: today,
      frozenDates: frozenDates,
    );
    final avgScore = allLogs.isEmpty
        ? 0
        : (allLogs
                  .map((e) =>
                      e.maxScore > 0 ? (e.score / e.maxScore) * 100 : 0.0)
                  .reduce((a, b) => a + b) /
              allLogs.length)
            .round();
    return _ProfileData(
      selectedLog: selectedLog ?? fallback,
      weeklyLogs: allLogs,
      computedStreak: computedStreak,
      avgScore: avgScore,
      effectiveDate: effectiveDate,
    );
  }

  Future<void> _showDuaSheet({
    required BuildContext context,
    required FirestoreService fs,
    required String senderUid,
    required String recipientUid,
    required String senderName,
    String? senderGender,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) {
        return _DuaSheet(
          onSend: (selectedPhrase) {
            final message = '$senderName: $selectedPhrase 🤲';
            return _sendDua(
              context: context,
              fs: fs,
              senderUid: senderUid,
              recipientUid: recipientUid,
              senderName: senderName,
              message: message,
              senderGender: senderGender,
            );
          },
        );
      },
    );
  }

  Future<bool> _sendDua({
    required BuildContext context,
    required FirestoreService fs,
    required String senderUid,
    required String recipientUid,
    required String senderName,
    required String message,
    String? senderGender,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _sendingDua = true);
    try {
      final today = IslamicDateService.getCurrentIslamicDateStringSafe();
      logDuaPushDebug(
        'user profile send dua tapped: senderUid=$senderUid '
        'recipientUid=$recipientUid hijriDate=$today',
      );
      final exists = await fs.hasSentDuaToday(
        senderUid: senderUid,
        recipientUid: recipientUid,
        hijriDate: today,
      );
      if (exists) {
        logDuaPushDebug(
          'send dua aborted: already sent today senderUid=$senderUid '
          'recipientUid=$recipientUid',
        );
        if (!context.mounted) return false;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.alreadySentDuaToday)));
        return false;
      }
      await fs.sendDua(
        senderUid: senderUid,
        senderName: senderName,
        recipientUid: recipientUid,
        hijriDate: today,
        message: message,
        senderGender: senderGender,
      );
      logDuaPushDebug(
        'user profile send dua finished (see Firestore/gateway logs for push): '
        'recipientUid=$recipientUid',
      );
      if (!context.mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.duaSent)));
      return true;
    } finally {
      if (mounted) setState(() => _sendingDua = false);
    }
  }
}

class _DuaSheet extends StatefulWidget {
  const _DuaSheet({required this.onSend});

  final Future<bool> Function(String selectedPhrase) onSend;

  @override
  State<_DuaSheet> createState() => _DuaSheetState();
}

class _DuaSheetState extends State<_DuaSheet> {
  String? _selectedPhrase;
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDisabled = _isSending || _selectedPhrase == null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h + bottomInset),
        child: CardContainer(
          color: AppColors.emeraldMid,
          borderColor: AppColors.goldBorder,
          radius: 24,
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'দোয়া বেছে নিন',
                style: AppTextStyles.headlineMedium(context),
              ),
              SizedBox(height: 12.h),
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 8.w) / 2;
                  return Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: _kDuaPhrases.map((phrase) {
                      final selected = _selectedPhrase == phrase;
                      return SizedBox(
                        width: itemWidth,
                        child: _DuaPhraseButton(
                          phrase: phrase,
                          selected: selected,
                          onTap: () {
                            setState(
                              () => _selectedPhrase = selected ? null : phrase,
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              SizedBox(height: 14.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isDisabled
                      ? null
                      : () async {
                          setState(() => _isSending = true);
                          final didSend = await widget.onSend(_selectedPhrase!);
                          if (!context.mounted) return;
                          setState(() => _isSending = false);
                          if (didSend) {
                            Navigator.of(context).pop();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.emeraldDeep,
                    disabledBackgroundColor: AppColors.gold.withValues(
                      alpha: 0.45,
                    ),
                    disabledForegroundColor: AppColors.emeraldDeep.withValues(
                      alpha: 0.75,
                    ),
                  ),
                  child: _isSending
                      ? SizedBox(
                          width: 16.r,
                          height: 16.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.emeraldDeep,
                            ),
                          ),
                        )
                      : Text(
                          'পাঠান',
                          style: AppTextStyles.button(
                            context,
                          ).copyWith(color: AppColors.emeraldDeep),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DuaPhraseButton extends StatelessWidget {
  const _DuaPhraseButton({
    required this.phrase,
    required this.selected,
    required this.onTap,
  });

  final String phrase;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: selected ? AppColors.goldCard : AppColors.cardDark,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: selected ? AppColors.goldBorder : AppColors.cardBorder,
            ),
          ),
          child: Text(
            phrase,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: selected ? AppColors.gold : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AmalReadOnlyRow extends StatelessWidget {
  const _AmalReadOnlyRow({
    required this.field,
    required this.locale,
    required this.value,
  });

  final AmalField field;
  final String locale;
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
          child: AmalFieldIcon(
            fieldId: field.id,
            size: 14.r,
            color: done ? AppColors.gold : AppColors.textMuted,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            field.getLabel(locale),
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
    final bars = logs.length <= 7 ? logs : logs.sublist(logs.length - 7);
    return CardContainer(
      child: SizedBox(
        height: 130.h,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: bars.map((log) {
            final barMax = log.maxScore <= 0 ? 1 : log.maxScore;
            final ratio = (log.score / barMax).clamp(0.0, 1.0);
            final missed = log.score < (barMax * 0.5).round();
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
    required this.computedStreak,
    required this.avgScore,
    required this.effectiveDate,
  });

  final AmalLogModel? selectedLog;
  final List<AmalLogModel> weeklyLogs;
  final int computedStreak;
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
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(0, 6.h, 0, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 76.r,
                      height: 76.r,
                      decoration: const BoxDecoration(
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
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(top: 14.h),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
                childAspectRatio: 1.2,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, __) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                childCount: 3,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(top: 16.h, bottom: 24.h),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
            ),
          ),
        ],
      ),
    );
  }
}

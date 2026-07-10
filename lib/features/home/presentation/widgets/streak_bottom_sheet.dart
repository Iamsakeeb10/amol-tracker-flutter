import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/streak_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../providers/amal_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/date_provider.dart';
import '../../../../shared/widgets/card_container.dart';

enum StreakDayStatus { completed, missed, today, preAccount }

class StreakDay {
  final String hijriDate;
  final StreakDayStatus status;
  final int score;
  final String weekday;
  final String hijriDisplay;

  const StreakDay({
    required this.hijriDate,
    required this.status,
    required this.score,
    required this.weekday,
    required this.hijriDisplay,
  });
}

class StreakBottomSheet extends ConsumerStatefulWidget {
  const StreakBottomSheet({super.key, required this.uid});

  final String uid;

  static Future<void> show(BuildContext context, {required String uid}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StreakBottomSheet(uid: uid),
    );
  }

  @override
  ConsumerState<StreakBottomSheet> createState() => _StreakBottomSheetState();
}

class _StreakBottomSheetState extends ConsumerState<StreakBottomSheet> {
  int _weekOffset = 0;
  int _selectedIndex = 6;
  Map<String, AmalLogModel?> _dayLogs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeekLogs();
  }

  String get _today =>
      ref.read(currentHijriDateProvider);

  List<String> get _visibleDates {
    final today = _today;
    return List.generate(
      7,
      (i) => IslamicDateService.shiftStorageByDays(
        today,
        _weekOffset + i - 6,
      ),
    );
  }

  bool get _canGoPrevious {
    final dates = _visibleDates;
    final earliest = dates.first;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return false;
    final accountCreated = IslamicDateService.hijriStorageForAccountCreated(
      user.createdAt,
    );
    return earliest.compareTo(accountCreated) > 0;
  }

  bool get _canGoNext => _weekOffset < 0;

  Future<void> _loadWeekLogs() async {
    setState(() => _isLoading = true);
    final dates = _visibleDates;
    final fs = ref.read(firestoreServiceProvider);
    final results = await Future.wait(
      dates.map((d) => fs.getLog(widget.uid, d)),
    );
    if (!mounted) return;
    setState(() {
      _dayLogs = {
        for (var i = 0; i < dates.length; i++) dates[i]: results[i],
      };
      _isLoading = false;
    });
    _clampSelectedIndex();
  }

  void _clampSelectedIndex() {
    final dates = _visibleDates;
    final today = _today;
    final user = ref.read(currentUserProvider).value;
    final accountCreated = user != null
        ? IslamicDateService.hijriStorageForAccountCreated(user.createdAt)
        : '';
    var lastValid = 6;
    for (var i = 6; i >= 0; i--) {
      final d = dates[i];
      if (d.compareTo(today) <= 0 &&
          (accountCreated.isEmpty || d.compareTo(accountCreated) >= 0)) {
        lastValid = i;
        break;
      }
    }
    if (_selectedIndex > lastValid) {
      _selectedIndex = lastValid;
    }
  }

  /// Locale-aware weekday for a Hijri storage date.
  /// For today, uses [nowInBD] directly to stay in sync with the home screen.
  static String _weekdayForStorage(
    String hijriYyyyMmDd,
    String locale, {
    bool isToday = false,
  }) {
    final loc = locale == 'bn' ? 'bn_BD' : 'en_US';
    if (isToday) {
      return DateFormat('EEEE', loc).format(IslamicDateService.nowInBD());
    }
    final parts = hijriYyyyMmDd.split('-');
    if (parts.length != 3) return '';
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return '';
    try {
      final dt = HijriCalendar().hijriToGregorian(y, m, d);
      return DateFormat('EEEE', loc).format(dt);
    } catch (_) {
      return '';
    }
  }

  /// Returns true if [log] was backfilled — i.e. submitted on a different
  /// Hijri day than the log's own [hijriDate]. Backfilled logs should not
  /// count as "completed" for streak display purposes.
  static bool _isBackfilled(AmalLogModel log, String hijriDate) {
    try {
      final submittedBd = IslamicDateService.bangladeshDateTimeFrom(
        log.submittedAt,
      );
      final submittedHijri = IslamicDateService.islamicDateStringForGregorianDate(
        submittedBd,
      );
      return submittedHijri != hijriDate;
    } catch (_) {
      return false;
    }
  }

  StreakDay _resolveDay(String hijriDate, String locale) {
    final today = _today;
    final user = ref.read(currentUserProvider).value;
    final accountCreated = user != null
        ? IslamicDateService.hijriStorageForAccountCreated(user.createdAt)
        : '';

    final weekday = _weekdayForStorage(
      hijriDate,
      locale,
      isToday: hijriDate == today,
    );
    final hijriDisplay = locale == 'bn'
        ? IslamicDateService.displayFromStorageBn(hijriDate)
        : IslamicDateService.displayFromStorageEn(hijriDate);

    if (accountCreated.isNotEmpty && hijriDate.compareTo(accountCreated) < 0) {
      return StreakDay(
        hijriDate: hijriDate,
        status: StreakDayStatus.preAccount,
        score: 0,
        weekday: weekday,
        hijriDisplay: hijriDisplay,
      );
    }

    if (hijriDate == today) {
      final log = _dayLogs[hijriDate];
      final isSubmitted = ref.read(
        amalProvider(widget.uid).select((s) => s.isSubmitted),
      );
      if (isSubmitted && log != null) {
        return StreakDay(
          hijriDate: hijriDate,
          status: StreakDayStatus.completed,
          score: log.score,
          weekday: weekday,
          hijriDisplay: hijriDisplay,
        );
      }
      return StreakDay(
        hijriDate: hijriDate,
        status: StreakDayStatus.today,
        score: 0,
        weekday: weekday,
        hijriDisplay: hijriDisplay,
      );
    }

    final log = _dayLogs[hijriDate];
    if (log != null) {
      final backfilled = _isBackfilled(log, hijriDate);
      return StreakDay(
        hijriDate: hijriDate,
        status: (log.score > 0 && !backfilled)
            ? StreakDayStatus.completed
            : StreakDayStatus.missed,
        score: log.score,
        weekday: weekday,
        hijriDisplay: hijriDisplay,
      );
    }

    return StreakDay(
      hijriDate: hijriDate,
      status: StreakDayStatus.missed,
      score: 0,
      weekday: weekday,
      hijriDisplay: hijriDisplay,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final user = ref.watch(currentUserProvider).value;
    final displayStreak = resolveDisplayedStreakValues(
      currentStreak: user?.currentStreak ?? 0,
      bestStreak: user?.bestStreak ?? 0,
      hasSubmittedToday: ref.watch(
        amalProvider(widget.uid).select((s) => s.isSubmitted),
      ),
    );

    final currentWeekKey = weekKeyFromDate(IslamicDateService.nowInBD());
    final freezeAvailable = user != null &&
        (user.streakFreezeWeekKey != currentWeekKey || !user.streakFreezeUsed);

    final days = _visibleDates.map((d) => _resolveDay(d, locale)).toList();

    return Padding(
      padding: EdgeInsets.all(16.r),
      child: SafeArea(
        top: false,
        child: CardContainer(
          color: AppColors.emeraldMid,
          borderColor: AppColors.goldBorder,
          radius: 24,
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                ),
              ),
              _SheetHeader(
                streak: displayStreak.currentStreak,
                onClose: () => Navigator.pop(context),
              ),
              SizedBox(height: 12.h),
              _StatsRow(
                bestStreak: displayStreak.bestStreak,
                freezeAvailable: freezeAvailable,
                freezeUsed: user?.streakFreezeUsed ?? false,
                currentWeekKey: currentWeekKey,
                freezeWeekKey: user?.streakFreezeWeekKey ?? '',
              ),
              SizedBox(height: 16.h),
              Text(
                l10n.streakSheetLast7Days,
                style: AppTextStyles.label(context),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                height: 90.h,
                child: _isLoading
                    ? _DayCardsShimmer()
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        itemCount: days.length,
                        separatorBuilder: (_, index) => SizedBox(width: 6.w),
                        itemBuilder: (_, i) => _DayCard(
                          day: days[i],
                          isSelected: i == _selectedIndex,
                          onTap: () => setState(() => _selectedIndex = i),
                        ),
                      ),
              ),
              SizedBox(height: 10.h),
              _WeekNavRow(
                weekOffset: _weekOffset,
                onPrev: _canGoPrevious
                    ? () => setState(() {
                          _weekOffset -= 7;
                          _selectedIndex = 6;
                          _loadWeekLogs();
                        })
                    : null,
                onNext: _canGoNext
                    ? () => setState(() {
                          _weekOffset += 7;
                          _selectedIndex = 6;
                          _loadWeekLogs();
                        })
                    : null,
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final int streak;
  final VoidCallback onClose;

  const _SheetHeader({required this.streak, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.local_fire_department,
          color: AppColors.warning,
          size: 22.r,
        ),
        SizedBox(width: 8.w),
        Text(
          AppLocalizations.of(context)!.dayStreak(streak),
          style: AppTextStyles.headlineMedium(context),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Icon(
              Icons.close,
              color: AppColors.textSecondary,
              size: 16.r,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int bestStreak;
  final bool freezeAvailable;
  final bool freezeUsed;
  final String currentWeekKey;
  final String freezeWeekKey;

  const _StatsRow({
    required this.bestStreak,
    required this.freezeAvailable,
    required this.freezeUsed,
    required this.currentWeekKey,
    required this.freezeWeekKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final freezeActiveThisWeek = freezeUsed && currentWeekKey == freezeWeekKey;

    return Row(
      children: [
        Expanded(
          child: _StatPill(
            icon: Icons.workspace_premium,
            label: l10n.streakSheetBestStreak,
            value: '$bestStreak',
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _StatPill(
            icon: Icons.ac_unit,
            label: freezeActiveThisWeek
                ? l10n.streakSheetFreezeUsed
                : l10n.streakSheetFreezeAvailable,
            value: freezeActiveThisWeek ? '0' : '1',
            valueColor: freezeActiveThisWeek
                ? AppColors.textMuted
                : AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 28.r,
            height: 28.r,
            decoration: BoxDecoration(
              color: AppColors.goldCard,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: AppColors.gold, size: 16.r),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.goldNumeric(context).copyWith(
              fontSize: 18.sp,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final StreakDay day;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayCard({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  Color _borderColor() => switch (day.status) {
        StreakDayStatus.completed => AppColors.success.withValues(alpha: 0.4),
        StreakDayStatus.missed => AppColors.danger.withValues(alpha: 0.35),
        StreakDayStatus.today => AppColors.goldBorder,
        StreakDayStatus.preAccount => AppColors.cardBorder,
      };

  Color _bgColor() => switch (day.status) {
        StreakDayStatus.completed => AppColors.successLight,
        StreakDayStatus.missed => AppColors.dangerLight,
        StreakDayStatus.today => AppColors.goldCard,
        StreakDayStatus.preAccount => AppColors.cardDark,
      };

  IconData _statusIcon() => switch (day.status) {
        StreakDayStatus.completed => Icons.check_circle,
        StreakDayStatus.missed => Icons.cancel,
        StreakDayStatus.today => Icons.schedule,
        StreakDayStatus.preAccount => Icons.remove_circle_outline,
      };

  Color _iconColor() => switch (day.status) {
        StreakDayStatus.completed => AppColors.success,
        StreakDayStatus.missed => AppColors.danger,
        StreakDayStatus.today => AppColors.gold,
        StreakDayStatus.preAccount => AppColors.textMuted,
      };

  String _weekdayShort() {
    if (day.weekday.isEmpty) return '';
    const bnShort = {
      'শনিবার': 'শনি',
      'রবিবার': 'রবি',
      'সোমবার': 'সোম',
      'মঙ্গলবার': 'মঙ্গল',
      'বুধবার': 'বুধ',
      'বৃহস্পতিবার': 'বৃহ',
      'শুক্রবার': 'শুক্র',
    };
    return bnShort[day.weekday] ??
        day.weekday.substring(
          0,
          day.weekday.length < 3 ? day.weekday.length : 3,
        );
  }

  @override
  Widget build(BuildContext context) {
    final hijriDayNum = day.hijriDisplay.split(' ').firstOrNull ?? '';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 62.w,
        decoration: BoxDecoration(
          color: _bgColor(),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? AppColors.gold.withValues(alpha: 0.6)
                : _borderColor(),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 4.h),
            Text(
              _weekdayShort(),
              style: AppTextStyles.label(context).copyWith(
                fontSize: 9.sp,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 3.h),
            Icon(
              _statusIcon(),
              color: _iconColor(),
              size: 20.r,
            ),
            SizedBox(height: 2.h),
            Text(
              hijriDayNum,
              style: AppTextStyles.bodySmall(context).copyWith(
                fontSize: 9.sp,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              day.status == StreakDayStatus.completed
                  ? '${day.score}'
                  : _statusLabel(context),
              style: AppTextStyles.pill(context).copyWith(
                fontSize: 9.sp,
                color: _iconColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  String _statusLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (day.status) {
      StreakDayStatus.completed => '',
      StreakDayStatus.missed => l10n.streakSheetMissed,
      StreakDayStatus.today => l10n.streakSheetToday,
      StreakDayStatus.preAccount => l10n.streakSheetPreAccount,
    };
  }
}

class _DayCardsShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.emeraldMid.withValues(alpha: 0.35),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: 7,
        separatorBuilder: (_, idx) => SizedBox(width: 6.w),
        itemBuilder: (_, idx) => Container(
          width: 62.w,
          height: 82.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }
}

class _WeekNavRow extends StatelessWidget {
  final int weekOffset;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _WeekNavRow({
    required this.weekOffset,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        GestureDetector(
          onTap: onPrev,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chevron_left,
                color: onPrev != null ? AppColors.gold : AppColors.textMuted,
                size: 20.r,
              ),
              Text(
                l10n.streakSheetPrevious,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: onPrev != null ? AppColors.gold : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onNext,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.streakSheetNext,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: onNext != null ? AppColors.gold : AppColors.textMuted,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: onNext != null ? AppColors.gold : AppColors.textMuted,
                size: 20.r,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/personal_amol_model.dart';
import '../../../../providers/personal_amol_provider.dart';
import '../../../../shared/widgets/card_container.dart';
import 'personal_amol_create_sheet.dart';
import 'personal_amol_icons.dart';

/// Visual constants shared by personal-amol modal UI, mirroring the community
/// amol dialog palette so the two feel identical on the home screen.
abstract final class PersonalAmolDialogColors {
  static final barrier = Colors.black.withValues(alpha: 0.6);
  static final dialogBorder = AppColors.goldBorder.withValues(alpha: 0.8);
  static final dialogBg = AppColors.emeraldMid.withValues(alpha: 0.98);
  static final shadow = Colors.black.withValues(alpha: 0.35);
  static final sublabelBg = AppColors.emeraldDeep.withValues(alpha: 0.88);
  static final sublabelBorder = AppColors.goldBorder.withValues(alpha: 0.45);
}

/// Details dialog for a personal amol on the home screen, styled after the
/// community amol dialog ([showHomeAmalDetailsDialog]). Shows the amol's icon,
/// name, frequency, tracking type/target, scheduled weekdays, today's progress
/// and streak stats, with an Edit action that reuses the sheet.
Future<void> showPersonalAmolDetailsDialog(
  BuildContext context, {
  required String uid,
  required PersonalAmolModel amol,
  required int doneCount,
}) async {
  final l10n = AppLocalizations.of(context)!;
  // Read the streak snapshot synchronously from the provider cache (may be
  // null if not yet loaded — that's fine, we log 0 as a safe default).
  AnalyticsService.instance.logPersonalAmolDetailOpened(
    type: amol.type == PersonalAmolType.count ? 'count' : 'toggle',
    currentStreak: 0, // streak is loaded inside the dialog widget itself
  );
  await showDialog<void>(
    context: context,
    barrierColor: PersonalAmolDialogColors.barrier,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
        child: _PersonalAmolDetailsDialog(
          uid: uid,
          amol: amol,
          doneCount: doneCount,
          l10n: l10n,
        ),
      );
    },
  );
}

class _PersonalAmolDetailsDialog extends ConsumerWidget {
  const _PersonalAmolDetailsDialog({
    required this.uid,
    required this.amol,
    required this.doneCount,
    required this.l10n,
  });

  final String uid;
  final PersonalAmolModel amol;
  final int doneCount;
  final AppLocalizations l10n;

  bool get _isWeekdays => amol.frequency == PersonalAmolFrequency.weekdays;

  int get _target =>
      amol.type == PersonalAmolType.count ? amol.target : 1;

  String _weekdayName(int dayIndex) {
    switch (dayIndex) {
      case 1:
        return l10n.personalAmolWeekdaySat;
      case 2:
        return l10n.personalAmolWeekdaySun;
      case 3:
        return l10n.personalAmolWeekdayMon;
      case 4:
        return l10n.personalAmolWeekdayTue;
      case 5:
        return l10n.personalAmolWeekdayWed;
      case 6:
        return l10n.personalAmolWeekdayThu;
      case 7:
        return l10n.personalAmolWeekdayFri;
    }
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(
      personalAmolStreakProvider(
        PersonalAmolStreakKey(uid: uid, amolId: amol.id),
      ),
    );
    final currentStreak = streakAsync.value?.currentStreak ?? 0;
    final bestStreak = streakAsync.value?.bestStreak ?? 0;
    final progress = (_target <= 0) ? 0.0 : (doneCount / _target).clamp(0.0, 1.0);
    final isDone = doneCount >= _target;

    return CardContainer(
      padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 14.h),
      borderColor: PersonalAmolDialogColors.dialogBorder,
      color: PersonalAmolDialogColors.dialogBg,
      boxShadow: [
        BoxShadow(
          color: PersonalAmolDialogColors.shadow,
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
                  color: isDone ? AppColors.gold : AppColors.goldCard,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDone ? AppColors.goldBorder : AppColors.goldBorder,
                  ),
                ),
                child: AmolIconView(
                  icon: amol.icon,
                  onFilled: isDone,
                  emojiSize: 20,
                  iconSize: 22,
                  fallbackText: amol.name,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      amol.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      amol.frequency == PersonalAmolFrequency.daily
                          ? l10n.personalAmolFrequencyDaily
                          : l10n.personalAmolFrequencyWeekdays,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
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
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: PersonalAmolDialogColors.sublabelBg,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: PersonalAmolDialogColors.sublabelBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.personalAmolProgressLabel(doneCount, _target),
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_isWeekdays) ...[
                      SizedBox(width: 8.w),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            amol.weekdays.map(_weekdayName).join(', '),
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6.h,
                    backgroundColor: AppColors.cardBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _InfoChip(
                icon: amol.type == PersonalAmolType.count
                    ? Icons.pin_outlined
                    : Icons.toggle_on_outlined,
                text: amol.type == PersonalAmolType.count
                    ? l10n.personalAmolTypeCount
                    : l10n.personalAmolTypeToggle,
              ),
              if (amol.type == PersonalAmolType.count)
                _InfoChip(
                  icon: Icons.filter_alt_outlined,
                  text: '${l10n.personalAmolTargetLabel}: $_target',
                ),
              _StreakChip(currentStreak: currentStreak),
              if (bestStreak > 0)
                _InfoChip(
                  icon: Icons.emoji_events_outlined,
                  text: '${l10n.historyBestStreak}: $bestStreak',
                ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.goldBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.cancel,
                      style: AppTextStyles.button(context).copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    AnalyticsService.instance.logPersonalAmolCreateSheetOpened(
                      entryPoint: 'detail_edit',
                    );
                    PersonalAmolCreateSheet.showForEdit(
                      context,
                      uid: uid,
                      amol: amol,
                      entryPoint: 'detail_edit',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.emeraldDeep,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.personalAmolEditLabel,
                      style: AppTextStyles.button(context).copyWith(
                        color: AppColors.emeraldDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.goldCard,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.goldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold, size: 14.r),
          SizedBox(width: 5.w),
          Text(
            text,
            style: AppTextStyles.label(context).copyWith(
              color: AppColors.textPrimary,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.currentStreak});

  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.goldCard,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.goldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: AppColors.warning, size: 14.r),
          SizedBox(width: 5.w),
          Text(
            l10n.personalAmolStreakLabel(currentStreak),
            style: AppTextStyles.label(context).copyWith(
              color: AppColors.textPrimary,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}
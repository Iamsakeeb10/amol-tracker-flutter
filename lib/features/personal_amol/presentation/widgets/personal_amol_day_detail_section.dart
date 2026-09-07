import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/bengali_numeral_helper.dart';
import '../../../../core/utils/personal_amol_schedule.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/personal_amol_model.dart';
import '../../../../providers/personal_amol_provider.dart';
import 'personal_amol_icons.dart';

/// Read-only personal amol section shown on the day-detail screen. Lists each
/// active personal amol with its completion status for the given hijri date.
class PersonalAmolDayDetailSection extends ConsumerWidget {
  const PersonalAmolDayDetailSection({
    super.key,
    required this.uid,
    required this.hijriDate,
  });

  final String uid;
  final String hijriDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final amolsAsync = ref.watch(allPersonalAmolProvider(uid));
    final amols = amolsAsync.value ?? const <PersonalAmolModel>[];
    final due = amols
        .where((a) => personalAmolScheduledOn(a, hijriDate))
        .toList();
    if (due.isEmpty) return const SizedBox.shrink();

    final completionsAsync = ref.watch(
      personalAmolCompletionsForDateProvider(
        PersonalAmolDateKey(uid: uid, hijriDate: hijriDate),
      ),
    );
    final counts = <String, int>{};
    for (final c in completionsAsync.value ?? const <PersonalAmolCompletion>[]) {
      counts[c.amolId] = (counts[c.amolId] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),
        Text(
          l10n.personalAmolHistorySection,
          style: AppTextStyles.headlineMedium(context),
        ),
        SizedBox(height: 8.h),
    for (final amol in due) ...[
          _row(context, amol, counts[amol.id] ?? 0),
          SizedBox(height: 8.h),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, PersonalAmolModel amol, int doneCount) {
    final l10n = AppLocalizations.of(context)!;
    final target = amol.type == PersonalAmolType.count ? amol.target : 1;
    final completed = doneCount >= target;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.emeraldMid.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: completed
                  ? AppColors.gold
                  : AppColors.emeraldMid.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: AmolIconView(
              icon: amol.icon,
              onFilled: completed,
              emojiSize: 18,
              iconSize: 20,
              fallbackText: amol.name,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amol.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: completed
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  amol.type == PersonalAmolType.count && !completed
                      ? '${toBengaliNumeral(doneCount)}/${toBengaliNumeral(target)}'
                      : completed
                            ? l10n.personalAmolHistoryCompleted
                            : l10n.personalAmolHistoryNotCompleted,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontSize: 11.sp,
                    color: completed ? AppColors.gold : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (amol.frequency == PersonalAmolFrequency.weekdays)
            Container(
              width: 30.r,
              height: 30.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: completed
                    ? AppColors.gold
                    : AppColors.emeraldMid.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed ? Icons.check : Icons.schedule,
                color: completed ? AppColors.emeraldDeep : AppColors.gold,
                size: 18.r,
              ),
            )
          else
            Icon(
              completed ? Icons.check_circle : Icons.circle_outlined,
              color: completed ? AppColors.gold : AppColors.textMuted,
              size: 26.r,
            ),
        ],
      ),
    );
  }
}

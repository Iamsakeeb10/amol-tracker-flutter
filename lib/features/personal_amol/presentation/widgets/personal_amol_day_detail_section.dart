import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/personal_amol_model.dart';
import '../../../../providers/personal_amol_provider.dart';

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
    final amolsAsync = ref.watch(activePersonalAmolProvider(uid));
    final amols = amolsAsync.value ?? const <PersonalAmolModel>[];
    if (amols.isEmpty) return const SizedBox.shrink();

    final completionsAsync = ref.watch(
      personalAmolCompletionsForDateProvider(
        PersonalAmolDateKey(uid: uid, hijriDate: hijriDate),
      ),
    );
    final doneIds =
        (completionsAsync.value ?? const <PersonalAmolCompletion>[])
            .map((c) => c.amolId)
            .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),
        Text(
          l10n.personalAmolHistorySection,
          style: AppTextStyles.headlineMedium(context),
        ),
        SizedBox(height: 8.h),
        for (final amol in amols) ...[
          _row(context, amol, doneIds.contains(amol.id)),
          SizedBox(height: 8.h),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, PersonalAmolModel amol, bool completed) {
    final l10n = AppLocalizations.of(context)!;
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
              color: AppColors.emeraldMid.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              amol.icon.isNotEmpty ? amol.icon : amol.name.characters.first,
              style: TextStyle(fontSize: 18.sp),
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
                  completed
                      ? l10n.personalAmolHistoryCompleted
                      : l10n.personalAmolHistoryNotCompleted,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(fontSize: 11.sp, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
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

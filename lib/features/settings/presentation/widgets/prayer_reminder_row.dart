import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/time_display_helper.dart';
import '../../../../l10n/app_localizations.dart';

class PrayerAdhanOffsetChip extends StatelessWidget {
  const PrayerAdhanOffsetChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isLast = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: isLast ? 0 : 4.w),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: selected ? AppColors.gold : AppColors.cardDark,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: selected ? AppColors.gold : AppColors.cardBorder,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall(context).copyWith(
                fontSize: 10.sp,
                color: selected
                    ? AppColors.emeraldDeep
                    : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PrayerTimesStripColumn extends StatelessWidget {
  const PrayerTimesStripColumn({
    super.key,
    required this.icon,
    required this.label,
    required this.time,
  });

  final IconData icon;
  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.r, color: AppColors.gold),
        SizedBox(height: 4.h),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall(context).copyWith(fontSize: 10.sp),
        ),
        SizedBox(height: 2.h),
        Text(
          time,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall(context).copyWith(
            fontSize: 9.sp,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class PrayerReminderRow extends StatelessWidget {
  const PrayerReminderRow({
    super.key,
    required this.icon,
    required this.title,
    required this.reminderTime,
    required this.enabled,
    required this.usesCustomTime,
    required this.onToggle,
    required this.onPickTime,
    this.onReset,
    this.suppressedByQuietHours = false,
    this.quietHoursLabel,
    this.isSaving = false,
  });

  final IconData icon;
  final String title;
  final TimeOfDay reminderTime;
  final bool enabled;
  final bool usesCustomTime;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;
  final VoidCallback? onReset;
  final bool suppressedByQuietHours;
  final String? quietHoursLabel;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeColor = !enabled
        ? AppColors.textHint
        : suppressedByQuietHours
        ? AppColors.textHint
        : AppColors.textMuted;
    final subtitle = suppressedByQuietHours && quietHoursLabel != null
        ? quietHoursLabel!
        : usesCustomTime
        ? l10n.prayerAdhanCustomTimeLabel
        : l10n.prayerAdhanCalculatedTime;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onPickTime,
              borderRadius: BorderRadius.circular(AppRadius.md.r),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
                child: Row(
                  children: [
                    Container(
                      width: 34.r,
                      height: 34.r,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(icon, size: 16.r, color: AppColors.gold),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.bodyLarge(context).copyWith(
                              fontSize: 14.sp,
                              color: enabled
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            subtitle,
                            style: AppTextStyles.bodySmall(context).copyWith(
                              fontSize: 11.sp,
                              color: suppressedByQuietHours
                                  ? AppColors.textHint
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatBdTime(context, reminderTime),
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: timeColor,
                        fontSize: 13.sp,
                      ),
                    ),
                    if (usesCustomTime && onReset != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 28.r,
                          minHeight: 28.r,
                        ),
                        tooltip: l10n.prayerAdhanResetToAdhan,
                        onPressed: onReset,
                        icon: Icon(
                          Icons.restore_outlined,
                          size: 18.r,
                          color: AppColors.gold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (isSaving)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: SizedBox(
                width: 14.r,
                height: 14.r,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.gold,
                ),
              ),
            ),
          Switch.adaptive(
            value: enabled,
            onChanged: onToggle,
            activeThumbColor: AppColors.emeraldDeep,
            activeTrackColor: AppColors.gold,
          ),
        ],
      ),
    );
  }
}

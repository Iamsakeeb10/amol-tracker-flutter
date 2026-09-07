import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/bengali_numeral_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/personal_amol_model.dart';
import '../../../../providers/personal_amol_provider.dart';
import '../../../../shared/widgets/card_container.dart';
import 'personal_amol_icons.dart';
import 'personal_amol_stepper.dart';

/// Card for a single personal amol, styled to match the community amol rows
/// (see [AmalRow]): same card colors, rounded-square icon, and adaptive switch.
///
/// On the home screen [onToggle] (toggle type) or [onPlus]/[onMinus] (count
/// type) are provided and [readOnly] is false; in other contexts the tile is
/// static.
class PersonalAmolTile extends ConsumerWidget {
  const PersonalAmolTile({
    super.key,
    required this.uid,
    required this.amol,
    this.completed = false,
    this.doneCount = 0,
    this.readOnly = false,
    this.onToggle,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onPlus,
    this.onMinus,
  });

  final String uid;
  final PersonalAmolModel amol;
  final bool completed;
  final int doneCount;
  final bool readOnly;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPlus;
  final VoidCallback? onMinus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final streakAsync = ref.watch(
      personalAmolStreakProvider(
        PersonalAmolStreakKey(uid: uid, amolId: amol.id),
      ),
    );
    final streak = streakAsync.value?.currentStreak ?? 0;
    final frequency = amol.frequency == PersonalAmolFrequency.daily
        ? l10n.personalAmolFrequencyDaily
        : l10n.personalAmolFrequencyWeekdays;

    return CardContainer(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w + 2.w,
        vertical: AppSpacing.md.h,
      ),
      color: completed ? AppColors.goldCard : AppColors.cardDark,
      borderColor: completed ? AppColors.goldBorder : AppColors.cardBorder,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: completed ? AppColors.gold : AppColors.cardBorder,
              borderRadius: BorderRadius.circular(AppRadius.md.r - 2),
            ),
            child: AmolIconView(
              icon: amol.icon,
              onFilled: completed,
              emojiSize: 18,
              iconSize: 20,
              fallbackText: amol.name,
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amol.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                SizedBox(
                  height: 18.h,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          frequency,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                      if (streak > 0) ...[
                        Text(
                          ' • ',
                          style: AppTextStyles.bodySmall(context).copyWith(
                            fontSize: 11.sp,
                          ),
                        ),
                        Icon(
                          Icons.local_fire_department,
                          color: AppColors.warning,
                          size: 13.r,
                        ),
                        SizedBox(width: 2.w),
                        Flexible(
                          child: Text(
                            l10n.dayStreak(streak),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall(context).copyWith(
                              fontSize: 11.sp,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          if (readOnly)
            if (onEdit != null || onDelete != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    SizedBox(
                      width: 40.w,
                      height: 40.h,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.edit_outlined,
                          color: AppColors.gold,
                          size: 20.r,
                        ),
                        onPressed: onEdit,
                      ),
                    ),
                  if (onDelete != null)
                    SizedBox(
                      width: 40.w,
                      height: 40.h,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.danger,
                          size: 20.r,
                        ),
                        onPressed: onDelete,
                      ),
                    ),
                ],
              )
            else
              _staticTrailing(context)
          else if (amol.type == PersonalAmolType.count &&
              (onPlus != null || onMinus != null))
            PersonalAmolStepper(
              doneCount: doneCount,
              target: amol.target,
              onIncrement: onPlus,
              onDecrement: onMinus,
            )
          else if (onToggle != null)
            SizedBox(
              width: 48.w,
              height: 48.h,
              child: Center(
                child: Switch.adaptive(
                  value: completed,
                  onChanged: (_) => onToggle!(),
                  activeThumbColor: AppColors.emeraldDeep,
                  activeTrackColor: AppColors.gold,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            )
          else
            _staticTrailing(context),
        ],
      ),
    );
  }

  Widget _staticTrailing(BuildContext context) {
    if (amol.type == PersonalAmolType.count) {
      return Container(
        height: 48.h,
        alignment: Alignment.centerRight,
        child: Text(
          '${toBengaliNumeral(doneCount)}/${toBengaliNumeral(amol.target)}',
          style: AppTextStyles.pill(context).copyWith(
            color: completed ? AppColors.gold : AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Container(
      height: 48.h,
      alignment: Alignment.centerRight,
      child: Icon(
        completed ? Icons.check_circle : Icons.cancel_outlined,
        color: completed ? AppColors.success : AppColors.danger,
        size: 22.r,
      ),
    );
  }
}
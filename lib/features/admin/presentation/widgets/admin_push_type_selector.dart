import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import 'admin_push_helpers.dart';

class AdminPushTypePillSelector extends StatelessWidget {
  const AdminPushTypePillSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: kAdminPushTypes.map((type) {
          final isSelected = selected == type;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: InkWell(
              onTap: () => onChanged(type),
              borderRadius: BorderRadius.circular(99.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.goldCard : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(99.r),
                  border: Border.all(
                    color: isSelected ? AppColors.gold : AppColors.cardBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      iconForAdminPushType(type),
                      size: 14.r,
                      color: isSelected ? AppColors.gold : AppColors.textMuted,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      adminPushTypeLabel(l10n, type),
                      style: AppTextStyles.pill(context).copyWith(
                        color: isSelected
                            ? AppColors.gold
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

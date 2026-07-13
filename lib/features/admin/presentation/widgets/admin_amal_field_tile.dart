import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/streak_badge.dart';
import 'admin_amal_field_helpers.dart';
import 'admin_shared_widgets.dart';

class AdminAmalFieldTile extends StatelessWidget {
  const AdminAmalFieldTile({
    super.key,
    required this.field,
    required this.onTap,
    required this.onToggleActive,
  });

  final AmalField field;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleActive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = amalFieldLocaleCode(context);
    final isActive = field.isActive;
    final statusColor = isActive ? AppColors.success : AppColors.textMuted;
    final statusText = isActive ? l10n.adminFormActive : l10n.adminStatusOff;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: CardContainer(
        onTap: onTap,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            AdminIconBox(
              icon: resolveIconFromField(field) ?? iconForAmalType(field.type),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.getLabel(locale),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge(context).copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    amalFieldTileSubtitle(l10n, field),
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Pill(
                  text: statusText,
                  color: statusColor.withValues(alpha: 0.2),
                  textColor: statusColor,
                ),
                SizedBox(height: 6.h),
                Switch(
                  value: isActive,
                  onChanged: onToggleActive,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeThumbColor: AppColors.emeraldDeep,
                  activeTrackColor: AppColors.gold,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

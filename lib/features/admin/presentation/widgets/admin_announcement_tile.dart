import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/announcement_model.dart';
import 'admin_announcement_helpers.dart';

class AdminAnnouncementTile extends StatelessWidget {
  const AdminAnnouncementTile({
    super.key,
    required this.announcement,
    required this.onTap,
    required this.onToggleActive,
    required this.onDismissed,
  });

  final AnnouncementModel announcement;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleActive;
  final Future<void> Function() onDismissed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = statusForAnnouncement(announcement);

    return Dismissible(
      key: ValueKey<String>(announcement.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        color: AppColors.danger.withValues(alpha: 0.85),
        child: Icon(Icons.delete_outline, color: AppColors.textPrimary, size: 22.r),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.emeraldDeep,
            title: Text(
              l10n.adminDeleteTitle,
              style: AppTextStyles.headlineMedium(ctx),
            ),
            content: Text(
              l10n.adminDeleteConfirm,
              style: AppTextStyles.bodyMedium(ctx),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  l10n.delete,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) => onDismissed(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            children: [
              Icon(
                iconForAnnouncementType(announcement.type),
                color: AppColors.goldLight,
                size: 20.r,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor(status).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: statusColor(status).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        statusLabel(l10n, status),
                        style: AppTextStyles.label(context).copyWith(
                          color: statusColor(status),
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: announcement.isActive,
                onChanged: onToggleActive,
                activeThumbColor: AppColors.gold,
                activeTrackColor: AppColors.gold.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

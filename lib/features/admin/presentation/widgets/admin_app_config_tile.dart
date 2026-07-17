import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/app_config_model.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/streak_badge.dart';
import 'admin_shared_widgets.dart';

class AdminAppConfigTile extends StatelessWidget {
  const AdminAppConfigTile({
    super.key,
    required this.config,
    required this.onTap,
    required this.onToggleActive,
    required this.onDismissed,
  });

  final AppConfigModel config;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleActive;
  final Future<void> Function() onDismissed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final created = DateFormat('dd MMM yyyy').format(config.createdAt);
    final statusText = config.isActive ? l10n.adminStatusLive : l10n.adminStatusOff;
    final statusColor = config.isActive ? AppColors.success : AppColors.textMuted;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Dismissible(
        key: ValueKey<String>(config.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.w),
          decoration: BoxDecoration(
            color: AppColors.dangerLight,
            borderRadius: BorderRadius.circular(AppRadius.lg.r),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.delete,
                style: AppTextStyles.bodySmall(context).copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 6.w),
              Icon(Icons.delete_outline, color: AppColors.danger, size: 20.r),
            ],
          ),
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
        child: CardContainer(
          onTap: onTap,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              AdminIconBox(
                icon: config.forceUpdate
                    ? Icons.lock_outline
                    : Icons.system_update_outlined,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.updateTitle.isNotEmpty
                          ? config.updateTitle
                          : 'v${config.latestVersion}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'v${config.latestVersion} (${config.latestVersionCode}) · $created',
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
                    value: config.isActive,
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
      ),
    );
  }
}

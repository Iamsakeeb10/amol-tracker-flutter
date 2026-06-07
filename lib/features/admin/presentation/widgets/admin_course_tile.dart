import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/course_model.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/streak_badge.dart';
import 'admin_course_helpers.dart';
import 'admin_shared_widgets.dart';

class AdminCourseTile extends StatelessWidget {
  const AdminCourseTile({
    super.key,
    required this.course,
    required this.onTap,
    required this.onManageLessons,
    this.onTogglePublished,
    this.onDismissed,
  });

  final CourseModel course;
  final VoidCallback onTap;
  final VoidCallback onManageLessons;
  final ValueChanged<bool>? onTogglePublished;
  final Future<void> Function()? onDismissed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = course.status;
    final canManageLifecycle = onDismissed != null && onTogglePublished != null;

    final card = CardContainer(
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AdminIconBox(icon: Icons.menu_book_outlined),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (course.tags.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        course.tags.take(3).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Pill(
                text: courseStatusLabel(l10n, status),
                color: courseStatusColor(status).withValues(alpha: 0.2),
                textColor: courseStatusColor(status),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onManageLessons,
                  icon: Icon(Icons.playlist_play_rounded, size: 16.r),
                  label: Text(l10n.adminCourseManageLessons),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.cardBorder),
                    foregroundColor: AppColors.goldLight,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                  ),
                ),
              ),
              if (canManageLifecycle) ...[
                SizedBox(width: 12.w),
                Text(
                  l10n.adminCourseStatusPublished,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontSize: 11.sp,
                  ),
                ),
                Switch(
                  value: course.isPublished,
                  onChanged: onTogglePublished,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeThumbColor: AppColors.emeraldDeep,
                  activeTrackColor: AppColors.gold,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (!canManageLifecycle) {
      return Padding(padding: EdgeInsets.only(bottom: 8.h), child: card);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Dismissible(
        key: ValueKey<String>(course.id),
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
                l10n.adminCourseDeleteTitle,
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
        onDismissed: (_) => onDismissed!(),
        child: card,
      ),
    );
  }
}

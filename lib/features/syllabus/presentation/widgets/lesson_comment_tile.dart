import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/lesson_comment_model.dart';
import '../../../../shared/widgets/avatar_chip.dart';

class LessonCommentTile extends StatelessWidget {
  const LessonCommentTile({
    super.key,
    required this.comment,
    required this.canEdit,
    required this.canDelete,
    this.onEdit,
    this.onDelete,
  });

  final LessonCommentModel comment;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = comment.authorName.trim();
    final initial = name.isEmpty
        ? '?'
        : String.fromCharCode(name.runes.first).toUpperCase();
    final timeLabel = DateFormat.MMMd().add_jm().format(comment.createdAt);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarChip(initial: initial, color: AppColors.gold, size: 36),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.authorName.trim().isEmpty
                            ? 'Student'
                            : comment.authorName,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10.sp,
                      ),
                    ),
                    if (canEdit && onEdit != null) ...[
                      SizedBox(width: 4.w),
                      InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(4.r),
                        child: Padding(
                          padding: EdgeInsets.all(4.r),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 16.r,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                    if (canDelete && onDelete != null) ...[
                      SizedBox(width: 4.w),
                      InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(4.r),
                        child: Padding(
                          padding: EdgeInsets.all(4.r),
                          child: Icon(
                            Icons.delete_outline,
                            size: 16.r,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  comment.message,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontSize: 13.sp,
                  ),
                ),
                if (comment.editedAt != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    l10n.lessonDiscussionEdited,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10.sp,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/admin_push_debug.dart';
import '../../../../core/theme/colors.dart';
import '../../../../providers/admin_push_provider.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/constants/admin_config.dart';
import '../../../../models/course_model.dart';
import '../../../../models/user_model.dart';
import '../../../../models/lesson_model.dart';

const kLessonResourceTypes = <LessonResourceType>[
  LessonResourceType.youtube,
  LessonResourceType.pdf,
  LessonResourceType.link,
  LessonResourceType.text,
];

class AdminLessonFormArgs {
  const AdminLessonFormArgs({required this.courseId, this.lesson});

  final String courseId;
  final LessonModel? lesson;
}

bool adminCanAccessCourseList(UserModel? user, List<CourseModel> courses) {
  if (AdminConfig.canAccessCourseAdmin(user?.uid, role: user?.role)) {
    return true;
  }
  final uid = user?.uid;
  if (uid == null) return false;
  return courses.any((course) => course.moderators.contains(uid));
}

List<CourseModel> adminVisibleCourses(
  UserModel? user,
  List<CourseModel> courses,
) {
  if (AdminConfig.isFullAdmin(user?.uid, role: user?.role)) return courses;
  final uid = user?.uid;
  if (uid == null) return const [];
  return courses
      .where(
        (course) =>
            AdminConfig.canModerateCourse(uid, course, role: user?.role),
      )
      .toList();
}

bool adminCanModerateCourseRef(UserModel? user, CourseModel? course) {
  if (course == null) {
    return AdminConfig.canAccessCourseAdmin(user?.uid, role: user?.role);
  }
  return AdminConfig.canModerateCourse(user?.uid, course, role: user?.role);
}

IconData iconForResourceType(LessonResourceType type) {
  return switch (type) {
    LessonResourceType.youtube => Icons.play_circle_outline,
    LessonResourceType.pdf => Icons.picture_as_pdf_outlined,
    LessonResourceType.link => Icons.link_rounded,
    LessonResourceType.text => Icons.article_outlined,
  };
}

String resourceTypeLabel(AppLocalizations l10n, LessonResourceType type) {
  return switch (type) {
    LessonResourceType.youtube => l10n.adminLessonTypeYoutube,
    LessonResourceType.pdf => l10n.adminLessonTypePdf,
    LessonResourceType.link => l10n.adminLessonTypeLink,
    LessonResourceType.text => l10n.adminLessonTypeText,
  };
}

String courseStatusLabel(AppLocalizations l10n, CourseStatus status) {
  return switch (status) {
    CourseStatus.published => l10n.adminCourseStatusPublished,
    CourseStatus.draft => l10n.adminCourseStatusDraft,
  };
}

Color courseStatusColor(CourseStatus status) {
  return switch (status) {
    CourseStatus.published => AppColors.success,
    CourseStatus.draft => AppColors.textMuted,
  };
}

List<String> parseCommaSeparated(String raw) {
  return raw
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String joinCommaSeparated(List<String> items) => items.join(', ');

/*
Purpose:
Broadcast an FCM push when an admin publishes a new syllabus course.

Response:
None — failures are logged and do not block the publish action.

Business Rules:
- Skips silently when push gateway is not configured.
- Uses type syllabus_course for inbox routing.

Flow:
1. Read AdminPushGatewayService from Riverpod.
2. POST title/message via sendAdminPush.
3. Log result in debug mode.

Side Effects:
- Triggers remote FCM broadcast via Cloudflare worker.

Failure Cases:
- Gateway misconfiguration, auth, or network errors are non-fatal.
*/
Future<void> notifyCoursePublishedPush({
  required WidgetRef ref,
  required String adminUid,
  required String courseTitle,
  required String pushTitle,
  required String pushMessage,
}) async {
  if (adminUid.isEmpty) return;

  final gateway = ref.read(adminPushGatewayServiceProvider);
  if (!gateway.isConfigured) {
    logAdminPushDebug('course publish push skipped: gateway not configured');
    return;
  }

  final result = await gateway.sendAdminPush(
    adminUid: adminUid,
    title: pushTitle,
    message: pushMessage,
    type: 'syllabus_course',
  );

  if (!result.success) {
    logAdminPushDebug(
      'course publish push failed: adminUid=$adminUid error=${result.error}',
    );
  }
}

class AdminResourceTypeSelector extends StatelessWidget {
  const AdminResourceTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final LessonResourceType selected;
  final ValueChanged<LessonResourceType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: kLessonResourceTypes.map((type) {
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
                      iconForResourceType(type),
                      size: 14.r,
                      color: isSelected ? AppColors.gold : AppColors.textMuted,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      resourceTypeLabel(l10n, type),
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

class AdminCourseStatusSelector extends StatelessWidget {
  const AdminCourseStatusSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final CourseStatus selected;
  final ValueChanged<CourseStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: CourseStatus.values.map((status) {
        final isSelected = selected == status;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: status == CourseStatus.draft ? 8.w : 0,
            ),
            child: InkWell(
              onTap: () => onChanged(status),
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.goldCard : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? AppColors.gold : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  courseStatusLabel(l10n, status),
                  style: AppTextStyles.pill(context).copyWith(
                    color: isSelected ? AppColors.gold : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

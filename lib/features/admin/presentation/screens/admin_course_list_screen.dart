import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/admin_config.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/course_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/syllabus_provider.dart';
import '../../../../shared/widgets/card_container.dart';
import '../widgets/admin_course_helpers.dart';
import '../widgets/admin_course_tile.dart';
import '../widgets/admin_shared_widgets.dart';
import '../../../../shared/widgets/app_scaffold.dart';

class AdminCourseListScreen extends ConsumerWidget {
  const AdminCourseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).asData?.value;
    final coursesAsync = ref.watch(allCoursesProvider);
    final courses = coursesAsync.value ?? const [];

    if (coursesAsync.hasValue && !adminCanAccessCourseList(user, courses)) {
      return AppScaffold(
        body: Center(
          child: Text(
            l10n.adminNotAuthorized,
            style: AppTextStyles.bodyMedium(context),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final isFullAdmin =
        AdminConfig.isFullAdmin(user?.uid, role: user?.role);

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AdminAppBar(title: l10n.adminCoursesTitle),
      floatingActionButton: isFullAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.adminCourseForm),
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.emeraldDeep,
              icon: Icon(Icons.add, size: 20.r),
              label: Text(
                l10n.adminCourseCreateTitle,
                style: AppTextStyles.button(context).copyWith(
                  color: AppColors.emeraldDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      body: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
        children: [
          AdminScreenHeader(
            subtitle: l10n.adminSectionTitle.toUpperCase(),
            title: l10n.adminCoursesTitle,
          ),
          SizedBox(height: 18.h),
          coursesAsync.when(
            loading: () => const AdminListShimmer(),
            error: (_, _) => CardContainer(
              child: Text(
                l10n.adminCourseLoadFailed,
                style: AppTextStyles.bodyMedium(context),
              ),
            ),
            data: (courses) {
              final visibleCourses = adminVisibleCourses(user, courses);
              if (visibleCourses.isEmpty) {
                return _AdminCourseEmptyList(message: l10n.adminCourseEmptyList);
              }
              return Column(
                children: visibleCourses
                    .map((course) => _AdminCourseRow(course: course))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminCourseEmptyList extends StatelessWidget {
  const _AdminCourseEmptyList({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 20.w),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            color: AppColors.gold,
            size: 36.r,
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(context),
          ),
        ],
      ),
    );
  }
}

class _AdminCourseRow extends ConsumerWidget {
  const _AdminCourseRow({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).asData?.value;
    final service = ref.read(syllabusServiceProvider);
    final canPublish = AdminConfig.isFullAdmin(user?.uid, role: user?.role);

    return AdminCourseTile(
      course: course,
      onTap: () => context.push(AppRoutes.adminCourseForm, extra: course),
      onManageLessons: () =>
          context.push(AppRoutes.adminLessonsPath(course.id)),
      onTogglePublished: canPublish
          ? (value) async {
              final adminUid = user?.uid;
              try {
                if (value) {
                  await service.publishCourse(course.id);
                  if (adminUid != null) {
                    unawaited(
                      notifyCoursePublishedPush(
                        ref: ref,
                        adminUid: adminUid,
                        courseTitle: course.title,
                        pushTitle: l10n.adminCoursePublishedPushTitle,
                        pushMessage:
                            l10n.adminCoursePublishedPushMessage(course.title),
                      ),
                    );
                  }
                } else {
                  await service.unpublishCourse(course.id);
                }
              } catch (_) {
                if (!context.mounted) return;
                showAdminSnackBar(
                  context,
                  message: l10n.adminCoursePublishFailed,
                  isError: true,
                );
              }
            }
          : null,
      onDismissed: canPublish
          ? () async {
              try {
                await service.deleteCourse(course.id);
              } catch (_) {
                if (!context.mounted) return;
                showAdminSnackBar(
                  context,
                  message: l10n.adminCourseDeleteFailed,
                  isError: true,
                );
              }
            }
          : null,
    );
  }
}

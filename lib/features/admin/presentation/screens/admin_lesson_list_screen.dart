import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/admin_config.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/lesson_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/syllabus_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../widgets/admin_course_helpers.dart';
import '../widgets/admin_lesson_tile.dart';
import '../widgets/admin_quiz_list_section.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminLessonListScreen extends ConsumerStatefulWidget {
  const AdminLessonListScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<AdminLessonListScreen> createState() =>
      _AdminLessonListScreenState();
}

class _AdminLessonListScreenState extends ConsumerState<AdminLessonListScreen> {
  bool _isReordering = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).asData?.value;
    final courseAsync = ref.watch(courseProvider(widget.courseId));
    final course = courseAsync.value;

    if (course != null &&
        !AdminConfig.canModerateCourse(user?.uid, course, role: user?.role)) {
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

    if (courseAsync.hasValue &&
        course == null &&
        !AdminConfig.canAccessCourseAdmin(user?.uid, role: user?.role)) {
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

    final lessonsAsync = ref.watch(courseLessonsProvider(widget.courseId));
    final courseTitle = courseAsync.value?.title ?? l10n.adminLessonsTitle;

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AdminAppBar(
        title: l10n.adminLessonsTitle,
        fallbackRoute: AppRoutes.adminCourses,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          AppRoutes.adminLessonForm,
          extra: AdminLessonFormArgs(courseId: widget.courseId),
        ),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.emeraldDeep,
        icon: Icon(Icons.add, size: 20.r),
        label: Text(
          l10n.adminLessonCreateTitle,
          style: AppTextStyles.button(context).copyWith(
            color: AppColors.emeraldDeep,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
        children: [
          AdminScreenHeader(
            subtitle: l10n.adminCoursesTitle.toUpperCase(),
            title: courseTitle,
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.adminLessonsSubtitle,
            style: AppTextStyles.bodySmall(context),
          ),
          SizedBox(height: 18.h),
          if (_isReordering)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: LinearProgressIndicator(
                color: AppColors.gold,
                backgroundColor: AppColors.cardBorder,
              ),
            ),
          lessonsAsync.when(
            loading: () => const AdminListShimmer(),
            error: (_, _) => CardContainer(
              child: Text(
                l10n.adminLessonLoadFailed,
                style: AppTextStyles.bodyMedium(context),
              ),
            ),
            data: (lessons) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (lessons.isEmpty)
                    CardContainer(
                      padding: EdgeInsets.symmetric(
                        vertical: 32.h,
                        horizontal: 20.w,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.playlist_play_outlined,
                            color: AppColors.gold,
                            size: 36.r,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            l10n.adminLessonEmptyList,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium(context),
                          ),
                        ],
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: lessons.length,
                      onReorder: (oldIndex, newIndex) =>
                          _onReorder(context, lessons, oldIndex, newIndex),
                      itemBuilder: (context, index) {
                        final lesson = lessons[index];
                        return _AdminLessonRow(
                          key: ValueKey<String>(lesson.id),
                          lesson: lesson,
                          index: index,
                          courseId: widget.courseId,
                        );
                      },
                    ),
                  SizedBox(height: 24.h),
                  AdminQuizListSection(
                    courseId: widget.courseId,
                    lessons: lessons,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /*
  Purpose:
  Persist a new lesson order after drag-and-drop reordering.

  Response:
  Updates local list optimistically; reverts on Firestore failure.

  Business Rules:
  - order field is zero-based index in the list.
  - Empty courseId is ignored by the service.

  Flow:
  1. Adjust newIndex for Flutter reorder semantics.
  2. Reorder local list copy.
  3. Call SyllabusService.reorderLessons with id list.

  Side Effects:
  - Batch-updates lesson order fields in Firestore.

  Failure Cases:
  - Firestore write failure shows error snackbar.
  */
  Future<void> _onReorder(
    BuildContext context,
    List<LessonModel> lessons,
    int oldIndex,
    int newIndex,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (newIndex > oldIndex) newIndex -= 1;

    final updated = List<LessonModel>.from(lessons);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    setState(() => _isReordering = true);
    try {
      await ref.read(syllabusServiceProvider).reorderLessons(
            widget.courseId,
            updated.map((l) => l.id).toList(),
          );
    } catch (_) {
      if (!context.mounted) return;
      showAdminSnackBar(
        context,
        message: l10n.adminLessonReorderFailed,
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isReordering = false);
    }
  }
}

class _AdminLessonRow extends ConsumerWidget {
  const _AdminLessonRow({
    super.key,
    required this.lesson,
    required this.index,
    required this.courseId,
  });

  final LessonModel lesson;
  final int index;
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(syllabusServiceProvider);

    return AdminLessonTile(
      lesson: lesson,
      index: index,
      onTap: () => context.push(
        AppRoutes.adminLessonForm,
        extra: AdminLessonFormArgs(courseId: courseId, lesson: lesson),
      ),
      onTogglePublished: (value) async {
        try {
          await service.updateLesson(lesson.copyWith(isPublished: value));
        } catch (_) {
          if (!context.mounted) return;
          showAdminSnackBar(
            context,
            message: l10n.adminToggleFailed,
            isError: true,
          );
        }
      },
      onDismissed: () async {
        try {
          await service.deleteLesson(courseId, lesson.id);
        } catch (_) {
          if (!context.mounted) return;
          showAdminSnackBar(
            context,
            message: l10n.adminLessonDeleteFailed,
            isError: true,
          );
        }
      },
    );
  }
}

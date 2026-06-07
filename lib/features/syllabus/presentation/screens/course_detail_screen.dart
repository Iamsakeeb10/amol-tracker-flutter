import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/user_progress_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/quiz_provider.dart';
import '../../../../providers/syllabus_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/streak_badge.dart';
import '../widgets/course_progress_header.dart';
import '../widgets/course_quiz_list_section.dart';
import '../widgets/course_certificate_sheet.dart';
import '../widgets/syllabus_helpers.dart';
import '../widgets/syllabus_lesson_tile.dart';

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  /*
  Purpose:
  Show published course info, enrollment/progress, and lesson list for students.

  Response:
  Scrollable detail view with enroll CTA or progress bar.

  Business Rules:
  - Only published lessons appear in the list.
  - Enrollment required before lesson completion icons show.
  - Enroll requires signed-in user; otherwise redirect to sign-in.

  Flow:
  1. Stream course + published lessons + user progress.
  2. Render header, description, progress/enroll section.
  3. List lessons with completion state when enrolled.

  Side Effects:
  - enroll() writes userProgress via syllabusCourseActionsProvider.

  Failure Cases:
  - Missing course shows load error state.
  - Enroll failure surfaces snackbar from notifier error.
  */
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final courseAsync = ref.watch(courseProvider(courseId));
    final lessonsAsync = ref.watch(publishedCourseLessonsProvider(courseId));
    final progressAsync = ref.watch(currentUserCourseProgressProvider(courseId));
    final actionState = ref.watch(syllabusCourseActionsProvider(courseId));
    final courseQuizzesAsync = ref.watch(courseLevelQuizzesProvider(courseId));
    final courseQuizzes = filterPlayableQuizzes(
      courseQuizzesAsync.value ?? const [],
    );

    ref.listen(syllabusCourseActionsProvider(courseId), (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return AppScaffold(
      handleExitBack: false,
      padding: EdgeInsets.zero,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.syllabus);
            }
          },
        ),
        title: courseAsync.maybeWhen(
          data: (course) => Text(
            course?.title ?? l10n.syllabusTitle,
            style: AppTextStyles.headlineMedium(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          orElse: () => Text(
            l10n.syllabusTitle,
            style: AppTextStyles.headlineMedium(context),
          ),
        ),
      ),
      body: courseAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (_, _) => Center(
          child: Text(
            l10n.syllabusCourseLoadFailed,
            style: AppTextStyles.bodyMedium(context),
          ),
        ),
        data: (course) {
          if (course == null || !course.isPublished) {
            return Center(
              child: Text(
                l10n.syllabusCourseLoadFailed,
                style: AppTextStyles.bodyMedium(context),
              ),
            );
          }

          final lessons = lessonsAsync.value ?? const [];
          final progress = progressAsync.value;
          final isEnrolled = progress != null;
          final user = ref.watch(currentUserProvider).asData?.value;

          return CustomScrollView(
            slivers: [
              if (course.coverImageUrl.trim().isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg.r),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          course.coverImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _CoverPlaceholder(),
                        ),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: AppTextStyles.displayMedium(context).copyWith(
                          fontSize: 22.sp,
                        ),
                      ),
                      if (course.description.trim().isNotEmpty) ...[
                        SizedBox(height: 10.h),
                        Text(
                          course.description,
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (course.tags.isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: course.tags
                              .map(
                                (tag) => Pill(
                                  text: tag,
                                  color: AppColors.goldCard,
                                  textColor: AppColors.gold,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 16.h),
                  child: CourseProgressHeader(
                    courseId: courseId,
                    isEnrolling: actionState.isBusy,
                    onEnroll: () => _handleEnroll(context, ref),
                  ),
                ),
              ),
              if (progress?.isCourseCompleted == true)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: user == null
                            ? null
                            : () => CourseCertificateSheet.show(
                                  context,
                                  courseTitle: course.title,
                                  userName: user.name,
                                  completedAt:
                                      progress!.completedAt ?? DateTime.now(),
                                ),
                        icon: Icon(Icons.workspace_premium_outlined, size: 18.r),
                        label: Text(l10n.courseCertificateView),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.gold,
                          side: const BorderSide(color: AppColors.gold),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 8.h),
                  child: SectionHeader(
                    title: l10n.syllabusLessonsSection,
                    trailingText: lessons.isEmpty
                        ? null
                        : l10n.syllabusLessonCount(lessons.length),
                  ),
                ),
              ),
              if (lessons.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                    child: Text(
                      l10n.syllabusNoLessons,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final lesson = lessons[index];
                        return SyllabusLessonTile(
                          lesson: lesson,
                          index: index,
                          isEnrolled: isEnrolled,
                          isCompleted: _isLessonCompleted(progress, lesson.id),
                          onTap: () => context.push(
                            AppRoutes.lessonViewerPath(courseId, lesson.id),
                          ),
                        );
                      },
                      childCount: lessons.length,
                    ),
                  ),
                ),
              CourseQuizListSection(courseId: courseId, quizzes: courseQuizzes),
              if (courseQuizzes.isEmpty)
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleEnroll(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) {
      context.push(AppRoutes.signIn);
      return;
    }

    final success =
        await ref.read(syllabusCourseActionsProvider(courseId).notifier).enroll();
    if (!context.mounted || !success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.syllabusEnrollSuccess)),
    );
  }

  bool _isLessonCompleted(UserProgressModel? progress, String lessonId) {
    if (progress == null) return false;
    return progress.isLessonCompleted(lessonId);
  }
}

class _CoverPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBorder,
      alignment: Alignment.center,
      child: Icon(
        Icons.menu_book_outlined,
        size: 40.r,
        color: AppColors.gold.withValues(alpha: 0.5),
      ),
    );
  }
}

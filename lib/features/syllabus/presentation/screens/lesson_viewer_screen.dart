import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/youtube_url_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/lesson_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/quiz_provider.dart';
import '../../../../providers/syllabus_provider.dart';
import '../../../admin/presentation/widgets/admin_course_helpers.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../widgets/lesson_complete_bar.dart';
import '../widgets/lesson_content_view.dart';
import '../widgets/lesson_youtube_player.dart';
import '../widgets/syllabus_helpers.dart';
import '../widgets/syllabus_quiz_tile.dart';
import '../../../../shared/widgets/section_header.dart';

class LessonViewerScreen extends ConsumerWidget {
  const LessonViewerScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  final String courseId;
  final String lessonId;

  /*
  Purpose:
  Render a single lesson resource and let enrolled students mark it complete.

  Response:
  Scrollable viewer with resource-specific content and completion bar.

  Business Rules:
  - Only published lessons are shown; missing docs show error state.
  - YouTube lessons require a valid video URL.
  - Mark complete requires sign-in, enrollment, and incomplete lesson state.

  Flow:
  1. Stream lesson + user progress for the course.
  2. Render title, description, and typed content widget.
  3. Handle mark complete via syllabusCourseActionsProvider.

  Side Effects:
  - markLessonComplete writes userProgress in Firestore.

  Failure Cases:
  - Missing lesson, invalid YouTube URL, launch failures, save errors.
  */
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lessonRef = (courseId: courseId, lessonId: lessonId);
    final lessonAsync = ref.watch(lessonProvider(lessonRef));
    final progress = ref.watch(currentUserCourseProgressProvider(courseId)).value;
    final actionState = ref.watch(syllabusCourseActionsProvider(courseId));
    final lessonQuizzes = filterPlayableQuizzes(
      ref
              .watch(lessonQuizzesProvider((
                courseId: courseId,
                lessonId: lessonId,
              )))
              .value ??
          const [],
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
      safeAreaBottom: false,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.courseDetailPath(courseId));
            }
          },
        ),
        title: lessonAsync.maybeWhen(
          data: (lesson) => Text(
            lesson?.title ?? l10n.syllabusLessonsSection,
            style: AppTextStyles.headlineMedium(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          orElse: () => Text(
            l10n.syllabusLessonsSection,
            style: AppTextStyles.headlineMedium(context),
          ),
        ),
      ),
      body: lessonAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (_, _) => Center(
          child: Text(
            l10n.syllabusLessonLoadFailed,
            style: AppTextStyles.bodyMedium(context),
          ),
        ),
        data: (lesson) {
          if (lesson == null || !lesson.isPublished) {
            return Center(
              child: Text(
                l10n.syllabusLessonLoadFailed,
                style: AppTextStyles.bodyMedium(context),
              ),
            );
          }

          if (lesson.resourceType == LessonResourceType.youtube &&
              extractYoutubeVideoId(lesson.resourceUrl) == null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  l10n.syllabusInvalidYoutubeUrl,
                  style: AppTextStyles.bodyMedium(context),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final isEnrolled = progress != null;
          final isCompleted = progress?.isLessonCompleted(lessonId) ?? false;
          final isYoutube = lesson.resourceType == LessonResourceType.youtube;

          return Column(
            children: [
              if (isYoutube)
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                  child: LessonYoutubePlayer(
                    videoUrl: lesson.resourceUrl,
                    title: lesson.title,
                    captionLanguage:
                        Localizations.localeOf(context).languageCode,
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                  children: [
                    Row(
                      children: [
                        Icon(
                          iconForResourceType(lesson.resourceType),
                          size: 18.r,
                          color: AppColors.goldLight,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          resourceTypeLabel(l10n, lesson.resourceType),
                          style: AppTextStyles.bodySmall(context),
                        ),
                        if (lesson.durationMinutes > 0) ...[
                          const Spacer(),
                          Text(
                            '${lesson.durationMinutes} min',
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (lesson.description.trim().isNotEmpty &&
                        lesson.resourceType != LessonResourceType.text) ...[
                      SizedBox(height: 12.h),
                      Text(
                        lesson.description,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                    if (!isYoutube) ...[
                      SizedBox(height: 16.h),
                      LessonContentView(
                        lesson: lesson,
                        onLaunchFailed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.syllabusLaunchUrlFailed),
                            ),
                          );
                        },
                      ),
                    ],
                    if (lessonQuizzes.isNotEmpty) ...[
                      SizedBox(height: 24.h),
                      SectionHeader(title: l10n.syllabusQuizTitle),
                      SizedBox(height: 8.h),
                      ...lessonQuizzes.map(
                        (quiz) => SyllabusQuizTile(
                          courseId: courseId,
                          quiz: quiz,
                          onTap: () => context.push(
                            AppRoutes.quizIntroPath(courseId, quiz.id),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              LessonCompleteBar(
                isEnrolled: isEnrolled,
                isCompleted: isCompleted,
                isBusy: actionState.isBusy,
                onMarkComplete: () => _handleMarkComplete(context, ref, l10n),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleMarkComplete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) {
      context.push(AppRoutes.signIn);
      return;
    }

    final progress = ref.read(currentUserCourseProgressProvider(courseId)).value;
    if (progress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.syllabusEnrollToComplete)),
      );
      return;
    }

    final success = await ref
        .read(syllabusCourseActionsProvider(courseId).notifier)
        .markLessonComplete(lessonId);
    if (!context.mounted || !success) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.syllabusLessonCompleteSuccess)),
    );
  }
}

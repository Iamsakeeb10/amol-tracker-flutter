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
import '../../../../providers/quiz_provider.dart';
import '../../../../providers/syllabus_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../widgets/lesson_viewer_actions.dart';
import '../widgets/lesson_viewer_body.dart';
import '../widgets/syllabus_helpers.dart';

class LessonViewerScreen extends ConsumerStatefulWidget {
  const LessonViewerScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  final String courseId;
  final String lessonId;

  @override
  ConsumerState<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends ConsumerState<LessonViewerScreen> {
  String get courseId => widget.courseId;
  String get lessonId => widget.lessonId;

  @override
  Widget build(BuildContext context) {
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

          if (lesson.resourceType == LessonResourceType.audio &&
              lesson.resourceUrl.trim().isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  l10n.syllabusAudioLoadFailed,
                  style: AppTextStyles.bodyMedium(context),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return LessonViewerBody(
            lesson: lesson,
            courseId: courseId,
            lessonId: lessonId,
            isEnrolled: isEnrolled,
            isCompleted: isCompleted,
            isBusy: actionState.isBusy,
            lessonQuizzes: lessonQuizzes,
            onMarkComplete: () => handleLessonMarkComplete(
              context: context,
              ref: ref,
              l10n: l10n,
              courseId: courseId,
              lessonId: lessonId,
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/lesson_model.dart';
import '../../../../models/quiz_model.dart';
import '../../../admin/presentation/widgets/admin_course_helpers.dart';
import '../widgets/lesson_audio_player.dart';
import '../widgets/lesson_complete_bar.dart';
import '../widgets/lesson_content_view.dart';
import '../widgets/lesson_youtube_player.dart';
import '../widgets/syllabus_quiz_tile.dart';
import '../../../../shared/widgets/section_header.dart';

class LessonViewerBody extends StatelessWidget {
  const LessonViewerBody({
    super.key,
    required this.lesson,
    required this.courseId,
    required this.lessonId,
    required this.isEnrolled,
    required this.isCompleted,
    required this.isBusy,
    required this.lessonQuizzes,
    required this.onMarkComplete,
  });

  final LessonModel lesson;
  final String courseId;
  final String lessonId;
  final bool isEnrolled;
  final bool isCompleted;
  final bool isBusy;
  final List<QuizModel> lessonQuizzes;
  final VoidCallback onMarkComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isYoutube = lesson.resourceType == LessonResourceType.youtube;
    final isAudio = lesson.resourceType == LessonResourceType.audio;

    return Column(
      children: [
        if (isYoutube)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
            child: LessonYoutubePlayer(
              videoUrl: lesson.resourceUrl,
              title: lesson.title,
              captionLanguage: Localizations.localeOf(context).languageCode,
            ),
          ),
        if (isAudio)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
            child: LessonAudioPlayer(
              audioUrl: lesson.resourceUrl,
              title: lesson.title,
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
              if (!isYoutube && !isAudio) ...[
                SizedBox(height: 16.h),
                LessonContentView(
                  lesson: lesson,
                  onLaunchFailed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.syllabusLaunchUrlFailed)),
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
          isBusy: isBusy,
          onMarkComplete: onMarkComplete,
        ),
      ],
    );
  }
}

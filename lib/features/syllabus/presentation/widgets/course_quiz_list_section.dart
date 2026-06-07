import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/quiz_model.dart';
import '../../../../shared/widgets/section_header.dart';
import 'syllabus_quiz_tile.dart';

class CourseQuizListSection extends StatelessWidget {
  const CourseQuizListSection({
    super.key,
    required this.courseId,
    required this.quizzes,
  });

  final String courseId;
  final List<QuizModel> quizzes;

  @override
  Widget build(BuildContext context) {
    if (quizzes.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final l10n = AppLocalizations.of(context)!;

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 8.h),
            child: SectionHeader(title: l10n.syllabusQuizTitle),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final quiz = quizzes[index];
                return SyllabusQuizTile(
                  courseId: courseId,
                  quiz: quiz,
                  onTap: () => context.push(
                    AppRoutes.quizIntroPath(courseId, quiz.id),
                  ),
                );
              },
              childCount: quizzes.length,
            ),
          ),
        ),
      ],
    );
  }
}

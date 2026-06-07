import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/lesson_model.dart';
import '../../../../models/quiz_model.dart';

const kDefaultMcqOptionCount = 4;
const kMinMcqOptions = 2;

class AdminQuizFormArgs {
  const AdminQuizFormArgs({
    required this.courseId,
    this.lessonId,
    this.quiz,
  });

  final String courseId;
  final String? lessonId;
  final QuizModel? quiz;
}

class AdminQuestionEditorArgs {
  const AdminQuestionEditorArgs({
    this.question,
    this.questionIndex,
  });

  final QuizQuestion? question;
  final int? questionIndex;
}

String generateQuestionId() =>
    'q${DateTime.now().millisecondsSinceEpoch}';

String quizScopeLabel(AppLocalizations l10n, {String? lessonTitle}) {
  if (lessonTitle == null || lessonTitle.isEmpty) {
    return l10n.adminQuizScopeCourse;
  }
  return lessonTitle;
}

class AdminLessonPicker extends StatelessWidget {
  const AdminLessonPicker({
    super.key,
    required this.lessons,
    required this.selectedLessonId,
    required this.onChanged,
  });

  final List<LessonModel> lessons;
  final String? selectedLessonId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Text(
            l10n.adminQuizLinkedLesson,
            style: AppTextStyles.label(context),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ScopePill(
                label: l10n.adminQuizScopeCourse,
                icon: Icons.school_outlined,
                isSelected: selectedLessonId == null,
                onTap: () => onChanged(null),
              ),
              ...lessons.map(
                (lesson) => _ScopePill(
                  label: lesson.title,
                  icon: Icons.play_lesson_outlined,
                  isSelected: selectedLessonId == lesson.id,
                  onTap: () => onChanged(lesson.id),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScopePill extends StatelessWidget {
  const _ScopePill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99.r),
        child: Container(
          constraints: BoxConstraints(maxWidth: 180.w),
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
                icon,
                size: 14.r,
                color: isSelected ? AppColors.gold : AppColors.textMuted,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pill(context).copyWith(
                    color: isSelected
                        ? AppColors.gold
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

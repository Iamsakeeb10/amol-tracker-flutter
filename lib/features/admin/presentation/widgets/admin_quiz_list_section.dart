import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/lesson_model.dart';
import '../../../../models/quiz_model.dart';
import '../../../../providers/quiz_provider.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import 'admin_quiz_helpers.dart';
import 'admin_shared_widgets.dart';

class AdminQuizListSection extends ConsumerWidget {
  const AdminQuizListSection({
    super.key,
    required this.courseId,
    required this.lessons,
  });

  final String courseId;
  final List<LessonModel> lessons;

  String _scopeLabel(AppLocalizations l10n, QuizModel quiz) {
    if (quiz.isCourseLevel) return l10n.adminQuizScopeCourse;
    final lesson = lessons.where((l) => l.id == quiz.lessonId).firstOrNull;
    return lesson?.title ?? l10n.adminQuizScopeCourse;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final quizzesAsync = ref.watch(courseQuizzesProvider(courseId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.adminQuizTitle.toUpperCase()),
        SizedBox(height: 8.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push(
              AppRoutes.adminQuizForm,
              extra: AdminQuizFormArgs(courseId: courseId),
            ),
            icon: Icon(Icons.add_rounded, size: 18.r),
            label: Text(l10n.adminQuizCreateTitle),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.goldBorder),
              foregroundColor: AppColors.goldLight,
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        quizzesAsync.when(
          loading: () => const AdminListShimmer(),
          error: (_, _) => CardContainer(
            child: Text(
              l10n.syllabusQuizLoadFailed,
              style: AppTextStyles.bodyMedium(context),
            ),
          ),
          data: (quizzes) {
            if (quizzes.isEmpty) {
              return CardContainer(
                padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
                child: Text(
                  l10n.adminQuizEmptyList,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              );
            }
            return Column(
              children: quizzes
                  .map(
                    (quiz) => _AdminQuizRow(
                      quiz: quiz,
                      scopeLabel: _scopeLabel(l10n, quiz),
                      onTap: () => context.push(
                        AppRoutes.adminQuizForm,
                        extra: AdminQuizFormArgs(
                          courseId: courseId,
                          lessonId: quiz.lessonId,
                          quiz: quiz,
                        ),
                      ),
                      onDelete: () async {
                        try {
                          await ref
                              .read(quizServiceProvider)
                              .deleteQuiz(courseId, quiz.id);
                        } catch (_) {
                          if (!context.mounted) return;
                          showAdminSnackBar(
                            context,
                            message: l10n.adminSaveFailed,
                            isError: true,
                          );
                        }
                      },
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _AdminQuizRow extends StatelessWidget {
  const _AdminQuizRow({
    required this.quiz,
    required this.scopeLabel,
    required this.onTap,
    required this.onDelete,
  });

  final QuizModel quiz;
  final String scopeLabel;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Dismissible(
        key: ValueKey<String>(quiz.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.w),
          decoration: BoxDecoration(
            color: AppColors.dangerLight,
            borderRadius: BorderRadius.circular(AppRadius.lg.r),
          ),
          child: Icon(Icons.delete_outline, color: AppColors.danger, size: 20.r),
        ),
        confirmDismiss: (_) async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.emeraldDeep,
              title: Text(
                l10n.adminQuizQuestionDeleteTitle,
                style: AppTextStyles.headlineMedium(ctx),
              ),
              content: Text(
                l10n.adminDeleteConfirm,
                style: AppTextStyles.bodyMedium(ctx),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    l10n.delete,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          );
          return confirmed ?? false;
        },
        onDismissed: (_) => onDelete(),
        child: CardContainer(
          onTap: onTap,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              AdminIconBox(icon: Icons.quiz_outlined),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '$scopeLabel · ${l10n.syllabusQuizQuestionCount(quiz.questionCount)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20.r),
            ],
          ),
        ),
      ),
    );
  }
}

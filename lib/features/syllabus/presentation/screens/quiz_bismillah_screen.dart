import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/quiz_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';

class QuizBismillahScreen extends ConsumerWidget {
  const QuizBismillahScreen({
    super.key,
    required this.courseId,
    required this.quizId,
  });

  final String courseId;
  final String quizId;

  QuizRef get _quizRef => (courseId: courseId, quizId: quizId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(quizSessionProvider(_quizRef));

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
              context.go(AppRoutes.quizIntroPath(courseId, quizId));
            }
          },
        ),
        title: Text(
          l10n.syllabusQuizBismillahTitle,
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              CardContainer(
                child: Column(
                  children: [
                    Text(
                      l10n.syllabusQuizBismillahArabic,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displayMedium(context).copyWith(
                        fontSize: 28.sp,
                        height: 1.8,
                        color: AppColors.gold,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      l10n.syllabusQuizBismillahTranslation,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Divider(color: AppColors.cardBorder.withValues(alpha: 0.6)),
                    SizedBox(height: 16.h),
                    Text(
                      l10n.syllabusQuizBismillahIntention,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.textPrimary,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: session.quiz == null
                      ? null
                      : () => _handleBegin(context, ref),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.emeraldDeep,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: Text(
                    l10n.syllabusQuizBismillahBegin,
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.emeraldDeep,
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleBegin(BuildContext context, WidgetRef ref) {
    final quiz = ref.read(quizSessionProvider(_quizRef)).quiz;
    if (quiz == null || quiz.questionCount == 0) return;

    ref.read(quizSessionProvider(_quizRef).notifier).startSession();
    context.push(AppRoutes.quizPlayPath(courseId, quizId));
  }
}

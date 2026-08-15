import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../battle/models/question_model.dart';
import 'admin_battle_question_form_screen.dart';

final adminQuestionsStreamProvider = StreamProvider.family<List<QuestionModel>, String>((ref, topicId) {
  return FirebaseFirestore.instance
      .collection('topics')
      .doc(topicId)
      .collection('questions')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => QuestionModel.fromJson({...doc.data(), 'id': doc.id})).toList();
  });
});

class AdminBattleQuestionsScreen extends ConsumerWidget {
  final String topicId;
  const AdminBattleQuestionsScreen({super.key, required this.topicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(adminQuestionsStreamProvider(topicId));

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Questions',
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/admin/battle-topics/$topicId/questions/new');
        },
        backgroundColor: AppColors.gold,
        icon: Icon(Icons.add, color: AppColors.emeraldDeep),
        label: Text(
          'New Question',
          style: TextStyle(color: AppColors.emeraldDeep, fontWeight: FontWeight.bold),
        ),
      ),
      body: questionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return Center(child: Text('No questions yet. Add one!', style: AppTextStyles.bodyMedium(context)));
          }
          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h).copyWith(bottom: 100.h),
            itemCount: questions.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final question = questions[index];
              return _AdminQuestionCard(topicId: topicId, question: question);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, st) => Center(child: Text('Error loading questions: $e', style: TextStyle(color: AppColors.danger))),
      ),
    );
  }
}

class _AdminQuestionCard extends StatelessWidget {
  final String topicId;
  final QuestionModel question;
  const _AdminQuestionCard({required this.topicId, required this.question});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push('/admin/battle-topics/$topicId/questions/${question.id}', extra: question);
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.emeraldMid,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: question.isActive ? AppColors.emeraldDeep.withOpacity(0.1) : AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                question.isActive ? Icons.check_circle : Icons.cancel,
                color: question.isActive ? AppColors.emeraldLight : AppColors.danger,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.text.isNotEmpty ? question.text : 'No Text',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Difficulty: ${question.difficulty.toUpperCase()}',
                    style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

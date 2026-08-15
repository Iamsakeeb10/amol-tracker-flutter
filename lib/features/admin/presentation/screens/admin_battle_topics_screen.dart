import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../battle/models/topic_model.dart';
import 'admin_battle_topic_form_screen.dart';

final adminTopicsStreamProvider = StreamProvider<List<TopicModel>>((ref) {
  return FirebaseFirestore.instance.collection('topics').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => TopicModel.fromJson({...doc.data(), 'id': doc.id})).toList();
  });
});

class AdminBattleTopicsScreen extends ConsumerWidget {
  const AdminBattleTopicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(adminTopicsStreamProvider);

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Manage Topics',
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTopicForm(context),
        backgroundColor: AppColors.gold,
        icon: Icon(Icons.add, color: AppColors.emeraldDeep),
        label: Text(
          'New Topic',
          style: TextStyle(color: AppColors.emeraldDeep, fontWeight: FontWeight.bold),
        ),
      ),
      body: topicsAsync.when(
        data: (topics) {
          if (topics.isEmpty) {
            return Center(child: Text('No topics found. Create one!', style: AppTextStyles.bodyMedium(context)));
          }
          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h).copyWith(bottom: 100.h),
            itemCount: topics.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final topic = topics[index];
              return _AdminTopicCard(topic: topic);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, st) => Center(child: Text('Error loading topics', style: TextStyle(color: AppColors.danger))),
      ),
    );
  }

  void _showTopicForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AdminBattleTopicFormScreen(),
    );
  }
}

class _AdminTopicCard extends StatelessWidget {
  final TopicModel topic;
  const _AdminTopicCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push('/admin/battle-topics/${topic.id}/questions');
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.emeraldMid,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Opacity(
              opacity: topic.isActive ? 1.0 : 0.5,
              child: Icon(Icons.menu_book, color: AppColors.gold, size: 32.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.name,
                    style: AppTextStyles.titleMedium(context).copyWith(
                      color: topic.isActive ? AppColors.textPrimary : AppColors.textMuted,
                      decoration: topic.isActive ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${topic.questionCount} Questions',
                    style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AdminBattleTopicFormScreen(existingTopic: topic),
                );
              },
              icon: Icon(Icons.edit, color: AppColors.textMuted, size: 20.sp),
            ),
          ],
        ),
      ),
    );
  }
}

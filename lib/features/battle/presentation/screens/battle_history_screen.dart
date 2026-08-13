import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../providers/locale_provider.dart';
import '../../providers/battle_providers.dart';
import '../../providers/topic_providers.dart';
import 'package:intl/intl.dart';

class BattleHistoryScreen extends ConsumerWidget {
  const BattleHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).languageCode;
    final isBn = locale == 'bn';
    final historyAsync = ref.watch(battleHistoryProvider);
    final activeTopics = ref.watch(activeTopicsProvider).asData?.value ?? [];

    return AppScaffold(
      handleExitBack: false,
      appBar: AppBar(
        title: Text(isBn ? 'ব্যাটেল হিস্ট্রি' : 'Battle History', style: AppTextStyles.headlineMedium(context)),
      ),
      body: historyAsync.when(
        data: (historyList) {
          if (historyList.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_toggle_off,
                      size: 64.r,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      isBn ? 'কোনো হিস্ট্রি নেই' : 'No history yet',
                      style: AppTextStyles.titleMedium(context).copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      isBn
                          ? 'আপনার প্রথম নলেজ ব্যাটেল শুরু করুন!'
                          : 'Play your first Knowledge Battle!',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.emeraldDeep,
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.w, vertical: 12.h),
                        textStyle: AppTextStyles.labelLarge(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        context.push(AppRoutes.battleHome);
                      },
                      child: Text(isBn ? 'নতুন ব্যাটেল' : 'New Battle'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(20.w),
            itemCount: historyList.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final item = historyList[index];
              final topic = activeTopics.firstWhere(
                (t) => t.id == item.topicId,
                orElse: () => activeTopics.first, // fallback if not found
              );
              
              String resultText = '';
              Color resultColor = AppColors.textSecondary;
              if (item.result == 'win') {
                resultText = isBn ? 'বিজয়ী' : 'Victory';
                resultColor = AppColors.gold;
              } else if (item.result == 'loss') {
                resultText = isBn ? 'পরাজিত' : 'Defeat';
                resultColor = AppColors.danger;
              } else {
                resultText = isBn ? 'ড্র' : 'Draw';
                resultColor = AppColors.textPrimary;
              }

              return CardContainer(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.displayName(locale),
                            style: AppTextStyles.titleSmall(context).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          if (item.date != null)
                            Text(
                              DateFormat.yMMMd().format(item.date!),
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          resultText,
                          style: AppTextStyles.titleSmall(context).copyWith(
                            color: resultColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '+${item.score} XP',
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            isBn ? 'কিছু ভুল হয়েছে' : 'Something went wrong',
            style: AppTextStyles.bodyMedium(context),
          ),
        ),
      ),
    );
  }
}

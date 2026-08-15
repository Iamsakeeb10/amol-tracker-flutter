import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../providers/locale_provider.dart';
import '../../../../l10n/app_localizations.dart';
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
                    Container(
                      width: 88.r,
                      height: 88.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.history_toggle_off,
                        size: 40.r,
                        color: AppColors.gold,
                      ),
                    ),
                    SizedBox(height: 20.h),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
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
            padding: EdgeInsets.fromLTRB(0.w, 16.h, 0.w, 24.h),
            itemCount: historyList.length,
            separatorBuilder: (context, index) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              final item = historyList[index];
              final topic = activeTopics.where((t) => t.id == item.topicId).firstOrNull;

              late final IconData resultIcon;
              late final Color resultColor;
              late final String resultText;
              if (item.result == 'win') {
                resultIcon = Icons.emoji_events_rounded;
                resultColor = AppColors.gold;
                resultText = isBn ? 'বিজয়ী' : 'Victory';
              } else if (item.result == 'loss') {
                resultIcon = Icons.close_rounded;
                resultColor = AppColors.danger;
                resultText = isBn ? 'পরাজিত' : 'Defeat';
              } else {
                resultIcon = Icons.horizontal_rule_rounded;
                resultColor = AppColors.textSecondary;
                resultText = isBn ? 'ড্র' : 'Draw';
              }

              return GestureDetector(
                onTap: () {
                  context.push(AppRoutes.battleResultsPath(item.battleId), extra: {'fromHistory': true});
                },
                child: Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44.r,
                        height: 44.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: resultColor.withOpacity(0.12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(resultIcon, size: 22.r, color: resultColor),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic?.displayName(locale) ?? (isBn ? 'অজানা টপিক' : 'Unknown Topic'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleSmall(context).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (item.opponents.isNotEmpty) ...[
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Icon(Icons.people_alt_outlined,
                                      size: 13.r, color: AppColors.textSecondary),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      isBn
                                          ? item.opponents.map((e) => e.name).join(', ')
                                          : item.opponents.map((e) => e.name).join(', '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodySmall(context).copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (item.date != null) ...[
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined,
                                      size: 12.r, color: AppColors.textSecondary),
                                  SizedBox(width: 4.w),
                                  Text(
                                    DateFormat.yMMMd().format(item.date!),
                                    style: AppTextStyles.bodySmall(context).copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: resultColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              resultText,
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: resultColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            AppLocalizations.of(context)!.battleXpEarned(item.score),
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            isBn ? 'কিছু ভুল হয়েছে' : 'Something went wrong',
            style: AppTextStyles.bodyMedium(context),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/leaderboard_provider.dart';
import '../../../../shared/widgets/avatar_chip.dart';

class HomeTopPerformers extends ConsumerWidget {
  const HomeTopPerformers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dailyAsync = ref.watch(dailyLeaderboardProvider);
    final monthlyAsync = ref.watch(monthlyLeaderboardProvider);
    final authUid = ref.watch(authStateProvider).asData?.value?.uid;
    final languageCode = Localizations.localeOf(context).languageCode;
    final currentMonthName = IslamicDateService.getCurrentHijriMonthName(
      languageCode: languageCode,
    );

    return Row(
      children: [
        Expanded(
          child: _PerformerCard(
            title: l10n.todayTop,
            badgeLabel: l10n.todayLabel,
            icon: Icons.emoji_events,
            asyncData: dailyAsync,
            isDaily: true,
            currentUserId: authUid,
            onTap: () => context.push(AppRoutes.leaderboard, extra: 2),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _PerformerCard(
            title: l10n.monthTop,
            badgeLabel: currentMonthName,
            icon: Icons.star,
            asyncData: monthlyAsync,
            isDaily: false,
            currentUserId: authUid,
            onTap: () => context.push(AppRoutes.leaderboard, extra: 1),
          ),
        ),
      ],
    );
  }
}

class _PerformerCard extends StatelessWidget {
  const _PerformerCard({
    required this.title,
    required this.badgeLabel,
    required this.icon,
    required this.asyncData,
    required this.isDaily,
    required this.onTap,
    this.currentUserId,
  });

  final String title;
  final String badgeLabel;
  final IconData icon;
  final AsyncValue<List<LeaderboardEntry>> asyncData;
  final bool isDaily;
  final VoidCallback onTap;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: AppColors.gold, size: 14.r),
                    SizedBox(width: 6.w),
                    Text(
                      title,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: asyncData.isLoading
                        ? Shimmer.fromColors(
                            baseColor: AppColors.gold.withValues(alpha: 0.15),
                            highlightColor: AppColors.gold.withValues(alpha: 0.35),
                            child: Container(
                              height: 12.h,
                              width: 52.w,
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                            ),
                          )
                        : Text(
                            badgeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w500,
                              fontSize: 10.sp,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            asyncData.when(
              data: (entries) {
                if (entries.isEmpty || entries.first.score == 0) {
                  return SizedBox(
                    height: 30.h,
                    child: Center(
                      child: Text(
                        l10n.noOneYet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  );
                }
                final top = entries.first;
                final isMe = top.uid == currentUserId;
                
                final name = top.isAnonymousDisplay 
                    ? (isMe ? 'Me (Anonymous)' : 'Anonymous') 
                    : (isMe && top.displayName.isEmpty ? 'You' : top.displayName);
                
                final initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
                return Row(
                  children: [
                    AvatarChip(
                      initial: top.isAnonymousDisplay ? '🕌' : initial,
                      color: top.isAnonymousDisplay ? AppColors.cardBorder : (isDaily ? AppColors.gold : AppColors.emeraldMid),
                      size: 30,
                      fontSize: 11,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyMedium(context).copyWith(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (isMe) ...[
                                SizedBox(width: 4.w),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4.r),
                                    border: Border.all(
                                      color: AppColors.success.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)?.meLabel ?? 'Me',
                                    style: AppTextStyles.bodySmall(context).copyWith(
                                      color: AppColors.success,
                                      fontSize: 7.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${top.score} pts',
                            style: AppTextStyles.bodySmall(context).copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => Shimmer.fromColors(
                baseColor: AppColors.cardBorder.withValues(alpha: 0.4),
                highlightColor: AppColors.cardBorder.withValues(alpha: 0.9),
                child: Row(
                  children: [
                    // Avatar placeholder
                    Container(
                      width: 30.r,
                      height: 30.r,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name placeholder
                          Container(
                            height: 11.h,
                            width: 80.w,
                            decoration: BoxDecoration(
                              color: AppColors.cardBorder,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                          SizedBox(height: 5.h),
                          // Score placeholder
                          Container(
                            height: 9.h,
                            width: 44.w,
                            decoration: BoxDecoration(
                              color: AppColors.cardBorder,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              error: (_, __) => SizedBox(
                height: 30.h,
                child: Center(
                  child: Icon(Icons.error_outline, size: 16.r, color: AppColors.danger),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/date_provider.dart';
import '../../../../providers/notification_provider.dart';
import 'streak_bottom_sheet.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key, required this.streak, required this.uid});

  final int? streak;
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final unread = ref.watch(unreadNotificationsCountProvider);
    ref.watch(currentHijriDateProvider);
    final unreadLabel = unread > 99 ? '99+' : '$unread';
    final user = ref.watch(currentUserProvider).asData?.value;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.history),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            IslamicDateService.getDisplayIslamicDate(languageCode: locale),
            style: AppTextStyles.label(
              context,
            ).copyWith(color: AppColors.gold, fontSize: 11.sp),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  IslamicDateService.weekdayToday(languageCode: locale),
                  style: AppTextStyles.displayMedium(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              InkWell(
                onTap: () => StreakBottomSheet.show(context, uid: uid),
                borderRadius: BorderRadius.circular(99.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldCard,
                    border: Border.all(color: AppColors.goldBorder),
                    borderRadius: BorderRadius.circular(99.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: AppColors.warning,
                        size: 15.r,
                      ),
                      SizedBox(width: 4.w),
                      if (streak != null)
                        Text(
                          l10n.dayStreak(streak!),
                          style: AppTextStyles.pill(
                            context,
                          ).copyWith(color: AppColors.gold, fontSize: 11.sp),
                        )
                      else
                        Container(
                          width: 36.w,
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              InkWell(
                onTap: () => context.push(AppRoutes.notifications),
                borderRadius: BorderRadius.circular(12.r),
                child: Tooltip(
                  message: l10n.notifications,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 34.r,
                        height: 34.r,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.goldCard,
                          border: Border.all(color: AppColors.goldBorder),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.gold,
                          size: 20.r,
                        ),
                      ),
                      if (unread > 0)
                        Positioned(
                          right: -5.w,
                          top: -5.h,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(99.r),
                              border: Border.all(
                                color: AppColors.emeraldDeep,
                                width: 1.w,
                              ),
                            ),
                            constraints: BoxConstraints(minWidth: 16.r),
                            child: Text(
                              unreadLabel,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.pill(context).copyWith(
                                color: AppColors.emeraldDeep,
                                fontWeight: FontWeight.w700,
                                fontSize: 9.sp,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              InkWell(
                onTap: () => context.push(AppRoutes.profile),
                borderRadius: BorderRadius.circular(100.r),
                child: Tooltip(
                  message: l10n.profile,
                  child: Container(
                    width: 34.r,
                    height: 34.r,
                    decoration: BoxDecoration(
                      color: AppColors.goldCard,
                      border: Border.all(color: AppColors.goldBorder),
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: user?.photoUrl.isNotEmpty == true
                        ? Image.network(
                            user!.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.gold,
                              size: 20.r,
                            ),
                          )
                        : Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.gold,
                            size: 20.r,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

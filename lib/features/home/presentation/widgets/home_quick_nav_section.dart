import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/card_container.dart';

class HomeQuickNavSection extends StatelessWidget {
  const HomeQuickNavSection({super.key});

  static const _morningEveningCategoryUrl = 'morning-and-evening';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final items = [
      _QuickNavItem(
        icon: Icons.auto_stories_outlined,
        label: l10n.quranTitle,
        onTap: () => context.push(AppRoutes.quran),
      ),
      _QuickNavItem(
        icon: Icons.menu_book_outlined,
        label: l10n.navDua,
        onTap: () => context.push(AppRoutes.dua),
      ),
      _QuickNavItem(
        icon: Icons.wb_sunny_outlined,
        label: l10n.morningEveningDua,
        onTap: () => context.push(
          AppRoutes.dua,
          extra: _morningEveningCategoryUrl,
        ),
      ),
      _QuickNavItem(
        icon: Icons.leaderboard_outlined,
        label: l10n.leaderboard,
        onTap: () => context.push(AppRoutes.leaderboard),
      ),
      _QuickNavItem(
        icon: Icons.assessment_outlined,
        label: l10n.myReports,
        onTap: () => context.push(AppRoutes.reports),
      ),
      _QuickNavItem(
        icon: Icons.calendar_month_outlined,
        label: l10n.hijriCalendar,
        onTap: () => context.push(AppRoutes.hijriCalendar),
      ),
      _QuickNavItem(
        icon: Icons.explore_outlined,
        label: l10n.qiblaTitle,
        onTap: () => context.push(AppRoutes.qibla),
      ),
      _QuickNavItem(
        icon: Icons.fiber_manual_record_outlined,
        label: l10n.dhikrCounter,
        onTap: () => context.push(AppRoutes.dhikr),
      ),
      _QuickNavItem(
        icon: Icons.auto_awesome_outlined,
        label: l10n.asmaUlHusna,
        onTap: () => context.push(AppRoutes.asmaUlHusna),
      ),
      _QuickNavItem(
        icon: Icons.menu_book_outlined,
        label: l10n.syllabusTitle,
        onTap: () => context.push(AppRoutes.syllabus),
      ),
      _QuickNavItem(
        icon: Icons.notifications_active_outlined,
        label: l10n.prayerAdhanScreenTitle,
        onTap: () => context.push(AppRoutes.prayerAdhan),
      ),
      _QuickNavItem(
        icon: Icons.sports_esports_outlined,
        label: Localizations.localeOf(context).languageCode == 'bn' ? 'নলেজ ব্যাটেল' : 'Knowledge Battle',
        onTap: () => context.push(AppRoutes.battleHome),
      ),
    ];

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.quickNavSection,
            style: AppTextStyles.headlineMedium(context),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 88.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                return _QuickNavCard(item: items[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickNavItem {
  const _QuickNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _QuickNavCard extends StatelessWidget {
  const _QuickNavCard({required this.item});

  final _QuickNavItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72.w,
      height: 88.h,
      child: CardContainer(
        onTap: item.onTap,
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.goldCard,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.goldBorder),
              ),
              child: Icon(item.icon, color: AppColors.gold, size: 18.r),
            ),
            SizedBox(height: 6.h),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall(context).copyWith(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

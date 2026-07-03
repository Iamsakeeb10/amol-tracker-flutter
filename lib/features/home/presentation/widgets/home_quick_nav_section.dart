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
      _QuickNavCard(
        icon: Icons.auto_stories_outlined,
        label: l10n.quranTitle,
        onTap: () => context.push(AppRoutes.quran),
      ),
      _QuickNavCard(
        icon: Icons.menu_book_outlined,
        label: l10n.navDua,
        onTap: () => context.push(AppRoutes.dua),
      ),
      _QuickNavCard(
        icon: Icons.wb_sunny_outlined,
        label: l10n.morningEveningDua,
        onTap: () => context.push(
          AppRoutes.dua,
          extra: _morningEveningCategoryUrl,
        ),
      ),
      _QuickNavCard(
        icon: Icons.leaderboard_outlined,
        label: l10n.leaderboard,
        onTap: () => context.push(AppRoutes.leaderboard),
      ),
      _QuickNavCard(
        icon: Icons.calendar_month_outlined,
        label: l10n.hijriCalendar,
        onTap: () => context.push(AppRoutes.hijriCalendar),
      ),
      _QuickNavCard(
        icon: Icons.explore_outlined,
        label: l10n.qiblaTitle,
        onTap: () => context.push(AppRoutes.qibla),
      ),
      _QuickNavCard(
        icon: Icons.fiber_manual_record_outlined,
        label: l10n.dhikrCounter,
        onTap: () => context.push(AppRoutes.dhikr),
      ),
      _QuickNavCard(
        icon: Icons.auto_awesome_outlined,
        label: l10n.asmaUlHusna,
        onTap: () => context.push(AppRoutes.asmaUlHusna),
      ),
      _QuickNavCard(
        icon: Icons.menu_book_outlined,
        label: l10n.syllabusTitle,
        onTap: () => context.push(AppRoutes.syllabus),
      ),
      _QuickNavCard(
        icon: Icons.notifications_active_outlined,
        label: l10n.prayerAdhanScreenTitle,
        onTap: () => context.push(AppRoutes.prayerAdhan),
      ),
    ];

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.quickNavSection,
            style: AppTextStyles.headlineMedium(context),
          ),
          SizedBox(height: 8.h),
          for (int i = 0; i < items.length; i += 3) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: items[i]),
                SizedBox(width: 10.w),
                Expanded(
                  child: i + 1 < items.length
                      ? items[i + 1]
                      : const SizedBox.shrink(),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: i + 2 < items.length
                      ? items[i + 2]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            if (i + 3 < items.length) SizedBox(height: 10.h),
          ],
        ],
      ),
    );
  }
}

class _QuickNavCard extends StatelessWidget {
  const _QuickNavCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 14.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.goldCard,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.goldBorder),
            ),
            child: Icon(icon, color: AppColors.gold, size: 20.r),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall(context).copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

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

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.quickNavSection,
            style: AppTextStyles.headlineMedium(context),
          ),

          SizedBox(height: 8.h),

          Row(
            children: [
              Expanded(
                child: _QuickNavCard(
                  icon: Icons.auto_stories_outlined,
                  label: l10n.quranTitle,
                  onTap: () => context.push(AppRoutes.quran),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _QuickNavCard(
                  icon: Icons.menu_book_outlined,
                  label: l10n.navDua,
                  onTap: () => context.push(AppRoutes.dua),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _QuickNavCard(
                  icon: Icons.wb_sunny_outlined,
                  label: l10n.morningEveningDua,
                  onTap: () => context.push(
                    AppRoutes.dua,
                    extra: _morningEveningCategoryUrl,
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

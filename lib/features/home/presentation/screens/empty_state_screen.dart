import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../l10n/app_localizations.dart';

class EmptyStateScreen extends StatelessWidget {
  const EmptyStateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppBar(
        title: Text(l10n.welcome, style: AppTextStyles.headlineMedium(context)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 24.h),
        children: [
          CardContainer.gold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: AppColors.goldLight,
                      size: 16.r,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      l10n.today,
                      style: AppTextStyles.label(
                        context,
                      ).copyWith(color: AppColors.gold),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(kHadiths[0], style: AppTextStyles.bodyLarge(context)),
              ],
            ),
          ),
          SizedBox(height: 22.h),
          _EmptyBlock(
            icon: Icons.event_note_outlined,
            title: l10n.noAmalLoggedYet,
            body: l10n.freshStartMessage,
            ctaLabel: l10n.logTodayAmal,
            onTap: () => context.go(AppRoutes.home),
          ),
          SizedBox(height: 18.h),
          const Divider(),
          SizedBox(height: 18.h),
          _EmptyBlock(
            icon: Icons.public_rounded,
            title: l10n.joinCommunity,
            body: l10n.joinCommunitySubtitle,
            ctaLabel: l10n.openCommunity,
            onTap: () => context.go(AppRoutes.community),
          ),
        ],
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String ctaLabel;
  final VoidCallback onTap;

  const _EmptyBlock({
    required this.icon,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96.r,
          height: 96.r,
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cardBorder),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.gold, size: 36.r),
        ),
        SizedBox(height: 14.h),
        Text(title, style: AppTextStyles.headlineLarge(context)),
        SizedBox(height: 6.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(context),
          ),
        ),
        SizedBox(height: 14.h),
        SizedBox(
          height: 46.h,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.emeraldDeep,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Text(
              ctaLabel,
              style: AppTextStyles.button(context).copyWith(
                color: AppColors.emeraldDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

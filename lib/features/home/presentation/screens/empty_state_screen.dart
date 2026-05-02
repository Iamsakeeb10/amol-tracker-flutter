import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';

class EmptyStateScreen extends StatelessWidget {
  const EmptyStateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text('Welcome', style: AppTextStyles.headlineMedium(context)),
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
                      'TODAY',
                      style: AppTextStyles.label(context).copyWith(color: AppColors.gold),
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
            title: 'No amal logged yet',
            body:
                "Today's a fresh start. Tick off your first amal — even one counts.",
            ctaLabel: "Log today's amal",
            onTap: () => context.go(AppRoutes.home),
          ),
          SizedBox(height: 18.h),
          const Divider(),
          SizedBox(height: 18.h),
          _EmptyBlock(
            icon: Icons.group_add_outlined,
            title: 'No friends yet',
            body:
                'Pull a brother along. Invite friends to keep each other consistent.',
            ctaLabel: 'Invite friends',
            onTap: () => context.go(AppRoutes.invite),
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

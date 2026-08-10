import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/battle_teaser_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';

class AdminKnowledgeBattleScreen extends ConsumerWidget {
  const AdminKnowledgeBattleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(battleInterestMetricsProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.adminKnowledgeBattleTitle,
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: metricsAsync.when(
        data: (metrics) {
          final yes = metrics['yes'] ?? 0;
          final no = metrics['no'] ?? 0;
          final dismissed = metrics['dismissed'] ?? 0;
          final seen = yes + no + dismissed;
          
          final interestRate = seen > 0 ? (yes / seen * 100) : 0.0;

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            children: [
              CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 24.sp),
                        SizedBox(width: 8.w),
                        Text(
                          l10n.adminKnowledgeBattleTitle,
                          style: AppTextStyles.headlineMedium(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    
                    _StatRow(
                      icon: Icons.visibility_rounded,
                      iconColor: AppColors.textMuted,
                      label: l10n.adminKnowledgeBattleSeen,
                      value: '$seen',
                      isProminent: false,
                    ),
                    SizedBox(height: 16.h),
                    
                    _StatRow(
                      icon: Icons.check_circle_rounded,
                      iconColor: AppColors.gold,
                      label: l10n.adminKnowledgeBattleInterested,
                      value: '$yes',
                      isProminent: true,
                    ),
                    SizedBox(height: 16.h),
                    
                    _StatRow(
                      icon: Icons.cancel_rounded,
                      iconColor: AppColors.danger,
                      label: l10n.adminKnowledgeBattleNotInterested,
                      value: '$no',
                      isProminent: false,
                    ),
                    SizedBox(height: 16.h),
                    
                    _StatRow(
                      icon: Icons.close_rounded,
                      iconColor: AppColors.textMuted,
                      label: l10n.adminKnowledgeBattleDismissed,
                      value: '$dismissed',
                      isProminent: false,
                    ),
                    SizedBox(height: 24.h),
                    
                    Divider(color: AppColors.cardBorder),
                    SizedBox(height: 16.h),
                    
                    _StatRow(
                      icon: Icons.trending_up_rounded,
                      iconColor: AppColors.gold,
                      label: l10n.adminKnowledgeBattleInterestRate,
                      value: '${interestRate.toStringAsFixed(1)}%',
                      isProminent: true,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: AppTextStyles.bodyMedium(context)),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isProminent = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isProminent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: isProminent
                  ? AppTextStyles.bodyLarge(context).copyWith(fontWeight: FontWeight.bold)
                  : AppTextStyles.bodyMedium(context),
            ),
          ],
        ),
        Text(
          value,
          style: isProminent
              ? AppTextStyles.headlineMedium(context).copyWith(color: AppColors.gold)
              : AppTextStyles.bodyLarge(context),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/husna_name_model.dart';
import '../../../../providers/asma_ul_husna_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';

class AsmaUlHusnaDetailScreen extends ConsumerWidget {
  const AsmaUlHusnaDetailScreen({super.key, required this.name});

  final HusnaName name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(asmaUlHusnaProvider);
    final notifier = ref.read(asmaUlHusnaProvider.notifier);
    final isLearned = state.isLearned(name.number);
    final meaning = name.localizedMeaningFromLocale(Localizations.localeOf(context));

    return AppScaffold(
      handleExitBack: false,
      appBar: AppBar(
        title: Text(
          l10n.husnaNumber(name.number),
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        children: [
          CardContainer(
            child: Column(
              children: [
                Text(
                  name.arabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: AppTextStyles.displayLarge(context).copyWith(
                    fontSize: 34.sp,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  name.transliteration,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.husnaMeaning,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11.sp,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  meaning,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.husnaBenefit,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11.sp,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  name.benefit,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => notifier.toggleLearned(name.number),
              style: FilledButton.styleFrom(
                backgroundColor:
                    isLearned ? AppColors.cardBorder : AppColors.gold,
                foregroundColor:
                    isLearned ? AppColors.textPrimary : AppColors.emeraldDeep,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              icon: Icon(
                isLearned ? Icons.bookmark_remove_outlined : Icons.bookmark_add_outlined,
                size: 20.r,
              ),
              label: Text(
                isLearned ? l10n.husnaMarkNotLearned : l10n.husnaMarkLearned,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                  color: isLearned ? AppColors.textPrimary : AppColors.emeraldDeep,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

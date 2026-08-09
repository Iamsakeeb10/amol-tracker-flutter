import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/amal_entry_policy.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/amal_provider.dart';
import 'home_amal_details_dialog.dart';
import 'home_amal_fields_sliver.dart';
import 'home_amal_loading_shimmer.dart';
import 'home_widgets.dart';

List<Widget> buildHomeEditingAmalSlivers({
  required BuildContext context,
  required WidgetRef ref,
  required String uid,
  required AsyncValue<List<AmalField>> fieldsAsync,
  required String locale,
  required AppLocalizations l10n,
  required bool isAmalLoading,
  required bool hasAnyDone,
  required Future<void> Function() onRetryFields,
}) {
  final amalNotifier = ref.read(amalProvider(uid).notifier);
  final policy = ref.watch(amalEntryPolicyProvider);

  return [
    SliverToBoxAdapter(
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.todaysAmal,
              style: AppTextStyles.headlineMedium(context),
            ),
          ),
          OutlinedButton.icon(
            onPressed: isAmalLoading
                ? null
                : hasAnyDone
                ? amalNotifier.clearAll
                : amalNotifier.markAllDone,
            icon: Icon(
              hasAnyDone ? Icons.restart_alt : Icons.done_all,
              size: 17.r,
              color: hasAnyDone ? AppColors.warning : AppColors.gold,
            ),
            label: Text(
              hasAnyDone ? l10n.deselectAll : l10n.markAllDone,
              style: AppTextStyles.button(context).copyWith(
                color: hasAnyDone ? AppColors.warning : AppColors.gold,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: hasAnyDone
                    ? HomeUiColors.warningButtonBorder
                    : AppColors.goldBorder,
              ),
              backgroundColor: hasAnyDone
                  ? AppColors.warningLight
                  : AppColors.goldCard,
              foregroundColor: AppColors.gold,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              minimumSize: Size(0, 40.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    ),
    SliverToBoxAdapter(child: SizedBox(height: 6.h)),
    if (isAmalLoading || fieldsAsync.isLoading)
      const SliverToBoxAdapter(child: HomeAmalLoadingShimmer())
    else
      ...buildHomeAmalFieldSlivers(
        uid: uid,
        context: context,
        fieldsAsync: fieldsAsync,
        locale: locale,
        onRetry: onRetryFields,
        onTapDetails: (f) => showHomeAmalDetailsDialog(context, f, locale),
        mainFields: policy.mainFields,
        optionalFields: policy.optionalFields,
        inactiveSpecialTimeFields: policy.inactiveSpecialTimeFields,
      ),
    SliverToBoxAdapter(child: SizedBox(height: 14.h)),
    SliverToBoxAdapter(
      child: Text(
        hasAnyDone
            ? l10n.draftSavedTapSaveToFinish(l10n.saveFabLabel)
            : l10n.progressAutosavedHint,
        style: AppTextStyles.bodySmall(context).copyWith(
          color: AppColors.textSecondary,
          fontSize: 12.sp,
        ),
      ),
    ),
  ];
}

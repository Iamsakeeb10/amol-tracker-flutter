import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../shared/widgets/card_container.dart';
import 'home_amal_details_dialog.dart';
import 'home_amal_fields_sliver.dart';
import 'home_widgets.dart';

List<Widget> buildHomeSubmittedAmalSlivers({
  required BuildContext context,
  required String uid,
  required AsyncValue<List<AmalField>> fieldsAsync,
  required String locale,
  required AppLocalizations l10n,
  required AmalLogModel? submittedLog,
  required Future<void> Function() onRetryFields,
  required Future<void> Function(AmalLogModel log) onEditTodayAmal,
}) {
  return [
    SliverToBoxAdapter(
      child: CardContainer.gold(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 22.r),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                l10n.loggedToday,
                style: AppTextStyles.bodyLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ),
    SliverToBoxAdapter(child: SizedBox(height: 14.h)),
    SliverToBoxAdapter(
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.todaysAmal,
              style: AppTextStyles.headlineMedium(context),
            ),
          ),
          HomeSubmittedAmalIconButton(
            icon: Icons.check_circle,
            tooltip: l10n.markAllDone,
            iconColor: AppColors.success,
          ),
          SizedBox(width: 8.w),
          HomeSubmittedAmalIconButton(
            icon: Icons.edit_outlined,
            tooltip: l10n.editTodayAmal,
            onPressed: submittedLog == null
                ? null
                : () => onEditTodayAmal(submittedLog),
          ),
        ],
      ),
    ),
    SliverToBoxAdapter(child: SizedBox(height: 12.h)),
    ...buildHomeAmalFieldSlivers(
      uid: uid,
      context: context,
      fieldsAsync: fieldsAsync,
      locale: locale,
      readOnly: true,
      onRetry: onRetryFields,
      onTapDetails: (f) => showHomeAmalDetailsDialog(context, f, locale),
      mainFields: _mainFieldsForSubmitted(fieldsAsync, submittedLog),
      inactiveSpecialTimeFields:
          _inactiveFieldsForSubmitted(fieldsAsync, submittedLog),
    ),
  ];
}

List<AmalField>? _mainFieldsForSubmitted(
  AsyncValue<List<AmalField>> fieldsAsync,
  AmalLogModel? submittedLog,
) {
  final fields = fieldsAsync.asData?.value;
  if (fields == null || submittedLog == null) return null;
  final activeIds = submittedLog.activeFieldIds.toSet();
  if (activeIds.isEmpty) return null;
  return fields.where((f) => activeIds.contains(f.id)).toList();
}

List<AmalField>? _inactiveFieldsForSubmitted(
  AsyncValue<List<AmalField>> fieldsAsync,
  AmalLogModel? submittedLog,
) {
  final fields = fieldsAsync.asData?.value;
  if (fields == null || submittedLog == null) return null;
  final activeIds = submittedLog.activeFieldIds.toSet();
  if (activeIds.isEmpty) return null;
  // Only show inactive section when special-time was applied at submit.
  if (!submittedLog.specialTimeApplied) return const [];
  return fields
      .where((f) => f.isActive && f.id.isNotEmpty && !activeIds.contains(f.id))
      .toList();
}

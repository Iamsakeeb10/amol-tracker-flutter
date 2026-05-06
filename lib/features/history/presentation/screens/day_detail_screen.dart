import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/amal_fields.dart' as amal_const;
import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/hijri_helper.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/history_provider.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/stat_card.dart';

class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({
    super.key,
    required this.hijriDate,
  });

  /// Hijri storage key `YYYY-MM-DD`.
  final String hijriDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).asData?.value;
    if (authUser == null) {
      return AppScaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final asyncLog = ref.watch(
      dayDetailLogProvider(DayLogKey(uid: authUser.uid, hijriDate: hijriDate)),
    );

    return asyncLog.when(
      loading: () => AppScaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      ),
      error: (_, _) => AppScaffold(
        body: Center(
          child: Text(
            'Could not load this day.',
            style: AppTextStyles.bodyLarge(context),
          ),
        ),
      ),
      data: (log) {
        final score = log?.score ?? 0;
        final title = hijriDate.isEmpty
            ? 'Day detail'
            : HijriHelper.displayFromStorage(hijriDate);
        final weekday = hijriDate.isEmpty
            ? ''
            : HijriHelper.weekdayEnglishForHijriStorage(hijriDate);

        return AppScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, size: 22.r),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.history),
            ),
            title: Text(title, style: AppTextStyles.headlineMedium(context)),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(99.r),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      'READ-ONLY',
                      style: AppTextStyles.label(context).copyWith(
                        fontSize: 10.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
            children: [
              if (weekday.isNotEmpty) ...[
                Text(
                  weekday,
                  style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.gold),
                ),
                SizedBox(height: 12.h),
              ],
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Score',
                      value: '$score',
                      sublabel: 'of 100',
                      icon: Icons.workspace_premium_outlined,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: StatCard(
                      label: 'Streak that day',
                      value: '—',
                      sublabel: 'not stored',
                      icon: Icons.local_fire_department_outlined,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text('Amal', style: AppTextStyles.headlineMedium(context)),
              SizedBox(height: 8.h),
              if (log == null)
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: CardContainer(
                    color: AppColors.warningLight.withValues(alpha: 0.25),
                    borderColor: AppColors.warning.withValues(alpha: 0.35),
                    child: Text(
                      'No log was submitted for this Hijri day.',
                      style: AppTextStyles.bodyMedium(context),
                    ),
                  ),
                ),
              ...amal_const.kAmalFields.map((field) {
                final done = log?.toggles[field.id] ?? false;
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: AmalRow(
                    field: field,
                    done: done,
                    readOnly: true,
                  ),
                );
              }),
              SizedBox(height: 14.h),
              CardContainer(
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: AppColors.textMuted,
                      size: 16.r,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'Locked — past days cannot be edited.',
                        style: AppTextStyles.bodyMedium(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

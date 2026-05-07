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
import '../../../../l10n/app_localizations.dart';

class DayDetailScreen extends ConsumerWidget {
  const DayDetailScreen({super.key, required this.hijriDate});

  /// Hijri storage key `YYYY-MM-DD`.
  final String hijriDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
            l10n.dayDetailLoadFailed,
            style: AppTextStyles.bodyLarge(context),
          ),
        ),
      ),
      data: (log) {
        final score = log?.score ?? 0;
        final title = hijriDate.isEmpty
            ? l10n.dayDetailTitle
            : HijriHelper.displayFromStorage(hijriDate);
        final weekday = hijriDate.isEmpty
            ? ''
            : HijriHelper.weekdayEnglishForHijriStorage(hijriDate);

        return AppScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, size: 22.r),
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.history),
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
                      l10n.readOnly,
                      style: AppTextStyles.label(
                        context,
                      ).copyWith(fontSize: 10.sp, color: AppColors.textMuted),
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
                  style: AppTextStyles.bodyMedium(
                    context,
                  ).copyWith(color: AppColors.gold),
                ),
                SizedBox(height: 12.h),
              ],
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: l10n.score,
                      value: '$score',
                      sublabel: l10n.outOf100,
                      icon: Icons.workspace_premium_outlined,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: StatCard(
                      label: l10n.dayDetailStreakThatDay,
                      value: '—',
                      sublabel: l10n.dayDetailNotStored,
                      icon: Icons.local_fire_department_outlined,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(l10n.amal, style: AppTextStyles.headlineMedium(context)),
              SizedBox(height: 8.h),
              if (log == null)
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: CardContainer(
                    color: AppColors.warningLight.withValues(alpha: 0.25),
                    borderColor: AppColors.warning.withValues(alpha: 0.35),
                    child: Text(
                      l10n.dayDetailNoLogForDay,
                      style: AppTextStyles.bodyMedium(context),
                    ),
                  ),
                ),
              ...amal_const.kAmalFields.map((field) {
                final done = field.type == amal_const.AmalType.numeric
                    ? amal_const.getNumericValue(
                        log?.toggles[field.id],
                        field.maxValue,
                      ) >
                      0
                    : (log?.toggles[field.id] as bool? ?? false);
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: AmalRow(
                    field: field,
                    done: done,
                    numericValue: field.type == amal_const.AmalType.numeric
                        ? amal_const.getNumericValue(
                            log?.toggles[field.id],
                            field.maxValue,
                          )
                        : null,
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
                        l10n.dayDetailLockedPastDays,
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

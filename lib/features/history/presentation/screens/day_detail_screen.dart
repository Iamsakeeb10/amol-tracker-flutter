import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/amal_fields.dart' as amal_const;
import '../../../../core/constants/default_amal_fields.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/amal_edit_debug.dart';
import '../../../../core/utils/score_calculator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/amal_fields_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/history_provider.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/edited_badge.dart';
import '../../../../shared/widgets/stat_card.dart';

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
    final editableAsync = ref.watch(editableDayProvider(hijriDate));
    final locale = Localizations.localeOf(context).languageCode;

    return asyncLog.when(
      loading: () => AppScaffold(body: const _DayDetailLoadingShimmer()),
      error: (_, _) => AppScaffold(
        body: Center(
          child: Text(
            l10n.dayDetailLoadFailed,
            style: AppTextStyles.bodyLarge(context),
          ),
        ),
      ),
      data: (log) {
        final fields = ref.watch(amalFieldsListProvider);
        final maxScore = getMaxScore(fields).clamp(1, kDefaultMaxDailyScore);
        final score = log?.score ?? 0;
        final editableDay = editableAsync.asData?.value;
        final showEditFab = editableDay?.canEdit ?? false;
        final logForEdit = editableDay?.existingLog;
        if (kDebugMode) {
          logAmalEditDebug(
            'DayDetail hijriDate=$hijriDate hasLog=${log != null} '
            'showEditFab=$showEditFab backfill=${showEditFab && log == null} '
            'editableLoading=${editableAsync.isLoading}',
          );
        }
        final title = hijriDate.isEmpty
            ? l10n.dayDetailTitle
            : IslamicDateService.displayFromStorageBn(hijriDate);
        final weekday = hijriDate.isEmpty
            ? ''
            : IslamicDateService.weekdayEnglishForStorage(hijriDate);

        return AppScaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: showEditFab
              ? Tooltip(
                  message: 'এই দিনের আমল সম্পাদনা করুন',
                  child: FloatingActionButton(
                    onPressed: () => context.push(
                      AppRoutes.editAmalPath(hijriDate),
                      extra: logForEdit,
                    ),
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.emeraldDeep,
                    child: Icon(Icons.edit_outlined, size: 22.r),
                  ),
                )
              : null,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back, size: 22.r),
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.history),
            ),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headlineMedium(context),
            ),
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
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(0, 4.h, 0, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              sublabel: '/$maxScore',
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
                      if (log?.editedAt != null) ...[
                        SizedBox(height: 8.h),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: EditedBadge(),
                        ),
                      ],
                      SizedBox(height: 16.h),
                      Text(
                        l10n.amal,
                        style: AppTextStyles.headlineMedium(context),
                      ),
                      SizedBox(height: 8.h),
                      if (log == null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: CardContainer(
                            color: AppColors.warningLight.withValues(alpha: 0.25),
                            borderColor:
                                AppColors.warning.withValues(alpha: 0.35),
                            child: Text(
                              l10n.dayDetailNoLogForDay,
                              style: AppTextStyles.bodyMedium(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverList.builder(
                itemCount: fields.length,
                itemBuilder: (context, index) {
                  final field = fields[index];
                  final done = field.type == amal_const.AmalType.numeric
                      ? getNumericValue(
                              log?.toggles[field.id],
                              field.maxValue,
                            ) >
                            0
                      : (log?.toggles[field.id] as bool? ?? false);
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: AmalRow(
                      field: field,
                      locale: locale,
                      done: done,
                      numericValue: field.type == amal_const.AmalType.numeric
                          ? getNumericValue(
                              log?.toggles[field.id],
                              field.maxValue,
                            )
                          : null,
                      readOnly: true,
                    ),
                  );
                },
              ),
              if (!showEditFab)
                SliverPadding(
                  padding: EdgeInsets.only(top: 14.h),
                  sliver: SliverToBoxAdapter(
                    child: CardContainer(
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
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: showEditFab ? 88.h : 24.h),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayDetailLoadingShimmer extends StatelessWidget {
  const _DayDetailLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.emeraldMid.withValues(alpha: 0.35),
      child: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
        children: [
          Container(
            width: 110.w,
            height: 14.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 92.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Container(
                  height: 92.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            width: 70.w,
            height: 16.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          SizedBox(height: 8.h),
          ...List.generate(
            6,
            (_) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Container(
                height: 56.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

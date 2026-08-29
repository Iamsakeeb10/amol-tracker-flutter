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
import '../../../../core/utils/amal_entry_policy.dart';
import '../../../../core/utils/bengali_numeral_helper.dart';
import '../../../../core/utils/score_calculator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/amal_fields_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/history_provider.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/edited_badge.dart';
import '../../../../shared/widgets/fard_prayer_expand_row.dart';
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

    ref.watch(amalLogRefreshProvider);
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
        final computedMax = fields
            .where((f) => f.isActive && f.id.isNotEmpty)
            .fold<int>(0, (sum, f) => sum + f.points);
        final maxScore =
            (log?.maxScore ?? computedMax).clamp(1, kDefaultMaxDailyScore);
        final score = log?.score ?? 0;
        final activeIds = log?.activeFieldIds.toSet() ?? const <String>{};
        final activeFields = activeIds.isEmpty
            ? fields
            : fields.where((f) => activeIds.contains(f.id)).toList();
            
        final isSpecialTimeActive = log?.specialTimeApplied ?? false;
        final user = ref.watch(currentUserProvider).asData?.value;
        final userProfile = user?.amalProfile ?? UserAmalProfile.unset;
        
        final displayPolicy = AmalEntryPolicy.from(
          userProfile, 
          activeFields, 
          specialTimeActive: isSpecialTimeActive,
        );
        
        final mainFields = displayPolicy.mainFields;
        final optionalFields = displayPolicy.optionalFields;
        
        final inactiveFields = isSpecialTimeActive
            ? fields
                .where(
                  (f) =>
                      f.isActive &&
                      f.id.isNotEmpty &&
                      !activeIds.contains(f.id),
                )
                .toList()
            : const <amal_const.AmalField>[];
        final editableDay = editableAsync.asData?.value;
        final editableResolved = editableAsync.hasValue;
        final showEditFab = editableDay?.canEdit ?? false;
        final isTodayNotSubmitted = editableDay?.isTodayNotSubmitted ?? false;
        final logForEdit = log ?? editableDay?.existingLog;
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
        final isFriday = weekday == 'Friday';

        return AppScaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: showEditFab
              ? Tooltip(
                  message: l10n.editDayAmal,
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
              if (editableResolved && !showEditFab)
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
                itemCount: mainFields.length,
                itemBuilder: (context, index) {
                  final field = mainFields[index];
                  return _DayDetailAmalRow(
                    field: field,
                    locale: locale,
                    log: log,
                    isFriday: isFriday,
                  );
                },
              ),
              if (optionalFields.isNotEmpty)
                SliverToBoxAdapter(
                  child: _DayDetailOptionalFieldsSection(
                    fields: optionalFields,
                    locale: locale,
                    log: log,
                    isFriday: isFriday,
                  ),
                ),
              if (inactiveFields.isNotEmpty) ...[
                SliverToBoxAdapter(child: SizedBox(height: 8.h)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                    child: Row(
                      children: [
                        Icon(
                          Icons.pause_circle_outline_rounded,
                          size: 20.r,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                         child: Text(
                           l10n.inactiveSpecialTimeExcusedSection,
                           style: AppTextStyles.bodySmall(context).copyWith(
                             color: AppColors.textSecondary,
                             fontSize: 12.sp,
                             fontWeight: FontWeight.w600,
                             overflow: TextOverflow.ellipsis,
                           ),
                         ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: inactiveFields.length,
                  itemBuilder: (context, index) {
                    final field = inactiveFields[index];
                    return Opacity(
                      opacity: 0.5,
                      child: _DayDetailAmalRow(
                        field: field,
                        locale: locale,
                        log: log,
                        isFriday: isFriday,
                      ),
                    );
                  },
                ),
              ],
              if (editableResolved && !showEditFab)
                SliverPadding(
                  padding: EdgeInsets.only(top: 14.h),
                  sliver: SliverToBoxAdapter(
                    child: CardContainer(
                      child: isTodayNotSubmitted
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.home_outlined,
                                      color: AppColors.gold,
                                      size: 16.r,
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Text(
                                        l10n.dayDetailTodayGoHome,
                                        style: AppTextStyles.bodyMedium(context),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => context.go(AppRoutes.home),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.gold,
                                      side: const BorderSide(
                                        color: AppColors.goldBorder,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 11.h,
                                      ),
                                    ),
                                    child: Text(
                                      l10n.dayDetailGoToHome,
                                      style: AppTextStyles.button(context)
                                          .copyWith(
                                            color: AppColors.gold,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
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

class _DayDetailAmalRow extends StatelessWidget {
  const _DayDetailAmalRow({
    required this.field,
    required this.locale,
    required this.log,
    required this.isFriday,
  });

  final amal_const.AmalField field;
  final String locale;
  final AmalLogModel? log;
  final bool isFriday;

  @override
  Widget build(BuildContext context) {
    final done = field.type == amal_const.AmalType.numeric
        ? getNumericValue(log?.toggles[field.id], field.maxValue) > 0
        : (log?.toggles[field.id] as bool? ?? false);
    // Show prayer circles when Firestore has individual selection
    // data (new logs). Fall back to count-only for old logs.
    final prayerSlots =
        field.supportsExpansion ? log?.prayers[field.id] : null;
    final hasPrayerData = prayerSlots != null && prayerSlots.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: AmalRow(
        field: field,
        locale: locale,
        done: done,
        numericValue: field.type == amal_const.AmalType.numeric
            ? getNumericValue(log?.toggles[field.id], field.maxValue)
            : null,
        readOnly: true,
        expandable: hasPrayerData,
        isExpanded: hasPrayerData,
        expandedContent: hasPrayerData
            ? FardPrayerExpandRow(
                selectedIndices: prayerSlots.toSet(),
                onToggleIndex: (_) {},
                slotCount: field.maxValue,
                isFriday: isFriday,
                readOnly: true,
              )
            : null,
      ),
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

class _DayDetailOptionalFieldsSection extends StatefulWidget {
  const _DayDetailOptionalFieldsSection({
    required this.fields,
    required this.locale,
    required this.log,
    required this.isFriday,
  });

  final List<amal_const.AmalField> fields;
  final String locale;
  final AmalLogModel? log;
  final bool isFriday;

  @override
  State<_DayDetailOptionalFieldsSection> createState() =>
      _DayDetailOptionalFieldsSectionState();
}

class _DayDetailOptionalFieldsSectionState
    extends State<_DayDetailOptionalFieldsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final radius = 14.r;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.goldCard,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: AppColors.goldBorder, width: 1),
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20.r,
                      color: AppColors.gold,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Flexible(
                    flex: 5,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            l10n.optionalAmalSectionTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyLarge(context).copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.goldLight,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          constraints: BoxConstraints(minWidth: 20.r),
                          height: 20.r,
                          padding: EdgeInsets.symmetric(horizontal: 6.w),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            widget.locale == 'bn'
                                ? toBengaliNumeral(widget.fields.length)
                                : '${widget.fields.length}',
                            style: AppTextStyles.pill(context).copyWith(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.goldPale,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _expanded
              ? Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: Column(
                    children: [
                      for (final field in widget.fields)
                        _DayDetailAmalRow(
                          field: field,
                          locale: widget.locale,
                          log: widget.log,
                          isFriday: widget.isFriday,
                        ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

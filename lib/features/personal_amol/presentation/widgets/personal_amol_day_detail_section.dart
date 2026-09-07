import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/personal_amol_schedule.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/personal_amol_model.dart';
import '../../../../providers/personal_amol_date_pending_provider.dart';
import '../../../../providers/personal_amol_provider.dart';
import '../../../../shared/widgets/card_container.dart';
import 'personal_amol_create_sheet.dart';
import 'personal_amol_details_dialog.dart';
import 'personal_amol_empty_state.dart';
import 'personal_amol_tile.dart';

/// Personal amol section on the day-detail screen.
///
/// Active amols due that day are editable (toggle / +/− → staged save).
/// Soft-deleted amols with completions on the viewed date appear as read-only
/// history so calendar gold days stay explainable after delete.
class PersonalAmolDayDetailSection extends ConsumerWidget {
  const PersonalAmolDayDetailSection({
    super.key,
    required this.uid,
    required this.hijriDate,
    this.showInlineSaveButton = true,
  });

  final String uid;
  final String hijriDate;

  /// When false, the inline (in-flow) Save button is suppressed so the parent
  /// screen can render its own fixed save bar instead.
  final bool showInlineSaveButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final amolsAsync = ref.watch(allPersonalAmolProvider(uid));
    final amols = amolsAsync.value ?? const <PersonalAmolModel>[];
    if (amolsAsync.isLoading) return const _PersonalAmolSectionShimmer();

    final completionsAsync = ref.watch(
      personalAmolCompletionsForDateProvider(
        PersonalAmolDateKey(uid: uid, hijriDate: hijriDate),
      ),
    );
    if (completionsAsync.isLoading && !completionsAsync.hasValue) {
      return const _PersonalAmolSectionShimmer();
    }
    final completions =
        completionsAsync.value ?? const <PersonalAmolCompletion>[];
    final counts = <String, int>{};
    for (final c in completions) {
      counts[c.amolId] = (counts[c.amolId] ?? 0) + 1;
    }

    final active = amols.where((a) => a.isActive).toList();
    final due = active
        .where((a) => personalAmolScheduledOn(a, hijriDate))
        .toList();
    final historical = historicalPersonalAmolForDay(
      amols: amols,
      hijriDate: hijriDate,
      completions: completions,
    );

    if (due.isEmpty && historical.isEmpty) {
      if (active.isEmpty) {
        return Padding(
          padding: EdgeInsets.only(top: 24.h),
          child: PersonalAmolEmptyState(
            onAdd: () => PersonalAmolCreateSheet.show(
              context,
              uid: uid,
              entryPoint: 'day_detail_empty',
            ),
          ),
        );
      }
      return Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: CardContainer(
          child: Row(
            children: [
              Icon(
                Icons.event_busy,
                color: AppColors.textMuted,
                size: 20.r,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  l10n.personalAmolNoneDueToday,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pending = ref.watch(
      personalAmolDatePendingProvider(
        PersonalAmolDateEditKey(uid: uid, hijriDate: hijriDate),
      ),
    );
    final shown = <String, int>{...counts, ...pending.staged};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (due.isNotEmpty) ...[
          SizedBox(height: 4.h),
          Text(
            l10n.personalAmolHistorySection,
            style: AppTextStyles.headlineMedium(context),
          ),
          SizedBox(height: 6.h),
          for (final amol in due) ...[
            _editableRow(context, ref, amol, shown[amol.id] ?? 0),
            SizedBox(height: 8.h),
          ],
          if (showInlineSaveButton && pending.dirty) ...[
            SizedBox(height: 12.h),
            _SaveButton(
              isSaving: pending.isSaving,
              enabled: pending.dirty,
              onPressed: () async {
                final saved = await ref
                    .read(
                      personalAmolDatePendingProvider(
                        PersonalAmolDateEditKey(
                          uid: uid,
                          hijriDate: hijriDate,
                        ),
                      ).notifier,
                    )
                    .save();
                if (!context.mounted || !saved) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.personalAmolSaved)),
                );
              },
            ),
          ],
        ],
        if (historical.isNotEmpty) ...[
          if (due.isNotEmpty) SizedBox(height: 16.h),
          if (due.isEmpty) SizedBox(height: 4.h),
          Text(
            l10n.personalAmolDeletedHistorySection,
            style: AppTextStyles.headlineMedium(context),
          ),
          SizedBox(height: 6.h),
          for (final amol in historical) ...[
            _historicalRow(context, amol, counts[amol.id] ?? 0),
            SizedBox(height: 8.h),
          ],
        ],
      ],
    );
  }

  Widget _editableRow(
    BuildContext context,
    WidgetRef ref,
    PersonalAmolModel amol,
    int doneCount,
  ) {
    final target = amol.type == PersonalAmolType.count ? amol.target : 1;
    final completed = doneCount >= target;
    final key = PersonalAmolDateEditKey(uid: uid, hijriDate: hijriDate);
    final notifier = ref.read(personalAmolDatePendingProvider(key).notifier);

    return PersonalAmolTile(
      uid: uid,
      amol: amol,
      completed: completed,
      doneCount: doneCount,
      onTap: () => showPersonalAmolDetailsDialog(
        context,
        uid: uid,
        amol: amol,
        doneCount: doneCount,
      ),
      onToggle: amol.type == PersonalAmolType.toggle
          ? () => notifier.toggle(amol)
          : null,
      onPlus: amol.type == PersonalAmolType.count
          ? () => notifier.plus(amol)
          : null,
      onMinus: amol.type == PersonalAmolType.count
          ? () => notifier.minus(amol)
          : null,
    );
  }

  Widget _historicalRow(
    BuildContext context,
    PersonalAmolModel amol,
    int doneCount,
  ) {
    final target = amol.type == PersonalAmolType.count ? amol.target : 1;
    final completed = doneCount >= target;

    return PersonalAmolTile(
      uid: uid,
      amol: amol,
      completed: completed,
      doneCount: doneCount,
      readOnly: true,
      onTap: () => showPersonalAmolDetailsDialog(
        context,
        uid: uid,
        amol: amol,
        doneCount: doneCount,
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaving,
    required this.enabled,
    required this.onPressed,
  });

  final bool isSaving;

  /// When false the button renders disabled — used by fixed bottom bars that
  /// must always be visible but inert until there is something to save.
  final bool enabled;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSaving || !enabled
            ? null
            : () {
                onPressed();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.emeraldDeep,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        child: isSaving
            ? SizedBox(
                width: 22.r,
                height: 22.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.emeraldDeep,
                ),
              )
            : Text(
                l10n.personalAmolSaveLabel,
                style: AppTextStyles.button(context).copyWith(
                  color: AppColors.emeraldDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Shimmer skeleton for the day-detail personal amol section. Rendered while
/// amol definitions or the day's completions are loading/refreshing, so stale
/// pre-edit values are never painted over the fresh post-save data.
class _PersonalAmolSectionShimmer extends StatelessWidget {
  const _PersonalAmolSectionShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.emeraldMid.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4.h),
          Container(
            width: 130.w,
            height: 18.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          SizedBox(height: 14.h),
          for (var i = 0; i < 3; i++) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 18.w,
                vertical: 12.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120.w,
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: 70.w,
                          height: 10.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    width: 48.w,
                    height: 20.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ],
      ),
    );
  }
}

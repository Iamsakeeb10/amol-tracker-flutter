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
import 'personal_amol_details_dialog.dart';
import 'personal_amol_tile.dart';

/// Editable personal amol section shown on the day-detail screen.
///
/// Mirrors the home screen's personal-amol UI: active amols get a toggle switch
/// or +/− stepper and a tap on the card opens the details dialog (same as
/// home). Taps stage into the per-date pending provider and only persist to
/// Firestore when the section's Save button is pressed. Only active amols are
/// listed — soft-deleted amols are omitted entirely.
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
    // Wait for the amol definitions before deciding how many rows to render.
    if (amolsAsync.isLoading) return const _PersonalAmolSectionShimmer();

    // Only active amols are editable here; soft-deleted amols ("old" ones)
    // have no meaning on this screen and must not render with dead controls.
    final due = amols
        .where((a) => a.isActive && personalAmolScheduledOn(a, hijriDate))
        .toList();
    if (due.isEmpty) return const SizedBox.shrink();

    final completionsAsync = ref.watch(
      personalAmolCompletionsForDateProvider(
        PersonalAmolDateKey(uid: uid, hijriDate: hijriDate),
      ),
    );
    // After a save the completions provider re-fetches from Firestore; keep a
    // shimmer in place while that reload is in flight so the pre-edit counts
    // never flash back before the fresh (post-save) data arrives.
    if (completionsAsync.isLoading && !completionsAsync.hasValue) {
      return const _PersonalAmolSectionShimmer();
    }
    final counts = <String, int>{};
    for (final c in completionsAsync.value ?? const <PersonalAmolCompletion>[]) {
      counts[c.amolId] = (counts[c.amolId] ?? 0) + 1;
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
        SizedBox(height: 4.h),
        Text(
          l10n.personalAmolHistorySection,
          style: AppTextStyles.headlineMedium(context),
        ),
        SizedBox(height: 6.h),
        for (final amol in due) ...[
          _row(context, ref, amol, shown[amol.id] ?? 0),
          SizedBox(height: 8.h),
        ],
        if (showInlineSaveButton && pending.dirty) ...[
          SizedBox(height: 12.h),
          _SaveButton(
            isSaving: pending.isSaving,
            enabled: pending.dirty,
            onPressed: () {
              ref
                  .read(
                    personalAmolDatePendingProvider(
                      PersonalAmolDateEditKey(
                        uid: uid,
                        hijriDate: hijriDate,
                      ),
                    ).notifier,
                  )
                  .save();
            },
          ),
        ],
      ],
    );
  }

  Widget _row(
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
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSaving || !enabled ? null : onPressed,
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

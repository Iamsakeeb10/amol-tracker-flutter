import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/submit_todays_amal.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/amal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/personal_amol_pending_provider.dart';

/// Save FAB for home tab; rendered on [ScaffoldWithBottomNav] above bottom nav.
///
/// Surfaces whenever there are unsaved changes — community amol toggles and/or
/// staged personal-amol edits — and persists both on press.
class HomeSaveFab extends ConsumerWidget {
  const HomeSaveFab({super.key});

  static const _fabHeight = 48.0;
  static const _fabHorizontalPadding = 20.0;
  static const _iconSize = 20.0;
  static const _labelSize = 15.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).asData?.value;
    final user = ref.watch(currentUserProvider).asData?.value;
    if (authUser == null || user == null) return const SizedBox.shrink();

    final uid = authUser.uid;
    final isSubmitted = ref.watch(
      amalProvider(uid).select((s) => s.isSubmitted),
    );
    final hasAnyDone = ref.watch(
      amalProvider(uid).select((s) => s.hasAnyDone),
    );
    final isAmalLoading = ref.watch(
      amalProvider(uid).select((s) => s.isLoading),
    );
    final personalPending = ref.watch(personalAmolPendingProvider(uid));
    final personalDirty = personalPending.dirty;
    final personalSaving = personalPending.isSaving;

    // Community has unsaved toggles, or personal amol edits are staged.
    final communityDirty = !isSubmitted && hasAnyDone;
    final isLoading = isAmalLoading || personalSaving;
    if (!communityDirty && !personalDirty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final labelStyle = AppTextStyles.button(context).copyWith(
      color: AppColors.emeraldDeep,
      fontWeight: FontWeight.w600,
      fontSize: _labelSize.sp,
      height: 1,
      letterSpacing: 0.1,
    );

    return Tooltip(
      message: l10n.saveTodaysAmal,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_fabHeight.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.goldLight.withValues(alpha: 0.5),
              blurRadius: 18.r,
              spreadRadius: 1.r,
            ),
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.45),
              blurRadius: 12.r,
              spreadRadius: 0.5.r,
              offset: Offset(0, 3.h),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 6.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading
                ? null
                : () => _onSavePressed(
                    context,
                    ref,
                    uid: uid,
                    user: user,
                  ),
            borderRadius: BorderRadius.circular(_fabHeight.r),
            child: Ink(
              height: _fabHeight.h,
              padding: EdgeInsets.symmetric(
                horizontal: _fabHorizontalPadding.w,
              ),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(_fabHeight.r),
                border: Border.all(
                  color: AppColors.goldPale.withValues(alpha: 0.85),
                  width: 0.8.w,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: _iconSize.r,
                      height: _iconSize.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.emeraldDeep,
                      ),
                    )
                  else
                    Icon(
                      Icons.check_rounded,
                      size: _iconSize.r,
                      color: AppColors.emeraldDeep,
                    ),
                  SizedBox(width: 7.w),
                  Text(l10n.saveFabLabel, style: labelStyle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSavePressed(
    BuildContext context,
    WidgetRef ref, {
    required String uid,
    required UserModel user,
  }) async {
    bool personalSaved = false;
    // 1. Persist staged personal-amol edits (batched Firestore writes).
    final pendingNotifier =
        ref.read(personalAmolPendingProvider(uid).notifier);
    if (ref.read(personalAmolPendingProvider(uid)).dirty) {
      try {
        await pendingNotifier.saveToday();
        personalSaved = true;
      } catch (_) {
        // Keep going so a personal-save failure never blocks the community
        // submission below.
      }
    }
    // 2. Submit the community amol as today only if it still has unsaved
    //    toggles (may navigate to the day-complete screen, unchanged).
    if (!context.mounted) return;
    final amal = ref.read(amalProvider(uid));
    if (!amal.isSubmitted && amal.hasAnyDone) {
      await submitTodaysAmal(context, ref, uid: uid, user: user);
    } else if (personalSaved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ব্যক্তিগত আমল সংরক্ষণ করা হয়েছে ✓')),
      );
    }
  }
}

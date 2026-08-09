import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/amal_entry_policy.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';

/// Compact special-time switch shown as the top row of the home progress card
/// for users on the female amal profile.
class HomeSpecialTimeToggle extends ConsumerWidget {
  const HomeSpecialTimeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = ref.watch(isSpecialTimeActiveForCurrentEntryProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: SizedBox(
        height: 22.h,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 16.r, color: AppColors.gold),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                l10n.specialTimeToggleTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge(
                  context,
                ).copyWith(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _setSpecialTimeActive(ref, !isActive),
              child: Padding(
                padding: EdgeInsets.all(
                  10.r,
                ), // hitSlop — enlarges tap area only
                child: SizedBox(
                  height: 20.h,
                  width: 34.w,
                  child: IgnorePointer(
                    // Outer GestureDetector owns the tap; switch is visual only.
                    child: Transform.scale(
                      scale: 0.85,
                      child: Switch.adaptive(
                        value: isActive,
                        onChanged: null,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        activeThumbColor: AppColors.emeraldDeep,
                        activeTrackColor: AppColors.gold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setSpecialTimeActive(WidgetRef ref, bool value) async {
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null) return;
    await ref
        .read(firestoreServiceProvider)
        .updateUserGenderPreferences(uid, specialTimeActive: value);
  }
}

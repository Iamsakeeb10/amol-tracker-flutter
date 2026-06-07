import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';
import '../../core/utils/submit_todays_amal.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/amal_provider.dart';
import '../../providers/auth_provider.dart';

/// Save FAB for home tab; rendered on [ScaffoldWithBottomNav] above bottom nav.
class HomeSaveFab extends ConsumerWidget {
  const HomeSaveFab({super.key});

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

    if (isSubmitted || !hasAnyDone) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.saveTodaysAmal,
      child: FloatingActionButton(
        onPressed: isAmalLoading
            ? null
            : () => submitTodaysAmal(
                context,
                ref,
                uid: uid,
                user: user,
              ),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.emeraldDeep,
        child: isAmalLoading
            ? SizedBox(
                width: 22.r,
                height: 22.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.emeraldDeep,
                ),
              )
            : Icon(Icons.save_rounded, size: 22.r),
      ),
    );
  }
}

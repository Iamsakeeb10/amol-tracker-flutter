import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/utils/streak_helper.dart';
import '../../models/user_model.dart';
import '../../providers/amal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/streak_freeze_modal.dart';

/*
Purpose:
  Submit today's amal from any entry point (home FAB, inline button, etc.).

Response:
  Navigates to day-complete on success; may show streak-freeze modal first.

Business Rules:
  - No-op when submit returns null (validation / already submitted).
  - Streak freeze modal blocks navigation until user chooses freeze or reset.

Flow:
  1. Call amal notifier submit with current user.
  2. Exit early when result is null or context unmounted.
  3. Show freeze modal or push day-complete with submitted log.

Side Effects:
  - Persists amal log and may update streak via notifier.

Failure Cases:
  - submit returns null; context unmounted before navigation.
*/
Future<void> submitTodaysAmal(
  BuildContext context,
  WidgetRef ref, {
  required String uid,
  required UserModel user,
}) async {
  final notifier = ref.read(amalProvider(uid).notifier);
  final result = await notifier.submit(user);
  if (!context.mounted) return;
  if (result == null) return;

  if (result.streakResult.action == StreakAction.showFreeze) {
    await StreakFreezeModal.show(
      context,
      preservedStreak: result.streakResult.newCurrentStreak,
      onUseFreeze: () async {
        await notifier.applyFreeze(
          user,
          hijri: result.log.hijriDate,
          preservedStreak: result.streakResult.newCurrentStreak,
        );
        // Invalidate so the bottomsheet and other UI see the updated streakFreezeDate immediately.
        ref.invalidate(currentUserProvider);
        if (!context.mounted) return;
        context.push(AppRoutes.dayComplete, extra: result.log);
      },
      onResetStreak: () async {
        await notifier.resetStreak(user.uid);
        ref.invalidate(currentUserProvider);
        if (!context.mounted) return;
        context.push(AppRoutes.dayComplete, extra: result.log);
      },
    );
  } else {
    context.push(AppRoutes.dayComplete, extra: result.log);
  }
}

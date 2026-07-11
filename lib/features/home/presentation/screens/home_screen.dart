import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/default_amal_fields.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/score_calculator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../models/announcement_model.dart';
import '../../../../providers/amal_fields_provider.dart';
import '../../../../providers/amal_provider.dart';
import '../../../../providers/announcement_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/date_provider.dart';
import '../../../../providers/history_provider.dart';
import '../../../../shared/widgets/announcement_modal.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../widgets/home_scroll_body.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<String> _sessionDismissedAnnouncementIds = <String>{};
  bool _isAnnouncementDialogOpen = false;
  String? _trackedUserId;
  String? _scheduledAnnouncementId;
  bool _didInitialAnnouncementCheck = false;

  void _resetAnnouncementSessionForUser(String? uid) {
    _sessionDismissedAnnouncementIds.clear();
    _isAnnouncementDialogOpen = false;
    _scheduledAnnouncementId = null;
    _trackedUserId = uid;
    _didInitialAnnouncementCheck = false;
  }

  AnnouncementModel? _resolveNextAnnouncement() {
    final announcements = ref.read(announcementsProvider).value ?? const [];
    final user = ref.read(currentUserProvider).value;
    if (user == null || announcements.isEmpty) return null;

    final seen = user.seenAnnouncements;
    for (final announcement in announcements) {
      if (_sessionDismissedAnnouncementIds.contains(announcement.id)) {
        continue;
      }
      if (!announcement.showOnce || !seen.contains(announcement.id)) {
        return announcement;
      }
    }
    return null;
  }

  void _scheduleAnnouncementShow() {
    if (!mounted || _isAnnouncementDialogOpen) return;

    final target = _resolveNextAnnouncement();
    if (target == null) return;
    if (_scheduledAnnouncementId == target.id) return;

    _scheduledAnnouncementId = target.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduledAnnouncementId = null;
      _showAnnouncementDialog(target);
    });
  }

  Future<void> _showAnnouncementDialog(AnnouncementModel announcement) async {
    if (!mounted || _isAnnouncementDialogOpen) return;
    if (_sessionDismissedAnnouncementIds.contains(announcement.id)) return;

    _isAnnouncementDialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.54),
      builder: (_) => AnnouncementModal(announcement: announcement),
    );

    if (!mounted) return;
    _isAnnouncementDialogOpen = false;

    setState(() {
      _sessionDismissedAnnouncementIds.add(announcement.id);
    });

    final next = _resolveNextAnnouncement();
    if (next != null && next.id != announcement.id) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      await _showAnnouncementDialog(next);
    }
  }

  Future<void> _retryAmalFields(String uid) async {
    await ref.read(amalFieldsProvider.notifier).forceRefresh();
    if (!mounted) return;
    await ref.read(amalProvider(uid).notifier).refreshFromFields();
  }

  Future<void> _refreshAll(String uid) async {
    ref.invalidate(currentUserProvider);
    ref.invalidate(amalFieldsProvider);
    ref.invalidate(amalProvider(uid));
    ref.invalidate(liveStreakProvider);
    ref.invalidate(announcementsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authUser = ref.watch(authStateProvider).asData?.value;
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.asData?.value;
    final connectivity = ref.watch(connectivityListProvider).asData?.value;

    ref.listen<String?>(
      authStateProvider.select((auth) => auth.asData?.value?.uid),
      (previousUid, nextUid) {
        if (previousUid == nextUid) return;
        _resetAnnouncementSessionForUser(nextUid);
        if (nextUid != null) _scheduleAnnouncementShow();
      },
    );
    ref.listen(currentUserProvider, (previous, next) {
      final nextUser = next.asData?.value;
      if (nextUser == null) return;
      if (_trackedUserId != nextUser.uid) {
        _resetAnnouncementSessionForUser(nextUser.uid);
      }
      _scheduleAnnouncementShow();

      // Push widget update immediately with the live streak.
      final liveValue = ref.read(liveStreakProvider).value;
      final resolvedStreak = liveValue ?? nextUser.currentStreak;
      unawaited(
        ref
            .read(amalProvider(nextUser.uid).notifier)
            .refreshWidgetData(streakOverride: resolvedStreak),
      );
    });
    // When liveStreakProvider finishes loading (or refreshes after submit),
    // push the correct streak to the native home screen widget.
    ref.listen<AsyncValue<int>>(liveStreakProvider, (previous, next) {
      final liveValue = next.value;
      if (liveValue == null) return;
      final uid = authUser?.uid;
      if (uid == null) return;
      unawaited(
        ref
            .read(amalProvider(uid).notifier)
            .refreshWidgetData(streakOverride: liveValue),
      );
    });
    ref.listen(announcementsProvider, (previous, next) {
      if (!next.hasValue) return;
      _scheduleAnnouncementShow();
    });
    ref.listen<AnnouncementModel?>(pendingAnnouncementProvider, (
      previous,
      next,
    ) {
      if (next == null) return;
      _scheduleAnnouncementShow();
    });

    if (authUser == null) {
      return AppScaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    if (userAsync.hasError) {
      return AppScaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.historyLoadFailed,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(context),
                ),
                SizedBox(height: 16.h),
                FilledButton(
                  onPressed: () => ref.invalidate(currentUserProvider),
                  child: Text(l10n.refresh),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (user == null) {
      return AppScaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    if (!_didInitialAnnouncementCheck) {
      _didInitialAnnouncementCheck = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scheduleAnnouncementShow();
      });
    }

    final uid = authUser.uid;
    final fieldsAsync = ref.watch(amalFieldsProvider);
    final fields = ref.watch(amalFieldsListProvider);
    final locale = Localizations.localeOf(context).languageCode;
    final maxScore = getMaxScore(fields).clamp(1, kDefaultMaxDailyScore);
    final doneCount = ref.watch(amalProvider(uid).select((s) => s.doneCount));
    final totalScore = ref.watch(amalProvider(uid).select((s) => s.totalScore));
    final isSubmitted = ref.watch(
      amalProvider(uid).select((s) => s.isSubmitted),
    );
    final isAmalLoading = ref.watch(
      amalProvider(uid).select((s) => s.isLoading),
    );
    final hasAnyDone = ref.watch(amalProvider(uid).select((s) => s.hasAnyDone));
    final amalError = ref.watch(amalProvider(uid).select((s) => s.error));
    ref.listen(amalProvider(uid).select((s) => s.error), (previous, next) {
      if (!mounted || next == null || previous == next) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
    });

    final offline =
        connectivity != null && connectivity.contains(ConnectivityResult.none);
    final liveStreakAsync = ref.watch(liveStreakProvider);
    final liveStreak = liveStreakAsync.value;
    // Show null (loader) while live streak is loading, then use the computed value.
    final streakValue = liveStreakAsync is AsyncLoading
        ? null
        : (liveStreak ?? user.currentStreak);
    final isNewUser = user.lastLogDate.trim().isEmpty && !isSubmitted;
    final todayHijri = ref.watch(currentHijriDateProvider);
    final submittedLog = ref.watch(
      amalProvider(uid).select((s) => s.submittedLog),
    );
    ref.watch(amalLogRefreshProvider);

    return AppScaffold(
      padding: EdgeInsets.zero,
      body: HomeScrollBody(
        uid: uid,
        fieldsAsync: fieldsAsync,
        fields: fields,
        locale: locale,
        offline: offline,
        amalError: amalError,
        doneCount: doneCount,
        totalScore: totalScore,
        maxScore: maxScore,
        isSubmitted: isSubmitted,
        isAmalLoading: isAmalLoading,
        hasAnyDone: hasAnyDone,
        isNewUser: isNewUser,
        streak: streakValue,
        submittedLog: submittedLog,
        showSaveFab: !isSubmitted && hasAnyDone,
        onRefreshAll: () => _refreshAll(uid),
        onRetryFields: () => _retryAmalFields(uid),
        onEditTodayAmal: (log) => _onEditTodayAmal(
          context,
          uid: uid,
          todayHijri: todayHijri,
          log: log,
        ),
      ),
    );
  }

  Future<void> _onEditTodayAmal(
    BuildContext context, {
    required String uid,
    required String todayHijri,
    required AmalLogModel log,
  }) async {
    await context.push(AppRoutes.editAmalPath(todayHijri), extra: log);
    if (!mounted) return;
    ref.invalidate(amalProvider(uid));
  }
}

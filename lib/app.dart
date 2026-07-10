import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show Platform;

import 'core/router/router.dart';
import 'core/services/analytics_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/theme.dart';
import 'features/badges/presentation/widgets/badge_celebration_overlay.dart';
import 'features/syllabus/presentation/widgets/lms_level_up_overlay.dart';
import 'l10n/app_localizations.dart';
import 'providers/amal_fields_provider.dart';
import 'providers/amal_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/badge_celebration_provider.dart';
import 'providers/date_provider.dart';
import 'providers/locale_provider.dart';

class AmolTrackerApp extends ConsumerStatefulWidget {
  const AmolTrackerApp({super.key});

  @override
  ConsumerState<AmolTrackerApp> createState() => _AmolTrackerAppState();
}

class _AmolTrackerAppState extends ConsumerState<AmolTrackerApp>
    with WidgetsBindingObserver {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = buildAppRouter();
    unawaited(_initNotifications());
    unawaited(_setupCrashlytics());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(appBootstrapProvider.future));
      _scheduleSmartReminders();
    });
  }

  Future<void> _setupCrashlytics() async {
    // Set user ID on auth state changes
    ref.listen(authStateProvider, (prev, next) {
      final user = next.asData?.value;
      if (user != null) {
        AnalyticsService.instance.setUserIdentifier(user.uid);
      } else {
        AnalyticsService.instance.setUserIdentifier('');
      }
    });

    // Set custom keys
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final locale = Platform.localeName;
      final lang = ref.read(localeProvider).languageCode;
      await AnalyticsService.instance.setCustomKeys(
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        language: lang,
        deviceLocale: locale,
      );
    } catch (_) {}
  }

  Future<void> _initNotifications() async {
    await NotificationService.instance.initialize(
      onDeepLink: (route) {
        if (!mounted) return;
        _router.go(route);
      },
    );
  }

  Future<void> _onAppResumed() async {
    final previousDate = ref.read(currentHijriDateProvider);
    ref.invalidate(currentHijriDateProvider);
    final nextDate = ref.read(currentHijriDateProvider);
    if (previousDate != nextDate) {
      final uid = ref.read(currentUserProvider).asData?.value?.uid;
      if (uid != null) {
        unawaited(ref.read(amalProvider(uid).notifier).reloadForNewDay());
      }
    }
    await NotificationService.instance.rescheduleAll();
    _scheduleSmartReminders();
    if (!mounted) return;
    ref.read(badgeCelebrationProvider.notifier).retryPendingWrites();
    ref.read(amalFieldsProvider.notifier).refreshIfStale();
  }

  void _scheduleSmartReminders() {
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) return;
    final locale = ref.read(localeProvider).languageCode;
    unawaited(
      NotificationService.instance.scheduleSmartReminders(
        uid: user.uid,
        currentStreak: user.currentStreak,
        lastLogDate: user.lastLogDate,
        locale: locale,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(_onAppResumed());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.instance.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.build(context, locale: locale),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQueryData.fromView(
            View.of(context),
          ).copyWith(alwaysUse24HourFormat: false),
          child: LmsLevelUpHost(
            child: BadgeCelebrationHost(child: child!),
          ),
        );
      },
      routerConfig: _router,
    );
  }
}

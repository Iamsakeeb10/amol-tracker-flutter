import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/services/notification_service.dart';
import 'core/router/router.dart';
import 'core/theme/theme.dart';
import 'l10n/app_localizations.dart';
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
    NotificationService.instance.initialize(
      onDeepLink: (route) {
        if (!mounted) return;
        _router.go(route);
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      NotificationService.instance.rescheduleAll();
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
      theme: AppTheme.build(context),
      routerConfig: _router,
    );
  }
}

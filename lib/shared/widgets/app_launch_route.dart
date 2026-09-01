import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_redirect.dart';
import '../../core/router/routes.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/firestore_service.dart';
import 'app_launch_screen.dart';

/// Launch route: paints [AppLaunchScreen], removes native splash, then navigates on.
class AppLaunchRoute extends StatefulWidget {
  const AppLaunchRoute({super.key, required this.firestoreService});

  final FirestoreService firestoreService;

  @override
  State<AppLaunchRoute> createState() => _AppLaunchRouteState();
}

class _AppLaunchRouteState extends State<AppLaunchRoute> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_leaveLaunch()));
  }

  Future<void> _leaveLaunch() async {
    if (_navigated) return;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_navigateToDestination());
    });
  }

  Future<void> _navigateToDestination() async {
    if (_navigated || !mounted) return;
    try {
      final destination =
          await destinationAfterLaunch(widget.firestoreService);
      if (!mounted || _navigated) return;
      _navigated = true;
      context.go(destination);
    } catch (e, st) {
      AnalyticsService.instance.recordError(
        e,
        st,
        reason: 'AppLaunchRoute navigation failed',
      );
      if (!mounted || _navigated) return;
      _navigated = true;
      context.go(AppRoutes.signIn);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: true,
        child: const AppLaunchScreen(),
      );
}

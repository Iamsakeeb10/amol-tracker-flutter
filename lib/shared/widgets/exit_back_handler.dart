import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/exit_app_debug.dart';
import '../../core/utils/show_exit_app_dialog.dart';

/// Intercepts only the system back button. Safe to use inside route pages —
/// unlike [GoRoute.onExit], this does not run during [GoRouter.go] redirects.
class ExitBackHandler extends StatelessWidget {
  final Widget child;

  const ExitBackHandler({super.key, required this.child});

  Future<void> _handleBack(BuildContext context) async {
    final router = GoRouter.of(context);
    final route = GoRouterState.of(context).matchedLocation;
    exitAppDebug(
      'back — route=$route canPop=${router.canPop()} '
      'mounted=${context.mounted}',
    );

    if (router.canPop()) {
      exitAppDebug('back — router.pop()');
      router.pop();
      return;
    }

    if (!context.mounted) return;

    exitAppDebug('back — show exit dialog');
    final shouldExit = await showExitAppDialog(context);
    exitAppDebug('back — dialog result=$shouldExit');

    if (shouldExit == true && context.mounted) {
      exitAppDebug('back — SystemNavigator.pop()');
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack(context);
      },
      child: BackButtonListener(
        onBackButtonPressed: () async {
          await _handleBack(context);
          return true;
        },
        child: child,
      ),
    );
  }
}

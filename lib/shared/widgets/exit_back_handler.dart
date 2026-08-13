import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/exit_app_debug.dart';
import '../../core/utils/show_exit_app_dialog.dart';

/// Intercepts only the system back button. Safe to use inside route pages —
/// unlike [GoRoute.onExit], this does not run during [GoRouter.go] redirects.
///
/// NOTE: This now uses PopScope only (no BackButtonListener). Mixing the two
/// caused a bug where this handler's BackButtonListener — which is not
/// route-stack-aware — intercepted every back press ahead of any dialog's
/// own PopScope (e.g. a required showDialog on top of Home), always
/// self-reported `return true` regardless of what _handleBack actually did,
/// and swallowed the event even when it correctly detected a dialog was
/// open and chose to no-op. PopScope alone respects route stack ordering
/// the same way ConfirmExitAppOnBack does, so a dialog above this in the
/// Navigator gets first right of refusal automatically.
class ExitBackHandler extends StatelessWidget {
  final Widget child;

  const ExitBackHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    final canPop = router.canPop();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // If router.canPop() was true but didPop is false, another PopScope
        // further down the widget tree blocked the pop (e.g. unsaved changes).
        // We should respect that and NOT show the exit app dialog.
        if (canPop) return;
        
        if (!context.mounted) return;

        final currentRouteName = ModalRoute.of(context)?.settings.name;
        if (currentRouteName != 'home') {
          context.go('/home');
          return;
        }

        exitAppDebug('back — show exit dialog');
        final shouldExit = await showExitAppDialog(context);
        exitAppDebug('back — dialog result=$shouldExit');

        if (shouldExit == true && context.mounted) {
          exitAppDebug('back — SystemNavigator.pop()');
          SystemNavigator.pop();
        }
      },
      child: child,
    );
  }
}

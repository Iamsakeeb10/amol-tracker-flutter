import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'exit_app_debug.dart';
import 'show_exit_app_dialog.dart';

/*
Purpose:
  Intercept the Android/gesture back event at the shell-route level and ask
  the user to confirm before exiting the app. On confirmation it calls
  SystemNavigator.pop() to close the process.

Response:
  Wraps [child] in a PopScope. Returns the child unchanged on platforms where
  the back gesture would not exit the app (the pop is allowed to propagate).

Business Rules:
  - canPop is always false so Flutter never handles the pop automatically at
    this level; we decide what happens ourselves.
  - If the user taps "Stay" or dismisses the dialog the app stays open.
  - If the user taps "Exit" we call SystemNavigator.pop().

Flow:
  1. System fires back event → onPopInvokedWithResult is called (didPop=false).
  2. Open AmolExitDialog via showExitAppDialog().
  3. If result == true  → SystemNavigator.pop() (exit app).
  4. If result != true → do nothing (stay in app).

Side Effects:
  Calls SystemNavigator.pop() which terminates the Flutter activity on Android.

Failure Cases:
  - If context is no longer mounted after await, exit is skipped safely.
*/
class ConfirmExitAppOnBack extends StatelessWidget {
  const ConfirmExitAppOnBack({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final rootNavigator = Navigator.of(context, rootNavigator: true);
        if (rootNavigator.canPop()) {
          exitAppDebug(
            'ConfirmExitAppOnBack — dialog/route active on root navigator, ignoring',
          );
          return;
        }
        exitAppDebug('ConfirmExitAppOnBack — back intercepted, showing dialog');
        final shouldExit = await showExitAppDialog(context);
        exitAppDebug('ConfirmExitAppOnBack — dialog result=$shouldExit');
        if (shouldExit == true) {
          exitAppDebug('ConfirmExitAppOnBack — calling SystemNavigator.pop()');
          await SystemNavigator.pop();
        }
      },
      child: child,
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/utils/exit_app_debug.dart';
import '../../shared/widgets/amol_exit_dialog.dart';

/*
Purpose:
  Ask the user to confirm before leaving the app via the system back gesture.

Response:
  true when the user chooses to exit; false or null when they stay.

Business Rules:
  - Uses the branded AmolExitDialog with localized copy.
  - Cancel / dismiss keeps the app open; Exit closes the app (caller calls SystemNavigator.pop).

Flow:
  1. Present AmolExitDialog.
  2. Return the dialog result.

Side Effects:
  None (navigation exit is handled by the caller).

Failure Cases:
  Returns null if the dialog is dismissed without a choice.
*/
Future<bool?> showExitAppDialog(BuildContext context) {
  exitAppDebug('showDialog — opening AmolExitDialog mounted=${context.mounted}');
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      exitAppDebug('showDialog — builder called');
      return const AmolExitDialog();
    },
  ).then((value) {
    exitAppDebug('showDialog — closed with value=$value');
    return value;
  }).catchError((Object error, StackTrace stack) {
    exitAppDebug('showDialog — error=$error');
    Error.throwWithStackTrace(error, stack);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/utils/show_exit_app_dialog.dart';

/// Back control for bottom-navigation tab roots and related feature screens.
class BottomTabBackButton extends StatelessWidget {
  const BottomTabBackButton({
    super.key,
    this.fallbackRoute = AppRoutes.home,
    this.style,
    this.iconSize,
  });

  final String fallbackRoute;
  final ButtonStyle? style;
  final double? iconSize;

  static bool isHomeRoute(BuildContext context) {
    return GoRouterState.of(context).matchedLocation.startsWith(AppRoutes.home);
  }

  Future<void> _handlePress(BuildContext context) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (rootNavigator.canPop()) {
      rootNavigator.pop();
      return;
    }

    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }

    if (isHomeRoute(context)) {
      final shouldExit = await showExitAppDialog(context);
      if (shouldExit == true && context.mounted) {
        await SystemNavigator.pop();
      }
      return;
    }

    if (context.mounted) {
      context.go(fallbackRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      style: style ??
          IconButton.styleFrom(
            padding: EdgeInsets.all(10.r),
            minimumSize: Size(44.r, 44.r),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
      onPressed: () => _handlePress(context),
      icon: Icon(Icons.arrow_back, size: iconSize ?? 22.r),
    );
  }
}

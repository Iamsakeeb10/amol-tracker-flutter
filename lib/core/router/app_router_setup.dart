import 'package:go_router/go_router.dart';

import 'safe_back_button_dispatcher.dart';

/// Router instance plus the guarded back-button dispatcher wired to it.
class AppRouterSetup {
  const AppRouterSetup({
    required this.router,
    required this.backButtonDispatcher,
  });

  final GoRouter router;
  final SafeBackButtonDispatcher backButtonDispatcher;
}

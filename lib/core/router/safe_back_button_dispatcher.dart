import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Guards Android system back from known [GoRouterDelegate.popRoute] crashes.
///
/// go_router 17.2.x calls [GoRouterDelegate._findCurrentNavigators] without
/// checking for an empty [RouteMatchList], which throws `Bad state: No element`
/// during startup, redirects, and other transient navigation windows.
///
/// See https://github.com/flutter/flutter/issues/187616
class SafeBackButtonDispatcher extends RootBackButtonDispatcher {
  SafeBackButtonDispatcher(this._routerGetter);

  final GoRouter Function() _routerGetter;

  GoRouter get _router => _routerGetter();

  @override
  Future<bool> didPopRoute() {
    if (_router.routerDelegate.currentConfiguration.isEmpty) {
      return SynchronousFuture<bool>(false);
    }

    return super.didPopRoute().catchError((Object error, StackTrace stack) {
      if (_isKnownPopRouteFailure(error)) {
        return false;
      }
      Error.throwWithStackTrace(error, stack);
    });
  }

  bool _isKnownPopRouteFailure(Object error) {
    return error is StateError || error is TypeError;
  }
}

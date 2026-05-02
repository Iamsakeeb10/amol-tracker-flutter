import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/router/router.dart';
import 'core/theme/theme.dart';

class AmolTrackerApp extends StatefulWidget {
  const AmolTrackerApp({super.key});

  @override
  State<AmolTrackerApp> createState() => _AmolTrackerAppState();
}

class _AmolTrackerAppState extends State<AmolTrackerApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildAppRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Amol Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(context),
      routerConfig: _router,
    );
  }
}

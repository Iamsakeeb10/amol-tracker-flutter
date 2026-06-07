import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../screens/day_detail_screen.dart';

class HistoryDateRouteGuard extends StatelessWidget {
  const HistoryDateRouteGuard({super.key, required this.hijriDate});

  final String hijriDate;

  @override
  Widget build(BuildContext context) {
    if (hijriDate.isEmpty) {
      return const _HistoryRouteRedirect();
    }
    return DayDetailScreen(hijriDate: hijriDate);
  }
}

class _HistoryRouteRedirect extends StatefulWidget {
  const _HistoryRouteRedirect();

  @override
  State<_HistoryRouteRedirect> createState() => _HistoryRouteRedirectState();
}

class _HistoryRouteRedirectState extends State<_HistoryRouteRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(AppRoutes.history);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.emeraldDeep,
      body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../providers/history_provider.dart';
import '../screens/edit_amal_screen.dart';

class EditAmalRouteGuard extends ConsumerWidget {
  const EditAmalRouteGuard({
    super.key,
    required this.hijriDate,
    this.existingLog,
  });

  final String hijriDate;
  final AmalLogModel? existingLog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (hijriDate.isEmpty) {
      return _RouteRedirect(destination: AppRoutes.history);
    }

    final editableAsync = ref.watch(editableDayProvider(hijriDate));
    return editableAsync.when(
      data: (editable) {
        if (!editable.canEdit) {
          return _RouteRedirect(destination: AppRoutes.dayDetailPath(hijriDate));
        }
        return EditAmalScreen(
          hijriDate: hijriDate,
          existingLog: existingLog ?? editable.existingLog,
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.emeraldDeep,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      ),
      error: (_, _) => _RouteRedirect(destination: AppRoutes.history),
    );
  }
}

class _RouteRedirect extends StatefulWidget {
  const _RouteRedirect({required this.destination});

  final String destination;

  @override
  State<_RouteRedirect> createState() => _RouteRedirectState();
}

class _RouteRedirectState extends State<_RouteRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(widget.destination);
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

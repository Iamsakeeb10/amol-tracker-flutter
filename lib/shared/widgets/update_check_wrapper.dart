import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_config_provider.dart';
import 'update_modal.dart';

class UpdateCheckHost extends ConsumerStatefulWidget {
  const UpdateCheckHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateCheckHost> createState() => _UpdateCheckHostState();
}

class _UpdateCheckHostState extends ConsumerState<UpdateCheckHost>
    with WidgetsBindingObserver {
  bool _isDialogOpen = false;
  bool _didCheckOnLaunch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkForUpdate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkForUpdate();
    }
  }

  void _checkForUpdate() {
    if (_isDialogOpen || !mounted) return;

    final status = ref.read(updateStatusProvider);
    if (!status.isAvailable || status.config == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDialogOpen) return;
      _showUpdateDialog(status);
    });
  }

  Future<void> _showUpdateDialog(UpdateStatus status) async {
    if (!mounted || _isDialogOpen) return;
    _isDialogOpen = true;

    await UpdateModal.show(
      context,
      config: status.config!,
      installedVersionCode: status.installedVersionCode,
    );

    if (!mounted) return;
    _isDialogOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UpdateStatus>(updateStatusProvider, (prev, next) {
      if (next.isAvailable && !_isDialogOpen) {
        _checkForUpdate();
      }
    });

    return widget.child;
  }
}

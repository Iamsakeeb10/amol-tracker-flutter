import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/admin_config.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/app_config_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/update_modal.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminAppConfigFormScreen extends ConsumerStatefulWidget {
  const AdminAppConfigFormScreen({super.key, this.existing});

  final AppConfigModel? existing;

  @override
  ConsumerState<AdminAppConfigFormScreen> createState() =>
      _AdminAppConfigFormScreenState();
}

class _AdminAppConfigFormScreenState
    extends ConsumerState<AdminAppConfigFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _latestVersionCtrl;
  late final TextEditingController _latestVersionCodeCtrl;
  late final TextEditingController _playStoreUrlCtrl;
  late final TextEditingController _updateTitleCtrl;
  late final TextEditingController _updateMessageCtrl;
  late final TextEditingController _minSupportedVersionCodeCtrl;
  late final TextEditingController _buttonLabelCtrl;
  late bool _forceUpdate;
  late bool _isActive;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _latestVersionCtrl = TextEditingController(text: e?.latestVersion ?? '');
    _latestVersionCodeCtrl = TextEditingController(
      text: e?.latestVersionCode.toString() ?? '',
    );
    _playStoreUrlCtrl = TextEditingController(text: e?.playStoreUrl ?? '');
    _updateTitleCtrl = TextEditingController(text: e?.updateTitle ?? '');
    _updateMessageCtrl = TextEditingController(text: e?.updateMessage ?? '');
    _minSupportedVersionCodeCtrl = TextEditingController(
      text: e?.minSupportedVersionCode.toString() ?? '',
    );
    _buttonLabelCtrl = TextEditingController(text: e?.buttonLabel ?? '');
    _forceUpdate = e?.forceUpdate ?? false;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _latestVersionCtrl.dispose();
    _latestVersionCodeCtrl.dispose();
    _playStoreUrlCtrl.dispose();
    _updateTitleCtrl.dispose();
    _updateMessageCtrl.dispose();
    _minSupportedVersionCodeCtrl.dispose();
    _buttonLabelCtrl.dispose();
    super.dispose();
  }

  AppConfigModel _buildDraft() {
    return AppConfigModel(
      id: widget.existing?.id ?? 'preview',
      latestVersion: _latestVersionCtrl.text.trim(),
      latestVersionCode: int.tryParse(_latestVersionCodeCtrl.text.trim()) ?? 0,
      playStoreUrl: _playStoreUrlCtrl.text.trim(),
      updateTitle: _updateTitleCtrl.text.trim(),
      updateMessage: _updateMessageCtrl.text.trim(),
      forceUpdate: _forceUpdate,
      minSupportedVersionCode:
          int.tryParse(_minSupportedVersionCodeCtrl.text.trim()) ?? 0,
      isActive: _isActive,
      buttonLabel: _buttonLabelCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider).asData?.value;
    if (!AdminConfig.isFullAdmin(user?.email, role: user?.role)) return;

    setState(() => _isSaving = true);

    final data = <String, dynamic>{
      'latestVersion': _latestVersionCtrl.text.trim(),
      'latestVersionCode': int.tryParse(_latestVersionCodeCtrl.text.trim()) ?? 0,
      'playStoreUrl': _playStoreUrlCtrl.text.trim(),
      'updateTitle': _updateTitleCtrl.text.trim(),
      'updateMessage': _updateMessageCtrl.text.trim(),
      'minSupportedVersionCode':
          int.tryParse(_minSupportedVersionCodeCtrl.text.trim()) ?? 0,
      'forceUpdate': _forceUpdate,
      'buttonLabel': _buttonLabelCtrl.text.trim(),
      'isActive': _isActive,
    };

    try {
      final service = ref.read(firestoreServiceProvider);
      if (_isEdit) {
        await service.updateAppConfig(widget.existing!.id, data);
      } else {
        await service.createAppConfig(data: data, adminUid: user!.uid);
      }
      if (!mounted) return;
      showAdminSnackBar(
        context,
        message: l10n.adminFormSaved,
        popAfter: true,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showAdminSnackBar(context, message: l10n.adminSaveFailed, isError: true);
    }
  }

  void _preview() {
    final l10n = AppLocalizations.of(context)!;
    if (_latestVersionCodeCtrl.text.trim().isEmpty) {
      showAdminSnackBar(context, message: l10n.adminPreviewRequired, isError: true);
      return;
    }
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.54),
      builder: (_) => UpdateModal(
        config: _buildDraft(),
        installedVersionCode: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).asData?.value;

    if (!AdminConfig.isFullAdmin(user?.email, role: user?.role)) {
      return AppScaffold(
        body: Center(
          child: Text(
            l10n.adminNotAuthorized,
            style: AppTextStyles.bodyMedium(context),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final formTitle = _isEdit
        ? l10n.adminFormEditTitle
        : l10n.adminFormCreateTitle;

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AdminAppBar(
        title: formTitle,
        fallbackRoute: AppRoutes.adminAppConfigList,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
          children: [
            AdminScreenHeader(
              subtitle: l10n.adminAppConfigTitle.toUpperCase(),
              title: formTitle,
            ),
            SizedBox(height: 18.h),
            SectionHeader(title: l10n.adminAppConfigUpdateSettings.toUpperCase()),
            CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminFormField(
                    label: l10n.adminAppConfigLatestVersion,
                    controller: _latestVersionCtrl,
                    icon: Icons.tag,
                    required: true,
                    error: 'Version is required',
                  ),
                  AdminFormField(
                    label: l10n.adminAppConfigLatestVersionCode,
                    controller: _latestVersionCodeCtrl,
                    icon: Icons.code,
                    required: true,
                    error: 'Version code is required',
                    keyboardType: TextInputType.number,
                  ),
                  AdminFormField(
                    label: l10n.adminAppConfigPlayStoreUrl,
                    controller: _playStoreUrlCtrl,
                    icon: Icons.link,
                    required: true,
                    error: 'Play Store URL is required',
                  ),
                  AdminFormField(
                    label: l10n.adminAppConfigUpdateTitle,
                    controller: _updateTitleCtrl,
                    icon: Icons.title,
                  ),
                  AdminFormField(
                    label: l10n.adminAppConfigUpdateMessage,
                    controller: _updateMessageCtrl,
                    icon: Icons.message,
                    maxLines: 3,
                  ),
                  AdminFormField(
                    label: l10n.adminAppConfigMinVersionCode,
                    controller: _minSupportedVersionCodeCtrl,
                    icon: Icons.warning_amber,
                    keyboardType: TextInputType.number,
                  ),
                  AdminFormField(
                    label: l10n.adminAppConfigButtonLabel,
                    controller: _buttonLabelCtrl,
                    icon: Icons.text_fields,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SectionHeader(title: l10n.adminAppConfigFlags.toUpperCase()),
            CardContainer(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
              child: Column(
                children: [
                  AdminToggleRow(
                    icon: Icons.toggle_on_outlined,
                    title: l10n.adminAppConfigActive,
                    subtitle: l10n.adminAppConfigActiveSubtitle,
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  const Divider(),
                  AdminToggleRow(
                    icon: Icons.lock_outline,
                    title: l10n.adminAppConfigForceUpdate,
                    subtitle: l10n.adminAppConfigForceUpdateSubtitle,
                    value: _forceUpdate,
                    onChanged: (v) => setState(() => _forceUpdate = v),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            AdminFormActionRow(
              previewLabel: l10n.adminFormPreview,
              saveLabel: l10n.adminFormSave,
              isSaving: _isSaving,
              onPreview: _preview,
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

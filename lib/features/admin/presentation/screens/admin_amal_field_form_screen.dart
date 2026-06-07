import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/admin_config.dart';
import '../../../../core/constants/amal_fields.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/amal_fields_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../widgets/admin_amal_field_helpers.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminAmalFieldFormScreen extends ConsumerStatefulWidget {
  const AdminAmalFieldFormScreen({super.key, this.existing});

  final AmalField? existing;

  @override
  ConsumerState<AdminAmalFieldFormScreen> createState() =>
      _AdminAmalFieldFormScreenState();
}

class _AdminAmalFieldFormScreenState
    extends ConsumerState<AdminAmalFieldFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idCtrl;
  late final TextEditingController _labelEnCtrl;
  late final TextEditingController _labelBnCtrl;
  late final TextEditingController _sublabelEnCtrl;
  late final TextEditingController _sublabelBnCtrl;
  late final TextEditingController _pointsCtrl;
  late final TextEditingController _maxValueCtrl;
  late final TextEditingController _orderCtrl;
  late AmalType _type;
  late bool _isActive;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _idCtrl = TextEditingController(text: e?.id ?? '');
    _labelEnCtrl = TextEditingController(text: e?.label['en'] ?? '');
    _labelBnCtrl = TextEditingController(text: e?.label['bn'] ?? '');
    _sublabelEnCtrl = TextEditingController(text: e?.sublabel['en'] ?? '');
    _sublabelBnCtrl = TextEditingController(text: e?.sublabel['bn'] ?? '');
    _pointsCtrl = TextEditingController(text: '${e?.points ?? 0}');
    _maxValueCtrl = TextEditingController(text: '${e?.maxValue ?? 1}');
    _orderCtrl = TextEditingController(text: '${e?.order ?? 999}');
    _type = e?.type ?? AmalType.boolean;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _labelEnCtrl.dispose();
    _labelBnCtrl.dispose();
    _sublabelEnCtrl.dispose();
    _sublabelBnCtrl.dispose();
    _pointsCtrl.dispose();
    _maxValueCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  int _parseInt(TextEditingController ctrl, {required int fallback}) =>
      int.tryParse(ctrl.text.trim()) ?? fallback;

  AmalField _buildDraft() {
    return buildDraftAmalField(
      id: _isEdit ? widget.existing!.id : _idCtrl.text,
      labelEn: _labelEnCtrl.text,
      labelBn: _labelBnCtrl.text,
      sublabelEn: _sublabelEnCtrl.text,
      sublabelBn: _sublabelBnCtrl.text,
      type: _type,
      points: _parseInt(_pointsCtrl, fallback: 0),
      maxValue: _parseInt(_maxValueCtrl, fallback: 1),
      order: _parseInt(_orderCtrl, fallback: 999),
      isActive: _isActive,
    );
  }

  /*
  Purpose:
  Persist a new or updated amal field definition from the admin form.

  Response:
  Pops screen on success after snackbar; stays on form on failure.

  Business Rules:
  Field id immutable on edit; English label required; soft-delete via isActive only.

  Flow:
  1. Validate form
  2. Build Firestore map
  3. createField or updateField via AmalFieldsService
  4. Show feedback and pop

  Side Effects:
  Firestore write + meta version bump; clients reload fields.

  Failure Cases:
  Shows error snackbar; re-enables save button.
  */
  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider).asData?.value;
    if (!AdminConfig.isFullAdmin(user?.uid, role: user?.role)) return;

    setState(() => _isSaving = true);
    final data = amalFieldToFirestoreMap(
      id: _isEdit ? null : _idCtrl.text.trim(),
      labelEn: _labelEnCtrl.text,
      labelBn: _labelBnCtrl.text,
      sublabelEn: _sublabelEnCtrl.text,
      sublabelBn: _sublabelBnCtrl.text,
      type: _type,
      points: _parseInt(_pointsCtrl, fallback: 0),
      maxValue: _parseInt(_maxValueCtrl, fallback: 1),
      order: _parseInt(_orderCtrl, fallback: 999),
      isActive: _isActive,
    );

    try {
      final service = ref.read(amalFieldsServiceProvider);
      if (_isEdit) {
        await service.updateField(widget.existing!.id, data);
      } else {
        await service.createField(_buildDraft());
      }
      if (!mounted) return;
      showAdminSnackBar(
        context,
        message: l10n.adminAmalFieldSaved,
        popAfter: true,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showAdminSnackBar(
        context,
        message: l10n.adminAmalFieldSaveFailed,
        isError: true,
      );
    }
  }

  void _preview() {
    final l10n = AppLocalizations.of(context)!;
    if (_labelEnCtrl.text.trim().isEmpty) {
      showAdminSnackBar(
        context,
        message: l10n.adminAmalFieldPreviewRequired,
        isError: true,
      );
      return;
    }
    final draft = _buildDraft();
    final locale = amalFieldLocaleCode(context);
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.54),
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.emeraldDeep,
        title: Text(
          l10n.adminFormPreview,
          style: AppTextStyles.headlineMedium(ctx),
        ),
        content: AmalRow(
          field: draft,
          done: draft.type == AmalType.boolean,
          numericValue: draft.type == AmalType.numeric ? 0 : null,
          locale: locale,
          readOnly: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).asData?.value;

    if (!AdminConfig.isFullAdmin(user?.uid, role: user?.role)) {
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
        ? l10n.adminAmalFieldFormEdit
        : l10n.adminAmalFieldFormCreate;

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AdminAppBar(
        title: formTitle,
        fallbackRoute: AppRoutes.adminAmalFields,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
          children: [
            AdminScreenHeader(
              subtitle: l10n.adminAmalFieldsTitle.toUpperCase(),
              title: formTitle,
            ),
            SizedBox(height: 18.h),
            SectionHeader(title: l10n.adminAmalFieldIdentitySection.toUpperCase()),
            CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isEdit) ...[
                    AdminFormField(
                      label: l10n.adminAmalFieldId,
                      controller: _idCtrl,
                      icon: Icons.tag_outlined,
                      readOnly: true,
                    ),
                    Text(
                      l10n.adminAmalFieldIdImmutable,
                      style: AppTextStyles.bodySmall(context),
                    ),
                  ] else
                    AdminFormField(
                      label: l10n.adminAmalFieldId,
                      controller: _idCtrl,
                      icon: Icons.tag_outlined,
                      validator: (v) => validateAmalFieldId(v, l10n),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SectionHeader(title: l10n.adminAmalFieldLabelsSection.toUpperCase()),
            CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminFormField(
                    label: l10n.adminAmalFieldLabelEn,
                    controller: _labelEnCtrl,
                    icon: Icons.title_rounded,
                    required: true,
                    error: l10n.adminAmalFieldLabelRequired,
                  ),
                  AdminFormField(
                    label: l10n.adminAmalFieldLabelBn,
                    controller: _labelBnCtrl,
                    icon: Icons.translate_rounded,
                  ),
                  AdminFormField(
                    label: l10n.adminAmalFieldSublabelEn,
                    controller: _sublabelEnCtrl,
                    icon: Icons.notes_outlined,
                    maxLines: 2,
                  ),
                  AdminFormField(
                    label: l10n.adminAmalFieldSublabelBn,
                    controller: _sublabelBnCtrl,
                    icon: Icons.notes_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SectionHeader(title: l10n.adminAmalFieldScoringSection.toUpperCase()),
            CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Text(
                      l10n.adminFormType,
                      style: AppTextStyles.label(context),
                    ),
                  ),
                  AdminAmalTypeSelector(
                    selected: _type,
                    onChanged: (v) => setState(() => _type = v),
                  ),
                  SizedBox(height: 12.h),
                  AdminFormField(
                    label: l10n.adminAmalFieldPoints,
                    controller: _pointsCtrl,
                    icon: Icons.star_outline,
                    keyboardType: TextInputType.number,
                    validator: (v) => validatePoints(v, l10n),
                  ),
                  if (_type == AmalType.numeric)
                    AdminFormField(
                      label: l10n.adminAmalFieldMaxValue,
                      controller: _maxValueCtrl,
                      icon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) => validateMaxValue(v, l10n),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SectionHeader(title: l10n.adminAmalFieldDisplaySection.toUpperCase()),
            CardContainer(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
              child: Column(
                children: [
                  AdminFormField(
                    label: l10n.adminAmalFieldOrder,
                    controller: _orderCtrl,
                    icon: Icons.format_list_numbered_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) => validateOrder(v, l10n),
                  ),
                  const Divider(),
                  AdminToggleRow(
                    icon: Icons.toggle_on_outlined,
                    title: l10n.adminFormActive,
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
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

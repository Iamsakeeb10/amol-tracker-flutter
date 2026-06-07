import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/admin_config.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/announcement_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/announcement_modal.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../widgets/admin_announcement_helpers.dart';
import '../widgets/admin_form_date_field.dart';

class AdminAnnouncementFormScreen extends ConsumerStatefulWidget {
  const AdminAnnouncementFormScreen({super.key, this.existing});

  final AnnouncementModel? existing;

  @override
  ConsumerState<AdminAnnouncementFormScreen> createState() =>
      _AdminAnnouncementFormScreenState();
}

class _AdminAnnouncementFormScreenState
    extends ConsumerState<AdminAnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _messageCtrl;
  late final TextEditingController _arabicCtrl;
  late final TextEditingController _imageCtrl;
  late String _type;
  late bool _isActive;
  late bool _showOnce;
  DateTime? _startsAt;
  DateTime? _expiresAt;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _messageCtrl = TextEditingController(text: e?.message ?? '');
    _arabicCtrl = TextEditingController(text: e?.arabicText ?? '');
    _imageCtrl = TextEditingController(text: e?.imageUrl ?? '');
    _type = normalizeAnnouncementType(e?.type);
    _isActive = e?.isActive ?? true;
    _showOnce = e?.showOnce ?? false;
    _startsAt = e?.startsAt;
    _expiresAt = e?.expiresAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _arabicCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  AnnouncementModel _buildDraft() {
    return AnnouncementModel(
      id: widget.existing?.id ?? 'preview',
      title: _titleCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
      arabicText: _nullable(_arabicCtrl.text),
      imageUrl: _nullable(_imageCtrl.text),
      type: _type,
      isActive: _isActive,
      startsAt: _startsAt,
      expiresAt: _expiresAt,
      showOnce: _showOnce,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
  }

  String? _nullable(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (!isAnnouncementScheduleValid(
      startsAt: _startsAt,
      expiresAt: _expiresAt,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminDateRangeInvalid)),
      );
      return;
    }

    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (!AdminConfig.isAdmin(uid)) return;

    setState(() => _isSaving = true);
    final data = announcementToFirestoreMap(
      title: _titleCtrl.text,
      message: _messageCtrl.text,
      type: _type,
      isActive: _isActive,
      showOnce: _showOnce,
      arabicText: _arabicCtrl.text,
      imageUrl: _imageCtrl.text,
      startsAt: _startsAt,
      expiresAt: _expiresAt,
      forUpdate: _isEdit,
    );

    try {
      final service = ref.read(firestoreServiceProvider);
      if (_isEdit) {
        await service.updateAnnouncement(widget.existing!.id, data);
      } else {
        await service.createAnnouncement(data: data, adminUid: uid!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminFormSaved)),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminSaveFailed)),
      );
    }
  }

  void _preview() {
    final l10n = AppLocalizations.of(context)!;
    if (_titleCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminPreviewRequired)),
      );
      return;
    }
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.54),
      builder: (_) => AnnouncementModal(announcement: _buildDraft()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = ref.watch(authStateProvider).asData?.value?.uid;

    if (!AdminConfig.isAdmin(uid)) {
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

    return AppScaffold(
      padding: EdgeInsets.zero,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
          children: [
            Text(
              _isEdit ? l10n.adminFormEditTitle : l10n.adminFormCreateTitle,
              style: AppTextStyles.displayMedium(context),
            ),
            SizedBox(height: 16.h),
            CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _dropdown(l10n),
                  _field(
                    label: l10n.adminFormTitle,
                    controller: _titleCtrl,
                    required: true,
                    error: l10n.adminFormTitleRequired,
                  ),
                  _field(
                    label: l10n.adminFormMessage,
                    controller: _messageCtrl,
                    required: true,
                    error: l10n.adminFormMessageRequired,
                    maxLines: 5,
                  ),
                  _field(
                    label: l10n.adminFormArabicText,
                    controller: _arabicCtrl,
                    textDirection: TextDirection.rtl,
                  ),
                  _field(
                    label: l10n.adminFormImageUrl,
                    controller: _imageCtrl,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.adminFormActive,
                      style: AppTextStyles.bodyMedium(context),
                    ),
                    value: _isActive,
                    activeThumbColor: AppColors.gold,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.adminFormShowOnce,
                      style: AppTextStyles.bodyMedium(context),
                    ),
                    value: _showOnce,
                    activeThumbColor: AppColors.gold,
                    onChanged: (v) => setState(() => _showOnce = v),
                  ),
                  AdminFormDateField(
                    label: l10n.adminFormStartsAt,
                    value: _startsAt,
                    onPick: () async {
                      final picked = await pickDateTime(context, _startsAt);
                      if (picked != null) setState(() => _startsAt = picked);
                    },
                    onClear: () => setState(() => _startsAt = null),
                  ),
                  AdminFormDateField(
                    label: l10n.adminFormExpiresAt,
                    value: _expiresAt,
                    onPick: () async {
                      final picked = await pickDateTime(context, _expiresAt);
                      if (picked != null) setState(() => _expiresAt = picked);
                    },
                    onClear: () => setState(() => _expiresAt = null),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _preview,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.goldBorder),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: Text(l10n.adminFormPreview),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.emeraldDeep,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 18.r,
                            height: 18.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.emeraldDeep,
                            ),
                          )
                        : Text(l10n.adminFormSave),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: DropdownButtonFormField<String>(
        initialValue: _type,
        decoration: InputDecoration(
          labelText: l10n.adminFormType,
          labelStyle: AppTextStyles.label(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        dropdownColor: AppColors.emeraldMid,
        items: kAnnouncementTypes
            .map(
              (t) => DropdownMenuItem(
                value: t,
                child: Text(typeLabel(l10n, t)),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _type = v);
        },
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    bool required = false,
    String? error,
    int maxLines = 1,
    TextDirection? textDirection,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        textDirection: textDirection,
        style: AppTextStyles.bodyMedium(context),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.label(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? error : null
            : null,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/admin_config.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/announcement_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/announcement_modal.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../widgets/admin_announcement_helpers.dart';
import '../widgets/admin_form_date_field.dart';
import '../widgets/admin_shared_widgets.dart';

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
  late final TextEditingController _actionUrlCtrl;
  late final TextEditingController _actionLabelCtrl;
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
    _actionUrlCtrl = TextEditingController(text: e?.actionUrl ?? '');
    _actionLabelCtrl = TextEditingController(text: e?.actionLabel ?? '');
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
    _actionUrlCtrl.dispose();
    _actionLabelCtrl.dispose();
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
      actionUrl: _nullable(_actionUrlCtrl.text),
      actionLabel: _nullable(_actionLabelCtrl.text),
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
      showAdminSnackBar(context, message: l10n.adminDateRangeInvalid, isError: true);
      return;
    }

    final user = ref.read(currentUserProvider).asData?.value;
    if (!AdminConfig.isFullAdmin(user?.uid, role: user?.role)) return;

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
      actionUrl: _actionUrlCtrl.text,
      actionLabel: _actionLabelCtrl.text,
      forUpdate: _isEdit,
    );

    try {
      final service = ref.read(firestoreServiceProvider);
      if (_isEdit) {
        await service.updateAnnouncement(widget.existing!.id, data);
      } else {
        await service.createAnnouncement(data: data, adminUid: user!.uid);
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
    if (_titleCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      showAdminSnackBar(context, message: l10n.adminPreviewRequired, isError: true);
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
        ? l10n.adminFormEditTitle
        : l10n.adminFormCreateTitle;

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AdminAppBar(
        title: formTitle,
        fallbackRoute: AppRoutes.adminAnnouncements,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
          children: [
            AdminScreenHeader(
              subtitle: l10n.adminAnnouncementsTitle.toUpperCase(),
              title: formTitle,
            ),
            SizedBox(height: 18.h),
            SectionHeader(title: l10n.adminFormMessage.toUpperCase()),
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
                  AdminTypePillSelector(
                    selected: _type,
                    onChanged: (v) => setState(() => _type = v),
                  ),
                  SizedBox(height: 12.h),
                  AdminFormField(
                    label: l10n.adminFormTitle,
                    controller: _titleCtrl,
                    icon: Icons.title_rounded,
                    required: true,
                    error: l10n.adminFormTitleRequired,
                  ),
                  AdminFormField(
                    label: l10n.adminFormMessage,
                    controller: _messageCtrl,
                    icon: Icons.message_outlined,
                    required: true,
                    error: l10n.adminFormMessageRequired,
                    maxLines: 5,
                  ),
                  AdminFormField(
                    label: l10n.adminFormArabicText,
                    controller: _arabicCtrl,
                    icon: Icons.translate_rounded,
                    textDirection: TextDirection.rtl,
                  ),
                  AdminFormField(
                    label: l10n.adminFormImageUrl,
                    controller: _imageCtrl,
                    icon: Icons.image_outlined,
                  ),
                  AdminFormField(
                    label: l10n.adminFormActionUrl,
                    controller: _actionUrlCtrl,
                    icon: Icons.link_rounded,
                  ),
                  AdminFormField(
                    label: l10n.adminFormActionLabel,
                    controller: _actionLabelCtrl,
                    icon: Icons.text_fields_rounded,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SectionHeader(title: l10n.adminFormActive.toUpperCase()),
            CardContainer(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
              child: Column(
                children: [
                  AdminToggleRow(
                    icon: Icons.toggle_on_outlined,
                    title: l10n.adminFormActive,
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  const Divider(),
                  AdminToggleRow(
                    icon: Icons.looks_one_outlined,
                    title: l10n.adminFormShowOnce,
                    value: _showOnce,
                    onChanged: (v) => setState(() => _showOnce = v),
                  ),
                  const Divider(),
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

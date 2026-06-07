import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/lesson_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/syllabus_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../widgets/admin_course_helpers.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminLessonFormScreen extends ConsumerStatefulWidget {
  const AdminLessonFormScreen({super.key, required this.args});

  final AdminLessonFormArgs args;

  @override
  ConsumerState<AdminLessonFormScreen> createState() =>
      _AdminLessonFormScreenState();
}

class _AdminLessonFormScreenState extends ConsumerState<AdminLessonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _resourceUrlCtrl;
  late final TextEditingController _thumbnailCtrl;
  late final TextEditingController _durationCtrl;
  late LessonResourceType _resourceType;
  late bool _isPublished;
  bool _isSaving = false;

  bool get _isEdit => widget.args.lesson != null;

  @override
  void initState() {
    super.initState();
    final e = widget.args.lesson;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descriptionCtrl = TextEditingController(text: e?.description ?? '');
    _resourceUrlCtrl = TextEditingController(text: e?.resourceUrl ?? '');
    _thumbnailCtrl = TextEditingController(text: e?.thumbnailUrl ?? '');
    _durationCtrl = TextEditingController(
      text: e != null && e.durationMinutes > 0 ? '${e.durationMinutes}' : '',
    );
    _resourceType = e?.resourceType ?? LessonResourceType.youtube;
    _isPublished = e?.isPublished ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _resourceUrlCtrl.dispose();
    _thumbnailCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  int _parseDuration() {
    final parsed = int.tryParse(_durationCtrl.text.trim());
    return parsed == null || parsed < 0 ? 0 : parsed;
  }

  LessonModel _buildLesson({required int order}) {
    return LessonModel(
      id: widget.args.lesson?.id ?? '',
      courseId: widget.args.courseId,
      title: _titleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      resourceType: _resourceType,
      resourceUrl: _resourceUrlCtrl.text.trim(),
      thumbnailUrl: _thumbnailCtrl.text.trim(),
      durationMinutes: _parseDuration(),
      order: widget.args.lesson?.order ?? order,
      isPublished: _isPublished,
    );
  }

  /*
  Purpose:
  Persist a new or updated lesson under a course.

  Response:
  Pops the form on success; shows snackbar on failure.

  Business Rules:
  - Admin-only access.
  - resourceUrl required for youtube, pdf, and link types.
  - New lessons append to the end of the order list.

  Flow:
  1. Validate form including conditional resourceUrl.
  2. Build LessonModel from controllers.
  3. createLesson or updateLesson via SyllabusService.

  Side Effects:
  - Writes to courses/{courseId}/lessons/.

  Failure Cases:
  - Validation failure, permission errors, network errors.
  */
  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider).asData?.value;
    final course = ref.read(courseProvider(widget.args.courseId)).value;
    if (!adminCanModerateCourseRef(user, course)) return;

    setState(() => _isSaving = true);
    final service = ref.read(syllabusServiceProvider);

    try {
      if (_isEdit) {
        await service.updateLesson(_buildLesson(order: widget.args.lesson!.order));
      } else {
        final lessons =
            ref.read(courseLessonsProvider(widget.args.courseId)).value ??
                const [];
        final nextOrder = lessons.isEmpty
            ? 0
            : lessons.map((l) => l.order).reduce((a, b) => a > b ? a : b) + 1;
        await service.createLesson(_buildLesson(order: nextOrder));
      }
      if (!mounted) return;
      showAdminSnackBar(
        context,
        message: l10n.adminLessonFormSaved,
        popAfter: true,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showAdminSnackBar(context, message: l10n.adminSaveFailed, isError: true);
    }
  }

  String _resourceUrlLabel(AppLocalizations l10n) {
    return switch (_resourceType) {
      LessonResourceType.youtube => l10n.adminLessonYoutubeUrl,
      LessonResourceType.pdf => l10n.adminLessonPdfUrl,
      LessonResourceType.link => l10n.adminLessonLinkUrl,
      LessonResourceType.text => l10n.adminLessonTextContent,
      LessonResourceType.audio => l10n.adminLessonAudioUrl,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).asData?.value;
    final course = ref.watch(courseProvider(widget.args.courseId)).value;

    if (!adminCanModerateCourseRef(user, course)) {
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

    final formTitle =
        _isEdit ? l10n.adminLessonEditTitle : l10n.adminLessonCreateTitle;

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AdminAppBar(
        title: formTitle,
        fallbackRoute: AppRoutes.adminLessonsPath(widget.args.courseId),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
          children: [
            AdminScreenHeader(
              subtitle: l10n.adminLessonsTitle.toUpperCase(),
              title: formTitle,
            ),
            SizedBox(height: 18.h),
            SectionHeader(title: l10n.adminLessonDetailsSection.toUpperCase()),
            CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Text(
                      l10n.adminLessonResourceType,
                      style: AppTextStyles.label(context),
                    ),
                  ),
                  AdminResourceTypeSelector(
                    selected: _resourceType,
                    onChanged: (v) => setState(() => _resourceType = v),
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
                    label: l10n.adminCourseDescription,
                    controller: _descriptionCtrl,
                    icon: Icons.description_outlined,
                    maxLines: 3,
                  ),
                  AdminFormField(
                    label: _resourceUrlLabel(l10n),
                    controller: _resourceUrlCtrl,
                    icon: iconForResourceType(_resourceType),
                    required: _resourceType != LessonResourceType.text,
                    error: l10n.adminLessonResourceUrlRequired,
                    maxLines: _resourceType == LessonResourceType.text ? 8 : 1,
                    validator: _resourceType == LessonResourceType.audio
                        ? (v) => validateAudioLessonUrl(v, l10n)
                        : null,
                  ),
                  AdminFormField(
                    label: l10n.adminLessonThumbnailUrl,
                    controller: _thumbnailCtrl,
                    icon: Icons.image_outlined,
                  ),
                  AdminFormField(
                    label: l10n.adminLessonDuration,
                    controller: _durationCtrl,
                    icon: Icons.timer_outlined,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SectionHeader(title: l10n.adminFormActive.toUpperCase()),
            CardContainer(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
              child: AdminToggleRow(
                icon: Icons.visibility_outlined,
                title: l10n.adminLessonPublished,
                value: _isPublished,
                onChanged: (v) => setState(() => _isPublished = v),
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? SizedBox(
                        width: 18.r,
                        height: 18.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.emeraldDeep,
                        ),
                      )
                    : Icon(Icons.save_outlined, size: 18.r),
                label: Text(l10n.adminFormSave),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.emeraldDeep,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  textStyle: AppTextStyles.button(context).copyWith(
                    color: AppColors.emeraldDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

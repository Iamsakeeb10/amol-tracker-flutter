import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/admin_config.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/course_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/syllabus_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../widgets/admin_course_helpers.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminCourseFormScreen extends ConsumerStatefulWidget {
  const AdminCourseFormScreen({super.key, this.existing});

  final CourseModel? existing;

  @override
  ConsumerState<AdminCourseFormScreen> createState() =>
      _AdminCourseFormScreenState();
}

class _AdminCourseFormScreenState extends ConsumerState<AdminCourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _coverCtrl;
  late final TextEditingController _tagsCtrl;
  late final TextEditingController _moderatorsCtrl;
  late CourseStatus _status;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descriptionCtrl = TextEditingController(text: e?.description ?? '');
    _coverCtrl = TextEditingController(text: e?.coverImageUrl ?? '');
    _tagsCtrl = TextEditingController(text: joinCommaSeparated(e?.tags ?? []));
    _moderatorsCtrl = TextEditingController(
      text: joinCommaSeparated(e?.moderators ?? []),
    );
    _status = e?.status ?? CourseStatus.draft;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _coverCtrl.dispose();
    _tagsCtrl.dispose();
    _moderatorsCtrl.dispose();
    super.dispose();
  }

  CourseModel _buildCourse(String uid, {required int order}) {
    return CourseModel(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      coverImageUrl: _coverCtrl.text.trim(),
      tags: parseCommaSeparated(_tagsCtrl.text),
      status: _status,
      createdBy: widget.existing?.createdBy ?? uid,
      moderators: parseCommaSeparated(_moderatorsCtrl.text),
      publishedAt: widget.existing?.publishedAt,
      order: widget.existing?.order ?? order,
    );
  }

  /*
  Purpose:
  Persist a new or updated course document in Firestore.

  Response:
  Pops the form on success; shows snackbar on failure.

  Business Rules:
  - Admin-only access.
  - New courses append to the end of the order list.
  - publishedAt is set server-side when status is published on create.

  Flow:
  1. Validate form fields.
  2. Build CourseModel from controllers.
  3. createCourse or updateCourse via SyllabusService.
  4. publishCourse when status is published on create.

  Side Effects:
  - Writes to courses/ collection.

  Failure Cases:
  - Validation failure, permission errors, network errors.
  */
  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final uid = ref.read(authStateProvider).asData?.value?.uid;
    final user = ref.read(currentUserProvider).asData?.value;
    if (_isEdit) {
      if (!AdminConfig.canModerateCourse(
        uid,
        widget.existing!,
        role: user?.role,
      )) {
        return;
      }
    } else if (!AdminConfig.isFullAdmin(uid, role: user?.role)) {
      return;
    }

    setState(() => _isSaving = true);
    final service = ref.read(syllabusServiceProvider);

    try {
      if (_isEdit) {
        final course = _buildCourse(uid!, order: widget.existing!.order);
        await service.updateCourse(widget.existing!.id, course);
        if (_status == CourseStatus.published && !widget.existing!.isPublished) {
          await service.publishCourse(widget.existing!.id);
          unawaited(
            notifyCoursePublishedPush(
              ref: ref,
              adminUid: uid,
              courseTitle: course.title,
              pushTitle: l10n.adminCoursePublishedPushTitle,
              pushMessage: l10n.adminCoursePublishedPushMessage(course.title),
            ),
          );
        } else if (_status == CourseStatus.draft && widget.existing!.isPublished) {
          await service.unpublishCourse(widget.existing!.id);
        }
      } else {
        final courses = ref.read(allCoursesProvider).value ?? const [];
        final nextOrder = courses.isEmpty
            ? 0
            : courses.map((c) => c.order).reduce((a, b) => a > b ? a : b) + 1;
        final course = _buildCourse(uid!, order: nextOrder);
        final courseId = await service.createCourse(course);
        if (_status == CourseStatus.published) {
          await service.publishCourse(courseId);
          unawaited(
            notifyCoursePublishedPush(
              ref: ref,
              adminUid: uid,
              courseTitle: course.title,
              pushTitle: l10n.adminCoursePublishedPushTitle,
              pushMessage: l10n.adminCoursePublishedPushMessage(course.title),
            ),
          );
        }
      }
      if (!mounted) return;
      showAdminSnackBar(
        context,
        message: l10n.adminCourseFormSaved,
        popAfter: true,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showAdminSnackBar(context, message: l10n.adminSaveFailed, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).asData?.value;
    final unauthorized = _isEdit
        ? !AdminConfig.canModerateCourse(
            user?.uid,
            widget.existing!,
            role: user?.role,
          )
        : !AdminConfig.isFullAdmin(user?.uid, role: user?.role);

    if (unauthorized) {
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
        _isEdit ? l10n.adminCourseEditTitle : l10n.adminCourseCreateTitle;

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AdminAppBar(
        title: formTitle,
        fallbackRoute: AppRoutes.adminCourses,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
          children: [
            AdminScreenHeader(
              subtitle: l10n.adminCoursesTitle.toUpperCase(),
              title: formTitle,
            ),
            SizedBox(height: 18.h),
            SectionHeader(title: l10n.adminCourseDetailsSection.toUpperCase()),
            CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                    required: true,
                    error: l10n.adminCourseDescriptionRequired,
                    maxLines: 4,
                  ),
                  AdminFormField(
                    label: l10n.adminCourseCoverUrl,
                    controller: _coverCtrl,
                    icon: Icons.image_outlined,
                  ),
                  AdminFormField(
                    label: l10n.adminCourseTags,
                    controller: _tagsCtrl,
                    icon: Icons.label_outline,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SectionHeader(title: l10n.adminCourseModeratorsSection.toUpperCase()),
            CardContainer(
              child: AdminFormField(
                label: l10n.adminCourseModerators,
                controller: _moderatorsCtrl,
                icon: Icons.group_outlined,
              ),
            ),
            SizedBox(height: 16.h),
            SectionHeader(title: l10n.adminCourseStatusSection.toUpperCase()),
            CardContainer(
              child: AdminCourseStatusSelector(
                selected: _status,
                onChanged: (v) => setState(() => _status = v),
              ),
            ),
            if (_isEdit) ...[
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    AppRoutes.adminLessonsPath(widget.existing!.id),
                  ),
                  icon: Icon(Icons.playlist_play_rounded, size: 18.r),
                  label: Text(l10n.adminCourseManageLessons),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.goldBorder),
                    foregroundColor: AppColors.goldLight,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ),
            ],
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

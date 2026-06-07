import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/quiz_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/quiz_provider.dart';
import '../../../../providers/syllabus_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../widgets/admin_course_helpers.dart';
import '../widgets/admin_question_tile.dart';
import '../widgets/admin_quiz_helpers.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminQuizFormScreen extends ConsumerStatefulWidget {
  const AdminQuizFormScreen({super.key, required this.args});

  final AdminQuizFormArgs args;

  @override
  ConsumerState<AdminQuizFormScreen> createState() =>
      _AdminQuizFormScreenState();
}

class _AdminQuizFormScreenState extends ConsumerState<AdminQuizFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _timeLimitCtrl;
  late final TextEditingController _passingScoreCtrl;
  late String? _selectedLessonId;
  late List<QuizQuestion> _questions;
  bool _isSaving = false;

  bool get _isEdit => widget.args.quiz != null;

  @override
  void initState() {
    super.initState();
    final q = widget.args.quiz;
    _titleCtrl = TextEditingController(text: q?.title ?? '');
    _timeLimitCtrl = TextEditingController(
      text: q != null && q.timeLimitSeconds > 0 ? '${q.timeLimitSeconds}' : '',
    );
    _passingScoreCtrl = TextEditingController(
      text: q != null && q.passingScore > 0 ? '${q.passingScore}' : '',
    );
    _selectedLessonId = q?.lessonId ?? widget.args.lessonId;
    _questions = List<QuizQuestion>.from(q?.questions ?? const []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _timeLimitCtrl.dispose();
    _passingScoreCtrl.dispose();
    super.dispose();
  }

  int _parseInt(String raw, {int fallback = 0}) {
    final parsed = int.tryParse(raw.trim());
    return parsed == null || parsed < 0 ? fallback : parsed;
  }

  QuizModel _buildQuiz({required String id}) {
    return QuizModel(
      id: id,
      courseId: widget.args.courseId,
      title: _titleCtrl.text.trim(),
      lessonId: _selectedLessonId,
      timeLimitSeconds: _parseInt(_timeLimitCtrl.text),
      passingScore: _parseInt(_passingScoreCtrl.text),
      questions: _questions,
    );
  }

  Future<void> _openQuestionEditor({QuizQuestion? question, int? index}) async {
    final result = await context.push<QuizQuestion>(
      AppRoutes.adminQuestionEditor,
      extra: AdminQuestionEditorArgs(
        question: question,
        questionIndex: index,
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      if (index != null && index >= 0 && index < _questions.length) {
        _questions[index] = result;
      } else {
        _questions.add(result);
      }
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final item = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, item);
    });
  }

  /*
  Purpose:
  Persist a new or updated quiz with its embedded questions.

  Response:
  Pops the form on success; shows snackbar on failure.

  Business Rules:
  - Admin-only access.
  - At least one question required.
  - passingScore is an absolute correct-answer count.
  - Empty lessonId means course-level quiz.

  Flow:
  1. Validate form and question count.
  2. createQuiz or updateQuiz via QuizService.
  3. Pop with success snackbar.

  Side Effects:
  - Writes to courses/{courseId}/quizzes/.

  Failure Cases:
  - Validation failure, permission errors, network errors.
  */
  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (_questions.isEmpty) {
      showAdminSnackBar(
        context,
        message: l10n.adminQuizQuestionsRequired,
        isError: true,
      );
      return;
    }

    final passingScore = _parseInt(_passingScoreCtrl.text);
    if (passingScore > _questions.length) {
      showAdminSnackBar(
        context,
        message: l10n.adminQuizPassingScoreTooHigh,
        isError: true,
      );
      return;
    }

    final user = ref.read(currentUserProvider).asData?.value;
    final course = ref.read(courseProvider(widget.args.courseId)).value;
    if (!adminCanModerateCourseRef(user, course)) return;

    setState(() => _isSaving = true);
    final service = ref.read(quizServiceProvider);

    try {
      if (_isEdit) {
        await service.updateQuiz(_buildQuiz(id: widget.args.quiz!.id));
      } else {
        await service.createQuiz(_buildQuiz(id: ''));
      }
      if (!mounted) return;
      showAdminSnackBar(
        context,
        message: l10n.adminQuizFormSaved,
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

    final lessons =
        ref.watch(courseLessonsProvider(widget.args.courseId)).value ??
            const [];
    final formTitle =
        _isEdit ? l10n.adminQuizEditTitle : l10n.adminQuizCreateTitle;

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
              subtitle: l10n.adminQuizTitle.toUpperCase(),
              title: formTitle,
            ),
            SizedBox(height: 18.h),
            SectionHeader(title: l10n.adminQuizDetailsSection.toUpperCase()),
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
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: AdminLessonPicker(
                      lessons: lessons,
                      selectedLessonId: _selectedLessonId,
                      onChanged: (v) => setState(() => _selectedLessonId = v),
                    ),
                  ),
                  AdminFormField(
                    label: l10n.adminQuizTimeLimit,
                    controller: _timeLimitCtrl,
                    icon: Icons.timer_outlined,
                  ),
                  AdminFormField(
                    label: l10n.adminQuizPassingScore,
                    controller: _passingScoreCtrl,
                    icon: Icons.grade_outlined,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SectionHeader(title: l10n.adminQuizQuestionsSection.toUpperCase()),
            _AdminQuizQuestionsSection(
              questions: _questions,
              onAdd: () => _openQuestionEditor(),
              onEdit: (q, i) => _openQuestionEditor(question: q, index: i),
              onDelete: (i) => setState(() => _questions.removeAt(i)),
              onReorder: _onReorder,
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

class _AdminQuizQuestionsSection extends StatelessWidget {
  const _AdminQuizQuestionsSection({
    required this.questions,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
  });

  final List<QuizQuestion> questions;
  final VoidCallback onAdd;
  final void Function(QuizQuestion question, int index) onEdit;
  final void Function(int index) onDelete;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: Icon(Icons.add_rounded, size: 18.r),
          label: Text(l10n.adminQuizAddQuestion),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.goldBorder),
            foregroundColor: AppColors.goldLight,
            padding: EdgeInsets.symmetric(vertical: 12.h),
          ),
        ),
        SizedBox(height: 12.h),
        if (questions.isEmpty)
          CardContainer(
            padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
            child: Column(
              children: [
                Icon(Icons.quiz_outlined, color: AppColors.gold, size: 32.r),
                SizedBox(height: 8.h),
                Text(
                  l10n.adminQuizQuestionsEmpty,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(context),
                ),
              ],
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: questions.length,
            onReorder: onReorder,
            itemBuilder: (context, index) {
              final question = questions[index];
              return AdminQuestionTile(
                key: ValueKey<String>(question.id),
                question: question,
                index: index,
                onTap: () => onEdit(question, index),
                onDismissed: () async => onDelete(index),
              );
            },
          ),
      ],
    );
  }
}

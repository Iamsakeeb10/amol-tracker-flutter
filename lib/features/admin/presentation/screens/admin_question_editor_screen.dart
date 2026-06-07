import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/admin_config.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/quiz_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../widgets/admin_quiz_helpers.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminQuestionEditorScreen extends ConsumerStatefulWidget {
  const AdminQuestionEditorScreen({super.key, required this.args});

  final AdminQuestionEditorArgs args;

  @override
  ConsumerState<AdminQuestionEditorScreen> createState() =>
      _AdminQuestionEditorScreenState();
}

class _AdminQuestionEditorScreenState
    extends ConsumerState<AdminQuestionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textCtrl;
  late final TextEditingController _explanationCtrl;
  late final List<TextEditingController> _optionCtrls;
  late int _correctIndex;

  bool get _isEdit => widget.args.question != null;

  @override
  void initState() {
    super.initState();
    final q = widget.args.question;
    _textCtrl = TextEditingController(text: q?.text ?? '');
    _explanationCtrl = TextEditingController(text: q?.explanation ?? '');
    _correctIndex = q?.correctIndex ?? 0;

    final existingOptions = q?.options ?? const [];
    _optionCtrls = List.generate(kDefaultMcqOptionCount, (i) {
      final text = i < existingOptions.length ? existingOptions[i] : '';
      return TextEditingController(text: text);
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _explanationCtrl.dispose();
    for (final ctrl in _optionCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  List<String> _collectOptions() {
    return _optionCtrls
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }

  String? _validateOptions(AppLocalizations l10n) {
    final filled = _collectOptions();
    if (filled.length < kMinMcqOptions) {
      return l10n.adminQuizOptionsMinRequired;
    }
    if (_correctIndex < 0 || _correctIndex >= _optionCtrls.length) {
      return l10n.adminQuizCorrectAnswerRequired;
    }
    if (_optionCtrls[_correctIndex].text.trim().isEmpty) {
      return l10n.adminQuizCorrectAnswerRequired;
    }
    return null;
  }

  QuizQuestion _buildQuestion() {
    final rawOptions = _optionCtrls.map((c) => c.text.trim()).toList();
    final options = <String>[];
    var mappedCorrect = 0;

    for (var i = 0; i < rawOptions.length; i++) {
      final text = rawOptions[i];
      if (text.isEmpty) continue;
      if (i == _correctIndex) mappedCorrect = options.length;
      options.add(text);
    }

    return QuizQuestion(
      id: widget.args.question?.id ?? generateQuestionId(),
      text: _textCtrl.text.trim(),
      options: options,
      correctIndex: mappedCorrect,
      explanation: _explanationCtrl.text.trim(),
    );
  }

  /*
  Purpose:
  Validate and return a QuizQuestion to the quiz form screen.

  Response:
  Pops with QuizQuestion on success; shows inline/snackbar errors on failure.

  Business Rules:
  - At least two non-empty options required.
  - Correct answer must point to a non-empty option slot.
  - Preserves question id when editing.

  Flow:
  1. Validate form fields and option rules.
  2. Build QuizQuestion from controllers.
  3. context.pop(result).

  Side Effects:
  - None (caller persists on quiz save).

  Failure Cases:
  - Validation errors block pop.
  */
  void _save() {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final optionError = _validateOptions(l10n);
    if (optionError != null) {
      showAdminSnackBar(context, message: optionError, isError: true);
      return;
    }

    context.pop(_buildQuestion());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).asData?.value;

    if (!AdminConfig.canAccessCourseAdmin(user?.uid, role: user?.role)) {
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
        ? l10n.adminQuizQuestionEditTitle
        : l10n.adminQuizQuestionCreateTitle;

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AdminAppBar(title: formTitle),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
          children: [
            AdminScreenHeader(
              subtitle: l10n.adminQuizQuestionsSection.toUpperCase(),
              title: formTitle,
            ),
            SizedBox(height: 18.h),
            SectionHeader(title: l10n.adminQuizQuestionTextSection.toUpperCase()),
            CardContainer(
              child: AdminFormField(
                label: l10n.adminQuizQuestionText,
                controller: _textCtrl,
                icon: Icons.help_outline_rounded,
                required: true,
                error: l10n.adminQuizQuestionTextRequired,
                maxLines: 3,
              ),
            ),
            SizedBox(height: 16.h),
            SectionHeader(title: l10n.adminQuizOptionsSection.toUpperCase()),
            CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.adminQuizSelectCorrectHint,
                    style: AppTextStyles.bodySmall(context),
                  ),
                  SizedBox(height: 12.h),
                  ...List.generate(_optionCtrls.length, (index) {
                    final label = l10n.adminQuizOptionLabel(index + 1);
                    final isCorrect = _correctIndex == index;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 14.h),
                            child: InkWell(
                              onTap: () => setState(() => _correctIndex = index),
                              borderRadius: BorderRadius.circular(20.r),
                              child: Icon(
                                isCorrect
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: isCorrect
                                    ? AppColors.gold
                                    : AppColors.textMuted,
                                size: 22.r,
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: AdminFormField(
                              label: label,
                              controller: _optionCtrls[index],
                              icon: Icons.radio_button_unchecked,
                              required: index < kMinMcqOptions,
                              error: l10n.adminQuizOptionRequired,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SectionHeader(
              title: l10n.adminQuizExplanationSection.toUpperCase(),
            ),
            CardContainer(
              child: AdminFormField(
                label: l10n.adminQuizExplanation,
                controller: _explanationCtrl,
                icon: Icons.lightbulb_outline_rounded,
                maxLines: 4,
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: Icon(Icons.check_rounded, size: 18.r),
                label: Text(l10n.adminQuizQuestionDone),
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

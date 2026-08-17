import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../battle/models/question_model.dart';
import '../../repositories/admin_battle_repository.dart';

class AdminBattleQuestionFormScreen extends ConsumerStatefulWidget {
  final String topicId;
  final QuestionModel? existingQuestion;

  const AdminBattleQuestionFormScreen({super.key, required this.topicId, this.existingQuestion});

  @override
  ConsumerState<AdminBattleQuestionFormScreen> createState() => _AdminBattleQuestionFormScreenState();
}

class _AdminBattleQuestionFormScreenState extends ConsumerState<AdminBattleQuestionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _textCtrl;
  late List<TextEditingController> _optionsCtrls;
  late TextEditingController _expCtrl;
  String? _sourceType;
  late TextEditingController _sourceRefCtrl;
  
  late int _correctIndex;
  late String _difficulty;
  late bool _isActive;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final q = widget.existingQuestion;
    _textCtrl = TextEditingController(text: q?.text ?? '');
    
    _optionsCtrls = List.generate(4, (i) => TextEditingController(text: q?.options.elementAtOrNull(i) ?? ''));
    
    _expCtrl = TextEditingController(text: q?.explanation ?? '');
    _sourceType = q?.sourceType;
    _sourceRefCtrl = TextEditingController(text: q?.sourceReference ?? '');
    
    _correctIndex = q?.correctIndex ?? 0;
    _difficulty = q?.difficulty ?? 'easy';
    _isActive = q?.isActive ?? true;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    for (var c in _optionsCtrls) { c.dispose(); }
    _expCtrl.dispose();
    _sourceRefCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(adminBattleRepositoryProvider);
      
      final options = _optionsCtrls.map((c) => c.text.trim()).toList();
      
      final newQuestion = QuestionModel(
        id: widget.existingQuestion?.id ?? '',
        topicId: widget.topicId,
        text: _textCtrl.text.trim(),
        options: options,
        correctIndex: _correctIndex,
        explanation: _expCtrl.text.trim(),
        sourceType: _sourceType,
        sourceReference: _sourceRefCtrl.text.trim(),
        difficulty: _difficulty,
        isActive: _isActive,
      );

      if (widget.existingQuestion == null) {
        await repo.addQuestion(widget.topicId, newQuestion);
      } else {
        await repo.updateQuestion(widget.topicId, widget.existingQuestion!, newQuestion);
      }

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.adminKnowledgeBattle);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _delete() async {
    if (widget.existingQuestion == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => ctx.pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isLoading = true);
    try {
      await ref.read(adminBattleRepositoryProvider).deleteQuestion(widget.topicId, widget.existingQuestion!);
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.adminKnowledgeBattle);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, size: 22.r),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.adminKnowledgeBattle);
            }
          },
        ),
        title: Text(
          widget.existingQuestion == null ? 'New Question' : 'Edit Question',
          style: AppTextStyles.headlineMedium(context),
        ),
        actions: [
          if (widget.existingQuestion != null)
            IconButton(
              icon: Icon(Icons.delete, color: AppColors.danger),
              onPressed: _delete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                children: [
                  _buildSectionHeader('Question Text'),
                  _buildTextField(_textCtrl, 'Question', required: true),
                  
                  SizedBox(height: 24.h),
                  _buildSectionHeader('Options'),
                  for (int i = 0; i < 4; i++) ...[
                    _buildOptionField(_optionsCtrls[i], i),
                    SizedBox(height: 8.h),
                  ],
                  
                  SizedBox(height: 24.h),
                  _buildSectionHeader('Correct Answer Index'),
                  DropdownButtonFormField<int>(
                    value: _correctIndex,
                    items: List.generate(4, (index) => DropdownMenuItem(value: index, child: Text('Option ${index + 1}'))),
                    onChanged: (val) => setState(() => _correctIndex = val ?? 0),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  
                  SizedBox(height: 24.h),
                  _buildSectionHeader('Explanation & Source'),
                  _buildTextField(_expCtrl, 'Explanation'),
                  SizedBox(height: 12.h),
                  DropdownButtonFormField<String>(
                    value: _sourceType,
                    items: const [
                      DropdownMenuItem(value: 'quran', child: Text('Quran')),
                      DropdownMenuItem(value: 'hadith', child: Text('Hadith')),
                      DropdownMenuItem(value: 'book', child: Text('Book')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (val) => setState(() => _sourceType = val),
                    decoration: const InputDecoration(labelText: 'Source Type', border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 12.h),
                  _buildTextField(_sourceRefCtrl, 'Source Reference (e.g. হাদিস ১)'),
                  
                  SizedBox(height: 24.h),
                  _buildSectionHeader('Settings'),
                  DropdownButtonFormField<String>(
                    value: _difficulty,
                    items: const [
                      DropdownMenuItem(value: 'easy', child: Text('Easy')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'hard', child: Text('Hard')),
                    ],
                    onChanged: (val) => setState(() => _difficulty = val ?? 'easy'),
                    decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
                  ),
                  SizedBox(height: 12.h),
                  SwitchListTile(
                    title: const Text('Is Active'),
                    value: _isActive,
                    activeTrackColor: AppColors.gold,
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                  
                  SizedBox(height: 32.h),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                    child: Text('Save Question', style: TextStyle(color: AppColors.emeraldDeep, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(title, style: AppTextStyles.titleMedium(context).copyWith(color: AppColors.gold)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool required = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
      maxLines: null,
    );
  }

  Widget _buildOptionField(TextEditingController controller, int index) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Option ${index + 1}',
        border: const OutlineInputBorder(),
        prefixIcon: Icon(
          _correctIndex == index ? Icons.check_circle : Icons.radio_button_unchecked,
          color: _correctIndex == index ? AppColors.gold : AppColors.textMuted,
        ),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }
}


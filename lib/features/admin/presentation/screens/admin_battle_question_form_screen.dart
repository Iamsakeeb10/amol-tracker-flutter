import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

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

  late TextEditingController _textEnCtrl;
  late TextEditingController _textBnCtrl;
  late List<TextEditingController> _optionsEnCtrls;
  late List<TextEditingController> _optionsBnCtrls;
  late TextEditingController _expEnCtrl;
  late TextEditingController _expBnCtrl;
  late TextEditingController _refEnCtrl;
  late TextEditingController _refBnCtrl;
  
  late int _correctIndex;
  late String _difficulty;
  late bool _isActive;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final q = widget.existingQuestion;
    _textEnCtrl = TextEditingController(text: q?.textEn ?? '');
    _textBnCtrl = TextEditingController(text: q?.textBn ?? '');
    
    _optionsEnCtrls = List.generate(4, (i) => TextEditingController(text: q?.optionsEn.elementAtOrNull(i) ?? ''));
    _optionsBnCtrls = List.generate(4, (i) => TextEditingController(text: q?.optionsBn.elementAtOrNull(i) ?? ''));
    
    _expEnCtrl = TextEditingController(text: q?.explanationEn ?? '');
    _expBnCtrl = TextEditingController(text: q?.explanationBn ?? '');
    _refEnCtrl = TextEditingController(text: q?.referenceEn ?? '');
    _refBnCtrl = TextEditingController(text: q?.referenceBn ?? '');
    
    _correctIndex = q?.correctIndex ?? 0;
    _difficulty = q?.difficulty ?? 'easy';
    _isActive = q?.isActive ?? true;
  }

  @override
  void dispose() {
    _textEnCtrl.dispose();
    _textBnCtrl.dispose();
    for (var c in _optionsEnCtrls) { c.dispose(); }
    for (var c in _optionsBnCtrls) { c.dispose(); }
    _expEnCtrl.dispose();
    _expBnCtrl.dispose();
    _refEnCtrl.dispose();
    _refBnCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(adminBattleRepositoryProvider);
      
      final optionsEn = _optionsEnCtrls.map((c) => c.text.trim()).toList();
      final optionsBn = _optionsBnCtrls.map((c) => c.text.trim()).toList();
      
      final newQuestion = QuestionModel(
        id: widget.existingQuestion?.id ?? '',
        topicId: widget.topicId,
        textEn: _textEnCtrl.text.trim(),
        textBn: _textBnCtrl.text.trim(),
        optionsEn: optionsEn,
        optionsBn: optionsBn,
        correctIndex: _correctIndex,
        explanationEn: _expEnCtrl.text.trim(),
        explanationBn: _expBnCtrl.text.trim(),
        referenceEn: _refEnCtrl.text.trim(),
        referenceBn: _refBnCtrl.text.trim(),
        difficulty: _difficulty,
        isActive: _isActive,
      );

      if (widget.existingQuestion == null) {
        await repo.addQuestion(widget.topicId, newQuestion);
      } else {
        await repo.updateQuestion(widget.topicId, widget.existingQuestion!, newQuestion);
      }

      if (mounted) context.pop();
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
      if (mounted) context.pop();
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
          onPressed: () => context.pop(),
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
                  _buildTextField(_textEnCtrl, 'English Question', required: true),
                  SizedBox(height: 12.h),
                  _buildTextField(_textBnCtrl, 'Bangla Question', required: true),
                  
                  SizedBox(height: 24.h),
                  _buildSectionHeader('Options (English)'),
                  for (int i = 0; i < 4; i++) ...[
                    _buildOptionField(_optionsEnCtrls[i], i, 'EN'),
                    SizedBox(height: 8.h),
                  ],
                  
                  SizedBox(height: 16.h),
                  _buildSectionHeader('Options (Bangla)'),
                  for (int i = 0; i < 4; i++) ...[
                    _buildOptionField(_optionsBnCtrls[i], i, 'BN'),
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
                  _buildSectionHeader('Explanation & Reference'),
                  _buildTextField(_expEnCtrl, 'Explanation (English)'),
                  SizedBox(height: 12.h),
                  _buildTextField(_expBnCtrl, 'Explanation (Bangla)'),
                  SizedBox(height: 12.h),
                  _buildTextField(_refEnCtrl, 'Reference (English)'),
                  SizedBox(height: 12.h),
                  _buildTextField(_refBnCtrl, 'Reference (Bangla)'),
                  
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
                    activeColor: AppColors.gold,
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

  Widget _buildOptionField(TextEditingController controller, int index, String lang) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Option ${index + 1} ($lang)',
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/personal_amol_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/personal_amol_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/time_picker_sheet.dart';

const _kPersonalAmolEmojis = <String>[
  '🕌', '🕋', '📿', '🤲', '📖', '🌙', '⭐', '🌸',
  '💧', '🍃', '🌿', '🌹', '🫶', '❤️', '🤍', '🕊️',
  '🧠', '📚', '✍️', '🏃', '💪', '🥗', '🚭', '🌅',
  '🌇', '☀️', '✨', '🫧', '🧎', '🎵',
];

const _kWeekdayLabels = ['স', 'রো', 'ম', 'বু', 'বৃ', 'শু', 'শ'];

class PersonalAmolFormScreen extends ConsumerStatefulWidget {
  const PersonalAmolFormScreen({super.key, this.existingAmolId});

  final String? existingAmolId;

  @override
  ConsumerState<PersonalAmolFormScreen> createState() =>
      _PersonalAmolFormScreenState();
}

class _PersonalAmolFormScreenState
    extends ConsumerState<PersonalAmolFormScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isEditing = false;
  PersonalAmolModel? _existing;
  bool _daily = true;
  final Set<int> _selectedWeekdays = <int>{};
  String _icon = '';
  ({int hour, int minute})? _reminderTime;
  bool _isSaving = false;

  bool get _isWeekdays => !_daily;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingAmolId != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null || widget.existingAmolId == null) return;
    final all = ref.read(personalAmolNotifierProvider(uid));
    final amol = all[widget.existingAmolId];
    if (amol == null) return;
    setState(() {
      _existing = amol;
      _nameController.text = amol.name;
      _icon = amol.icon;
      _daily = amol.frequency == PersonalAmolFrequency.daily;
      _selectedWeekdays
        ..clear()
        ..addAll(amol.weekdays);
      _reminderTime = amol.reminderTime;
    });
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showBdTimePicker(
      context: context,
      initialTime: _reminderTime == null
          ? now
          : TimeOfDay(hour: _reminderTime!.hour, minute: _reminderTime!.minute),
    );
    if (picked != null) {
      setState(() => _reminderTime = (hour: picked.hour, minute: picked.minute));
    }
  }

  Future<void> _save() async {
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null) return;
    final notifier = ref.read(personalAmolNotifierProvider(uid).notifier);

    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim();
      if (_isEditing && _existing != null) {
        await notifier.updateAmol(
          _existing!.copyWith(
            name: name,
            icon: _icon,
            frequency: _daily
                ? PersonalAmolFrequency.daily
                : PersonalAmolFrequency.weekdays,
            weekdays: _isWeekdays ? _selectedWeekdays.toList() : const <int>[],
            reminderTime: _reminderTime,
          ),
        );
      } else {
        if (notifier.atCap) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.personalAmolCapMessage(AppConstants.kMaxFreePersonalAmol),
                ),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          return;
        }
        final amol = PersonalAmolModel(
          id: FirebaseFirestore.instance.collection('personal_amol_ids').doc().id,
          name: name,
          icon: _icon,
          frequency: _daily
              ? PersonalAmolFrequency.daily
              : PersonalAmolFrequency.weekdays,
          weekdays: _isWeekdays ? _selectedWeekdays.toList() : const <int>[],
          reminderTime: _reminderTime,
          isActive: true,
          createdAt: DateTime.now(),
        );
        await notifier.createAmol(amol);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null || _existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.emeraldMid,
        title: Text(l10n.personalAmolDeleteConfirm,
            style: AppTextStyles.headlineMedium(ctx)),
        content: Text(
          l10n.personalAmolDeleteSubtitle,
          style: AppTextStyles.bodyMedium(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: AppTextStyles.button(ctx)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete,
                style: AppTextStyles.button(ctx).copyWith(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(personalAmolNotifierProvider(uid).notifier).softDeleteAmol(_existing!.id);
    if (mounted) context.pop();
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).asData?.value?.uid;
    if (uid != null && widget.existingAmolId != null && _existing == null) {
      // load once after uid is known
      Future.microtask(_loadExisting);
    }
    final activeCount = ref.watch(activePersonalAmolProvider(uid ?? '')).value?.length ?? 0;
    final atCap = !_isEditing &&
        activeCount >= AppConstants.kMaxFreePersonalAmol &&
        !_isSaving;

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditing ? l10n.personalAmolEditTitle : l10n.personalAmolCreateTitle,
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
          children: [
            if (atCap) ...[
              CardContainer(
                color: AppColors.warningLight,
                borderColor: AppColors.warning.withValues(alpha: 0.4),
                child: Text(
                  l10n.personalAmolCapMessage(AppConstants.kMaxFreePersonalAmol),
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
            Text(l10n.personalAmolNameLabel, style: AppTextStyles.bodyMedium(context)),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _nameController,
              maxLength: 40,
              style: AppTextStyles.bodyLarge(context),
              decoration: InputDecoration(
                hintText: l10n.personalAmolNameHint,
                counterText: '',
                filled: true,
                fillColor: AppColors.cardDark,
                contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.personalAmolNameRequired : null,
            ),
            SizedBox(height: 20.h),
            Text(l10n.personalAmolIconLabel, style: AppTextStyles.bodyMedium(context)),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final e in _kPersonalAmolEmojis)
                  GestureDetector(
                    onTap: () => setState(() => _icon = e),
                    child: Container(
                      width: 44.r,
                      height: 44.r,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _icon == e
                            ? AppColors.gold.withValues(alpha: 0.25)
                            : AppColors.cardDark,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: _icon == e
                              ? AppColors.gold
                              : AppColors.cardBorder,
                          width: _icon == e ? 1.5 : 1,
                        ),
                      ),
                      child: Text(e, style: TextStyle(fontSize: 22.sp)),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20.h),
            Text(l10n.personalAmolFrequencyLabel,
                style: AppTextStyles.bodyMedium(context)),
            SizedBox(height: 8.h),
            Row(
              children: [
                _FrequencyPill(
                  label: l10n.personalAmolFrequencyDaily,
                  selected: _daily,
                  onTap: () => setState(() => _daily = true),
                ),
                SizedBox(width: 10.w),
                _FrequencyPill(
                  label: l10n.personalAmolFrequencyWeekdays,
                  selected: _isWeekdays,
                  onTap: () => setState(() => _daily = false),
                ),
              ],
            ),
            if (_isWeekdays) ...[
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 7; i++)
                    GestureDetector(
                      onTap: () => setState(() {
                        if (!_selectedWeekdays.add(i + 1)) {
                          _selectedWeekdays.remove(i + 1);
                        }
                      }),
                      child: Container(
                        width: 40.r,
                        height: 40.r,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedWeekdays.contains(i + 1)
                              ? AppColors.gold
                              : AppColors.cardDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          _kWeekdayLabels[i],
                          style: AppTextStyles.label(context).copyWith(
                            color: _selectedWeekdays.contains(i + 1)
                                ? AppColors.emeraldDeep
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: Text(l10n.personalAmolReminderLabel,
                      style: AppTextStyles.bodyMedium(context)),
                ),
                TextButton.icon(
                  onPressed: _pickTime,
                  icon: Icon(
                    _reminderTime == null
                        ? Icons.add_alarm_outlined
                        : Icons.alarm_on_outlined,
                    color: AppColors.gold,
                    size: 18.r,
                  ),
                  label: Text(
                    _reminderTime == null
                        ? l10n.personalAmolReminderNone
                        : '${_reminderTime!.hour.toString().padLeft(2, '0')}:'
                              '${_reminderTime!.minute.toString().padLeft(2, '0')}',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 28.h),
            SizedBox(
              height: 50.h,
              child: ElevatedButton(
                onPressed: (_isSaving || (_isEditing ? false : atCap))
                    ? null
                    : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.emeraldDeep,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(
                        _isEditing
                            ? l10n.personalAmolSaveLabel
                            : l10n.personalAmolAddLabel,
                        style: AppTextStyles.button(context)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            if (_isEditing) ...[
              SizedBox(height: 12.h),
              SizedBox(
                height: 50.h,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    l10n.personalAmolDeleteLabel,
                    style: AppTextStyles.button(context).copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FrequencyPill extends StatelessWidget {
  const _FrequencyPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.goldCard : AppColors.cardDark,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall(context).copyWith(
              color: selected ? AppColors.goldLight : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/amal_edit_toggles.dart';
import '../../../../core/utils/score_calculator.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../providers/amal_fields_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/edit_amal_progress_card.dart';
import '../../../../shared/widgets/edited_badge.dart';

class EditAmalScreen extends ConsumerStatefulWidget {
  const EditAmalScreen({super.key, required this.hijriDate, this.existingLog});

  final String hijriDate;

  /// Null = backfill a missed day within the 6-day Hijri window.
  final AmalLogModel? existingLog;

  @override
  ConsumerState<EditAmalScreen> createState() => _EditAmalScreenState();
}

class _EditAmalScreenState extends ConsumerState<EditAmalScreen> {
  late Map<String, dynamic> _toggles;
  bool _isSaving = false;
  String? _error;
  bool _togglesSyncedToFields = false;

  @override
  void initState() {
    super.initState();
    final fields = ref.read(amalFieldsListProvider);
    _toggles = widget.existingLog != null
        ? normalizeTogglesForFields(widget.existingLog!.toggles, fields)
        : emptyTogglesForFields(fields);
  }

  void _toggle(String fieldId, List<AmalField> fields) {
    if (_isSaving) return;
    setState(() {
      _toggles = toggleAmalField(_toggles, fields, fieldId);
      _error = null;
    });
  }

  void _setNumeric(String fieldId, int value, List<AmalField> fields) {
    if (_isSaving) return;
    setState(() {
      _toggles = setAmalNumeric(_toggles, fields, fieldId, value);
      _error = null;
    });
  }

  Future<void> _onSubmit(List<AmalField> fields) async {
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) return;

    if (!hasAnyAmalDone(_toggles)) {
      setState(() => _error = 'কমপক্ষে একটি আমল নির্বাচন করুন');
      return;
    }
    if (!isTakbirWithinFard(_toggles, fields)) {
      setState(() => _error = 'তাকবীর ফরযের চেয়ে বেশি হতে পারে না');
      return;
    }

    final toggles = normalizeTogglesForFields(_toggles, fields);
    final score = calculateScore(toggles, fields);
    final now = DateTime.now().toUtc();
    final fs = ref.read(firestoreServiceProvider);
    final existing = widget.existingLog;
    final AmalLogModel saved;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      if (existing == null) {
        saved = AmalLogModel(
          uid: user.uid,
          displayName: user.name,
          photoUrl: user.photoUrl,
          isAnonymousDisplay: user.isAnonymousDisplay,
          hijriDate: widget.hijriDate,
          toggles: toggles,
          score: score,
          submittedAt: now,
        );
        await fs.saveAmalLog(saved, fields);
      } else {
        saved = AmalLogModel(
          uid: existing.uid,
          displayName: existing.displayName,
          photoUrl: existing.photoUrl,
          isAnonymousDisplay: existing.isAnonymousDisplay,
          hijriDate: existing.hijriDate,
          toggles: toggles,
          score: score,
          submittedAt: existing.submittedAt,
          editedAt: now,
          editCount: existing.editCount + 1,
        );
        await fs.editAmalLog(updatedLog: saved, fields: fields);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = existing == null
            ? 'সংরক্ষণ করা যায়নি। ইন্টারনেট চেক করুন।'
            : 'আপডেট করা যায়নি। ইন্টারনেট চেক করুন।';
      });
      return;
    }

    await LocalStorageService.saveLog(
      'log_${user.uid}_${widget.hijriDate}',
      saved.toHiveMap(),
    );

    if (!mounted) return;

    invalidateAfterAmalEdit(ref, user.uid, widget.hijriDate);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null ? 'আমল সংরক্ষণ হয়েছে ✓' : 'আমল আপডেট হয়েছে ✓',
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final fields = ref.watch(amalFieldsListProvider);
    ref.listen<List<AmalField>>(amalFieldsListProvider, (prev, next) {
      if (next.isEmpty || _togglesSyncedToFields) return;
      _togglesSyncedToFields = true;
      setState(() {
        _toggles = widget.existingLog != null
            ? normalizeTogglesForFields(widget.existingLog!.toggles, next)
            : emptyTogglesForFields(next);
      });
    });

    final locale = Localizations.localeOf(context).languageCode;
    final maxScore = editAmalMaxScore(fields);
    final score = calculateScore(_toggles, fields);
    final doneCount = _toggles.values
        .where((v) => v == true || (v is int && v > 0))
        .length;
    final title = IslamicDateService.displayFromStorageBn(widget.hijriDate);
    final hasAnyDone = hasAnyAmalDone(_toggles);
    final isBackfill = widget.existingLog == null;

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: _isSaving ? null : () => context.pop(),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.headlineMedium(context),
        ),
        actions: [
          if (widget.existingLog?.editedAt != null)
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: const Center(child: EditedBadge()),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(0, 4.h, 0, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardContainer(
                    color: AppColors.emeraldMid.withValues(alpha: 0.35),
                    borderColor: AppColors.goldBorder.withValues(alpha: 0.45),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.gold,
                          size: 18.r,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            isBackfill
                                ? 'পিছনের দিনের আমল — স্ট্রিক পরিবর্তন হবে না'
                                : 'স্ট্রিক পরিবর্তন হবে না',
                            style: AppTextStyles.bodySmall(
                              context,
                            ).copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),
                  EditAmalProgressCard(
                    done: doneCount,
                    total: fields.length,
                    score: score,
                    maxScore: maxScore,
                  ),
                  if (_error != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      _error!,
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(color: AppColors.danger, fontSize: 12.sp),
                    ),
                  ],
                  SizedBox(height: 14.h),
                  Text('আমল', style: AppTextStyles.headlineMedium(context)),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final field = fields[index];
              final pickerMax = amalEditNumericMax(field, _toggles, fields);
              final numericVal = field.type == AmalType.numeric
                  ? getNumericValue(_toggles[field.id], field.maxValue)
                  : null;
              final done = field.type == AmalType.numeric
                  ? (numericVal ?? 0) > 0
                  : (_toggles[field.id] as bool? ?? false);
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: AmalRow(
                  field: field,
                  locale: locale,
                  done: done,
                  numericValue: numericVal,
                  numericPickerMax: pickerMax,
                  onNumericChanged: _isSaving
                      ? null
                      : (v) => _setNumeric(field.id, v, fields),
                  onChanged:
                      _isSaving ? null : (_) => _toggle(field.id, fields),
                ),
              );
            },
          ),
          SliverPadding(
            padding: EdgeInsets.only(top: 14.h, bottom: 24.h),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isSaving || !hasAnyDone
                      ? null
                      : () => _onSubmit(fields),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.emeraldDeep,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 22.r,
                          height: 22.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.emeraldDeep,
                          ),
                        )
                      : Text(
                          isBackfill ? 'আমল সংরক্ষণ করুন' : 'আমল আপডেট করুন',
                          style: AppTextStyles.button(context).copyWith(
                            color: AppColors.emeraldDeep,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

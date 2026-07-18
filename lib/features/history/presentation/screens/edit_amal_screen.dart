import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/amal_edit_debug.dart';
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
import '../../../../shared/widgets/fard_prayer_expand_row.dart';

class EditAmalScreen extends ConsumerStatefulWidget {
  const EditAmalScreen({super.key, required this.hijriDate, this.existingLog});

  final String hijriDate;

  /// Null = backfill a missed day since account creation.
  final AmalLogModel? existingLog;

  @override
  ConsumerState<EditAmalScreen> createState() => _EditAmalScreenState();
}

class _EditAmalScreenState extends ConsumerState<EditAmalScreen> {
  late Map<String, dynamic> _toggles;
  bool _isSaving = false;
  String? _error;
  bool _togglesSyncedToFields = false;
  String? _expandedFieldId;
  final Map<String, Set<int>> _prayerSelections = {};
  /// Hive key for the prayer-circle lit positions for a specific submitted log.
  /// Must match the key used by AmalNotifier so the home and edit screens share
  /// the same cached selections.
  static String _selectionsHiveKey(String uid, String hijriDate) =>
      'selections_${uid}_$hijriDate';

  @override
  void initState() {
    super.initState();
    final fields = ref.read(amalFieldsListProvider);
    _toggles = widget.existingLog != null
        ? normalizeTogglesForFields(widget.existingLog!.toggles, fields)
        : emptyTogglesForFields(fields);
    // Restore the exact prayer-circle positions from the local Hive cache
    // (stored alongside each submitted log). Without this, the UI would
    // default to a left-to-right fill (Fajr+Dhuhr) even if the user prayed
    // Fajr+Isha, because Firestore only persists counts.
    if (widget.existingLog != null) {
      final key = _selectionsHiveKey(
        widget.existingLog!.uid,
        widget.existingLog!.hijriDate,
      );
      final raw = LocalStorageService.getLog(key);
      if (raw != null) {
        raw.forEach((fieldId, value) {
          if (value is List) {
            _prayerSelections[fieldId] = value
                .map((e) => (e as num?)?.toInt())
                .whereType<int>()
                .toSet();
          }
        });
      }
    }
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
      // When an expandable numeric field changes via the stepper, reconcile
      // the prayer selection to a left-to-right fill so the expand row stays
      // consistent. Without this, stale _prayerSelections would cause wrong
      // circles to appear lit (or wrong circles to be toggled) on the next
      // interaction.
      final changedField =
          fields.where((f) => f.id == fieldId).firstOrNull;
      if (changedField != null && changedField.supportsExpansion) {
        final clampedVal = value.clamp(0, changedField.maxValue);
        _prayerSelections[fieldId] =
            <int>{for (var i = 0; i < clampedVal; i++) i};
      }
    });
  }

  void _toggleExpand(String fieldId) {
    setState(() {
      _expandedFieldId = _expandedFieldId == fieldId ? null : fieldId;
    });
  }

  void _togglePrayer(String fieldId, int index, AmalField field) {
    if (_isSaving) return;
    setState(() {
      final numericVal = getNumericValue(_toggles[fieldId], field.maxValue);
      final base = resolvePrayerSelection(
        _prayerSelections[fieldId],
        numericVal,
        field.maxValue,
      );
      final current = Set<int>.from(base);
      if (current.contains(index)) {
        current.remove(index);
      } else {
        current.add(index);
      }
      _prayerSelections[fieldId] = current;
      _toggles = setAmalNumeric(_toggles, [field], fieldId, current.length);
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
          prayers: <String, List<int>>{
            for (final e in _prayerSelections.entries)
              e.key: (e.value.toList()..sort()),
          },
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
          prayers: <String, List<int>>{
            for (final e in _prayerSelections.entries)
              e.key: (e.value.toList()..sort()),
          },
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
    // Persist the exact prayer-circle positions alongside the saved log so
    // future reloads (both from Hive and after a Firestore refresh) can
    // restore the correct circles rather than defaulting to a left-fill.
    if (_prayerSelections.isNotEmpty) {
      final selectionsMap = <String, dynamic>{
        for (final entry in _prayerSelections.entries)
          entry.key: (entry.value.toList()..sort()),
      };
      await LocalStorageService.saveLog(
        _selectionsHiveKey(user.uid, widget.hijriDate),
        selectionsMap,
      );
    }

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
        // Re-load prayer selections from Hive so the expand row shows the
        // correct specific prayers (not a default left-fill). Only clear
        // and re-populate; never wipe existing user edits already in memory.
        if (widget.existingLog != null && _prayerSelections.isEmpty) {
          final key = _selectionsHiveKey(
            widget.existingLog!.uid,
            widget.existingLog!.hijriDate,
          );
          final raw = LocalStorageService.getLog(key);
          if (raw != null) {
            raw.forEach((fieldId, value) {
              if (value is List) {
                _prayerSelections[fieldId] = value
                    .map((e) => (e as num?)?.toInt())
                    .whereType<int>()
                    .toSet();
              }
            });
          }
        }
      });
    });

    final locale = Localizations.localeOf(context).languageCode;
    final lockedFieldIds = <String>{
      for (final f in fields)
        if (!IslamicDateService.isHijriDateOnOrAfter(
          widget.hijriDate,
          f.createdAt,
        ))
          f.id,
    };
    if (kDebugMode) {
      for (final f in fields) {
        logAmalEditDebug(
          'field=${f.id} createdAt=${f.createdAt} '
          'hijriDate=${widget.hijriDate} '
          'locked=${lockedFieldIds.contains(f.id)}',
        );
      }
    }
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
              final isLocked = lockedFieldIds.contains(field.id);

              final canExpand = !isLocked && !_isSaving && field.supportsExpansion;
              final isExpanded = canExpand && _expandedFieldId == field.id;

              Set<int> selection = const <int>{};
              if (canExpand) {
                selection = resolvePrayerSelection(
                  _prayerSelections[field.id],
                  numericVal ?? 0,
                  field.maxValue,
                );
              }

              final row = Opacity(
                opacity: isLocked ? 0.5 : 1.0,
                child: AmalRow(
                  field: field,
                  locale: locale,
                  done: done,
                  numericValue: numericVal,
                  numericPickerMax: pickerMax,
                  readOnly: isLocked || _isSaving,
                  onNumericChanged: (isLocked || _isSaving)
                      ? null
                      : (v) => _setNumeric(field.id, v, fields),
                  onChanged: (isLocked || _isSaving)
                      ? null
                      : (_) => _toggle(field.id, fields),
                  expandable: canExpand,
                  isExpanded: isExpanded,
                  onToggleExpand: canExpand
                      ? () => _toggleExpand(field.id)
                      : null,
                  expandedContent: canExpand
                      ? FardPrayerExpandRow(
                          selectedIndices: selection,
                          slotCount: field.maxValue,
                          onToggleIndex: (i) => _togglePrayer(field.id, i, field),
                        )
                      : null,
                ),
              );

              final child = Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isExpanded
                        ? TapRegion(
                            onTapOutside: (_) => setState(() => _expandedFieldId = null),
                            child: row,
                          )
                        : row,
                    if (isLocked)
                      Padding(
                        padding: EdgeInsets.only(left: 14.w, top: 2.h, bottom: 4.h),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 12.r,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'এই দিনে এই আমল ছিল না',
                              style: AppTextStyles.bodySmall(context).copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );

              return child;
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

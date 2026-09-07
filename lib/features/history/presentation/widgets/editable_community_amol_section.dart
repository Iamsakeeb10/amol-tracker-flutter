import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/amal_edit_toggles.dart';
import '../../../../core/utils/amal_entry_policy.dart';
import '../../../../core/utils/bengali_numeral_helper.dart';
import '../../../../core/utils/score_calculator.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/amal_fields_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/fard_prayer_expand_row.dart';

/// In-place editable community amol section for a specific Hijri date, used on
/// the day-detail screen so community amols can be changed directly on the same
/// screen like the home screen (no pencil-FAB round trip).
///
/// Mirrors the logic in `EditAmalScreen` but renders inline and keeps its own
/// Save button instead of popping. Only rendered when the day is editable.
class EditableCommunityAmolSection extends ConsumerStatefulWidget {
  const EditableCommunityAmolSection({
    super.key,
    required this.uid,
    required this.hijriDate,
    this.existingLog,
  });

  final String uid;
  final String hijriDate;

  /// Null = backfill a missed day since account creation.
  final AmalLogModel? existingLog;

  @override
  ConsumerState<EditableCommunityAmolSection> createState() =>
      _EditableCommunityAmolSectionState();
}

class _EditableCommunityAmolSectionState
    extends ConsumerState<EditableCommunityAmolSection> {
  late Map<String, dynamic> _toggles;
  late Map<String, dynamic> _savedToggles;
  bool _isSaving = false;
  String? _error;
  bool _togglesSyncedToFields = false;
  String? _expandedFieldId;
  final Map<String, Set<int>> _prayerSelections = {};

  /// Hive key for the prayer-circle lit positions for a specific submitted log.
  /// Must match the key used by AmalNotifier and EditAmalScreen so the home,
  /// edit, and day-detail screens share the same cached selections.
  static String _selectionsHiveKey(String uid, String hijriDate) =>
      'selections_${uid}_$hijriDate';

  bool get _dirty => _toggles != _savedToggles;

  @override
  void initState() {
    super.initState();
    final fields = ref.read(amalFieldsListProvider);
    _toggles = widget.existingLog != null
        ? normalizeTogglesForFields(widget.existingLog!.toggles, fields)
        : emptyTogglesForFields(fields);
    _savedToggles = Map<String, dynamic>.from(_toggles);
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
      if (_prayerSelections.isEmpty && widget.existingLog!.prayers.isNotEmpty) {
        for (final entry in widget.existingLog!.prayers.entries) {
          _prayerSelections[entry.key] = entry.value.toSet();
        }
      }
    }
  }

  void _syncFieldsIfNeeded() {
    final fields = ref.read(amalFieldsListProvider);
    if (fields.isEmpty || _togglesSyncedToFields) return;
    _togglesSyncedToFields = true;
    _toggles = widget.existingLog != null
        ? normalizeTogglesForFields(widget.existingLog!.toggles, fields)
        : emptyTogglesForFields(fields);
    _savedToggles = Map<String, dynamic>.from(_toggles);
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
      if (_prayerSelections.isEmpty && widget.existingLog!.prayers.isNotEmpty) {
        for (final entry in widget.existingLog!.prayers.entries) {
          _prayerSelections[entry.key] = entry.value.toSet();
        }
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
      final changedField = fields.where((f) => f.id == fieldId).firstOrNull;
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

  Future<void> _onSave(List<AmalField> fields) async {
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) return;

    if (!hasAnyAmalDone(_toggles)) {
      setState(() => _error = 'কমপক্ষে একটি আমল নির্বাচন করুন');
      return;
    }

    final existing = widget.existingLog;
    late final List<AmalField> activeFields;

    if (existing == null) {
      activeFields = ref.read(amalEntryPolicyProvider).activeFields;
    } else {
      final existingActiveIds = existing.activeFieldIds;
      activeFields =
          fields.where((f) => existingActiveIds.contains(f.id)).toList();
    }

    if (!isTakbirWithinFard(_toggles, activeFields)) {
      setState(() => _error = 'তাকবীর ফরযের চেয়ে বেশি হতে পারে না');
      return;
    }

    final toggles = normalizeTogglesForFields(_toggles, activeFields);
    final scoreResult = calculateAmalScore(
      toggles: toggles,
      activeFields: activeFields,
    );
    final now = DateTime.now().toUtc();
    final fs = ref.read(firestoreServiceProvider);
    final AmalLogModel saved;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      if (existing == null) {
        final policy = ref.read(amalEntryPolicyProvider);
        saved = AmalLogModel(
          uid: user.uid,
          displayName: user.name,
          photoUrl: user.photoUrl,
          isAnonymousDisplay: user.isAnonymousDisplay,
          hijriDate: widget.hijriDate,
          toggles: toggles,
          score: scoreResult.score,
          submittedAt: now,
          maxScore: scoreResult.maxScore,
          activeFieldIds: scoreResult.activeFieldIds,
          specialTimeApplied: policy.isSpecialTimeActive,
          prayers: <String, List<int>>{
            for (final e in _prayerSelections.entries)
              e.key: (e.value.toList()..sort()),
          },
        );
        await fs.saveAmalLog(saved, activeFields);
      } else {
        saved = AmalLogModel(
          uid: existing.uid,
          displayName: existing.displayName,
          photoUrl: existing.photoUrl,
          isAnonymousDisplay: existing.isAnonymousDisplay,
          hijriDate: existing.hijriDate,
          toggles: toggles,
          score: scoreResult.score,
          submittedAt: existing.submittedAt,
          editedAt: now,
          editCount: existing.editCount + 1,
          maxScore: scoreResult.maxScore,
          activeFieldIds: scoreResult.activeFieldIds,
          specialTimeApplied: existing.specialTimeApplied,
          prayers: <String, List<int>>{
            for (final e in _prayerSelections.entries)
              e.key: (e.value.toList()..sort()),
          },
        );
        await fs.editAmalLog(updatedLog: saved, fields: activeFields);
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

    setState(() {
      _isSaving = false;
      _toggles = normalizeTogglesForFields(saved.toggles, activeFields);
      _savedToggles = Map<String, dynamic>.from(_toggles);
      _expandedFieldId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing == null ? 'আমল সংরক্ষণ হয়েছে ✓' : 'আমল আপডেট হয়েছে ✓',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fields = ref.watch(amalFieldsListProvider);
    _syncFieldsIfNeeded();

    final locale = Localizations.localeOf(context).languageCode;
    final lockedFieldIds = <String>{
      for (final f in fields)
        if (!IslamicDateService.isHijriDateOnOrAfter(
          widget.hijriDate,
          f.createdAt,
        ))
          f.id,
    };
    final existing = widget.existingLog;
    final policy = ref.watch(amalEntryPolicyProvider);
    late final List<AmalField> mainFields;
    late final List<AmalField> optionalFields;
    late final List<AmalField> inactiveFields;
    late final List<AmalField> activeFields;
    late final bool isSpecialTimeActive;
    if (existing == null) {
      mainFields = policy.mainFields;
      optionalFields = policy.optionalFields;
      inactiveFields = policy.inactiveSpecialTimeFields;
      activeFields = policy.activeFields;
      isSpecialTimeActive = policy.isSpecialTimeActive;
    } else {
      final existingActiveIds = existing.activeFieldIds.toSet();
      activeFields =
          fields.where((f) => existingActiveIds.contains(f.id)).toList();
      isSpecialTimeActive = existing.specialTimeApplied;

      final user = ref.watch(currentUserProvider).asData?.value;
      final userProfile = user?.amalProfile ?? UserAmalProfile.unset;
      final editingPolicy = AmalEntryPolicy.from(
        userProfile,
        activeFields,
        specialTimeActive: isSpecialTimeActive,
      );

      mainFields = editingPolicy.mainFields;
      optionalFields = editingPolicy.optionalFields;

      inactiveFields = isSpecialTimeActive
          ? fields
              .where(
                (f) =>
                    f.isActive &&
                    f.id.isNotEmpty &&
                    !existingActiveIds.contains(f.id),
              )
              .toList()
          : const [];
    }
    final isFriday =
        IslamicDateService.weekdayEnglishForStorage(widget.hijriDate) ==
        'Friday';
    final hasAnyDone = _toggles.entries
        .where((e) => activeFields.any((f) => f.id == e.key))
        .any((e) => e.value == true || (e.value is int && e.value > 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              _error!,
              style: AppTextStyles.bodySmall(
                context,
              ).copyWith(color: AppColors.danger, fontSize: 12.sp),
            ),
          ),
        for (final field in mainFields) ...[
          _buildFieldRow(
            field: field,
            fields: fields,
            locale: locale,
            lockedFieldIds: lockedFieldIds,
            readOnly: false,
            isFriday: isFriday,
          ),
          SizedBox(height: 8.h),
        ],
        if (optionalFields.isNotEmpty) ...[
          _OptionalFieldsSection(
            fields: optionalFields,
            buildRow: (field) => _buildFieldRow(
              field: field,
              fields: fields,
              locale: locale,
              lockedFieldIds: lockedFieldIds,
              readOnly: false,
              isFriday: isFriday,
            ),
          ),
          SizedBox(height: 8.h),
        ],
        if (inactiveFields.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
            child: Row(
              children: [
                Icon(
                  Icons.pause_circle_outline_rounded,
                  size: 20.r,
                  color: AppColors.textMuted,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!
                        .inactiveSpecialTimeExcusedSection,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final field in inactiveFields) ...[
            _buildFieldRow(
              field: field,
              fields: fields,
              locale: locale,
              lockedFieldIds: lockedFieldIds,
              readOnly: true,
              isFriday: isFriday,
            ),
            SizedBox(height: 8.h),
          ],
        ],
        if (_dirty) ...[
          SizedBox(height: 12.h),
          _SaveButton(
            isSaving: _isSaving,
            enabled: hasAnyDone,
            isBackfill: widget.existingLog == null,
            onPressed: () => _onSave(fields),
          ),
        ],
      ],
    );
  }

  Widget _buildFieldRow({
    required AmalField field,
    required List<AmalField> fields,
    required String locale,
    required Set<String> lockedFieldIds,
    required bool readOnly,
    required bool isFriday,
  }) {
    final pickerMax = amalEditNumericMax(field, _toggles, fields);
    final numericVal = field.type == AmalType.numeric
        ? getNumericValue(_toggles[field.id], field.maxValue)
        : null;
    final done = field.type == AmalType.numeric
        ? (numericVal ?? 0) > 0
        : (_toggles[field.id] as bool? ?? false);
    final isLocked = lockedFieldIds.contains(field.id) || readOnly;
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
        onToggleExpand: canExpand ? () => _toggleExpand(field.id) : null,
        expandedContent: canExpand
            ? FardPrayerExpandRow(
                selectedIndices: selection,
                slotCount: field.maxValue,
                isFriday: isFriday,
                onToggleIndex: (i) => _togglePrayer(field.id, i, field),
              )
            : null,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isExpanded
            ? TapRegion(
                onTapOutside: (_) => setState(() => _expandedFieldId = null),
                child: row,
              )
            : row,
        if (lockedFieldIds.contains(field.id))
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
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(color: AppColors.textMuted, fontSize: 11.sp),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _OptionalFieldsSection extends StatefulWidget {
  const _OptionalFieldsSection({
    required this.fields,
    required this.buildRow,
  });

  final List<AmalField> fields;
  final Widget Function(AmalField field) buildRow;

  @override
  State<_OptionalFieldsSection> createState() => _OptionalFieldsSectionState();
}

class _OptionalFieldsSectionState extends State<_OptionalFieldsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final radius = 14.r;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.goldCard,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: AppColors.goldBorder, width: 1),
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20.r,
                      color: AppColors.gold,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Flexible(
                    flex: 5,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            l10n.optionalAmalSectionTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyLarge(context).copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.goldLight,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          constraints: BoxConstraints(minWidth: 20.r),
                          height: 20.r,
                          padding: EdgeInsets.symmetric(horizontal: 6.w),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            locale == 'bn'
                                ? toBengaliNumeral(widget.fields.length)
                                : '${widget.fields.length}',
                            style: AppTextStyles.pill(context).copyWith(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.goldPale,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _expanded
              ? Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: Column(
                    children: [
                      for (final field in widget.fields) widget.buildRow(field),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaving,
    required this.enabled,
    required this.isBackfill,
    required this.onPressed,
  });

  final bool isSaving;
  final bool enabled;
  final bool isBackfill;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSaving || !enabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.emeraldDeep,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        child: isSaving
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
    );
  }
}
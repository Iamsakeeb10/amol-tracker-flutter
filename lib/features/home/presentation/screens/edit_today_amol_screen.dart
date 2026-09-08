import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/amal_edit_debug.dart';
import '../../../../core/utils/amal_edit_toggles.dart';
import '../../../../core/utils/amal_entry_policy.dart';
import '../../../../core/utils/bengali_numeral_helper.dart';
import '../../../../core/utils/score_calculator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/amal_fields_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/personal_amol_date_pending_provider.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/edit_amal_progress_card.dart';
import '../../../../shared/widgets/edited_badge.dart';
import '../../../../shared/widgets/fard_prayer_expand_row.dart';
import '../../../personal_amol/presentation/widgets/personal_amol_day_detail_section.dart';

/// Combined edit screen shown when the user presses the pencil icon on the
/// home screen after submitting today's amol.
///
/// Mirrors [EditAmalScreen] for community amol. When [showPersonalSection] is
/// true, appends the personal amol section ([PersonalAmolDayDetailSection])
/// below. Home's community pencil passes `false` so only community fields are
/// editable; personal has its own pencil and edit route.
///
/// The two sections save independently so a failure in one does not affect
/// the other. Personal amol completions are never written to the community
/// score, streak, or leaderboard — they persist to the user-private
/// subcollection.
class EditTodayAmolScreen extends ConsumerStatefulWidget {
  const EditTodayAmolScreen({
    super.key,
    required this.uid,
    required this.todayHijri,
    required this.existingLog,
    this.showPersonalSection = true,
  });

  final String uid;
  final String todayHijri;
  final AmalLogModel existingLog;

  /// When false, only the community amol section is shown (home community
  /// pencil). When true, personal amol is appended below (legacy combined).
  final bool showPersonalSection;

  @override
  ConsumerState<EditTodayAmolScreen> createState() =>
      _EditTodayAmolScreenState();
}

class _EditTodayAmolScreenState extends ConsumerState<EditTodayAmolScreen> {
  late Map<String, dynamic> _toggles;
  bool _isSaving = false;
  String? _error;
  bool _togglesSyncedToFields = false;
  String? _expandedFieldId;
  final Map<String, Set<int>> _prayerSelections = {};

  static String _selectionsHiveKey(String uid, String hijriDate) =>
      'selections_${uid}_$hijriDate';

  @override
  void initState() {
    super.initState();
    final fields = ref.read(amalFieldsListProvider);
    _toggles = normalizeTogglesForFields(widget.existingLog.toggles, fields);
    // Restore prayer circle positions from local Hive cache.
    final key = _selectionsHiveKey(widget.existingLog.uid, widget.existingLog.hijriDate);
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
    // Fallback: use prayer selections from the Firestore model.
    if (_prayerSelections.isEmpty && widget.existingLog.prayers.isNotEmpty) {
      for (final entry in widget.existingLog.prayers.entries) {
        _prayerSelections[entry.key] = entry.value.toSet();
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

  bool _computeCommunityDirty(List<AmalField> activeFields) {
    final existingToggles = normalizeTogglesForFields(
      widget.existingLog.toggles,
      activeFields,
    );
    final currentToggles = normalizeTogglesForFields(
      _toggles,
      activeFields,
    );

    for (final field in activeFields) {
      if (existingToggles[field.id] != currentToggles[field.id]) {
        return true;
      }
    }

    if (_prayerSelections.isNotEmpty || widget.existingLog.prayers.isNotEmpty) {
      for (final field in activeFields) {
        final currentSet = _prayerSelections[field.id] ?? const <int>{};
        final existingList =
            widget.existingLog.prayers[field.id] ?? const <int>[];
        final existingSet = existingList.toSet();
        if (!setEquals(currentSet, existingSet)) {
          return true;
        }
      }
    }

    return false;
  }

  Future<void> _saveAll(
    List<AmalField> fields,
    List<AmalField> activeFields,
  ) async {
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) return;

    final showPersonal = widget.showPersonalSection;
    var isPersonalDirty = false;
    PersonalAmolDateEditKey? personalKey;
    if (showPersonal) {
      personalKey = PersonalAmolDateEditKey(
        uid: widget.uid,
        hijriDate: widget.todayHijri,
      );
      isPersonalDirty =
          ref.read(personalAmolDatePendingProvider(personalKey)).dirty;
    }
    final isCommunityDirty = _computeCommunityDirty(activeFields);

    if (!isPersonalDirty && !isCommunityDirty) return;

    if (isCommunityDirty) {
      if (!hasAnyAmalDone(_toggles)) {
        setState(() => _error = 'কমপক্ষে একটি আমল নির্বাচন করুন');
        return;
      }

      if (!isTakbirWithinFard(_toggles, activeFields)) {
        setState(() => _error = 'তাকবীর ফরযের চেয়ে বেশি হতে পারে না');
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      if (isPersonalDirty && personalKey != null) {
        await ref
            .read(personalAmolDatePendingProvider(personalKey).notifier)
            .save();
      }

      if (isCommunityDirty) {
        final existing = widget.existingLog;
        final toggles = normalizeTogglesForFields(_toggles, activeFields);
        final scoreResult =
            calculateAmalScore(toggles: toggles, activeFields: activeFields);
        final now = DateTime.now().toUtc();
        final fs = ref.read(firestoreServiceProvider);

        final saved = AmalLogModel(
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

        await LocalStorageService.saveLog(
          'log_${user.uid}_${widget.todayHijri}',
          saved.toHiveMap(),
        );
        if (_prayerSelections.isNotEmpty) {
          final selectionsMap = <String, dynamic>{
            for (final entry in _prayerSelections.entries)
              entry.key: (entry.value.toList()..sort()),
          };
          await LocalStorageService.saveLog(
            _selectionsHiveKey(user.uid, widget.todayHijri),
            selectionsMap,
          );
        }

        invalidateAfterAmalEdit(ref, user.uid, widget.todayHijri);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'আপডেট করা যায়নি। ইন্টারনেট চেক করুন।';
      });
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('আমল আপডেট হয়েছে ✓')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final fields = ref.watch(amalFieldsListProvider);

    // Sync toggles once fields load (same pattern as EditAmalScreen).
    ref.listen<List<AmalField>>(amalFieldsListProvider, (prev, next) {
      if (next.isEmpty || _togglesSyncedToFields) return;
      _togglesSyncedToFields = true;
      setState(() {
        _toggles =
            normalizeTogglesForFields(widget.existingLog.toggles, next);
        if (_prayerSelections.isEmpty) {
          final key = _selectionsHiveKey(
            widget.existingLog.uid,
            widget.existingLog.hijriDate,
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
          if (_prayerSelections.isEmpty &&
              widget.existingLog.prayers.isNotEmpty) {
            for (final entry in widget.existingLog.prayers.entries) {
              _prayerSelections[entry.key] = entry.value.toSet();
            }
          }
        }
      });
    });

    final locale = Localizations.localeOf(context).languageCode;
    final existing = widget.existingLog;

    // Determine which fields were active when this log was originally submitted.
    final existingActiveIds = existing.activeFieldIds.toSet();
    final activeFields =
        fields.where((f) => existingActiveIds.contains(f.id)).toList();
    final isSpecialTimeActive = existing.specialTimeApplied;

    final user = ref.watch(currentUserProvider).asData?.value;
    final userProfile = user?.amalProfile ?? UserAmalProfile.unset;
    final editingPolicy = AmalEntryPolicy.from(
      userProfile,
      activeFields,
      specialTimeActive: isSpecialTimeActive,
    );

    final mainFields = editingPolicy.mainFields;
    final optionalFields = editingPolicy.optionalFields;
    final inactiveFields = isSpecialTimeActive
        ? fields
            .where(
              (f) =>
                  f.isActive &&
                  f.id.isNotEmpty &&
                  !existingActiveIds.contains(f.id),
            )
            .toList()
        : const <AmalField>[];

    final lockedFieldIds = <String>{
      for (final f in fields)
        if (!IslamicDateService.isHijriDateOnOrAfter(
          widget.todayHijri,
          f.createdAt,
        ))
          f.id,
    };

    if (kDebugMode) {
      for (final f in fields) {
        logAmalEditDebug(
          'field=${f.id} createdAt=${f.createdAt} '
          'hijriDate=${widget.todayHijri} '
          'locked=${lockedFieldIds.contains(f.id)}',
        );
      }
    }

    final maxScore = editAmalMaxScore(activeFields);
    final score = editAmalScore(_toggles, activeFields);
    final activeIds = activeFields.map((f) => f.id).toSet();
    final doneCount = _toggles.entries
        .where((e) => activeIds.contains(e.key))
        .where((e) => e.value == true || (e.value is int && e.value > 0))
        .length;
    final isFriday =
        IslamicDateService.weekdayEnglishForStorage(widget.todayHijri) ==
            'Friday';
    final title =
        IslamicDateService.displayFromStorageBn(widget.todayHijri);
    final l10n = AppLocalizations.of(context)!;

    final personalKey = PersonalAmolDateEditKey(
      uid: widget.uid,
      hijriDate: widget.todayHijri,
    );
    final isPersonalDirty = widget.showPersonalSection
        ? ref.watch(personalAmolDatePendingProvider(personalKey)).dirty
        : false;
    final personalIsSaving = widget.showPersonalSection
        ? ref.watch(personalAmolDatePendingProvider(personalKey)).isSaving
        : false;
    final isCommunityDirty = _computeCommunityDirty(activeFields);
    final canSave = isCommunityDirty || isPersonalDirty;

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.headlineMedium(context),
        ),
        actions: [
          if (existing.editedAt != null)
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: const Center(child: EditedBadge()),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 10.h),
          child: SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: (_isSaving || personalIsSaving || !canSave)
                  ? null
                  : () => _saveAll(fields, activeFields),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.emeraldDeep,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: (_isSaving || personalIsSaving)
                  ? SizedBox(
                      width: 22.r,
                      height: 22.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.emeraldDeep,
                      ),
                    )
                  : Text(
                      'আমল আপডেট করুন',
                      style: AppTextStyles.button(context).copyWith(
                        color: AppColors.emeraldDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Community amol section ─────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(0, 4.h, 0, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardContainer(
                    color: AppColors.emeraldMid.withValues(alpha: 0.35),
                    borderColor:
                        AppColors.goldBorder.withValues(alpha: 0.45),
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
                            'স্ট্রিক পরিবর্তন হবে না',
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
                    total: activeFields.length,
                    score: score,
                    maxScore: maxScore,
                  ),
                  if (_error != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      _error!,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.danger,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                  SizedBox(height: 14.h),
                  Text(
                    l10n.todaysAmal,
                    style: AppTextStyles.headlineMedium(context),
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
          // Main community amol rows
          SliverList.builder(
            itemCount: mainFields.length,
            itemBuilder: (context, index) => _buildEditFieldRow(
              field: mainFields[index],
              fields: fields,
              locale: locale,
              lockedFieldIds: lockedFieldIds,
              readOnly: false,
              isFriday: isFriday,
            ),
          ),
          if (optionalFields.isNotEmpty)
            SliverToBoxAdapter(
              child: _EditOptionalFieldsSection(
                fields: optionalFields,
                locale: locale,
                buildRow: (field) => _buildEditFieldRow(
                  field: field,
                  fields: fields,
                  locale: locale,
                  lockedFieldIds: lockedFieldIds,
                  readOnly: false,
                  isFriday: isFriday,
                ),
              ),
            ),
          if (inactiveFields.isNotEmpty) ...[
            SliverToBoxAdapter(child: SizedBox(height: 8.h)),
            SliverToBoxAdapter(
              child: Padding(
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
                        l10n.inactiveSpecialTimeExcusedSection,
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
            ),
            SliverList.builder(
              itemCount: inactiveFields.length,
              itemBuilder: (context, index) => _buildEditFieldRow(
                field: inactiveFields[index],
                fields: fields,
                locale: locale,
                lockedFieldIds: lockedFieldIds,
                readOnly: true,
                isFriday: isFriday,
              ),
            ),
          ],
          // ── Personal amol section (optional) ───────────────────────────────
          if (widget.showPersonalSection) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(height: 1, color: AppColors.cardBorder),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Text(
                        l10n.personalAmolSectionTitle,
                        style: AppTextStyles.label(context).copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(height: 1, color: AppColors.cardBorder),
                    ),
                  ],
                ),
              ),
            ),
            // Inline save suppressed — single bottom bar handles both sections.
            SliverToBoxAdapter(
              child: PersonalAmolDayDetailSection(
                uid: widget.uid,
                hijriDate: widget.todayHijri,
                showInlineSaveButton: false,
              ),
            ),
          ],
          SliverToBoxAdapter(child: SizedBox(height: 32.h)),
        ],
      ),
    );
  }

  Widget _buildEditFieldRow({
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

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isExpanded
              ? TapRegion(
                  onTapOutside: (_) =>
                      setState(() => _expandedFieldId = null),
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
  }
}

// ── Optional fields collapsible section ─────────────────────────────────────

class _EditOptionalFieldsSection extends StatefulWidget {
  const _EditOptionalFieldsSection({
    required this.fields,
    required this.locale,
    required this.buildRow,
  });

  final List<AmalField> fields;
  final String locale;
  final Widget Function(AmalField field) buildRow;

  @override
  State<_EditOptionalFieldsSection> createState() =>
      _EditOptionalFieldsSectionState();
}

class _EditOptionalFieldsSectionState
    extends State<_EditOptionalFieldsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              padding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
                            widget.locale == 'bn'
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
                      for (final field in widget.fields)
                        widget.buildRow(field),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

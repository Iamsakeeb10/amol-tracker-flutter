import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/personal_amol_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/personal_amol_provider.dart';
import 'personal_amol_icon_selector.dart';
import 'personal_amol_icons.dart';
import 'personal_amol_tracking_type_selector.dart';
import 'personal_amol_target_stepper.dart';
import 'personal_amol_weekday_chips.dart';

/// Inline bottom sheet for creating a personal amol (opened from the home `+`,
/// the list screen, and the empty state). Follows `streak_bottom_sheet.dart`
/// for the modal pattern and `personal_amol_create_sheet_v3.html` for layout:
/// name, Material-icon row, tracking type (toggle/count), daily target,
/// frequency pills, weekday chips — and no reminder.
///
/// Rendered inside a [DraggableScrollableSheet] so it opens at a sensible
/// height on any device, can be dragged to expand/collapse, and always
/// scrolls its content — not just once the keyboard is open.
///
/// IMPORTANT layering/sizing notes (fixes a bug where the Add button became
/// unreachable once the weekday chips row appeared):
/// 1. The sheet is pushed with `useRootNavigator: true` so it lands in the
///    ROOT overlay, above any persistent bottom tab bar. Without this, a
///    Stack-based/persistent bottom nav painted above the current branch's
///    Navigator can visually sit on top of the sheet's lower edge, blocking
///    taps on content near the bottom (e.g. the Add button) even though the
///    sheet itself is laid out correctly.
/// 2. A [DraggableScrollableController] lets us programmatically expand the
///    sheet the instant content grows (e.g. weekday chips appearing), so the
///    user never has to manually drag the sheet up just to reach the button.
class PersonalAmolCreateSheet extends ConsumerStatefulWidget {
  const PersonalAmolCreateSheet({
    super.key,
    required this.uid,
    this.existing,
    this.entryPoint = 'home_add',
  });

  final String uid;

  /// When non-null the sheet runs in edit mode, pre-filling from and saving
  /// back to this personal amol instead of creating a new one.
  final PersonalAmolModel? existing;

  /// Analytics entry point label. One of: `home_add`, `list_fab`,
  /// `empty_state`, `detail_edit`.
  final String entryPoint;

  static Future<void> show(
    BuildContext context, {
    required String uid,
    String entryPoint = 'home_add',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      // Insert into the ROOT navigator's overlay so the sheet renders above
      // any persistent/Stack-based bottom tab bar instead of underneath it.
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PersonalAmolCreateSheet(uid: uid, entryPoint: entryPoint),
    );
  }

  static Future<void> showForEdit(
    BuildContext context, {
    required String uid,
    required PersonalAmolModel amol,
    String entryPoint = 'detail_edit',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PersonalAmolCreateSheet(
        uid: uid,
        existing: amol,
        entryPoint: entryPoint,
      ),
    );
  }

  @override
  ConsumerState<PersonalAmolCreateSheet> createState() =>
      _PersonalAmolCreateSheetState();
}

class _PersonalAmolCreateSheetState extends ConsumerState<PersonalAmolCreateSheet> {
  static const double _minChildSize = 0.5;
  static const double _initialChildSize = 0.7;
  static const double _maxChildSize = 1;

  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  final _sheetController = DraggableScrollableController();

  String _icon = '';
  PersonalAmolType _type = PersonalAmolType.toggle;
  int _target = 3;
  bool _daily = true;
  final Set<int> _selectedWeekdays = <int>{};
  bool _isSaving = false;

  bool get _isWeekdays => !_daily;
  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _icon = existing.icon;
      _daily = existing.frequency == PersonalAmolFrequency.daily;
      _selectedWeekdays.addAll(existing.weekdays);
      _type = existing.type;
      _target = existing.type == PersonalAmolType.count ? existing.target : 3;
    }
    // Track which entry point opened the sheet.
    unawaited(
      AnalyticsService.instance.logPersonalAmolCreateSheetOpened(
        entryPoint: widget.entryPoint,
      ),
    );
    // When the name field gains focus the keyboard appears; expand the sheet
    // so the pinned Add button stays visible (and so the keyboard shrink keeps
    // content readable). Auto-collapse back to the initial height on blur so
    // the sheet returns to its normal state once the keyboard dismisses.
    _nameFocusNode.addListener(() {
      if (!mounted) return;
      if (_nameFocusNode.hasFocus) {
        _expandSheetIfNeeded();
      } else {
        _rebuildToInitialHeight();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  /// Grows the sheet toward [_maxChildSize] (if it isn't already there) so
  /// newly-added content — like the weekday chips row — stays fully visible
  /// and reachable without the user needing to drag the sheet manually.
  void _expandSheetIfNeeded({double target = _maxChildSize}) {
    if (!_sheetController.isAttached) return;
    if (_sheetController.size >= target) return;
    _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  /// Returns the sheet to its default resting height when the keyboard closes.
  void _rebuildToInitialHeight() {
    if (!_sheetController.isAttached) return;
    if (_sheetController.size > _initialChildSize) {
      _sheetController.animateTo(
        _initialChildSize,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onSelectDaily() {
    setState(() => _daily = true);
  }

  void _onSelectWeekdays() {
    setState(() => _daily = false);
    // New content (weekday chips) is about to be inserted below the
    // frequency pills — proactively expand the sheet so the Add button
    // doesn't end up squeezed against (or under) the bottom safe area.
    _expandSheetIfNeeded();
  }

  Future<void> _save() async {
    // Dismiss the keyboard first so the sheet settles before any snackbar
    // or pop animation runs.
    FocusScope.of(context).unfocus();

    final notifier = ref.read(personalAmolNotifierProvider(widget.uid).notifier);
    // Capacity only applies when creating a brand-new amol, not editing.
    if (!_isEditing && notifier.atCap) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.personalAmolCapMessage(AppConstants.kMaxFreePersonalAmol)),
          backgroundColor: AppColors.danger,
        ),
      );
      unawaited(
        AnalyticsService.instance.logPersonalAmolCapHit(
          cap: AppConstants.kMaxFreePersonalAmol,
        ),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final frequency =
        _daily ? PersonalAmolFrequency.daily : PersonalAmolFrequency.weekdays;
    final weekdays = _isWeekdays ? _selectedWeekdays.toList() : const <int>[];
    final type = _type;
    final target = _type == PersonalAmolType.count ? _target : 1;
    final typeLabel = type == PersonalAmolType.count ? 'count' : 'toggle';
    final freqLabel = _daily ? 'daily' : 'weekdays';

    setState(() => _isSaving = true);
    try {
      if (_isEditing && widget.existing != null) {
        final existing = widget.existing!;
        // Count which fields the user actually changed.
        var fieldsChanged = 0;
        if (name != existing.name) fieldsChanged++;
        if (_icon != existing.icon) fieldsChanged++;
        if (type != existing.type) fieldsChanged++;
        if (target != existing.target) fieldsChanged++;
        if (frequency != existing.frequency) fieldsChanged++;
        await notifier.updateAmol(
          existing.copyWith(
            name: name,
            icon: _icon,
            frequency: frequency,
            weekdays: weekdays,
            // Reminders are no longer a supported option; clear any leftover
            // reminder stored on older amols.
            reminderTime: null,
            type: type,
            target: target,
          ),
        );
        unawaited(
          AnalyticsService.instance.logPersonalAmolEdited(
            type: typeLabel,
            frequency: freqLabel,
            fieldsChanged: fieldsChanged,
          ),
        );
      } else {
        final amol = PersonalAmolModel(
          id: FirebaseFirestore.instance.collection('personal_amol_ids').doc().id,
          name: name,
          icon: _icon.isEmpty ? encodePersonalAmolIcon(Icons.auto_awesome) : _icon,
          frequency: frequency,
          weekdays: weekdays,
          reminderTime: null,
          isActive: true,
          createdAt: DateTime.now(),
          type: type,
          target: target,
        );
        await notifier.createAmol(amol);
        // amolCount = the freshly-updated active list length after creation.
        final amolCount =
            ref.read(activePersonalAmolProvider(widget.uid)).value?.length ?? 1;
        unawaited(
          AnalyticsService.instance.logPersonalAmolCreated(
            type: typeLabel,
            frequency: freqLabel,
            target: target,
            amolCount: amolCount,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).asData?.value?.uid;
    final atCap = !_isEditing &&
        uid != null &&
        (ref.watch(personalAmolNotifierProvider(uid)).length >=
            AppConstants.kMaxFreePersonalAmol);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    // Extra safety net: even with useSafeArea + useRootNavigator, pad for
    // the device's bottom safe area (gesture bar / soft nav) explicitly so
    // the Add button never ends up flush against — or behind — it.
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      controller: _sheetController,
      // 0.7 gives room to see the full form on a typical phone without
      // opening at max height and feeling modal/heavy; min/max bounds keep
      // it usable on both small and tall screens, and _maxChildSize now
      // leaves just a hair of room (0.95) rather than 0.92 so there's less
      // chance content gets squeezed when the weekday row appears.
      initialChildSize: _initialChildSize,
      minChildSize: _minChildSize,
      maxChildSize: _maxChildSize,
      snap: true,
      snapSizes: const [_minChildSize, _initialChildSize, _maxChildSize],
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.emeraldMid,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              // Drag handle — purely visual; drag-to-resize works anywhere
              // on the sheet because the scrollController below is what's
              // wired into DraggableScrollableSheet.
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    // Always-bounded ScrollPhysics so the sheet is scrollable
                    // from the first frame, not just once content overflows.
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      20.w,
                      16.h,
                      20.w,
                      // Keyboard-aware bottom padding lives on the scroll
                      // content, not on the sheet itself — so the sheet's
                      // fractional height stays stable and only the content
                      // scrolls up to clear the keyboard.
                      16.h + bottomInset + (bottomInset == 0 ? bottomSafeArea : 0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _isEditing
                                    ? l10n.personalAmolEditTitle
                                    : l10n.personalAmolCreateTitle,
                                style: AppTextStyles.headlineMedium(context),
                              ),
                            ),
                            // 36r visual + 6r padding on each side = ~48r tap target
                            Padding(
                              padding: EdgeInsets.all(6.r),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  width: 36.r,
                                  height: 36.r,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.cardDark,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: AppColors.textSecondary,
                                    size: 20.r,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (atCap) ...[
                          SizedBox(height: 16.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningLight,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: AppColors.warning.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              l10n.personalAmolCapMessage(
                                AppConstants.kMaxFreePersonalAmol,
                              ),
                              style: AppTextStyles.bodyMedium(context).copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: 16.h),
                        Text(l10n.personalAmolNameLabel,
                            style: AppTextStyles.bodyMedium(context)),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          maxLength: 40,
                          textInputAction: TextInputAction.done,
                          style: AppTextStyles.bodyLarge(context),
                          decoration: InputDecoration(
                            hintText: l10n.personalAmolNameHint,
                            hintStyle: AppTextStyles.bodyLarge(context).copyWith(
                              color: AppColors.textMuted.withValues(alpha: 0.5),
                            ),
                            counterText: '',
                            filled: true,
                            fillColor: AppColors.cardDark,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 14.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: AppColors.cardBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: AppColors.cardBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: AppColors.gold),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.personalAmolNameRequired
                              : null,
                          onFieldSubmitted: (_) => _nameFocusNode.unfocus(),
                        ),
                        SizedBox(height: 16.h),
                        PersonalAmolIconSelector(
                          selected: _icon,
                          onSelected: (value) => setState(() => _icon = value),
                        ),
                        SizedBox(height: 20.h),
                        Text(l10n.personalAmolTypeLabel,
                            style: AppTextStyles.bodyMedium(context)),
                        SizedBox(height: 8.h),
                        PersonalAmolTrackingTypeSelector(
                          value: _type,
                          onChanged: (v) => setState(() => _type = v),
                        ),
                        if (_type == PersonalAmolType.count) ...[
                          SizedBox(height: 16.h),
                          PersonalAmolTargetStepper(
                            value: _target,
                            onChanged: (v) => setState(() => _target = v),
                          ),
                        ],
                        SizedBox(height: 20.h),
                        Text(l10n.personalAmolFrequencyLabel,
                            style: AppTextStyles.bodyMedium(context)),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            _frequencyPill(
                              label: l10n.personalAmolFrequencyDaily,
                              selected: _daily,
                              onTap: _onSelectDaily,
                            ),
                            SizedBox(width: 10.w),
                            _frequencyPill(
                              label: l10n.personalAmolFrequencyWeekdays,
                              selected: _isWeekdays,
                              onTap: _onSelectWeekdays,
                            ),
                          ],
                        ),
                        if (_isWeekdays) ...[
                          SizedBox(height: 16.h),
                          PersonalAmolWeekdayChips(
                            selected: _selectedWeekdays,
                            onToggle: (day) => setState(() {
                              if (!_selectedWeekdays.add(day)) {
                                _selectedWeekdays.remove(day);
                              }
                            }),
                          ),
                        ],
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ),
              ),
              // Fixed footer — stays pinned to the bottom of the sheet no
              // matter how tall it is or how the content scrolls. It lives
              // inside the Form so field validation still applies.
              Container(
                padding: EdgeInsets.fromLTRB(
                  20.w,
                  12.h,
                  20.w,
                  // Keep the button floating above the on-screen keyboard
                  // (bottomInset = keyboard height when open) and clear the
                  // device bottom safe area otherwise.
                  12.h + bottomInset + (bottomInset == 0 ? bottomSafeArea : 0),
                ),
                decoration: const BoxDecoration(
                  color: AppColors.emeraldMid,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving || atCap ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.emeraldDeep,
                      disabledBackgroundColor: AppColors.cardBorder,
                      disabledForegroundColor: AppColors.textHint,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.emeraldDeep,
                            ),
                          )
                        : Icon(Icons.add_rounded, size: 16.r),
                    label: _isSaving
                        ? const SizedBox.shrink()
                        : Text(
                            _isEditing
                                ? l10n.personalAmolSaveLabel
                                : l10n.personalAmolAddLabel,
                            style: AppTextStyles.button(context).copyWith(
                              color: AppColors.emeraldDeep,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _frequencyPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
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
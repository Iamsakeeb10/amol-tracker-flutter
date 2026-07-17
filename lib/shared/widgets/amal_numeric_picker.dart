import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/bengali_numeral_helper.dart';
import '../../core/utils/tap_target.dart';

class AmalNumericPicker extends StatefulWidget {
  const AmalNumericPicker({
    super.key,
    required this.currentValue,
    required this.maxValue,
    required this.fieldMaxValue,
    required this.readOnly,
    required this.onChanged,
    this.onTapOverride,
    this.isExpanded = false,
  });

  final int currentValue;
  final int maxValue;
  final int fieldMaxValue;
  final bool readOnly;
  final ValueChanged<int>? onChanged;

  /// When provided, tapping the picker calls this instead of opening the
  /// value-selection overlay (used to toggle the inline prayer-circle row).
  final VoidCallback? onTapOverride;

  /// Rotates the trailing chevron to indicate the inline row is open.
  final bool isExpanded;

  @override
  State<AmalNumericPicker> createState() => _AmalNumericPickerState();
}

class _AmalNumericPickerState extends State<AmalNumericPicker> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _handleTap() {
    if (widget.readOnly) return;
    // Expandable fields toggle the inline prayer row instead of the overlay.
    if (widget.onTapOverride != null) {
      widget.onTapOverride!.call();
      return;
    }
    if (widget.onChanged == null) return;
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }
    _showOverlay();
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    final options = List<int>.generate(widget.maxValue + 1, (i) => i);

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            // Scrim
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeOverlay,
                behavior: HitTestBehavior.opaque,
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
              ),
            ),
            // Overlay panel anchored to the left of the picker widget
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.centerLeft,
              followerAnchor: Alignment.centerRight,
              offset: Offset(-8.w, 0),
              child: _AmalNumericOverlayPanel(
                options: options,
                selected: widget.currentValue,
                onSelect: (value) {
                  widget.onChanged?.call(value);
                  _removeOverlay();
                },
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.readOnly) {
      return Text(
        '${toBengaliNumeral(widget.currentValue)}/${toBengaliNumeral(widget.fieldMaxValue)}',
        style: AppTextStyles.pill(context).copyWith(
          color: widget.currentValue > 0 ? AppColors.gold : AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final hasValue = widget.currentValue > 0;
    final valueColor = hasValue ? AppColors.gold : AppColors.textMuted;
    final maxLabel = toBengaliNumeral(widget.fieldMaxValue);

    return CompositedTransformTarget(
      link: _layerLink,
      child: HitSlopWrapper(
        onTap: _handleTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 48.w, minHeight: 48.h),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.goldCard,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: hasValue
                        ? AppColors.goldBorder
                        : AppColors.cardBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      toBengaliNumeral(widget.currentValue),
                      style: AppTextStyles.bodyLarge(context).copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      '/$maxLabel',
                      style: AppTextStyles.bodySmall(context).copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    AnimatedRotation(
                      turns: widget.isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeInOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18.r,
                        color: hasValue ? AppColors.gold : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmalNumericOverlayPanel extends StatelessWidget {
  const _AmalNumericOverlayPanel({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<int> options;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    // Right-side panel: wider and well-proportioned
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = (screenWidth * 0.28).clamp(100.0, 140.0);

    return Material(
      color: Colors.transparent,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: panelWidth,
        constraints: BoxConstraints(maxHeight: 260.h),
        decoration: BoxDecoration(
          // Glassmorphic: semi-transparent emerald with blur effect via color
          color: AppColors.emeraldDeep.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: AppColors.goldBorder.withValues(alpha: 0.55),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppColors.emeraldMid.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(vertical: 6.h),
            itemCount: options.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 0.8,
              color: AppColors.cardBorder.withValues(alpha: 0.6),
            ),
            itemBuilder: (context, index) {
              final value = options[index];
              final isSelected = value == selected;

              return InkWell(
                onTap: () => onSelect(value),
                splashColor: AppColors.goldBorder.withValues(alpha: 0.2),
                highlightColor: AppColors.goldCard.withValues(alpha: 0.15),
                child: Container(
                  // No bg at all — glassmorphic panel, checkmark is the only indicator
                  color: Colors.transparent,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 11.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        toBengaliNumeral(value),
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          color: isSelected
                              ? AppColors.gold
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          fontSize: 15.sp,
                          height: 1.2,
                        ),
                      ),
                      // Fixed-width slot keeps row stable regardless of selection
                      SizedBox(
                        width: 18.r,
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                color: AppColors.gold,
                                size: 16.r,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

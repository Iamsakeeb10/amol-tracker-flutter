import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/bengali_numeral_helper.dart';
import '../../../../l10n/app_localizations.dart';
import 'amal_field_tile.dart';

class HomeInactiveSpecialTimeSection extends StatefulWidget {
  const HomeInactiveSpecialTimeSection({
    super.key,
    required this.fields,
    required this.uid,
    required this.locale,
    required this.readOnly,
    required this.onTapDetails,
  });

  final List<AmalField> fields;
  final String uid;
  final String locale;
  final bool readOnly;
  final ValueChanged<AmalField> onTapDetails;

  @override
  State<HomeInactiveSpecialTimeSection> createState() =>
      _HomeInactiveSpecialTimeSectionState();
}

class _HomeInactiveSpecialTimeSectionState
    extends State<HomeInactiveSpecialTimeSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          button: true,
          expanded: _expanded,
          label: l10n.inactiveSpecialTimeExcusedSection,
          child: _InactiveSpecialTimeHeader(
            expanded: _expanded,
            count: widget.fields.length,
            locale: widget.locale,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final field in widget.fields)
                        Padding(
                          key: ValueKey(field.id),
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: AmalFieldTile(
                            uid: widget.uid,
                            field: field,
                            locale: widget.locale,
                            readOnly: widget.readOnly,
                            onTapDetails: () => widget.onTapDetails(field),
                          ),
                        ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _InactiveSpecialTimeHeader extends StatelessWidget {
  const _InactiveSpecialTimeHeader({
    required this.expanded,
    required this.count,
    required this.locale,
    required this.onTap,
  });

  final bool expanded;
  final int count;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final radius = 14.r;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        // AnimatedContainer is implicit + layout-only (no extra render
        // passes, no packages), so it stays smooth even on low-end
        // devices. Border brightens slightly on expand as a subtle cue.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: AppColors.goldCard,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: expanded
                  ? AppColors.gold.withValues(alpha: 0.55)
                  : AppColors.goldBorder,
              width: 1,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon in a soft circular backdrop so it doesn't visually
              // compete with the text block next to it.
              Container(
                width: 30.r,
                height: 30.r,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pause_circle_outline_rounded,
                  size: 16.r,
                  color: AppColors.gold,
                ),
              ),
              SizedBox(width: 10.w),

              // Title + tap hint, stacked so the title stays a normal
              // reading size instead of stretching to fill the row.
              // AnimatedSize handles the height change when the title
              // goes from 1 line (collapsed) to full text (expanded) —
              // it's a clip + layout animation, no rebuild overhead,
              // and is cheap enough for low-end devices.
              Expanded(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  alignment: Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.inactiveSpecialTimeExcusedSection,
                        maxLines: expanded ? null : 1,
                        overflow: expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldLight,
                          height: 1.2,
                        ),
                      ),
                      if (!expanded) ...[
                        SizedBox(height: 2.h),
                        Text(
                          'দেখতে ট্যাপ করুন',
                          style: AppTextStyles.bodySmall(context).copyWith(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColors.goldLight.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              SizedBox(width: 8.w),
              _CountBadge(count: count, locale: locale),
              SizedBox(width: 4.w),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18.r,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.locale});

  final int count;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final label = locale == 'bn' ? toBengaliNumeral(count) : '$count';

    return Container(
      constraints: BoxConstraints(minWidth: 20.r),
      height: 20.r,
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.pill(context).copyWith(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.goldPale,
          height: 1,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/constants/amal_fields.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/tap_target.dart';
import '../../features/admin/presentation/widgets/admin_amal_field_helpers.dart';
import 'amal_numeric_picker.dart';
import 'card_container.dart';

/// Icon mapping for amal fields.
/// Uses FontAwesome for culturally appropriate Islamic icons.
Widget amalFieldIconWidget(String id, {Color? color, double? size}) {
  switch (id) {
    case 'fard_salah':
      return FaIcon(FontAwesomeIcons.mosque, color: color, size: size);
    case 'fard':
      return FaIcon(FontAwesomeIcons.peopleGroup, color: color, size: size);
    case 'takbir':
      return FaIcon(FontAwesomeIcons.handsPraying, color: color, size: size);
    case 'morning_azkar':
      return FaIcon(FontAwesomeIcons.cloudSun, color: color, size: size);
    case 'evening_azkar':
      return FaIcon(FontAwesomeIcons.moon, color: color, size: size);
    case 'quran':
      return FaIcon(FontAwesomeIcons.bookOpen, color: color, size: size);
    case 'mulk':
      return FaIcon(FontAwesomeIcons.starAndCrescent, color: color, size: size);
    case 'miswak':
      return FaIcon(FontAwesomeIcons.wandMagic, color: color, size: size);
    case 'sunnah':
      return FaIcon(FontAwesomeIcons.repeat, color: color, size: size);
    case 'post_azkar':
      return FaIcon(FontAwesomeIcons.checkDouble, color: color, size: size);
    default:
      return Icon(Icons.check_circle_outline, color: color, size: size);
  }
}

/// Whether the field uses a custom asset icon (e.g. SVG/PNG) instead of FontAwesome.
bool amalFieldHasCustomIcon(String id) => false;

/// Path to custom asset icon for fields that need SVG/PNG.
String? amalFieldCustomIconPath(String id) => null;

class AmalRow extends StatelessWidget {
  final AmalField field;
  final bool done;
  final int? numericValue;
  final String locale;
  final ValueChanged<bool>? onChanged;
  final ValueChanged<int>? onNumericChanged;
  final VoidCallback? onTapDetails;
  final bool readOnly;

  /// When set, caps numeric picker options (e.g. takbir max = fard).
  final int? numericPickerMax;

  /// Whether this row supports the inline expandable section. When true the
  /// numeric picker tap toggles [expandedContent] instead of opening its
  /// value overlay.
  final bool expandable;

  /// Whether the expandable section is currently open.
  final bool isExpanded;

  /// Invoked when the picker is tapped to open/close the section.
  final VoidCallback? onToggleExpand;

  /// Content revealed below the main row when [isExpanded] is true
  /// (e.g. the prayer-circle row).
  final Widget? expandedContent;

  const AmalRow({
    super.key,
    required this.field,
    required this.done,
    this.locale = 'bn',
    this.numericValue,
    this.onChanged,
    this.onNumericChanged,
    this.onTapDetails,
    this.readOnly = false,
    this.numericPickerMax,
    this.expandable = false,
    this.isExpanded = false,
    this.onToggleExpand,
    this.expandedContent,
  });

  @override
  Widget build(BuildContext context) {
    final isNumeric = field.type == AmalType.numeric;
    final pickerMax = numericPickerMax ?? field.maxValue;
    final currentNumeric = (numericValue ?? 0).clamp(0, pickerMax);
    final earnedPoints = isNumeric
        ? ((currentNumeric / field.maxValue) * field.points).round()
        : (done ? field.points : 0);

    final detailsContent = Row(
      children: [
        Container(
          width: 36.r,
          height: 36.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done ? AppColors.gold : AppColors.cardBorder,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: AmalFieldIcon(
            fieldId: field.id,
            color: done ? AppColors.emeraldDeep : AppColors.textSecondary,
            size: 18.r,
            field: field,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                field.getLabel(locale),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge(
                  context,
                ).copyWith(fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      field.getSublabel(locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall(
                        context,
                      ).copyWith(fontSize: 11.sp),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    width: 3.r,
                    height: 3.r,
                    decoration: const BoxDecoration(
                      color: AppColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '+$earnedPoints/${field.points} pts',
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontSize: 11.sp,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final mainRow = Row(
      children: [
        Expanded(
          child: onTapDetails == null
              ? detailsContent
              : HitSlopWrapper(
                  onTap: onTapDetails!,
                  hitSlop: amalControlHitSlop(),
                  child: IgnorePointer(child: detailsContent),
                ),
        ),
        SizedBox(width: 8.w),
        if (isNumeric)
          AmalNumericPicker(
            currentValue: currentNumeric,
            maxValue: pickerMax,
            fieldMaxValue: field.maxValue,
            readOnly: readOnly,
            onChanged: onNumericChanged,
            onTapOverride: expandable ? onToggleExpand : null,
            isExpanded: isExpanded,
          )
        else if (readOnly)
          SizedBox(
            width: 48.w,
            height: 48.h,
            child: Center(
              child: Icon(
                done ? Icons.check_circle : Icons.cancel_outlined,
                color: done ? AppColors.success : AppColors.danger,
                size: 22.r,
              ),
            ),
          )
        else
          SizedBox(
            width: 48.w,
            height: 48.h,
            child: Center(
              child: Switch.adaptive(
                value: done,
                onChanged: onChanged,
                activeThumbColor: AppColors.emeraldDeep,
                activeTrackColor: AppColors.gold,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
      ],
    );

    return CardContainer(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      color: done ? AppColors.goldCard : AppColors.cardDark,
      borderColor: done ? AppColors.goldBorder : AppColors.cardBorder,
      child: expandable
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                mainRow,
                // Smoothly grow/shrink the prayer-circle section. Using an
                // AnimatedSize keeps a single cheap layout animation that
                // performs well even on low-end devices, while a full-width
                // collapsed placeholder prevents any horizontal jump.
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.hardEdge,
                  child: isExpanded && expandedContent != null
                      ? SizedBox(width: double.infinity, child: expandedContent)
                      : const SizedBox(width: double.infinity),
                ),
              ],
            )
          : mainRow,
    );
  }
}

/// Widget that renders either a FontAwesome icon or a custom asset image.
/// Use this instead of `Icon(amalFieldIcon(...))` to support custom assets like miswak.
class AmalFieldIcon extends StatelessWidget {
  const AmalFieldIcon({
    super.key,
    required this.fieldId,
    required this.color,
    required this.size,
    this.field,
  });

  final String fieldId;
  final Color color;
  final double size;
  final AmalField? field;

  @override
  Widget build(BuildContext context) {
    if (amalFieldHasCustomIcon(fieldId)) {
      final assetPath = amalFieldCustomIconPath(fieldId);
      if (assetPath != null) {
        return Image.asset(
          assetPath,
          width: size,
          height: size,
          color: color,
          errorBuilder: (_, __, ___) => _buildIcon(),
        );
      }
    }
    return _buildIcon();
  }

  Widget _buildIcon() {
    // Try stored icon from field first
    if (field != null) {
      final resolved = resolveIconFromField(field!);
      if (resolved != null) {
        return Icon(resolved, color: color, size: size);
      }
    }
    // Fall back to hardcoded switch
    return amalFieldIconWidget(fieldId, color: color, size: size);
  }
}

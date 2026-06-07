import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

final kAmalFieldIdPattern = RegExp(r'^[a-z][a-z0-9_]*$');

String normalizeAmalFieldType(AmalType? type) =>
    type == AmalType.numeric ? 'numeric' : 'boolean';

AmalType parseAmalFieldType(String value) =>
    value == 'numeric' ? AmalType.numeric : AmalType.boolean;

bool isValidAmalFieldId(String id) =>
    id.isNotEmpty && kAmalFieldIdPattern.hasMatch(id);

Map<String, String> buildLocaleMap({required String en, String? bn}) {
  final map = <String, String>{'en': en.trim()};
  final bnTrimmed = bn?.trim();
  if (bnTrimmed != null && bnTrimmed.isNotEmpty) {
    map['bn'] = bnTrimmed;
  }
  return map;
}

/*
Purpose:
Build Firestore payload for create/update from admin form values.

Response:
Map ready for AmalFieldsService create/update.

Business Rules:
English label required; id only included on create; maxValue >= 1 for numeric.

Validation logic:
Caller validates id/labels/points before invoking.

Failure Cases:
Returns structurally valid map; invalid input should be caught by form validators.
*/
Map<String, dynamic> amalFieldToFirestoreMap({
  required String labelEn,
  String? labelBn,
  required String sublabelEn,
  String? sublabelBn,
  required AmalType type,
  required int points,
  required int maxValue,
  required int order,
  required bool isActive,
  String? id,
}) {
  final map = <String, dynamic>{
    'label': buildLocaleMap(en: labelEn, bn: labelBn),
    'sublabel': buildLocaleMap(en: sublabelEn, bn: sublabelBn),
    'points': points,
    'maxValue': type == AmalType.numeric ? maxValue : 1,
    'type': type == AmalType.numeric ? 'numeric' : 'boolean',
    'order': order,
    'isActive': isActive,
  };
  if (id != null) map['id'] = id.trim();
  return map;
}

AmalField buildDraftAmalField({
  required String id,
  required String labelEn,
  String? labelBn,
  required String sublabelEn,
  String? sublabelBn,
  required AmalType type,
  required int points,
  required int maxValue,
  required int order,
  required bool isActive,
}) {
  return AmalField(
    id: id.trim().isEmpty ? 'preview' : id.trim(),
    label: buildLocaleMap(en: labelEn, bn: labelBn),
    sublabel: buildLocaleMap(en: sublabelEn, bn: sublabelBn),
    points: points,
    maxValue: type == AmalType.numeric ? maxValue : 1,
    type: type,
    order: order,
    isActive: isActive,
  );
}

String? validateAmalFieldId(String? value, AppLocalizations l10n) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return l10n.adminAmalFieldIdRequired;
  if (!isValidAmalFieldId(trimmed)) return l10n.adminAmalFieldIdInvalid;
  return null;
}

String? validateRequiredLabel(String? value, AppLocalizations l10n) {
  if (value == null || value.trim().isEmpty) {
    return l10n.adminAmalFieldLabelRequired;
  }
  return null;
}

String? validatePoints(String? value, AppLocalizations l10n) {
  final parsed = int.tryParse(value?.trim() ?? '');
  if (parsed == null || parsed < 0 || parsed > 100) {
    return l10n.adminAmalFieldPointsInvalid;
  }
  return null;
}

String? validateMaxValue(String? value, AppLocalizations l10n) {
  final parsed = int.tryParse(value?.trim() ?? '');
  if (parsed == null || parsed < 1) return l10n.adminAmalFieldMaxValueInvalid;
  return null;
}

String? validateOrder(String? value, AppLocalizations l10n) {
  final parsed = int.tryParse(value?.trim() ?? '');
  if (parsed == null || parsed < 0) return l10n.adminAmalFieldOrderInvalid;
  return null;
}

String typeLabel(AppLocalizations l10n, AmalType type) {
  return type == AmalType.numeric
      ? l10n.adminAmalFieldTypeNumeric
      : l10n.adminAmalFieldTypeBoolean;
}

String amalFieldLocaleCode(BuildContext context) {
  return Localizations.localeOf(context).languageCode;
}

String amalFieldTileSubtitle(AppLocalizations l10n, AmalField field) {
  return l10n.adminAmalFieldTileSubtitle(
    field.id,
    typeLabel(l10n, field.type),
    l10n.pointsValue(field.points),
    field.order,
  );
}

IconData iconForAmalType(AmalType type) {
  return type == AmalType.numeric
      ? Icons.pin_outlined
      : Icons.toggle_on_outlined;
}

class AdminAmalTypeSelector extends StatelessWidget {
  const AdminAmalTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AmalType selected;
  final ValueChanged<AmalType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: AmalType.values.map((type) {
        final isSelected = selected == type;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: type == AmalType.boolean ? 8.w : 0,
            ),
            child: InkWell(
              onTap: () => onChanged(type),
              borderRadius: BorderRadius.circular(99.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.goldCard : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(99.r),
                  border: Border.all(
                    color: isSelected ? AppColors.gold : AppColors.cardBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      iconForAmalType(type),
                      size: 14.r,
                      color: isSelected ? AppColors.gold : AppColors.textMuted,
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        typeLabel(l10n, type),
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.pill(context).copyWith(
                          color: isSelected
                              ? AppColors.gold
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

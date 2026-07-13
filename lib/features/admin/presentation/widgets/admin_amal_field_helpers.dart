import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  String? iconName,
  IconSource? iconSource,
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
  if (iconName != null && iconName.isNotEmpty) map['iconName'] = iconName;
  if (iconSource != null) {
    map['iconSource'] = iconSource == IconSource.material ? 'material' : 'fontAwesome';
  } else if (iconName == null || iconName.isEmpty) {
    // Explicitly clear icon fields when no icon is selected
    map['iconName'] = null;
    map['iconSource'] = null;
  }
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
  String? iconName,
  IconSource? iconSource,
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
    iconName: iconName,
    iconSource: iconSource,
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

// --- Icon resolution maps ---

final Map<String, IconData> kFontAwesomeIconMap = {
  'fa_mosque': FontAwesomeIcons.mosque.data,
  'fa_hands_praying': FontAwesomeIcons.handsPraying.data,
  'fa_book_open': FontAwesomeIcons.bookOpen.data,
  'fa_moon': FontAwesomeIcons.moon.data,
  'fa_star_and_crescent': FontAwesomeIcons.starAndCrescent.data,
  'fa_cloud_sun': FontAwesomeIcons.cloudSun.data,
  'fa_people_group': FontAwesomeIcons.peopleGroup.data,
  'fa_wand_magic': FontAwesomeIcons.wandMagic.data,
  'fa_repeat': FontAwesomeIcons.repeat.data,
  'fa_check_double': FontAwesomeIcons.checkDouble.data,
  'fa_headphones': FontAwesomeIcons.headphones.data,
  'fa_person_walking': FontAwesomeIcons.personWalking.data,
  'fa_dove': FontAwesomeIcons.dove.data,
  'fa_spa': FontAwesomeIcons.spa.data,
  'fa_book_quran': FontAwesomeIcons.bookQuran.data,
  'fa_water': FontAwesomeIcons.water.data,
  'fa_seedling': FontAwesomeIcons.seedling.data,
  'fa_heart': FontAwesomeIcons.heart.data,
  'fa_clock': FontAwesomeIcons.clock.data,
  'fa_hand_holding_heart': FontAwesomeIcons.handHoldingHeart.data,
};

const Map<String, IconData> kMaterialIconMap = {
  'mi_star': Icons.star,
  'mi_favorite': Icons.favorite,
  'mi_book': Icons.book,
  'mi_nights_stay': Icons.nights_stay,
  'mi_wb_sunny': Icons.wb_sunny,
  'mi_self_improvement': Icons.self_improvement,
  'mi_spa': Icons.spa,
  'mi_water_drop': Icons.water_drop,
  'mi_eco': Icons.eco,
  'mi_access_time': Icons.access_time,
  'mi_check_circle': Icons.check_circle,
  'mi_volunteer_activism': Icons.volunteer_activism,
  'mi_menu_book': Icons.menu_book,
  'mi_light_mode': Icons.light_mode,
  'mi_dark_mode': Icons.dark_mode,
  'mi_auto_awesome': Icons.auto_awesome,
  'mi_psychology': Icons.psychology,
  'mi_sunny': Icons.sunny,
  'mi_wb_twilight': Icons.wb_twilight,
  'mi_self_improvement_2': Icons.self_improvement,
};

IconData? resolveIconFromFieldName(String iconName, IconSource source) {
  if (source == IconSource.material) {
    return kMaterialIconMap[iconName];
  }
  return kFontAwesomeIconMap[iconName];
}

IconData? resolveIconFromField(AmalField field) {
  if (field.iconName != null && field.iconSource != null) {
    return resolveIconFromFieldName(field.iconName!, field.iconSource!);
  }
  return null;
}

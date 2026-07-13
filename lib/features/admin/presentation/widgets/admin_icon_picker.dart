import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

class AdminIconPicker extends StatelessWidget {
  const AdminIconPicker({
    super.key,
    required this.selectedSource,
    required this.selectedIconName,
    required this.onSourceChanged,
    required this.onIconChanged,
  });

  final IconSource selectedSource;
  final String? selectedIconName;
  final ValueChanged<IconSource> onSourceChanged;
  final ValueChanged<String?> onIconChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Source chip selector
        Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Row(
            children: [
              Expanded(
                child: _SourceChip(
                  label: l10n.adminAmalFieldIconSourceFa,
                  iconWidget: FaIcon(
                    FontAwesomeIcons.starAndCrescent,
                    size: 14.r,
                  ),
                  isSelected: selectedSource == IconSource.fontAwesome,
                  onTap: () => onSourceChanged(IconSource.fontAwesome),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _SourceChip(
                  label: l10n.adminAmalFieldIconSourceMaterial,
                  iconWidget: Icon(Icons.star_outline, size: 14.r),
                  isSelected: selectedSource == IconSource.material,
                  onTap: () => onSourceChanged(IconSource.material),
                ),
              ),
            ],
          ),
        ),
        // Clear button
        if (selectedIconName != null)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: GestureDetector(
              onTap: () => onIconChanged(null),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(99.r),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 14.r, color: AppColors.textMuted),
                    SizedBox(width: 6.w),
                    Text(
                      l10n.adminAmalFieldIconClear,
                      style: AppTextStyles.pill(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Icon grid
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _iconEntries(selectedSource).map((entry) {
            final isSelected = selectedIconName == entry.name;
            return GestureDetector(
              onTap: () => onIconChanged(entry.name),
              child: Container(
                width: 72.r,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.goldCard : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? AppColors.gold : AppColors.cardBorder,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    entry.buildIcon(
                      size: 20.r,
                      color: isSelected ? AppColors.gold : AppColors.textSecondary,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      entry.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall(context).copyWith(
                        fontSize: 9.sp,
                        color: isSelected ? AppColors.gold : AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<_IconEntry> _iconEntries(IconSource source) {
    if (source == IconSource.fontAwesome) {
      return _faEntries;
    }
    return _miEntries;
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.label,
    required this.iconWidget,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Widget iconWidget;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
            IconTheme(
              data: IconThemeData(
                size: 14.r,
                color: isSelected ? AppColors.gold : AppColors.textMuted,
              ),
              child: iconWidget,
            ),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.pill(context).copyWith(
                  color: isSelected ? AppColors.gold : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Icon entries ---

abstract class _IconEntry {
  const _IconEntry(this.name, this.label);
  final String name;
  final String label;
  Widget buildIcon({required double size, required Color color});
}

class _FaIconEntry extends _IconEntry {
  const _FaIconEntry(super.name, this._faIcon, super.label);
  final FaIconData _faIcon;

  @override
  Widget buildIcon({required double size, required Color color}) {
    return FaIcon(_faIcon, size: size, color: color);
  }
}

class _MiIconEntry extends _IconEntry {
  const _MiIconEntry(super.name, this._iconData, super.label);
  final IconData _iconData;

  @override
  Widget buildIcon({required double size, required Color color}) {
    return Icon(_iconData, size: size, color: color);
  }
}

final _faEntries = <_IconEntry>[
  _FaIconEntry('fa_mosque', FontAwesomeIcons.mosque, 'Mosque'),
  _FaIconEntry('fa_hands_praying', FontAwesomeIcons.handsPraying, 'Praying'),
  _FaIconEntry('fa_book_open', FontAwesomeIcons.bookOpen, 'Book'),
  _FaIconEntry('fa_book_quran', FontAwesomeIcons.bookQuran, 'Quran'),
  _FaIconEntry('fa_moon', FontAwesomeIcons.moon, 'Moon'),
  _FaIconEntry('fa_star_and_crescent', FontAwesomeIcons.starAndCrescent, 'Star'),
  _FaIconEntry('fa_cloud_sun', FontAwesomeIcons.cloudSun, 'Cloud Sun'),
  _FaIconEntry('fa_people_group', FontAwesomeIcons.peopleGroup, 'Group'),
  _FaIconEntry('fa_wand_magic', FontAwesomeIcons.wandMagic, 'Magic'),
  _FaIconEntry('fa_repeat', FontAwesomeIcons.repeat, 'Repeat'),
  _FaIconEntry('fa_check_double', FontAwesomeIcons.checkDouble, 'Double Check'),
  _FaIconEntry('fa_headphones', FontAwesomeIcons.headphones, 'Headphones'),
  _FaIconEntry('fa_person_walking', FontAwesomeIcons.personWalking, 'Walking'),
  _FaIconEntry('fa_dove', FontAwesomeIcons.dove, 'Dove'),
  _FaIconEntry('fa_spa', FontAwesomeIcons.spa, 'Spa'),
  _FaIconEntry('fa_water', FontAwesomeIcons.water, 'Water'),
  _FaIconEntry('fa_seedling', FontAwesomeIcons.seedling, 'Seedling'),
  _FaIconEntry('fa_heart', FontAwesomeIcons.heart, 'Heart'),
  _FaIconEntry('fa_clock', FontAwesomeIcons.clock, 'Clock'),
  _FaIconEntry('fa_hand_holding_heart', FontAwesomeIcons.handHoldingHeart, 'Charity'),
];

const _miEntries = <_IconEntry>[
  _MiIconEntry('mi_star', Icons.star, 'Star'),
  _MiIconEntry('mi_favorite', Icons.favorite, 'Favorite'),
  _MiIconEntry('mi_book', Icons.book, 'Book'),
  _MiIconEntry('mi_menu_book', Icons.menu_book, 'Menu Book'),
  _MiIconEntry('mi_nights_stay', Icons.nights_stay, 'Night'),
  _MiIconEntry('mi_wb_sunny', Icons.wb_sunny, 'Sunny'),
  _MiIconEntry('mi_self_improvement', Icons.self_improvement, 'Meditate'),
  _MiIconEntry('mi_spa', Icons.spa, 'Spa'),
  _MiIconEntry('mi_water_drop', Icons.water_drop, 'Water'),
  _MiIconEntry('mi_eco', Icons.eco, 'Eco'),
  _MiIconEntry('mi_access_time', Icons.access_time, 'Time'),
  _MiIconEntry('mi_check_circle', Icons.check_circle, 'Check'),
  _MiIconEntry('mi_volunteer_activism', Icons.volunteer_activism, 'Volunteer'),
  _MiIconEntry('mi_light_mode', Icons.light_mode, 'Light'),
  _MiIconEntry('mi_dark_mode', Icons.dark_mode, 'Dark'),
  _MiIconEntry('mi_auto_awesome', Icons.auto_awesome, 'Awesome'),
  _MiIconEntry('mi_psychology', Icons.psychology, 'Mind'),
  _MiIconEntry('mi_sunny', Icons.sunny, 'Sun'),
  _MiIconEntry('mi_wb_twilight', Icons.wb_twilight, 'Twilight'),
  _MiIconEntry('mi_self_improvement_2', Icons.self_improvement, 'Peace'),
];

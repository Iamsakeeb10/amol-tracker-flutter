import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/services/islamic_date_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// A horizontal row of prayer circles for an expandable numeric amal field.
///
/// Each circle represents one of the five daily prayers and can be toggled on
/// and off independently. On Fridays the second slot (Dhuhr) is relabelled as
/// Jummah. The persisted field value stays a simple count (number of lit
/// circles); the specific lit positions are tracked separately by the caller.
class FardPrayerExpandRow extends StatelessWidget {
  const FardPrayerExpandRow({
    super.key,
    required this.selectedIndices,
    required this.onToggleIndex,
    this.slotCount = 5,
    this.readOnly = false,
  });

  /// Indices (0-based) of the currently lit prayer circles.
  final Set<int> selectedIndices;

  /// Called with the tapped circle index; the caller flips that prayer.
  final ValueChanged<int> onToggleIndex;

  /// Number of prayer circles to render (capped at the five daily prayers).
  final int slotCount;
  final bool readOnly;

  /// Extra invisible tap area added around each circle on every side.
  static const double _hitSlop = 10;

  /// Canonical prayer keys in daily order.
  static const List<String> _prayerKeys = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  /// Material icons per prayer slot (Jummah reuses a mosque glyph).
  static const Map<String, IconData> _prayerIcons = {
    'fajr': Icons.wb_twilight,
    'dhuhr': Icons.wb_sunny_outlined,
    'jummah': Icons.mosque_outlined,
    'asr': Icons.wb_cloudy_outlined,
    'maghrib': Icons.nights_stay_outlined,
    'isha': Icons.dark_mode_outlined,
  };

  String _prayerName(AppLocalizations l10n, String key) {
    switch (key) {
      case 'fajr':
        return l10n.prayerFajr;
      case 'dhuhr':
        return l10n.prayerDhuhr;
      case 'jummah':
        return l10n.prayerJummah;
      case 'asr':
        return l10n.prayerAsr;
      case 'maghrib':
        return l10n.prayerMaghrib;
      case 'isha':
        return l10n.prayerIsha;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFriday = IslamicDateService.isCurrentPrayerDayFriday();
    final slots = slotCount.clamp(1, _prayerKeys.length);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, thickness: 0.8, color: AppColors.cardBorder),
        Padding(
          padding: EdgeInsets.fromLTRB(0.w, 10.h, 0.w, 0.h),
          child: Row(
            children: List.generate(slots, (index) {
              final key = index == 1 && isFriday
                  ? 'jummah'
                  : _prayerKeys[index];
              final isChecked = selectedIndices.contains(index);
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isChecked,
                  label: _prayerName(l10n, key),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      _PrayerCircle(
                        isChecked: isChecked,
                        icon: _prayerIcons[key] ?? Icons.check,
                        label: _prayerName(l10n, key),
                      ),
                      Positioned.fill(
                        left: -_hitSlop.w,
                        right: -_hitSlop.w,
                        top: -_hitSlop.h,
                        bottom: -_hitSlop.h,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: readOnly ? null : () => onToggleIndex(index),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _PrayerCircle extends StatelessWidget {
  const _PrayerCircle({
    required this.isChecked,
    required this.icon,
    required this.label,
  });

  final bool isChecked;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 36.r,
          height: 36.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isChecked ? AppColors.gold : Colors.transparent,
            border: Border.all(
              color: isChecked ? AppColors.gold : AppColors.cardBorder,
              width: 1.5,
            ),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isChecked
                  ? Icon(
                      Icons.check,
                      key: const ValueKey(true),
                      color: AppColors.emeraldDeep,
                      size: 18.r,
                    )
                  : Icon(
                      icon,
                      key: const ValueKey(false),
                      color: AppColors.textMuted,
                      size: 14.r,
                    ),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: AppTextStyles.bodySmall(context).copyWith(
            fontSize: 9.sp,
            color: isChecked ? AppColors.gold : AppColors.textMuted,
            fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/prayer_analytics.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/amal_log_model.dart';
import '../../../../shared/widgets/card_container.dart';
const Map<String, Map<String, String>> _prayerTranslations = {
  'fajr': {'en': 'Fajr', 'bn': 'ফজর'},
  'dhuhr': {'en': 'Dhuhr', 'bn': 'যোহর'},
  'asr': {'en': 'Asr', 'bn': 'আসর'},
  'maghrib': {'en': 'Maghrib', 'bn': 'মাগরিব'},
  'isha': {'en': 'Isha', 'bn': 'এশা'},
};

class ReportPrayerBreakdownSection extends StatelessWidget {
  const ReportPrayerBreakdownSection({
    super.key,
    required this.logs,
    required this.fields,
    this.compact = false,
  });

  final List<AmalLogModel> logs;
  final List<AmalField> fields;
  /// If true, uses a slightly smaller layout for profile screens.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final expandableFields = fields.where((f) => f.supportsExpansion).toList();

    // Only show fields that have at least one log with prayer data
    final activeFields = expandableFields
        .where((f) => PrayerAnalytics.hasPrayerData(logs, f.id))
        .toList();

    if (activeFields.isEmpty) {
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return const SizedBox.shrink();
      return CardContainer(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mosque_outlined,
                  size: 40.r,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 12.h),
                Text(
                  l10n.reportsPrayerEmptyTitle,
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  l10n.reportsPrayerEmptyMessage,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return CardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < activeFields.length; i++) ...[
                _PrayerFieldStats(
                  field: activeFields[i],
                  logs: logs,
                  locale: locale,
                  compact: compact,
                ),
                if (i != activeFields.length - 1)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: compact ? 8.h : 12.h),
                    child: const Divider(height: 1, color: AppColors.cardBorder),
                  ),
              ],
            ],
          ),
        );
  }
}

class _PrayerFieldStats extends StatelessWidget {
  const _PrayerFieldStats({
    required this.field,
    required this.logs,
    required this.locale,
    required this.compact,
  });

  final AmalField field;
  final List<AmalLogModel> logs;
  final String locale;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final stats = PrayerAnalytics.compute(
      logs: logs,
      fieldId: field.id,
      slotCount: field.maxValue,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.getLabel(locale),
          style: AppTextStyles.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: compact ? 6.h : 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(stats.length, (index) {
            final stat = stats[index];
            return _PrayerCircleStat(
              prayerKey: stat.prayerKey,
              rate: stat.rate,
              doneCount: stat.doneCount,
              eligibleDays: stat.eligibleDays,
              locale: locale,
              compact: compact,
            );
          }),
        ),
      ],
    );
  }
}

class _PrayerCircleStat extends StatelessWidget {
  const _PrayerCircleStat({
    required this.prayerKey,
    required this.rate,
    required this.doneCount,
    required this.eligibleDays,
    required this.locale,
    required this.compact,
  });

  final String prayerKey;
  final double rate;
  final int doneCount;
  final int eligibleDays;
  final String locale;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final translationMap = _prayerTranslations[prayerKey] ?? {};
    final prayerName = translationMap[locale] ?? prayerKey;

    final Color color;
    if (rate >= 0.8) {
      color = AppColors.success;
    } else if (rate >= 0.5) {
      color = AppColors.gold;
    } else if (rate > 0) {
      color = AppColors.warning;
    } else {
      color = AppColors.cardBorder;
    }

    final double circleSize = compact ? 36.r : 44.r;

    return Column(
      children: [
        Tooltip(
          message: '$doneCount / $eligibleDays days',
          child: SizedBox(
            width: circleSize,
            height: circleSize,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: compact ? 3.r : 4.r,
                  color: AppColors.cardBorder,
                ),
                CircularProgressIndicator(
                  value: rate,
                  strokeWidth: compact ? 3.r : 4.r,
                  backgroundColor: Colors.transparent,
                  color: rate == 0 ? Colors.transparent : color,
                ),
                Center(
                  child: Text(
                    '${(rate * 100).round()}%',
                    style: AppTextStyles.label(context).copyWith(
                      fontSize: compact ? 9.sp : 11.sp,
                      fontWeight: FontWeight.bold,
                      color: rate == 0 ? AppColors.textMuted : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          prayerName,
          style: AppTextStyles.label(context).copyWith(
            fontSize: compact ? 9.sp : 10.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

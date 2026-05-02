import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/streak_badge.dart';

class DayCompleteScreen extends StatelessWidget {
  const DayCompleteScreen({super.key});

  int get _totalEarned =>
      kTodayAmalEntries.fold<int>(0, (s, e) => s + e.earnedPoints);

  @override
  Widget build(BuildContext context) {
    final earned = _totalEarned;
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 28),
        children: [
          const SizedBox(height: 8),
          Center(child: _ScoreRing(score: earned)),
          const SizedBox(height: 18),
          Text(
            "Alhamdulillah",
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMedium,
          ),
          const SizedBox(height: 4),
          Text(
            "You completed today's amal.",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          Center(child: Pill(text: '+$earned pts earned', icon: Icons.bolt)),
          const SizedBox(height: 22),
          CardContainer(
            color: AppColors.goldCard,
            borderColor: AppColors.goldBorder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.format_quote,
                      color: AppColors.goldLight,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'HADITH OF THE DAY',
                      style: AppTextStyles.label.copyWith(color: AppColors.gold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(kHadiths[0], style: AppTextStyles.bodyLarge),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text("Today's summary", style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          ...kTodayAmalEntries.map((entry) {
            final field = kAmalFields.firstWhere(
              (f) => f.id == entry.fieldId,
              orElse: () => kAmalFields.first,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SummaryRow(field: field, entry: entry),
            );
          }),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.emeraldDeep,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Back to home',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.emeraldDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int score;
  const _ScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 10,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              backgroundColor: AppColors.cardBorder,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: AppTextStyles.displayLarge.copyWith(
                  color: AppColors.goldLight,
                  fontSize: 56,
                ),
              ),
              Text(
                'of 100',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final AmalField field;
  final MockAmalEntry entry;

  const _SummaryRow({required this.field, required this.entry});

  @override
  Widget build(BuildContext context) {
    final partial =
        !entry.done && entry.value != null && entry.value! > 0;
    Color iconColor;
    IconData iconData;

    if (entry.done) {
      iconColor = AppColors.success;
      iconData = Icons.check_circle;
    } else if (partial) {
      iconColor = AppColors.warning;
      iconData = Icons.adjust;
    } else {
      iconColor = AppColors.danger;
      iconData = Icons.cancel_outlined;
    }

    return CardContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(iconData, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              field.label,
              style: AppTextStyles.bodyLarge.copyWith(fontSize: 14),
            ),
          ),
          Text(
            '${entry.earnedPoints} pts',
            style: AppTextStyles.pill.copyWith(
              color: entry.earnedPoints > 0
                  ? AppColors.gold
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

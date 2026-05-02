import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/stat_card.dart';

class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final score = kTodayAmalEntries.fold<int>(
      0,
      (s, e) => s + e.earnedPoints,
    );
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/history'),
        ),
        title: Text('14 Shawwal 1447', style: AppTextStyles.headlineMedium),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  'READ-ONLY',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
        children: [
          Text(
            'Tuesday',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Score',
                  value: '$score',
                  sublabel: 'of 100',
                  icon: Icons.workspace_premium_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Streak that day',
                  value: '14',
                  sublabel: 'days',
                  icon: Icons.local_fire_department_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text("Amal", style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          ...kTodayAmalEntries.map((entry) {
            final field = kAmalFields.firstWhere(
              (f) => f.id == entry.fieldId,
              orElse: () => kAmalFields.first,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AmalRow(
                field: field,
                done: entry.done,
                numericValue: entry.value,
                readOnly: true,
              ),
            );
          }),
          const SizedBox(height: 14),
          CardContainer(
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: AppColors.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Past days are locked. Stay consistent today.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

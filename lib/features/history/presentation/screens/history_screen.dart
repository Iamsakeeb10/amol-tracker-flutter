import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/calendar_day_cell.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/stat_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final days = buildMockMonth();
    final completed =
        days.where((d) => d.state == DayCompletion.full).length;
    final consistency = ((completed / days.length) * 100).round();
    return AppScaffold(
      padding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HISTORY',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Shawwal 1447', style: AppTextStyles.displayMedium),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.chevron_left,
                  color: AppColors.textSecondary,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$consistency% consistency',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Completed',
                  value: '$completed',
                  sublabel: 'of ${days.length} days',
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Best streak',
                  value: '${kCurrentUser.bestStreak}',
                  sublabel: 'days',
                  icon: Icons.local_fire_department_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DayLabels(),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: days.length,
            itemBuilder: (_, i) => CalendarDayCell(
              day: days[i],
              onTap: () => context.push(AppRoutes.dayDetail),
            ),
          ),
          const SizedBox(height: 12),
          const _Legend(),
          const SizedBox(height: 16),
          CardContainer.gold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INSIGHT',
                  style: AppTextStyles.label.copyWith(color: AppColors.gold),
                ),
                const SizedBox(height: 6),
                Text(kHadiths[1], style: AppTextStyles.bodyLarge),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CardContainer(
            color: AppColors.dangerLight,
            borderColor: AppColors.danger.withValues(alpha: 0.3),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_outlined,
                  color: AppColors.danger,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weakest amal',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Evening Azkar — missed 8 days this month',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                      ),
                    ],
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

class _DayLabels extends StatelessWidget {
  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  @override
  Widget build(BuildContext context) {
    return Row(
      children: _labels
          .map(
            (l) => Expanded(
              child: Text(
                l,
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();
  Widget _dot(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(AppColors.gold),
        const SizedBox(width: 6),
        Text('Full', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
        const SizedBox(width: 12),
        _dot(AppColors.warning),
        const SizedBox(width: 6),
        Text('Partial', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
        const SizedBox(width: 12),
        _dot(AppColors.danger),
        const SizedBox(width: 6),
        Text('Miss', style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
      ],
    );
  }
}

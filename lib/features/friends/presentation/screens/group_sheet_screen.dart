import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';
import '../../../../shared/widgets/streak_badge.dart';

class GroupSheetScreen extends StatefulWidget {
  const GroupSheetScreen({super.key});

  @override
  State<GroupSheetScreen> createState() => _GroupSheetScreenState();
}

class _GroupSheetScreenState extends State<GroupSheetScreen> {
  int _selectedDay = 5;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/friends'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Group Sheet', style: AppTextStyles.headlineMedium),
            Text(
              '${kGroup.name} · Shawwal',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 28),
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 12,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final day = 18 + i;
                final isToday = day == 24;
                final selected = _selectedDay == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = i),
                  child: Container(
                    width: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.gold
                          : isToday
                              ? AppColors.goldCard
                              : AppColors.cardDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.gold
                            : isToday
                                ? AppColors.goldBorder
                                : AppColors.cardBorder,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontSize: 13,
                            color: selected
                                ? AppColors.emeraldDeep
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isToday)
                          Text(
                            'Today',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 9,
                              color: selected
                                  ? AppColors.emeraldDeep
                                  : AppColors.gold,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          CardContainer.gold(
            child: Row(
              children: [
                const Icon(
                  Icons.group,
                  color: AppColors.goldLight,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All ${kGroup.memberCount} active today',
                    style: AppTextStyles.bodyLarge.copyWith(fontSize: 13),
                  ),
                ),
                StreakBadge(days: kGroup.groupStreak, label: 'group streak'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ColumnHeaders(),
          const SizedBox(height: 8),
          ...kGroup.members.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MemberSheetCard(user: m),
              )),
          const SizedBox(height: 12),
          const _Legend(),
          const SizedBox(height: 12),
          CardContainer(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group avg',
                        style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '78',
                        style: AppTextStyles.goldNumeric.copyWith(fontSize: 22),
                      ),
                    ],
                  ),
                ),
                StreakBadge(days: kGroup.groupStreak, label: 'days'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnHeaders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              'MEMBER',
              style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Row(
              children: kAmalFields
                  .map(
                    (f) => Expanded(
                      child: Center(
                        child: Text(
                          kAmalShortLabels[f.id] ?? '?',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 9,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberSheetCard extends StatelessWidget {
  final MockUser user;
  const _MemberSheetCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              AvatarChip(
                initial: user.initial,
                color: user.avatarColor,
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  user.name,
                  style: AppTextStyles.bodyLarge.copyWith(fontSize: 13),
                ),
              ),
              StreakBadge(days: user.currentStreak, compact: true),
              const SizedBox(width: 8),
              Text(
                '${user.todayScore}/100',
                style: AppTextStyles.goldNumeric.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ScoreBar(value: user.todayScore / 100, height: 4),
          const SizedBox(height: 10),
          Row(
            children: [
              for (int i = 0; i < kAmalFields.length; i++)
                Expanded(child: _SheetCell(index: i, user: user)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetCell extends StatelessWidget {
  final int index;
  final MockUser user;
  const _SheetCell({required this.index, required this.user});

  @override
  Widget build(BuildContext context) {
    final field = kAmalFields[index];
    final h = (user.id.hashCode + index) % 5;
    final done = h > 1;
    final isNumeric = field.isNumeric;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: done ? AppColors.successLight : AppColors.dangerLight,
            border: Border.all(
              color: done
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.danger.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: isNumeric
              ? Text(
                  '${(user.id.hashCode + index) % 5 + 1}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    color: done ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Icon(
                  done ? Icons.check : Icons.close,
                  size: 12,
                  color: done ? AppColors.success : AppColors.danger,
                ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          _LegendItem(
            icon: Icons.check,
            color: AppColors.success,
            label: 'Done',
          ),
          _LegendItem(
            icon: Icons.close,
            color: AppColors.danger,
            label: 'Miss',
          ),
          _LegendItem(label: 'N', color: AppColors.gold, isNum: true),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final IconData? icon;
  final Color color;
  final String label;
  final bool isNum;
  const _LegendItem({
    this.icon,
    required this.color,
    required this.label,
    this.isNum = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: isNum
              ? Text(
                  'N',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Icon(icon, size: 10, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          isNum ? 'Numeric (Fard, Takbir)' : label,
          style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

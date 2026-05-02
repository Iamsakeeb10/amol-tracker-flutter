import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/amal_row.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/score_bar.dart';
import '../../../../shared/widgets/streak_freeze_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Map<String, bool> _toggles;

  @override
  void initState() {
    super.initState();
    _toggles = {
      'fard': true,
      'takbir': true,
      'morning_azkar': true,
      'evening_azkar': false,
      'quran': true,
      'mulk': true,
      'miswak': true,
      'sunnah': true,
      'post_azkar': false,
    };
  }

  int get _doneCount => _toggles.values.where((v) => v).length;
  int get _totalScore {
    int s = 0;
    for (final f in kAmalFields) {
      if (_toggles[f.id] == true) s += f.points;
    }
    return s;
  }

  void _markAllDone() {
    setState(() {
      for (final k in _toggles.keys.toList()) {
        _toggles[k] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      padding: EdgeInsets.zero,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        children: [
          _Header(),
          const SizedBox(height: 18),
          _StreakBanner(streak: kCurrentUser.currentStreak),
          const SizedBox(height: 14),
          _ProgressCard(
            done: _doneCount,
            total: _toggles.length,
            score: _totalScore,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text("Today's Amal", style: AppTextStyles.headlineMedium),
              ),
              TextButton(
                onPressed: _markAllDone,
                child: Text(
                  'Mark all',
                  style: AppTextStyles.button.copyWith(color: AppColors.gold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...kAmalFields.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AmalRow(
                  field: f,
                  done: _toggles[f.id] ?? false,
                  onChanged: (v) => setState(() => _toggles[f.id] = v),
                ),
              )),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.dayComplete),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Day complete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.goldBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => StreakFreezeModal.show(context),
                icon: const Icon(Icons.ac_unit, color: AppColors.gold),
                tooltip: 'Streak freeze',
                style: IconButton.styleFrom(
                  side: const BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => context.push(AppRoutes.emptyState),
                icon: const Icon(
                  Icons.hourglass_empty,
                  color: AppColors.textMuted,
                ),
                tooltip: 'Empty state preview',
                style: IconButton.styleFrom(
                  side: const BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '24 Shawwal 1447',
                style: AppTextStyles.label.copyWith(color: AppColors.gold),
              ),
              const SizedBox(height: 2),
              Text('Sunday', style: AppTextStyles.displayMedium),
            ],
          ),
        ),
        const AvatarChip(
          initial: 'Y',
          color: AppColors.gold,
          ring: true,
          size: 38,
          fontSize: 16,
        ),
      ],
    );
  }
}

class _StreakBanner extends StatelessWidget {
  final int streak;
  const _StreakBanner({required this.streak});

  @override
  Widget build(BuildContext context) {
    return CardContainer.gold(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$streak-day streak',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'on fire',
                        style: AppTextStyles.pill.copyWith(
                          color: AppColors.warning,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Best: 41 days · keep it going',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int done;
  final int total;
  final int score;

  const _ProgressCard({
    required this.done,
    required this.total,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Today's progress",
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              Text(
                '$done/$total',
                style: AppTextStyles.goldNumeric.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ScoreBar(value: total == 0 ? 0 : done / total),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                color: AppColors.gold,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '$score / $kMaxDailyScore points',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

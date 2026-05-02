import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import 'card_container.dart';

class StreakFreezeModal extends StatelessWidget {
  final int freezesLeft;
  final int totalFreezes;
  final VoidCallback? onUseFreeze;
  final VoidCallback? onResetStreak;

  const StreakFreezeModal({
    super.key,
    this.freezesLeft = 2,
    this.totalFreezes = 3,
    this.onUseFreeze,
    this.onResetStreak,
  });

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StreakFreezeModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: CardContainer(
          color: AppColors.emeraldMid,
          borderColor: AppColors.goldBorder,
          radius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.ac_unit,
                    color: AppColors.warning,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Streak Freeze',
                  style: AppTextStyles.headlineLarge,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "You missed yesterday. Use a streak freeze to keep your 23-day streak alive — your habit, intact.",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.goldBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.gold,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Freezes left this week',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '$freezesLeft / $totalFreezes',
                      style: AppTextStyles.goldNumeric.copyWith(fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.emeraldDeep,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    onUseFreeze?.call();
                    Navigator.of(context).maybePop();
                  },
                  child: Text(
                    'Use a freeze',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.emeraldDeep,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: TextButton(
                  onPressed: () {
                    onResetStreak?.call();
                    Navigator.of(context).maybePop();
                  },
                  child: Text(
                    'Reset streak',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

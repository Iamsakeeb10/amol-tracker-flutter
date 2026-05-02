import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../mock/mock_data.dart';
import 'card_container.dart';
import 'score_bar.dart';

class BadgeTile extends StatelessWidget {
  final MockBadge badge;

  const BadgeTile({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.unlocked;
    return CardContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: unlocked ? AppColors.goldCard : AppColors.cardDark,
      borderColor: unlocked ? AppColors.goldBorder : AppColors.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppColors.gold
                  : AppColors.cardBorder.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              badge.icon,
              color: unlocked ? AppColors.emeraldDeep : AppColors.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            badge.title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: unlocked ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            badge.description,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!unlocked) ...[
            const SizedBox(height: 8),
            ScoreBar(value: badge.progress, height: 4),
            const SizedBox(height: 4),
            Text(
              '${(badge.progress * 100).toInt()}%',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                color: AppColors.gold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

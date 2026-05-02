import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../mock/mock_data.dart';
import 'card_container.dart';

class AmalRow extends StatelessWidget {
  final AmalField field;
  final bool done;
  final int? numericValue;
  final ValueChanged<bool>? onChanged;
  final bool readOnly;

  const AmalRow({
    super.key,
    required this.field,
    required this.done,
    this.numericValue,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: done ? AppColors.goldCard : AppColors.cardDark,
      borderColor: done ? AppColors.goldBorder : AppColors.cardBorder,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done ? AppColors.gold : AppColors.cardBorder,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              field.icon,
              color: done ? AppColors.emeraldDeep : AppColors.textSecondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      field.sublabel,
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${field.points} pts',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (readOnly)
            Icon(
              done
                  ? Icons.check_circle
                  : (numericValue != null && numericValue! > 0
                        ? Icons.adjust
                        : Icons.cancel_outlined),
              color: done
                  ? AppColors.success
                  : (numericValue != null && numericValue! > 0
                        ? AppColors.warning
                        : AppColors.danger),
            )
          else
            Switch.adaptive(
              value: done,
              onChanged: onChanged,
              activeThumbColor: AppColors.emeraldDeep,
              activeTrackColor: AppColors.gold,
            ),
        ],
      ),
    );
  }
}

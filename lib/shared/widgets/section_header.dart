import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailingText;
  final VoidCallback? onTrailingTap;
  final EdgeInsetsGeometry? padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailingText,
    this.onTrailingTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        EdgeInsets.fromLTRB(4.w, 0, 4.w, AppSpacing.md.h);
    return Padding(
      padding: effectivePadding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.label(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (trailingText != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: Text(
                trailingText!,
                style: AppTextStyles.label(context).copyWith(
                  color: AppColors.gold,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/amal_fields.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/amal_log_model.dart';
import 'avatar_chip.dart';
import 'card_container.dart';

const double kCommunityNameColWidth = 120;
const double kCommunityAmalColWidth = 44;
const double kCommunityScoreColWidth = 52;

const List<({String id, String label})> kCommunityColumns = <({String id, String label})>[
  (id: 'fard', label: 'Fard'),
  (id: 'takbir', label: 'Takbir'),
  (id: 'morning_azkar', label: 'M.Az'),
  (id: 'evening_azkar', label: 'E.Az'),
  (id: 'quran', label: 'Quran'),
  (id: 'mulk', label: 'Mulk'),
  (id: 'miswak', label: 'Miswak'),
  (id: 'sunnah', label: 'Sunnah'),
  (id: 'post_azkar', label: 'P.Az'),
];

double get kCommunityMinGridWidth =>
    kCommunityNameColWidth +
    (kCommunityAmalColWidth * kAmalFields.length) +
    kCommunityScoreColWidth;

class CommunityHeaderRow extends StatelessWidget {
  const CommunityHeaderRow({super.key, required this.horizontalController});

  final ScrollController horizontalController;

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      radius: AppRadius.md,
      child: SingleChildScrollView(
        controller: horizontalController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: kCommunityMinGridWidth.w,
          child: Row(
            children: [
              _HeaderCell(
                text: 'Name',
                width: kCommunityNameColWidth,
                align: TextAlign.left,
              ),
              for (final col in kCommunityColumns)
                _HeaderCell(text: col.label, width: kCommunityAmalColWidth),
              _HeaderCell(text: 'Score', width: kCommunityScoreColWidth),
            ],
          ),
        ),
      ),
    );
  }
}

class CommunityRowCard extends StatelessWidget {
  const CommunityRowCard({
    super.key,
    required this.log,
    required this.horizontalController,
    required this.isToday,
    this.isPinned = false,
    this.isPending = false,
    this.onTap,
  });

  final AmalLogModel log;
  final ScrollController horizontalController;
  final bool isToday;
  final bool isPinned;
  final bool isPending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final displayName = log.isAnonymousDisplay
        ? 'Anonymous'
        : (log.displayName.trim().isEmpty ? 'Community member' : log.displayName.trim());
    final initial = log.isAnonymousDisplay
        ? '🕌'
        : (displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'A');
    final rowColor = isPinned ? AppColors.goldCard : AppColors.cardDark;
    final rowBorder = isPinned ? AppColors.goldBorder : AppColors.cardBorder;

    return CardContainer(
      onTap: onTap,
      color: rowColor,
      borderColor: rowBorder,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      radius: AppRadius.md,
      child: SingleChildScrollView(
        controller: horizontalController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: kCommunityMinGridWidth.w,
          child: Row(
            children: [
              SizedBox(
                width: kCommunityNameColWidth.w,
                child: Row(
                  children: [
                    AvatarChip(
                      initial: initial,
                      color: log.isAnonymousDisplay ? AppColors.emeraldLight : AppColors.emeraldMid,
                      size: 28,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: isPinned ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (final col in kCommunityColumns)
                _StatusCell(
                  width: kCommunityAmalColWidth,
                  isDone: log.toggles[col.id] ?? false,
                  pending: isPending && isToday,
                ),
              SizedBox(
                width: kCommunityScoreColWidth.w,
                child: Center(
                  child: Text(
                    isPending ? '--' : '${log.score}',
                    style: AppTextStyles.bodyMedium(context).copyWith(
                      color: isPinned ? AppColors.goldLight : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
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

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.text,
    required this.width,
    this.align = TextAlign.center,
  });

  final String text;
  final double width;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width.w,
      child: Text(
        text,
        textAlign: align,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySmall(context).copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  const _StatusCell({
    required this.width,
    required this.isDone,
    required this.pending,
  });

  final double width;
  final bool isDone;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final color = pending
        ? AppColors.textMuted
        : isDone
        ? AppColors.success
        : AppColors.danger;
    final label = pending ? '⏳' : (isDone ? '✅' : '❌');
    return SizedBox(
      width: width.w,
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.bodyMedium(context).copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

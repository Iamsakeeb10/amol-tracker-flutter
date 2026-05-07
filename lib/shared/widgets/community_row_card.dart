import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/amal_fields.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/amal_log_model.dart';
import 'avatar_chip.dart';
import 'card_container.dart';

const double kCommunityHeaderRowHeight = 60;
const double kCommunityNameColWidth = 132;
const double kCommunityAmalColWidth = 82;
const double kCommunityScoreColWidth = 60;

final List<({String id, String label})> kCommunityColumns =
    kAmalFields.map((field) => (id: field.id, label: field.labelBn)).toList();

double get kCommunityScrollableGridWidth =>
    kCommunityNameColWidth +
    (kCommunityAmalColWidth * kAmalFields.length) +
    kCommunityScoreColWidth;

class CommunityHeaderRow extends StatelessWidget {
  const CommunityHeaderRow({super.key, required this.horizontalController});

  final ScrollController horizontalController;

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      color: AppColors.cardDark,
      borderColor: AppColors.cardBorder,
      padding: EdgeInsets.zero,
      radius: AppRadius.md,
      child: RawScrollbar(
        controller: horizontalController,
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 5.w,
        radius: Radius.zero,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: SingleChildScrollView(
          controller: horizontalController,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: kCommunityScrollableGridWidth.w,
            child: Row(
              children: [
                _HeaderCell(
                  text: 'Name',
                  width: kCommunityNameColWidth,
                  align: TextAlign.left,
                ),
                for (final col in kCommunityColumns)
                  _HeaderCell(
                    text: col.label,
                    width: kCommunityAmalColWidth,
                  ),
                _HeaderCell(text: 'Score', width: kCommunityScoreColWidth),
              ],
            ),
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
        : (log.displayName.trim().isEmpty
              ? 'Community member'
              : log.displayName.trim());
    final initial = log.isAnonymousDisplay
        ? '🕌'
        : (displayName.isNotEmpty
              ? displayName.substring(0, 1).toUpperCase()
              : 'A');
    final rowColor = isPinned ? AppColors.goldCard : AppColors.cardDark;
    final rowBorder = isPinned ? AppColors.goldBorder : AppColors.cardBorder;

    return CardContainer(
      onTap: onTap,
      color: rowColor,
      borderColor: rowBorder,
      padding: EdgeInsets.zero,
      radius: AppRadius.md,
      child: SingleChildScrollView(
        controller: horizontalController,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: kCommunityScrollableGridWidth.w,
          child: Row(
            children: [
              _NameCell(
                width: kCommunityNameColWidth,
                displayName: displayName,
                initial: initial,
                isAnonymousDisplay: log.isAnonymousDisplay,
                isPinned: isPinned,
              ),
              for (final col in kCommunityColumns)
                () {
                  final field = kAmalFields.firstWhere((f) => f.id == col.id);
                  if (field.type == AmalType.numeric) {
                    return _NumericCell(
                      width: kCommunityAmalColWidth,
                      value: getNumericValue(log.toggles[col.id], field.maxValue),
                      pending: isPending && isToday,
                    );
                  }
                  return _StatusCell(
                    width: kCommunityAmalColWidth,
                    isDone: _toBool(log.toggles[col.id]),
                    pending: isPending && isToday,
                  );
                }(),
              _ScoreCell(
                width: kCommunityScoreColWidth,
                scoreLabel: isPending ? '--' : '${log.score}',
                isPinned: isPinned,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value > 0;
  return false;
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
    return Container(
      width: width.w,
      height: kCommunityHeaderRowHeight.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      alignment: align == TextAlign.left ? Alignment.centerLeft : Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Text(
        text,
        textAlign: align,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySmall(
          context,
        ).copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 10.sp,
          height: 1.15,
        ),
      ),
    );
  }
}

class _NameCell extends StatelessWidget {
  const _NameCell({
    required this.width,
    required this.displayName,
    required this.initial,
    required this.isAnonymousDisplay,
    required this.isPinned,
  });

  final double width;
  final String displayName;
  final String initial;
  final bool isAnonymousDisplay;
  final bool isPinned;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width.w,
      height: 46.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Row(
        children: [
          AvatarChip(
            initial: initial,
            color: isAnonymousDisplay ? AppColors.emeraldLight : AppColors.emeraldMid,
            size: 24,
          ),
          SizedBox(width: 6.w),
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
    final icon = pending
        ? Icons.hourglass_top_rounded
        : (isDone ? Icons.check_circle_rounded : Icons.cancel_rounded);
    return Container(
      width: width.w,
      height: 46.h,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: 17.sp,
        ),
      ),
    );
  }
}

class _NumericCell extends StatelessWidget {
  const _NumericCell({
    required this.width,
    required this.value,
    required this.pending,
  });

  final double width;
  final int value;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    if (pending) {
      return Container(
        width: width.w,
        height: 46.h,
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: AppColors.cardBorder),
          ),
        ),
        child: Center(
          child: Icon(
            Icons.hourglass_top_rounded,
            color: AppColors.textMuted,
            size: 17.sp,
          ),
        ),
      );
    }

    return Container(
      width: width.w,
      height: 46.h,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(minWidth: 32.w),
          alignment: Alignment.center,
          child: Text(
            _toBengaliNumeral(value),
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: value > 0 ? AppColors.gold : AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

String _toBengaliNumeral(int number) {
  const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return number
      .toString()
      .split('')
      .map((digit) => bnDigits[int.parse(digit)])
      .join();
}

class _ScoreCell extends StatelessWidget {
  const _ScoreCell({
    required this.width,
    required this.scoreLabel,
    required this.isPinned,
  });

  final double width;
  final String scoreLabel;
  final bool isPinned;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width.w,
      height: 46.h,
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Center(
        child: Text(
          scoreLabel,
          style: AppTextStyles.bodyMedium(context).copyWith(
            color: isPinned ? AppColors.goldLight : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

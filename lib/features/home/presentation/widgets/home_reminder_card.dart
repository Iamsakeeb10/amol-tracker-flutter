import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/card_container.dart';

class HomeReminderCard extends StatefulWidget {
  const HomeReminderCard({
    super.key,
    required this.l10n,
    required this.onDismiss,
  });

  final AppLocalizations l10n;
  final VoidCallback onDismiss;

  @override
  State<HomeReminderCard> createState() => _HomeReminderCardState();
}

class _HomeReminderCardState extends State<HomeReminderCard> {
  bool _isExpanded = false;

  List<TextSpan> _parseMarkdownBold(String text, BuildContext context) {
    final spans = <TextSpan>[];
    final defaultStyle = AppTextStyles.bodyMedium(context);
    final boldStyle = defaultStyle.copyWith(fontWeight: FontWeight.w600);
    
    final parts = text.split('**');
    for (var i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: i % 2 == 1 ? boldStyle : defaultStyle,
      ));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return CardContainer.gold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.goldLight,
                size: 16.r,
              ),
              SizedBox(width: 6.w),
              Text(
                widget.l10n.homeReminderTitle,
                style: AppTextStyles.label(context).copyWith(color: AppColors.gold),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onDismiss,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.all(4.r),
                  child: Icon(
                    Icons.close,
                    color: AppColors.textMuted,
                    size: 16.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: _parseMarkdownBold(widget.l10n.homeReminderBody, context),
              ),
            ),
            secondChild: RichText(
              text: TextSpan(
                children: _parseMarkdownBold(widget.l10n.homeReminderBody, context),
              ),
            ),
          ),
          SizedBox(height: 4.h),
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Text(
              _isExpanded ? widget.l10n.seeLess : widget.l10n.seeMore,
              style: AppTextStyles.label(context).copyWith(
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

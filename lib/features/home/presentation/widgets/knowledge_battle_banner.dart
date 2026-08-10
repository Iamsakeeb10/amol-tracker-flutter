import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/card_container.dart';

class KnowledgeBattleBanner extends StatefulWidget {
  const KnowledgeBattleBanner({
    super.key,
    required this.l10n,
    required this.locale,
    required this.onYes,
    required this.onNo,
    required this.onDismiss,
  });

  final AppLocalizations l10n;
  final String locale;
  final VoidCallback onYes;
  final VoidCallback onNo;
  final VoidCallback onDismiss;

  @override
  State<KnowledgeBattleBanner> createState() => _KnowledgeBattleBannerState();
}

class _KnowledgeBattleBannerState extends State<KnowledgeBattleBanner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logBattleTeaserAction(
        action: 'impression',
        locale: widget.locale,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.l10n.battleTeaserTitle,
                  style: AppTextStyles.label(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onDismiss,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.only(left: 8.w, bottom: 8.h),
                  child: Icon(
                    Icons.close,
                    color: AppColors.textMuted,
                    size: 16.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            widget.l10n.battleTeaserSubtitle,
            style: AppTextStyles.bodySmall(context).copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onNo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(widget.l10n.battleTeaserNo),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onYes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldMid,
                    foregroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(widget.l10n.battleTeaserYes),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

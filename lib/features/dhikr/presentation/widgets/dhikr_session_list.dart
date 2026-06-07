import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/dhikr_model.dart';
import '../../../../shared/widgets/card_container.dart';

class DhikrSessionList extends StatelessWidget {
  const DhikrSessionList({
    super.key,
    required this.sessions,
  });

  final List<DhikrSession> sessions;

  String _sessionName(DhikrSession session, AppLocalizations l10n) {
    switch (session.presetId) {
      case kSubhanAllahId:
        return l10n.subhanAllah;
      case kAlhamdulillahId:
        return l10n.alhamdulillah;
      case kAllahuAkbarId:
        return l10n.allahuAkbar;
      default:
        return session.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeFormat = DateFormat.jm();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dhikrTodaySessions,
          style: AppTextStyles.headlineMedium(context).copyWith(fontSize: 16.sp),
        ),
        SizedBox(height: 10.h),
        if (sessions.isEmpty)
          CardContainer(
            child: Text(
              l10n.dhikrNoSessions,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            child: Column(
              children: [
                for (var i = 0; i < sessions.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 18.r,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _sessionName(sessions[i], l10n),
                                style: AppTextStyles.bodyLarge(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.sp,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                l10n.dhikrTarget(sessions[i].target),
                                style: AppTextStyles.bodySmall(context).copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          timeFormat.format(
                            sessions[i].completedAt.toLocal(),
                          ),
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

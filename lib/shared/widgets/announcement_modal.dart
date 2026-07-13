import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/services/analytics_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/external_url_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../models/announcement_model.dart';
import '../../providers/auth_provider.dart';

class AnnouncementModal extends ConsumerStatefulWidget {
  const AnnouncementModal({super.key, required this.announcement});

  final AnnouncementModel announcement;

  @override
  ConsumerState<AnnouncementModal> createState() => _AnnouncementModalState();
}

class _AnnouncementModalState extends ConsumerState<AnnouncementModal> {
  DateTime? _openTime;

  @override
  void initState() {
    super.initState();
    _openTime = DateTime.now();
    AnalyticsService.instance.logAnnouncementOpened(
      announcementId: widget.announcement.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasArabic =
        widget.announcement.arabicText != null && widget.announcement.arabicText!.isNotEmpty;
    final hasImage =
        widget.announcement.imageUrl != null && widget.announcement.imageUrl!.isNotEmpty;

    int timeVisibleSeconds() {
      if (_openTime == null) return 0;
      return DateTime.now().difference(_openTime!).inSeconds;
    }

    Future<void> dismiss() async {
      AnalyticsService.instance.logAnnouncementAction(
        announcementId: widget.announcement.id,
        action: 'dismissed',
        timeVisibleSeconds: timeVisibleSeconds(),
      );
      Navigator.pop(context);
      if (!widget.announcement.showOnce) return;
      final uid = ref.read(currentUserProvider).value?.uid;
      if (uid == null) return;
      await ref
          .read(firestoreServiceProvider)
          .markAnnouncementSeen(uid, widget.announcement.id);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.emeraldDeep,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.goldBorder, width: 1.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close, color: AppColors.textMuted, size: 22.r),
                onPressed: () => dismiss(),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
              child: Column(
                children: [
                  Icon(
                    _iconForType(widget.announcement.type),
                    color: AppColors.goldLight,
                    size: 32.r,
                  ),
                  SizedBox(height: 12.h),
                  if (hasArabic) ...[
                    Text(
                      widget.announcement.arabicText!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 20.sp,
                        color: AppColors.goldLight,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],
                  if (hasImage) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.network(
                        widget.announcement.imageUrl!,
                        width: double.infinity,
                        height: 180.h,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return SizedBox(
                            height: 180.h,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.goldLight,
                                strokeWidth: 2.r,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                  Text(
                    widget.announcement.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NotoSansBengali',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    widget.announcement.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NotoSansBengali',
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  if (widget.announcement.actionUrl != null &&
                      widget.announcement.actionUrl!.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: dismiss,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textMuted,
                              side: BorderSide(color: AppColors.textMuted, width: 1.r),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            child: Text(
                              l10n.announcementDismiss,
                              style: AppTextStyles.button(context).copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              AnalyticsService.instance.logAnnouncementAction(
                                announcementId: widget.announcement.id,
                                action: 'tapped_cta',
                                timeVisibleSeconds: timeVisibleSeconds(),
                              );
                              await launchExternalUrl(widget.announcement.actionUrl!);
                              if (context.mounted) dismiss();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.goldLight,
                              foregroundColor: AppColors.emeraldDeep,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              elevation: 0,
                            ),
                            child: Text(
                              widget.announcement.actionLabel ??
                                  l10n.announcementActionDefault,
                              style: AppTextStyles.button(context).copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emeraldDeep,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: dismiss,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          side: BorderSide(color: AppColors.textMuted, width: 1.r),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: Text(
                          l10n.announcementDismiss,
                          style: AppTextStyles.button(context).copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'dua':
        return Icons.volunteer_activism;
      case 'reminder':
        return Icons.notifications_outlined;
      case 'hadith':
        return Icons.menu_book_outlined;
      case 'announcement':
      default:
        return Icons.campaign_outlined;
    }
  }
}

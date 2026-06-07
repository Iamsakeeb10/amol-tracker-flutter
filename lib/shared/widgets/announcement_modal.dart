import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../l10n/app_localizations.dart';
import '../../models/announcement_model.dart';
import '../../providers/auth_provider.dart';

class AnnouncementModal extends ConsumerWidget {
  const AnnouncementModal({super.key, required this.announcement});

  final AnnouncementModel announcement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final hasArabic =
        announcement.arabicText != null && announcement.arabicText!.isNotEmpty;
    final hasImage =
        announcement.imageUrl != null && announcement.imageUrl!.isNotEmpty;

    Future<void> dismiss() async {
      Navigator.pop(context);
      if (!announcement.showOnce) return;
      final uid = ref.read(currentUserProvider).value?.uid;
      if (uid == null) return;
      await ref
          .read(firestoreServiceProvider)
          .markAnnouncementSeen(uid, announcement.id);
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
                    _iconForType(announcement.type),
                    color: AppColors.goldLight,
                    size: 32.r,
                  ),
                  SizedBox(height: 12.h),
                  if (hasArabic) ...[
                    Text(
                      announcement.arabicText!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
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
                        announcement.imageUrl!,
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
                    announcement.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    announcement.message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: dismiss,
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
                        l10n.announcementDismiss,
                        style: AppTextStyles.button(context).copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.emeraldDeep,
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

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';

class JummahReminderModal extends StatelessWidget {
  const JummahReminderModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.54),
      builder: (_) => const JummahReminderModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
              child: Column(
                children: [
                  Icon(
                    Icons.mosque,
                    color: AppColors.goldLight,
                    size: 32.r,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'بِسْمِ ٱللَّٰهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 20.sp,
                      color: AppColors.goldLight,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'জুমুআহর বরকতময় সময়',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NotoSansBengali',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _modalBullet(
                    icon: Icons.menu_book_outlined,
                    text: 'সূরা কাহফ তিলাওয়াত করুন।',
                  ),
                  _modalBullet(
                    icon: Icons.auto_awesome_outlined,
                    text: 'রাসূলুল্লাহ ﷺ-এর প্রতি বেশি বেশি দরূদ পাঠ করুন।',
                  ),
                  _modalBullet(
                    icon: Icons.front_hand_outlined,
                    text: 'আন্তরিকভাবে দোয়া করুন; জুমুআহে এমন একটি সময় রয়েছে যখন দোয়া কবুল হয়।',
                  ),
                  _modalBullet(
                    icon: Icons.mosque_outlined,
                    text: 'সময়মতো জুমুআহর সালাতে অংশ নিন এবং সম্ভব হলে আগে মসজিদে পৌঁছান।',
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: BorderSide(color: AppColors.textMuted, width: 1.r),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: Text(
                        'বন্ধ করুন',
                        style: TextStyle(
                          fontFamily: 'NotoSansBengali',
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

  Widget _modalBullet({required IconData icon, required String text}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.goldLight, size: 16.r),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'NotoSansBengali',
                fontSize: 13.sp,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

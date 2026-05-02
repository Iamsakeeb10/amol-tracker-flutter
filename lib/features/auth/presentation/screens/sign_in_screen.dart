import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 96.r,
                  height: 96.r,
                  decoration: BoxDecoration(
                    color: AppColors.goldCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 1.5.r),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'ع',
                    style: AppTextStyles.displayLarge(context).copyWith(
                      color: AppColors.goldLight,
                      fontSize: 38.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'Amol Tracker',
                textAlign: TextAlign.center,
                style: AppTextStyles.displayMedium(context),
              ),
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  'Daily devotion, with brothers',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(context),
                ),
              ),
              SizedBox(height: 26.h),
              Center(
                child: Container(
                  width: 64.w,
                  height: 1.r,
                  color: AppColors.gold.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go(AppRoutes.onboarding),
                        icon: Icon(
                          Icons.g_mobiledata,
                          color: AppColors.emeraldDeep,
                          size: 26.r,
                        ),
                        label: Text(
                          'Continue with Google',
                          style: AppTextStyles.button(context).copyWith(
                            color: AppColors.emeraldDeep,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cream,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: OutlinedButton(
                        onPressed: () => context.go(AppRoutes.onboarding),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(
                          'Continue as guest',
                          style: AppTextStyles.button(context).copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  'By continuing you agree to our Terms & Privacy.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall(context).copyWith(fontSize: 11.sp),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
          Positioned(
            top: 8.h,
            right: 4.w,
            child: TextButton(
              onPressed: () => context.go(AppRoutes.dev),
              child: Text(
                'DEV',
                style: AppTextStyles.label(context).copyWith(color: AppColors.gold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

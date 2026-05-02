import 'package:flutter/material.dart';
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
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.goldCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'ع',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.goldLight,
                      fontSize: 38,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Amol Tracker',
                textAlign: TextAlign.center,
                style: AppTextStyles.displayMedium,
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Daily devotion, with brothers',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              const SizedBox(height: 26),
              Center(
                child: Container(
                  width: 64,
                  height: 1,
                  color: AppColors.gold.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go(AppRoutes.onboarding),
                        icon: const Icon(
                          Icons.g_mobiledata,
                          color: AppColors.emeraldDeep,
                          size: 26,
                        ),
                        label: Text(
                          'Continue with Google',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.emeraldDeep,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cream,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => context.go(AppRoutes.onboarding),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Continue as guest',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'By continuing you agree to our Terms & Privacy.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
          Positioned(
            top: 8,
            right: 4,
            child: TextButton(
              onPressed: () => context.go(AppRoutes.dev),
              child: Text(
                'DEV',
                style: AppTextStyles.label.copyWith(color: AppColors.gold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/locale_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _isSigningIn = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isSigningIn = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      await NotificationService.instance.syncFcmTokenNow();
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.googleSignInFailed('$e')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<void> _handleGuestSignIn() async {
    setState(() => _isSigningIn = true);
    try {
      await ref.read(authServiceProvider).signInAnonymously();
      await NotificationService.instance.syncFcmTokenNow();
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.guestSignInFailed('$e')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  void _showLanguageSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.emeraldMid,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final locale = ref.watch(localeProvider);
            return Padding(
              padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 22.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.languageSection,
                    style: AppTextStyles.headlineMedium(ctx),
                  ),
                  SizedBox(height: 14.h),
                  CardContainer(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.language_outlined, size: 20.r),
                          title: Text(
                            l10n.english,
                            style: AppTextStyles.bodyLarge(ctx),
                          ),
                          trailing: Icon(
                            locale.languageCode == 'en'
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: locale.languageCode == 'en'
                                ? AppColors.gold
                                : AppColors.textMuted,
                          ),
                          onTap: () {
                            ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                            Navigator.pop(ctx);
                          },
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.language_outlined, size: 20.r),
                          title: Text(
                            l10n.bangla,
                            style: AppTextStyles.bodyLarge(ctx),
                          ),
                          trailing: Icon(
                            locale.languageCode == 'bn'
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: locale.languageCode == 'bn'
                                ? AppColors.gold
                                : AppColors.textMuted,
                          ),
                          onTap: () {
                            ref.read(localeProvider.notifier).setLocale(const Locale('bn'));
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                    style: AppTextStyles.displayLarge(
                      context,
                    ).copyWith(color: AppColors.goldLight, fontSize: 38.sp),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                l10n.appTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.displayMedium(context),
              ),
              SizedBox(height: 6.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  l10n.signInTagline,
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
                        onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                        icon: Icon(
                          Icons.g_mobiledata,
                          color: AppColors.emeraldDeep,
                          size: 26.r,
                        ),
                        label: Text(
                          l10n.continueWithGoogle,
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
                        onPressed: _isSigningIn ? null : _handleGuestSignIn,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(
                          l10n.continueAsGuest,
                          style: AppTextStyles.button(
                            context,
                          ).copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    if (_isSigningIn) ...[
                      SizedBox(height: 12.h),
                      const CircularProgressIndicator(strokeWidth: 2),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  l10n.continueTerms,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(fontSize: 11.sp),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
         Positioned(
  top: 12.h,
  right: 6.w,
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: _showLanguageSheet,
      customBorder: const CircleBorder(),
      child: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.cardBorder,
            width: 1.r,
          ),
        ),
        child: Icon(
          Icons.language_outlined,
          color: AppColors.gold,
          size: 24.r,
        ),
      ),
    ),
  ),
),
        ],
      ),
    );
  }
}

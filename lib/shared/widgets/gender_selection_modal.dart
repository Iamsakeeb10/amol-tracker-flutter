import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/services/analytics_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class GenderSelectionModal extends ConsumerStatefulWidget {
  const GenderSelectionModal({
    super.key,
    this.isRequired = false,
    this.customSubtitle,
  });

  final bool isRequired;
  final String? customSubtitle;

  @override
  ConsumerState<GenderSelectionModal> createState() =>
      _GenderSelectionModalState();
}

class _GenderSelectionModalState extends ConsumerState<GenderSelectionModal> {
  UserAmalProfile? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !widget.isRequired,
      // TEMP DEBUG: confirms whether this PopScope is even reached when
      // hardware back is pressed. If this never prints while the dialog
      // is visible, the back press is being swallowed somewhere higher
      // up (e.g. GoRouter's backButtonDispatcher or a PopScope in
      // ScaffoldWithBottomNav / AppScaffold) before it ever gets here.
      // Remove this once the root cause is confirmed.
      onPopInvokedWithResult: (didPop, result) {
        debugPrint(
          '[GenderModal] onPopInvokedWithResult — didPop=$didPop '
          'isRequired=${widget.isRequired}',
        );
      },
      child: Dialog(
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
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 8.h),
                child: Text(
                  l10n.genderSelectionTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineMedium(context),
                ),
              ),
              if (widget.customSubtitle != '')
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                  child: Text(
                    widget.customSubtitle ?? l10n.genderSelectionSubtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium(
                      context,
                    ).copyWith(color: AppColors.textSecondary),
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Expanded(
                      child: _GenderCard(
                        label: l10n.genderMale,
                        selected: _selected == UserAmalProfile.male,
                        onTap: () =>
                            setState(() => _selected = UserAmalProfile.male),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _GenderCard(
                        label: l10n.genderFemale,
                        selected: _selected == UserAmalProfile.female,
                        onTap: () =>
                            setState(() => _selected = UserAmalProfile.female),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _selected == null
                            ? null
                            : () async {
                                AnalyticsService.instance.logGenderSelected(
                                  gender: _selected == UserAmalProfile.male
                                      ? 'male'
                                      : 'female',
                                );
                                final uid = ref
                                    .read(authStateProvider)
                                    .asData
                                    ?.value
                                    ?.uid;
                                if (uid == null) return;
                                final navigator = Navigator.of(context);
                                final isMale =
                                    _selected == UserAmalProfile.male;
                                AnalyticsService.instance.logMessage('Gender selected: ${isMale ? 'male' : 'female'}');
                                await ref
                                    .read(firestoreServiceProvider)
                                    .updateUserGenderPreferences(
                                      uid,
                                      gender: isMale ? 'male' : 'female',
                                      specialTimeActive: isMale ? false : null,
                                    );
                                if (!mounted) return;
                                navigator.pop();
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.emeraldDeep,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          textStyle: AppTextStyles.button(context).copyWith(
                            color: AppColors.emeraldDeep,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(l10n.genderConfirm),
                      ),
                    ),
                    if (!widget.isRequired) ...[
                      SizedBox(height: 10.h),
                      TextButton(
                        onPressed: () async {
                          AnalyticsService.instance.logGenderSkipped();
                          AnalyticsService.instance.logMessage('Gender prompt skipped');
                          final uid = ref
                              .read(authStateProvider)
                              .asData
                              ?.value
                              ?.uid;
                          if (uid == null) return;
                          final navigator = Navigator.of(context);
                          await ref
                              .read(firestoreServiceProvider)
                              .updateUserGenderPreferences(
                                uid,
                                genderPromptDismissed: true,
                              );
                          if (!mounted) return;
                          navigator.pop();
                        },
                        child: Text(
                          l10n.genderSkip,
                          style: AppTextStyles.bodySmall(
                            context,
                          ).copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: selected ? AppColors.goldCard : AppColors.cardDark,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.cardBorder,
            width: selected ? 1.6.r : 1.r,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 18.r,
              height: 18.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.gold : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.gold : AppColors.textHint,
                  width: 1.6.r,
                ),
              ),
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      size: 12.r,
                      color: AppColors.emeraldDeep,
                    )
                  : null,
            ),
            SizedBox(height: 14.h),
            Text(
              label,
              style: AppTextStyles.bodyLarge(context).copyWith(
                fontSize: 15.sp,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.gold : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

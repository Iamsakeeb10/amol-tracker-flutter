import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../providers/locale_provider.dart';
import '../../providers/battle_providers.dart';
import '../../exceptions/battle_api_exception.dart';

class JoinBattleScreen extends ConsumerStatefulWidget {
  final String? initialCode;

  const JoinBattleScreen({super.key, this.initialCode});

  @override
  ConsumerState<JoinBattleScreen> createState() => _JoinBattleScreenState();
}

class _JoinBattleScreenState extends ConsumerState<JoinBattleScreen> {
  late final TextEditingController _codeController;
  bool _isJoining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onCodeChanged(String value) {
    setState(() {
      _error = null;
    });
  }

  Future<void> _handleJoin() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) return;

    final isBn = ref.read(localeProvider).languageCode == 'bn';

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      final repo = ref.read(battleRepositoryProvider);
      await repo.joinBattle(code: code);

      if (mounted) {
        AnalyticsService.instance.logBattleJoined(battleCode: code);
        LocalStorageService.saveActiveBattleCode(code);
        context.pushReplacement(AppRoutes.battleWaitingRoomPath(code));
      }
    } on BattleApiException catch (e, st) {
      AnalyticsService.instance.recordError(e, st, reason: 'Battle API exception when joining');
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      String localMsg = isBn ? 'একটি সমস্যা হয়েছে। আবার চেষ্টা করুন।' : 'An error occurred. Please try again.';
      
      if (msg.contains('not found')) {
        localMsg = isBn ? 'ব্যাটেল খুঁজে পাওয়া যায়নি। কোডটি আবার চেক করুন।' : 'Battle not found. Check the code and try again.';
      } else if (msg.contains('full')) {
        localMsg = isBn ? 'এই ব্যাটেলটি ইতিমধ্যে পূর্ণ হয়ে গেছে।' : 'This battle is already full.';
      } else if (msg.contains('already started') || msg.contains('finished')) {
        localMsg = isBn ? 'এই ব্যাটেলটি ইতিমধ্যে শুরু বা শেষ হয়ে গেছে।' : 'This battle has already started or finished.';
      } else {
        localMsg = e.message;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localMsg), backgroundColor: AppColors.danger),
      );
      setState(() => _error = localMsg);
    } catch (e, st) {
      AnalyticsService.instance.recordError(e, st, reason: 'Failed to join battle');
      if (!mounted) return;
      final errorMsg = isBn ? 'একটি অপ্রত্যাশিত সমস্যা হয়েছে। আবার চেষ্টা করুন।' : 'An unexpected error occurred. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: AppColors.danger),
      );
      setState(() => _error = errorMsg);
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider).languageCode;
    final isBn = locale == 'bn';

    final isValid = _codeController.text.trim().length == 6;

    return AppScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isBn ? 'ব্যাটেল যোগ দিন' : 'Join Battle',
          style: AppTextStyles.headlineMedium(context).copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 24.r),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(0.w, 8.h, 0.w, 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20.h),
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.goldCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldBorder),
              ),
              child: Icon(Icons.group_add_rounded, color: AppColors.gold, size: 26.r),
            ),
            SizedBox(height: 20.h),
            Text(
              isBn ? 'আপনি আমন্ত্রিত!' : 'You\'ve been invited!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              isBn
                  ? 'নিচের কোডটি ব্যবহার করে ব্যাটেলে যোগ দিন'
                  : 'Join the battle using the invite code below',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5.sp, color: AppColors.textSecondary),
            ),
            SizedBox(height: 28.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(AppRadius.lg.r),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                controller: _codeController,
                onChanged: _onCodeChanged,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                ],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8.w,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  hintText: 'ABCDEF',
                  hintStyle: TextStyle(
                    color: AppColors.textHint,
                    letterSpacing: 8.w,
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              SizedBox(height: 16.h),
              _ErrorBanner(message: _error!),
            ],
            const Spacer(),
            _JoinButton(
              label: isBn ? 'যোগ দিন' : 'Join',
              isLoading: _isJoining,
              enabled: isValid,
              onTap: _handleJoin,
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline error banner, styled with the danger palette instead of a plain
/// colored Text — matches the other battle screens.
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(AppRadius.md.r),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13.sp, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold gradient CTA — matches Create Battle / Start Battle buttons used
/// elsewhere in the battle flow.
class _JoinButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const _JoinButton({
    required this.label,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = isLoading || !enabled;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled && !isLoading ? 0.5 : 1,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gold, AppColors.goldLight],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 20.r,
                    width: 20.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.emeraldDeep,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.emeraldDeep,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
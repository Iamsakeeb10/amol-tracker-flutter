import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../providers/locale_provider.dart';
import '../../providers/battle_providers.dart';

/// Entry point for the Battle feature.
/// Lets the user either create a new battle (goes to topic selection)
/// or join an existing battle using a room code.
class BattleHomeScreen extends ConsumerWidget {
  const BattleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).languageCode;
    final isBn = locale == 'bn';

    final titleText = isBn ? 'নলেজ ব্যাটেল' : 'Knowledge Battle';
    final subtitleText = isBn
        ? 'বন্ধুদের সাথে প্রতিযোগিতা করুন অথবা কোড দিয়ে যোগ দিন'
        : 'Compete with friends or join using a room code';

    final createTitle = isBn ? 'নতুন ব্যাটেল তৈরি করুন' : 'Create a Battle';
    final createSubtitle = isBn
        ? 'একটি বিষয় বেছে নিন এবং বন্ধুদের আমন্ত্রণ জানান'
        : 'Pick a topic and invite your friends to play';

    final joinTitle = isBn ? 'কোড দিয়ে যোগ দিন' : 'Join with a Code';
    final joinSubtitle = isBn
        ? 'বন্ধুর দেওয়া ব্যাটেল কোড লিখে সরাসরি যোগ দিন'
        : 'Enter a code shared by your friend to jump right in';

    return AppScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          titleText,
          style: AppTextStyles.headlineMedium(context).copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 24.r),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(0.w, 8.h, 0.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 4.h),
            Text(
              subtitleText,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 28.h),
            _BattleOptionRow(
              icon: Icons.emoji_events_rounded,
              title: createTitle,
              subtitle: createSubtitle,
              isPrimary: true,
              onTap: () => context.push(AppRoutes.battleTopics),
            ),
            SizedBox(height: 12.h),
            _BattleOptionRow(
              icon: Icons.vpn_key_rounded,
              title: joinTitle,
              subtitle: joinSubtitle,
              isPrimary: false,
              onTap: () => _showJoinBattleSheet(context, isBn: isBn),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinBattleSheet(BuildContext context, {required bool isBn}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JoinBattleSheet(isBn: isBn),
    );
  }
}

/// Compact, single-row option card — icon, title/subtitle, trailing arrow.
/// Height is driven by content/padding only, matching the slim list-row
/// style used on the amal home screen (no more full-height hero cards).
class _BattleOptionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback onTap;

  const _BattleOptionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.r, vertical: AppSpacing.md.r),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.goldCard : AppColors.cardDark,
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
          border: Border.all(
            color: isPrimary ? AppColors.goldBorder : AppColors.cardBorder,
            width: isPrimary ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: isPrimary
                    ? AppColors.goldCard
                    : AppColors.emeraldLight.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.md.r),
                border: Border.all(
                  color: isPrimary ? AppColors.goldBorder : AppColors.cardBorder,
                ),
              ),
              child: Icon(
                icon,
                color: isPrimary ? AppColors.gold : AppColors.goldLight,
                size: 22.r,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isPrimary ? AppColors.gold : AppColors.textMuted,
              size: 14.r,
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinBattleSheet extends ConsumerStatefulWidget {
  final bool isBn;
  const _JoinBattleSheet({required this.isBn});

  @override
  ConsumerState<_JoinBattleSheet> createState() => _JoinBattleSheetState();
}

class _JoinBattleSheetState extends ConsumerState<_JoinBattleSheet> {
  final _codeController = TextEditingController();
  bool _isJoining = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.isBn;

    final sheetTitle = isBn ? 'ব্যাটেল কোড লিখুন' : 'Enter Battle Code';
    final sheetSubtitle = isBn
        ? 'বন্ধুর কাছ থেকে পাওয়া ৬ ডিজিটের কোডটি লিখুন'
        : 'Enter the 6-character code shared with you';
    final hintText = isBn ? 'যেমনঃ AB12CD' : 'e.g. AB12CD';
    final joinBtnText = isBn ? 'যোগ দিন' : 'Join Battle';
    final emptyError = isBn ? 'অনুগ্রহ করে কোড লিখুন' : 'Please enter a code';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
        decoration: BoxDecoration(
          color: AppColors.emeraldDeep,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl.r)),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.goldCard,
                    borderRadius: BorderRadius.circular(AppRadius.sm.r),
                    border: Border.all(color: AppColors.goldBorder),
                  ),
                  child: Icon(Icons.vpn_key_rounded, color: AppColors.gold, size: 18.r),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    sheetTitle,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              sheetSubtitle,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              autofocus: true,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
              ],
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: hintText,
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                  letterSpacing: 4,
                  fontWeight: FontWeight.normal,
                ),
                filled: true,
                fillColor: AppColors.cardDark,
                contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md.r),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md.r),
                  borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md.r),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            if (_error != null) ...[
              SizedBox(height: 10.h),
              Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 16.r),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(fontSize: 12.5.sp, color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 24.h),
            GestureDetector(
              onTap: _isJoining ? null : () => _joinBattle(isBn: isBn, emptyError: emptyError),
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
                  child: _isJoining
                      ? SizedBox(
                          height: 20.r,
                          width: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.emeraldDeep,
                          ),
                        )
                      : Text(
                          joinBtnText,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emeraldDeep,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinBattle({required bool isBn, required String emptyError}) async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() => _error = emptyError);
      return;
    }

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      // TODO: replace with your actual join-by-code repository method,
      // e.g. `repo.joinBattle(code: code)`.
      final repo = ref.read(battleRepositoryProvider);
      await repo.joinBattle(code: code);

      if (mounted) {
        LocalStorageService.saveActiveBattleCode(code);
        Navigator.of(context).pop();
        context.pushReplacement(AppRoutes.battleWaitingRoomPath(code));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = isBn ? 'কোডটি সঠিক নয় অথবা মেয়াদ শেষ হয়ে গেছে' : 'Invalid or expired code';
      });
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }
}
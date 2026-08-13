import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../providers/locale_provider.dart';
import '../../../../core/services/local_storage_service.dart';
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

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      final repo = ref.read(battleRepositoryProvider);
      await repo.joinBattle(code: code);
      
      if (mounted) {
        LocalStorageService.saveActiveBattleCode(code);
        context.pushReplacement(AppRoutes.battleWaitingRoomPath(code));
      }
    } on BattleApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'An unexpected error occurred. Please try again.');
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
          style: AppTextStyles.headlineMedium(context),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 24.r),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 24.h),
          Text(
            isBn ? '৬ অক্ষরের কোড প্রবেশ করান' : 'Enter 6-character code',
            style: AppTextStyles.titleMedium(context),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
            Text(
              _error!,
              style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.danger),
              textAlign: TextAlign.center,
            ),
          ],
          const Spacer(),
          ElevatedButton(
            onPressed: (_isJoining || !isValid) ? null : _handleJoin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.3),
              foregroundColor: AppColors.emeraldDeep,
              disabledForegroundColor: AppColors.emeraldDeep.withValues(alpha: 0.5),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: _isJoining
                ? SizedBox(
                    height: 20.r,
                    width: 20.r,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.emeraldDeep),
                  )
                : Text(
                    isBn ? 'যোগ দিন' : 'Join',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/admin_config.dart';
import '../../../../core/services/admin_push_gateway_service.dart';
import '../../../../core/utils/admin_push_debug.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/streak_badge.dart';
import '../widgets/admin_shared_widgets.dart';

final adminPushGatewayServiceProvider = Provider<AdminPushGatewayService>(
  (ref) => AdminPushGatewayService.fromEnvironment(),
);

class AdminPushNotificationScreen extends ConsumerStatefulWidget {
  const AdminPushNotificationScreen({super.key});

  @override
  ConsumerState<AdminPushNotificationScreen> createState() =>
      _AdminPushNotificationScreenState();
}

class _AdminPushNotificationScreenState
    extends ConsumerState<AdminPushNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _type = 'announcement';
  bool _isSending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _titleCtrl.clear();
    _messageCtrl.clear();
    setState(() => _type = 'announcement');
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (!AdminConfig.isAdmin(uid)) return;

    final gateway = ref.read(adminPushGatewayServiceProvider);
    logAdminPushDebug(
      'send tapped: uid=$uid gateway=${gateway.gatewayUrl} '
      'configured=${gateway.isConfigured} hasKey=${gateway.hasGatewayKey}',
    );
    if (!gateway.isConfigured) {
      showAdminSnackBar(context, message: l10n.adminPushGatewayNotConfigured);
      return;
    }

    setState(() => _isSending = true);
    final result = await gateway.sendAdminPush(
      adminUid: uid!,
      title: _titleCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
      type: _type,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    if (result.success) {
      showAdminSnackBar(context, message: l10n.adminPushSent);
      _resetForm();
      return;
    }

    final detail = result.body ?? result.error ?? '';
    showAdminSnackBar(
      context,
      message: detail.isEmpty ? l10n.adminPushFailed : detail,
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = ref.watch(authStateProvider).asData?.value?.uid;
    final hasKey = ref.watch(adminPushGatewayServiceProvider).hasGatewayKey;

    if (!AdminConfig.isAdmin(uid)) {
      return AppScaffold(
        body: Center(
          child: Text(
            l10n.adminNotAuthorized,
            style: AppTextStyles.bodyMedium(context),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AdminAppBar(title: l10n.adminPushScreenTitle),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
          children: [
            AdminScreenHeader(
              subtitle: l10n.adminSectionTitle.toUpperCase(),
              title: l10n.adminPushScreenTitle,
            ),
            SizedBox(height: 18.h),
            SectionHeader(title: l10n.adminPushMessage.toUpperCase()),
            CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminFormField(
                    label: l10n.adminPushTitle,
                    controller: _titleCtrl,
                    icon: Icons.title_rounded,
                    required: true,
                    error: l10n.adminPushTitleRequired,
                  ),
                  AdminFormField(
                    label: l10n.adminPushMessage,
                    controller: _messageCtrl,
                    icon: Icons.message_outlined,
                    required: true,
                    error: l10n.adminPushMessageRequired,
                    maxLines: 5,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SectionHeader(title: l10n.adminPushType.toUpperCase()),
            CardContainer(
              child: AdminTypePillSelector(
                selected: _type,
                onChanged: (v) => setState(() => _type = v),
              ),
            ),
            if (!hasKey) ...[
              SizedBox(height: 12.h),
              const Pill(
                text: 'Gateway key optional',
                icon: Icons.info_outline,
                color: AppColors.warningLight,
                textColor: AppColors.warning,
              ),
            ],
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _send,
                icon: _isSending
                    ? SizedBox(
                        width: 18.r,
                        height: 18.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.emeraldDeep,
                        ),
                      )
                    : Icon(Icons.send_rounded, size: 18.r),
                label: Text(l10n.adminPushSend),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.emeraldDeep,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  textStyle: AppTextStyles.button(context).copyWith(
                    color: AppColors.emeraldDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

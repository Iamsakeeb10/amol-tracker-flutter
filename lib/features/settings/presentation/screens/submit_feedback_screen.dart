import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/feedback_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/feedback_provider.dart';
import '../../../../providers/admin_push_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';

class SubmitFeedbackScreen extends ConsumerStatefulWidget {
  final FeedbackType type;

  const SubmitFeedbackScreen({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<SubmitFeedbackScreen> createState() =>
      _SubmitFeedbackScreenState();
}

class _SubmitFeedbackScreenState extends ConsumerState<SubmitFeedbackScreen> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = ref.read(currentUserProvider).asData?.value;
      final userId = user?.uid ?? 'anonymous';

      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      final platform = Platform.operatingSystem;

      final feedback = FeedbackModel(
        id: FirebaseFirestore.instance.collection('feedbacks').doc().id,
        userId: userId,
        userEmail: user?.email,
        type: widget.type,
        content: content,
        appVersion: appVersion,
        platform: platform,
        createdAt: DateTime.now(),
        status: FeedbackStatus.pending,
      );

      await ref.read(feedbackServiceProvider).submitFeedback(feedback);

      final gateway = ref.read(adminPushGatewayServiceProvider);
      if (gateway.isConfigured) {
        final isBug = widget.type == FeedbackType.bug;
        // ignore result as it's non-blocking for user feedback success
        gateway.sendAdminPush(
          adminUid: userId,
          title: isBug ? '🐛 New Bug Report' : '💡 New Feature Request',
          message: content.length > 100 ? '${content.substring(0, 97)}...' : content,
          type: 'feedback_submitted',
        );
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.submitFeedbackSuccess),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit feedback: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isBug = widget.type == FeedbackType.bug;

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isBug ? l10n.reportBug : l10n.requestFeature,
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBug) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'UI Issue',
                      'Crash',
                      'Performance',
                      'Typo',
                    ].map((preset) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: _FeedbackPresetChip(
                          label: preset,
                          onTap: () {
                            final currentText = _controller.text.trim();
                            if (currentText.isEmpty) {
                              _controller.text = '[$preset] ';
                            } else if (!currentText.startsWith('[$preset]')) {
                              _controller.text = '[$preset] $currentText';
                            }
                            setState(() {});
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 16.h),
              ],
              Expanded(
                child: CardContainer(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    autofocus: true,
                    style: AppTextStyles.bodyLarge(context),
                    decoration: InputDecoration(
                      hintText: l10n.feedbackContentHint,
                      hintStyle: AppTextStyles.bodyLarge(context).copyWith(
                        color: AppColors.textHint,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: (_controller.text.trim().isNotEmpty && !_isSubmitting) ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.emeraldDeep,
                    disabledBackgroundColor: AppColors.cardBorder,
                    disabledForegroundColor: AppColors.textHint,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 22.r,
                          height: 22.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.emeraldDeep,
                          ),
                        )
                      : Text(
                          l10n.save,
                          style: AppTextStyles.button(context).copyWith(
                            color: _controller.text.trim().isNotEmpty ? AppColors.emeraldDeep : AppColors.textHint,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackPresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FeedbackPresetChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gold,
      borderRadius: BorderRadius.circular(100.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          child: Text(
            label,
            style: AppTextStyles.pill(context).copyWith(
              color: AppColors.emeraldDeep,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

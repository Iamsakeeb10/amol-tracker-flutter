import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/feedback_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/feedback_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../core/theme/colors.dart';

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

      final feedback = FeedbackModel(
        id: FirebaseFirestore.instance.collection('feedbacks').doc().id,
        userId: userId,
        type: widget.type,
        content: content,
        createdAt: DateTime.now(),
        status: FeedbackStatus.pending,
      );

      await ref.read(feedbackServiceProvider).submitFeedback(feedback);

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
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _controller.text.trim().isNotEmpty ? _submit : null,
              child: Text(
                l10n.save,
                style: TextStyle(
                  color: _controller.text.trim().isNotEmpty
                      ? AppColors.gold
                      : AppColors.textMuted,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBug) ...[
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    'UI Issue',
                    'Crash',
                    'Performance',
                    'Typo',
                  ].map((preset) {
                    return ActionChip(
                      label: Text(
                        preset,
                        style: TextStyle(fontSize: 12.sp, color: AppColors.textPrimary),
                      ),
                      backgroundColor: AppColors.emeraldMid,
                      side: const BorderSide(color: AppColors.cardBorder),
                      onPressed: () {
                        final currentText = _controller.text.trim();
                        if (currentText.isEmpty) {
                          _controller.text = '[$preset] ';
                        } else if (!currentText.startsWith('[$preset]')) {
                          _controller.text = '[$preset] $currentText';
                        }
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 12.h),
              ],
              CardContainer(
                padding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 14.h,
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 10,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.feedbackContentHint,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

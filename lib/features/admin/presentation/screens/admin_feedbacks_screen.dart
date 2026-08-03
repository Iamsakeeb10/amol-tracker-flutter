import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/feedback_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/time_display_helper.dart';

class AdminFeedbacksScreen extends ConsumerWidget {
  const AdminFeedbacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final feedbacksAsync = ref.watch(feedbacksStreamProvider);

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.adminFeedbacksTitle,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: feedbacksAsync.when(
        data: (feedbacks) {
          if (feedbacks.isEmpty) {
            return const Center(child: Text('No feedbacks yet.'));
          }

          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            itemCount: feedbacks.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final feedback = feedbacks[index];
              final isBug = feedback.type.name == 'bug';

              return CardContainer(
                padding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 14.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isBug
                              ? Icons.bug_report_outlined
                              : Icons.lightbulb_outline_rounded,
                          color: AppColors.gold,
                          size: 18.r,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          isBug ? 'Bug Report' : 'Feature Request',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formatBdTime(context, TimeOfDay.fromDateTime(feedback.createdAt)),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppColors.emeraldDeep,
                                title: Text(l10n.adminDeleteConfirm),
                                actions: [
                                  TextButton(
                                    onPressed: () => context.pop(false),
                                    child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textPrimary)),
                                  ),
                                  TextButton(
                                    onPressed: () => context.pop(true),
                                    child: Text(l10n.delete, style: const TextStyle(color: AppColors.danger)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await ref.read(feedbackServiceProvider).deleteFeedback(feedback.id);
                            }
                          },
                          child: Icon(
                            Icons.delete_outline,
                            color: AppColors.danger,
                            size: 20.r,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      feedback.content,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'User ID: ${feedback.userId}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (feedback.userEmail != null && feedback.userEmail!.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        'Email: ${feedback.userEmail}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (feedback.platform != null || feedback.appVersion != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        'Device: ${feedback.platform ?? "Unknown"} • App Version: ${feedback.appVersion ?? "Unknown"}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

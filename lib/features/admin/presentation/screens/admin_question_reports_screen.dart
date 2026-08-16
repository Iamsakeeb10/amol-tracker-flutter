import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../battle/models/question_report_model.dart';
import '../../../battle/repositories/question_report_repository.dart';

final questionReportsStreamProvider = StreamProvider<List<QuestionReportModel>>((ref) {
  final repo = ref.watch(questionReportRepositoryProvider);
  return repo.watchReports();
});

class AdminQuestionReportsScreen extends ConsumerStatefulWidget {
  const AdminQuestionReportsScreen({super.key});

  @override
  ConsumerState<AdminQuestionReportsScreen> createState() => _AdminQuestionReportsScreenState();
}

class _AdminQuestionReportsScreenState extends ConsumerState<AdminQuestionReportsScreen> {
  String _filterStatus = 'all';

  void _showReportDetails(QuestionReportModel report, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.emeraldDeep,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Details',
                  style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.h),
                _detailRow('Question:', report.questionText),
                SizedBox(height: 8.h),
                _detailRow('Reason:', report.reason),
                SizedBox(height: 8.h),
                _detailRow('Details:', report.details ?? 'N/A'),
                SizedBox(height: 8.h),
                _detailRow('Reported By:', '${report.reportedByUserName} (${report.reportedByUserId})'),
                SizedBox(height: 8.h),
                _detailRow('Date:', DateFormat('MMM dd, yyyy h:mm a').format(report.createdAt)),
                SizedBox(height: 8.h),
                _detailRow('Status:', report.status.toUpperCase()),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (report.status == 'pending') ...[
                      TextButton(
                        onPressed: () {
                          ref.read(questionReportRepositoryProvider).updateReportStatus(report.id, 'dismissed');
                          Navigator.pop(context);
                        },
                        child: Text('Dismiss', style: AppTextStyles.button(context).copyWith(color: AppColors.textMuted)),
                      ),
                      SizedBox(width: 8.w),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(questionReportRepositoryProvider).updateReportStatus(report.id, 'resolved');
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                        ),
                        child: Text('Mark Resolved', style: AppTextStyles.button(context).copyWith(color: Colors.white)),
                      ),
                    ] else ...[
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close', style: AppTextStyles.button(context).copyWith(color: AppColors.gold)),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label(context).copyWith(color: AppColors.textMuted),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: AppTextStyles.bodyMedium(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reportsAsync = ref.watch(questionReportsStreamProvider);

    return AppScaffold(
      handleExitBack: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.adminQuestionReportsTitle, style: AppTextStyles.headlineMedium(context)),
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                SizedBox(width: 8.w),
                _buildFilterChip('Pending', 'pending'),
                SizedBox(width: 8.w),
                _buildFilterChip('Resolved', 'resolved'),
              ],
            ),
          ),
          Expanded(
            child: reportsAsync.when(
              data: (reports) {
                final filtered = reports.where((r) => _filterStatus == 'all' || r.status == _filterStatus).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No reports found.',
                      style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textMuted),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 100.h),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final report = filtered[index];
                    final isPending = report.status == 'pending';
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: CardContainer(
                        padding: EdgeInsets.zero,
                        child: InkWell(
                          onTap: () => _showReportDetails(report, l10n),
                          borderRadius: BorderRadius.circular(16.r),
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: isPending ? AppColors.warning.withOpacity(0.2) : AppColors.success.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Text(
                                        report.status.toUpperCase(),
                                        style: AppTextStyles.label(context).copyWith(
                                          color: isPending ? AppColors.warning : AppColors.success,
                                          fontSize: 10.sp,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM dd').format(report.createdAt),
                                      style: AppTextStyles.label(context).copyWith(color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  report.questionText,
                                  style: AppTextStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Reason: ${report.reason}',
                                  style: AppTextStyles.bodySmall(context).copyWith(color: AppColors.dangerLight),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return InkWell(
      onTap: () => setState(() => _filterStatus = value),
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withOpacity(0.15) : AppColors.emeraldMid,
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.emeraldDeep,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall(context).copyWith(
            color: isSelected ? AppColors.gold : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

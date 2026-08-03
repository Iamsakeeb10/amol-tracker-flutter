import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/toggle_row.dart';

class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.sendFeedback,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),

            SectionHeader(
              title: l10n.sendFeedback,
            ),

           CardContainer(
                padding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 4.h,
                ),
                child: Column(
                  children: [
                    NavRow(
                      icon: Icons.bug_report_outlined,
                      title: l10n.reportBug,
                      subtitle: l10n.reportBugSubtitle,
                      onTap: () {
                        // TODO: Implement report a bug
                      },
                    ),
                    const Divider(),
                    NavRow(
                      icon: Icons.lightbulb_outline_rounded,
                      title: l10n.requestFeature,
                      subtitle: l10n.requestFeatureSubtitle,
                      onTap: () {
                        // TODO: Implement request a feature
                      },
                    ),
                  ],
                ),
              ),
            
          ],
        ),
      ),
    );
  }
}
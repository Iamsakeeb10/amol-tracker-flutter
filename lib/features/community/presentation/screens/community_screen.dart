import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            'Community screen is coming in Phase 5.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(context),
          ),
        ),
      ),
    );
  }
}

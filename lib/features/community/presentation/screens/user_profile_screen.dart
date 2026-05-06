import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            'User profile ($userId) is coming in Phase 5.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(context),
          ),
        ),
      ),
    );
  }
}

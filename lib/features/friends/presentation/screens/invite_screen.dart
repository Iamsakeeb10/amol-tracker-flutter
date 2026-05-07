import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../l10n/app_localizations.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final _joinController = TextEditingController();

  @override
  void dispose() {
    _joinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/friends'),
          icon: Icon(Icons.arrow_back, size: 22.r),
        ),
        title: Text(
          l10n.inviteAndJoin,
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 4.h, 0, 24.h),
        children: [
          Text(
            l10n.yourInviteCode,
            style: AppTextStyles.label(context).copyWith(color: AppColors.gold),
          ),
          SizedBox(height: 8.h),
          CardContainer.gold(
            padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 18.w),
            child: Column(
              children: [
                Text(
                  kGroup.inviteCode,
                  style: AppTextStyles.displayLarge(context).copyWith(
                    color: AppColors.goldLight,
                    fontSize: 36.sp,
                    letterSpacing: 6,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  l10n.inviteCodeValid,
                  style: AppTextStyles.bodySmall(
                    context,
                  ).copyWith(fontSize: 11.sp),
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  height: 40.h,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: kGroup.inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.inviteCodeCopied),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 14.r,
                      color: AppColors.emeraldDeep,
                    ),
                    label: Text(
                      l10n.copyCode,
                      style: AppTextStyles.button(context).copyWith(
                        color: AppColors.emeraldDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: _ShareTile(
                  icon: Icons.message_rounded,
                  label: 'WhatsApp',
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _ShareTile(
                  icon: Icons.link_rounded,
                  label: l10n.shareLink,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Text(
            l10n.joinGroupUpper,
            style: AppTextStyles.label(context).copyWith(color: AppColors.gold),
          ),
          SizedBox(height: 8.h),
          CardContainer(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.textMuted, size: 18.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: _joinController,
                    style: AppTextStyles.bodyLarge(
                      context,
                    ).copyWith(fontSize: 14.sp),
                    cursorColor: AppColors.gold,
                    decoration: InputDecoration(
                      hintText: l10n.enterInviteCode,
                      hintStyle: AppTextStyles.bodyMedium(context),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 48.h,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.joinedMock),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.emeraldDeep,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                l10n.joinGroup,
                style: AppTextStyles.button(context).copyWith(
                  color: AppColors.emeraldDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ShareTile({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 20.r),
          ),
          SizedBox(height: 10.h),
          Text(label, style: AppTextStyles.bodyMedium(context)),
        ],
      ),
    );
  }
}

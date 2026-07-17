import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/external_url_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../models/app_config_model.dart';

class UpdateModal extends StatelessWidget {
  const UpdateModal({
    super.key,
    required this.config,
    required this.installedVersionCode,
  });

  final AppConfigModel config;
  final int installedVersionCode;

  static Future<void> show(
    BuildContext context, {
    required AppConfigModel config,
    required int installedVersionCode,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !config.forceUpdate,
      barrierColor: Colors.black.withValues(alpha: 0.54),
      builder: (_) => UpdateModal(
        config: config,
        installedVersionCode: installedVersionCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasCloseButton = !config.forceUpdate;

    return PopScope(
      canPop: !config.forceUpdate,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.emeraldDeep,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.goldBorder, width: 1.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasCloseButton)
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close, color: AppColors.textMuted, size: 22.r),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20.w,
                  hasCloseButton ? 0 : 24.h,
                  20.w,
                  24.h,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.system_update,
                      color: AppColors.goldLight,
                      size: 32.r,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      config.updateTitle.isNotEmpty
                          ? config.updateTitle
                          : l10n.updateModalTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'NotoSansBengali',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      config.updateMessage.isNotEmpty
                          ? config.updateMessage
                          : l10n.updateModalMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'NotoSansBengali',
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    if (hasCloseButton)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textMuted,
                                side: BorderSide(color: AppColors.textMuted, width: 1.r),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                              ),
                              child: Text(
                                l10n.updateModalMaybeLater,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.button(context).copyWith(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await launchExternalUrl(config.playStoreUrl);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.goldLight,
                                foregroundColor: AppColors.emeraldDeep,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                elevation: 0,
                              ),
                              child: Text(
                                config.buttonLabel.isNotEmpty
                                ? config.buttonLabel
                                : l10n.updateModalUpdateNow,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.button(context).copyWith(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.emeraldDeep,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await launchExternalUrl(config.playStoreUrl);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldLight,
                            foregroundColor: AppColors.emeraldDeep,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            elevation: 0,
                          ),
                          child: Text(
                            config.buttonLabel.isNotEmpty
                                ? config.buttonLabel
                                : l10n.updateModalUpdateNow,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.button(context).copyWith(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.emeraldDeep,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

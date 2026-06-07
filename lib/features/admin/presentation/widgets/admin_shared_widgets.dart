import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import 'admin_announcement_helpers.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminAppBar({
    super.key,
    required this.title,
    this.fallbackRoute = '/more',
  });

  final String title;
  final String? fallbackRoute;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, size: 22.r, color: AppColors.textPrimary),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
            return;
          }
          final route = fallbackRoute;
          if (route != null) context.go(route);
        },
      ),
      title: Text(title, style: AppTextStyles.headlineMedium(context)),
    );
  }
}

class AdminScreenHeader extends StatelessWidget {
  const AdminScreenHeader({
    super.key,
    required this.subtitle,
    required this.title,
  });

  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: AppTextStyles.label(context).copyWith(color: AppColors.gold),
        ),
        SizedBox(height: 2.h),
        Text(title, style: AppTextStyles.displayMedium(context)),
      ],
    );
  }
}

class AdminIconBox extends StatelessWidget {
  const AdminIconBox({super.key, required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34.r,
      height: 34.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cardBorder,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(icon, size: 16.r, color: color ?? AppColors.gold),
    );
  }
}

class AdminTypePillSelector extends StatelessWidget {
  const AdminTypePillSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: kAnnouncementTypes.map((type) {
          final isSelected = selected == type;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: InkWell(
              onTap: () => onChanged(type),
              borderRadius: BorderRadius.circular(99.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.goldCard : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(99.r),
                  border: Border.all(
                    color: isSelected ? AppColors.gold : AppColors.cardBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      iconForAnnouncementType(type),
                      size: 14.r,
                      color: isSelected ? AppColors.gold : AppColors.textMuted,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      typeLabel(l10n, type),
                      style: AppTextStyles.pill(context).copyWith(
                        color: isSelected
                            ? AppColors.gold
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AdminFormField extends StatelessWidget {
  const AdminFormField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.required = false,
    this.error,
    this.maxLines = 1,
    this.textDirection,
  });

  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final bool required;
  final String? error;
  final int maxLines;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        textDirection: textDirection,
        style: AppTextStyles.bodyMedium(context).copyWith(
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.label(context),
          filled: true,
          fillColor: AppColors.cardDark,
          prefixIcon: icon != null
              ? Padding(
                  padding: EdgeInsets.only(left: 12.w, right: 8.w),
                  child: AdminIconBox(icon: icon!),
                )
              : null,
          prefixIconConstraints: BoxConstraints(minWidth: 54.w, minHeight: 34.h),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: AppColors.goldBorder),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: AppColors.danger),
          ),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? error : null
            : null,
      ),
    );
  }
}

class AdminToggleRow extends StatelessWidget {
  const AdminToggleRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          AdminIconBox(icon: icon),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    fontSize: 14.sp,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall(context).copyWith(
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.emeraldDeep,
            activeTrackColor: AppColors.gold,
          ),
        ],
      ),
    );
  }
}

class AdminFormActionRow extends StatelessWidget {
  const AdminFormActionRow({
    super.key,
    required this.previewLabel,
    required this.saveLabel,
    required this.onPreview,
    required this.onSave,
    this.isSaving = false,
  });

  final String previewLabel;
  final String saveLabel;
  final VoidCallback onPreview;
  final VoidCallback onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPreview,
            icon: Icon(Icons.visibility_outlined, size: 18.r),
            label: Text(previewLabel),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.goldBorder),
              foregroundColor: AppColors.goldLight,
              padding: EdgeInsets.symmetric(vertical: 14.h),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.emeraldDeep,
                    ),
                  )
                : Icon(Icons.save_outlined, size: 18.r),
            label: Text(saveLabel),
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
    );
  }
}

void showAdminSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.danger : AppColors.emeraldMid,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      duration: Duration(seconds: isError ? 6 : 3),
    ),
  );
}

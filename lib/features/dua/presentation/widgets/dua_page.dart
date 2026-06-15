import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../models/dua_models.dart';

class DuaPage extends StatelessWidget {
  const DuaPage({super.key, required this.dua});

  final DuaModel dua;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (dua.hasIntroduction) ...[
            Text(
              dua.introduction,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            SizedBox(height: 20.h),
          ],
          if (dua.hasArabic) ...[
            Text(
              dua.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.headlineMedium(context).copyWith(
                fontSize: 22.sp,
                height: 1.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20.h),
          ],
          if (dua.hasTransliteration) ...[
            _TranslationBlock(
              label: l10n.duaTransliteration,
              text: dua.transliteration,
            ),
            SizedBox(height: 16.h),
          ],
          if (dua.hasTranslation) ...[
            _TranslationBlock(
              label: l10n.duaTranslation,
              text: dua.translation,
            ),
            SizedBox(height: 16.h),
          ],
          if (dua.reference.isNotEmpty) ...[
            CardContainer.gold(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bookmark_outline_rounded, color: AppColors.gold, size: 18.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.duaReference,
                          style: AppTextStyles.label(context).copyWith(
                            color: AppColors.gold,
                            fontSize: 10.sp,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          dua.reference,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TranslationBlock extends StatelessWidget {
  const _TranslationBlock({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3.r,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.label(context).copyWith(
                    color: AppColors.gold,
                    fontSize: 10.sp,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  text,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../models/dua_models.dart';
import '../../providers/dua_reader_settings_provider.dart';
import 'dua_floating_audio_button.dart';

class DuaPage extends StatelessWidget {
  const DuaPage({
    super.key,
    required this.dua,
    this.settings = const DuaReaderSettings(),
  });

  final DuaModel dua;
  final DuaReaderSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scale = settings.textScale;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20.w,
        8.h,
        20.w,
        duaPageScrollBottomPadding(hasAudio: dua.hasAudio),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (settings.showIntroduction && dua.hasIntroduction) ...[
            Text(
              dua.introduction,
              style: AppTextStyles.bodyMedium(
                context,
              ).copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
                fontSize: 13.5.sp * scale,
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
                fontSize: 22.sp * scale,
                height: 1.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20.h),
          ],
          if (settings.showTransliteration && dua.hasTransliteration) ...[
            _TranslationBlock(
              label: l10n.duaTransliteration,
              text: dua.transliteration,
              textScale: scale,
            ),
            SizedBox(height: 16.h),
          ],
          if (settings.showTranslation && dua.hasTranslation) ...[
            _TranslationBlock(
              label: l10n.duaTranslation,
              text: dua.displayTranslation,
              textScale: scale,
            ),
            SizedBox(height: 16.h),
          ],
          if (settings.showReference && dua.reference.isNotEmpty) ...[
            CardContainer.gold(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.bookmark_outline_rounded,
                    color: AppColors.gold,
                    size: 18.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.duaReference,
                          style: AppTextStyles.label(
                            context,
                          ).copyWith(
                            color: AppColors.gold,
                            fontSize: 10.sp * scale,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          dua.reference,
                          style: AppTextStyles.bodySmall(context).copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                            fontSize: 12.sp * scale,
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
  const _TranslationBlock({
    required this.label,
    required this.text,
    required this.textScale,
  });

  final String label;
  final String text;
  final double textScale;

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
                  style: AppTextStyles.label(
                    context,
                  ).copyWith(
                    color: AppColors.gold,
                    fontSize: 10.sp * textScale,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  text,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    height: 1.6,
                    fontSize: 15.sp * textScale,
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

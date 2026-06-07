import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/services/hadith_asset_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/card_container.dart';

class HomeWelcomeCard extends StatefulWidget {
  const HomeWelcomeCard({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  State<HomeWelcomeCard> createState() => _HomeWelcomeCardState();
}

class _HomeWelcomeCardState extends State<HomeWelcomeCard> {
  late final Future<List<String>> _hadithFuture =
      HadithAssetService.loadHadithTexts();

  @override
  Widget build(BuildContext context) {
    return CardContainer.gold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.goldLight, size: 16.r),
              SizedBox(width: 6.w),
              Text(
                widget.l10n.welcomeUpper,
                style: AppTextStyles.label(
                  context,
                ).copyWith(color: AppColors.gold),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            widget.l10n.firstAmalStartsToday,
            style: AppTextStyles.bodyLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6.h),
          FutureBuilder<List<String>>(
            future: _hadithFuture,
            builder: (context, snapshot) {
              final hadiths = snapshot.data ?? const <String>[];
              final hadith = hadiths.isEmpty ? null : hadiths.first;
              if (hadith == null) return const SizedBox.shrink();
              return Text(hadith, style: AppTextStyles.bodyMedium(context));
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../models/dua_models.dart';

/// Maps bundled category icon filenames to Material icons.
class DuaCategoryIcons {
  DuaCategoryIcons._();

  static const _iconMap = <String, IconData>{
    'dua_s_importance.svg': Icons.auto_awesome_outlined,
    'dua_s_excellence.svg': Icons.star_outline_rounded,
    'time_of_dua.svg': Icons.schedule_outlined,
    'dua_acceptance.svg': Icons.check_circle_outline_rounded,
    'morning_evening.svg': Icons.wb_twilight_outlined,
    'sleep.svg': Icons.bedtime_outlined,
    'cloths.svg': Icons.checkroom_outlined,
    'home.svg': Icons.home_outlined,
    'toilet.svg': Icons.wc_outlined,
    'adhaan_iqamah.svg': Icons.volume_up_outlined,
    'ablution_bath.svg': Icons.water_drop_outlined,
    'mosque.svg': Icons.mosque_outlined,
    'salah.svg': Icons.mosque_outlined,
    'witr_other.svg': Icons.nightlight_outlined,
    'grave_funeral.svg': Icons.favorite_border_rounded,
    'fasting.svg': Icons.nights_stay_outlined,
    'travel.svg': Icons.flight_outlined,
    'hajj_umrah.svg': Icons.tour_outlined,
    'sacrifice.svg': Icons.celebration_outlined,
    'evil_protection.svg': Icons.shield_outlined,
    'forgiveness.svg': Icons.volunteer_activism_outlined,
    'marriage.svg': Icons.favorite_outline_rounded,
    'family.svg': Icons.family_restroom_outlined,
    'debt.svg': Icons.account_balance_wallet_outlined,
    'anxiety.svg': Icons.psychology_outlined,
    'danger.svg': Icons.warning_amber_outlined,
    'condemnation_praise.svg': Icons.thumb_up_outlined,
    'manners.svg': Icons.handshake_outlined,
    'gathering.svg': Icons.groups_outlined,
    'food.svg': Icons.restaurant_outlined,
    'animals.svg': Icons.pets_outlined,
    'rain_nature.svg': Icons.cloud_outlined,
    'sickness.svg': Icons.medical_services_outlined,
    'jinn_diseases.svg': Icons.healing_outlined,
    'quranic_dua.svg': Icons.menu_book_outlined,
    'greatest_name_of_allah.svg': Icons.auto_awesome,
    'prophet_s_dua.svg': Icons.person_outline_rounded,
    'duas_of_hadith.svg': Icons.article_outlined,
    'duas_of_sahaba.svg': Icons.people_outline_rounded,
    'masnun_duas.svg': Icons.format_quote_outlined,
    'other_duas.svg': Icons.more_horiz_rounded,
    'when_to_say_what.svg': Icons.event_note_outlined,
    'eid.svg': Icons.celebration_outlined,
    '40_rabbana_duas.svg': Icons.format_list_numbered_rounded,
  };

  static IconData resolve(String iconFile) {
    return _iconMap[iconFile] ?? Icons.menu_book_outlined;
  }
}

class DuaCategoryCard extends StatelessWidget {
  const DuaCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  final DuaCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CardContainer(
            padding: EdgeInsets.all(12.r),
            radius: AppRadius.xl,
            color: AppColors.goldCard,
            borderColor: AppColors.goldBorder,
            onTap: onTap,
            child: AspectRatio(
              aspectRatio: 1,
              child: Center(
                child: Icon(
                  DuaCategoryIcons.resolve(category.icon),
                  color: AppColors.gold,
                  size: 40.r,
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            category.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium(context).copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary.withOpacity(0.9),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import 'personal_amol_icons.dart';

/// Full-screen picker with every icon in [kPersonalAmolMaterialIcons]. Pops
/// with the chosen [IconData] (or null when dismissed without a selection).
class PersonalAmolIconPicker extends ConsumerWidget {
  const PersonalAmolIconPicker({super.key, this.selected});

  final IconData? selected;

  static Future<IconData?> show(BuildContext context, {IconData? selected}) {
    return Navigator.of(context).push<IconData>(
      MaterialPageRoute(
        builder: (_) => PersonalAmolIconPicker(selected: selected),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedCodePoint = selected?.codePoint;

    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () => context.canPop() ? context.pop() : null,
        ),
        title: Text(
          l10n.personalAmolIconPickerTitle,
          style: AppTextStyles.headlineMedium(context),
        ),
      ),
      body: GridView.builder(
        // Match the AppBar's horizontal inset (Material titleSpacing is a
        // fixed logical 16, not screen-scaled), so body rows line up with the
        // title and back arrow.
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 10.h,
          crossAxisSpacing: 10,
        ),
        itemCount: kPersonalAmolMaterialIcons.length,
        itemBuilder: (context, index) {
          final icon = kPersonalAmolMaterialIcons[index];
          final isSelected = icon.codePoint == selectedCodePoint;
          return GestureDetector(
            onTap: () => Navigator.of(context).pop(icon),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold : AppColors.cardDark,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected ? AppColors.gold : AppColors.cardBorder,
                ),
              ),
              child: Icon(
                icon,
                size: 22.r,
                color: isSelected
                    ? AppColors.emeraldDeep
                    : AppColors.textSecondary,
              ),
            ),
          );
        },
      ),
    );
  }
}
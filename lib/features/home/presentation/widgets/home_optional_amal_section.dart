import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/amal_fields.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/bengali_numeral_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/optional_amal_expansion_provider.dart';
import 'amal_field_tile.dart';

/// Collapsible group of optional (female-deprioritized) amals shown under the
/// main amal list on the home screen.
///
/// The header is a solid gold-tinted card: chevron, section title, a count
/// badge and a right-aligned hint. Expansion is persisted through
/// [optionalAmalExpansionProvider] so the section keeps its state across
/// launches.
class HomeOptionalAmalSection extends ConsumerWidget {
  const HomeOptionalAmalSection({
    super.key,
    required this.fields,
    required this.uid,
    required this.locale,
    required this.readOnly,
    required this.onTapDetails,
  });

  final List<AmalField> fields;
  final String uid;
  final String locale;
  final bool readOnly;
  final ValueChanged<AmalField> onTapDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final expanded = ref.watch(optionalAmalExpansionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          button: true,
          expanded: expanded,
          label: l10n.optionalAmalSection(fields.length),
          child: _OptionalAmalHeader(
            expanded: expanded,
            count: fields.length,
            locale: locale,
            onTap: () =>
                ref.read(optionalAmalExpansionProvider.notifier).toggle(),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final field in fields)
                        Padding(
                          key: ValueKey(field.id),
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: AmalFieldTile(
                            uid: uid,
                            field: field,
                            locale: locale,
                            readOnly: readOnly,
                            onTapDetails: () => onTapDetails(field),
                          ),
                        ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _OptionalAmalHeader extends StatelessWidget {
  const _OptionalAmalHeader({
    required this.expanded,
    required this.count,
    required this.locale,
    required this.onTap,
  });

  final bool expanded;
  final int count;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final radius = 14.r;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.goldCard,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.goldBorder, width: 1),
          ),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20.r,
                  color: AppColors.gold,
                ),
              ),
              SizedBox(width: 6.w),
              Flexible(
                flex: 5,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        l10n.optionalAmalSectionTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldLight,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _CountBadge(count: count, locale: locale),
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

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.locale});

  final int count;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final label = locale == 'bn' ? toBengaliNumeral(count) : '$count';

    return Container(
      constraints: BoxConstraints(minWidth: 20.r),
      height: 20.r,
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.pill(context).copyWith(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.goldPale,
          height: 1,
        ),
      ),
    );
  }
}

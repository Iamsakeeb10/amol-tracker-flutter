import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/amal_fields.dart';
import 'amal_field_tile.dart';
import 'home_amal_loading_shimmer.dart';
import 'home_inactive_special_time_section.dart';
import 'home_optional_amal_section.dart';
import 'home_widgets.dart';

List<Widget> buildHomeAmalFieldSlivers({
  required String uid,
  required BuildContext context,
  required AsyncValue<List<AmalField>> fieldsAsync,
  required String locale,
  required void Function(AmalField field) onTapDetails,
  Future<void> Function()? onRetry,
  bool readOnly = false,
  List<AmalField>? mainFields,
  List<AmalField>? optionalFields,
  List<AmalField>? inactiveSpecialTimeFields,
}) {
  return fieldsAsync.when(
    loading: () => [
      const SliverToBoxAdapter(child: HomeAmalLoadingShimmer()),
    ],
    error: (error, stackTrace) => [
      SliverToBoxAdapter(
        child: HomeAmalFieldsStatusCard(
          message: locale == 'bn'
              ? 'আমল লোড করতে সমস্যা হয়েছে'
              : 'Failed to load amal fields',
          showRetry: onRetry != null,
          onRetry: onRetry,
        ),
      ),
    ],
    data: (loadedFields) {
      final main = mainFields ?? loadedFields;
      final optional = optionalFields;
      final inactive = inactiveSpecialTimeFields;

      if (main.isEmpty &&
          (optional == null || optional.isEmpty) &&
          (inactive == null || inactive.isEmpty)) {
        return const [SliverToBoxAdapter(child: SizedBox.shrink())];
      }

      final widgets = <Widget>[
        SliverList.builder(
          addAutomaticKeepAlives: false,
          itemCount: main.length,
          itemBuilder: (context, index) {
            final field = main[index];
            return Padding(
              key: ValueKey(field.id),
              padding: EdgeInsets.only(bottom: 8.h),
              child: AmalFieldTile(
                uid: uid,
                field: field,
                locale: locale,
                readOnly: readOnly,
                onTapDetails: () => onTapDetails(field),
              ),
            );
          },
        ),
      ];

      if (optional != null && optional.isNotEmpty) {
        widgets.add(
          SliverToBoxAdapter(
            child: HomeOptionalAmalSection(
              fields: optional,
              uid: uid,
              locale: locale,
              readOnly: readOnly,
              onTapDetails: onTapDetails,
            ),
          ),
        );
      }

      if (inactive != null && inactive.isNotEmpty) {
        widgets.add(
          SliverToBoxAdapter(
            child: HomeInactiveSpecialTimeSection(
              fields: inactive,
              uid: uid,
              locale: locale,
              readOnly: true,
              onTapDetails: onTapDetails,
            ),
          ),
        );
      }

      return widgets;
    },
  );
}

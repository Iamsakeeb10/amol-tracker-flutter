import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/amal_fields.dart';
import 'amal_field_tile.dart';
import 'home_amal_loading_shimmer.dart';
import 'home_widgets.dart';

List<Widget> buildHomeAmalFieldSlivers({
  required String uid,
  required AsyncValue<List<AmalField>> fieldsAsync,
  required String locale,
  required void Function(AmalField field) onTapDetails,
  Future<void> Function()? onRetry,
  bool readOnly = false,
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
      if (loadedFields.isEmpty) {
        return const [SliverToBoxAdapter(child: SizedBox.shrink())];
      }
      return [
        SliverList.builder(
          addAutomaticKeepAlives: false,
          itemCount: loadedFields.length,
          itemBuilder: (context, index) {
            final field = loadedFields[index];
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
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/amal_fields.dart';
import '../../core/utils/score_calculator.dart';
import '../../providers/amal_provider.dart';
import 'amal_row.dart';

/// Lazy-built list of amal rows — each row rebuilds only when its toggle changes.
class AmalFieldsListSection extends ConsumerWidget {
  const AmalFieldsListSection({
    super.key,
    required this.uid,
    required this.fields,
    required this.locale,
    this.readOnly = false,
    this.onTapDetails,
  });

  final String uid;
  final List<AmalField> fields;
  final String locale;
  final bool readOnly;
  final void Function(AmalField field)? onTapDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (fields.isEmpty) return const SizedBox.shrink();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      addAutomaticKeepAlives: false,
      itemCount: fields.length,
      itemBuilder: (context, index) {
        final field = fields[index];
        return Padding(
          key: ValueKey(field.id),
          padding: EdgeInsets.only(bottom: 8.h),
          child: _AmalFieldRowTile(
            uid: uid,
            field: field,
            locale: locale,
            readOnly: readOnly,
            onTapDetails: onTapDetails == null
                ? null
                : () => onTapDetails!(field),
          ),
        );
      },
    );
  }
}

class _AmalFieldRowTile extends ConsumerWidget {
  const _AmalFieldRowTile({
    required this.uid,
    required this.field,
    required this.locale,
    required this.readOnly,
    this.onTapDetails,
  });

  final String uid;
  final AmalField field;
  final String locale;
  final bool readOnly;
  final VoidCallback? onTapDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toggleValue = ref.watch(
      amalProvider(uid).select((s) => s.toggles[field.id]),
    );
    final notifier = ref.read(amalProvider(uid).notifier);

    return RepaintBoundary(
      child: field.type == AmalType.numeric
          ? AmalRow(
              field: field,
              locale: locale,
              done: getNumericValue(toggleValue, field.maxValue) > 0,
              numericValue: getNumericValue(toggleValue, field.maxValue),
              onNumericChanged: readOnly
                  ? null
                  : (v) => notifier.setNumeric(field.id, v),
              onTapDetails: onTapDetails,
              readOnly: readOnly,
            )
          : AmalRow(
              field: field,
              locale: locale,
              done: toggleValue as bool? ?? false,
              onChanged: readOnly ? null : (_) => notifier.toggle(field.id),
              onTapDetails: onTapDetails,
              readOnly: readOnly,
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/amal_fields.dart';
import '../../core/utils/score_calculator.dart';
import '../../providers/amal_provider.dart';
import 'amal_row.dart';

/// Lazy-built list of amal rows — rebuilds only when [fields] or toggles change.
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

    final amal = ref.watch(amalProvider(uid));
    final notifier = ref.read(amalProvider(uid).notifier);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fields.length,
      itemBuilder: (context, index) {
        final f = fields[index];
        return Padding(
          key: ValueKey(f.id),
          padding: EdgeInsets.only(bottom: 8.h),
          child: f.type == AmalType.numeric
              ? AmalRow(
                  field: f,
                  locale: locale,
                  done: getNumericValue(amal.toggles[f.id], f.maxValue) > 0,
                  numericValue: getNumericValue(
                    amal.toggles[f.id],
                    f.maxValue,
                  ),
                  onNumericChanged: readOnly
                      ? null
                      : (v) => notifier.setNumeric(f.id, v),
                  onTapDetails: onTapDetails == null
                      ? null
                      : () => onTapDetails!(f),
                  readOnly: readOnly,
                )
              : AmalRow(
                  field: f,
                  locale: locale,
                  done: amal.toggles[f.id] as bool? ?? false,
                  onChanged: readOnly
                      ? null
                      : (_) => notifier.toggle(f.id),
                  onTapDetails: onTapDetails == null
                      ? null
                      : () => onTapDetails!(f),
                  readOnly: readOnly,
                ),
        );
      },
    );
  }
}

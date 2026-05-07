import 'package:flutter/material.dart';

/// Formats notification times in Bangladesh-friendly 12-hour style.
String formatBdTime(BuildContext context, TimeOfDay time) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    time,
    alwaysUse24HourFormat: false,
  );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formats notification times as 12-hour (h:mm a) in the app locale (en/bn).
String formatBdTime(BuildContext context, TimeOfDay time) {
  final locale = Localizations.localeOf(context).toString();
  final dt = DateTime(2000, 1, 1, time.hour, time.minute);
  return DateFormat('h:mm a', locale).format(dt);
}

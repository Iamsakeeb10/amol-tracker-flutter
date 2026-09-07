import 'package:flutter/widgets.dart';

String localeAwareNumeral(BuildContext context, int number) {
  final locale = Localizations.localeOf(context).languageCode;
  return locale == 'bn' ? toBengaliNumeral(number) : '$number';
}

String toBengaliNumeral(int number) {
  const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return number
      .toString()
      .split('')
      .map((digit) => bnDigits[int.parse(digit)])
      .join();
}

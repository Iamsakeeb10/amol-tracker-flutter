import '../../l10n/app_localizations.dart';
import 'bengali_numeral_helper.dart';

String prayerAdhanOffsetChipLabel(
  AppLocalizations l10n,
  int offset, {
  required String languageCode,
}) {
  if (offset == 0) return l10n.prayerAdhanChipAtTime;
  final minutes = offset.abs();
  final display = languageCode == 'bn'
      ? toBengaliNumeral(minutes)
      : '$minutes';
  return l10n.prayerAdhanChipMinBefore(display);
}

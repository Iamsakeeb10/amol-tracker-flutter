import 'package:amol_tracker_app/core/services/islamic_date_service.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  tz.initializeTimeZones();

  final now = IslamicDateService.nowInBD();
  final maghrib = IslamicDateService.getMaghribTime();
  final dateStr = IslamicDateService.getCurrentIslamicDateString();
  final monthNameEn = IslamicDateService.getDisplayIslamicDate(languageCode: 'en');
  final monthNameBn = IslamicDateService.getDisplayIslamicDate(languageCode: 'bn');

  print('Current time in BD: $now');
  print('Maghrib prayer time in BD: $maghrib');
  print('Hijri storage key (midnight day cycle): $dateStr');
  print('Display Date (EN): $monthNameEn');
  print('Display Date (BN): $monthNameBn');
}

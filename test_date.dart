import 'package:amol_tracker_app/core/services/islamic_date_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz_lib;
import 'package:amol_tracker_app/core/constants/app_constants.dart';
import 'package:hijri/hijri_calendar.dart';

void main() {
  tz.initializeTimeZones();
  
  final now = IslamicDateService.nowInBD();
  final maghrib = IslamicDateService.getMaghribTimeSafe();
  final dateStr = IslamicDateService.getCurrentIslamicDateString();
  final dateStorageParts = dateStr.split('-');
  
  final y = int.tryParse(dateStorageParts[0]) ?? 0;
  final m = int.tryParse(dateStorageParts[1]) ?? 0;
  final d = int.tryParse(dateStorageParts[2]) ?? 0;
  
  final monthNameEn = IslamicDateService.getDisplayIslamicDate(languageCode: 'en');
  final monthNameBn = IslamicDateService.getDisplayIslamicDate(languageCode: 'bn');

  final rawHijri = HijriCalendar.fromDate(now);

  print('Current time in BD: $now');
  print('Raw Hijri from package: ${rawHijri.hYear}-${rawHijri.hMonth}-${rawHijri.hDay}');
  print('Maghrib time in BD: $maghrib');
  print('Is past maghrib: ${now.isAfter(maghrib.add(const Duration(minutes: 2)))}');
  print('Calculated Hijri Date String: $dateStr');
  print('Display Date (EN): $monthNameEn');
  print('Display Date (BN): $monthNameBn');
}

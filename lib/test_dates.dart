import 'package:amol_tracker_app/core/services/islamic_date_service.dart';
void main() {
  var now = DateTime.parse("2024-05-11T12:00:00"); // A Saturday
  var hijri = IslamicDateService.islamicDateStringForGregorianDate(now);
  var weekday = IslamicDateService.weekdayEnglishForStorage(hijri);
  print("Saturday -> $hijri -> $weekday");
}

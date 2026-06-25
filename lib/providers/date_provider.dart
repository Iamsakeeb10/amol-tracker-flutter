import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/islamic_date_service.dart';

/// Today's Hijri storage key (`YYYY-MM-DD`). Invalidate on app resume so
/// dependent providers refresh when the Islamic day rolls over.
final currentHijriDateProvider = Provider<String>((ref) {
  return IslamicDateService.getCurrentIslamicDateStringSafe();
});

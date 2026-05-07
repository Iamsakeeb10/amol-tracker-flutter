# 🛠️ Amol Tracker — Fix & Enhancement Task Prompt for Cursor

> Version: Post Phase-8 Fixes
> All current features are working. Apply these changes carefully without breaking existing functionality.
> Follow each phase in order. Test after every phase before proceeding to next.

---

## 📋 Context for Cursor

This is a Flutter app (Flutter 3.38.3, Dart 3.10.1) with:

- Firebase Auth + Firestore + FCM
- Riverpod state management
- GoRouter navigation
- Hive offline cache
- Hijri package for dates
- All 18 screens working

The app tracks 9 daily Islamic habits (amal) for users in Bangladesh (UTC+6).

**Do NOT break any existing working screen or feature. Every change must be surgical and backward compatible.**

---

## 🔴 Phase 1 — Fix Score System (Max 100 not 86)

### Problem

Current point values sum to 86 maximum, but app shows "/100". This is misleading.

### Solution

Rebalance point values so max = exactly 100. Use the following new weights:

```dart
// REPLACE entire kAmalFields in lib/core/constants/amal_fields.dart

const List<AmalField> kAmalFields = [
  AmalField(
    id: 'fard',
    label: 'Fard Salah',
    labelBn: 'জামাতে ফরয নামাজ',
    sublabel: 'জামাতে মোট ফরয নামাজ আদায়',
    points: 30,           // 0-5 numeric, full = 30pts
    maxValue: 5,
    type: AmalType.numeric,
  ),
  AmalField(
    id: 'takbir',
    label: 'Takbir-e-Ula',
    labelBn: 'তাকবীরে উলা',
    sublabel: 'তাকবীরে উলার সাথে জামাতে নামাজ',
    points: 10,           // 0-5 numeric, full = 10pts
    maxValue: 5,
    type: AmalType.numeric,
  ),
  AmalField(
    id: 'morning_azkar',
    label: 'Morning Azkar',
    labelBn: 'সকালের আযকার',
    sublabel: 'সকালের আযকার সম্পন্ন',
    points: 10,
    type: AmalType.boolean,
  ),
  AmalField(
    id: 'evening_azkar',
    label: 'Evening Azkar',
    labelBn: 'সন্ধ্যার আযকার',
    sublabel: 'সন্ধ্যার আযকার সম্পন্ন',
    points: 10,
    type: AmalType.boolean,
  ),
  AmalField(
    id: 'quran',
    label: 'Quran Tilawat',
    labelBn: 'কুরআন তিলাওয়াত',
    sublabel: 'কমপক্ষে এক রুকু তিলাওয়াত',
    points: 10,
    type: AmalType.boolean,
  ),
  AmalField(
    id: 'mulk',
    label: 'Surah Mulk',
    labelBn: 'সূরা মূলক',
    sublabel: 'রাতে ঘুমের আগে সূরা মূলক',
    points: 10,
    type: AmalType.boolean,
  ),
  AmalField(
    id: 'miswak',
    label: 'Miswak',
    labelBn: 'মিসওয়াক',
    sublabel: 'ওজুতে মিসওয়াক (কমপক্ষে একবার)',
    points: 5,
    type: AmalType.boolean,
  ),
  AmalField(
    id: 'sunnah',
    label: 'Sunnah + Witr',
    labelBn: 'সুন্নাহ + বিতির',
    sublabel: '১২ রাকাত সুন্নাহ ও বিতির নামাজ',
    points: 10,
    type: AmalType.boolean,
  ),
  AmalField(
    id: 'post_azkar',
    label: 'Post-Prayer Azkar',
    labelBn: 'নামাজ পরবর্তী আযকার',
    sublabel: 'ফরয নামাজ পরবর্তী আযকার',
    points: 5,
    type: AmalType.boolean,
  ),
];
// Total max: 30 + 10 + 10 + 10 + 10 + 10 + 5 + 10 + 5 = 100 ✅
const int kMaxDailyScore = 100;
```

### Updated AmalField class:

```dart
enum AmalType { boolean, numeric }

class AmalField {
  final String id;
  final String label;         // English label
  final String labelBn;       // Bengali label
  final String sublabel;      // Bengali description
  final int points;           // Max points for this field
  final int maxValue;         // For numeric: max count (default 1 for boolean)
  final AmalType type;

  const AmalField({
    required this.id,
    required this.label,
    required this.labelBn,
    required this.sublabel,
    required this.points,
    this.maxValue = 1,
    this.type = AmalType.boolean,
  });
}
```

### Updated score calculation:

```dart
// lib/core/utils/score_calculator.dart
int calculateScore(Map<String, dynamic> log) {
  int score = 0;
  for (final field in kAmalFields) {
    if (field.type == AmalType.boolean) {
      if (log[field.id] == true) score += field.points;
    } else {
      // Numeric: proportional score
      // e.g. fard = 3/5 prayers → (3/5) * 30 = 18 pts
      final val = (log[field.id] as num?)?.toInt() ?? 0;
      final maxVal = field.maxValue;
      final pts = field.points;
      score += ((val / maxVal) * pts).round();
    }
  }
  return score.clamp(0, kMaxDailyScore);
}
```

### Firestore migration note:

- Existing logs stored as `fard: true/false` must be handled gracefully
- In score calculation: if `log['fard']` is a bool `true`, treat as `5/5` (full marks)
- If `log['fard']` is an int, use the int value
- Add this backward-compat check:

```dart
int getNumericValue(dynamic rawValue, int maxValue) {
  if (rawValue == null) return 0;
  if (rawValue is bool) return rawValue ? maxValue : 0;
  if (rawValue is int) return rawValue.clamp(0, maxValue);
  return 0;
}
```

### Files to update:

- `lib/core/constants/amal_fields.dart` — full replacement
- `lib/core/utils/score_calculator.dart` — update logic
- `lib/models/amal_log_model.dart` — handle both bool and int for fard/takbir
- `lib/providers/amal_provider.dart` — state now Map<String, dynamic> (bool or int)

### Test after Phase 1:

- [ ] Complete all 9 amal with Fard=5, Takbir=5 → score shows 100
- [ ] Fard=3, Takbir=2, all boolean done → score = 18+4+10+10+10+10+5+10+5 = 82
- [ ] All zero → score = 0
- [ ] Old Firestore logs (with bool fard) load correctly without crash

---

## 🕌 Phase 2 — Bangladesh Islamic Date & Maghrib-based Day Change

### Problem

- App uses UTC or device time inconsistently
- Islamic day change happens at midnight (wrong — should be at Maghrib/sunset)
- No BD timezone enforcement

### Solution Architecture

#### Step 1 — Add packages to pubspec.yaml:

```yaml
# Add these:
adhan: ^1.1.2 # Prayer time calculation (offline, no API needed)
flutter_timezone: ^1.0.4 # Get device timezone
```

#### Step 2 — Create BD timezone constant:

```dart
// lib/core/constants/app_constants.dart
class AppConstants {
  // Bangladesh is always UTC+6, no DST
  static const String bdTimezone = 'Asia/Dhaka';
  static const double bdLatitude  = 23.8103;   // Dhaka default
  static const double bdLongitude = 90.4125;   // Dhaka default

  // If you want user location later, store in SharedPreferences
  // For now all BD users use Dhaka coordinates
}
```

#### Step 3 — Create IslamicDateService:

```dart
// lib/core/services/islamic_date_service.dart
import 'package:adhan/adhan.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

class IslamicDateService {
  static final _coords = Coordinates(
    AppConstants.bdLatitude,
    AppConstants.bdLongitude,
  );
  static final _params = CalculationMethod.karachi().getParameters();

  /// Returns Maghrib time for today in Bangladesh local time
  static DateTime getMaghribTime() {
    final now = _nowInBD();
    final dateComponents = DateComponents(now.year, now.month, now.day);
    final prayerTimes = PrayerTimes(_coords, dateComponents, _params);
    // Convert UTC prayer time to BD time
    return prayerTimes.maghrib.toLocal();
  }

  /// Returns the CURRENT Islamic date string (YYYY-MM-DD Hijri)
  /// Rule: After Maghrib → next Islamic day has started
  static String getCurrentIslamicDateString() {
    final now = _nowInBD();
    final maghrib = getMaghribTime();

    // If current time is AFTER maghrib → the new Islamic day has started
    // so use tomorrow's Gregorian date to get the correct Hijri date
    DateTime gregorianForHijri = now;
    if (now.isAfter(maghrib)) {
      gregorianForHijri = now.add(const Duration(days: 1));
    }

    final h = HijriCalendar.fromDate(DateTime(
      gregorianForHijri.year,
      gregorianForHijri.month,
      gregorianForHijri.day,
    ));
    return _formatHijri(h);
  }

  /// Returns Islamic date for display (e.g. "১ জিলকদ ১৪৪৭")
  static String getDisplayIslamicDate() {
    final dateStr = getCurrentIslamicDateString();
    final parts   = dateStr.split('-');
    final h = HijriCalendar()
      ..hYear  = int.parse(parts[0])
      ..hMonth = int.parse(parts[1])
      ..hDay   = int.parse(parts[2]);
    return '${_toBengaliNumeral(h.hDay)} ${_hijriMonthBn(h.hMonth)} ${_toBengaliNumeral(h.hYear)}';
  }

  /// Check if two Islamic date strings are consecutive
  static bool areConsecutiveIslamicDays(String prev, String current) {
    if (prev.isEmpty) return false;
    final p = _parseHijri(prev);
    final c = _parseHijri(current);
    // Convert both to Gregorian and check if difference is 1 day
    final pGreg = HijriCalendar()
      ..hYear = p[0]..hMonth = p[1]..hDay = p[2];
    final cGreg = HijriCalendar()
      ..hYear = c[0]..hMonth = c[1]..hDay = c[2];
    final pDate = pGreg.hijriToGregorian(p[0], p[1], p[2]);
    final cDate = cGreg.hijriToGregorian(c[0], c[1], c[2]);
    final diff = DateTime(cDate.year, cDate.month, cDate.day)
        .difference(DateTime(pDate.year, pDate.month, pDate.day))
        .inDays;
    return diff == 1;
  }

  /// Returns current time in Bangladesh (UTC+6)
  static DateTime _nowInBD() {
    final bdLocation = tz.getLocation(AppConstants.bdTimezone);
    final nowBD = tz.TZDateTime.now(bdLocation);
    return DateTime(nowBD.year, nowBD.month, nowBD.day,
                    nowBD.hour, nowBD.minute, nowBD.second);
  }

  static String _formatHijri(HijriCalendar h) =>
      '${h.hYear}-${h.hMonth.toString().padLeft(2,'0')}-${h.hDay.toString().padLeft(2,'0')}';

  static List<int> _parseHijri(String s) =>
      s.split('-').map(int.parse).toList();

  static String _toBengaliNumeral(int n) {
    const bn = ['০','১','২','৩','৪','৫','৬','৭','৮','৯'];
    return n.toString().split('').map((c) => bn[int.parse(c)]).join();
  }

  static String _hijriMonthBn(int m) {
    const months = ['','মুহাররম','সফর','রবিউল আউয়াল','রবিউল আখির',
      'জুমাদাল উলা','জুমাদাল আখিরাহ','রজব','শাবান',
      'রমজান','শাওয়াল','জিলকদ','জিলহজ'];
    return months[m];
  }
}
```

#### Step 4 — Replace ALL existing Hijri date calls:

Search the entire codebase for:

- `HijriCalendar.now()` → replace with `IslamicDateService.getCurrentIslamicDateString()`
- `HijriHelper.todayString()` → replace with `IslamicDateService.getCurrentIslamicDateString()`
- Any `DateTime.now()` used for Islamic date logic → replace with BD-aware version

#### Step 5 — Day lock logic update:

```dart
// lib/core/utils/streak_helper.dart
// The "today" key for Hive and Firestore is ALWAYS:
final todayKey = IslamicDateService.getCurrentIslamicDateString();

// Day is locked when:
// log exists in Firestore for todayKey AND log.submittedAt exists
// This means: after Maghrib, if user submitted during the day,
// the log belongs to that Islamic date and is locked.
```

#### Step 6 — Initialize timezone in main.dart:

```dart
// In main() before runApp():
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  // Force BD timezone for all Islamic date calculations
  // (device timezone doesn't matter — we always use Asia/Dhaka)
  await Firebase.initializeApp(...);
  // ... rest of init
}
```

#### Step 7 — Home screen Hijri date header:

```dart
// In home_screen.dart, replace date display with:
Text(IslamicDateService.getDisplayIslamicDate())
// Shows: "১ জিলকদ ১৪৪৭" (Bengali numerals + month name)
```

### Files to update:

- `pubspec.yaml` — add adhan, flutter_timezone
- `lib/core/constants/app_constants.dart` — new file
- `lib/core/services/islamic_date_service.dart` — new file (replace hijri_helper.dart)
- `lib/main.dart` — timezone init
- `lib/screens/home/home_screen.dart` — date header
- `lib/core/utils/streak_helper.dart` — use new date service
- `lib/providers/amal_provider.dart` — use new date service
- `lib/providers/community_provider.dart` — use new date service
- Every file that calls HijriCalendar.now() or HijriHelper.todayString()

### Test after Phase 2:

- [ ] Date header on Home shows Bengali Hijri date
- [ ] Set device time to 5:50 PM → Maghrib ~6:10 PM → date shows today's Islamic date
- [ ] Set device time to 6:15 PM (after Maghrib) → date shows next Islamic date
- [ ] Submitted log has correct Islamic date key in Firestore
- [ ] Streak calculation uses Islamic consecutive days correctly
- [ ] Community sheet date tabs show correct Hijri dates in Bengali

---

## 🎛️ Phase 3 — Numeric Amal Fields UI (Stepper Widget)

### Problem

Fard and Takbir are numeric (0–5) but show as switches. UI needs a stepper/counter.

### Exact Field Labels (match Google Sheet exactly):

```dart
// Update labels in amal_fields.dart to match sheet headers:
Field 1 — id: 'fard'
  label:    'Fard Salah'
  labelBn:  'জামাতে ফরয নামাজ'
  sublabel: 'জামাতে মোট ফরয নামাজ আদায়'
  type:     AmalType.numeric, maxValue: 5

Field 2 — id: 'takbir'
  label:    'Takbir-e-Ula'
  labelBn:  'তাকবীরে উলা'
  sublabel: 'তাকবীরে উলার সাথে জামাতে মোট ফরয নামাজ'
  type:     AmalType.numeric, maxValue: 5
  // CONSTRAINT: value cannot exceed fard value
  // e.g. if fard = 3, takbir max = 3

Field 3 — id: 'morning_azkar'
  labelBn:  'সকালের আযকার'
  sublabel: 'সকালের আযকার সম্পন্ন'
  type:     AmalType.boolean

Field 4 — id: 'evening_azkar'
  labelBn:  'সন্ধ্যার আযকার'
  sublabel: 'সন্ধ্যার আযকার সম্পন্ন'
  type:     AmalType.boolean

Field 5 — id: 'quran'
  labelBn:  'কুরআন তিলাওয়াত'
  sublabel: 'কমপক্ষে এক রুকু তিলাওয়াত'
  type:     AmalType.boolean

Field 6 — id: 'mulk'
  labelBn:  'সূরা মূলক'
  sublabel: 'রাতে ঘুমের আগে সূরা মূলক তিলাওয়াত'
  type:     AmalType.boolean

Field 7 — id: 'miswak'
  labelBn:  'মিসওয়াক'
  sublabel: 'ওজুতে মিসওয়াক (কমপক্ষে দিনে একবার)'
  type:     AmalType.boolean

Field 8 — id: 'sunnah'
  labelBn:  'সুন্নাহ + বিতির'
  sublabel: 'ফরয নামাজ ব্যতীত ১২ রাকাত সুন্নাহ + বিতির'
  type:     AmalType.boolean

Field 9 — id: 'post_azkar'
  labelBn:  'নামাজ পরবর্তী আযকার'
  sublabel: 'ফরয নামাজ পরবর্তী আযকার সম্পন্ন'
  type:     AmalType.boolean
```

### New Widget — AmalStepperRow (for numeric fields):

```dart
// lib/widgets/common/amal_stepper_row.dart

class AmalStepperRow extends StatelessWidget {
  final AmalField field;
  final int currentValue;
  final int maxAllowed;  // For takbir: capped at fard value
  final ValueChanged<int> onChanged;

  // UI: [Label] [– ] [  3  ] [ +]
  // Minus button: decrements, min = 0
  // Plus button: increments, max = min(field.maxValue, maxAllowed)
  // Center: shows current value as Bengali numeral
  // Color: gold when > 0, grey when 0
  // The row shows points earned: e.g. "18/30 pts" below stepper

  @override
  Widget build(BuildContext context) {
    return Container(
      // Same styling as AmalToggleRow — dark card, gold border
      // Left: icon + labelBn + sublabel (Bengali text)
      // Right: stepper control [–][value][+]
      // Below value: tiny pts indicator
    );
  }
}
```

### Updated AmalToggleRow (for boolean fields):

```dart
// lib/widgets/common/amal_toggle_row.dart
// Keep existing design — just update labels to use field.labelBn and field.sublabel
// Switch remains the same — no change to boolean UI
```

### Home screen amal list:

```dart
// lib/screens/home/home_screen.dart
// Replace static list with:
ListView.builder(
  itemCount: kAmalFields.length,
  itemBuilder: (context, i) {
    final field = kAmalFields[i];
    if (field.type == AmalType.numeric) {
      final fardVal = amalState['fard'] as int? ?? 0;
      return AmalStepperRow(
        field: field,
        currentValue: amalState[field.id] as int? ?? 0,
        // Takbir cannot exceed Fard count
        maxAllowed: field.id == 'takbir' ? fardVal : field.maxValue,
        onChanged: (val) => ref.read(amalProvider.notifier).setNumeric(field.id, val),
      );
    } else {
      return AmalToggleRow(
        field: field,
        isDone: amalState[field.id] as bool? ?? false,
        onToggle: () => ref.read(amalProvider.notifier).toggleBoolean(field.id),
      );
    }
  },
)
```

### Provider update:

```dart
// lib/providers/amal_provider.dart
// State is Map<String, dynamic> — values are bool (for boolean) or int (for numeric)

class AmalLog extends _$AmalLog {
  @override
  Map<String, dynamic> build() => {
    'fard': 0,
    'takbir': 0,
    'morning_azkar': false,
    'evening_azkar': false,
    'quran': false,
    'mulk': false,
    'miswak': false,
    'sunnah': false,
    'post_azkar': false,
  };

  void setNumeric(String id, int value) {
    // Extra validation for takbir
    if (id == 'takbir') {
      final fard = state['fard'] as int? ?? 0;
      value = value.clamp(0, fard);
    }
    state = {...state, id: value};
  }

  void toggleBoolean(String id) {
    final current = state[id] as bool? ?? false;
    state = {...state, id: !current};
  }

  void markAll() {
    state = {
      'fard': 5,
      'takbir': 5,
      'morning_azkar': true,
      'evening_azkar': true,
      'quran': true,
      'mulk': true,
      'miswak': true,
      'sunnah': true,
      'post_azkar': true,
    };
  }
}
```

### Community Sheet grid cells — numeric display:

```dart
// lib/widgets/common/community_row_card.dart
// For numeric fields (fard, takbir):
// Instead of ✅/❌, show the number: "৩" (Bengali numeral) in gold
// or "০" in grey if 0

Widget _buildCell(AmalField field, dynamic value, bool pending) {
  if (pending) return _pendingCell(); // ⏳

  if (field.type == AmalType.numeric) {
    final val = _getInt(value, field);
    return Container(
      // gold background if val > 0, grey if 0
      child: Text(_toBn(val), style: ...),
    );
  } else {
    final done = value == true;
    return done ? _doneCell() : _missedCell(); // ✅ or ❌
  }
}

int _getInt(dynamic raw, AmalField field) {
  if (raw == null) return 0;
  if (raw is bool) return raw ? field.maxValue : 0;
  if (raw is int) return raw.clamp(0, field.maxValue);
  return 0;
}
```

### Files to update:

- `lib/core/constants/amal_fields.dart` — already done in Phase 1, just verify
- `lib/widgets/common/amal_stepper_row.dart` — new file
- `lib/widgets/common/amal_toggle_row.dart` — update labels to Bengali
- `lib/widgets/common/community_row_card.dart` — numeric cell display
- `lib/screens/home/home_screen.dart` — mixed list rendering
- `lib/providers/amal_provider.dart` — setNumeric + toggleBoolean
- `lib/models/amal_log_model.dart` — toMap/fromDoc for mixed types
- `lib/screens/home/day_complete_screen.dart` — show numeric values in summary
- `lib/screens/history/day_detail_screen.dart` — show numeric values read-only
- `lib/screens/community/user_profile_screen.dart` — amal grid shows numbers

### Test after Phase 3:

- [ ] Home shows stepper for Fard (0–5) with – and + buttons
- [ ] Home shows stepper for Takbir (0–max_fard_value)
- [ ] Takbir cannot go above Fard value (auto-capped)
- [ ] All 7 boolean fields still show toggle switch
- [ ] Bengali labels and sublabels shown correctly
- [ ] "Mark all done" sets Fard=5, Takbir=5, all booleans=true
- [ ] Score 100 when all maxed
- [ ] Community sheet shows Bengali numerals "৩" for fard=3
- [ ] Day Complete summary shows "৩/৫" for numeric fields
- [ ] Day Detail (read-only) shows numeric values correctly

---

## 🛡️ Phase 4 — Edge Case Hardening & Regression Tests

### 4.1 — Backward compatibility for old Firestore logs

All existing logs stored with `fard: true` (bool) must still work.

```dart
// Add to amal_log_model.dart fromDoc():
static AmalLogModel fromDoc(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;

  // Backward compat: fard/takbir may be bool (old) or int (new)
  int parseFard(dynamic v) {
    if (v == null) return 0;
    if (v is bool) return v ? 5 : 0;   // old bool → 5 = all 5 prayers
    if (v is int) return v.clamp(0, 5);
    return 0;
  }
  int parseTakbir(dynamic v, int fard) {
    if (v == null) return 0;
    if (v is bool) return v ? fard : 0;
    if (v is int) return v.clamp(0, fard);
    return 0;
  }

  final fard = parseFard(data['fard']);
  return AmalLogModel(
    uid: data['uid'] ?? '',
    fard: fard,
    takbir: parseTakbir(data['takbir'], fard),
    morningAzkar: data['morning_azkar'] == true,
    eveningAzkar: data['evening_azkar'] == true,
    quran: data['quran'] == true,
    mulk: data['mulk'] == true,
    miswak: data['miswak'] == true,
    sunnah: data['sunnah'] == true,
    postAzkar: data['post_azkar'] == true,
    // ... other fields
  );
}
```

### 4.2 — Takbir cannot exceed Fard: enforce server-side too

```dart
// In Firestore submit logic:
// Before saving, validate:
final fard = log['fard'] as int? ?? 0;
final takbir = (log['takbir'] as int? ?? 0).clamp(0, fard);
log['takbir'] = takbir;
```

### 4.3 — Islamic date edge cases:

```dart
// Edge case 1: Ramadan/Eid — Hijri month boundaries
// HijriCalendar package handles this — no extra logic needed

// Edge case 2: What if Maghrib API/calculation fails?
// Fallback: use 6:00 PM as default Maghrib for Bangladesh
static DateTime getMaghribTimeSafe() {
  try {
    return getMaghribTime();
  } catch (e) {
    final now = _nowInBD();
    return DateTime(now.year, now.month, now.day, 18, 0); // 6:00 PM fallback
  }
}

// Edge case 3: User travels outside BD
// We hardcode BD coordinates — time zone is always Asia/Dhaka
// This is by design (BD-only app per requirements)

// Edge case 4: App open exactly at Maghrib
// Add 2-minute buffer: Islamic day changes 2 min after Maghrib
// to avoid split-second issues
static bool _isPastMaghrib(DateTime now, DateTime maghrib) {
  return now.isAfter(maghrib.add(const Duration(minutes: 2)));
}
```

### 4.4 — Score display update across all screens:

```dart
// Everywhere score is displayed, update denominator:
// OLD: "74/100" where 100 was hardcoded
// NEW: "${score}/${kMaxDailyScore}" — always 100 since Phase 1 fixed it
// Verify in: home_screen, day_complete_screen, community_row_card,
//            leaderboard_screen, user_profile_screen, history_screen
```

### 4.5 — "Mark all done" button edge case:

```dart
// After marking all done:
// Fard = 5, Takbir = 5 (not exceeding Fard)
// All booleans = true
// Score = 100
// Verify stepper UI shows 5 for both numeric fields visually
```

### 4.6 — Community sheet column width for numeric cells:

```dart
// Numeric cells ("৩") may need slightly more width than boolean cells (✅)
// Ensure minimum cell width: 32px for numeric, 28px for boolean
// Test with Bengali numeral "৫" which is slightly wider
```

### 4.7 — Streak with new Islamic date logic:

```dart
// Regression test: streak should still work correctly
// Scenario: User logs at 5:00 PM → Islamic date = "1447-11-01"
// User logs next day at 5:30 PM (before Maghrib) → Islamic date = "1447-11-02"
// Streak: consecutive ✅
// Scenario: User logs at 7:00 PM (after Maghrib) → Islamic date = "1447-11-02"
// Same Islamic date as above → "already logged today" ✅
```

### Files to update in Phase 4:

- `lib/models/amal_log_model.dart` — backward compat parsers
- `lib/core/services/islamic_date_service.dart` — safe fallback + buffer
- `lib/core/utils/firestore_service.dart` — server-side takbir validation
- All screens showing score — verify denominator is kMaxDailyScore

### Test after Phase 4:

- [ ] Old Firestore log with `fard: true` loads as fard=5 without crash
- [ ] Old log with `fard: false` loads as fard=0 without crash
- [ ] Takbir saved as bool true → loads as takbir = fard value
- [ ] Score always between 0 and 100 inclusive
- [ ] Streak works correctly across Maghrib boundary
- [ ] App doesn't crash if prayer time calculation throws exception
- [ ] All 18 screens open without error after all changes

---

## ✅ Final Regression Checklist (Run After All 4 Phases)

### Score system

- [ ] Complete all → 100/100
- [ ] Fard=3, Takbir=2, rest done → correct score (not 100)
- [ ] Nothing done → 0/100
- [ ] Old log (bool format) shows correct score

### Islamic date

- [ ] Bengali Hijri date shows on Home header
- [ ] Before Maghrib → today's Islamic date
- [ ] After Maghrib → next Islamic date
- [ ] Log key in Firestore uses correct Islamic date
- [ ] Community sheet date tabs show correct Hijri dates

### Numeric amal UI

- [ ] Fard stepper works: tap + increases, tap – decreases, min=0 max=5
- [ ] Takbir stepper caps at Fard value
- [ ] 7 boolean toggles unchanged and still work
- [ ] Bengali labels show for all 9 amal
- [ ] Community sheet shows "৩" not ✅ for numeric fields

### No regressions

- [ ] Sign in still works
- [ ] All 3 onboarding slides still work
- [ ] Day Complete screen shows correct summary
- [ ] History calendar still loads
- [ ] Community sheet real-time updates still work
- [ ] Leaderboard still loads and sorts
- [ ] Notifications still fire
- [ ] Settings toggles still work
- [ ] Streak freeze modal still appears correctly
- [ ] Profile badges still show
- [ ] Offline mode still works (Hive cache)
- [ ] No new Dart analysis errors or warnings

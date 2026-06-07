Looking at your codebase (the analysis report), here's exactly how to add per-prayer adhan reminders:

Overview
You already have adhan_dart and flutter_local_notifications in the project. This slots cleanly into your existing NotificationService.

Step 1 — Add prayer reminder settings to Hive prefs
In lib/core/services/local_storage_service.dart, add these pref keys:
dart// Prayer adhan reminder keys
static const String kAdhanFajrEnabled = 'adhan_fajr_enabled';
static const String kAdhanDhuhrEnabled = 'adhan_dhuhr_enabled';
static const String kAdhanAsrEnabled = 'adhan_asr_enabled';
static const String kAdhanMaghribEnabled = 'adhan_maghrib_enabled';
static const String kAdhanIshaEnabled = 'adhan_isha_enabled';
static const String kAdhanOffsetMinutes = 'adhan_offset_minutes'; // 0 = at adhan, -10 = 10 min before

// Getters/setters
bool getAdhanEnabled(String prayer) =>
_prefs.get('adhan_${prayer}\_enabled') as bool? ?? false;

Future<void> setAdhanEnabled(String prayer, bool value) =>
_prefs.put('adhan_${prayer}\_enabled', value);

int getAdhanOffset() =>
\_prefs.get(kAdhanOffsetMinutes) as int? ?? 0;

Future<void> setAdhanOffset(int minutes) =>
\_prefs.put(kAdhanOffsetMinutes, minutes);

Step 2 — Add prayer reminder scheduler to NotificationService
In lib/core/services/notification_service.dart, add:
dart// Notification IDs — keep separate from your existing amal IDs
static const int \_kFajrId = 100;
static const int \_kDhuhrId = 101;
static const int \_kAsrId = 102;
static const int \_kMaghribId = 103;
static const int \_kIshaId = 104;

static const Map<String, int> \_prayerNotifIds = {
'fajr': \_kFajrId,
'dhuhr': \_kDhuhrId,
'asr': \_kAsrId,
'maghrib': \_kMaghribId,
'isha': \_kIshaId,
};

static const Map<String, String> \_prayerNamesBn = {
'fajr': 'ফজর',
'dhuhr': 'যোহর',
'asr': 'আসর',
'maghrib': 'মাগরিব',
'isha': 'ইশা',
};

Future<void> schedulePrayerAdhanReminders() async {
// Cancel existing prayer reminders first
for (final id in \_prayerNotifIds.values) {
await \_localNotifications.cancel(id);
}

final prefs = ref.read(localStorageServiceProvider);
final offsetMinutes = prefs.getAdhanOffset();

// Get tomorrow's prayer times (schedule always for next occurrence)
final prayerTimes = IslamicDateService.getPrayerTimesForBD();

final prayers = {
'fajr': prayerTimes.fajr,
'dhuhr': prayerTimes.dhuhr,
'asr': prayerTimes.asr,
'maghrib': prayerTimes.maghrib,
'isha': prayerTimes.isha,
};

for (final entry in prayers.entries) {
final prayerKey = entry.key;
final prayerTime = entry.value;

    if (!prefs.getAdhanEnabled(prayerKey)) continue;

    // Apply offset (negative = before adhan)
    final notifTime = prayerTime.add(Duration(minutes: offsetMinutes));

    // Skip if time already passed today
    if (notifTime.isBefore(DateTime.now())) continue;

    final nameBn = _prayerNamesBn[prayerKey]!;
    final offsetLabel = offsetMinutes == 0
        ? ''
        : offsetMinutes < 0
            ? ' (${offsetMinutes.abs()} মিনিট আগে)'
            : ' (${offsetMinutes} মিনিট পরে)';

    await _localNotifications.zonedSchedule(
      _prayerNotifIds[prayerKey]!,
      '$nameBn নামাযের সময় হয়েছে$offsetLabel',
      'আযান শুনুন এবং নামাযের জন্য প্রস্তুত হন।',
      tz.TZDateTime.from(notifTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_adhan',
          'নামাযের আযান রিমাইন্ডার',
          channelDescription: 'প্রতিটি ওয়াক্তের আযানের রিমাইন্ডার',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

}
}

// Call this on app resume and after midnight to reschedule
Future<void> reschedulePrayerRemindersIfNeeded() async {
await schedulePrayerAdhanReminders();
}

Step 3 — Add getPrayerTimesForBD() to IslamicDateService
In lib/core/services/islamic_date_service.dart, add:
dartstatic PrayerTimes getPrayerTimesForBD({DateTime? date}) {
final target = date ?? nowInBD();

// Bangladesh coordinates (Dhaka — adjust if needed)
final coordinates = Coordinates(23.8103, 90.4125);
final params = CalculationMethod.karachi.getParameters();
params.madhab = Madhab.hanafi;

final dateComponents = DateComponents(
target.year,
target.month,
target.day,
);

return PrayerTimes(coordinates, dateComponents, params);
}

Step 4 — Create the settings UI
Create: lib/features/settings/presentation/screens/prayer_reminder_screen.dart
dartclass PrayerReminderScreen extends ConsumerStatefulWidget {
const PrayerReminderScreen({super.key});

@override
ConsumerState<PrayerReminderScreen> createState() =>
\_PrayerReminderScreenState();
}

class \_PrayerReminderScreenState
extends ConsumerState<PrayerReminderScreen> {

final List<Map<String, String>> \_prayers = [
{'key': 'fajr', 'bn': 'ফজর', 'en': 'Fajr'},
{'key': 'dhuhr', 'bn': 'যোহর', 'en': 'Dhuhr'},
{'key': 'asr', 'bn': 'আসর', 'en': 'Asr'},
{'key': 'maghrib', 'bn': 'মাগরিব', 'en': 'Maghrib'},
{'key': 'isha', 'bn': 'ইশা', 'en': 'Isha'},
];

// -15, -10, -5, 0 minutes offset options
final List<int> \_offsetOptions = [-15, -10, -5, 0];

@override
Widget build(BuildContext context) {
final prefs = ref.watch(localStorageServiceProvider);
final notifService = ref.read(notificationServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.emeraldDeep,
      appBar: AppBar(
        backgroundColor: AppColors.emeraldDeep,
        title: Text('নামাযের রিমাইন্ডার',
            style: GoogleFonts.notoSansBengali(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // Prayer time preview card
          _PrayerTimesCard(),
          const SizedBox(height: 20),

          // Per-prayer toggles
          ...List.generate(_prayers.length, (i) {
            final p = _prayers[i];
            final enabled = prefs.getAdhanEnabled(p['key']!);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.goldBorder),
              ),
              child: SwitchListTile(
                title: Text('${p['bn']} (${p['en']})',
                    style: GoogleFonts.notoSansBengali(
                        color: Colors.white, fontSize: 15)),
                value: enabled,
                activeColor: AppColors.goldLight,
                onChanged: (val) async {
                  await prefs.setAdhanEnabled(p['key']!, val);
                  await notifService.schedulePrayerAdhanReminders();
                  setState(() {});
                },
              ),
            );
          }),

          const SizedBox(height: 20),

          // Offset selector
          Text('রিমাইন্ডার কখন দেখাবে?',
              style: GoogleFonts.notoSansBengali(
                  color: AppColors.goldLight, fontSize: 14)),
          const SizedBox(height: 10),

          Row(
            children: _offsetOptions.map((offset) {
              final selected = prefs.getAdhanOffset() == offset;
              final label = offset == 0
                  ? 'আযানের সময়'
                  : '${offset.abs()} মিনিট আগে';
              return Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await prefs.setAdhanOffset(offset);
                    await notifService.schedulePrayerAdhanReminders();
                    setState(() {});
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.goldLight
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.goldBorder),
                    ),
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 11,
                          color: selected
                              ? AppColors.emeraldDeep
                              : Colors.white70,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );

}
}

// Shows today's calculated prayer times
class \_PrayerTimesCard extends StatelessWidget {
@override
Widget build(BuildContext context) {
final times = IslamicDateService.getPrayerTimesForBD();
final prayers = [
('ফজর', times.fajr),
('যোহর', times.dhuhr),
('আসর', times.asr),
('মাগরিব', times.maghrib),
('ইশা', times.isha),
];
final fmt = DateFormat('h:mm a');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.goldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('আজকের নামাযের সময়',
              style: GoogleFonts.notoSansBengali(
                  color: AppColors.goldLight, fontSize: 13)),
          const SizedBox(height: 10),
          ...prayers.map((p) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(p.$1,
                    style: GoogleFonts.notoSansBengali(
                        color: Colors.white, fontSize: 14)),
                Text(fmt.format(p.$2),
                    style: GoogleFonts.notoSansBengali(
                        color: Colors.white70, fontSize: 14)),
              ],
            ),
          )),
        ],
      ),
    );

}
}

Step 5 — Wire into router and settings screen
In lib/core/router/routes.dart, add:
dartstatic const String prayerReminder = 'prayerReminder';
static const String prayerReminderPath = '/settings/prayer-reminder';
In lib/core/router/router.dart, add the route under settings:
dartGoRoute(
path: AppRoutes.prayerReminderPath,
name: AppRoutes.prayerReminder,
builder: (\_, \_\_) => const PrayerReminderScreen(),
),
In settings_screen.dart, add a tile:
dartListTile(
leading: const Icon(Icons.notifications_active_outlined,
color: AppColors.goldLight),
title: Text('নামাযের রিমাইন্ডার',
style: GoogleFonts.notoSansBengali(color: Colors.white)),
subtitle: Text('প্রতিটি ওয়াক্তের আলাদা রিমাইন্ডার',
style: GoogleFonts.notoSansBengali(
color: Colors.white54, fontSize: 12)),
trailing: const Icon(Icons.chevron_right, color: Colors.white38),
onTap: () => context.pushNamed(AppRoutes.prayerReminder),
),

Step 6 — Reschedule on app resume
In your app lifecycle handler (wherever you already call reschedulePrayerRemindersIfNeeded for amal reminders), add:
dart@override
void didChangeAppLifecycleState(AppLifecycleState state) {
if (state == AppLifecycleState.resumed) {
// existing calls...
ref.read(notificationServiceProvider)
.reschedulePrayerRemindersIfNeeded(); // add this
}
}

How it works end-to-end
The user opens Settings → নামাযের রিমাইন্ডার, toggles on whichever prayers they want, picks the offset (at adhan, 5/10/15 min before), and sees today's calculated prayer times right there. Each toggle immediately cancels and reschedules that prayer's notification. On app resume the scheduler re-runs so tomorrow's times are always fresh — since adhan_dart calculates times per date, you always get accurate location-based times without any API call.

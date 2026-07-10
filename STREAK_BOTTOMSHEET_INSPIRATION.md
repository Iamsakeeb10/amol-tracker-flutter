The UI is interactive — tap any day card to see its detail, and use prev/next week to navigate. Now here's the Flutter implementation:

Flutter Code
Step 1 — Show the bottom sheet from your streak button
dart// In home_screen.dart — wherever your streak icon button is
GestureDetector(
onTap: () => showStreakBottomSheet(context, ref),
child: StreakBannerWidget(), // your existing widget
)

void showStreakBottomSheet(BuildContext context, WidgetRef ref) {
showModalBottomSheet(
context: context,
isScrollControlled: true,
backgroundColor: Colors.transparent,
builder: (\_) => const StreakBottomSheet(),
);
}

Step 2 — Create the bottom sheet
Create: lib/features/home/presentation/widgets/streak_bottom_sheet.dart
dartimport 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class StreakBottomSheet extends ConsumerStatefulWidget {
const StreakBottomSheet({super.key});

@override
ConsumerState<StreakBottomSheet> createState() =>
\_StreakBottomSheetState();
}

class \_StreakBottomSheetState
extends ConsumerState<StreakBottomSheet> {

int \_selectedIndex = 6; // default = today (last item)
int \_weekOffset = 0; // 0 = this week, -7 = last week

// Build 7 days based on current offset
List<StreakDay> get \_days {
// Build from your actual history provider
// This is example data structure
return List.generate(7, (i) {
final hijriDate = \_getHijriDateForOffset(
\_weekOffset + i - 6,
);
return StreakDay(
hijriDate: hijriDate,
status: \_getStatusForDate(hijriDate),
score: \_getScoreForDate(hijriDate),
);
});
}

@override
Widget build(BuildContext context) {
final user = ref.watch(currentUserProvider).value;
final days = \_days;
final selected = days[_selectedIndex];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D3D2E),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: Color(0x4DC9A84C),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // Handle
          const _SheetHandle(),

          // Header — streak count + close
          _SheetHeader(
            streak: user?.currentStreak ?? 0,
            onClose: () => Navigator.pop(context),
          ),

          // Stats row
          _StatsRow(
            bestStreak: user?.bestStreak ?? 0,
            freezeUsed: user?.streakFreezeUsed ?? false,
          ),

          // Section label
          const _SectionLabel(text: 'Last 7 days'),

          // Day cards horizontal scroll
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              itemCount: days.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _DayCard(
                  day: days[i],
                  isSelected: i == _selectedIndex,
                  onTap: () => setState(
                    () => _selectedIndex = i,
                  ),
                ),
              ),
            ),
          ),

          // Prev / Next week navigation
          _WeekNavRow(
            weekOffset: _weekOffset,
            onPrev: _weekOffset > -14
                ? () => setState(() {
                    _weekOffset -= 7;
                    _selectedIndex = 6;
                  })
                : null,
            onNext: _weekOffset < 0
                ? () => setState(() {
                    _weekOffset += 7;
                    _selectedIndex = 6;
                  })
                : null,
          ),

          // Detail card for selected day
          _DayDetailCard(day: selected),

          // Freeze info (only when frozen day selected)
          if (selected.status == DayStatus.frozen)
            const _FreezeInfoCard(),

          const SizedBox(height: 24),
        ],
      ),
    );

}
}

Step 3 — Data model
dart// lib/models/streak_day.dart

enum DayStatus { done, missed, frozen, today, future }

class StreakDay {
final String hijriDate; // "1447-10-15"
final DayStatus status;
final int score; // 0–100
final String dayName; // "Fri"
final String hijriDisplay; // "15 Sha"

const StreakDay({
required this.hijriDate,
required this.status,
required this.score,
required this.dayName,
required this.hijriDisplay,
});
}

Step 4 — Day card widget
dartclass \_DayCard extends StatelessWidget {
final StreakDay day;
final bool isSelected;
final VoidCallback onTap;

const \_DayCard({
required this.day,
required this.isSelected,
required this.onTap,
});

Color get \_borderColor => switch (day.status) {
DayStatus.done => const Color(0x4D2ECC71),
DayStatus.missed => const Color(0x33E74C3C),
DayStatus.frozen => const Color(0x4D64B4FF),
DayStatus.today => const Color(0x80C9A84C),
DayStatus.future => Colors.transparent,
};

Color get \_bgColor => switch (day.status) {
DayStatus.done => const Color(0x1F2ECC71),
DayStatus.missed => const Color(0x1AE74C3C),
DayStatus.frozen => const Color(0x1A64B4FF),
DayStatus.today => const Color(0x26C9A84C),
DayStatus.future => const Color(0x0DFFFFFF),
};

String get \_icon => switch (day.status) {
DayStatus.done => '✅',
DayStatus.missed => '❌',
DayStatus.frozen => '🧊',
DayStatus.today => '⏳',
DayStatus.future => '○',
};

@override
Widget build(BuildContext context) {
return GestureDetector(
onTap: onTap,
child: AnimatedContainer(
duration: const Duration(milliseconds: 150),
width: 58,
decoration: BoxDecoration(
color: \_bgColor,
borderRadius: BorderRadius.circular(14),
border: Border.all(
color: isSelected
? const Color(0x99C9A84C)
: \_borderColor,
width: isSelected ? 1.5 : 1,
),
boxShadow: isSelected
? [
BoxShadow(
color: const Color(0xFFC9A84C)
.withOpacity(0.2),
blurRadius: 8,
)
]
: null,
),
child: Stack(
children: [
Padding(
padding: const EdgeInsets.symmetric(
vertical: 10, horizontal: 6,
),
child: Column(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
Text(
day.dayName,
style: GoogleFonts.dmSans(
fontSize: 9,
fontWeight: FontWeight.w500,
color: Colors.white38,
letterSpacing: 0.06,
),
),
const SizedBox(height: 4),
Text(_icon, style: const TextStyle(
fontSize: 18,
)),
const SizedBox(height: 4),
Text(
day.hijriDisplay,
style: const TextStyle(
fontSize: 8,
color: Colors.white30,
),
),
const SizedBox(height: 2),
Text(
day.status == DayStatus.done
? '${day.score}pts'
: day.status.name,
style: TextStyle(
fontSize: 9,
fontWeight: FontWeight.w600,
color: _borderColor,
),
),
],
),
),
// Freeze badge
if (day.status == DayStatus.frozen)
Positioned(
top: -4, right: -4,
child: Container(
width: 16, height: 16,
decoration: BoxDecoration(
color: const Color(0xFF64B4FF),
shape: BoxShape.circle,
border: Border.all(
color: const Color(0xFF0D3D2E),
width: 1.5,
),
),
child: const Center(
child: Text('❄', style: TextStyle(
fontSize: 7,
)),
),
),
),
],
),
),
);
}
}

Step 5 — Connect to your history provider
In \_StreakBottomSheetState, replace the placeholder methods:
dartDayStatus \_getStatusForDate(String hijriDate) {
final today = IslamicDateService
.getCurrentIslamicDateString();
final user = ref.read(currentUserProvider).value;
final logs = ref.read(
historyMonthProvider(...).notifier
); // your existing provider

if (hijriDate == today) return DayStatus.today;

final log = logs.getLogForDate(hijriDate);
if (log == null) {
// Check if freeze was used for this date
if (\_wasFreezeUsed(hijriDate)) {
return DayStatus.frozen;
}
return DayStatus.missed;
}
return DayStatus.done;
}

int \_getScoreForDate(String hijriDate) {
final log = \_getLogForDate(hijriDate);
return log?.score ?? 0;
}

That's the complete implementation. The key parts that match the design:

Animated selection on day card tap
Freeze badge (❄ circle) on frozen days
Detail card updates when day is tapped
Freeze info card slides in only when frozen day is selected
Week navigation with disabled state when at boundaries
Status colors match your brand: green done, red missed, blue frozen, gold today

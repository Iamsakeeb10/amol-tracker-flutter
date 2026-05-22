import 'package:flutter/material.dart';

import '../../core/constants/amal_fields.dart';
import '../../core/theme/colors.dart';
import 'mock_amal_fields.dart';

export 'mock_amal_fields.dart';

/// Legacy alias for mock-only screens.
const List<AmalField> kAmalFields = kMockAmalFields;
const int kMaxDailyScore = kMockMaxDailyScore;

class MockUser {
  final String id;
  final String name;
  final String initial;
  final Color avatarColor;
  final int currentStreak;
  final int bestStreak;
  final int weeklyScore;
  final int todayScore;
  final bool doneToday;

  const MockUser({
    required this.id,
    required this.name,
    required this.initial,
    required this.avatarColor,
    required this.currentStreak,
    required this.bestStreak,
    required this.weeklyScore,
    required this.todayScore,
    this.doneToday = false,
  });
}

const MockUser kCurrentUser = MockUser(
  id: 'me',
  name: 'You',
  initial: 'Y',
  avatarColor: AppColors.gold,
  currentStreak: 23,
  bestStreak: 41,
  weeklyScore: 612,
  todayScore: 84,
  doneToday: false,
);

const List<MockUser> kFriends = [
  MockUser(
    id: 'u1',
    name: 'Ahmad',
    initial: 'A',
    avatarColor: Color(0xFF2D8A6F),
    currentStreak: 31,
    bestStreak: 45,
    weeklyScore: 658,
    todayScore: 92,
    doneToday: true,
  ),
  MockUser(
    id: 'u2',
    name: 'Yousuf',
    initial: 'Y',
    avatarColor: Color(0xFF6E4FA0),
    currentStreak: 18,
    bestStreak: 28,
    weeklyScore: 590,
    todayScore: 78,
    doneToday: true,
  ),
  MockUser(
    id: 'u3',
    name: 'Bilal',
    initial: 'B',
    avatarColor: Color(0xFF8C6A39),
    currentStreak: 12,
    bestStreak: 22,
    weeklyScore: 540,
    todayScore: 65,
    doneToday: false,
  ),
  MockUser(
    id: 'u4',
    name: 'Hamza',
    initial: 'H',
    avatarColor: Color(0xFFB58A4D),
    currentStreak: 9,
    bestStreak: 16,
    weeklyScore: 498,
    todayScore: 44,
    doneToday: false,
  ),
  MockUser(
    id: 'u5',
    name: 'Zayd',
    initial: 'Z',
    avatarColor: Color(0xFF3F7B8C),
    currentStreak: 5,
    bestStreak: 11,
    weeklyScore: 412,
    todayScore: 30,
    doneToday: false,
  ),
];

class MockGroup {
  final String id;
  final String name;
  final String description;
  final String inviteCode;
  final int groupStreak;
  final int memberCount;
  final List<MockUser> members;

  const MockGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.inviteCode,
    required this.groupStreak,
    required this.memberCount,
    required this.members,
  });
}

const MockGroup kGroup = MockGroup(
  id: 'g1',
  name: 'Brothers of Madinah',
  description: 'Daily Fajr challenge',
  inviteCode: 'BRO-447',
  groupStreak: 14,
  memberCount: 5,
  members: kFriends,
);

class MockNotification {
  final String id;
  final String title;
  final String body;
  final String time;
  final bool unread;
  final IconData icon;

  const MockNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    this.unread = false,
  });
}

const List<MockNotification> kNotifications = [
  MockNotification(
    id: 'n1',
    title: 'ফজরের আর ১২ মিনিট বাকি',
    body: 'সকালের নামাজের প্রস্তুতি নিন',
    time: '4:38 AM',
    icon: Icons.notifications_active_outlined,
    unread: true,
  ),
  MockNotification(
    id: 'n2',
    title: 'আহমাদ আপনাকে দোয়া পাঠিয়েছেন',
    body: 'আল্লাহ আপনার চেষ্টা কবুল করুন।',
    time: '8h ago',
    icon: Icons.favorite_outline,
    unread: true,
  ),
  MockNotification(
    id: 'n3',
    title: 'স্ট্রিক মাইলস্টোন',
    body: 'আপনি ২৩ দিন পূর্ণ করেছেন। চালিয়ে যান!',
    time: '1d ago',
    icon: Icons.local_fire_department_outlined,
  ),
  MockNotification(
    id: 'n4',
    title: 'ইউসুফ আপনার গ্রুপে যোগ দিয়েছেন',
    body: 'সালাম দিয়ে স্বাগত জানান',
    time: '2d ago',
    icon: Icons.group_add_outlined,
  ),
  MockNotification(
    id: 'n5',
    title: 'দৈনিক নোটিফিকেশন',
    body: 'সন্ধ্যার আযকার ভুলবেন না',
    time: '3d ago',
    icon: Icons.notifications_outlined,
  ),
];

class MockActivity {
  final String id;
  final String userInitial;
  final Color avatarColor;
  final String text;
  final String time;
  final bool isMilestone;

  const MockActivity({
    required this.id,
    required this.userInitial,
    required this.avatarColor,
    required this.text,
    required this.time,
    this.isMilestone = false,
  });
}

const List<MockActivity> kActivities = [
  MockActivity(
    id: 'a1',
    userInitial: 'A',
    avatarColor: Color(0xFF2D8A6F),
    text: 'Ahmad completed all amal today',
    time: '2h ago',
  ),
  MockActivity(
    id: 'a2',
    userInitial: 'Y',
    avatarColor: AppColors.gold,
    text: 'You hit a 23-day streak',
    time: '5h ago',
    isMilestone: true,
  ),
  MockActivity(
    id: 'a3',
    userInitial: 'Y',
    avatarColor: Color(0xFF6E4FA0),
    text: 'Yousuf prayed Tahajjud',
    time: '8h ago',
  ),
  MockActivity(
    id: 'a4',
    userInitial: 'B',
    avatarColor: Color(0xFF8C6A39),
    text: 'Bilal earned the 10-day badge',
    time: '1d ago',
  ),
  MockActivity(
    id: 'a5',
    userInitial: 'H',
    avatarColor: Color(0xFFB58A4D),
    text: 'Hamza sent you a Dua',
    time: '1d ago',
  ),
];

class MockBadge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
  final double progress;

  const MockBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
    this.progress = 0,
  });
}

const List<MockBadge> kBadges = [
  MockBadge(
    id: 'b1',
    title: '7-Day Streak',
    description: 'A full week of devotion',
    icon: Icons.local_fire_department,
    unlocked: true,
    progress: 1,
  ),
  MockBadge(
    id: 'b2',
    title: '30-Day Streak',
    description: 'A full month of devotion',
    icon: Icons.whatshot,
    unlocked: false,
    progress: 0.76,
  ),
  MockBadge(
    id: 'b3',
    title: 'Quran Reciter',
    description: 'Read Quran 30 days in a row',
    icon: Icons.menu_book,
    unlocked: true,
    progress: 1,
  ),
  MockBadge(
    id: 'b4',
    title: 'Night Worshipper',
    description: 'Tahajjud 21 days',
    icon: Icons.nightlight,
    unlocked: false,
    progress: 0.34,
  ),
];

// ── Only this enum and the buildMockMonth() function change ──

enum DayCompletion {
  full, // score >= 80  ✅ Alhamdulillah
  partial, // score >= 50  🌙 Ma sha Allah
  light, // score >= 20  🟠 Keep Going
  minimal, // score >= 1   💧 A Start
  miss, // score == 0 but log exists (opened app, no amal)
  noData, // no log found for past day (neutral, not a failure)
  today, // today's date
  future, // after today
  preAccount, // before account creation
}

class MockDay {
  final int day;
  final int score;
  final DayCompletion state;

  const MockDay({required this.day, required this.score, required this.state});
}

List<MockDay> buildMockMonth() {
  return List.generate(31, (i) {
    final day = i + 1;
    if (day > 24) {
      return MockDay(
        day: day,
        score: 0,
        state: day == 24 ? DayCompletion.today : DayCompletion.future,
      );
    }
    final pattern = (day * 13) % 10;
    if (pattern < 4) {
      return MockDay(
        day: day,
        score: 80 + (pattern * 3),
        state: DayCompletion.full,
      );
    }
    if (pattern < 6) {
      return MockDay(
        day: day,
        score: 50 + (pattern * 2),
        state: DayCompletion.partial,
      );
    }
    if (pattern < 7) {
      return MockDay(day: day, score: 25 + pattern, state: DayCompletion.light);
    }
    if (pattern < 8) {
      return MockDay(
        day: day,
        score: 5 + pattern,
        state: DayCompletion.minimal,
      );
    }
    // pattern 8-9: alternate between miss (logged zero) and noData (never opened)
    if (pattern == 8) {
      return MockDay(day: day, score: 0, state: DayCompletion.miss);
    }
    return MockDay(day: day, score: 0, state: DayCompletion.noData);
  });
}

class MockWeeklyBar {
  final String label;
  final double value;
  final bool missed;

  const MockWeeklyBar({
    required this.label,
    required this.value,
    this.missed = false,
  });
}

const List<MockWeeklyBar> kWeeklyBars = [
  MockWeeklyBar(label: 'M', value: 0.92),
  MockWeeklyBar(label: 'T', value: 0.85),
  MockWeeklyBar(label: 'W', value: 0.78),
  MockWeeklyBar(label: 'T', value: 0.95),
  MockWeeklyBar(label: 'F', value: 0.40, missed: true),
  MockWeeklyBar(label: 'S', value: 0.88),
  MockWeeklyBar(label: 'S', value: 0.82),
];

const List<String> kHadiths = [
  '"আল্লাহর কাছে সবচেয়ে প্রিয় আমল হলো যে আমল নিয়মিত করা হয়, যদিও তা অল্প হয়।" — সহিহ বুখারি',
  '"পাঁচটি বিষয়ের আগে পাঁচটি বিষয়ের মূল্য দাও: বার্ধক্যের আগে যৌবন, অসুস্থতার আগে সুস্থতা..." — মুস্তাদরাক হাকিম',
  '"যে ব্যক্তি জামাতে ফজর আদায় করে, সে আল্লাহর জিম্মায় থাকে।" — সহিহ মুসলিম',
];

class MockAmalEntry {
  final String fieldId;
  final bool done;
  final int? value;
  final int earnedPoints;

  const MockAmalEntry({
    required this.fieldId,
    required this.done,
    this.value,
    required this.earnedPoints,
  });
}

const List<MockAmalEntry> kTodayAmalEntries = [
  MockAmalEntry(fieldId: 'fard', done: true, value: 5, earnedPoints: 30),
  MockAmalEntry(fieldId: 'takbir', done: true, value: 4, earnedPoints: 8),
  MockAmalEntry(fieldId: 'morning_azkar', done: true, earnedPoints: 10),
  MockAmalEntry(fieldId: 'evening_azkar', done: false, earnedPoints: 0),
  MockAmalEntry(fieldId: 'quran', done: true, earnedPoints: 10),
  MockAmalEntry(fieldId: 'mulk', done: true, earnedPoints: 10),
  MockAmalEntry(fieldId: 'miswak', done: true, earnedPoints: 5),
  MockAmalEntry(fieldId: 'sunnah', done: true, earnedPoints: 10),
  MockAmalEntry(fieldId: 'post_azkar', done: false, earnedPoints: 0),
];

const Map<String, String> kAmalShortLabels = {
  'fard': 'Fard',
  'takbir': 'Tak',
  'morning_azkar': 'M.A',
  'evening_azkar': 'E.A',
  'quran': 'Qur',
  'mulk': 'Mlk',
  'miswak': 'Msw',
  'sunnah': 'Sun',
  'post_azkar': 'P.A',
};

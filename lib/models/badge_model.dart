import 'package:flutter/material.dart';

enum BadgeType {
  threeDays,
  sevenDays,
  fourteenDays,
  thirtyDays,
  sixtyDays,
  hundredDays,
  topOfCommunity,
  perfectWeek,
  courseGraduate,
}

class BadgeDefinition {
  const BadgeDefinition({
    required this.type,
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.streakThreshold,
  });

  final BadgeType type;
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int? streakThreshold;
}

const List<BadgeDefinition> kBadgeDefinitions = [
  BadgeDefinition(
    type: BadgeType.threeDays,
    id: 'threeDays',
    title: '3-Day Streak',
    description: 'Complete amal for 3 consecutive days.',
    icon: Icons.local_fire_department,
    streakThreshold: 3,
  ),
  BadgeDefinition(
    type: BadgeType.sevenDays,
    id: 'sevenDays',
    title: '7-Day Streak',
    description: 'Complete amal for 7 consecutive days.',
    icon: Icons.whatshot,
    streakThreshold: 7,
  ),
  BadgeDefinition(
    type: BadgeType.fourteenDays,
    id: 'fourteenDays',
    title: '14-Day Streak',
    description: 'Complete amal for 14 consecutive days.',
    icon: Icons.local_fire_department_outlined,
    streakThreshold: 14,
  ),
  BadgeDefinition(
    type: BadgeType.thirtyDays,
    id: 'thirtyDays',
    title: '30-Day Streak',
    description: 'Complete amal for 30 consecutive days.',
    icon: Icons.emoji_events_outlined,
    streakThreshold: 30,
  ),
  BadgeDefinition(
    type: BadgeType.sixtyDays,
    id: 'sixtyDays',
    title: '60-Day Streak',
    description: 'Complete amal for 60 consecutive days.',
    icon: Icons.military_tech_outlined,
    streakThreshold: 60,
  ),
  BadgeDefinition(
    type: BadgeType.hundredDays,
    id: 'hundredDays',
    title: '100-Day Streak',
    description: 'Complete amal for 100 consecutive days.',
    icon: Icons.workspace_premium_outlined,
    streakThreshold: 100,
  ),
  BadgeDefinition(
    type: BadgeType.topOfCommunity,
    id: 'topOfCommunity',
    title: 'Top of Community',
    description: 'Rank #1 on the global weekly leaderboard.',
    icon: Icons.leaderboard,
  ),
  BadgeDefinition(
    type: BadgeType.perfectWeek,
    id: 'perfectWeek',
    title: 'Perfect Week',
    description: 'Score 80+ for 7 consecutive days.',
    icon: Icons.calendar_month,
  ),
  BadgeDefinition(
    type: BadgeType.courseGraduate,
    id: 'courseGraduate',
    title: 'Course Graduate',
    description: 'Complete all lessons in a syllabus course.',
    icon: Icons.school_outlined,
  ),
];
